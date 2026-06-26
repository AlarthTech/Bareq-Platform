import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/animation_constants.dart';
import '../../../../core/constants/app_input_types.dart';
import '../../../../core/widgets/app_app_bar.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/loading_shimmer_widget.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/repositories/worker_repository.dart';
import '../widgets/health_certificate_picker.dart';
import '../bloc/worker_bloc.dart';
import '../bloc/worker_event.dart';
import '../bloc/worker_state.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../company/domain/entities/company_entity.dart';
import '../../../company/presentation/bloc/company_bloc.dart';
import '../../../company/presentation/bloc/company_event.dart';
import '../../../company/presentation/bloc/company_state.dart';
import '../../domain/entities/nationality_entity.dart';
import '../utils/worker_form_validation.dart';

const _kFieldFill = Color(0xFFF1F5F9);
const _kFieldRadius = 12.0;

class AddWorkerScreen extends StatefulWidget {
  const AddWorkerScreen({super.key});

  @override
  State<AddWorkerScreen> createState() => _AddWorkerScreenState();
}

class _AddWorkerScreenState extends State<AddWorkerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  final _fullNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _experienceYearsController = TextEditingController();

  final _sectionKeys = List.generate(4, (_) => GlobalKey());

  int? _selectedCompanyId;
  int? _selectedNationalityId;
  DateTime? _healthCertificateExpiryDate;
  HealthCertificatePickResult? _healthCertificateFile;
  bool _healthCertificateUploading = false;
  final Set<int> _selectedLanguageIds = {};

  bool _submitAttempted = false;
  bool _submitting = false;
  int _activeStep = 0;

  static const _sectionTitles = [
    'المعلومات الأساسية',
    'الخبرة',
    'اللغات',
    'المستندات',
  ];

  @override
  void initState() {
    super.initState();
    context.read<WorkerBloc>().add(const LoadWorkerFormLookupsEvent());
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<CompanyBloc>().add(GetMyCompanyEvent(authState.user.id));
    }
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _fullNameController.dispose();
    _ageController.dispose();
    _experienceYearsController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final scrollY = _scrollController.hasClients ? _scrollController.offset : 0.0;
    for (var i = 0; i < _sectionKeys.length; i++) {
      final ctx = _sectionKeys[i].currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null) continue;
      final dy = box.localToGlobal(Offset.zero).dy;
      final h = box.size.height;
      if (dy < 220 && dy + h > 0) {
        if (_activeStep != i) setState(() => _activeStep = i);
        break;
      }
    }
    if (scrollY < 40 && _activeStep != 0) setState(() => _activeStep = 0);
  }

  Future<void> _selectExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _healthCertificateExpiryDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      locale: const Locale('en', 'GB'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryTeal,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppTheme.gray900,
            ),
            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _healthCertificateExpiryDate = picked);
    }
  }

  _CertExpiryVisual _certVisual() {
    final d = _healthCertificateExpiryDate;
    if (d == null) return _CertExpiryVisual.none;
    final today = DateTime.now();
    final t = DateTime(today.year, today.month, today.day);
    if (d.isBefore(t)) return _CertExpiryVisual.expired;
    if (d.difference(t).inDays <= 30) return _CertExpiryVisual.expiring;
    return _CertExpiryVisual.valid;
  }

  Future<void> _scrollToSection(int index) async {
    final ctx = _sectionKeys[index].currentContext;
    if (ctx == null) return;
    await Scrollable.ensureVisible(
      ctx,
      alignment: 0.12,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _handleSubmit() async {
    setState(() {
      _submitAttempted = true;
    });

    if (_selectedCompanyId == null) {
      await _scrollToSection(0);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار الشركة')),
      );
      return;
    }
    if (_fullNameController.text.trim().isEmpty) {
      await _scrollToSection(0);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال الاسم الكامل')),
      );
      return;
    }
    if (_selectedNationalityId == null) {
      await _scrollToSection(0);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار الجنسية')),
      );
      return;
    }
    if (_selectedLanguageIds.isEmpty) {
      await _scrollToSection(2);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار لغة واحدة على الأقل')),
      );
      return;
    }
    if (_healthCertificateFile != null && _healthCertificateExpiryDate == null) {
      await _scrollToSection(3);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار تاريخ انتهاء الشهادة الصحية')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      final ageError = WorkerFormValidation.validateAge(_ageController.text);
      if (ageError != null) {
        await _scrollToSection(0);
      } else {
        final expError = WorkerFormValidation.validateExperienceYears(
          _experienceYearsController.text,
          age: WorkerFormValidation.parseAge(_ageController.text),
        );
        if (expError != null) {
          await _scrollToSection(1);
        }
      }
      return;
    }

    final languagesIds = _selectedLanguageIds.join(',');
    setState(() => _submitting = true);

    if (!mounted) return;
    context.read<WorkerBloc>().add(
          CreateWorkerEvent(
            companyId: _selectedCompanyId!,
            fullName: _fullNameController.text.trim(),
            nationalityId: _selectedNationalityId!,
            age: int.tryParse(_ageController.text) ?? 0,
            experienceYears: int.tryParse(_experienceYearsController.text) ?? 0,
            isAvailable: true,
            isActive: true,
            profileImage: null,
            healthCertificate: _healthCertificateFile?.name,
            healthCertificateExpiryDate: _healthCertificateExpiryDate,
            languagesIds: languagesIds,
          ),
        );
  }

  Future<void> _pickHealthCertificate() async {
    if (_submitting || _healthCertificateUploading) return;
    try {
      final picked = await HealthCertificatePicker.pick();
      if (!mounted) return;
      if (picked != null) {
        setState(() => _healthCertificateFile = picked);
      }
    } on HealthCertificatePickerException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppTheme.dangerRed,
        ),
      );
    }
  }

  void _clearHealthCertificate() {
    if (_submitting || _healthCertificateUploading) return;
    setState(() => _healthCertificateFile = null);
  }

  void _showWorkerSavedSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
            const SizedBox(width: AppTheme.spacing12),
            Expanded(
              child: Text(
                'تم حفظ العاملة بنجاح',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.successGreen,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppTheme.spacing16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
      ),
    );
  }

  Widget _sectionFade(int index, Widget child) {
    return child
        .animate()
        .fadeIn(
          duration: AnimationConstants.fadeIn,
          delay: (index * 45).ms,
          curve: AnimationConstants.fadeInCurve,
        )
        .slideY(
          begin: 0.04,
          end: 0,
          duration: AnimationConstants.fadeIn,
          delay: (index * 45).ms,
          curve: AnimationConstants.fadeInCurve,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceBackground,
      appBar: AppAppBar(
        title: 'إضافة عاملة جديدة',
        showLogout: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 22),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocListener<WorkerBloc, WorkerState>(
        listener: (context, state) async {
          if (state is WorkerError) {
            if (mounted) setState(() => _submitting = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.dangerRed,
              ),
            );
          } else if (state is WorkerCreated) {
            if (_healthCertificateFile != null) {
              setState(() => _healthCertificateUploading = true);
              final uploadResult =
                  await getIt<WorkerRepository>().uploadHealthCertificate(
                workerId: state.worker.id,
                fileName: _healthCertificateFile!.name,
                filePath: _healthCertificateFile!.path,
                bytes: _healthCertificateFile!.bytes,
              );
              if (!mounted) return;
              setState(() {
                _healthCertificateUploading = false;
                _submitting = false;
              });
              uploadResult.fold(
                (failure) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'تم إنشاء العاملة لكن فشل رفع الشهادة: ${failure.message}',
                      ),
                      backgroundColor: AppTheme.dangerRed,
                    ),
                  );
                },
                (_) => _showWorkerSavedSnackBar(context),
              );
              await Future<void>.delayed(const Duration(milliseconds: 450));
              if (context.mounted) context.pop(true);
              return;
            }
            if (mounted) setState(() => _submitting = false);
            _showWorkerSavedSnackBar(context);
            await Future<void>.delayed(const Duration(milliseconds: 450));
            if (context.mounted) context.pop(true);
          }
        },
        child: BlocBuilder<WorkerBloc, WorkerState>(
          buildWhen: (prev, curr) {
            if (curr is WorkerLookupsLoaded) return true;
            if (curr is WorkerLookupsLoading) return true;
            if (curr is WorkerError && prev is! WorkerLookupsLoaded) return true;
            return false;
          },
          builder: (context, state) {
            if (state is WorkerLookupsLoading) {
              return _FormSkeleton();
            }
            if (state is WorkerError) {
              return ErrorStateWidget(
                message: state.message,
                onRetry: () => context.read<WorkerBloc>().add(const LoadWorkerFormLookupsEvent()),
              );
            }
            if (state is! WorkerLookupsLoaded) {
              return const Center(child: CircularProgressIndicator());
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _StepProgressHeader(
                  activeStep: _activeStep,
                  labels: _sectionTitles,
                ),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(
                        AppTheme.spacing16,
                        AppTheme.spacing8,
                        AppTheme.spacing16,
                        AppTheme.spacing24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _sectionFade(
                            0,
                            _SectionCard(
                              sectionKey: _sectionKeys[0],
                              title: 'المعلومات الأساسية',
                              description: 'الاسم، الشركة، الجنسية، والعمر',
                              child: _buildBasicSection(state),
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacing24),
                          _sectionFade(
                            1,
                            _SectionCard(
                              sectionKey: _sectionKeys[1],
                              title: 'الخبرة',
                              description: 'سنوات العمل في المجال',
                              child: _buildExperienceSection(),
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacing24),
                          _sectionFade(
                            2,
                            _SectionCard(
                              sectionKey: _sectionKeys[2],
                              title: 'اللغات',
                              description: 'اختر اللغات التي تتقنها العاملة',
                              child: _buildLanguagesSection(state),
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacing24),
                          _sectionFade(
                            3,
                            _SectionCard(
                              sectionKey: _sectionKeys[3],
                              title: 'المستندات',
                              description: 'الشهادة الصحية',
                              child: _buildDocumentsSection(),
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacing24),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: BlocBuilder<WorkerBloc, WorkerState>(
        buildWhen: (p, c) => c is WorkerLookupsLoaded || c is WorkerLookupsLoading,
        builder: (context, state) {
          if (state is! WorkerLookupsLoaded) {
            return const SizedBox.shrink();
          }
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spacing16,
                AppTheme.spacing8,
                AppTheme.spacing16,
                AppTheme.spacing16,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: (_submitting || _healthCertificateUploading) ? null : _handleSubmit,
                  style: FilledButton.styleFrom(
                    elevation: _submitting ? 0 : 2,
                    shadowColor: AppTheme.primaryTeal.withValues(alpha: 0.35),
                    backgroundColor: AppTheme.primaryTeal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_kFieldRadius),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.save_rounded, size: 22),
                            const SizedBox(width: AppTheme.spacing8),
                            Text(
                              'حفظ وإضافة العاملة',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBasicSection(WorkerLookupsLoaded lookups) {
    return BlocBuilder<CompanyBloc, CompanyState>(
      builder: (context, companyState) {
        if (companyState is CompanyLoaded && companyState.companies.isNotEmpty) {
          if (_selectedCompanyId == null && companyState.companies.length == 1) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _selectedCompanyId = companyState.activeCompanyId);
            });
          }
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (companyState is CompanyLoaded && companyState.companies.isNotEmpty)
              _CompanyPickerField(
                companies: companyState.companies,
                selectedId: _selectedCompanyId,
                submitAttempted: _submitAttempted,
                onOpen: () => _showCompanySheet(companyState.companies),
              ),
            const SizedBox(height: AppTheme.spacing16),
            _FilledTextField(
              label: 'الاسم الكامل',
              hint: 'أدخل الاسم الكامل',
              controller: _fullNameController,
              icon: Icons.person_outline_rounded,
              textCapitalization: TextCapitalization.words,
              submitAttempted: _submitAttempted,
              validator: (v) =>
                  v == null || v.isEmpty ? 'يرجى إدخال الاسم الكامل' : null,
            ),
            const SizedBox(height: AppTheme.spacing16),
            _NationalityPickerField(
              nationalities: lookups.nationalities,
              selectedId: _selectedNationalityId,
              submitAttempted: _submitAttempted,
              onOpen: () => _showNationalitySheet(lookups.nationalities),
            ),
            const SizedBox(height: AppTheme.spacing16),
            _FilledTextField(
              label: 'العمر',
              hint: 'من ${AppConstants.workerMinAge} إلى ${AppConstants.workerMaxAge} سنة',
              controller: _ageController,
              icon: Icons.cake_outlined,
              keyboardType: AppInputTypes.numberType1,
              inputFormatters: [
                ...AppInputTypes.digitsOnly,
                LengthLimitingTextInputFormatter(2),
              ],
              submitAttempted: _submitAttempted,
              validator: WorkerFormValidation.validateAge,
              onChanged: (_) {
                setState(() {});
                if (_submitAttempted) {
                  _formKey.currentState?.validate();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showCompanySheet(List<CompanyEntity> companies) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _SearchableSheet<CompanyEntity>(
        title: 'اختر الشركة',
        items: companies,
        searchHint: 'بحث…',
        filter: (c, q) => c.name.contains(q),
        itemBuilder: (c, selected) {
          final letter = c.name.isNotEmpty ? c.name.substring(0, 1) : '?';
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryTeal.withValues(alpha: 0.12),
              foregroundColor: AppTheme.primaryTeal,
              child: Text(
                letter,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            title: Text(c.name),
            trailing: selected
                ? const Icon(Icons.check_circle_rounded, color: AppTheme.primaryTeal)
                : null,
            selected: selected,
            selectedTileColor: AppTheme.primaryTeal.withValues(alpha: 0.12),
            onTap: () {
              setState(() => _selectedCompanyId = c.id);
              Navigator.of(ctx).pop();
            },
          );
        },
        isSelected: (c) => c.id == _selectedCompanyId,
      ),
    );
  }

  Future<void> _showNationalitySheet(List<NationalityEntity> nationalities) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _SearchableSheet<NationalityEntity>(
        title: 'اختر الجنسية',
        items: nationalities,
        searchHint: 'بحث…',
        filter: (n, q) => n.name.contains(q),
        itemBuilder: (n, selected) {
          return ListTile(
            leading: Icon(
              Icons.flag_outlined,
              color: selected ? AppTheme.primaryTeal : AppTheme.gray500,
            ),
            title: Text(n.name),
            trailing: selected
                ? const Icon(Icons.check_circle_rounded, color: AppTheme.primaryTeal)
                : null,
            selected: selected,
            selectedTileColor: AppTheme.primaryTeal.withValues(alpha: 0.12),
            onTap: () {
              setState(() => _selectedNationalityId = n.id);
              Navigator.of(ctx).pop();
            },
          );
        },
        isSelected: (n) => n.id == _selectedNationalityId,
      ),
    );
  }

  Widget _buildExperienceSection() {
    final age = WorkerFormValidation.parseAge(_ageController.text);
    return _FilledTextField(
      label: 'سنوات الخبرة',
      hint: age != null ? 'أقل من $age سنوات' : 'أدخل العمر أولاً',
      controller: _experienceYearsController,
      icon: Icons.work_outline_rounded,
      keyboardType: AppInputTypes.numberType1,
      inputFormatters: [
        ...AppInputTypes.digitsOnly,
        LengthLimitingTextInputFormatter(2),
      ],
      submitAttempted: _submitAttempted,
      validator: (v) => WorkerFormValidation.validateExperienceYears(
        v,
        age: age,
      ),
      onChanged: (_) {
        if (_submitAttempted) {
          _formKey.currentState?.validate();
        }
      },
    );
  }

  Widget _buildLanguagesSection(WorkerLookupsLoaded lookups) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppTheme.spacing8,
          runSpacing: AppTheme.spacing8,
          children: lookups.languages.map((lang) {
            final selected = _selectedLanguageIds.contains(lang.id);
            return _LanguageChip(
              label: lang.name,
              selected: selected,
              onTap: () {
                setState(() {
                  if (selected) {
                    _selectedLanguageIds.remove(lang.id);
                  } else {
                    _selectedLanguageIds.add(lang.id);
                  }
                });
              },
            );
          }).toList(),
        ),
        if (_submitAttempted && _selectedLanguageIds.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppTheme.spacing8),
            child: Text(
              'يرجى اختيار لغة واحدة على الأقل',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.dangerRed,
                  ),
            ),
          ),
      ],
    );
  }

  Widget _buildDocumentsSection() {
    final certUploaded = _healthCertificateFile != null;
    final cv = _certVisual();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DocumentUploadCard(
          icon: Icons.badge_outlined,
          title: 'الشهادة الصحية',
          subtitle: _healthCertificateUploading
              ? 'جاري رفع الملف…'
              : certUploaded
                  ? _healthCertificateFile!.name
                  : 'لم يُرفع بعد — PDF أو JPG أو PNG',
          uploaded: certUploaded,
          statusColor: certUploaded ? _certStatusColor(cv) : null,
          statusLabel: certUploaded ? _certStatusLabel(cv) : null,
          onTap: _pickHealthCertificate,
        ),
        if (certUploaded) ...[
          const SizedBox(height: AppTheme.spacing8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _clearHealthCertificate,
              icon: const Icon(Icons.close, size: 18),
              label: const Text('إزالة الملف'),
              style: TextButton.styleFrom(foregroundColor: AppTheme.dangerRed),
            ),
          ),
        ],
        const SizedBox(height: AppTheme.spacing16),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            'تاريخ انتهاء الشهادة',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.gray600,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        const SizedBox(height: AppTheme.spacing8),
        _DatePickerTile(
          date: _healthCertificateExpiryDate,
          onTap: _selectExpiryDate,
          visual: cv,
        ),
      ],
    );
  }

  Color _certStatusColor(_CertExpiryVisual v) {
    switch (v) {
      case _CertExpiryVisual.none:
        return AppTheme.gray500;
      case _CertExpiryVisual.valid:
        return AppTheme.successGreen;
      case _CertExpiryVisual.expiring:
        return AppTheme.warningAmber;
      case _CertExpiryVisual.expired:
        return AppTheme.dangerRed;
    }
  }

  String _certStatusLabel(_CertExpiryVisual v) {
    switch (v) {
      case _CertExpiryVisual.none:
        return '';
      case _CertExpiryVisual.valid:
        return 'سارية';
      case _CertExpiryVisual.expiring:
        return 'تنتهي قريباً';
      case _CertExpiryVisual.expired:
        return 'منتهية';
    }
  }

}

enum _CertExpiryVisual { none, valid, expiring, expired }

class _StepProgressHeader extends StatelessWidget {
  const _StepProgressHeader({
    required this.activeStep,
    required this.labels,
  });

  final int activeStep;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final step = activeStep.clamp(0, labels.length - 1);
    final progress = (step + 1) / labels.length;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacing16,
        AppTheme.spacing8,
        AppTheme.spacing16,
        AppTheme.spacing16,
      ),
      color: AppTheme.surfaceBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  labels[step],
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.gray800,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${step + 1}/${labels.length}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppTheme.gray500,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppTheme.gray200,
              color: AppTheme.primaryTeal,
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(labels.length, (i) {
              final done = i <= step;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: i == 0 ? 0 : 4,
                    right: i == labels.length - 1 ? 0 : 4,
                  ),
                  child: AnimatedContainer(
                    duration: AnimationConstants.microInteraction,
                    height: 6,
                    decoration: BoxDecoration(
                      color: done ? AppTheme.primaryTeal : AppTheme.gray200,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.sectionKey,
    required this.title,
    this.description,
    required this.child,
  });

  final GlobalKey sectionKey;
  final String title;
  final String? description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: sectionKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.gray900,
                ),
          ),
          if (description != null) ...[
            const SizedBox(height: AppTheme.spacing4),
            Text(
              description!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.gray500,
                  ),
            ),
          ],
          const SizedBox(height: AppTheme.spacing16),
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.softShadow,
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _FilledTextField extends StatefulWidget {
  const _FilledTextField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.icon,
    this.keyboardType,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.validator,
    required this.submitAttempted,
    this.onChanged,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData icon;
  final TextInputType? keyboardType;
  final int maxLines;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final FormFieldValidator<String>? validator;
  final bool submitAttempted;
  final ValueChanged<String>? onChanged;

  @override
  State<_FilledTextField> createState() => _FilledTextFieldState();
}

class _FilledTextFieldState extends State<_FilledTextField> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AnimationConstants.microInteraction,
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_kFieldRadius),
        boxShadow: _focus.hasFocus
            ? [
                BoxShadow(
                  color: AppTheme.primaryTeal.withValues(alpha: 0.22),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: TextFormField(
          controller: widget.controller,
          focusNode: _focus,
          keyboardType: widget.keyboardType,
          maxLines: widget.maxLines,
          textCapitalization: widget.textCapitalization,
          inputFormatters: widget.inputFormatters,
          onChanged: widget.onChanged,
          autovalidateMode: widget.submitAttempted
              ? AutovalidateMode.always
              : AutovalidateMode.disabled,
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            filled: true,
            fillColor: _kFieldFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_kFieldRadius),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_kFieldRadius),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_kFieldRadius),
              borderSide: const BorderSide(color: AppTheme.primaryTeal, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_kFieldRadius),
              borderSide: const BorderSide(color: AppTheme.dangerRed, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_kFieldRadius),
              borderSide: const BorderSide(color: AppTheme.dangerRed, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacing16,
              vertical: AppTheme.spacing16,
            ),
            prefixIcon: IconTheme.merge(
              data: const IconThemeData(size: 20, color: AppTheme.gray500),
              child: Icon(widget.icon),
            ),
          ),
          validator: widget.validator,
        ),
    );
  }
}

class _CompanyPickerField extends StatelessWidget {
  const _CompanyPickerField({
    required this.companies,
    required this.selectedId,
    required this.submitAttempted,
    required this.onOpen,
  });

  final List<CompanyEntity> companies;
  final int? selectedId;
  final bool submitAttempted;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final selected = companies.where((c) => c.id == selectedId).firstOrNull;
    final label = selected?.name ?? 'اختر الشركة';
    final error = submitAttempted && selectedId == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: _kFieldFill,
          borderRadius: BorderRadius.circular(_kFieldRadius),
          child: InkWell(
            onTap: onOpen,
            borderRadius: BorderRadius.circular(_kFieldRadius),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacing16,
                vertical: AppTheme.spacing16,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppTheme.primaryTeal.withValues(alpha: 0.12),
                    foregroundColor: AppTheme.primaryTeal,
                    child: Text(
                      selected?.name.isNotEmpty == true ? selected!.name.substring(0, 1) : '?',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الشركة',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: AppTheme.gray600,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          label,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.gray900,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.gray500),
                ],
              ),
            ),
          ),
        ),
        if (error)
          Padding(
            padding: const EdgeInsets.only(top: AppTheme.spacing8, right: 4),
            child: Text(
              'يرجى اختيار الشركة',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.dangerRed),
            ),
          ),
      ],
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (!it.moveNext()) return null;
    return it.current;
  }
}

class _NationalityPickerField extends StatelessWidget {
  const _NationalityPickerField({
    required this.nationalities,
    required this.selectedId,
    required this.submitAttempted,
    required this.onOpen,
  });

  final List<NationalityEntity> nationalities;
  final int? selectedId;
  final bool submitAttempted;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final selected = nationalities.where((n) => n.id == selectedId).firstOrNull;
    final label = selected?.name ?? 'اختر الجنسية';
    final error = submitAttempted && selectedId == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: _kFieldFill,
          borderRadius: BorderRadius.circular(_kFieldRadius),
          child: InkWell(
            onTap: onOpen,
            borderRadius: BorderRadius.circular(_kFieldRadius),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacing16,
                vertical: AppTheme.spacing16,
              ),
              child: Row(
                children: [
                  Icon(Icons.flag_outlined, color: AppTheme.gray500.withValues(alpha: 0.9), size: 22),
                  const SizedBox(width: AppTheme.spacing12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الجنسية',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: AppTheme.gray600,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          label,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.gray900,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.gray500),
                ],
              ),
            ),
          ),
        ),
        if (error)
          Padding(
            padding: const EdgeInsets.only(top: AppTheme.spacing8, right: 4),
            child: Text(
              'يرجى اختيار الجنسية',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.dangerRed),
            ),
          ),
      ],
    );
  }
}

class _SearchableSheet<T> extends StatefulWidget {
  const _SearchableSheet({
    required this.title,
    required this.items,
    required this.searchHint,
    required this.filter,
    required this.itemBuilder,
    required this.isSelected,
  });

  final String title;
  final List<T> items;
  final String searchHint;
  final bool Function(T item, String query) filter;
  final Widget Function(T item, bool selected) itemBuilder;
  final bool Function(T item) isSelected;

  @override
  State<_SearchableSheet<T>> createState() => _SearchableSheetState<T>();
}

class _SearchableSheetState<T> extends State<_SearchableSheet<T>> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.items.where((e) => widget.filter(e, _q)).toList();
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Column(
          children: [
            const SizedBox(height: 8),
            Text(
              widget.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
              child: TextField(
                onChanged: (v) => setState(() => _q = v),
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  hintText: widget.searchHint,
                  prefixIcon: const Icon(Icons.search, size: 22),
                  filled: true,
                  fillColor: _kFieldFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(_kFieldRadius),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacing8),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: filtered.length,
                itemBuilder: (context, i) {
                  final item = filtered[i];
                  return widget.itemBuilder(item, widget.isSelected(item));
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LanguageChip extends StatelessWidget {
  const _LanguageChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AnimationConstants.microInteraction,
      curve: Curves.easeOutCubic,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          child: AnimatedContainer(
            duration: AnimationConstants.microInteraction,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: selected
                  ? AppTheme.primaryTeal.withValues(alpha: 0.12)
                  : AppTheme.gray100,
              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
              border: Border.all(
                color: selected ? AppTheme.primaryTeal : AppTheme.gray200,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected)
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(Icons.check_rounded, size: 18, color: AppTheme.primaryTeal),
                  ),
                if (selected) const SizedBox(width: 6),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: selected ? AppTheme.primaryTeal : AppTheme.gray700,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DocumentUploadCard extends StatelessWidget {
  const _DocumentUploadCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.uploaded,
    required this.onTap,
    this.statusColor,
    this.statusLabel,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool uploaded;
  final VoidCallback onTap;
  final Color? statusColor;
  final String? statusLabel;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacing24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.gray200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryTeal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppTheme.primaryTeal, size: 22),
              ),
              const SizedBox(width: AppTheme.spacing16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: uploaded ? AppTheme.successGreen : AppTheme.gray500,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    if (statusLabel != null && statusLabel!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        statusLabel!,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                uploaded ? Icons.check_circle_rounded : Icons.cloud_upload_outlined,
                color: uploaded ? AppTheme.successGreen : AppTheme.gray400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  const _DatePickerTile({
    required this.date,
    required this.onTap,
    required this.visual,
  });

  final DateTime? date;
  final VoidCallback onTap;
  final _CertExpiryVisual visual;

  @override
  Widget build(BuildContext context) {
    final borderColor = date == null
        ? Colors.transparent
        : switch (visual) {
            _CertExpiryVisual.expired => AppTheme.dangerRed,
            _CertExpiryVisual.expiring => AppTheme.warningAmber,
            _CertExpiryVisual.valid => AppTheme.successGreen,
            _CertExpiryVisual.none => AppTheme.gray200,
          };

    return Material(
      color: _kFieldFill,
      borderRadius: BorderRadius.circular(_kFieldRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_kFieldRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacing16,
            vertical: AppTheme.spacing16,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_kFieldRadius),
            border: Border.all(color: borderColor, width: date == null ? 0 : 1.5),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_month_rounded, size: 22, color: AppTheme.gray500),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: Text(
                  date != null
                      ? DateFormatter.formatDisplayDate(date!)
                      : 'اختر التاريخ',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: date != null ? AppTheme.gray900 : AppTheme.gray500,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      children: [
        LoadingShimmerWidget(height: 48, borderRadius: BorderRadius.circular(12)),
        const SizedBox(height: AppTheme.spacing16),
        LoadingShimmerWidget(height: 56, borderRadius: BorderRadius.circular(12)),
        const SizedBox(height: AppTheme.spacing16),
        LoadingShimmerWidget(height: 56, borderRadius: BorderRadius.circular(12)),
        const SizedBox(height: AppTheme.spacing24),
        LoadingShimmerWidget(height: 120, borderRadius: BorderRadius.circular(16)),
      ],
    );
  }
}
