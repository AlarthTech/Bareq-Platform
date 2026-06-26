import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';

class LoadingShimmerWidget extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  
  const LoadingShimmerWidget({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });
  
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppTheme.gray200,
      highlightColor: AppTheme.gray100,
      child: Container(
        width: width ?? double.infinity,
        height: height ?? 20,
        decoration: BoxDecoration(
          color: AppTheme.gray300,
          borderRadius: borderRadius ?? BorderRadius.circular(AppTheme.radiusSmall),
        ),
      ),
    );
  }
}
