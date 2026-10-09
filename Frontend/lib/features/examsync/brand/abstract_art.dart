import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:UniSync/features/examsync/theme/es_theme.dart';
import 'package:UniSync/features/examsync/utils/hash.dart';

/// Deterministic Bauhaus-style art for a subject: the tone's face colour plus
/// one of five compositions, picked by `hash(code + "::art") % 5`.
class AbstractArt extends StatelessWidget {
  const AbstractArt({super.key, required this.courseCode, this.tone});

  final String courseCode;
  final EsTone? tone;

  @override
  Widget build(BuildContext context) {
    final t = tone ?? EsTone.forCode(courseCode);
    final variant = fnv1a32('$courseCode::art') % 5;
    return ExcludeSemantics(
      child: ClipRect(
        child: CustomPaint(
          painter: _ArtPainter(t, variant),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _ArtPainter extends CustomPainter {
  _ArtPainter(this.tone, this.variant);

  final EsTone tone;
  final int variant;

  /// Shapes use black ink (or white on dark faces where black would vanish
  /// into the edge colours) and the tone's pop colour.
  Color get ink => Colors.black;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = tone.face);
    switch (variant) {
      case 0:
        _sunAndHorizon(canvas, size);
      case 1:
        _quarterArcs(canvas, size);
      case 2:
        _stackedBlocks(canvas, size);
      case 3:
        _orbit(canvas, size);
      default:
        _triangleAndStripes(canvas, size);
    }
  }

  void _sunAndHorizon(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    final horizon = h * 0.62;
    canvas.drawCircle(
      Offset(w * 0.55, horizon),
      math.min(w, h) * 0.32,
      Paint()..color = tone.pop,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, horizon, w, h - horizon),
      Paint()..color = ink,
    );
    final stripe = Paint()..color = tone.face;
    for (var i = 0; i < 3; i++) {
      final y = horizon + (h - horizon) * (0.2 + i * 0.25);
      canvas.drawRect(Rect.fromLTWH(0, y, w, 2.5), stripe);
    }
  }

  void _quarterArcs(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    final r = math.min(w, h) * 0.55;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(0, h), radius: r),
      -math.pi / 2,
      math.pi / 2,
      true,
      Paint()..color = ink,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(w, 0), radius: r),
      math.pi / 2,
      math.pi / 2,
      true,
      Paint()..color = tone.pop,
    );
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.5),
      math.min(w, h) * 0.09,
      Paint()..color = ink,
    );
  }

  void _stackedBlocks(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    final unit = math.min(w, h) * 0.26;
    final d = unit * 0.18;
    void block(double x, double y, double bw, double bh, Color face) {
      // Plunk edges, then the face.
      canvas.drawPath(
        Path()
          ..moveTo(x + bw, y)
          ..lineTo(x + bw + d, y + d)
          ..lineTo(x + bw + d, y + bh + d)
          ..lineTo(x + d, y + bh + d)
          ..lineTo(x, y + bh)
          ..lineTo(x + bw, y + bh)
          ..close(),
        Paint()..color = Colors.black.withValues(alpha: 0.55),
      );
      canvas.drawRect(Rect.fromLTWH(x, y, bw, bh), Paint()..color = face);
    }

    final baseX = w * 0.18;
    final baseY = h * 0.78 - unit;
    block(baseX, baseY, unit * 2.4, unit, ink);
    block(baseX + unit * 0.4, baseY - unit * 1.05, unit * 1.6, unit, tone.pop);
    block(baseX + unit * 0.8, baseY - unit * 2.1, unit, unit,
        tone.ink == Colors.white ? Colors.white : ink);
  }

  void _orbit(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    final c = Offset(w * 0.5, h * 0.52);
    final r = math.min(w, h) * 0.34;
    canvas.drawOval(
      Rect.fromCenter(center: c, width: r * 2.6, height: r * 1.1),
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawCircle(c, r * 0.62, Paint()..color = ink);
    canvas.drawCircle(
      c + Offset(r * 1.2, -r * 0.28),
      r * 0.2,
      Paint()..color = tone.pop,
    );
  }

  void _triangleAndStripes(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    final stripe = Paint()..color = ink;
    for (var i = 0; i < 5; i++) {
      canvas.drawRect(Rect.fromLTWH(0, h * (0.1 + i * 0.09), w, 3), stripe);
    }
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.15, h * 0.92)
        ..lineTo(w * 0.58, h * 0.3)
        ..lineTo(w * 0.98, h * 0.92)
        ..close(),
      Paint()..color = tone.pop,
    );
    canvas.drawRect(
      Rect.fromLTWH(w * 0.05, h * 0.62, w * 0.22, w * 0.22),
      Paint()..color = ink,
    );
  }

  @override
  bool shouldRepaint(_ArtPainter old) =>
      old.variant != variant || old.tone != tone;
}
