import 'package:flutter/material.dart';
import '../../constants/app_assets.dart';
import '../../constants/app_colors.dart';

/// Compact Bareq brand mark for app bars — uses the official logo asset.
class BareqBrandMark extends StatelessWidget {
  const BareqBrandMark({
    super.key,
    this.size = 44,
    this.showLabel = true,
  });

  final double size;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          AppAssets.bareqLogoTopbar,
          width: size,
          height: size,
          fit: BoxFit.contain,
        ),
        if (showLabel) ...[
          SizedBox(width: size * 0.22),
          Text(
            'Bareq',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                  fontSize: size * 0.38,
                ),
          ),
        ],
      ],
    );
  }
}
