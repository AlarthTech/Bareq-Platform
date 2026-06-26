import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../company/domain/usecases/get_my_company_usecase.dart';
import '../../../work_types/domain/entities/work_type_entity.dart';
import '../../../work_types/domain/usecases/assign_work_type_to_worker_usecase.dart';
import '../../../work_types/domain/usecases/get_work_types_usecase.dart';
import '../../domain/entities/worker_entity.dart';

/// Bottom sheet to assign a work type to a worker (shared by list + detail screens).
class AssignWorkTypeSheet {
  AssignWorkTypeSheet._();

  static Future<void> show(
    BuildContext context, {
    required WorkerEntity worker,
    VoidCallback? onAssigned,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final companyId = await resolveCompanyId(context, worker);
    if (!context.mounted) return;
    if (companyId == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'تعذر تحديد الشركة. أعد تسجيل الدخول أو افتح العاملة من قائمة الشركة.',
          ),
        ),
      );
      return;
    }

    final typesResult = await getIt<GetWorkTypesUseCase>()(
      GetWorkTypesParams(companyId: companyId),
    );
    if (!context.mounted) return;

    final typesList = typesResult.fold<List<WorkTypeEntity>?>(
      (f) {
        messenger.showSnackBar(SnackBar(content: Text(f.message)));
        return null;
      },
      (page) => page.items,
    );
    if (typesList == null) return;
    if (typesList.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('لا توجد أنواع خدمات. أضف نوع خدمة من القائمة أولاً.'),
        ),
      );
      return;
    }

    var selectedWt = typesList.first;
    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLarge)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom + 24,
          ),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'ربط نوع خدمة',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.gray900,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    worker.fullName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.gray500,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<int>(
                    value: selectedWt.id,
                    decoration: const InputDecoration(
                      labelText: 'نوع الخدمة',
                      border: OutlineInputBorder(),
                    ),
                    items: typesList
                        .map(
                          (e) => DropdownMenuItem<int>(
                            value: e.id,
                            child: Text(
                              e.isOvernight ? '${e.name} (مبيت)' : e.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (id) {
                      if (id == null) return;
                      setSheetState(() {
                        selectedWt = typesList.firstWhere((t) => t.id == id);
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () async {
                      final nav = Navigator.of(sheetContext);
                      final result = await getIt<AssignWorkTypeToWorkerUseCase>()(
                        AssignWorkTypeToWorkerParams(
                          workerId: worker.id,
                          workTypeId: selectedWt.id,
                        ),
                      );
                      if (!context.mounted) return;
                      nav.pop();
                      result.fold(
                        (f) => messenger.showSnackBar(SnackBar(content: Text(f.message))),
                        (_) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('تم ربط نوع الخدمة بالعاملة بنجاح'),
                            ),
                          );
                          onAssigned?.call();
                        },
                      );
                    },
                    child: const Text('تأكيد الربط'),
                  ),
                  const SizedBox(height: 8),
                ],
              );
            },
          ),
        );
      },
    );
  }

  static Future<int?> resolveCompanyId(
    BuildContext context,
    WorkerEntity worker,
  ) async {
    if (worker.companyId != null) return worker.companyId;
    final auth = context.read<AuthBloc>().state;
    if (auth is! AuthAuthenticated) return null;
    final result = await getIt<GetMyCompanyUseCase>()(auth.user.id);
    return result.fold((_) => null, (list) => list.isEmpty ? null : list.first.id);
  }
}
