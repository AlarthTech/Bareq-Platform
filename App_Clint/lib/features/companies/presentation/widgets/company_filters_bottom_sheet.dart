import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/localization/l10n_helper.dart';

/// Company Filters Bottom Sheet
/// Contains all filter options for companies in a scrollable bottom sheet
class CompanyFiltersBottomSheet extends StatefulWidget {
  final Set<String> selectedServices;
  final String? selectedLocation;
  final double minRating;
  final bool? verifiedOnly;

  final Function(Set<String>, String?, double, bool?) onApplyFilters;

  const CompanyFiltersBottomSheet({
    super.key,
    required this.selectedServices,
    required this.selectedLocation,
    required this.minRating,
    required this.verifiedOnly,
    required this.onApplyFilters,
  });

  @override
  State<CompanyFiltersBottomSheet> createState() => _CompanyFiltersBottomSheetState();
}

class _CompanyFiltersBottomSheetState extends State<CompanyFiltersBottomSheet> {
  late Set<String> _selectedServices;
  String? _selectedLocation;
  double _minRating = 0.0;
  bool? _verifiedOnly;

  // Available options
  final List<String> _services = [
    AppStrings.dailyCleaning,
    AppStrings.weeklyCleaning,
    AppStrings.deepCleaning,
    AppStrings.postConstruction,
  ];

  final List<String> _cities = [
    AppStrings.tripoli,
    AppStrings.benghazi,
    AppStrings.misrata,
    AppStrings.sabha,
  ];

  @override
  void initState() {
    super.initState();
    _selectedServices = Set<String>.from(widget.selectedServices);
    _selectedLocation = widget.selectedLocation;
    _minRating = widget.minRating;
    _verifiedOnly = widget.verifiedOnly;
  }

  void _clearAllFilters() {
    setState(() {
      _selectedServices.clear();
      _selectedLocation = null;
      _minRating = 0.0;
      _verifiedOnly = null;
    });
  }

  void _applyFilters() {
    widget.onApplyFilters(
      _selectedServices,
      _selectedLocation,
      _minRating,
      _verifiedOnly,
    );
    Navigator.of(context).pop();
  }

  bool get _hasActiveFilters {
    return _selectedServices.isNotEmpty ||
        _selectedLocation != null ||
        _minRating > 0.0 ||
        _verifiedOnly != null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n?.translate('filters') ?? AppStrings.filters,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                if (_hasActiveFilters)
                  TextButton(
                    onPressed: _clearAllFilters,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                    child: Text(l10n?.translate('clearFilters') ?? AppStrings.clearFilters),
                  ),
              ],
            ),
          ),
          // Filters Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Services Filter
                  _buildServiceFilter(),
                  const SizedBox(height: 24),
                  // Location Filter
                  _buildLocationFilter(),
                  const SizedBox(height: 24),
                  // Rating Filter
                  _buildRatingFilter(),
                  const SizedBox(height: 24),
                  // Verified Filter
                  _buildVerifiedFilter(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          // Apply Button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: AppColors.border.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _applyFilters,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(0, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text(
                    l10n?.translate('applyFilters') ?? AppStrings.applyFilters,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceFilter() {
    final l10n = L10n.of(context);
    return _buildFilterSection(
      title: l10n?.translate('service') ?? AppStrings.service,
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: _services.map((service) {
          final isSelected = _selectedServices.contains(service);
          return _buildFilterChip(
            label: service,
            isSelected: isSelected,
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedServices.remove(service);
                } else {
                  _selectedServices.add(service);
                }
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLocationFilter() {
    final l10n = L10n.of(context);
    return _buildFilterSection(
      title: l10n?.translate('location') ?? AppStrings.location,
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: _cities.map((city) {
          final isSelected = _selectedLocation == city;
          return _buildFilterChip(
            label: city,
            isSelected: isSelected,
            onTap: () {
              setState(() {
                _selectedLocation = isSelected ? null : city;
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRatingFilter() {
    final l10n = L10n.of(context);
    return _buildFilterSection(
      title: l10n?.translate('rating') ?? AppStrings.rating,
      child: Row(
        children: [
          ...List.generate(5, (index) {
            final rating = index + 1.0;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _minRating = _minRating == rating ? 0.0 : rating;
                });
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Icon(
                  _minRating >= rating ? Icons.star : Icons.star_border,
                  color: _minRating >= rating ? AppColors.primary : AppColors.border,
                  size: 32,
                ),
              ),
            );
          }),
          const SizedBox(width: 8),
          Builder(
            builder: (context) {
              final l10n = L10n.of(context);
              return Text(
                _minRating > 0 ? '${_minRating.toStringAsFixed(1)} ${l10n?.translate('andAbove') ?? 'and above'}' : '',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVerifiedFilter() {
    final l10n = L10n.of(context);
    return _buildFilterSection(
      title: l10n?.translate('verification') ?? AppStrings.verification,
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _buildFilterChip(
            label: l10n?.translate('verifiedOnly') ?? AppStrings.verifiedOnly,
            isSelected: _verifiedOnly == true,
            onTap: () {
              setState(() {
                _verifiedOnly = _verifiedOnly == true ? null : true;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection({
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : AppColors.secondary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.border.withOpacity(0.3),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
        ),
      ),
    );
  }
}






