import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:UniSync/features/HomeScreen/models/hero_banner_style.dart';

enum HomeCarouselActionType {
  url,
  route,
}

String homeCarouselActionTypeToValue(HomeCarouselActionType type) {
  switch (type) {
    case HomeCarouselActionType.route:
      return 'route';
    case HomeCarouselActionType.url:
      return 'url';
  }
}

class HomeCarouselItem {
  const HomeCarouselItem({
    required this.id,
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    required this.actionType,
    required this.actionValue,
    required this.isActive,
    required this.order,
    this.ctaLabel = 'Explore',
    this.palette = HeroBannerPalette.fallback,
    this.backdrop = HeroBannerBackdropStyle.fallback,
    this.art = HeroBannerArt.fallback,
    this.artAsset,
  });

  final String id;

  /// Remote artwork override. Legacy field name — kept so existing Firestore
  /// docs and the admin sheet keep working unchanged.
  final String imageUrl;
  final String title;
  final String subtitle;
  final HomeCarouselActionType actionType;
  final String actionValue;
  final bool isActive;
  final int order;

  // ── Hero banner presentation ───────────────────────────────────────────────
  final String ctaLabel;
  final HeroBannerPalette palette;
  final HeroBannerBackdropStyle backdrop;
  final HeroBannerArt art;

  /// Bundled asset override, sitting between [imageUrl] and [art] in the
  /// resolution order below.
  final String? artAsset;

  /// Artwork resolves remote URL → bundled asset override → shipped enum asset.
  /// Every path falls back to the shipped SVG on error, so a dead URL still
  /// renders a finished-looking banner.
  String? get resolvedArtUrl => _normalize(imageUrl);
  String? get resolvedArtAsset => _normalize(artAsset) ?? art.asset;

  factory HomeCarouselItem.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    return HomeCarouselItem(
      id: doc.id,
      imageUrl: (data['imageUrl'] ?? '').toString(),
      title: (data['title'] ?? '').toString(),
      subtitle: (data['subtitle'] ?? '').toString(),
      actionType: _parseActionType((data['actionType'] ?? '').toString()),
      actionValue: (data['actionValue'] ?? '').toString(),
      // A doc with no `isActive` field defaults to visible.
      isActive: data['isActive'] is bool ? data['isActive'] as bool : true,
      order: (data['order'] as num?)?.toInt() ??
          int.tryParse((data['order'] ?? '').toString()) ??
          0,
      ctaLabel: _normalize(data['ctaLabel']?.toString()) ?? 'Explore',
      palette: HeroBannerPalette.parse(data['palette']?.toString()),
      backdrop: HeroBannerBackdropStyle.parse(data['backdrop']?.toString()),
      art: HeroBannerArt.parse(data['art']?.toString()),
      artAsset: _normalize(data['artAsset']?.toString()),
    );
  }

  static HomeCarouselActionType _parseActionType(String value) {
    switch (value.toLowerCase().trim()) {
      case 'route':
      case 'app':
      case 'in_app':
      case 'inapp':
        return HomeCarouselActionType.route;
      case 'url':
      default:
        return HomeCarouselActionType.url;
    }
  }

  /// Empty strings normalize to null so callers can use `??` chains.
  static String? _normalize(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  // ───────────────────────────────────────────────────────────────────────────
  //  BUNDLED DEFAULTS
  //
  //  Used until Firestore answers, and whenever it answers with nothing —
  //  empty collection, no network, rejected read. The carousel is never blank,
  //  so the app looks finished before anyone touches the console.
  //
  //  Two palettes, two backdrops, two artworks: enough for the carousel to
  //  loop and to show its range without shipping a banner for a feature the
  //  user may not have connected yet.
  // ───────────────────────────────────────────────────────────────────────────
  static const List<HomeCarouselItem> defaults = [
    HomeCarouselItem(
      id: '_default_interview',
      imageUrl: '',
      title: 'Practice the interview first',
      subtitle:
          'AI mock rounds with feedback on what you actually said, not just '
          'whether you finished.',
      actionType: HomeCarouselActionType.route,
      actionValue: '/carrer-interview-screen',
      isActive: true,
      order: 0,
      ctaLabel: 'Start a mock',
      palette: HeroBannerPalette.indigo,
      backdrop: HeroBannerBackdropStyle.sunburst,
      art: HeroBannerArt.desk,
    ),
    HomeCarouselItem(
      id: '_default_opportunities',
      imageUrl: '',
      title: 'Internships worth your time',
      subtitle:
          'Hand-picked openings and hackathons, filtered for students who '
          'are still in college.',
      actionType: HomeCarouselActionType.route,
      actionValue: '/opportunities',
      isActive: true,
      order: 1,
      ctaLabel: 'Browse openings',
      palette: HeroBannerPalette.plum,
      backdrop: HeroBannerBackdropStyle.rings,
      art: HeroBannerArt.chart,
    ),
  ];
}
