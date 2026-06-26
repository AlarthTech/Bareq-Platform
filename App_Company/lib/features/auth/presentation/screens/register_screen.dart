import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/animation_constants.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/forgot_password_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/storage/onboarding_prefill_storage.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../company/domain/entities/city_entity.dart';
import '../../../company/presentation/bloc/company_bloc.dart';
import '../../../company/presentation/bloc/company_event.dart';
import '../../../company/presentation/bloc/company_state.dart';
import '../../../company/presentation/widgets/city_dropdown_field.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  int? _selectedCityId;
  List<CityEntity> _cities = [];
  bool _citiesLoading = true;
  String? _citiesError;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _loadCities() {
    setState(() {
      _citiesLoading = true;
      _citiesError = null;
    });
    context.read<CompanyBloc>().add(const GetAllCitiesEvent());
  }

  void _handleRegister() {
    if (!_formKey.currentState!.validate()) return;

    OnboardingPrefillStorage.setCityId(_selectedCityId);

    context.read<AuthBloc>().add(
          RegisterEvent(
            fullName: _fullNameController.text.trim(),
            phone: _phoneController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
            cityId: _selectedCityId,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CompanyBloc>()..add(const GetAllCitiesEvent()),
      child: MultiBlocListener(
        listeners: [
          BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppTheme.dangerRed,
                  ),
                );
              }
            },
          ),
          BlocListener<CompanyBloc, CompanyState>(
            listener: (context, state) {
              if (state is CitiesLoaded) {
                setState(() {
                  _cities = state.cities;
                  _citiesLoading = false;
                  _citiesError = null;
                });
              } else if (state is CompanyError && _cities.isEmpty) {
                setState(() {
                  _citiesLoading = false;
                  _citiesError = state.message;
                });
              }
            },
          ),
        ],
        child: Scaffold(
          appBar: AppBar(
            foregroundColor: ForgotPasswordConstants.tealDark,
            title: Text('إنشاء حساب جديد')
                .animate()
                .fadeIn(
                  duration: AnimationConstants.fadeIn,
                  curve: AnimationConstants.fadeInCurve,
                ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacing24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppTheme.spacing16),
                    AppTextField(
                      label: 'الاسم الكامل',
                      hint: 'أدخل الاسم الكامل',
                      controller: _fullNameController,
                      prefixIcon: const Icon(Icons.person_outline),
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'يرجى إدخال الاسم الكامل';
                        }
                        if (value.trim().length > 200) {
                          return 'الاسم طويل جداً';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppTheme.spacing20),
                    AppTextField(
                      label: 'البريد الإلكتروني',
                      hint: 'owner@company.com',
                      controller: _emailController,
                      prefixIcon: const Icon(Icons.email_outlined),
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
                    AppTextField(
                      label: 'رقم الهاتف',
                      hint: '0912345678',
                      controller: _phoneController,
                      prefixIcon: const Icon(Icons.phone_outlined),
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
                      label: 'كلمة المرور',
                      hint: '6 أحرف على الأقل',
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'يرجى إدخال كلمة المرور';
                        }
                        if (value.length < 6) {
                          return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppTheme.spacing20),
                    AppTextField(
                      label: 'تأكيد كلمة المرور',
                      hint: 'أعد إدخال كلمة المرور',
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () => setState(
                          () => _obscureConfirmPassword = !_obscureConfirmPassword,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'يرجى تأكيد كلمة المرور';
                        }
                        if (value != _passwordController.text) {
                          return 'كلمة المرور غير متطابقة';
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
                      label: 'المدينة (اختياري)',
                      required: false,
                    ),
                    const SizedBox(height: AppTheme.spacing32),
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        return AppButton(
                          text: 'إنشاء حساب',
                          onPressed: state is AuthLoading ? null : _handleRegister,
                          isLoading: state is AuthLoading,
                          isFullWidth: true,
                          icon: Icons.person_add,
                        );
                      },
                    ),
                    const SizedBox(height: AppTheme.spacing24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'لديك حساب بالفعل؟ ',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: () => context.go(AppRoutes.login),
                          child: const Text('تسجيل الدخول'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
