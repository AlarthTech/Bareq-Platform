import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/forgot_password_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/entities/city_entity.dart';
import '../../domain/entities/company_entity.dart';
import '../bloc/company_bloc.dart';
import '../bloc/company_event.dart';
import '../bloc/company_state.dart';
import '../cubit/company_guard_cubit.dart';
import '../models/company_form_mode.dart';
import '../models/onboarding_success_extra.dart';
import '../widgets/city_dropdown_field.dart';
import '../widgets/commercial_register_picker.dart';

class CreateCompanyScreen extends StatefulWidget {
  const CreateCompanyScreen({
    super.key,
    required this.userId,
    this.initialPhone,
    this.initialEmail,
    this.initialCityId,
    this.mode = CompanyFormMode.onboarding,
  });

  final int userId;
  final String? initialPhone;
  final String? initialEmail;
  final int? initialCityId;
  final CompanyFormMode mode;

  bool get isOnboarding => mode == CompanyFormMode.onboarding;

  @override
  State<CreateCompanyScreen> createState() => _CreateCompanyScreenState();
}

class _CreateCompanyScreenState extends State<CreateCompanyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _commercialRegController = TextEditingController();
  final _addressController = TextEditingController();
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  final _experienceYearsController = TextEditingController(text: '0');
  final _descriptionController = TextEditingController();

  int? _selectedCityId;
  List<CityEntity> _cities = [];
  bool _citiesLoading = true;
  String? _citiesError;
  String? _registerFileName;
  CommercialRegisterPickResult? _registerFile;
  CompanyEntity? _createdCompany;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.initialPhone ?? '');
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
    _selectedCityId = widget.initialCityId;
    context.read<CompanyBloc>().add(const GetAllCitiesEvent());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _commercialRegController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _experienceYearsController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _loadCities() {
    setState(() {
      _citiesLoading = true;
      _citiesError = null;
    });
    context.read<CompanyBloc>().add(const GetAllCitiesEvent());
  }

  Future<void> _pickRegisterFile() async {
    try {
      final file = await CommercialRegisterPicker.pick();
      if (file == null) return;
      setState(() {
        _registerFile = file;
        _registerFileName = file.name;
      });
    } on CommercialRegisterPickerException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppTheme.dangerRed),
      );
    }
  }

  int _parseExperienceYears() {
    final raw = _experienceYearsController.text.trim();
    if (raw.isEmpty) return 0;
    final value = int.tryParse(raw) ?? 0;
    return value.clamp(0, 100);
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate() || _selectedCityId == null) {
      if (_selectedCityId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى اختيار المدينة')),
        );
      }
      return;
    }

    context.read<CompanyBloc>().add(
          CreateCompanyEvent(
            name: _nameController.text.trim(),
            address: _addressController.text.trim().isEmpty
                ? null
                : _addressController.text.trim(),
            commercialRegNo: _commercialRegController.text.trim().isEmpty
                ? null
                : _commercialRegController.text.trim(),
            phone: _phoneController.text.trim(),
            email: _emailController.text.trim(),
            ownerUserId: widget.userId,
            cityId: _selectedCityId!,
            experienceYears: _parseExperienceYears(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
          ),
        );
  }

  void _uploadIfNeeded(CompanyEntity company) {
    final file = _registerFile;
    if (file != null) {
      context.read<CompanyBloc>().add(
            UploadCommercialRegisterEvent(
              companyId: company.id,
              fileName: file.name,
              filePath: file.path,
              bytes: file.bytes,
            ),
          );
    } else {
      _goToSuccess(company, uploadFailed: false);
    }
  }

  void _skipForNow() {
    context.read<CompanyGuardCubit>().skipForNow();
    context.go(AppRoutes.dashboard);
  }

  void _goToSuccess(CompanyEntity company, {required bool uploadFailed}) {
    if (widget.isOnboarding) {
      context.read<CompanyGuardCubit>().markCompanyCreated(company);
    } else {
      context.read<CompanyGuardCubit>().refresh(widget.userId);
    }
    context.push(
      AppRoutes.onboardingSuccess,
      extra: OnboardingSuccessExtra(
        company: company,
        uploadFailed: uploadFailed,
        registerFile: uploadFailed ? _registerFile : null,
        fromAddCompany: !widget.isOnboarding,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOnboarding = widget.isOnboarding;

    return BlocBuilder<CompanyGuardCubit, CompanyGuardState>(
      builder: (context, guardState) {
        final skippedOnboarding =
            guardState is CompanyGuardNoCompany && guardState.skipped;

        return PopScope(
          canPop: !isOnboarding || skippedOnboarding,
          child: BlocListener<CompanyBloc, CompanyState>(
        listener: (context, state) {
          if (state is CitiesLoaded) {
            setState(() {
              _cities = state.cities;
              _citiesLoading = false;
              _citiesError = null;
            });
          } else if (state is CompanyCreated) {
            _createdCompany = state.company;
            _uploadIfNeeded(state.company);
          } else if (state is CommercialRegisterUploaded) {
            _goToSuccess(state.company, uploadFailed: false);
          } else if (state is CompanyError) {
            if (_createdCompany != null) {
              _goToSuccess(_createdCompany!, uploadFailed: true);
              return;
            }
            if (_cities.isEmpty && _citiesLoading) {
              setState(() {
                _citiesLoading = false;
                _citiesError = state.message;
              });
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppTheme.dangerRed,
                ),
              );
            }
          }
        },
        child: Scaffold(
          backgroundColor: const Color(0xFFF8FAFA),
          appBar: AppBar(
            automaticallyImplyLeading: !isOnboarding || skippedOnboarding,
            backgroundColor: Colors.transparent,
            foregroundColor: ForgotPasswordConstants.tealDark,
            title: Text(isOnboarding ? 'إنشاء الشركة' : 'إضافة شركة جديدة'),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacing24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      isOnboarding ? 'أكمل إعداد شركتك' : 'بيانات الشركة الجديدة',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: ForgotPasswordConstants.tealDark,
                          ),
                    ),
                    const SizedBox(height: AppTheme.spacing8),
                    Text(
                      isOnboarding
                          ? 'أنشئ شركتك للبدء في إدارة العاملات والحجوزات، أو تخطَّ الآن والعودة لاحقاً.'
                          : 'أدخل بيانات الشركة الجديدة. سيتم مراجعتها من قبل الإدارة قبل تفعيلها.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.gray500,
                            height: 1.5,
                          ),
                    ),
                    const SizedBox(height: AppTheme.spacing24),
                    AppTextField(
                      label: 'اسم الشركة *',
                      hint: 'أدخل اسم الشركة',
                      controller: _nameController,
                      prefixIcon: const Icon(
                        Icons.business_outlined,
                        color: ForgotPasswordConstants.tealPrimary,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'يرجى إدخال اسم الشركة';
                        }
                        if (value.trim().length > 200) {
                          return 'الاسم طويل جداً (200 حرف كحد أقصى)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppTheme.spacing20),
                    AppTextField(
                      label: 'هاتف الشركة *',
                      hint: '0912345678',
                      controller: _phoneController,
                      prefixIcon: const Icon(
                        Icons.phone_outlined,
                        color: ForgotPasswordConstants.tealPrimary,
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'يرجى إدخال رقم الهاتف';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppTheme.spacing20),
                    AppTextField(
                      label: 'بريد الشركة *',
                      hint: 'company@example.com',
                      controller: _emailController,
                      prefixIcon: const Icon(
                        Icons.email_outlined,
                        color: ForgotPasswordConstants.tealPrimary,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textCapitalization: TextCapitalization.none,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'يرجى إدخال البريد الإلكتروني';
                        }
                        final emailRegex =
                            RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                        if (!emailRegex.hasMatch(value.trim())) {
                          return 'يرجى إدخال بريد إلكتروني صحيح';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppTheme.spacing20),
                    CityDropdownField(
                      cities: _cities,
                      isLoading: _citiesLoading,
                      errorMessage: _citiesError,
                      selectedCityId: _selectedCityId,
                      onRetry: _loadCities,
                      onChanged: (value) => setState(() => _selectedCityId = value),
                    ),
                    const SizedBox(height: AppTheme.spacing20),
                    AppTextField(
                      label: 'العنوان',
                      hint: 'شارع الجمهورية، طرابلس',
                      controller: _addressController,
                      prefixIcon: const Icon(
                        Icons.location_on_outlined,
                        color: ForgotPasswordConstants.tealPrimary,
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: AppTheme.spacing20),
                    AppTextField(
                      label: 'رقم السجل التجاري',
                      hint: 'CR-12345',
                      controller: _commercialRegController,
                      prefixIcon: const Icon(
                        Icons.description_outlined,
                        color: ForgotPasswordConstants.tealPrimary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing20),
                    AppTextField(
                      label: 'سنوات الخبرة',
                      hint: '0',
                      controller: _experienceYearsController,
                      prefixIcon: const Icon(
                        Icons.calendar_today_outlined,
                        color: ForgotPasswordConstants.tealPrimary,
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return null;
                        final n = int.tryParse(value.trim());
                        if (n == null) return 'يرجى إدخال رقم صحيح';
                        if (n < 0 || n > 100) {
                          return 'يجب أن تكون بين 0 و 100';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppTheme.spacing20),
                    AppTextField(
                      label: 'وصف الشركة',
                      hint: 'وصف مختصر عن الشركة',
                      controller: _descriptionController,
                      prefixIcon: const Icon(
                        Icons.notes_outlined,
                        color: ForgotPasswordConstants.tealPrimary,
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: AppTheme.spacing20),
                    CommercialRegisterPicker(
                      fileName: _registerFileName,
                      onPick: _pickRegisterFile,
                      onClear: () => setState(() {
                        _registerFile = null;
                        _registerFileName = null;
                      }),
                    ),
                    const SizedBox(height: AppTheme.spacing32),
                    BlocBuilder<CompanyBloc, CompanyState>(
                      builder: (context, state) {
                        final isSubmitting = state is CompanyLoading ||
                            state is CommercialRegisterUploading;
                        return AppButton(
                          text: isOnboarding ? 'إنشاء الشركة' : 'إضافة الشركة',
                          onPressed: isSubmitting ? null : _handleSubmit,
                          isLoading: isSubmitting,
                          isFullWidth: true,
                          icon: Icons.add_business_outlined,
                        );
                      },
                    ),
                    if (isOnboarding) ...[
                      const SizedBox(height: AppTheme.spacing16),
                      TextButton(
                        onPressed: _skipForNow,
                        child: Text(
                          'تخطي الآن',
                          style: TextStyle(color: AppTheme.gray600),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
      },
    );
  }
}
