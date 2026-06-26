import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/booking_report_constants.dart';
import '../../../../core/constants/notification_type_names.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/domain/entities/pagination_params.dart';
import '../../../../core/storage/company_session_storage.dart';
import '../../../bookings/domain/usecases/get_booking_by_id_usecase.dart';
import '../../../bookings/presentation/bloc/booking_bloc.dart';
import '../../../bookings/presentation/models/booking_detail_extra.dart';
import '../../../workers/domain/entities/worker_entity.dart';
import '../../../workers/domain/usecases/get_workers_usecase.dart';
import '../../../workers/presentation/models/worker_detail_extra.dart';
import '../../../../core/constants/app_routes.dart';
import '../../domain/entities/notification_entity.dart';

class NotificationNavigationHelper {
  NotificationNavigationHelper._();

  static Future<void> openNotificationTarget(
    BuildContext context,
    NotificationEntity notification,
  ) async {
    final relatedId = notification.relatedEntityId;
    if (relatedId == null) return;

    if (notification.notificationTypeId ==
            BookingReportNotificationTypes.submittedForCompany ||
        notification.notificationTypeName == 'BookingReportSubmittedForCompany') {
      context.push(AppRoutes.companyBookingReportDetail(relatedId));
      return;
    }

    if (NotificationTypeNames.isBooking(notification.notificationTypeName)) {
      await _openBooking(context, relatedId);
      return;
    }

    if (NotificationTypeNames.isWorkerHealth(notification.notificationTypeName)) {
      await _openWorker(context, relatedId, focusHealthCertificate: true);
    }
  }

  static Future<void> _openBooking(BuildContext context, int bookingId) async {
    final result = await getIt<GetBookingByIdUseCase>()(bookingId);
    if (!context.mounted) return;

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
      },
      (booking) {
        final bookingBloc = getIt<BookingBloc>();
        context.push(
          AppRoutes.bookingDetail(bookingId),
          extra: BookingDetailExtra(
            booking: booking,
            bookingBloc: bookingBloc,
          ),
        );
      },
    );
  }

  static Future<void> _openWorker(
    BuildContext context,
    int workerId, {
    bool focusHealthCertificate = false,
  }) async {
    final companyId = await CompanySessionStorage.readPrimaryCompanyId();
    if (!context.mounted) return;

    if (companyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار شركة أولاً')),
      );
      return;
    }

    final worker = await _findWorker(companyId, workerId);
    if (!context.mounted) return;

    if (worker == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر العثور على بيانات العاملة')),
      );
      return;
    }

    context.push(
      AppRoutes.workerDetail(workerId),
      extra: WorkerDetailExtra(
        worker: worker,
        focusHealthCertificate: focusHealthCertificate,
      ),
    );
  }

  static Future<WorkerEntity?> _findWorker(int companyId, int workerId) async {
    var page = 1;
    while (page <= 20) {
      final result = await getIt<GetWorkersUseCase>()(
        GetWorkersParams(
          companyId: companyId,
          pagination: PaginationParams(page: page, pageSize: 50),
        ),
      );

      final found = result.fold<WorkerEntity?>(
        (_) => null,
        (paged) {
          for (final worker in paged.items) {
            if (worker.id == workerId) return worker;
          }
          if (!paged.hasNextPage) return null;
          return null;
        },
      );

      if (found != null) return found;

      final hasNext = result.fold((_) => false, (p) => p.hasNextPage);
      if (!hasNext) break;
      page++;
    }
    return null;
  }
}
