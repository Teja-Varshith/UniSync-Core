import 'package:flutter/material.dart';
import 'package:UniSync/app/theme/app_colors.dart';

/// The clean card system used below the hero banner.
///
/// Deliberately almost colorless. The banner is the page's one saturated
/// element; everything under it is white cards on a faintly tinted ground,
/// near-black titles, grey subtitles, and a single accent that appears only
/// in the arrow affordance. Tinting each card with its own accent — which is
/// what this used to do — made eight competing colors fight on one screen.
///
/// Color here is a signal, not decoration: if it is colored, it is tappable.
class HeroSurface extends StatelessWidget {
  const HeroSurface({
    super.key,
    required this.child,
    this.radius = 18,
    this.height,
    this.onTap,
  });

  final Widget child;
  final double radius;
  final double? height;
  final VoidCallback? onTap;

  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  // ── Surfaces ───────────────────────────────────────────────────────────────

  // Dark mode is neutral black, not tinted. These were green-cast greys,
  // which on an OLED panel reads as a colour wash over the whole page rather
  // than as dark UI. They now reuse the app's own neutral dark ramp.

  /// The page behind the cards: a barely-there tint, never pure white, so the
  /// white cards have something to sit on.
  static Color pageTint(BuildContext context) =>
      _isDark(context) ? AppColors.darkBg : const Color(0xFFF1F2F6);

  /// The section container the cards are grouped inside.
  static Color groupSurface(BuildContext context) =>
      _isDark(context) ? AppColors.darkSurface : Colors.white;

  /// The cards themselves.
  static Color cardSurface(BuildContext context) =>
      _isDark(context) ? AppColors.darkCard : Colors.white;

  static Color hairline(BuildContext context) => _isDark(context)
      ? Colors.white.withValues(alpha: 0.07)
      : const Color(0xFF101828).withValues(alpha: 0.07);

  // ── Content colors ─────────────────────────────────────────────────────────

  static Color onSurface(BuildContext context) =>
      _isDark(context) ? const Color(0xFFF5F5F5) : const Color(0xFF0B0F14);

  /// One grey for every subtitle on the page. A second grey is how a layout
  /// starts looking accidental.
  static Color onSurfaceMuted(BuildContext context) =>
      _isDark(context) ? const Color(0xFF9A9A9A) : const Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    final card = Container(
      height: height,
      decoration: BoxDecoration(
        color: cardSurface(context),
        borderRadius: BorderRadius.circular(radius),
        // A hairline instead of a shadow. Shadows on a pale ground read as
        // grime; the reference layout separates cards with line weight alone.
        border: Border.all(color: hairline(context), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: card,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// The one piece of color on a card: a circular outlined chevron.
///
/// It replaces the old text CTAs ("Open ›", "Visit ›"). A row of cards each
/// spelling out its own verb is noise — the arrow says the same thing in a
/// fixed amount of space, and lets the title be the only text that varies.
class HeroArrow extends StatelessWidget {
  const HeroArrow({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: dark ? 0.16 : 0.09),
        shape: BoxShape.circle,
        border: Border.all(color: accent.withValues(alpha: 0.26), width: 1),
      ),
      child: Icon(
        Icons.chevron_right_rounded,
        size: size * 0.5,
        color: accent,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Heading for a group of cards, matching the reference's plain, heavy,
/// left-aligned section title. No eyebrow, no accent rule, no italic — the
/// weight alone is enough to open a section.
class HeroSectionTitle extends StatelessWidget {
  const HeroSectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              height: 1.2,
              color: HeroSurface.onSurface(context),
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
