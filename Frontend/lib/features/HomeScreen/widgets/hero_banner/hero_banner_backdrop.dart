import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:UniSync/features/HomeScreen/models/hero_banner_style.dart';

/// Texture layer sitting between the gradient and the artwork.
///
/// Everything here is painted in [foreground] (white) at 6–9% alpha. Keeping
/// the texture monochrome-on-alpha is what lets one backdrop sit over any
/// palette without being re-tuned per color. This is texture, not content: if
/// you can read it as a picture, it's too strong.
class HeroBannerBackdrop extends StatelessWidget {
  const HeroBannerBackdrop({
    super.key,
    required this.backdrop,
    this.foreground = Colors.white,
  });

  final HeroBannerBackdropStyle backdrop;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final painter = switch (backdrop) {
      HeroBannerBackdropStyle.ruled => _RuledPainter(foreground),
      HeroBannerBackdropStyle.sunburst => _SunburstPainter(foreground),
      HeroBannerBackdropStyle.rings => _RingsPainter(foreground),
      HeroBannerBackdropStyle.none => null,
    };

    if (painter == null) return const SizedBox.shrink();

    return Positioned.fill(
      child: IgnorePointer(
        child: RepaintBoundary(
          child: CustomPaint(painter: painter),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  RULED  — a sheet of notebook paper laid under the banner
// ─────────────────────────────────────────────────────────────────────────────

class _RuledPainter extends CustomPainter {
  _RuledPainter(this.foreground);

  final Color foreground;

  /// The whole sheet is rotated a hair off true. Perfectly horizontal rules
  /// read as UI chrome — dividers someone forgot to remove. A slight tilt
  /// reads as a physical sheet of paper sitting under the banner.
  static const _tilt = -0.06;
  static const _lineGap = 13.0;

  /// Every 12th line is a heavier "heading" bar, so the texture has the
  /// rhythm of a written page rather than of graph paper.
  static const _headingEvery = 12;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);

    // Rotate about the center and overdraw well past the edges, so the tilt
    // never exposes an uncovered corner.
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(_tilt);
    canvas.translate(-size.width / 2, -size.height / 2);

    final overscan = size.height * 0.5 + 40;
    final rule = Paint()
      ..color = foreground.withValues(alpha: 0.07)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final heading = Paint()
      ..color = foreground.withValues(alpha: 0.09)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;

    var index = 0;
    // Ragged right edges: each rule stops a little short, by a repeating
    // pattern rather than at random, so repaints stay stable.
    const ragged = [0.86, 0.71, 0.93, 0.64, 0.80, 0.55];

    for (var y = -overscan; y < size.height + overscan; y += _lineGap) {
      final isHeading = index % _headingEvery == 0;
      final end = size.width * ragged[index % ragged.length];
      canvas.drawLine(
        Offset(-overscan, y),
        Offset(end, y),
        isHeading ? heading : rule,
      );
      index++;
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_RuledPainter old) => old.foreground != foreground;
}

// ─────────────────────────────────────────────────────────────────────────────
//  SUNBURST  — wedges from an off-center origin
// ─────────────────────────────────────────────────────────────────────────────

class _SunburstPainter extends CustomPainter {
  _SunburstPainter(this.foreground);

  final Color foreground;

  static const _wedges = 22;

  /// Off-center, high and to the right, so the rays sweep diagonally across
  /// the banner instead of radiating symmetrically out of the middle.
  static const _originX = 0.74;
  static const _originY = 0.12;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);

    final origin = Offset(size.width * _originX, size.height * _originY);
    // Long enough to clear the far corner from an off-center origin.
    final radius = size.width + size.height;

    final paint = Paint()
      ..color = foreground.withValues(alpha: 0.065)
      ..style = PaintingStyle.fill;

    // A full turn split into 2x the wedge count, drawing every other slot:
    // each lit wedge is exactly as wide as the gap beside it, so the burst
    // reads evenly instead of as thick spokes with hairline gaps.
    final step = (2 * math.pi) / (_wedges * 2);

    for (var i = 0; i < _wedges; i++) {
      final start = step * i * 2;
      final path = Path()
        ..moveTo(origin.dx, origin.dy)
        ..lineTo(
          origin.dx + radius * math.cos(start),
          origin.dy + radius * math.sin(start),
        )
        ..lineTo(
          origin.dx + radius * math.cos(start + step),
          origin.dy + radius * math.sin(start + step),
        )
        ..close();
      canvas.drawPath(path, paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_SunburstPainter old) => old.foreground != foreground;
}

// ─────────────────────────────────────────────────────────────────────────────
//  RINGS  — a motif enlarged past the point of being a logo
// ─────────────────────────────────────────────────────────────────────────────

class _RingsPainter extends CustomPainter {
  _RingsPainter(this.foreground);

  final Color foreground;

  static const _originX = 0.82;
  static const _originY = 0.5;
  static const _ringGap = 26.0;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);

    final center = Offset(size.width * _originX, size.height * _originY);
    final paint = Paint()..style = PaintingStyle.stroke;

    // Deliberately oversized and centered off the right edge: the rings bleed
    // out of frame, so they read as an enlarged detail rather than a badge
    // someone dropped onto the banner.
    final maxRadius = size.width * 1.1;

    var index = 0;
    for (var r = _ringGap; r < maxRadius; r += _ringGap) {
      // Alternating weights give the rings a groove-like rhythm; a single
      // uniform weight reads as a target.
      paint
        ..strokeWidth = index.isEven ? 2 : 8
        ..color = foreground.withValues(alpha: index.isEven ? 0.075 : 0.055);
      canvas.drawCircle(center, r, paint);
      index++;
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_RingsPainter old) => old.foreground != foreground;
}
