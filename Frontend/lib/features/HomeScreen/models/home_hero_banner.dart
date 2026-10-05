import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:UniSync/features/HomeScreen/models/hero_banner_style.dart';

/// Firestore collection backing the home hero banner.
///
/// Deliberately separate from the legacy `home_carousel` collection. That one
/// was shaped for an image-in-a-box carousel — `imageUrl` was mandatory and
/// there was nowhere to put a palette, a backdrop or a CTA label — so the
/// hero banner had been bolted onto it with optional fields and a legacy
/// field name doing double duty. This schema says what it means.
const kHomeHeroBannerCollection = 'home_hero_banners';

/// How a custom image is placed on a slide.
enum HeroBannerImageMode {
  /// The image sits centre-right as the artwork, the way the bundled SVGs do.
  /// Use for cut-out subjects on a transparent or matching background.
  art,

  /// The image covers the entire slide, with a scrim so the app's title and
  /// subtitle stay readable over it. Use when you want a photographic
  /// background but still want the copy managed from Firestore.
  cover,

  /// The image *is* the slide: full bleed, no scrim, no app text at all.
  ///
  /// Use for a banner a designer has already finished — one whose own
  /// artwork contains the headline. Anything the app drew on top would
  /// duplicate or fight it, so in this mode the app draws nothing but the
  /// image. `title` and `subtitle` are ignored for display, though they are
  /// still worth filling in as a description of the banner.
  full;

  static const fallback = HeroBannerImageMode.art;

  /// True when the image fills the slide rather than sitting in it.
  bool get isFullBleed => this != HeroBannerImageMode.art;

  /// True when the app must not draw its own copy over the image.
  bool get hidesCopy => this == HeroBannerImageMode.full;

  static HeroBannerImageMode parse(String? raw) {
    final key = raw?.trim().toLowerCase().replaceAll(RegExp(r'[\s_-]'), '');
    if (key == null || key.isEmpty) return fallback;
    for (final value in values) {
      if (value.name.toLowerCase() == key) return value;
    }
    // Synonyms an author is likely to reach for.
    switch (key) {
      case 'fullbleed':
      case 'imageonly':
      case 'onlyimage':
      case 'raw':
      case 'direct':
        return HeroBannerImageMode.full;
      case 'background':
      case 'bg':
      case 'fill':
        return HeroBannerImageMode.cover;
      case 'artwork':
      case 'icon':
        return HeroBannerImageMode.art;
    }
    return fallback;
  }
}

/// What tapping the banner's CTA does.
enum HeroBannerActionType {
  route,
  url;

  static const fallback = HeroBannerActionType.route;

  static HeroBannerActionType parse(String? raw) {
    switch (raw?.trim().toLowerCase()) {
      case 'url':
      case 'link':
      case 'web':
        return HeroBannerActionType.url;
      case 'route':
      case 'app':
      case 'inapp':
      case 'in_app':
        return HeroBannerActionType.route;
      default:
        return fallback;
    }
  }
}

@immutable
class HomeHeroBanner {
  const HomeHeroBanner({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
    required this.actionType,
    required this.actionValue,
    required this.order,
    required this.active,
    this.palette = HeroBannerPalette.fallback,
    this.backdrop = HeroBannerBackdropStyle.fallback,
    this.art = HeroBannerArt.fallback,
    this.imageUrl,
    this.imageAsset,
    this.imageMode = HeroBannerImageMode.fallback,
  });

  final String id;
  final String title;
  final String subtitle;
  final String ctaLabel;
  final HeroBannerActionType actionType;
  final String actionValue;
  final int order;
  final bool active;

  // ── Presentation ───────────────────────────────────────────────────────────
  final HeroBannerPalette palette;
  final HeroBannerBackdropStyle backdrop;

  /// Bundled SVG used when no custom image is supplied, and as the fallback
  /// whenever a custom image fails to load.
  final HeroBannerArt art;

  // ── Custom imagery ─────────────────────────────────────────────────────────

  /// A remote image. Anything Flutter can decode — PNG, JPG, WebP — plus SVG
  /// when the URL ends in `.svg`.
  final String? imageUrl;

  /// A bundled asset path, for imagery shipped with the build.
  final String? imageAsset;

  /// Whether [imageUrl] / [imageAsset] is placed as artwork or covers the
  /// whole slide.
  final HeroBannerImageMode imageMode;

  /// True when the author supplied imagery of their own.
  bool get hasCustomImage => imageUrl != null || imageAsset != null;

  /// A full-bleed image carries the whole slide, so the watermark backdrop
  /// would only muddy it.
  bool get isFullBleedImage => hasCustomImage && imageMode.isFullBleed;

  bool get showsBackdrop => !isFullBleedImage;

  /// In `full` mode the supplied artwork already contains its own headline,
  /// so the app draws no copy over it.
  bool get showsCopy => !(hasCustomImage && imageMode.hidesCopy);

  factory HomeHeroBanner.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    return HomeHeroBanner(
      id: doc.id,
      title: _str(data['title']) ?? '',
      subtitle: _str(data['subtitle']) ?? '',
      ctaLabel: _str(data['ctaLabel']) ?? 'Explore',
      actionType: HeroBannerActionType.parse(_str(data['actionType'])),
      actionValue: _str(data['actionValue']) ?? '',
      // Missing `order` sorts last rather than excluding the document. The
      // legacy collection relied on Firestore's orderBy, which silently drops
      // docs that lack the field — the single most common reason an author's
      // banner "just doesn't show up".
      order: _int(data['order']) ?? 1 << 20,
      // A doc with no `active` field is visible.
      active: data['active'] is bool ? data['active'] as bool : true,
      palette: HeroBannerPalette.parse(_str(data['palette'])),
      backdrop: HeroBannerBackdropStyle.parse(_str(data['backdrop'])),
      art: HeroBannerArt.parse(_str(data['art'])),
      imageUrl: _str(data['imageUrl']),
      imageAsset: _str(data['imageAsset']),
      imageMode: HeroBannerImageMode.parse(_str(data['imageMode'])),
    );
  }

  /// A banner is renderable if it has something to say or something to show.
  bool get isRenderable =>
      title.trim().isNotEmpty ||
      subtitle.trim().isNotEmpty ||
      hasCustomImage;

  static String? _str(Object? value) {
    if (value == null) return null;
    final trimmed = value.toString().trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static int? _int(Object? value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  // ───────────────────────────────────────────────────────────────────────────
  //  BUNDLED DEFAULTS
  //
  //  Shown until Firestore answers, and whenever it answers with nothing.
  //  The carousel is never blank, so the app looks finished before anyone
  //  touches the console.
  // ───────────────────────────────────────────────────────────────────────────
  static const List<HomeHeroBanner> defaults = [
    HomeHeroBanner(
      id: '_default_interview',
      title: 'Practice the interview first',
      subtitle:
          'AI mock rounds with feedback on what you actually said, not just '
          'whether you finished.',
      ctaLabel: 'Start a mock',
      actionType: HeroBannerActionType.route,
      actionValue: '/carrer-interview-screen',
      order: 0,
      active: true,
      palette: HeroBannerPalette.indigo,
      backdrop: HeroBannerBackdropStyle.sunburst,
      art: HeroBannerArt.desk,
    ),
    HomeHeroBanner(
      id: '_default_opportunities',
      title: 'Internships worth your time',
      subtitle:
          'Hand-picked openings and hackathons, filtered for students who '
          'are still in college.',
      ctaLabel: 'Browse openings',
      actionType: HeroBannerActionType.route,
      actionValue: '/opportunities',
      order: 1,
      active: true,
      palette: HeroBannerPalette.plum,
      backdrop: HeroBannerBackdropStyle.rings,
      art: HeroBannerArt.chart,
    ),
  ];
}
