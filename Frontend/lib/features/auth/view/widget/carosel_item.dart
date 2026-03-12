import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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

    return Container(
      width: 90,
      height: 90,
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1A1A1A)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF2A2A2A)
              : Colors.grey.shade300,
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
