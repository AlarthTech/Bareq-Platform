import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_session_notifier.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/localization/l10n_helper.dart';
import '../../../../core/widgets/common/app_top_bar.dart';
import '../../domain/entities/city.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/complete_profile_usecase.dart';
import '../../domain/usecases/get_cities_usecase.dart';
import '../widgets/phone_form_field.dart';

/// Mandatory phone + city gate after social login when the backend sets
/// [requiresProfileCompletion].
class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _saving = false;
  bool _loadingCities = true;
  List<City> _cities = [];
  City? _selectedCity;

  @override
  void initState() {
    super.initState();
    _loadCities();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadCities() async {
    final result = await sl<GetCitiesUseCase>()();
    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() => _loadingCities = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: AppColors.error,
          ),
        );
      },
      (cities) {
        setState(() {
          _cities = cities;
          _loadingCities = false;
        });
      },
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    if (_selectedCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            L10n.translate(context, 'cityRequired'),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    final result = await sl<CompleteProfileUseCase>()(
      phone: _phoneController.text.trim(),
      cityId: _selectedCity!.id,
    );

    if (!mounted) return;
    setState(() => _saving = false);

    final l10n = L10n.of(context);
    await result.fold(
      (failure) async {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: AppColors.error,
          ),
        );
      },
      (user) async {
        await sl<AuthRepository>().setRequiresProfileCompletion(false);
        sl<AuthSessionNotifier>().setLoggedIn(
          user,
          requiresProfileCompletion: false,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n?.translate('profileUpdated') ?? 'Profile updated',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        context.go(sl<AuthSessionNotifier>().postAuthHomeRoute);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppTopBar(
          title: l10n?.translate('completeYourProfile') ?? 'Complete your profile',
          showBackButton: false,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ProfileCompletionHint(
                  message: l10n?.translate('phoneRequiredForAccount') ??
                      'أضف رقم هاتفك واختر منطقتك لإكمال حسابك وعرض الشركات الأقرب إليك.',
                ),
                const SizedBox(height: 28),
                PhoneFormField(
                  controller: _phoneController,
                  enabled: !_saving,
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<City>(
                  value: _selectedCity,
                  decoration: InputDecoration(
                    labelText: L10n.translate(context, 'selectCity'),
                    prefixIcon: const Icon(Icons.location_city_outlined),
                    hintText: _loadingCities
                        ? L10n.translate(context, 'loadingCities')
                        : L10n.translate(context, 'selectCity'),
                  ),
                  items: _cities.map((city) {
                    return DropdownMenuItem<City>(
                      value: city,
                      child: Text(city.name),
                    );
                  }).toList(),
                  onChanged: _saving || _loadingCities
                      ? null
                      : (City? city) {
                          setState(() => _selectedCity = city);
                        },
                  validator: (value) {
                    if (value == null) {
                      return L10n.translate(context, 'cityRequired');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          l10n?.translate('save') ?? 'Save',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
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

class _ProfileCompletionHint extends StatelessWidget {
  const _ProfileCompletionHint({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            AppColors.gradientTop,
            AppColors.surfaceVariant,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primaryLight.withValues(alpha: 0.45),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.near_me_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  L10n.translate(context, 'completeYourProfile'),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.65,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
