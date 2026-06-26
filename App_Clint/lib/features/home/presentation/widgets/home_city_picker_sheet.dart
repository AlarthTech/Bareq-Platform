import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/l10n_helper.dart';
import '../../../auth/domain/entities/city.dart';
import '../cubit/home_state.dart';

/// Bottom sheet to pick a city or all cities on the home screen.
class HomeCityPickerSheet extends StatelessWidget {
  final List<City> cities;
  final City? selectedCity;
  final ValueChanged<City?> onCitySelected;

  const HomeCityPickerSheet({
    super.key,
    required this.cities,
    required this.selectedCity,
    required this.onCitySelected,
  });

  static Future<void> show({
    required BuildContext context,
    required List<City> cities,
    required City? selectedCity,
    required ValueChanged<City?> onCitySelected,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => HomeCityPickerSheet(
        cities: cities,
        selectedCity: selectedCity,
        onCitySelected: onCitySelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final isArabic = l10n?.isRTL ?? false;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final title = l10n?.translate('selectCity') ?? 'Select City';
    final allCitiesLabel =
        l10n?.translate('allCities') ?? HomeCityFilter.allCitiesLabel;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.65,
      ),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: _titleStyle(context, isArabic, isDark),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
              children: [
                _CityTile(
                  label: allCitiesLabel,
                  isSelected: selectedCity == null,
                  isArabic: isArabic,
                  isDark: isDark,
                  onTap: () {
                    onCitySelected(null);
                    Navigator.of(context).pop();
                  },
                ),
                const Divider(height: 8),
                ...cities.map(
                  (city) => _CityTile(
                    label: city.name,
                    isSelected: selectedCity?.id == city.id,
                    isArabic: isArabic,
                    isDark: isDark,
                    onTap: () {
                      onCitySelected(city);
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _titleStyle(BuildContext context, bool isArabic, bool isDark) {
    final base = Theme.of(context).textTheme.titleLarge?.copyWith(
          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        );
    if (isArabic) {
      return GoogleFonts.almarai(textStyle: base);
    }
    return base ?? const TextStyle();
  }
}

class _CityTile extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isArabic;
  final bool isDark;
  final VoidCallback onTap;

  const _CityTile({
    required this.label,
    required this.isSelected,
    required this.isArabic,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: isSelected
          ? AppColors.primary.withValues(alpha: 0.1)
          : null,
      leading: Icon(
        isSelected ? Icons.check_circle : Icons.location_city_outlined,
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
      ),
      title: Text(
        label,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check, color: AppColors.primary, size: 20)
          : null,
    );
  }
}
