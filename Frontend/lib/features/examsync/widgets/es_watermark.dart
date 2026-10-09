import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:UniSync/app/providers.dart';

/// Faint, tiled watermark with the student's name and email over paid
/// content. Screenshots are already blocked; this makes a photo of the
/// screen traceable to the account it came from, which discourages sharing
/// without getting in the way of reading.
class EsWatermark extends ConsumerWidget {
  const EsWatermark({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final parts = [
      user?.name.trim() ?? '',
      user?.emailId.trim() ?? '',
    ].where((p) => p.isNotEmpty);
    if (parts.isEmpty) return child;
    final label = parts.join(' · ');
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: ExcludeSemantics(
              child: RepaintBoundary(
                child: CustomPaint(painter: _WatermarkPainter(label)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _WatermarkPainter extends CustomPainter {
  _WatermarkPainter(this.label)
      : _text = TextPainter(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0x14FFFFFF),
            ),
          ),
          textDirection: TextDirection.ltr,
          maxLines: 1,
        )..layout();

  final String label;
  final TextPainter _text;

  static const double _angle = -math.pi / 7;
  static const double _gapX = 56;
  static const double _gapY = 96;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(_angle);
    // Cover the rotated viewport: its diagonal bounds every rotation.
    final reach =
        math.sqrt(size.width * size.width + size.height * size.height);
    final stepX = _text.width + _gapX;
    var row = 0;
    for (var y = -reach / 2; y < reach / 2; y += _gapY, row++) {
      final offset = row.isOdd ? stepX / 2 : 0.0;
      for (var x = -reach / 2 - offset; x < reach / 2; x += stepX) {
        _text.paint(canvas, Offset(x, y));
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_WatermarkPainter old) => old.label != label;
}
