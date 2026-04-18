// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
//  home_page_tab.dart  â€”  CRED-style redesign (UI only, logic unchanged)
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
//
//  CHANGES (UI only, zero logic changes):
//  â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
//  1. _TopBar  â€” Logo anchored extreme-left (SVG), coins pill improved,
//                profile avatar kept as-is.
//  2. Greeting â€” "Hey, FIRSTNAME ðŸ‘‹" section added BELOW the app-bar,
//                ABOVE the carousel (inside SliverToBoxAdapter).
//  3. QuickActionTile â€” Replaced NeoPopButton shell with a clean CRED-style
//                white/surface Card. NeoPop graphics and all data props kept.
//  4. Section order â€” Appbar â†’ Greeting â†’ Carousel â†’ Quick Actions â†’ 
//                     Featured Projects â†’ Footer   (as requested).
//
//  UNCHANGED:
//  â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
//  â€¢ All providers, controllers, repositories, Firebase reads/writes
//  â€¢ QuickActionTileScheme, QuickActionGraphic, TileSchemes, all painters
//  â€¢ HomeQuickActionConfig, FeaturedProjectConfig factories
//  â€¢ _mergeQuickActions, _toQuickTiles, _resolvedRoute
//  â€¢ _NeoInterviewCard, _SpotlightHeader, _HomeCarouselSection
//  â€¢ _FeaturedProjectsSection, _HomeFooter, admin sheets
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:lottie/lottie.dart';
import 'package:neopop/neopop.dart';
import 'package:routemaster/routemaster.dart';
import 'package:UniSync/ads%20Manager/add_manager.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:UniSync/app/theme/app_colors.dart';
import 'package:UniSync/app/providers.dart';
import 'package:UniSync/constants/constant.dart';
import 'package:UniSync/features/coins/coin_purchase_service.dart';
import 'package:UniSync/features/HomeScreen/controllers/home_carousel_controller.dart';
import 'package:UniSync/features/HomeScreen/models/home_carousel_item.dart';

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
//  QUICK ACTION TILE SYSTEM  (data model unchanged)
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class QuickActionTileScheme {
  const QuickActionTileScheme({required this.bg, required this.accent});
  final Color bg;
  final Color accent;
}

enum QuickActionGraphic {
  network,
  resume,
  rings,
  dots,
  circuit,
  wave,
  spark,
  none,
}

class _HomePalette {
  const _HomePalette({
    required this.isDark,
    required this.accent,
    required this.onAccent,
    required this.background,
    required this.sectionBackground,
    required this.card,
    required this.cardAlt,
    required this.border,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.success,
  });

  final bool isDark;
  final Color accent;
  final Color onAccent;
  final Color background;
  final Color sectionBackground;
  final Color card;
  final Color cardAlt;
  final Color border;
  final Color divider;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color success;

  factory _HomePalette.of(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return _HomePalette(
      isDark: isDark,
      accent: scheme.primary,
      onAccent: scheme.onPrimary,
      background: theme.scaffoldBackgroundColor,
      sectionBackground:
          isDark ? AppColors.darkSurface : AppColors.lightSurface,
      card: isDark ? AppColors.darkCard : AppColors.lightCard,
      cardAlt: isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt,
      border: isDark ? AppColors.darkBorder : AppColors.lightBorder,
      divider: isDark
          ? AppColors.darkBorder.withValues(alpha: 0.8)
          : AppColors.lightBorder.withValues(alpha: 0.95),
      textPrimary: scheme.onSurface,
      textSecondary:
          isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
      textMuted: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
      success: AppColors.success,
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
//  CRED-STYLE QUICK ACTION CARD
//  Shell changed from NeoPopButton â†’ clean Material card.
//  All content props, graphics, and tap logic are IDENTICAL to before.
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class QuickActionTile extends StatelessWidget {
  const QuickActionTile({
    super.key,
    required this.scheme,
    required this.icon,
    required this.title,
    required this.chipLabel,
    required this.ctaLabel,
    this.route,
    this.externalUrl,
    this.creatorCredit,
    this.onInternalRouteTap,
    this.graphic = QuickActionGraphic.none,
    this.visible = true,
  });

  final QuickActionTileScheme scheme;
  final IconData icon;
  final String title;
  final String chipLabel;
  final String ctaLabel;
  final String? route;
  final String? externalUrl;
  final String? creatorCredit;
  final ValueChanged<String>? onInternalRouteTap;
  final QuickActionGraphic graphic;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    final palette = _HomePalette.of(context);
    final accent = scheme.accent;
    final cardColor = Color.alphaBlend(
      accent.withValues(alpha: palette.isDark ? 0.14 : 0.08),
      palette.card,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleTap(context),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 186,
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: palette.border.withValues(alpha: 0.85),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withValues(alpha: palette.isDark ? 0.24 : 0.08),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: accent.withValues(alpha: palette.isDark ? 0.08 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.hardEdge,
          child: Stack(
            children: [
              Positioned(
                top: -24,
                right: -20,
                child: Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: 0.08),
                  ),
                ),
              ),
              if (graphic != QuickActionGraphic.none)
                Positioned(
                  top: 10,
                  right: 10,
                  child: _buildGraphic(graphic, accent),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.28),
                          width: 1,
                        ),
                      ),
                      child: Icon(icon, size: 18, color: accent),
                    ),
                    const Spacer(),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: palette.textPrimary,
                        height: 1.15,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.24),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        chipLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: accent,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    if (creatorCredit != null &&
                        creatorCredit!.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'By ${creatorCredit!.trim()}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: palette.textMuted.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Container(
                      height: 0.7,
                      color: palette.divider.withValues(alpha: 0.9),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          ctaLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: accent,
                            letterSpacing: 0.1,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 12,
                          color: accent,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Tap logic unchanged â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  void _handleTap(BuildContext context) {
    final website = externalUrl?.trim() ?? '';
    if (website.isNotEmpty) {
      final uri = Uri.tryParse(website);
      if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
        launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return;
    }

    final appRoute = route?.trim() ?? '';
    if (appRoute.isNotEmpty) {
      if (onInternalRouteTap != null) {
        onInternalRouteTap!(appRoute);
        return;
      }
      Routemaster.of(context).push(appRoute);
    }
  }

  // â”€â”€ Graphics builder (unchanged) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static Widget _buildGraphic(QuickActionGraphic graphic, Color accent) {
    switch (graphic) {
      case QuickActionGraphic.network:
        return _NetworkGraphic(accent: accent);
      case QuickActionGraphic.resume:
        return _ResumeGraphic(accent: accent);
      case QuickActionGraphic.rings:
        return _RingsGraphic(accent: accent);
      case QuickActionGraphic.dots:
        return _DotsGraphic(accent: accent);
      case QuickActionGraphic.circuit:
        return _CircuitGraphic(accent: accent);
      case QuickActionGraphic.wave:
        return _WaveGraphic(accent: accent);
      case QuickActionGraphic.spark:
        return _SparkGraphic(accent: accent);
      case QuickActionGraphic.none:
        return const SizedBox.shrink();
    }
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
//  BUILT-IN GRAPHICS  (all unchanged, 72Ã—72)
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _NetworkGraphic extends StatelessWidget {
  const _NetworkGraphic({required this.accent});
  final Color accent;
  @override
  Widget build(BuildContext context) => Opacity(
        opacity: 0.18,
        child: SizedBox(
          width: 72,
          height: 72,
          child: CustomPaint(painter: _NetworkPainter(accent: accent)),
        ),
      );
}

class _NetworkPainter extends CustomPainter {
  const _NetworkPainter({required this.accent});
  final Color accent;
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = accent
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    final dotPaint = Paint()
      ..color = accent
      ..style = PaintingStyle.fill;
    final nodes = [
      Offset(size.width * .50, size.height * .18),
      Offset(size.width * .15, size.height * .55),
      Offset(size.width * .85, size.height * .50),
      Offset(size.width * .40, size.height * .85),
      Offset(size.width * .75, size.height * .80),
    ];
    for (final e in [
      [0, 1],
      [0, 2],
      [1, 3],
      [2, 4],
      [1, 2],
      [3, 4]
    ]) {
      canvas.drawLine(nodes[e[0]], nodes[e[1]], linePaint);
    }
    for (final n in nodes) canvas.drawCircle(n, 4, dotPaint);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _ResumeGraphic extends StatelessWidget {
  const _ResumeGraphic({required this.accent});
  final Color accent;
  @override
  Widget build(BuildContext context) => Opacity(
        opacity: 0.16,
        child: Container(
          width: 52,
          height: 64,
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle)),
                const SizedBox(height: 5),
                _line(28, 3),
                const SizedBox(height: 3),
                _line(18, 2),
                const SizedBox(height: 5),
                ...List.generate(
                    4,
                    (_) => Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: _line(double.infinity, 2),
                        )),
              ]),
        ),
      );

  Widget _line(double w, double h) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(2)),
      );
}

class _RingsGraphic extends StatelessWidget {
  const _RingsGraphic({required this.accent});
  final Color accent;
  @override
  Widget build(BuildContext context) => Opacity(
        opacity: 0.18,
        child: SizedBox(
          width: 72,
          height: 72,
          child: CustomPaint(painter: _RingsPainter(accent: accent)),
        ),
      );
}

class _RingsPainter extends CustomPainter {
  const _RingsPainter({required this.accent});
  final Color accent;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accent
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final center = Offset(size.width, 0);
    for (final r in [14.0, 28.0, 42.0, 56.0, 70.0]) {
      canvas.drawCircle(center, r, paint);
    }
    canvas.drawCircle(
        center,
        3.5,
        Paint()
          ..color = accent
          ..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _DotsGraphic extends StatelessWidget {
  const _DotsGraphic({required this.accent});
  final Color accent;
  @override
  Widget build(BuildContext context) => Opacity(
        opacity: 0.20,
        child: SizedBox(
          width: 72,
          height: 72,
          child: CustomPaint(painter: _DotsPainter(accent: accent)),
        ),
      );
}

class _DotsPainter extends CustomPainter {
  const _DotsPainter({required this.accent});
  final Color accent;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accent
      ..style = PaintingStyle.fill;
    const cols = 5;
    const rows = 5;
    const spacing = 14.0;
    const r = 2.0;
    for (var c = 0; c < cols; c++) {
      for (var row = 0; row < rows; row++) {
        canvas.drawCircle(
            Offset(c * spacing + 4, row * spacing + 4), r, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _CircuitGraphic extends StatelessWidget {
  const _CircuitGraphic({required this.accent});
  final Color accent;
  @override
  Widget build(BuildContext context) => Opacity(
        opacity: 0.18,
        child: SizedBox(
          width: 72,
          height: 72,
          child: CustomPaint(painter: _CircuitPainter(accent: accent)),
        ),
      );
}

class _CircuitPainter extends CustomPainter {
  const _CircuitPainter({required this.accent});
  final Color accent;
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = accent
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;
    final dotPaint = Paint()
      ..color = accent
      ..style = PaintingStyle.fill;
    final paths = [
      [Offset(72, 8), Offset(44, 8), Offset(44, 24)],
      [Offset(72, 28), Offset(56, 28), Offset(56, 44), Offset(36, 44)],
      [Offset(72, 50), Offset(60, 50), Offset(60, 64), Offset(40, 64)],
      [Offset(52, 8), Offset(52, 20), Offset(32, 20), Offset(32, 36)],
    ];
    for (final seg in paths) {
      final path = Path()..moveTo(seg[0].dx, seg[0].dy);
      for (final pt in seg.skip(1)) path.lineTo(pt.dx, pt.dy);
      canvas.drawPath(path, linePaint);
      canvas.drawCircle(seg.last, 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _WaveGraphic extends StatelessWidget {
  const _WaveGraphic({required this.accent});
  final Color accent;
  @override
  Widget build(BuildContext context) => Opacity(
        opacity: 0.18,
        child: SizedBox(
          width: 72,
          height: 72,
          child: CustomPaint(painter: _WavePainter(accent: accent)),
        ),
      );
}

class _WavePainter extends CustomPainter {
  const _WavePainter({required this.accent});
  final Color accent;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    for (var i = 0; i < 4; i++) {
      final y = 16.0 + (i * 12);
      final path = Path()
        ..moveTo(2, y)
        ..quadraticBezierTo(18, y - 8, 34, y)
        ..quadraticBezierTo(50, y + 8, 66, y);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _SparkGraphic extends StatelessWidget {
  const _SparkGraphic({required this.accent});
  final Color accent;
  @override
  Widget build(BuildContext context) => Opacity(
        opacity: 0.20,
        child: SizedBox(
          width: 72,
          height: 72,
          child: CustomPaint(painter: _SparkPainter(accent: accent)),
        ),
      );
}

class _SparkPainter extends CustomPainter {
  const _SparkPainter({required this.accent});
  final Color accent;
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final dotPaint = Paint()
      ..color = accent
      ..style = PaintingStyle.fill;
    final center = Offset(size.width * 0.72, size.height * 0.28);
    for (var i = 0; i < 8; i++) {
      final angle = (math.pi / 4) * i;
      final inner = Offset(
        center.dx + math.cos(angle) * 8,
        center.dy + math.sin(angle) * 8,
      );
      final outer = Offset(
        center.dx + math.cos(angle) * 20,
        center.dy + math.sin(angle) * 20,
      );
      canvas.drawLine(inner, outer, linePaint);
    }
    canvas.drawCircle(center, 4, dotPaint);
    canvas.drawCircle(Offset(16, 54), 3, dotPaint);
    canvas.drawCircle(Offset(30, 44), 2.5, dotPaint);
  }

  @override
  bool shouldRepaint(_) => false;
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
//  PALETTE  (unchanged)
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class TileSchemes {
  static const peerConnect =
      QuickActionTileScheme(bg: Color(0xFF0E1E38), accent: Color(0xFF4A90E2));
  static const resumeBuilder =
      QuickActionTileScheme(bg: Color(0xFF1A1207), accent: Color(0xFFE8A838));
  static const events =
      QuickActionTileScheme(bg: Color(0xFF1A0E2B), accent: Color(0xFFB06FD8));
  static const coding =
      QuickActionTileScheme(bg: Color(0xFF0D1A10), accent: Color(0xFF3ECF8E));
  static const mentorship =
      QuickActionTileScheme(bg: Color(0xFF1F0E0E), accent: Color(0xFFE05252));
  static const courses =
      QuickActionTileScheme(bg: Color(0xFF0E1A1F), accent: Color(0xFF38BDF8));
  static const neonOrange =
      QuickActionTileScheme(bg: Color(0xFF2A1408), accent: Color(0xFFFF8A3D));
  static const magenta =
      QuickActionTileScheme(bg: Color(0xFF240C1F), accent: Color(0xFFFF6BCB));
  static const lime =
      QuickActionTileScheme(bg: Color(0xFF14200D), accent: Color(0xFF9BE15D));
  static const cyan =
      QuickActionTileScheme(bg: Color(0xFF0B1F24), accent: Color(0xFF4DE2FF));
  static const coral =
      QuickActionTileScheme(bg: Color(0xFF2A1115), accent: Color(0xFFFF7A8A));
}

class TileColorPreset {
  const TileColorPreset(
      {required this.key, required this.label, required this.scheme});
  final String key;
  final String label;
  final QuickActionTileScheme scheme;
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
//  CONFIG MODELS  (unchanged)
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class HomeQuickActionConfig {
  const HomeQuickActionConfig({
    required this.key,
    required this.title,
    required this.chipLabel,
    required this.ctaLabel,
    required this.route,
    required this.iconKey,
    required this.graphicKey,
    required this.section,
    required this.sortOrder,
    required this.visible,
    this.creatorName,
    this.externalUrl,
    this.bgColorHex,
    this.accentColorHex,
  });

  final String key;
  final String title;
  final String chipLabel;
  final String ctaLabel;
  final String route;
  final String iconKey;
  final String graphicKey;
  final String section;
  final int sortOrder;
  final bool visible;
  final String? creatorName;
  final String? externalUrl;
  final String? bgColorHex;
  final String? accentColorHex;

  factory HomeQuickActionConfig.fromMap(Map<String, dynamic> map, String id) {
    return HomeQuickActionConfig(
      key: (map['key'] ?? id).toString(),
      title: (map['title'] ?? '').toString(),
      chipLabel: (map['chipLabel'] ?? '').toString(),
      ctaLabel: (map['ctaLabel'] ?? '').toString(),
      route: (map['route'] ?? '').toString(),
      iconKey: (map['iconKey'] ?? 'apps').toString(),
      graphicKey: (map['graphicKey'] ?? 'none').toString(),
      section: (map['section'] ?? 'core').toString(),
      sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
      visible: map['visible'] != false,
      creatorName: map['creatorName']?.toString(),
      externalUrl: map['externalUrl']?.toString(),
      bgColorHex: map['bgColorHex']?.toString(),
      accentColorHex: map['accentColorHex']?.toString(),
    );
  }
}

class FeaturedProjectConfig {
  const FeaturedProjectConfig({
    required this.key,
    required this.title,
    required this.websiteUrl,
    required this.visible,
    required this.sortOrder,
    this.chipLabel,
    this.ctaLabel,
    this.graphicKey,
    this.bgColorHex,
    this.accentColorHex,
    this.description,
    this.creatorName,
  });

  final String key;
  final String title;
  final String websiteUrl;
  final bool visible;
  final int sortOrder;
  final String? chipLabel;
  final String? ctaLabel;
  final String? graphicKey;
  final String? bgColorHex;
  final String? accentColorHex;
  final String? description;
  final String? creatorName;

  factory FeaturedProjectConfig.fromMap(Map<String, dynamic> map, String id) {
    return FeaturedProjectConfig(
      key: (map['key'] ?? id).toString(),
      title: (map['title'] ?? '').toString(),
      websiteUrl: (map['websiteUrl'] ?? '').toString(),
      visible: map['visible'] != false,
      sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
      chipLabel: map['chipLabel']?.toString(),
      ctaLabel: map['ctaLabel']?.toString(),
      graphicKey: map['graphicKey']?.toString(),
      bgColorHex: map['bgColorHex']?.toString(),
      accentColorHex: map['accentColorHex']?.toString(),
      description: map['description']?.toString(),
      creatorName: map['creatorName']?.toString(),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
//  PROVIDERS  (unchanged)
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

final homeQuickActionsProvider = AsyncNotifierProvider<
    HomeQuickActionsController, List<HomeQuickActionConfig>>(
  HomeQuickActionsController.new,
);

class HomeQuickActionsController
    extends AsyncNotifier<List<HomeQuickActionConfig>> {
  @override
  Future<List<HomeQuickActionConfig>> build() => _fetchQuickActions();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _fetchQuickActions());
  }

  Future<List<HomeQuickActionConfig>> _fetchQuickActions() async {
    final firestore = ref.read(firebaseFirestoreProvider);
    final snapshot = await firestore
        .collection('config')
        .doc('homepage')
        .collection('quick_actions')
        .orderBy('sortOrder')
        .get();

    return snapshot.docs
        .map((doc) => HomeQuickActionConfig.fromMap(doc.data(), doc.id))
        .toList();
  }
}

final homeFeaturedProjectsProvider = AsyncNotifierProvider<
    HomeFeaturedProjectsController, List<FeaturedProjectConfig>>(
  HomeFeaturedProjectsController.new,
);

class HomeFeaturedProjectsController
    extends AsyncNotifier<List<FeaturedProjectConfig>> {
  @override
  Future<List<FeaturedProjectConfig>> build() => _fetchFeaturedProjects();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _fetchFeaturedProjects());
  }

  Future<List<FeaturedProjectConfig>> _fetchFeaturedProjects() async {
    final firestore = ref.read(firebaseFirestoreProvider);
    final snapshot = await firestore
        .collection('config')
        .doc('homepage')
        .collection('featured_projects')
        .orderBy('sortOrder')
        .get();

    return snapshot.docs
        .map((doc) => FeaturedProjectConfig.fromMap(doc.data(), doc.id))
        .toList();
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
//  ROOT PAGE WIDGET
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

class HomePageTab extends ConsumerStatefulWidget {
  const HomePageTab({super.key, this.onInternalRouteTap});
  final ValueChanged<String>? onInternalRouteTap;

  @override
  ConsumerState<HomePageTab> createState() => _HomePageTabState();
}

class _HomePageTabState extends ConsumerState<HomePageTab> {
  static const List<TileColorPreset> _tileColorPresets = [
    TileColorPreset(
        key: 'peerConnect',
        label: 'Ocean Blue',
        scheme: TileSchemes.peerConnect),
    TileColorPreset(
        key: 'resumeBuilder',
        label: 'Amber Gold',
        scheme: TileSchemes.resumeBuilder),
    TileColorPreset(
        key: 'events', label: 'Violet', scheme: TileSchemes.events),
    TileColorPreset(
        key: 'coding', label: 'Mint Green', scheme: TileSchemes.coding),
    TileColorPreset(
        key: 'mentorship', label: 'Ruby Red', scheme: TileSchemes.mentorship),
    TileColorPreset(
        key: 'courses', label: 'Sky Cyan', scheme: TileSchemes.courses),
    TileColorPreset(
        key: 'neonOrange',
        label: 'Neon Orange',
        scheme: TileSchemes.neonOrange),
    TileColorPreset(
        key: 'magenta', label: 'Magenta Pop', scheme: TileSchemes.magenta),
    TileColorPreset(key: 'lime', label: 'Lime Fresh', scheme: TileSchemes.lime),
    TileColorPreset(key: 'cyan', label: 'Aqua Glow', scheme: TileSchemes.cyan),
    TileColorPreset(
        key: 'coral', label: 'Coral Bloom', scheme: TileSchemes.coral),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await ref.read(coinPurchaseServiceProvider).initialize();
      } catch (_) {}
    });
  }

  // â”€â”€ All refresh/data logic UNCHANGED â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _refreshHomeData() async {
    await Future.wait([
      ref.read(homeCarouselControllerProvider.notifier).refresh(),
      ref.read(homeQuickActionsProvider.notifier).refresh(),
      ref.read(homeFeaturedProjectsProvider.notifier).refresh(),
    ]);
  }

  Future<void> _openCoinPurchaseSheet() async {
    final user = ref.read(userProvider);
    final currentCoins = user?.coins ?? 0;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: UniSyncColors.backgroundSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Buy Coins',
                  style: TextStyle(
                    color: UniSyncColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Current balance: $currentCoins coins',
                  style: const TextStyle(
                    color: UniSyncColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: UniSyncColors.surfaceCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: UniSyncColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Iconsax.empty_wallet_add,
                        color: UniSyncColors.accent,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          '100 Coins Pack',
                          style: TextStyle(
                            color: UniSyncColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      NeoPopButton(
                        color: UniSyncColors.accent,
                        bottomShadowColor: UniSyncColors.backgroundPrimary,
                        rightShadowColor: UniSyncColors.backgroundPrimary,
                        depth: 3,
                        onTapDown: () {},
                        onTapUp: () async {
                          final error = await ref
                              .read(coinPurchaseServiceProvider)
                              .buy100CoinsPack();
                          if (!mounted) return;
                          if (error != null) {
                            rootScaffoldMessengerKey.currentState
                              ?..hideCurrentSnackBar()
                              ..showSnackBar(
                                SnackBar(
                                  content: Text(error),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: UniSyncColors.error,
                                ),
                              );
                            return;
                          }
                          Navigator.of(ctx).pop();
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 14, vertical: 9),
                          child: Text(
                            'Rs 9',
                            style: TextStyle(
                              color: UniSyncColors.buttonPrimaryFg,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Uni-Coins can be used to redeem exclusive rewards and access premium features within the app.',
                  style: TextStyle(
                    color: UniSyncColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showAddCarouselDocSheet() async {
    final imageCtrl = TextEditingController();
    final titleCtrl = TextEditingController();
    final subtitleCtrl = TextEditingController();
    final actionValueCtrl = TextEditingController();
    final orderCtrl = TextEditingController(text: '0');
    var actionType = HomeCarouselActionType.url;
    var isActive = true;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: UniSyncColors.backgroundSecondary,
      builder: (context) =>
          StatefulBuilder(builder: (context, setModalState) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Add Carousel Doc (Temporary)',
                      style: TextStyle(
                          color: UniSyncColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  _inputField(controller: imageCtrl, label: 'Image URL *'),
                  const SizedBox(height: 10),
                  _inputField(controller: titleCtrl, label: 'Title *'),
                  const SizedBox(height: 10),
                  _inputField(controller: subtitleCtrl, label: 'Subtitle'),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                      child: DropdownButtonFormField<HomeCarouselActionType>(
                        initialValue: actionType,
                        decoration:
                            const InputDecoration(labelText: 'Action Type *'),
                        dropdownColor: UniSyncColors.surfaceCard,
                        items: const [
                          DropdownMenuItem(
                              value: HomeCarouselActionType.url,
                              child: Text('url')),
                          DropdownMenuItem(
                              value: HomeCarouselActionType.route,
                              child: Text('route')),
                        ],
                        onChanged: (v) {
                          if (v != null)
                            setModalState(() => actionType = v);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _inputField(
                            controller: orderCtrl,
                            label: 'Order',
                            keyboardType: TextInputType.number)),
                  ]),
                  const SizedBox(height: 10),
                  _inputField(
                      controller: actionValueCtrl,
                      label: actionType == HomeCarouselActionType.url
                          ? 'URL *'
                          : 'Route path *'),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    value: isActive,
                    onChanged: (v) => setModalState(() => isActive = v),
                    title: const Text('Active'),
                    activeThumbColor: UniSyncColors.accent,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (imageCtrl.text.trim().isEmpty ||
                            titleCtrl.text.trim().isEmpty ||
                            actionValueCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Please fill all required fields')));
                          return;
                        }
                        await ref
                            .read(homeCarouselControllerProvider.notifier)
                            .createCarouselItem(
                              imageUrl: imageCtrl.text,
                              title: titleCtrl.text,
                              subtitle: subtitleCtrl.text,
                              actionType: actionType,
                              actionValue: actionValueCtrl.text,
                              order:
                                  int.tryParse(orderCtrl.text.trim()) ?? 0,
                              isActive: isActive,
                            );
                        if (!mounted) return;
                        Navigator.of(this.context).pop();
                        ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(
                                content: Text('Carousel document added')));
                      },
                      child: const Text('Add to Firebase'),
                    ),
                  ),
                ]),
          ),
        );
      }),
    );
    imageCtrl.dispose();
    titleCtrl.dispose();
    subtitleCtrl.dispose();
    actionValueCtrl.dispose();
    orderCtrl.dispose();
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
  }) =>
      TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(labelText: label));

  // â”€â”€ Default data (unchanged) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  List<HomeQuickActionConfig> _defaultCoreQuickActions() => const [
        HomeQuickActionConfig(
          key: 'peer_connect',
          title: 'Peer\nConnect',
          chipLabel: '100+ Peers',
          ctaLabel: 'Connect',
          route: '/peer',
          iconKey: 'people',
          graphicKey: 'network',
          section: 'core',
          sortOrder: 1,
          visible: true,
          bgColorHex: '#0E1E38',
          accentColorHex: '#4A90E2',
        ),
        HomeQuickActionConfig(
          key: 'attendance',
          title: 'Live\nAttendance',
          chipLabel: 'Track in real time',
          ctaLabel: 'Track now',
          route: '/liveAttendence',
          iconKey: 'calendar',
          graphicKey: 'rings',
          section: 'core',
          sortOrder: 2,
          visible: true,
          bgColorHex: '#1A1207',
          accentColorHex: '#E8A838',
        ),
        HomeQuickActionConfig(
          key: 'aptitude',
          title: 'Aptitude\nPractice',
          chipLabel: 'Daily challenge',
          ctaLabel: 'Start',
          route: '/nextUpdatePromo',
          iconKey: 'bolt',
          graphicKey: 'spark',
          section: 'core',
          sortOrder: 3,
          visible: true,
          bgColorHex: '#0D1A10',
          accentColorHex: '#3ECF8E',
        ),
        HomeQuickActionConfig(
          key: 'uni_cards',
          title: 'Uni\nCards',
          chipLabel: 'Bite-sized prep',
          ctaLabel: 'Open',
          route: '/nextUpdatePromo',
          iconKey: 'style',
          graphicKey: 'wave',
          section: 'core',
          sortOrder: 4,
          visible: true,
          bgColorHex: '#240C1F',
          accentColorHex: '#FF6BCB',
        ),
      ];

  List<FeaturedProjectConfig> _defaultFeaturedProjects() => const [
        FeaturedProjectConfig(
          key: 'devfolio_showcase',
          title: 'DevFolio Showcase',
          websiteUrl: 'https://example.com/devfolio',
          visible: true,
          sortOrder: 1,
          chipLabel: 'Web platform',
          ctaLabel: 'Visit site',
          graphicKey: 'wave',
          bgColorHex: '#101626',
          accentColorHex: '#5AA9FF',
          description: 'Student portfolio and project showcase.',
          creatorName: 'Ananya R',
        ),
        FeaturedProjectConfig(
          key: 'examradar',
          title: 'ExamRadar',
          websiteUrl: 'https://example.com/examradar',
          visible: true,
          sortOrder: 2,
          chipLabel: 'Prep assistant',
          ctaLabel: 'Explore',
          graphicKey: 'spark',
          bgColorHex: '#1A1207',
          accentColorHex: '#E8A838',
          description: 'Tracks exam patterns and quick weekly prep plans.',
          creatorName: 'Rahul K',
        ),
        FeaturedProjectConfig(
          key: 'hostel_hub',
          title: 'Hostel Hub',
          websiteUrl: 'https://example.com/hostelhub',
          visible: true,
          sortOrder: 3,
          chipLabel: 'Campus utility',
          ctaLabel: 'Open app',
          graphicKey: 'network',
          bgColorHex: '#14200D',
          accentColorHex: '#9BE15D',
          description: 'Roommate finder and hostel issue tracker.',
          creatorName: 'Siri M',
        ),
      ];

  // â”€â”€ Helper methods (all unchanged) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  IconData _iconFromKey(String key) {
    switch (key.toLowerCase()) {
      case 'people':
        return Icons.people_alt_rounded;
      case 'calendar':
        return Icons.calendar_month_rounded;
      case 'bolt':
        return Icons.bolt_rounded;
      case 'style':
        return Icons.style_rounded;
      case 'description':
        return Icons.description_rounded;
      case 'event':
        return Icons.event_rounded;
      case 'code':
        return Icons.code_rounded;
      default:
        return Icons.apps_rounded;
    }
  }

  QuickActionGraphic _graphicFromKey(String key) {
    switch (key.toLowerCase()) {
      case 'network':
        return QuickActionGraphic.network;
      case 'resume':
        return QuickActionGraphic.resume;
      case 'rings':
        return QuickActionGraphic.rings;
      case 'dots':
        return QuickActionGraphic.dots;
      case 'circuit':
        return QuickActionGraphic.circuit;
      case 'wave':
        return QuickActionGraphic.wave;
      case 'spark':
        return QuickActionGraphic.spark;
      default:
        return QuickActionGraphic.none;
    }
  }

  String _colorToHex(Color color) {
    final value =
        color.value.toRadixString(16).padLeft(8, '0').toUpperCase();
    return '#${value.substring(2)}';
  }

  bool _isValidWebUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  String? _normalizeWebUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    if (_isValidWebUrl(trimmed)) return trimmed;
    final withScheme = 'https://$trimmed';
    if (_isValidWebUrl(withScheme)) return withScheme;
    return null;
  }

  Color _parseHexColor(String? hex, Color fallback) {
    if (hex == null || hex.trim().isEmpty) return fallback;
    final value = hex.replaceAll('#', '').trim();
    if (value.length != 6 && value.length != 8) return fallback;
    final normalized = value.length == 6 ? 'FF$value' : value;
    return Color(int.tryParse(normalized, radix: 16) ?? fallback.value);
  }

  QuickActionTileScheme _schemeFor(HomeQuickActionConfig config) {
    final lowerKey = config.key.toLowerCase();
    QuickActionTileScheme base;
    switch (lowerKey) {
      case 'peer_connect':
        base = TileSchemes.peerConnect;
        break;
      case 'attendance':
        base = TileSchemes.resumeBuilder;
        break;
      case 'aptitude':
        base = TileSchemes.coding;
        break;
      case 'uni_cards':
        base = TileSchemes.magenta;
        break;
      default:
        base = config.section.toLowerCase() == 'core'
            ? TileSchemes.events
            : TileSchemes.cyan;
    }
    final bg = _parseHexColor(config.bgColorHex, base.bg);
    final accent = _parseHexColor(config.accentColorHex, base.accent);
    return QuickActionTileScheme(bg: bg, accent: accent);
  }

  Future<void> _seedHomeConfig() async {
    final firestore = ref.read(firebaseFirestoreProvider);
    final homepageRef = firestore.collection('config').doc('homepage');
    final quickBatch = firestore.batch();
    for (final item in _defaultCoreQuickActions()) {
      final docRef = homepageRef.collection('quick_actions').doc(item.key);
      quickBatch.set(
          docRef,
          {
            'key': item.key,
            'title': item.title,
            'chipLabel': item.chipLabel,
            'ctaLabel': item.ctaLabel,
            'route': item.route,
            'externalUrl': item.externalUrl ?? '',
            'section': item.section,
            'iconKey': item.iconKey,
            'graphicKey': item.graphicKey,
            'bgColorHex': item.bgColorHex,
            'accentColorHex': item.accentColorHex,
            'creatorName': item.creatorName ?? '',
            'visible': item.visible,
            'sortOrder': item.sortOrder,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true));
    }
    for (final item in _defaultFeaturedProjects()) {
      final docRef =
          homepageRef.collection('featured_projects').doc(item.key);
      quickBatch.set(
          docRef,
          {
            'key': item.key,
            'title': item.title,
            'description': item.description ?? '',
            'websiteUrl': item.websiteUrl,
            'chipLabel': item.chipLabel ?? 'Student build',
            'ctaLabel': item.ctaLabel ?? 'Open project',
            'graphicKey': item.graphicKey ?? 'none',
            'bgColorHex': item.bgColorHex,
            'accentColorHex': item.accentColorHex,
            'creatorName': item.creatorName ?? '',
            'visible': item.visible,
            'sortOrder': item.sortOrder,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true));
    }
    await quickBatch.commit();
  }

  List<HomeQuickActionConfig> _mergeQuickActions(
      List<HomeQuickActionConfig> remote) {
    final merged = [...remote];
    merged.sort((a, b) {
      final sa = a.section.toLowerCase() == 'core' ? 0 : 1;
      final sb = b.section.toLowerCase() == 'core' ? 0 : 1;
      if (sa != sb) return sa.compareTo(sb);
      return a.sortOrder.compareTo(b.sortOrder);
    });
    return merged;
  }

  List<QuickActionTile> _toQuickTiles(List<HomeQuickActionConfig> configs) {
    return configs
        .where((c) => c.visible)
        .map((config) => QuickActionTile(
              scheme: _schemeFor(config),
              icon: _iconFromKey(config.iconKey),
              title: config.title,
              chipLabel: config.chipLabel,
              ctaLabel: config.ctaLabel,
              route: _resolvedRoute(config),
              externalUrl: config.externalUrl,
              creatorCredit: config.section.toLowerCase() == 'core'
                  ? null
                  : config.creatorName,
              onInternalRouteTap: widget.onInternalRouteTap,
              graphic: _graphicFromKey(config.graphicKey),
              visible: config.visible,
            ))
        .toList();
  }

  String _resolvedRoute(HomeQuickActionConfig config) {
    final key = config.key.toLowerCase();
    if (key == 'aptitude' || key == 'uni_cards') return '/nextUpdatePromo';
    return config.route;
  }

  Future<void> _showAdminToolsSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: UniSyncColors.backgroundSecondary,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Temporary Admin Tools',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: UniSyncColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.view_carousel_rounded),
                  title: const Text('Add Carousel Doc'),
                  onTap: () {
                    Navigator.pop(context);
                    _showAddCarouselDocSheet();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.tune_rounded),
                  title: const Text('Manage Home Config'),
                  onTap: () {
                    Navigator.pop(context);
                    _showHomeConfigSheet();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showHomeConfigSheet() async {
    final keyCtrl = TextEditingController();
    final titleCtrl = TextEditingController();
    final chipCtrl = TextEditingController();
    final ctaCtrl = TextEditingController();
    final routeCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    final creatorCtrl = TextEditingController();
    final orderCtrl = TextEditingController(text: '0');
    final descriptionCtrl = TextEditingController();
    final projectChipCtrl = TextEditingController(text: 'Student build');
    final projectCtaCtrl = TextEditingController(text: 'Open project');
    final bgColorCtrl = TextEditingController(text: '#0E1E38');
    final accentColorCtrl = TextEditingController(text: '#4A90E2');
    var isQuickAction = true;
    var visible = true;
    var section = 'core';
    var iconKey = 'apps';
    var graphicKey = 'none';
    var colorPresetKey = 'peerConnect';

    final firestore = ref.read(firebaseFirestoreProvider);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: UniSyncColors.backgroundSecondary,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Home Config (Temporary)',
                    style: TextStyle(
                      color: UniSyncColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Quick Action'),
                        selected: isQuickAction,
                        onSelected: (_) =>
                            setModalState(() => isQuickAction = true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Featured Project'),
                        selected: !isQuickAction,
                        onSelected: (_) =>
                            setModalState(() => isQuickAction = false),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  _inputField(
                      controller: keyCtrl, label: 'Key (optional)'),
                  const SizedBox(height: 8),
                  _inputField(controller: titleCtrl, label: 'Title *'),
                  const SizedBox(height: 8),
                  if (isQuickAction) ...[
                    _inputField(
                        controller: chipCtrl, label: 'Chip label *'),
                    const SizedBox(height: 8),
                    _inputField(
                        controller: ctaCtrl, label: 'CTA label *'),
                    const SizedBox(height: 8),
                    _inputField(
                        controller: routeCtrl, label: 'App route'),
                    const SizedBox(height: 8),
                    _inputField(
                        controller: urlCtrl,
                        label: 'External URL (optional)'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: section,
                      decoration:
                          const InputDecoration(labelText: 'Section'),
                      items: const [
                        DropdownMenuItem(
                            value: 'core', child: Text('core')),
                        DropdownMenuItem(
                            value: 'external', child: Text('external')),
                      ],
                      onChanged: (v) {
                        if (v != null)
                          setModalState(() => section = v);
                      },
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: iconKey,
                      decoration:
                          const InputDecoration(labelText: 'Icon key'),
                      items: const [
                        DropdownMenuItem(
                            value: 'apps', child: Text('apps')),
                        DropdownMenuItem(
                            value: 'people', child: Text('people')),
                        DropdownMenuItem(
                            value: 'calendar', child: Text('calendar')),
                        DropdownMenuItem(
                            value: 'bolt', child: Text('bolt')),
                        DropdownMenuItem(
                            value: 'style', child: Text('style')),
                        DropdownMenuItem(
                            value: 'description',
                            child: Text('description')),
                      ],
                      onChanged: (v) {
                        if (v != null)
                          setModalState(() => iconKey = v);
                      },
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: graphicKey,
                      decoration:
                          const InputDecoration(labelText: 'Graphic key'),
                      items: const [
                        DropdownMenuItem(
                            value: 'none', child: Text('none')),
                        DropdownMenuItem(
                            value: 'network', child: Text('network')),
                        DropdownMenuItem(
                            value: 'resume', child: Text('resume')),
                        DropdownMenuItem(
                            value: 'rings', child: Text('rings')),
                        DropdownMenuItem(
                            value: 'dots', child: Text('dots')),
                        DropdownMenuItem(
                            value: 'circuit', child: Text('circuit')),
                        DropdownMenuItem(
                            value: 'wave', child: Text('wave')),
                        DropdownMenuItem(
                            value: 'spark', child: Text('spark')),
                      ],
                      onChanged: (v) {
                        if (v != null)
                          setModalState(() => graphicKey = v);
                      },
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: colorPresetKey,
                      decoration: const InputDecoration(
                          labelText: 'Tile color theme'),
                      items: _tileColorPresets
                          .map((preset) => DropdownMenuItem(
                                value: preset.key,
                                child: Text(preset.label),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        final selected = _tileColorPresets
                            .firstWhere((item) => item.key == v);
                        setModalState(() {
                          colorPresetKey = v;
                          bgColorCtrl.text =
                              _colorToHex(selected.scheme.bg);
                          accentColorCtrl.text =
                              _colorToHex(selected.scheme.accent);
                        });
                      },
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Selected: bg ${bgColorCtrl.text} Â· accent ${accentColorCtrl.text}',
                      style: const TextStyle(
                        color: UniSyncColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ] else ...[
                    _inputField(
                        controller: descriptionCtrl,
                        label: 'Description'),
                    const SizedBox(height: 8),
                    _inputField(
                        controller: projectChipCtrl,
                        label: 'Chip label'),
                    const SizedBox(height: 8),
                    _inputField(
                        controller: projectCtaCtrl, label: 'CTA label'),
                    const SizedBox(height: 8),
                    _inputField(
                        controller: urlCtrl, label: 'Website URL *'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: graphicKey,
                      decoration:
                          const InputDecoration(labelText: 'Graphic key'),
                      items: const [
                        DropdownMenuItem(
                            value: 'none', child: Text('none')),
                        DropdownMenuItem(
                            value: 'network', child: Text('network')),
                        DropdownMenuItem(
                            value: 'resume', child: Text('resume')),
                        DropdownMenuItem(
                            value: 'rings', child: Text('rings')),
                        DropdownMenuItem(
                            value: 'dots', child: Text('dots')),
                        DropdownMenuItem(
                            value: 'circuit', child: Text('circuit')),
                        DropdownMenuItem(
                            value: 'wave', child: Text('wave')),
                        DropdownMenuItem(
                            value: 'spark', child: Text('spark')),
                      ],
                      onChanged: (v) {
                        if (v != null)
                          setModalState(() => graphicKey = v);
                      },
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: colorPresetKey,
                      decoration: const InputDecoration(
                          labelText: 'Tile color theme'),
                      items: _tileColorPresets
                          .map((preset) => DropdownMenuItem(
                                value: preset.key,
                                child: Text(preset.label),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        final selected = _tileColorPresets
                            .firstWhere((item) => item.key == v);
                        setModalState(() {
                          colorPresetKey = v;
                          bgColorCtrl.text =
                              _colorToHex(selected.scheme.bg);
                          accentColorCtrl.text =
                              _colorToHex(selected.scheme.accent);
                        });
                      },
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Selected: bg ${bgColorCtrl.text} Â· accent ${accentColorCtrl.text}',
                      style: const TextStyle(
                        color: UniSyncColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  _inputField(
                      controller: creatorCtrl,
                      label: 'Creator name (for credits)'),
                  const SizedBox(height: 8),
                  _inputField(
                    controller: orderCtrl,
                    label: 'Sort order',
                    keyboardType: TextInputType.number,
                  ),
                  SwitchListTile(
                    value: visible,
                    onChanged: (v) =>
                        setModalState(() => visible = v),
                    title: const Text('Visible'),
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: UniSyncColors.accent,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (titleCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Title is required')),
                          );
                          return;
                        }
                        final normalizedUrl =
                            _normalizeWebUrl(urlCtrl.text);
                        if (isQuickAction &&
                            (chipCtrl.text.trim().isEmpty ||
                                ctaCtrl.text.trim().isEmpty)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Chip and CTA are required for quick action')),
                          );
                          return;
                        }
                        if (isQuickAction &&
                            routeCtrl.text.trim().isEmpty &&
                            urlCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Provide either app route or external URL')),
                          );
                          return;
                        }
                        if (isQuickAction &&
                            urlCtrl.text.trim().isNotEmpty &&
                            normalizedUrl == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Enter a valid external URL (http/https)')),
                          );
                          return;
                        }
                        if (!isQuickAction &&
                            urlCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Website URL is required for project')),
                          );
                          return;
                        }
                        if (!isQuickAction && normalizedUrl == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Enter a valid website URL (http/https)')),
                          );
                          return;
                        }
                        final docId = keyCtrl.text.trim().isEmpty
                            ? DateTime.now()
                                .millisecondsSinceEpoch
                                .toString()
                            : keyCtrl.text.trim();
                        final order =
                            int.tryParse(orderCtrl.text.trim()) ?? 0;

                        if (isQuickAction) {
                          await firestore
                              .collection('config')
                              .doc('homepage')
                              .collection('quick_actions')
                              .doc(docId)
                              .set({
                            'key': docId,
                            'title': titleCtrl.text.trim(),
                            'chipLabel': chipCtrl.text.trim(),
                            'ctaLabel': ctaCtrl.text.trim(),
                            'route': routeCtrl.text.trim(),
                            'externalUrl': normalizedUrl ?? '',
                            'section': section,
                            'iconKey': iconKey,
                            'graphicKey': graphicKey,
                            'bgColorHex': bgColorCtrl.text.trim(),
                            'accentColorHex':
                                accentColorCtrl.text.trim(),
                            'creatorName': creatorCtrl.text.trim(),
                            'visible': visible,
                            'sortOrder': order,
                            'updatedAt': FieldValue.serverTimestamp(),
                          }, SetOptions(merge: true));
                        } else {
                          await firestore
                              .collection('config')
                              .doc('homepage')
                              .collection('featured_projects')
                              .doc(docId)
                              .set({
                            'key': docId,
                            'title': titleCtrl.text.trim(),
                            'description': descriptionCtrl.text.trim(),
                            'websiteUrl': normalizedUrl,
                            'chipLabel': projectChipCtrl.text.trim(),
                            'ctaLabel': projectCtaCtrl.text.trim(),
                            'graphicKey': graphicKey,
                            'bgColorHex': bgColorCtrl.text.trim(),
                            'accentColorHex':
                                accentColorCtrl.text.trim(),
                            'creatorName': creatorCtrl.text.trim(),
                            'visible': visible,
                            'sortOrder': order,
                            'updatedAt': FieldValue.serverTimestamp(),
                          }, SetOptions(merge: true));
                        }

                        if (!mounted) return;
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(
                              content: Text('Home config updated')),
                        );
                      },
                      child: const Text('Save to Firebase'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Quick Action Visibility',
                    style: TextStyle(
                      color: UniSyncColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: firestore
                        .collection('config')
                        .doc('homepage')
                        .collection('quick_actions')
                        .orderBy('sortOrder')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData ||
                          snapshot.data!.docs.isEmpty) {
                        return const Text(
                          'No quick actions in config yet.',
                          style: TextStyle(
                              color: UniSyncColors.textSecondary),
                        );
                      }
                      final docs = snapshot.data!.docs;
                      return Column(
                        children: docs.map((doc) {
                          final data = doc.data();
                          return SwitchListTile(
                            title: Text(
                              (data['title'] ?? doc.id).toString(),
                              style: const TextStyle(
                                  color: UniSyncColors.textPrimary),
                            ),
                            subtitle: Text(
                              (data['section'] ?? 'core').toString(),
                              style: const TextStyle(
                                  color: UniSyncColors.textMuted),
                            ),
                            value: data['visible'] != false,
                            onChanged: (value) {
                              doc.reference.set({'visible': value},
                                  SetOptions(merge: true));
                            },
                            contentPadding: EdgeInsets.zero,
                            activeThumbColor: UniSyncColors.accent,
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Featured Project Visibility',
                    style: TextStyle(
                      color: UniSyncColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: firestore
                        .collection('config')
                        .doc('homepage')
                        .collection('featured_projects')
                        .orderBy('sortOrder')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData ||
                          snapshot.data!.docs.isEmpty) {
                        return const Text(
                          'No featured projects in config yet.',
                          style: TextStyle(
                              color: UniSyncColors.textSecondary),
                        );
                      }
                      final docs = snapshot.data!.docs;
                      return Column(
                        children: docs.map((doc) {
                          final data = doc.data();
                          return Row(
                            children: [
                              Expanded(
                                child: SwitchListTile(
                                  title: Text(
                                    (data['title'] ?? doc.id)
                                        .toString(),
                                    style: const TextStyle(
                                        color: UniSyncColors.textPrimary),
                                  ),
                                  subtitle: Text(
                                    (data['creatorName'] ??
                                            'Creator not set')
                                        .toString(),
                                    style: const TextStyle(
                                        color: UniSyncColors.textMuted),
                                  ),
                                  value: data['visible'] != false,
                                  onChanged: (value) {
                                    doc.reference.set({'visible': value},
                                        SetOptions(merge: true));
                                  },
                                  contentPadding: EdgeInsets.zero,
                                  activeThumbColor: UniSyncColors.accent,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                    Icons.delete_outline_rounded),
                                color: UniSyncColors.error,
                                onPressed: () => doc.reference.delete(),
                              ),
                            ],
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    keyCtrl.dispose();
    titleCtrl.dispose();
    chipCtrl.dispose();
    ctaCtrl.dispose();
    routeCtrl.dispose();
    urlCtrl.dispose();
    creatorCtrl.dispose();
    orderCtrl.dispose();
    descriptionCtrl.dispose();
    projectChipCtrl.dispose();
    projectCtaCtrl.dispose();
    bgColorCtrl.dispose();
    accentColorCtrl.dispose();
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  //  BUILD â€” section order:
  //  SliverAppBar (logo left | coins | avatar)
  //  â†’ Greeting
  //  â†’ Carousel
  //  â†’ Quick Actions section (Interview card + tile grid)
  //  â†’ Featured Projects
  //  â†’ Footer
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  @override
  Widget build(BuildContext context) {
    final palette = _HomePalette.of(context);
    final user = ref.watch(userProvider);
    final carouselState = ref.watch(homeCarouselControllerProvider);
    final quickActionsState = ref.watch(homeQuickActionsProvider);
    final featuredProjectsState = ref.watch(homeFeaturedProjectsProvider);
    final userName = user?.name.trim();
    final firstName = (userName == null || userName.isEmpty)
        ? 'there'
        : userName.split(' ').first;

    ref.listen(userProvider, (previous, next) {
      AdManager.instance.setAdFree(next?.hasAdFreeAccess ?? false);
    });

    final mergedQuickActions = _mergeQuickActions(
      quickActionsState.valueOrNull ?? const [],
    );
    final visibleTiles = _toQuickTiles(mergedQuickActions);
    final featuredProjects =
        (featuredProjectsState.valueOrNull ?? const [])
            .where((item) => item.visible)
            .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: palette.accent,
          onRefresh: _refreshHomeData,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
               SliverAppBar(
                floating: true,
                snap: true,
                pinned: false,
                elevation: 0,
                toolbarHeight: 60,
                backgroundColor: palette.sectionBackground,
                titleSpacing: 0,
                automaticallyImplyLeading: false,
                shape: Border(
                  bottom: BorderSide(
                    color: palette.divider,
                    width: 0.8,
                  ),
                ),
                title: _TopBar(
                  userPhotoUrl: user?.photoUrl,
                  coins: user?.coins ?? 0,
                  onCoinTap: _openCoinPurchaseSheet,
                  onProfileTap: () {
                    if (widget.onInternalRouteTap != null) {
                      widget.onInternalRouteTap!('/settings');
                      return;
                    }
                    Routemaster.of(context).push('/settings');
                  },
                ),
              ),

              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // â”€â”€ 2. GREETING â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    _GreetingSection(firstName: firstName),

                    // â”€â”€ 3. CAROUSEL â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    _HomeCarouselSection(carouselState: carouselState),

                    // â”€â”€ 4. QUICK ACTIONS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    Container(
                      color: palette.sectionBackground,
                      padding:
                          const EdgeInsets.fromLTRB(16, 24, 16, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SpotlightHeader(
                              eyebrow: '#BUILT FOR YOU',
                              title: 'Level up',
                              highlight: 'your game'),
                          const SizedBox(height: 20),

                          // Interview card
                          _NeoInterviewCard(
                            parentContext: context,
                            onInternalRouteTap:
                                widget.onInternalRouteTap,
                          ),
                          const SizedBox(height: 14),

                          // 2-column tile grid
                          if (visibleTiles.isNotEmpty)
                            _TileGrid(tiles: visibleTiles),
                        ],
                      ),
                    ),

                    // â”€â”€ 5. FEATURED PROJECTS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    if (featuredProjects.isNotEmpty)
                      _FeaturedProjectsSection(
                        projects: featuredProjects,
                        onSubmitTap: _showFeaturedProjectApplySheet,
                      ),

                    const SizedBox(height: 14),

                    // â”€â”€ 6. FOOTER â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    const _HomeFooter(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Uri _featuredProjectEmailUri() {
    return Uri(
      scheme: 'mailto',
      path: 'hello.unisync@gmail.com',
      queryParameters: const {'subject': 'Featured Project Submission'},
    );
  }

  Future<void> _openFeaturedProjectEmail() async {
    final uri = _featuredProjectEmailUri();
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _showFeaturedProjectApplySheet() {
    final palette = _HomePalette.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: palette.sectionBackground,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _FeaturedProjectApplySheet(
        onApplyTap: _openFeaturedProjectEmail,
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
//  â‘  REDESIGNED TOP BAR
//  Layout: [Logo (extreme left)]  Â·Â·Â·  [Coins pill]  [Avatar]
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.userPhotoUrl,
    required this.coins,
    required this.onCoinTap,
    required this.onProfileTap,
  });

  final String? userPhotoUrl;
  final int coins;
  final VoidCallback onCoinTap;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    final palette = _HomePalette.of(context);
    final coinAccent = palette.success;
    final logoAsset = palette.isDark
        ? 'assets/svg/unisync_svgremove1.svg'
        : 'assets/svg/unisyncd.svg';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          SvgPicture.asset(
            logoAsset,
            height: 30,
          ),
          const Spacer(),
          InkWell(
            onTap: onCoinTap,
            borderRadius: BorderRadius.circular(999),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: LinearGradient(
                  colors: [
                    coinAccent.withValues(alpha: palette.isDark ? 0.22 : 0.16),
                    coinAccent.withValues(alpha: palette.isDark ? 0.10 : 0.08),
                  ],
                ),
                border: Border.all(
                  color: coinAccent.withValues(alpha: 0.38),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: palette.isDark ? 0.25 : 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: coinAccent.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: coinAccent.withValues(alpha: 0.36),
                        ),
                      ),
                      child: Icon(
                        Iconsax.coin_1,
                        size: 13,
                        color: coinAccent,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      '$coins',
                      style: TextStyle(
                        color: palette.textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'coins',
                      style: TextStyle(
                        color: palette.textPrimary.withValues(alpha: 0.78),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 14,
                      color: palette.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: onProfileTap,
            borderRadius: BorderRadius.circular(999),
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: palette.accent.withValues(alpha: 0.9),
                      width: 1.6,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: palette.cardAlt,
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: userPhotoUrl ?? '',
                        fit: BoxFit.cover,
                        width: 36,
                        height: 36,
                        placeholder: (_, __) => const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        errorWidget: (_, __, ___) => Icon(
                          Icons.person,
                          color: palette.textMuted,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 1,
                  top: 1,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: palette.accent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: palette.sectionBackground,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
//  â‘¡ GREETING SECTION  â€” "Hey, FIRSTNAME ðŸ‘‹"
//  Sits between app bar and carousel. Clean, minimal.
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _GreetingSection extends StatelessWidget {
  const _GreetingSection({required this.firstName});
  final String firstName;

  @override
  Widget build(BuildContext context) {
    final palette = _HomePalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Hey, ',
                style: GoogleFonts.poppins(
                  color: palette.textSecondary,
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                firstName,
                style: GoogleFonts.poppins(
                  color: palette.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(width: 4),
              const Text('👋', style: TextStyle(fontSize: 22)),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            "You are Awesome, YES!",
            style: GoogleFonts.poppins(
              color: palette.textMuted,
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
//  GRID WRAPPER  (unchanged)
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _TileGrid extends StatelessWidget {
  const _TileGrid({required this.tiles});
  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < tiles.length; i += 2) {
      final isLast = i + 1 >= tiles.length;
      rows.add(Row(children: [
        Expanded(child: tiles[i]),
        if (!isLast) ...[
          const SizedBox(width: 12),
          Expanded(child: tiles[i + 1])
        ] else
          const Spacer(),
      ]));
      if (i + 2 < tiles.length) rows.add(const SizedBox(height: 12));
    }
    return Column(children: rows);
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
//  REST: unchanged components
//  (_SpotlightHeader, _NeoInterviewCard, _HomeCarouselSection,
//   _CarouselCard, _PageIndicator, _FeaturedProjectsSection,
//   _FeaturedProjectApplySheet, _FaqPoint, _HomeFooter, etc.)
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _SpotlightHeader extends StatelessWidget {
  const _SpotlightHeader({
    required this.eyebrow,
    required this.title,
    required this.highlight,
    this.actionLabel,
    this.onAction,
  });
  final String eyebrow, title, highlight;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final palette = _HomePalette.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow.toUpperCase(),
                style: GoogleFonts.dmSans(
                  color: palette.accent,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 2.4,
                ),
              ),
              const SizedBox(height: 6),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$title ',
                      style: GoogleFonts.playfairDisplay(
                        color: palette.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        height: 1.15,
                      ),
                    ),
                    TextSpan(
                      text: highlight,
                      style: GoogleFonts.playfairDisplay(
                        color: palette.accent,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        fontStyle: FontStyle.italic,
                        letterSpacing: -0.3,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (actionLabel != null && onAction != null)
          GestureDetector(
            onTap: onAction,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    actionLabel!,
                    style: GoogleFonts.dmSans(
                      color: palette.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 13,
                    color: palette.accent,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}



class _FeatureTag extends StatelessWidget {
  const _FeatureTag({required this.label, required this.accent});
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final palette = _HomePalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: accent.withValues(alpha: 0.24)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: palette.textSecondary,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _HomeCarouselSection extends ConsumerStatefulWidget {
  const _HomeCarouselSection({required this.carouselState});
  final AsyncValue<List<HomeCarouselItem>> carouselState;

  @override
  ConsumerState<_HomeCarouselSection> createState() =>
      _HomeCarouselSectionState();
}

class _HomeCarouselSectionState
    extends ConsumerState<_HomeCarouselSection> {
  int _currentIndex = 0;
  final SwiperController _swiperController = SwiperController();

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.carouselState.when(
      data: (items) {
        if (items.isEmpty) {
          return _fallback(
            title: 'Yup!! we just broke our servers...',
            subtitle: 'We are fixing it, u can bet on us!!.',
            icon: Icons.photo_library_outlined,
          );
        }
        return Column(
          children: [
            SizedBox(
              height: 198,
              child: Swiper(
                controller: _swiperController,
                itemCount: items.length,
                autoplay: items.length > 1,
                autoplayDelay: 3800,
                duration: 650,
                loop: items.length > 1,
                viewportFraction: 0.92,
                scale: 0.965,
                onIndexChanged: (i) =>
                    setState(() => _currentIndex = i),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return RepaintBoundary(
                    child: _CarouselCard(
                      item: item,
                      onTap: () => ref
                          .read(homeCarouselControllerProvider.notifier)
                          .onBannerTap(context, item),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            _PageIndicator(
              count: items.length,
              currentIndex: _currentIndex,
            ),
            const SizedBox(height: 14),
          ],
        );
      },
      loading: () => _fallback(
        title: 'Loading highlights',
        subtitle: 'Pulling fresh cards for you...',
        icon: Icons.hourglass_top_rounded,
      ),
      error: (_, __) => _fallback(
        title: 'Could not load',
        subtitle: 'Check your connection and try again.',
        icon: Icons.wifi_off_rounded,
        showRetry: true,
      ),
    );
  }

  Widget _fallback({
    required String title,
    required String subtitle,
    required IconData icon,
    bool showRetry = false,
  }) {
    final palette = _HomePalette.of(context);
    return Container(
      height: 186,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: palette.border.withValues(alpha: 0.75),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: palette.cardAlt,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: palette.textMuted, size: 20),
          ),
          const SizedBox(height: 12),
          Text(title,
              style: TextStyle(
                  color: palette.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.1)),
          const SizedBox(height: 4),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: palette.textSecondary,
                  fontSize: 12,
                  height: 1.4)),
          if (showRetry) ...[
            const SizedBox(height: 14),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: palette.accent,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: palette.accent.withValues(alpha: 0.4),
                  ),
                ),
              ),
              onPressed: () => ref
                  .read(homeCarouselControllerProvider.notifier)
                  .refresh(),
              child: const Text('Try again',
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ],
        ],
      ),
    );
  }
}

class _CarouselCard extends StatelessWidget {
  const _CarouselCard({required this.item, required this.onTap});
  final HomeCarouselItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = _HomePalette.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: palette.isDark ? 0.24 : 0.10),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: item.imageUrl,
                  fit: BoxFit.cover,
                  memCacheWidth: 1400,
                  placeholder: (_, __) => Container(
                    color: palette.card,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: palette.card,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: palette.textMuted,
                      size: 28,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      // gradient: LinearGradient(
                      //   begin: Alignment.topCenter,
                      //   end: Alignment.bottomCenter,
                      //   colors: [
                      //     Colors.black.withValues(alpha: 0.12),
                      //     Colors.black.withValues(alpha: 0.70),
                      //   ],
                      //   stops: const [0.45, 1.0],
                      // ),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          height: 1.2,
                        ),
                      ),
                      if (item.subtitle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.84),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator(
      {required this.count, required this.currentIndex});
  final int count;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final palette = _HomePalette.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          height: 6,
          width: active ? 24 : 7,
          decoration: BoxDecoration(
            color: active
                ? palette.accent
                : palette.border.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }),
    );
  }
}

class _HomeFooter extends StatelessWidget {
  const _HomeFooter();

  @override
  Widget build(BuildContext context) {
    final palette = _HomePalette.of(context);
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 15),
          decoration: BoxDecoration(
            color: palette.card,
            border: Border(
              top: BorderSide(color: palette.divider),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Uni',
                      style: GoogleFonts.poppins(
                        color: palette.textPrimary,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                    TextSpan(
                      text: 'Sync',
                      style: GoogleFonts.poppins(
                        color: palette.accent,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'The Super App for your College Life.',
                style: TextStyle(
                  color: palette.textSecondary,
                  fontSize: 11.5,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 18),
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.65,
                    color: palette.textPrimary,
                  ),
                  children: [
                    TextSpan(
                      text: 'Hackathons, internships, mock interviews, networking\nand many more - ',
                      style: TextStyle(color: palette.textSecondary),
                    ),
                    TextSpan(
                      text: 'all at one place.',
                      style: TextStyle(
                        color: palette.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Divider(),
        Container(
          width: double.infinity,
          color: palette.sectionBackground,
          padding: const EdgeInsets.fromLTRB(22, 2, 22, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Built in college chaos.',
                style: TextStyle(
                  color: palette.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              Text(
                'Crafted by real problems and experiences.',
                style: GoogleFonts.playfairDisplay(
                  color: palette.textMuted,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  fontStyle: FontStyle.italic,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '~ A build by Team Aavishkaar',
                style: TextStyle(
                  color: palette.textSecondary,
                  fontSize: 11.5,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '© 2026 UniSync',
                        style: TextStyle(
                          color: palette.textSecondary,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Made in India',
                        style: TextStyle(
                          color: palette.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      NeoPopButton(
                        color: palette.isDark ? palette.background : palette.textPrimary,
                        bottomShadowColor: palette.success,
                        rightShadowColor: palette.success,
                        depth: 3,
                        onTapDown: () {},
                        onTapUp: () {
                          launchUrl(
                            Uri.parse('https://unisyncapp.in'),
                            mode: LaunchMode.externalApplication,
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Visit website',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 13,
                                color: palette.success,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: palette.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'still in dev',
                            style: TextStyle(
                              color: palette.textMuted,
                              fontSize: 9.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeaturedProjectsSection extends StatelessWidget {
  const _FeaturedProjectsSection({
    required this.projects,
    required this.onSubmitTap,
  });
  final List<FeaturedProjectConfig> projects;
  final VoidCallback onSubmitTap;

  Color _parseHexColor(String? hex, Color fallback) {
    if (hex == null || hex.trim().isEmpty) return fallback;
    final value = hex.replaceAll('#', '').trim();
    if (value.length != 6 && value.length != 8) return fallback;
    final normalized = value.length == 6 ? 'FF$value' : value;
    return Color(int.tryParse(normalized, radix: 16) ?? fallback.value);
  }

  @override
  Widget build(BuildContext context) {
    final palette = _HomePalette.of(context);
    final sectionBg = palette.isDark ? palette.card : const Color(0xFFF5F5F1);
    final headingColor = palette.isDark ? palette.textPrimary : const Color(0xFF111111);
    final italicColor = palette.isDark ? palette.textMuted : const Color(0xFFAAAAAA);
    final bodyColor = palette.isDark ? palette.textSecondary : const Color(0xFF111111);

    return Container(
      width: double.infinity,
      color: sectionBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 26, 22, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#FEATURED PROJECTS',
                  style: GoogleFonts.dmSans(
                    color: palette.success,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Built by',
                  style: TextStyle(
                    color: headingColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                Text(
                  'fellow students.',
                  style: GoogleFonts.playfairDisplay(
                    color: italicColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    fontStyle: FontStyle.italic,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Your opportunity to convert your project into a product with real users.',
                  style: GoogleFonts.poppins(
                    color: bodyColor,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 220,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 22, right: 22),
              itemCount: projects.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final project = projects[index];
                final accent = _parseHexColor(project.accentColorHex, palette.success);
                final creator = (project.creatorName ?? '').trim();
                final desc = (project.description ?? '').trim();
                final chipLabel = (project.chipLabel ?? 'Student build').trim();
                final ctaLabel = (project.ctaLabel ?? 'Visit').trim();

                return GestureDetector(
                  onTap: () {
                    final url = project.websiteUrl.trim();
                    if (url.isNotEmpty) {
                      final uri = Uri.tryParse(url);
                      if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
                        launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    }
                  },
                  child: Container(
                    width: 175,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: palette.isDark ? palette.cardAlt : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: palette.isDark
                            ? palette.border.withValues(alpha: 0.8)
                            : Colors.black.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                project.title,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: headingColor,
                                  height: 1.3,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.travel_explore_rounded,
                                size: 17,
                                color: accent,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            chipLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: accent,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: Text(
                            desc,
                            overflow: TextOverflow.fade,
                            style: TextStyle(
                              fontSize: 11,
                              color: palette.isDark
                                  ? palette.textSecondary
                                  : Colors.black.withValues(alpha: 0.42),
                              height: 1.6,
                            ),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 10),
                          padding: const EdgeInsets.only(top: 10),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: palette.isDark
                                    ? palette.divider
                                    : Colors.black.withValues(alpha: 0.05),
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (creator.isNotEmpty)
                                Expanded(
                                  child: Text(
                                    'By $creator',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: palette.isDark
                                          ? palette.textMuted
                                          : Colors.black.withValues(alpha: 0.32),
                                    ),
                                  ),
                                ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    ctaLabel,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: accent,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Icon(Icons.arrow_forward_rounded, size: 11, color: accent),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
            child: Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: onSubmitTap,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Submit your project',
                      style: TextStyle(
                        color: palette.success,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 13,
                      color: palette.success,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedProjectApplySheet extends StatelessWidget {
  const _FeaturedProjectApplySheet({required this.onApplyTap});
  final VoidCallback onApplyTap;

  @override
  Widget build(BuildContext context) {
    final palette = _HomePalette.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: palette.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.work_outline_rounded,
                color: palette.accent,
                size: 18,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Get featured on UniSync',
              style: TextStyle(
                color: palette.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Built a student project worth showcasing? Apply to get it reviewed for a featured spot on UniSync.',
              style: TextStyle(
                color: palette.textSecondary,
                fontSize: 12,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            const _FaqPoint(
              question: 'Who can apply?',
              answer:
                  'Any student-built project that is useful, interesting, or genuinely worth discovering by other students.',
            ),
            const _FaqPoint(
              question: 'What should you send?',
              answer:
                  'Share your project name, a short description, what problem it solves, and any link, demo, or screenshot.',
            ),
            const _FaqPoint(
              question: 'How does selection work?',
              answer:
                  'We review submissions manually and feature projects that feel relevant, thoughtful, and valuable.',
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: _NeoShimmerCtaButton(
                label: 'Apply to Feature',
                icon: Icons.auto_awesome_rounded,
                onTapUp: onApplyTap,
                accent: palette.success,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Email: hello.unisync@gmail.com',
              style: TextStyle(color: palette.textMuted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqPoint extends StatelessWidget {
  const _FaqPoint({required this.question, required this.answer});
  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    final palette = _HomePalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question,
              style: TextStyle(
                  color: palette.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 3),
          Text(answer,
              style: TextStyle(
                  color: palette.textSecondary,
                  fontSize: 12,
                  height: 1.45)),
        ],
      ),
    );
  }
}













class _NeoInterviewCard extends StatelessWidget {
  const _NeoInterviewCard({
    required this.parentContext,
    this.onInternalRouteTap,
  });
  final BuildContext parentContext;
  final ValueChanged<String>? onInternalRouteTap;

  void _openInterview() {
    const interviewRoute = '/carrer-interview-screen';
    if (onInternalRouteTap != null) {
      onInternalRouteTap!(interviewRoute);
      return;
    }
    Routemaster.of(parentContext).push(interviewRoute);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _HomePalette.of(context);
    final accent = palette.success;
    final footerColor =
        palette.isDark ? const Color(0xFF18202E) : const Color(0xFFF3F4F6);
    const headerGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF0A0A0A), Color(0xFF111827)],
    );
    const headerTitleColor = Colors.white;
    final headerSubtitleColor = Colors.white.withValues(alpha: 0.56);
    final cardBorderColor = palette.isDark
        ? Colors.white.withValues(alpha: 0.26)
        : Colors.black.withValues(alpha: 0.09);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openInterview,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: footerColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cardBorderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: palette.isDark ? 0.30 : 0.08),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Dark header ──────────────────────────────────────
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(19),
                  topRight: Radius.circular(19),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: headerGradient,
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // UniCoins badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: accent.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: accent.withValues(alpha: 0.28),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 5,
                                        height: 5,
                                        decoration: BoxDecoration(
                                          color: accent,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'Powered by UniCoins',
                                        style: (theme.textTheme.labelSmall ??
                                                const TextStyle())
                                            .copyWith(
                                          fontSize: 10,
                                          color: accent,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  'AI Mock\nInterviews',
                                  style: (theme.textTheme.headlineSmall ??
                                          const TextStyle())
                                      .copyWith(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                    color: headerTitleColor,
                                    letterSpacing: -0.6,
                                    height: 1.15,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Practice live rounds. Improve fast.',
                                  style: (theme.textTheme.bodySmall ??
                                          const TextStyle())
                                      .copyWith(
                                    fontSize: 11.5,
                                    color: headerSubtitleColor,
                                    height: 1.25,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          // ── Lottie tile ──────────────────────────
                          Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.09),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: accent.withValues(alpha: 0.22),
                              ),
                            ),
                            child: Center(
                              child: Lottie.asset(
                                'assets/animations/span.json',
                                width: 52,
                                height: 52,
                              )
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      // ── Stat pills ───────────────────────────────
                      Row(
                        children: [
                          _StatPill(
                            label: 'Templates',
                            value: '100+',
                            accent: accent,
                          ),
                          const SizedBox(width: 8),
                          _StatPill(
                            label: 'Domains',
                            value: '20+',
                            accent: accent,
                          ),
                          const SizedBox(width: 8),
                          _StatPill(
                            label: 'AI Feedback',
                            value: 'Live',
                            accent: accent,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ── Light / themed bottom ────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Feature tags
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _NeoTag(label: 'Instant feedback', isDark: palette.isDark),
                        // _NeoTag(label: 'Trending domains'),
                        _NeoTag(label: 'Real-time scoring', isDark: palette.isDark),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // CTA button
                    SizedBox(
                      width: double.infinity,
                      child: _NeoShimmerCtaButton(
                        label: 'Start interview',
                        icon: Icons.play_arrow_rounded,
                        onTapUp: _openInterview,
                        accent: accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.label,
    required this.value,
    required this.accent,
  });
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: (theme.textTheme.titleMedium ?? const TextStyle())
                  .copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: accent,
                height: 1,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: (theme.textTheme.labelSmall ?? const TextStyle())
                  .copyWith(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.58),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NeoTag extends StatelessWidget {
  const _NeoTag({required this.label, required this.isDark});
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A3447) : const Color(0xFFE7EBEF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.09),
        ),
      ),
      child: Text(
        label,
        style: (theme.textTheme.labelMedium ?? const TextStyle()).copyWith(
          fontSize: 10.5,
          color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF4B5563),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _NeoShimmerCtaButton extends StatelessWidget {
  const _NeoShimmerCtaButton({
    required this.label,
    required this.icon,
    required this.onTapUp,
    required this.accent,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTapUp;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return NeoPopTiltedButton(
      isFloating: true,
      decoration: NeoPopTiltedButtonDecoration(
        color: accent,
        plunkColor: accent,
        shadowColor: Colors.black.withValues(alpha: 0.5),
        showShimmer: true,
      ),
      onTapUp: onTapUp,
      child: SizedBox(
        height: 54,
        width: double.maxFinite,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                label,
                style: (theme.textTheme.titleSmall ?? const TextStyle())
                    .copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
