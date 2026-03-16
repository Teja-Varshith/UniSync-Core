import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:neopop/neopop.dart';
import 'package:routemaster/routemaster.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:unisync/app/providers.dart';
import 'package:unisync/constants/constant.dart';
import 'package:unisync/features/HomeScreen/controllers/home_carousel_controller.dart';
import 'package:unisync/features/HomeScreen/models/home_carousel_item.dart';

// ═════════════════════════════════════════════════════════════════════════════
//  QUICK ACTION TILE SYSTEM
//  ─────────────────────────────────────────────────────────────────────────
//  Use [QuickActionTileScheme] to define a tile's colors.
//  Use [QuickActionGraphic] enum to pick a built-in decoration graphic.
//  Pass [visible: false] to hide a tile without removing it from the list.
//
//  Example – adding a new tile later:
//
//  QuickActionTile(
//    scheme: QuickActionTileScheme(
//      bg:     Color(0xFF1A0E2B),
//      accent: Color(0xFFB06FD8),
//    ),
//    icon:      Icons.star_rounded,
//    title:     'Achievements',
//    chipLabel: '12 badges',
//    ctaLabel:  'View all',
//    route:     '/achievements',
//    graphic:   QuickActionGraphic.rings,   // or .grid / .dots / .circuit / none
//    visible:   true,
//  )
// ═════════════════════════════════════════════════════════════════════════════

// ─── Color scheme ────────────────────────────────────────────────────────────
class QuickActionTileScheme {
  const QuickActionTileScheme({required this.bg, required this.accent});
  final Color bg;
  final Color accent;
}

// ─── Built-in decoration graphics ────────────────────────────────────────────
enum QuickActionGraphic {
  /// Social-graph network nodes & edges  (Peer Connect)
  network,

  /// Mini resume document illustration  (Resume Builder)
  resume,

  /// Concentric rings / radar           (Events, Courses …)
  rings,

  /// Dotted grid pattern                (generic)
  dots,

  /// Circuit-board traces               (Tech / Coding …)
  circuit,

  /// Wave pattern for fluid/community themes
  wave,

  /// Spark/star burst style accents
  spark,

  /// No decoration
  none,
}

// ─── The reusable tile ───────────────────────────────────────────────────────
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

  /// Two-line title — use '\n' to break (e.g. 'Peer\nConnect')
  final String title;

  /// Small accent chip below the title (e.g. '200+ online')
  final String chipLabel;

  /// CTA link text (e.g. 'Connect')
  final String ctaLabel;

  /// Routemaster route
  final String? route;

  /// Optional external URL used when this tile points to a website
  final String? externalUrl;

  /// Optional credit shown for community-created features
  final String? creatorCredit;

  /// Optional callback to intercept in-app route taps
  final ValueChanged<String>? onInternalRouteTap;

  /// Decoration graphic drawn in the top-right corner
  final QuickActionGraphic graphic;

  /// Set to false to hide this tile without removing it from the layout
  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    return NeoPopButton(
      color: scheme.bg,
      bottomShadowColor: scheme.accent,
      rightShadowColor: scheme.accent,
      depth: 4,
      onTapUp: () => _handleTap(context),
      onTapDown: () {},
      child: ClipRect(
        child: SizedBox(
          height: 186,
          child: Stack(children: [
            // ── Decoration graphic (top-right) ────────────────────────
            if (graphic != QuickActionGraphic.none)
              Positioned(
                top: 8, right: 8,
                child: _buildGraphic(graphic, scheme.accent),
              ),

            // ── Content ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon badge
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: scheme.accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: scheme.accent.withOpacity(0.28)),
                    ),
                    child: Icon(icon, size: 18, color: scheme.accent),
                  ),

                  const Spacer(),

                  // Title
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800,
                      color: Colors.white, height: 1.15, letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: scheme.accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      chipLabel,
                      style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w600,
                        color: scheme.accent, letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  if (creatorCredit != null && creatorCredit!.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'By ${creatorCredit!.trim()}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.68),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),

                  // CTA link
                  Row(children: [
                    Text(ctaLabel,
                        style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: scheme.accent,
                        )),
                    const SizedBox(width: 3),
                    Icon(Icons.arrow_forward_rounded,
                        size: 12, color: scheme.accent),
                  ]),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

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

// ─────────────────────────────────────────────────────────────────────────────
//  BUILT-IN GRAPHICS
//  All are 72×72, drawn at low opacity so they never fight the content.
// ─────────────────────────────────────────────────────────────────────────────

// 1. Network graph ─────────────────────────────────────────────────────────────
class _NetworkGraphic extends StatelessWidget {
  const _NetworkGraphic({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: 0.18,
    child: SizedBox(
      width: 72, height: 72,
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
      ..color = accent..strokeWidth = 1.4..style = PaintingStyle.stroke;
    final dotPaint = Paint()..color = accent..style = PaintingStyle.fill;

    final nodes = [
      Offset(size.width * .50, size.height * .18),
      Offset(size.width * .15, size.height * .55),
      Offset(size.width * .85, size.height * .50),
      Offset(size.width * .40, size.height * .85),
      Offset(size.width * .75, size.height * .80),
    ];

    for (final e in [[0,1],[0,2],[1,3],[2,4],[1,2],[3,4]]) {
      canvas.drawLine(nodes[e[0]], nodes[e[1]], linePaint);
    }
    for (final n in nodes) canvas.drawCircle(n, 4, dotPaint);
  }

  @override bool shouldRepaint(_) => false;
}

// 2. Mini resume document ──────────────────────────────────────────────────────
class _ResumeGraphic extends StatelessWidget {
  const _ResumeGraphic({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: 0.16,
    child: Container(
      width: 52, height: 64,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 14, height: 14,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
        const SizedBox(height: 5),
        _line(28, 3), const SizedBox(height: 3),
        _line(18, 2), const SizedBox(height: 5),
        ...List.generate(4, (_) => Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: _line(double.infinity, 2),
        )),
      ]),
    ),
  );

  Widget _line(double w, double h) => Container(
    width: w, height: h,
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2)),
  );
}

// 3. Concentric rings / radar ─────────────────────────────────────────────────
class _RingsGraphic extends StatelessWidget {
  const _RingsGraphic({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: 0.18,
    child: SizedBox(
      width: 72, height: 72,
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
      ..color = accent..strokeWidth = 1.2..style = PaintingStyle.stroke;
    final center = Offset(size.width, 0); // anchor top-right
    for (final r in [14.0, 28.0, 42.0, 56.0, 70.0]) {
      canvas.drawCircle(center, r, paint);
    }
    // centre dot
    canvas.drawCircle(center, 3.5,
        Paint()..color = accent..style = PaintingStyle.fill);
  }

  @override bool shouldRepaint(_) => false;
}

// 4. Dotted grid ──────────────────────────────────────────────────────────────
class _DotsGraphic extends StatelessWidget {
  const _DotsGraphic({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: 0.20,
    child: SizedBox(
      width: 72, height: 72,
      child: CustomPaint(painter: _DotsPainter(accent: accent)),
    ),
  );
}

class _DotsPainter extends CustomPainter {
  const _DotsPainter({required this.accent});
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = accent..style = PaintingStyle.fill;
    const cols = 5; const rows = 5; const spacing = 14.0; const r = 2.0;
    for (var c = 0; c < cols; c++) {
      for (var row = 0; row < rows; row++) {
        canvas.drawCircle(
          Offset(c * spacing.toDouble() + 4, row * spacing.toDouble() + 4), r, paint);
      }
    }
  }

  @override bool shouldRepaint(_) => false;
}

// 5. Circuit-board traces ──────────────────────────────────────────────────────
class _CircuitGraphic extends StatelessWidget {
  const _CircuitGraphic({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: 0.18,
    child: SizedBox(
      width: 72, height: 72,
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
      ..color = accent..strokeWidth = 1.4..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;
    final dotPaint = Paint()..color = accent..style = PaintingStyle.fill;

    // Horizontal + vertical traces (Manhattan routing)
    final paths = [
      [Offset(72,8),  Offset(44,8),  Offset(44,24)],
      [Offset(72,28), Offset(56,28), Offset(56,44), Offset(36,44)],
      [Offset(72,50), Offset(60,50), Offset(60,64), Offset(40,64)],
      [Offset(52,8),  Offset(52,20), Offset(32,20), Offset(32,36)],
    ];

    for (final seg in paths) {
      final path = Path()..moveTo(seg[0].dx, seg[0].dy);
      for (final pt in seg.skip(1)) path.lineTo(pt.dx, pt.dy);
      canvas.drawPath(path, linePaint);
      // solder dot at end
      canvas.drawCircle(seg.last, 3, dotPaint);
    }
  }

  @override bool shouldRepaint(_) => false;
}

// 6. Wave pattern ────────────────────────────────────────────────────────────
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

// 7. Spark burst ─────────────────────────────────────────────────────────────
class _SparkGraphic extends StatelessWidget {
  const _SparkGraphic({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: 0.2,
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

// ─────────────────────────────────────────────────────────────────────────────
//  PALETTE  — pre-defined schemes ready to use
// ─────────────────────────────────────────────────────────────────────────────
class TileSchemes {
  static const peerConnect   = QuickActionTileScheme(bg: Color(0xFF0E1E38), accent: Color(0xFF4A90E2));
  static const resumeBuilder = QuickActionTileScheme(bg: Color(0xFF1A1207), accent: Color(0xFFE8A838));
  static const events        = QuickActionTileScheme(bg: Color(0xFF1A0E2B), accent: Color(0xFFB06FD8));
  static const coding        = QuickActionTileScheme(bg: Color(0xFF0D1A10), accent: Color(0xFF3ECF8E));
  static const mentorship    = QuickActionTileScheme(bg: Color(0xFF1F0E0E), accent: Color(0xFFE05252));
  static const courses       = QuickActionTileScheme(bg: Color(0xFF0E1A1F), accent: Color(0xFF38BDF8));
  static const neonOrange    = QuickActionTileScheme(bg: Color(0xFF2A1408), accent: Color(0xFFFF8A3D));
  static const magenta       = QuickActionTileScheme(bg: Color(0xFF240C1F), accent: Color(0xFFFF6BCB));
  static const lime          = QuickActionTileScheme(bg: Color(0xFF14200D), accent: Color(0xFF9BE15D));
  static const cyan          = QuickActionTileScheme(bg: Color(0xFF0B1F24), accent: Color(0xFF4DE2FF));
  static const coral         = QuickActionTileScheme(bg: Color(0xFF2A1115), accent: Color(0xFFFF7A8A));
}

class TileColorPreset {
  const TileColorPreset({required this.key, required this.label, required this.scheme});

  final String key;
  final String label;
  final QuickActionTileScheme scheme;
}

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

final homeQuickActionsProvider = StreamProvider<List<HomeQuickActionConfig>>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);

  return firestore
      .collection('config')
      .doc('homepage')
      .collection('quick_actions')
      .orderBy('sortOrder')
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => HomeQuickActionConfig.fromMap(doc.data(), doc.id))
          .toList());
});

final homeFeaturedProjectsProvider = StreamProvider<List<FeaturedProjectConfig>>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);

  return firestore
      .collection('config')
      .doc('homepage')
      .collection('featured_projects')
      .orderBy('sortOrder')
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => FeaturedProjectConfig.fromMap(doc.data(), doc.id))
          .toList());
});

// ═════════════════════════════════════════════════════════════════════════════
//  ROOT PAGE WIDGET
// ═════════════════════════════════════════════════════════════════════════════

class HomePageTab extends ConsumerStatefulWidget {
  const HomePageTab({super.key, this.onInternalRouteTap});

  final ValueChanged<String>? onInternalRouteTap;

  @override
  ConsumerState<HomePageTab> createState() => _HomePageTabState();
}

class _HomePageTabState extends ConsumerState<HomePageTab> {
  static const List<TileColorPreset> _tileColorPresets = [
    TileColorPreset(key: 'peerConnect', label: 'Ocean Blue', scheme: TileSchemes.peerConnect),
    TileColorPreset(key: 'resumeBuilder', label: 'Amber Gold', scheme: TileSchemes.resumeBuilder),
    TileColorPreset(key: 'events', label: 'Violet', scheme: TileSchemes.events),
    TileColorPreset(key: 'coding', label: 'Mint Green', scheme: TileSchemes.coding),
    TileColorPreset(key: 'mentorship', label: 'Ruby Red', scheme: TileSchemes.mentorship),
    TileColorPreset(key: 'courses', label: 'Sky Cyan', scheme: TileSchemes.courses),
    TileColorPreset(key: 'neonOrange', label: 'Neon Orange', scheme: TileSchemes.neonOrange),
    TileColorPreset(key: 'magenta', label: 'Magenta Pop', scheme: TileSchemes.magenta),
    TileColorPreset(key: 'lime', label: 'Lime Fresh', scheme: TileSchemes.lime),
    TileColorPreset(key: 'cyan', label: 'Aqua Glow', scheme: TileSchemes.cyan),
    TileColorPreset(key: 'coral', label: 'Coral Bloom', scheme: TileSchemes.coral),
  ];

  // ── Add-carousel bottom sheet (logic unchanged) ───────────────────────────
  Future<void> _showAddCarouselDocSheet() async {
    final imageCtrl       = TextEditingController();
    final titleCtrl       = TextEditingController();
    final subtitleCtrl    = TextEditingController();
    final actionValueCtrl = TextEditingController();
    final orderCtrl       = TextEditingController(text: '0');
    var actionType        = HomeCarouselActionType.url;
    var isActive          = true;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: UniSyncColors.backgroundSecondary,
      builder: (context) => StatefulBuilder(builder: (context, setModalState) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16, right: 16, top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Add Carousel Doc (Temporary)',
                  style: TextStyle(color: UniSyncColors.textPrimary,
                      fontSize: 18, fontWeight: FontWeight.w700)),
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
                    decoration: const InputDecoration(labelText: 'Action Type *'),
                    dropdownColor: UniSyncColors.surfaceCard,
                    items: const [
                      DropdownMenuItem(value: HomeCarouselActionType.url,   child: Text('url')),
                      DropdownMenuItem(value: HomeCarouselActionType.route, child: Text('route')),
                    ],
                    onChanged: (v) { if (v != null) setModalState(() => actionType = v); },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: _inputField(controller: orderCtrl,
                    label: 'Order', keyboardType: TextInputType.number)),
              ]),
              const SizedBox(height: 10),
              _inputField(controller: actionValueCtrl,
                  label: actionType == HomeCarouselActionType.url ? 'URL *' : 'Route path *'),
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
                          const SnackBar(content: Text('Please fill all required fields')));
                      return;
                    }
                    await ref.read(homeCarouselControllerProvider.notifier)
                        .createCarouselItem(
                          imageUrl: imageCtrl.text, title: titleCtrl.text,
                          subtitle: subtitleCtrl.text, actionType: actionType,
                          actionValue: actionValueCtrl.text,
                          order: int.tryParse(orderCtrl.text.trim()) ?? 0,
                          isActive: isActive,
                        );
                    if (!mounted) return;
                    Navigator.of(this.context).pop();
                    ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(content: Text('Carousel document added')));
                  },
                  child: const Text('Add to Firebase'),
                ),
              ),
            ]),
          ),
        );
      }),
    );
    imageCtrl.dispose(); titleCtrl.dispose(); subtitleCtrl.dispose();
    actionValueCtrl.dispose(); orderCtrl.dispose();
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
  }) =>
      TextField(controller: controller, keyboardType: keyboardType,
          decoration: InputDecoration(labelText: label));

  List<HomeQuickActionConfig> _defaultCoreQuickActions() => const [
        HomeQuickActionConfig(
          key: 'peer_connect',
          title: 'Peer\nConnect',
          chipLabel: '200+ online',
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
          route: '/campXLogin',
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
          description: 'Student portfolio and project showcase for campus builders.',
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
          description: 'Tracks exam patterns and gives quick weekly prep plans.',
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
          description: 'Roommate finder and hostel issue tracker by fellow students.',
          creatorName: 'Siri M',
        ),
      ];

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
    final value = color.value.toRadixString(16).padLeft(8, '0').toUpperCase();
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
      quickBatch.set(docRef, {
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
      }, SetOptions(merge: true));
    }

    for (final item in _defaultFeaturedProjects()) {
      final docRef = homepageRef.collection('featured_projects').doc(item.key);
      quickBatch.set(docRef, {
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
      }, SetOptions(merge: true));
    }

    await quickBatch.commit();
  }

  List<HomeQuickActionConfig> _mergeQuickActions(List<HomeQuickActionConfig> remote) {
    final defaults = _defaultCoreQuickActions();
    if (remote.isEmpty) return defaults;

    final byKey = <String, HomeQuickActionConfig>{
      for (final item in remote) item.key: item,
    };

    final merged = <HomeQuickActionConfig>[];
    for (final item in defaults) {
      merged.add(byKey[item.key] ?? item);
    }

    final defaultKeys = defaults.map((e) => e.key).toSet();
    merged.addAll(
      remote.where((e) => !defaultKeys.contains(e.key)),
    );

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
    if (key == 'aptitude' || key == 'uni_cards') {
      return '/nextUpdatePromo';
    }
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
                ListTile(
                  leading: const Icon(Icons.cloud_upload_rounded),
                  title: const Text('Seed Default Home Config'),
                  subtitle: const Text('Adds core features + 3 featured projects'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _seedHomeConfig();
                    if (!mounted) return;
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(content: Text('Default home config seeded')),
                    );
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
                  Row(
                    children: [
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
                    ],
                  ),
                  const SizedBox(height: 12),
                  _inputField(controller: keyCtrl, label: 'Key (optional)'),
                  const SizedBox(height: 8),
                  _inputField(controller: titleCtrl, label: 'Title *'),
                  const SizedBox(height: 8),
                  if (isQuickAction) ...[
                    _inputField(controller: chipCtrl, label: 'Chip label *'),
                    const SizedBox(height: 8),
                    _inputField(controller: ctaCtrl, label: 'CTA label *'),
                    const SizedBox(height: 8),
                    _inputField(controller: routeCtrl, label: 'App route'),
                    const SizedBox(height: 8),
                    _inputField(controller: urlCtrl, label: 'External URL (optional)'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: section,
                      decoration: const InputDecoration(labelText: 'Section'),
                      items: const [
                        DropdownMenuItem(value: 'core', child: Text('core')),
                        DropdownMenuItem(value: 'external', child: Text('external')),
                      ],
                      onChanged: (v) {
                        if (v != null) setModalState(() => section = v);
                      },
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: iconKey,
                      decoration: const InputDecoration(labelText: 'Icon key'),
                      items: const [
                        DropdownMenuItem(value: 'apps', child: Text('apps')),
                        DropdownMenuItem(value: 'people', child: Text('people')),
                        DropdownMenuItem(value: 'calendar', child: Text('calendar')),
                        DropdownMenuItem(value: 'bolt', child: Text('bolt')),
                        DropdownMenuItem(value: 'style', child: Text('style')),
                        DropdownMenuItem(value: 'description', child: Text('description')),
                      ],
                      onChanged: (v) {
                        if (v != null) setModalState(() => iconKey = v);
                      },
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: graphicKey,
                      decoration: const InputDecoration(labelText: 'Graphic key'),
                      items: const [
                        DropdownMenuItem(value: 'none', child: Text('none')),
                        DropdownMenuItem(value: 'network', child: Text('network')),
                        DropdownMenuItem(value: 'resume', child: Text('resume')),
                        DropdownMenuItem(value: 'rings', child: Text('rings')),
                        DropdownMenuItem(value: 'dots', child: Text('dots')),
                        DropdownMenuItem(value: 'circuit', child: Text('circuit')),
                        DropdownMenuItem(value: 'wave', child: Text('wave')),
                        DropdownMenuItem(value: 'spark', child: Text('spark')),
                      ],
                      onChanged: (v) {
                        if (v != null) setModalState(() => graphicKey = v);
                      },
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: colorPresetKey,
                      decoration: const InputDecoration(labelText: 'Tile color theme'),
                      items: _tileColorPresets
                          .map(
                            (preset) => DropdownMenuItem(
                              value: preset.key,
                              child: Text(preset.label),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        final selected = _tileColorPresets.firstWhere((item) => item.key == v);
                        setModalState(() {
                          colorPresetKey = v;
                          bgColorCtrl.text = _colorToHex(selected.scheme.bg);
                          accentColorCtrl.text = _colorToHex(selected.scheme.accent);
                        });
                      },
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Selected: bg ${bgColorCtrl.text} · accent ${accentColorCtrl.text}',
                      style: const TextStyle(
                        color: UniSyncColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ] else ...[
                    _inputField(controller: descriptionCtrl, label: 'Description'),
                    const SizedBox(height: 8),
                    _inputField(controller: projectChipCtrl, label: 'Chip label'),
                    const SizedBox(height: 8),
                    _inputField(controller: projectCtaCtrl, label: 'CTA label'),
                    const SizedBox(height: 8),
                    _inputField(controller: urlCtrl, label: 'Website URL *'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: graphicKey,
                      decoration: const InputDecoration(labelText: 'Graphic key'),
                      items: const [
                        DropdownMenuItem(value: 'none', child: Text('none')),
                        DropdownMenuItem(value: 'network', child: Text('network')),
                        DropdownMenuItem(value: 'resume', child: Text('resume')),
                        DropdownMenuItem(value: 'rings', child: Text('rings')),
                        DropdownMenuItem(value: 'dots', child: Text('dots')),
                        DropdownMenuItem(value: 'circuit', child: Text('circuit')),
                        DropdownMenuItem(value: 'wave', child: Text('wave')),
                        DropdownMenuItem(value: 'spark', child: Text('spark')),
                      ],
                      onChanged: (v) {
                        if (v != null) setModalState(() => graphicKey = v);
                      },
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: colorPresetKey,
                      decoration: const InputDecoration(labelText: 'Tile color theme'),
                      items: _tileColorPresets
                          .map(
                            (preset) => DropdownMenuItem(
                              value: preset.key,
                              child: Text(preset.label),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        final selected = _tileColorPresets.firstWhere((item) => item.key == v);
                        setModalState(() {
                          colorPresetKey = v;
                          bgColorCtrl.text = _colorToHex(selected.scheme.bg);
                          accentColorCtrl.text = _colorToHex(selected.scheme.accent);
                        });
                      },
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Selected: bg ${bgColorCtrl.text} · accent ${accentColorCtrl.text}',
                      style: const TextStyle(
                        color: UniSyncColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  _inputField(controller: creatorCtrl, label: 'Creator name (for credits)'),
                  const SizedBox(height: 8),
                  _inputField(
                    controller: orderCtrl,
                    label: 'Sort order',
                    keyboardType: TextInputType.number,
                  ),
                  SwitchListTile(
                    value: visible,
                    onChanged: (v) => setModalState(() => visible = v),
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
                            const SnackBar(content: Text('Title is required')),
                          );
                          return;
                        }

                        final normalizedUrl = _normalizeWebUrl(urlCtrl.text);

                        if (isQuickAction &&
                            (chipCtrl.text.trim().isEmpty || ctaCtrl.text.trim().isEmpty)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Chip and CTA are required for quick action')),
                          );
                          return;
                        }

                        if (isQuickAction &&
                            routeCtrl.text.trim().isEmpty &&
                            urlCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Provide either app route or external URL')),
                          );
                          return;
                        }

                        if (isQuickAction &&
                            urlCtrl.text.trim().isNotEmpty &&
                            normalizedUrl == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Enter a valid external URL (http/https)')),
                          );
                          return;
                        }

                        if (!isQuickAction && urlCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Website URL is required for project')),
                          );
                          return;
                        }

                        if (!isQuickAction && normalizedUrl == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Enter a valid website URL (http/https)')),
                          );
                          return;
                        }

                        final docId = keyCtrl.text.trim().isEmpty
                            ? DateTime.now().millisecondsSinceEpoch.toString()
                            : keyCtrl.text.trim();
                        final order = int.tryParse(orderCtrl.text.trim()) ?? 0;

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
                            'accentColorHex': accentColorCtrl.text.trim(),
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
                            'accentColorHex': accentColorCtrl.text.trim(),
                            'creatorName': creatorCtrl.text.trim(),
                            'visible': visible,
                            'sortOrder': order,
                            'updatedAt': FieldValue.serverTimestamp(),
                          }, SetOptions(merge: true));
                        }

                        if (!mounted) return;
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(content: Text('Home config updated')),
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
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Text(
                          'No quick actions in config yet.',
                          style: TextStyle(color: UniSyncColors.textSecondary),
                        );
                      }

                      final docs = snapshot.data!.docs;
                      return Column(
                        children: docs.map((doc) {
                          final data = doc.data();
                          return SwitchListTile(
                            title: Text(
                              (data['title'] ?? doc.id).toString(),
                              style: const TextStyle(color: UniSyncColors.textPrimary),
                            ),
                            subtitle: Text(
                              (data['section'] ?? 'core').toString(),
                              style: const TextStyle(color: UniSyncColors.textMuted),
                            ),
                            value: data['visible'] != false,
                            onChanged: (value) {
                              doc.reference.set({'visible': value}, SetOptions(merge: true));
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
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Text(
                          'No featured projects in config yet.',
                          style: TextStyle(color: UniSyncColors.textSecondary),
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
                                    (data['title'] ?? doc.id).toString(),
                                    style: const TextStyle(color: UniSyncColors.textPrimary),
                                  ),
                                  subtitle: Text(
                                    (data['creatorName'] ?? 'Creator not set').toString(),
                                    style: const TextStyle(color: UniSyncColors.textMuted),
                                  ),
                                  value: data['visible'] != false,
                                  onChanged: (value) {
                                    doc.reference.set({'visible': value}, SetOptions(merge: true));
                                  },
                                  contentPadding: EdgeInsets.zero,
                                  activeThumbColor: UniSyncColors.accent,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded),
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

  @override
  Widget build(BuildContext context) {
    final user          = ref.watch(userProvider);
    final carouselState = ref.watch(homeCarouselControllerProvider);
    final quickActionsState = ref.watch(homeQuickActionsProvider);
    final featuredProjectsState = ref.watch(homeFeaturedProjectsProvider);
    final userName      = user?.name.trim();
    final firstName     = (userName == null || userName.isEmpty)
        ? 'there' : userName.split(' ').first;

    final mergedQuickActions = _mergeQuickActions(
      quickActionsState.valueOrNull ?? const [],
    );
    final visibleTiles = _toQuickTiles(mergedQuickActions);
    final featuredProjects = (featuredProjectsState.valueOrNull ?? const [])
        .where((item) => item.visible)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return Scaffold(
      backgroundColor: UniSyncColors.backgroundPrimary,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAdminToolsSheet,
        backgroundColor: UniSyncColors.accent,
        foregroundColor: UniSyncColors.buttonPrimaryFg,
        icon: const Icon(Icons.build_rounded),
        label: const Text('Admin Tools'),
      ),
      body: SafeArea(
        child: CustomScrollView(slivers: [
          // ── App bar ─────────────────────────────────────────────────
          SliverAppBar(
            floating: true, snap: true, pinned: false, elevation: 0,
            toolbarHeight: 68,
            backgroundColor: UniSyncColors.backgroundSecondary,
            titleSpacing: 0,
            automaticallyImplyLeading: false,
            shape: const Border(
                bottom: BorderSide(color: UniSyncColors.divider, width: 0.8)),
            title: _TopBar(
              firstName: firstName,
              userPhotoUrl: user?.photoUrl,
              coins: user?.coins ?? 0,
            ),
          ),

          SliverToBoxAdapter(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 26),

              // ── Carousel ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _SpotlightHeader(
                    eyebrow: '#HAPPENING',
                    title: 'Cool things', highlight: 'around you'),
              ),
              const SizedBox(height: 14),
              _HomeCarouselSection(carouselState: carouselState),

              const SizedBox(height: 32),

              // ── Feature block ──────────────────────────────────────
              Container(
                color: UniSyncColors.backgroundSecondary,
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 28),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const _SpotlightHeader(
                      eyebrow: '#BUILT FOR YOU',
                      title: 'Level up', highlight: 'your game'),
                  const SizedBox(height: 20),

                  // Interview card
                  _NeoInterviewCard(
                    parentContext: context,
                    onInternalRouteTap: widget.onInternalRouteTap,
                  ),
                  const SizedBox(height: 14),

                  // ── 2-column tile grid ───────────────────────────
                  // Tiles auto-wrap: odd count gets a full-width last tile
                  if (visibleTiles.isNotEmpty)
                    _TileGrid(tiles: visibleTiles),

                  if (featuredProjects.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const _SpotlightHeader(
                      eyebrow: '#FEATURED PROJECTS',
                      title: 'Built by',
                      highlight: 'fellow students',
                    ),
                    const SizedBox(height: 14),
                    _FeaturedProjectList(projects: featuredProjects),
                    const SizedBox(height: 8),
                    const Text(
                      'Built something cool and want your project to be listed and visible to 5k+ students? Email us at hello.unisync@gmail.com',
                      style: TextStyle(
                        color: UniSyncColors.textMuted,
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                  ],
                ]),
              ),

              const SizedBox(height: 28),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ─── 2-column grid that wraps automatically ──────────────────────────────────
class _TileGrid extends StatelessWidget {
  const _TileGrid({required this.tiles});
  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < tiles.length; i += 2) {
      final isLast  = i + 1 >= tiles.length;
      rows.add(Row(children: [
        Expanded(child: tiles[i]),
        if (!isLast) ...[const SizedBox(width: 12), Expanded(child: tiles[i + 1])]
        else         const Spacer(),
      ]));
      if (i + 2 < tiles.length) rows.add(const SizedBox(height: 12));
    }
    return Column(children: rows);
  }
}

class _FeaturedProjectList extends StatelessWidget {
  const _FeaturedProjectList({required this.projects});
  final List<FeaturedProjectConfig> projects;

  @override
  Widget build(BuildContext context) {
    final tiles = projects
        .map(
          (project) => _FeaturedProjectTile(project: project),
        )
        .toList();
    return _TileGrid(tiles: tiles);
  }
}

class _FeaturedProjectTile extends StatelessWidget {
  const _FeaturedProjectTile({required this.project});
  final FeaturedProjectConfig project;

  Color _parseHexColor(String? hex, Color fallback) {
    if (hex == null || hex.trim().isEmpty) return fallback;
    final value = hex.replaceAll('#', '').trim();
    if (value.length != 6 && value.length != 8) return fallback;
    final normalized = value.length == 6 ? 'FF$value' : value;
    return Color(int.tryParse(normalized, radix: 16) ?? fallback.value);
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

  @override
  Widget build(BuildContext context) {
    final creator = (project.creatorName ?? '').trim();
    final desc = (project.description ?? '').trim();
    final chipLabel = (project.chipLabel ?? 'Student build').trim();
    final ctaLabel = (project.ctaLabel ?? 'Open project').trim();
    final accent = _parseHexColor(project.accentColorHex, const Color(0xFF5AA9FF));
    final bg = _parseHexColor(project.bgColorHex, const Color(0xFF101626));
    final graphic = _graphicFromKey(project.graphicKey ?? 'none');

    return NeoPopButton(
      color: bg,
      bottomShadowColor: accent,
      rightShadowColor: accent,
      depth: 4,
      onTapDown: () {},
      onTapUp: () {
        final url = project.websiteUrl.trim();
        if (url.isNotEmpty) {
          final uri = Uri.tryParse(url);
          if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
            launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
      },
      child: SizedBox(
        height: 220,
        child: Stack(
          children: [
            if (graphic != QuickActionGraphic.none)
              Positioned(
                top: 8,
                right: 8,
                child: QuickActionTile._buildGraphic(graphic, accent),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: accent.withOpacity(0.28)),
                    ),
                    child: Icon(Icons.travel_explore_rounded,
                        size: 18, color: accent),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            chipLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: accent,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        if (desc.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            desc,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: UniSyncColors.textSecondary,
                              fontSize: 11,
                              height: 1.25,
                            ),
                          ),
                        ],
                        if (creator.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'By $creator',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.68),
                            ),
                          ),
                        ],
                        const SizedBox(height: 7),
                        Row(
                          children: [
                            Text(
                              ctaLabel,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: accent,
                              ),
                            ),
                            const SizedBox(width: 3),
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
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  REST OF UI (unchanged structure, unchanged logic)
// ═════════════════════════════════════════════════════════════════════════════

// ── Spotlight heading ────────────────────────────────────────────────────────
class _SpotlightHeader extends StatelessWidget {
  const _SpotlightHeader({
    required this.eyebrow, required this.title, required this.highlight,
    this.actionLabel, this.onAction,
  });
  final String eyebrow, title, highlight;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(eyebrow, style: const TextStyle(
              color: UniSyncColors.accent, fontSize: 10,
              fontWeight: FontWeight.w700, letterSpacing: 1.8)),
          const SizedBox(height: 4),
          RichText(text: TextSpan(children: [
            TextSpan(text: '$title ',
                style: const TextStyle(color: UniSyncColors.textPrimary,
                    fontSize: 26, fontWeight: FontWeight.w800,
                    letterSpacing: -0.6, height: 1.1)),
            TextSpan(text: highlight,
                style: const TextStyle(color: UniSyncColors.accent,
                    fontSize: 26, fontWeight: FontWeight.w800,
                    letterSpacing: -0.6, height: 1.1)),
          ])),
        ]),
      ),
      if (actionLabel != null && onAction != null)
        GestureDetector(
          onTap: onAction,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(actionLabel!, style: const TextStyle(
                color: UniSyncColors.accent, fontSize: 12,
                fontWeight: FontWeight.w600)),
            const SizedBox(width: 2),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 10, color: UniSyncColors.accent),
          ]),
        ),
    ]);
  }
}

// ── App bar ──────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.firstName,
    required this.userPhotoUrl,
    required this.coins,
  });
  final String firstName;
  final String? userPhotoUrl;
  final int coins;

  @override
  Widget build(BuildContext context) {
    final username = firstName.trim().isEmpty ? 'there' : firstName;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(alignment: Alignment.center, children: [
        NeoPopButton(
          buttonPosition: Position.center,
          parentColor: Colors.transparent,
          color: Colors.transparent,
          onTapUp: () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: SvgPicture.asset('assets/svg/unisync_svg.svg', height: 34),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(mainAxisSize: MainAxisSize.min, children: const [
                Text('HEY', style: TextStyle(
                    color: UniSyncColors.textSecondary,
                    fontSize: 10, fontWeight: FontWeight.w700,
                    letterSpacing: 2.2)),
                SizedBox(width: 3),
                Text('👋', style: TextStyle(fontSize: 11)),
              ]),
              const SizedBox(height: 1),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 120),
                child: Text(
                  username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: UniSyncColors.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            NeoPopButton(
              color: UniSyncColors.surfaceCard,
              bottomShadowColor: UniSyncColors.accent,
              rightShadowColor: UniSyncColors.accent,
              depth: 3,
              onTapUp: () {},
              onTapDown: () {},
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.monetization_on_rounded,
                      size: 14, color: UniSyncColors.accent),
                  const SizedBox(width: 4),
                  Text(
                    '$coins',
                    style: const TextStyle(
                      color: UniSyncColors.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ]),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => Routemaster.of(context).push('/profile'),
              borderRadius: BorderRadius.circular(999),
              child: Stack(children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: UniSyncColors.accent, width: 1.8),
                  ),
                  child: CircleAvatar(
                    radius: 19,
                    backgroundColor: UniSyncColors.surfaceElevated,
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: userPhotoUrl ?? '',
                        fit: BoxFit.cover,
                        width: 38,
                        height: 38,
                        placeholder: (_, __) => const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        errorWidget: (_, __, ___) => const Icon(
                          Icons.person,
                          color: UniSyncColors.textMuted,
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
                      color: UniSyncColors.accent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: UniSyncColors.backgroundSecondary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ── Interview card (emerald theme, unchanged) ─────────────────────────────────
class _NeoInterviewCard extends StatelessWidget {
  const _NeoInterviewCard({
    required this.parentContext,
    this.onInternalRouteTap,
  });
  final BuildContext parentContext;
  final ValueChanged<String>? onInternalRouteTap;

  static const _accent = Color(0xFF3ECF8E);
  static const _bg     = Color(0xFF0D1F18);

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
    return NeoPopButton(
      color: _bg,
      bottomShadowColor: _accent,
      rightShadowColor: _accent,
      depth: 5,
      onTapUp: _openInterview, onTapDown: () {},
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _accent.withOpacity(0.3)),
              ),
              child: const Icon(Icons.smart_toy_outlined, size: 22, color: _accent),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
              Text('AI Mock Interviews', style: TextStyle(fontSize: 15,
                  fontWeight: FontWeight.w700, color: Colors.white,
                  letterSpacing: -0.2)),
              SizedBox(height: 2),
              Text('Powered by Uni · your AI interviewer',
                  style: TextStyle(fontSize: 11, color: Colors.white54)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _accent.withOpacity(0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 5, height: 5,
                    decoration: const BoxDecoration(
                        color: _accent, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                const Text('LIVE', style: TextStyle(fontSize: 9,
                    fontWeight: FontWeight.w800, color: _accent, letterSpacing: 1.0)),
              ]),
            ),
          ]),
          const SizedBox(height: 14),
          Wrap(spacing: 6, runSpacing: 6, children: const [
            _FeatureTag(label: 'Real questions', accent: _accent),
            _FeatureTag(label: 'Instant feedback', accent: _accent),
            _FeatureTag(label: 'All domains', accent: _accent),
          ]),
          const SizedBox(height: 14),
          Divider(color: Colors.white.withOpacity(0.07), height: 1),
          const SizedBox(height: 14),
          Row(children: const [
            _StatItem(value: '500+', label: 'Questions', accent: _accent),
            _VDivider(),
            _StatItem(value: '12+',  label: 'Domains',   accent: _accent),
            _VDivider(),
            _StatItem(value: '4.9★', label: 'Rating',    accent: _accent),
          ]),
          const SizedBox(height: 16),
          NeoPopButton(
            color: _accent,
            bottomShadowColor: Colors.black,
            rightShadowColor: Colors.black,
            depth: 4,
            buttonPosition: Position.fullBottom,
            onTapUp: _openInterview,
            onTapDown: () {},
            child: const SizedBox(height: 46,
              child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.rocket_launch_rounded, size: 16, color: Colors.black),
                SizedBox(width: 8),
                Text('Start Interview', style: TextStyle(fontSize: 14,
                    fontWeight: FontWeight.w800, color: Colors.black,
                    letterSpacing: 0.2)),
              ])),
            ),
          ),
        ]),
      ),
    );
  }
}

class _FeatureTag extends StatelessWidget {
  const _FeatureTag({required this.label, required this.accent});
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: accent.withOpacity(0.08),
      borderRadius: BorderRadius.circular(5),
      border: Border.all(color: accent.withOpacity(0.2)),
    ),
    child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
        color: accent.withOpacity(0.9), letterSpacing: 0.2)),
  );
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.value, required this.label, required this.accent});
  final String value, label;
  final Color accent;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(children: [
      Text(value, style: TextStyle(color: accent, fontSize: 15,
          fontWeight: FontWeight.w800, letterSpacing: -0.2)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10,
          fontWeight: FontWeight.w500)),
    ]),
  );
}

class _VDivider extends StatelessWidget {
  const _VDivider();
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 28, color: Colors.white12);
}

// ── Carousel ──────────────────────────────────────────────────────────────────
class _HomeCarouselSection extends ConsumerStatefulWidget {
  const _HomeCarouselSection({required this.carouselState});
  final AsyncValue<List<HomeCarouselItem>> carouselState;

  @override
  ConsumerState<_HomeCarouselSection> createState() =>
      _HomeCarouselSectionState();
}

class _HomeCarouselSectionState extends ConsumerState<_HomeCarouselSection> {
  int _currentIndex = 0;
  final SwiperController _swiperController = SwiperController();

  @override
  void dispose() { _swiperController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return widget.carouselState.when(
      data: (items) {
        if (items.isEmpty) return _fallback(
            title: 'No highlights yet',
            subtitle: 'okoko will add them soon.',
            icon: Icons.photo_library_outlined);

        return Column(children: [
          SizedBox(
            height: 186,
            child: Swiper(
              controller: _swiperController,
              itemCount: items.length,
              autoplay: items.length > 1, autoplayDelay: 3800, duration: 400,
              loop: items.length > 1,
              viewportFraction: 0.9, scale: 0.95,
              onIndexChanged: (i) => setState(() => _currentIndex = i),
              itemBuilder: (context, index) {
                final item = items[index];
                return RepaintBoundary(
                  child: InkWell(
                    onTap: () => ref
                        .read(homeCarouselControllerProvider.notifier)
                        .onBannerTap(context, item),
                    child: Stack(fit: StackFit.expand, children: [
                      CachedNetworkImage(
                        imageUrl: item.imageUrl, fit: BoxFit.cover,
                        memCacheWidth: 1400,
                        placeholder: (_, __) => Container(
                            color: UniSyncColors.surfaceCard,
                            child: const Center(
                                child: CircularProgressIndicator(strokeWidth: 2))),
                        errorWidget: (_, __, ___) => Container(
                            color: UniSyncColors.surfaceCard,
                            alignment: Alignment.center,
                            child: const Icon(Icons.image_not_supported_outlined,
                                color: UniSyncColors.textMuted)),
                      ),
                      const DecoratedBox(decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter, end: Alignment.bottomCenter,
                          stops: [0.45, 1.0],
                          colors: [Color(0x00000000), Color(0xD5000000)],
                        ),
                      )),
                      Positioned(left: 14, right: 14, bottom: 14,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(item.title, maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white,
                                  fontSize: 16, fontWeight: FontWeight.w700)),
                          if (item.subtitle.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(item.subtitle, maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Colors.white60, fontSize: 12)),
                          ],
                        ]),
                      ),
                    ]),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(items.length, (i) {
                final active = i == _currentIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOut,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  height: 5, width: active ? 20 : 5,
                  decoration: BoxDecoration(
                    color: active ? UniSyncColors.accent : UniSyncColors.border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                );
              })),
        ]);
      },
      loading: () => _fallback(title: 'Loading highlights',
          subtitle: 'Pulling fresh cards for you...',
          icon: Icons.hourglass_top_rounded, showLoader: true),
      error: (_, __) => _fallback(title: 'Could not load',
          subtitle: 'Check your connection and try again.',
          icon: Icons.wifi_off_rounded, showRetry: true),
    );
  }

  Widget _fallback({
    required String title, required String subtitle, required IconData icon,
    bool showRetry = false, bool showLoader = false,
  }) {
    return Container(
      height: 186,
      width: 1/0,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: UniSyncColors.surfaceCard,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        if (showLoader)
          const SizedBox(width: 24, height: 24,
              child: CircularProgressIndicator(strokeWidth: 2))
        else
          Icon(icon, color: UniSyncColors.textMuted, size: 24),
        const SizedBox(height: 10),
        Text(title, style: const TextStyle(color: UniSyncColors.textPrimary,
            fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(subtitle, textAlign: TextAlign.center,
            style: const TextStyle(color: UniSyncColors.textSecondary, fontSize: 12)),
        if (showRetry) ...[
          const SizedBox(height: 12),
          TextButton(
            onPressed: () =>
                ref.read(homeCarouselControllerProvider.notifier).refresh(),
            child: const Text('Retry'),
          ),
        ],
      ]),
    );
  }
}