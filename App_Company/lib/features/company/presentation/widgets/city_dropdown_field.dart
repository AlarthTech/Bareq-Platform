import 'package:flutter/material.dart';

import '../../../../core/constants/forgot_password_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/city_entity.dart';

class CityDropdownField extends StatelessWidget {
  const CityDropdownField({
    super.key,
    required this.cities,
    required this.isLoading,
    required this.selectedCityId,
    required this.onChanged,
    required this.onRetry,
    this.errorMessage,
    this.label = 'المدينة',
    this.required = true,
  });

  final List<CityEntity> cities;
  final bool isLoading;
  final String? errorMessage;
  final int? selectedCityId;
  final ValueChanged<int?> onChanged;
  final VoidCallback onRetry;
  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const InputDecorator(
        decoration: InputDecoration(
          labelText: 'المدينة',
          prefixIcon: Icon(
            Icons.location_city_outlined,
            color: ForgotPasswordConstants.tealPrimary,
          ),
        ),
        child: Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (errorMessage != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            errorMessage!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.dangerRed,
                ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة تحميل المدن'),
          ),
        ],
      );
    }

    return DropdownButtonFormField<int>(
      value: selectedCityId,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(
          Icons.location_city_outlined,
          color: ForgotPasswordConstants.tealPrimary,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
      ),
      items: cities
          .map(
            (city) => DropdownMenuItem<int>(
              value: city.id,
              child: Text(city.name),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: (value) {
        if (!required) return null;
        if (value == null) {
          return 'يرجى اختيار المدينة';
        }
        return null;
      },
    );
  }
}
