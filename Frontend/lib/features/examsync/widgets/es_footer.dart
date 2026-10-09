import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:UniSync/features/examsync/theme/es_theme.dart';
import 'package:UniSync/features/examsync/widgets/es_disclaimer.dart';

/// Sign-off at the bottom of the ExamSync home: a strip of Bauhaus shapes,
/// a big faded tagline and a small "made by students" line, then the
/// disclaimer.
class EsFooter extends StatelessWidget {
  const EsFooter({super.key});

  @override
  Widget build(BuildContext context) {
    const faded = Color(0xFF3A3A3A);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ExcludeSemantics(
            child: SizedBox(
              height: 28,
              width: 172,
              child: CustomPaint(painter: _ShapesPainter()),
            ),
          ),
          const SizedBox(height: 22),
          Semantics(
            label: 'Prep smart. Stress less.',
            excludeSemantics: true,
            child: Text.rich(
              TextSpan(children: [
                TextSpan(
                  text: 'Prep smart,\n',
                  style: EsText.display(size: 46, color: faded),
                ),
                TextSpan(
                  text: 'stress less.',
                  style: EsText.display(
                    size: 46,
                    color: faded,
                    style: FontStyle.italic,
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                'Made with ',
                style: EsText.body(size: 13, color: EsColors.textMuted),
              ),
              const Icon(Icons.favorite_rounded,
                  size: 14, color: EsColors.pink),
              Text(
                ' by students, for students',
                style: EsText.body(size: 13, color: EsColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(height: 1, color: EsColors.border),
          const SizedBox(height: 16),
          const EsDisclaimerNote(),
        ],
      ),
    );
  }
}

/// Circle, half-moon, square, triangle and a ring in the brand colours,
/// muted so they sit quietly under the content.
class _ShapesPainter extends CustomPainter {
  const _ShapesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.height;
    Paint fill(Color c) => Paint()..color = c.withValues(alpha: 0.55);
    var x = 0.0;
    const gap = 8.0;

    canvas.drawCircle(Offset(x + s / 2, s / 2), s / 2, fill(EsColors.accent));
    x += s + gap;

    canvas.drawArc(Rect.fromLTWH(x, 0, s, s), math.pi / 2, math.pi, true,
        fill(EsColors.premium));
    canvas.drawArc(Rect.fromLTWH(x, 0, s, s), -math.pi / 2, math.pi, true,
        fill(EsColors.pink));
    x += s + gap;

    canvas.drawRect(Rect.fromLTWH(x, 0, s, s), fill(EsColors.lime));
    x += s + gap;

    canvas.drawPath(
      Path()
        ..moveTo(x, s)
        ..lineTo(x + s / 2, 0)
        ..lineTo(x + s, s)
        ..close(),
      fill(EsColors.success),
    );
    x += s + gap;

    canvas.drawCircle(
      Offset(x + s / 2, s / 2),
      s / 2 - 2.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = EsColors.warning.withValues(alpha: 0.55),
    );
  }

  @override
  bool shouldRepaint(_ShapesPainter old) => false;
}
