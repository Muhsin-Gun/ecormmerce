import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

class SkeletonLoader extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = AppTheme.radiusSmall,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Premium production-level gradients instead of plain grey
    final baseColor = isDark 
        ? AppColors.darkNavy.withOpacity(0.8) 
        : Colors.indigo[50]!;
    final highlightColor = isDark 
        ? AppColors.electricPurple.withOpacity(0.2) 
        : Colors.white;

    return Container(
      margin: margin,
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        period: const Duration(milliseconds: 1500),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
              width: 1,
            ),
          ),
        ),
      ),
    );
  }

  static Widget productCard() {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonLoader(width: 160, height: 160, borderRadius: AppTheme.radiusMedium),
          const SizedBox(height: 8),
          const SkeletonLoader(width: 80, height: 12),
          const SizedBox(height: 4),
          const SkeletonLoader(width: 120, height: 16),
          const SizedBox(height: 8),
          const SkeletonLoader(width: 60, height: 20),
        ],
      ),
    );
  }
}
