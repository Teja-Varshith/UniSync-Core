import 'package:flutter/material.dart';
import 'package:UniSync/features/examsync/theme/es_theme.dart';

/// ExamSync logo: a 34×34 yellow plunk block with an abstract "E", plus the
/// "exam*sync*" wordmark.
class ExamSyncLogo extends StatelessWidget {
  const ExamSyncLogo({super.key, this.showWordmark = true});

  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'ExamSync',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 37,
            height: 37,
            child: CustomPaint(painter: _LogoMarkPainter()),
          ),
          if (showWordmark) ...[
            const SizedBox(width: 10),
            ExcludeSemantics(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: 'exam', style: EsText.display(size: 22)),
                    TextSpan(
                      text: 'sync',
                      style: EsText.display(
                        size: 22,
                        color: EsColors.accent,
                        style: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LogoMarkPainter extends CustomPainter {
  const _LogoMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const s = 34.0, d = 3.0;
    canvas.drawPath(
      Path()
        ..moveTo(s, 0)
        ..lineTo(s + d, d)
        ..lineTo(s + d, s + d)
        ..lineTo(s, s)
        ..close(),
      Paint()..color = EsColors.accentRight,
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, s)
        ..lineTo(s, s)
        ..lineTo(s + d, s + d)
        ..lineTo(d, s + d)
        ..close(),
      Paint()..color = EsColors.accentBottom,
    );
    canvas.drawRect(
        const Rect.fromLTWH(0, 0, s, s), Paint()..color = EsColors.accent);
    final bar = Paint()..color = Colors.black;
    canvas.drawRect(const Rect.fromLTWH(7, 8, 20, 4), bar);
    canvas.drawRect(const Rect.fromLTWH(7, 15, 12, 4), bar);
    canvas.drawRect(const Rect.fromLTWH(7, 22, 20, 4), bar);
    canvas.drawCircle(
        const Offset(25.5, 17), 2.6, Paint()..color = EsColors.premium);
  }

  @override
  bool shouldRepaint(_LogoMarkPainter oldDelegate) => false;
}

enum IllustrationKind { lock, unlocked, empty, coin }

/// Small flat illustrations used in the paywall and empty states.
class EsIllustration extends StatelessWidget {
  const EsIllustration(this.kind, {super.key, this.size = 96});

  final IllustrationKind kind;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: _IllustrationPainter(kind)),
      ),
    );
  }
}

class _IllustrationPainter extends CustomPainter {
  _IllustrationPainter(this.kind);

  final IllustrationKind kind;

  void _block(Canvas canvas, Rect r, Color face, Color right, Color bottom,
      {double d = 5}) {
    canvas.drawPath(
      Path()
        ..moveTo(r.right, r.top)
        ..lineTo(r.right + d, r.top + d)
        ..lineTo(r.right + d, r.bottom + d)
        ..lineTo(r.right, r.bottom)
        ..close(),
      Paint()..color = right,
    );
    canvas.drawPath(
      Path()
        ..moveTo(r.left, r.bottom)
        ..lineTo(r.right, r.bottom)
        ..lineTo(r.right + d, r.bottom + d)
        ..lineTo(r.left + d, r.bottom + d)
        ..close(),
      Paint()..color = bottom,
    );
    canvas.drawRect(r, Paint()..color = face);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 100;
    switch (kind) {
      case IllustrationKind.lock:
        canvas.drawArc(
          Rect.fromLTWH(30 * u, 14 * u, 40 * u, 44 * u),
          3.14159,
          3.14159,
          false,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 8 * u,
        );
        canvas.drawRect(Rect.fromLTWH(26 * u, 34 * u, 8 * u, 10 * u),
            Paint()..color = Colors.white);
        canvas.drawRect(Rect.fromLTWH(66 * u, 34 * u, 8 * u, 10 * u),
            Paint()..color = Colors.white);
        _block(canvas, Rect.fromLTWH(18 * u, 42 * u, 64 * u, 46 * u),
            EsColors.premium, EsColors.premiumRight, EsColors.premiumBottom,
            d: 6 * u);
        canvas.drawCircle(
            Offset(50 * u, 60 * u), 6 * u, Paint()..color = Colors.black);
        canvas.drawRect(Rect.fromLTWH(47.5 * u, 62 * u, 5 * u, 14 * u),
            Paint()..color = Colors.black);
      case IllustrationKind.unlocked:
        _block(canvas, Rect.fromLTWH(18 * u, 18 * u, 64 * u, 64 * u),
            EsColors.success, EsColors.successRight, EsColors.successBottom,
            d: 6 * u);
        canvas.drawPath(
          Path()
            ..moveTo(33 * u, 51 * u)
            ..lineTo(45 * u, 63 * u)
            ..lineTo(68 * u, 38 * u),
          Paint()
            ..color = Colors.black
            ..style = PaintingStyle.stroke
            ..strokeWidth = 8 * u
            ..strokeCap = StrokeCap.square,
        );
      case IllustrationKind.empty:
        final dash = Paint()
          ..color = EsColors.borderLight
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5 * u;
        final rect = Rect.fromLTWH(16 * u, 22 * u, 68 * u, 56 * u);
        _dashedRect(canvas, rect, dash, 6 * u);
        canvas.drawRect(Rect.fromLTWH(26 * u, 36 * u, 34 * u, 5 * u),
            Paint()..color = EsColors.surfaceElevated);
        canvas.drawRect(Rect.fromLTWH(26 * u, 48 * u, 48 * u, 5 * u),
            Paint()..color = EsColors.surfaceElevated);
        canvas.drawRect(Rect.fromLTWH(26 * u, 60 * u, 24 * u, 5 * u),
            Paint()..color = EsColors.surfaceElevated);
        canvas.drawCircle(
            Offset(80 * u, 24 * u), 7 * u, Paint()..color = EsColors.accent);
      case IllustrationKind.coin:
        canvas.drawCircle(Offset(54 * u, 54 * u), 34 * u,
            Paint()..color = EsColors.accentBottom);
        canvas.drawCircle(
            Offset(50 * u, 50 * u), 34 * u, Paint()..color = EsColors.accent);
        canvas.drawCircle(
          Offset(50 * u, 50 * u),
          22 * u,
          Paint()
            ..color = EsColors.accentRight
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4 * u,
        );
    }
  }

  void _dashedRect(Canvas canvas, Rect r, Paint p, double dash) {
    void line(Offset a, Offset b) {
      final total = (b - a).distance;
      final dir = (b - a) / total;
      for (double t = 0; t < total; t += dash * 2) {
        final end = (t + dash).clamp(0, total).toDouble();
        canvas.drawLine(a + dir * t, a + dir * end, p);
      }
    }

    line(r.topLeft, r.topRight);
    line(r.topRight, r.bottomRight);
    line(r.bottomRight, r.bottomLeft);
    line(r.bottomLeft, r.topLeft);
  }

  @override
  bool shouldRepaint(_IllustrationPainter old) => old.kind != kind;
}

/// Small yellow coin disc, used inline next to balances.
class EsCoin extends StatelessWidget {
  const EsCoin({super.key, this.size = 16});

  final double size;

  @override
  Widget build(BuildContext context) =>
      EsIllustration(IllustrationKind.coin, size: size);
}

/// Illustration + title + one-liner (+ optional action).
class EsEmptyState extends StatelessWidget {
  const EsEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.action,
  });

  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        children: [
          const EsIllustration(IllustrationKind.empty, size: 88),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: EsText.body(size: 16, weight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: EsText.body(size: 13, color: EsColors.textMuted),
          ),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}
