import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:UniSync/app/theme/app_colors.dart';

class CarouselItem extends StatelessWidget {
  final String imagePath;

  const CarouselItem({
    super.key,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    // Check if image is SVG or PNG/other format
    final isSvg = imagePath.toLowerCase().endsWith('.svg');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 90,
      height: 90,
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: isSvg
              ? SvgPicture.asset(
                  imagePath,
                  fit: BoxFit.contain,
                )
              : Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                ),
        ),
      ),
    );
  }
}
