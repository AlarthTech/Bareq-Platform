import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/forgot_password_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../cubit/company_guard_cubit.dart';
import '../../domain/entities/city_entity.dart';
import '../../domain/entities/company_entity.dart';
import '../bloc/company_bloc.dart';
import '../bloc/company_event.dart';
import '../bloc/company_state.dart';
import '../widgets/city_dropdown_field.dart';
import '../widgets/commercial_register_picker.dart';

class EditCompanyScreen extends StatefulWidget {
  const EditCompanyScreen({super.key, required this.company});

  final CompanyEntity company;

  @override
  State<EditCompanyScreen> createState() => _EditCompanyScreenState();
}

class _EditCompanyScreenState extends State<EditCompanyScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _commercialRegController;
  late final TextEditingController _addressController;
  late final TextEditingController _emailController;
  late final TextEditingController _experienceYearsController;
  late final TextEditingController _descriptionController;

  int? _selectedCityId;
  List<CityEntity> _cities = [];
  bool _citiesLoading = true;
  String? _citiesError;
  String? _registerFileName;

  @override
  void initState() {
    super.initState();
    final c = widget.company;
    _nameController = TextEditingController(text: c.name);
    _commercialRegController = TextEditingController(text: c.commercialRegNo);
    _addressController = TextEditingController(text: c.address);
    _emailController = TextEditingController(text: c.email ?? '');
    _experienceYearsController =
        TextEditingController(text: '${c.experienceYears}');
    _descriptionController = TextEditingController(text: c.description ?? '');
    _selectedCityId = c.cityId;
    context.read<CompanyBloc>().add(const GetAllCitiesEvent());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _commercialRegController.dispose();
    _addressController.dispose();
    _emailController.dispose();
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
      setState(() => _registerFileName = file.name);
      if (!mounted) return;
      context.read<CompanyBloc>().add(
            UploadCommercialRegisterEvent(
              companyId: widget.company.id,
              fileName: file.name,
              filePath: file.path,
              bytes: file.bytes,
            ),
          );
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
    return (int.tryParse(raw) ?? 0).clamp(0, 100);
  }

  void _submit() {
    if (!_formKey.currentState!.validate() || _selectedCityId == null) {
      if (_selectedCityId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى اختيار المدينة')),
        );
      }
      return;
    }

    final auth = context.read<AuthBloc>().state;
    if (auth is! AuthAuthenticated) return;

    context.read<CompanyBloc>().add(
          UpdateCompanyEvent(
            userId: auth.user.id,
            companyId: widget.company.id,
            name: _nameController.text.trim(),
            address: _addressController.text.trim().isEmpty
                ? null
                : _addressController.text.trim(),
            commercialRegNo: _commercialRegController.text.trim().isEmpty
                ? null
                : _commercialRegController.text.trim(),
            commercialRegisterURL: widget.company.commercialRegisterUrl,
            email: _emailController.text.trim(),
            cityId: _selectedCityId!,
            experienceYears: _parseExperienceYears(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CompanyBloc, CompanyState>(
      listener: (context, state) {
        if (state is CitiesLoaded) {
          setState(() {
            _cities = state.cities;
            _citiesLoading = false;
            _citiesError = null;
          });
        } else if (state is CompanyError && _cities.isEmpty && _citiesLoading) {
          setState(() {
            _citiesLoading = false;
            _citiesError = state.message;
          });
        } else if (state is CompanyUpdated &&
            state.company.id == widget.company.id) {
          final auth = context.read<AuthBloc>().state;
          if (auth is AuthAuthenticated) {
            context.read<CompanyGuardCubit>().refresh(auth.user.id);
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تحديث بيانات الشركة بنجاح')),
          );
          context.pop(state.company);
        } else if (state is CommercialRegisterUploaded &&
            state.company.id == widget.company.id) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم رفع السجل التجاري بنجاح')),
          );
        } else if (state is CompanyError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppTheme.dangerRed,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFA),
        appBar: AppBar(
          foregroundColor: ForgotPasswordConstants.tealDark,
          title: const Text('تعديل الشركة'),
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
                    widget.company.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: ForgotPasswordConstants.tealDark,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.company.isVerified
                        ? 'شركة موثّقة'
                        : 'بانتظار موافقة الإدارة',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: widget.company.isVerified
                              ? AppTheme.successGreen
                              : Colors.amber.shade800,
                        ),
                  ),
                  const SizedBox(height: 24),
                  AppTextField(
                    label: 'اسم الشركة *',
                    controller: _nameController,
                    prefixIcon: const Icon(
                      Icons.business_outlined,
                      color: ForgotPasswordConstants.tealPrimary,
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'يرجى إدخال اسم الشركة' : null,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'هاتف الشركة',
                    initialValue: widget.company.phone,
                    readOnly: true,
                    enabled: false,
                    prefixIcon: const Icon(Icons.phone_outlined),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'لا يمكن تغيير رقم الهاتف من التطبيق',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.gray500,
                        ),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'بريد الشركة *',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      color: ForgotPasswordConstants.tealPrimary,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'يرجى إدخال البريد الإلكتروني';
                      }
                      final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                      if (!regex.hasMatch(v.trim())) {
                        return 'يرجى إدخال بريد إلكتروني صحيح';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CityDropdownField(
                    cities: _cities,
                    isLoading: _citiesLoading,
                    errorMessage: _citiesError,
                    selectedCityId: _selectedCityId,
                    onRetry: _loadCities,
                    onChanged: (v) => setState(() => _selectedCityId = v),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'العنوان',
                    controller: _addressController,
                    maxLines: 2,
                    prefixIcon: const Icon(
                      Icons.location_on_outlined,
                      color: ForgotPasswordConstants.tealPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'رقم السجل التجاري',
                    controller: _commercialRegController,
                    prefixIcon: const Icon(
                      Icons.description_outlined,
                      color: ForgotPasswordConstants.tealPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'سنوات الخبرة',
                    controller: _experienceYearsController,
                    keyboardType: TextInputType.number,
                    prefixIcon: const Icon(
                      Icons.calendar_today_outlined,
                      color: ForgotPasswordConstants.tealPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'وصف الشركة',
                    controller: _descriptionController,
                    maxLines: 4,
                    prefixIcon: const Icon(
                      Icons.notes_outlined,
                      color: ForgotPasswordConstants.tealPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  CommercialRegisterPicker(
                    fileName: _registerFileName ??
                        (widget.company.commercialRegisterUrl != null
                            ? 'ملف مرفوع'
                            : null),
                    onPick: _pickRegisterFile,
                    onClear: () => setState(() => _registerFileName = null),
                  ),
                  const SizedBox(height: 24),
                  BlocBuilder<CompanyBloc, CompanyState>(
                    builder: (context, state) {
                      final loading = state is CompanyLoading ||
                          state is CommercialRegisterUploading;
                      return AppButton(
                        text: 'حفظ التعديلات',
                        onPressed: loading ? null : _submit,
                        isLoading: loading,
                        isFullWidth: true,
                        icon: Icons.save_outlined,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
