import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/localization/l10n_helper.dart';
import '../../../legal/presentation/registration_legal_read_tracker.dart';
import '../../../legal/presentation/widgets/legal_agreement_checkbox.dart';
import '../../domain/entities/city.dart';
import '../../domain/usecases/get_cities_usecase.dart';
import '../../domain/usecases/register_customer_usecase.dart';
import '../../domain/usecases/save_user_usecase.dart';
import '../cubit/registration_cubit.dart';
import '../cubit/registration_state.dart';
import '../widgets/phone_form_field.dart';
import '../widgets/social_auth_scope.dart';
import '../widgets/social_login_buttons.dart';

/// Registration Screen
/// Allows users to create a new account
/// Follows Clean Architecture - UI only communicates via state management
class RegistrationScreen extends StatelessWidget {
  const RegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SocialAuthScope(
      child: BlocProvider(
        create: (context) => RegistrationCubit(
          getCitiesUseCase: sl<GetCitiesUseCase>(),
          registerCustomerUseCase: sl<RegisterCustomerUseCase>(),
          saveUserUseCase: sl<SaveUserUseCase>(),
        )..loadCities(),
        child: const _RegistrationScreenContent(),
      ),
    );
  }
}

class _RegistrationScreenContent extends StatefulWidget {
  const _RegistrationScreenContent();

  @override
  State<_RegistrationScreenContent> createState() =>
      _RegistrationScreenContentState();
}

class _RegistrationScreenContentState
    extends State<_RegistrationScreenContent> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToLegal = false;
  final _legalReadTracker = RegistrationLegalReadTracker();
  City? _selectedCity;

  @override
  void dispose() {
    _legalReadTracker.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegistration(BuildContext context) {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(L10n.translate(context, 'cityRequired')),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (!_legalReadTracker.canAgree) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(L10n.translate(context, 'legalMustReadBothDocuments')),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (!_agreedToLegal) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(L10n.translate(context, 'legalAgreeRequired')),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    context.read<RegistrationCubit>().registerCustomer(
          fullName: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          cityId: _selectedCity!.id,
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final isRTL = l10n?.isRTL ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          L10n.translate(context, 'createAccount'),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<RegistrationCubit, RegistrationState>(
          listener: (context, state) {
            if (state is RegistrationSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      L10n.translate(context, 'registrationSuccessMessage')),
                  backgroundColor: AppColors.success,
                ),
              );
              Future.delayed(const Duration(seconds: 1), () {
                if (context.mounted) {
                  context.go(AppStrings.routeLogin);
                }
              });
            } else if (state is RegistrationError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
          builder: (context, state) {
            final isLoadingCities = state is RegistrationLoadingCities;
            final isLoadingRegistration = state is RegistrationRegistering;
            final cities = state is RegistrationCitiesLoaded ? state.cities : [];

            return SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Brand hero illustration
                    Image.asset(
                      AppAssets.bareqRegistrationHero,
                      width: double.infinity,
                      height: 240,
                      fit: BoxFit.contain,
                    )
                        .animate()
                        .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic)
                        .scale(duration: 280.ms, curve: Curves.easeOutCubic),

                    const SizedBox(height: 16),
                    Text(
                        L10n.translate(context, 'createAccountSubtitle'),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      )
                        .animate(delay: 50.ms)
                        .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic),

                    const SizedBox(height: 24),

                    const SocialLoginButtons(),

                    const SizedBox(height: 28),

                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: L10n.translate(context, 'fullName'),
                        hintText: L10n.translate(context, 'fullNameHint'),
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                      textDirection:
                          isRTL ? TextDirection.rtl : TextDirection.ltr,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return L10n.translate(context, 'nameRequired');
                        }
                        if (value.trim().length < 2) {
                          return L10n.translate(context, 'nameTooShort');
                        }
                        return null;
                      },
                    )
                        .animate(delay: 150.ms)
                        .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: L10n.translate(context, 'email'),
                        hintText: L10n.translate(context, 'emailHint'),
                        prefixIcon: const Icon(Icons.email_outlined),
                      ),
                      textDirection:
                          isRTL ? TextDirection.rtl : TextDirection.ltr,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return L10n.translate(context, 'emailRequired');
                        }
                        if (!value.contains('@') || !value.contains('.')) {
                          return L10n.translate(context, 'emailInvalid');
                        }
                        return null;
                      },
                    )
                        .animate(delay: 200.ms)
                        .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic),

                    const SizedBox(height: 16),

                    PhoneFormField(
                      controller: _phoneController,
                    )
                        .animate(delay: 250.ms)
                        .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic),

                    const SizedBox(height: 16),

                    DropdownButtonFormField<City>(
                      value: _selectedCity,
                      decoration: InputDecoration(
                        labelText: L10n.translate(context, 'selectCity'),
                        prefixIcon: const Icon(Icons.location_city_outlined),
                        hintText: isLoadingCities
                            ? L10n.translate(context, 'loadingCities')
                            : L10n.translate(context, 'selectCity'),
                      ),
                      items: cities.map((city) {
                        return DropdownMenuItem<City>(
                          value: city,
                          child: Text(city.name),
                        );
                      }).toList(),
                      onChanged: isLoadingCities
                          ? null
                          : (City? city) {
                              setState(() {
                                _selectedCity = city;
                              });
                            },
                      validator: (value) {
                        if (value == null) {
                          return L10n.translate(context, 'cityRequired');
                        }
                        return null;
                      },
                    )
                        .animate(delay: 300.ms)
                        .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: L10n.translate(context, 'password'),
                        hintText: L10n.translate(context, 'passwordHint'),
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      textDirection:
                          isRTL ? TextDirection.rtl : TextDirection.ltr,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return L10n.translate(context, 'passwordRequired');
                        }
                        if (value.length < 6) {
                          return L10n.translate(context, 'passwordTooShort');
                        }
                        return null;
                      },
                    )
                        .animate(delay: 350.ms)
                        .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText:
                            L10n.translate(context, 'confirmPassword'),
                        hintText:
                            L10n.translate(context, 'confirmPasswordHint'),
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                      textDirection:
                          isRTL ? TextDirection.rtl : TextDirection.ltr,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return L10n.translate(
                              context, 'confirmPasswordRequired');
                        }
                        if (value != _passwordController.text) {
                          return L10n.translate(
                              context, 'passwordsDoNotMatch');
                        }
                        return null;
                      },
                    )
                        .animate(delay: 400.ms)
                        .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic),

                    LegalAgreementCheckbox(
                      readTracker: _legalReadTracker,
                      value: _agreedToLegal,
                      onChanged: (value) {
                        setState(() {
                          _agreedToLegal = value ?? false;
                        });
                      },
                    )
                        .animate(delay: 420.ms)
                        .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic),

                    const SizedBox(height: 24),

                    ElevatedButton(
                      onPressed: (isLoadingRegistration || isLoadingCities)
                          ? null
                          : () => _handleRegistration(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: isLoadingRegistration
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              L10n.translate(context, 'register'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    )
                        .animate(delay: 450.ms)
                        .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic)
                        .scale(duration: 280.ms, curve: Curves.easeOutCubic),

                    const SizedBox(height: 24),

                    Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            L10n.translate(context, 'alreadyHaveAccount'),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () => context.go(AppStrings.routeLogin),
                            child: Text(
                              L10n.translate(context, 'login'),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      )
                        .animate(delay: 500.ms)
                        .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
