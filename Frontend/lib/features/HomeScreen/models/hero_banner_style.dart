import 'package:flutter/material.dart';

/// Visual vocabulary for the home hero banner.
///
/// Everything an author can pick is an enum that carries its own values —
/// never a free-form hex string from Firestore. Whoever writes a banner doc
/// chooses from the app's own colors and physically cannot land a combination
/// that fails contrast or clashes with the white status-bar icons.

// ─────────────────────────────────────────────────────────────────────────────
//  PALETTE
// ─────────────────────────────────────────────────────────────────────────────

/// Every palette is dark enough to carry white status-bar icons, because the
/// banner runs underneath the status bar (see [HeroBannerCarousel]).
enum HeroBannerPalette {
  midnight(Color(0xFF0B3B24), Color(0xFF07140E)),
  indigo(Color(0xFF1B2A6B), Color(0xFF0A0F26)),
  plum(Color(0xFF4A1140), Color(0xFF160512)),
  forest(Color(0xFF12402F), Color(0xFF061410)),
  slate(Color(0xFF23304A), Color(0xFF0B1018));

  const HeroBannerPalette(this.start, this.end);

  /// topLeft of the slide gradient.
  final Color start;

  /// bottomRight of the slide gradient.
  final Color end;

  static const fallback = HeroBannerPalette.midnight;

  /// The 3px rule along the banner's bottom edge is derived from the banner's
  /// own hue rather than a fixed accent — a fixed accent reads as a stray line
  /// belonging to nothing once the gradient behind it changes color.
  Color get edgeRule => Color.lerp(start, Colors.white, 0.34)!;

  static HeroBannerPalette parse(String? raw) => _byName(values, raw, fallback);
}

// ─────────────────────────────────────────────────────────────────────────────
//  BACKDROP
// ─────────────────────────────────────────────────────────────────────────────

/// Texture painted over the gradient. Drawn in the foreground color (white) at
/// a low alpha, so one backdrop works over every palette without re-tuning.
enum HeroBannerBackdropStyle {
  /// Ruled notebook lines, rotated slightly so they read as a sheet laid under
  /// the banner rather than as UI rules.
  ruled,

  /// Wedges radiating from an off-center origin.
  sunburst,

  /// Oversized concentric rings bleeding off the right edge.
  rings,

  none;

  static const fallback = HeroBannerBackdropStyle.ruled;

  static HeroBannerBackdropStyle parse(String? raw) =>
      _byName(values, raw, fallback);
}

// ─────────────────────────────────────────────────────────────────────────────
//  ARTWORK
// ─────────────────────────────────────────────────────────────────────────────

/// Bundled SVG shipped with the app. A banner may override it with a remote
/// URL or a different bundled asset, but this is the guaranteed fallback —
/// a dead URL leaves a complete-looking banner rather than a hole.
enum HeroBannerArt {
  study('assets/icons/Student stress-rafiki.svg'),
  desk('assets/icons/retro computer-rafiki.svg'),
  spark('assets/icons/item1.svg'),
  chart('assets/icons/item3.svg'),
  badge('assets/icons/item5.svg'),
  none(null);

  const HeroBannerArt(this.asset);

  final String? asset;

  static const fallback = HeroBannerArt.spark;

  static HeroBannerArt parse(String? raw) => _byName(values, raw, fallback);
}

// ─────────────────────────────────────────────────────────────────────────────

/// Resolve an enum from a Firestore string by `name`, case- and
/// whitespace-insensitively. A typo renders the fallback instead of taking the
/// home screen down.
T _byName<T extends Enum>(List<T> values, String? raw, T fallback) {
  final key = raw?.trim().toLowerCase();
  if (key == null || key.isEmpty) return fallback;
  for (final value in values) {
    if (value.name.toLowerCase() == key) return value;
  }
  return fallback;
}
