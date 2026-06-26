import 'package:flutter/material.dart';
import '../../domain/entities/service_category.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/l10n_helper.dart';
import '../../../../core/constants/app_strings.dart';

/// Service category card widget
/// Displays a service category in a horizontal list
class ServiceCategoryCard extends StatefulWidget {
  final ServiceCategory category;
  final VoidCallback? onTap;
  final bool isSelected;

  const ServiceCategoryCard({
    super.key,
    required this.category,
    this.onTap,
    this.isSelected = false,
  });

  @override
  State<ServiceCategoryCard> createState() => _ServiceCategoryCardState();
}

class _ServiceCategoryCardState extends State<ServiceCategoryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _tapController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _tapController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _tapController,
      curve: Curves.easeOutCubic,
    ));
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1, // 4-6 degrees in radians
    ).animate(CurvedAnimation(
      parent: _tapController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _tapController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _tapController.forward().then((_) {
      _tapController.reverse();
    });
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _handleTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedBuilder(
        animation: _tapController,
        builder: (context, child) {
          return Transform.scale(
            scale: widget.isSelected ? 1.03 : _scaleAnimation.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              margin: const EdgeInsets.only(right: 12),
              width: 100,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? AppColors.primary.withOpacity(0.1) // Light rose background when selected
                    : AppColors.secondary, // Soft beige background when not selected
                borderRadius: BorderRadius.circular(18),
                border: widget.isSelected
                    ? Border.all(
                        color: AppColors.primary.withOpacity(0.3), // Thin rose border
                        width: 1.0,
                      )
                    : null,
                boxShadow: widget.isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon - Dusty Rose when selected, Lavender when not (reduced opacity)
                  Transform.rotate(
                    angle: _rotationAnimation.value,
                    child: Icon(
                      _getIcon(widget.category.icon),
                      color: widget.isSelected
                          ? AppColors.primary // Dusty Rose when selected
                          : AppColors.accent.withOpacity(0.8), // Lavender with reduced opacity when not selected
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Text - increased contrast
                  Text(
                    widget.category.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Micro-label hint
                  Text(
                    _getServiceHint(context, widget.category.name),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary.withOpacity(0.7),
                          fontSize: 10,
                        ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'cleaning_services':
        return Icons.cleaning_services;
      case 'construction':
        return Icons.construction;
      default:
        return Icons.category;
    }
  }

  String _getServiceHint(BuildContext context, String categoryName) {
    final l10n = L10n.of(context);
    if (categoryName == AppStrings.dailyCleaning) {
      return l10n?.translate('dailyCleaningHint') ?? 'For quick visits';
    } else if (categoryName == AppStrings.weeklyCleaning) {
      return l10n?.translate('weeklyCleaningHint') ?? 'Regular cleaning';
    } else if (categoryName == AppStrings.deepCleaning) {
      return l10n?.translate('deepCleaningHint') ?? 'Comprehensive cleaning';
    } else if (categoryName == AppStrings.postConstruction) {
      return l10n?.translate('postConstructionHint') ?? 'After construction cleanup';
    }
    return '';
  }
}

