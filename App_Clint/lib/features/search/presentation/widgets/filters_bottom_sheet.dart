import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/localization/l10n_helper.dart';
import '../../../../core/utils/western_numerals.dart';
import '../../../../core/utils/language_lookup.dart';
import '../models/worker_filter_state.dart';

/// Worker filters: booking date, city, rating, experience, nationality, language.
class FiltersBottomSheet extends StatefulWidget {
  const FiltersBottomSheet({
    super.key,
    required this.initialFilters,
    required this.cityOptions,
    required this.nationalityOptions,
    required this.languageOptions,
    required this.onApplyFilters,
    this.resultCount,
  });

  final WorkerFilterState initialFilters;
  final List<String> cityOptions;
  final List<String> nationalityOptions;
  final List<LanguageFilterOption> languageOptions;
  final void Function(WorkerFilterState filters) onApplyFilters;
  final int? resultCount;

  @override
  State<FiltersBottomSheet> createState() => _FiltersBottomSheetState();
}

class _FiltersBottomSheetState extends State<FiltersBottomSheet> {
  late DateTime? _bookingDate;
  late String? _selectedCity;
  late double _minRating;
  late int _minExperience;
  late Set<String> _selectedNationalities;
  late Set<String> _selectedLanguages;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    final f = widget.initialFilters;
    _bookingDate = f.bookingDate;
    _selectedCity = f.selectedCity;
    _minRating = f.minRating;
    _minExperience = f.minExperience;
    _selectedNationalities = Set<String>.from(f.selectedNationalities);
    _selectedLanguages = Set<String>.from(f.selectedLanguages);
    _checkForChanges();
  }

  WorkerFilterState get _current => WorkerFilterState(
        bookingDate: _bookingDate,
        selectedCity: _selectedCity,
        minRating: _minRating,
        minExperience: _minExperience,
        selectedNationalities: _selectedNationalities,
        selectedLanguages: _selectedLanguages,
      );

  void _checkForChanges() {
    final a = widget.initialFilters;
    final b = _current;
    _hasChanges =
        !_sameDate(a.bookingDate, b.bookingDate) ||
        a.selectedCity != b.selectedCity ||
        a.minRating != b.minRating ||
        a.minExperience != b.minExperience ||
        !_setEquals(a.selectedNationalities, b.selectedNationalities) ||
        !_setEquals(a.selectedLanguages, b.selectedLanguages);
  }

  bool _sameDate(DateTime? a, DateTime? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _setEquals(Set<String> a, Set<String> b) {
    if (a.length != b.length) return false;
    for (final item in a) {
      if (!b.contains(item)) return false;
    }
    return true;
  }

  void _clearAllFilters() {
    setState(() {
      _bookingDate = null;
      _selectedCity = null;
      _minRating = 0;
      _minExperience = 0;
      _selectedNationalities.clear();
      _selectedLanguages.clear();
      _checkForChanges();
    });
  }

  void _applyFilters() {
    widget.onApplyFilters(_current);
    Navigator.of(context).pop();
  }

  bool get _hasActiveFilters => _current.hasActiveFilters;

  Future<void> _pickBookingDate() async {
    final l10n = L10n.of(context);
    final locale = l10n?.locale ?? const Locale('en');
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _bookingDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      locale: locale,
      helpText: l10n?.translate('filterBookingDate') ?? 'Booking date',
    );
    if (picked != null) {
      setState(() {
        _bookingDate = DateTime(picked.year, picked.month, picked.day);
        _checkForChanges();
      });
    }
  }

  String _formatDate(BuildContext context) {
    if (_bookingDate == null) {
      return L10n.of(context)?.translate('selectDate') ?? AppStrings.selectDate;
    }
    final locale = L10n.of(context)?.locale.toString() ?? 'en';
    return WesternNumerals.normalize(
      DateFormat.yMMMd(locale).format(_bookingDate!),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
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
                    child: Text(
                      l10n?.translate('clearFilters') ?? AppStrings.clearFilters,
                    ),
                  ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildBookingDateFilter(context),
                  const SizedBox(height: 24),
                  _buildCityFilter(context),
                  const SizedBox(height: 24),
                  _buildRatingFilter(context),
                  const SizedBox(height: 24),
                  _buildExperienceFilter(context),
                  const SizedBox(height: 24),
                  _buildNationalityFilter(context),
                  const SizedBox(height: 24),
                  _buildLanguageFilter(context),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: AppColors.border.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: _AnimatedApplyButton(
                  onPressed: _hasChanges ? _applyFilters : null,
                  resultCount: widget.resultCount,
                  isEnabled: _hasChanges,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingDateFilter(BuildContext context) {
    final l10n = L10n.of(context);
    return _buildFilterSection(
      title: l10n?.translate('filterBookingDate') ?? 'Booking date',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n?.translate('filterBookingDateHint') ??
                'Show workers available on this day',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pickBookingDate,
            icon: const Icon(Icons.calendar_today_outlined),
            label: Text(_formatDate(context)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              alignment: AlignmentDirectional.centerStart,
            ),
          ),
          if (_bookingDate != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _bookingDate = null;
                    _checkForChanges();
                  });
                },
                child: Text(l10n?.translate('clearDate') ?? 'Clear date'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCityFilter(BuildContext context) {
    final l10n = L10n.of(context);
    if (widget.cityOptions.isEmpty) {
      return _buildFilterSection(
        title: l10n?.translate('city') ?? AppStrings.city,
        child: Text(
          l10n?.translate('noCitiesAvailable') ?? 'No cities available',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      );
    }
    return _buildFilterSection(
      title: l10n?.translate('city') ?? AppStrings.city,
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: widget.cityOptions.map((city) {
          final isSelected = _selectedCity == city;
          return _buildFilterChip(
            label: city,
            isSelected: isSelected,
            onTap: () {
              setState(() {
                _selectedCity = isSelected ? null : city;
                _checkForChanges();
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNationalityFilter(BuildContext context) {
    final l10n = L10n.of(context);
    if (widget.nationalityOptions.isEmpty) {
      return const SizedBox.shrink();
    }
    return _buildFilterSection(
      title: l10n?.translate('nationality') ?? 'Nationality',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: widget.nationalityOptions.map((nation) {
          final isSelected = _selectedNationalities.contains(nation);
          return _buildFilterChip(
            label: nation,
            isSelected: isSelected,
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedNationalities.remove(nation);
                } else {
                  _selectedNationalities.add(nation);
                }
                _checkForChanges();
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLanguageFilter(BuildContext context) {
    final l10n = L10n.of(context);
    if (widget.languageOptions.isEmpty) {
      return const SizedBox.shrink();
    }
    return _buildFilterSection(
      title: l10n?.translate('language') ?? AppStrings.language,
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: widget.languageOptions.map((option) {
          final isSelected = _selectedLanguages.contains(option.filterId);
          return _buildFilterChip(
            label: option.name,
            isSelected: isSelected,
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedLanguages.remove(option.filterId);
                } else {
                  _selectedLanguages.add(option.filterId);
                }
                _checkForChanges();
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRatingFilter(BuildContext context) {
    final l10n = L10n.of(context);
    return _buildFilterSection(
      title: l10n?.translate('minimumRating') ?? AppStrings.minimumRating,
      child: Row(
        children: [
          const Icon(Icons.star, size: 20, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Slider(
              value: _minRating,
              min: 0,
              max: 5,
              divisions: 10,
              activeColor: AppColors.primary,
              onChanged: (value) {
                setState(() {
                  _minRating = value;
                  _checkForChanges();
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _minRating > 0 ? _minRating.toStringAsFixed(1) : '0.0',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceFilter(BuildContext context) {
    final l10n = L10n.of(context);
    return _buildFilterSection(
      title: l10n?.translate('experience') ?? AppStrings.experience,
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [1, 2, 3, 5, 7, 10].map((years) {
          final isSelected = _minExperience == years;
          return _buildFilterChip(
            label: '$years+ ${l10n?.translate('years') ?? AppStrings.years}',
            isSelected: isSelected,
            onTap: () {
              setState(() {
                _minExperience = isSelected ? 0 : years;
                _checkForChanges();
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFilterSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
          color:
              isSelected
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : AppColors.secondary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: isSelected ? 1.5 : 0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                  ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              const Icon(Icons.check, size: 16, color: AppColors.primary),
            ],
          ],
        ),
      ),
    );
  }
}

class _AnimatedApplyButton extends StatefulWidget {
  const _AnimatedApplyButton({
    required this.onPressed,
    this.resultCount,
    required this.isEnabled,
  });

  final VoidCallback? onPressed;
  final int? resultCount;
  final bool isEnabled;

  @override
  State<_AnimatedApplyButton> createState() => _AnimatedApplyButtonState();
}

class _AnimatedApplyButtonState extends State<_AnimatedApplyButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return GestureDetector(
      onTapDown: widget.isEnabled ? (_) => _controller.forward() : null,
      onTapUp: widget.isEnabled ? (_) => _controller.reverse() : null,
      onTapCancel: widget.isEnabled ? () => _controller.reverse() : null,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: ElevatedButton(
          onPressed: widget.onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                widget.isEnabled
                    ? AppColors.primary
                    : AppColors.border.withValues(alpha: 0.3),
            foregroundColor:
                widget.isEnabled ? Colors.white : AppColors.textSecondary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            minimumSize: const Size(0, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n?.translate('applyFilters') ?? AppStrings.applyFilters,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (widget.resultCount != null && widget.isEnabled) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${widget.resultCount}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
