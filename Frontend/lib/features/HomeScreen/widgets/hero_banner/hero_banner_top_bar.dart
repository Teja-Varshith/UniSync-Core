import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Wordmark + chrome, floated over the slides and **fixed**: branding doesn't
/// belong to any single slide, so it must not travel with them.
class HeroBannerTopBar extends StatelessWidget {
  const HeroBannerTopBar({
    super.key,
    required this.coins,
    required this.onCoinTap,
  });

  final int coins;
  final VoidCallback onCoinTap;

  static const double gap = 8;
  static const double height = 42;
  static const double clearance = 14;

  /// Vertical space the bar occupies, which the slide's text padding consumes
  /// so a two-line headline can never climb under the wordmark.
  static const double reserved = gap + height + clearance;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const _Wordmark(),
            const Spacer(),
            _ChromeButton(
              icon: Icons.monetization_on_rounded,
              label: '₹$coins',
              onTap: onCoinTap,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  /// The dark-background variant of the app logo: white and yellow marks that
  /// already read as the one bright object up here, so it needs no plaque
  /// behind it. Every banner palette is dark, so this variant always applies.
  static const _asset = 'assets/svg/unisync_svgremove1.svg';

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(_asset, height: 32);
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ChromeButton extends StatelessWidget {
  const _ChromeButton({
    required this.icon,
    required this.onTap,
    this.label,
  });

  final IconData icon;
  final String? label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      shape: StadiumBorder(
        // A quieter ring than the CTA's, so the CTA stays the loudest thing
        // on the banner.
        side: BorderSide(
          color: Colors.white.withValues(alpha: 0.55),
          width: 1.1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: label == null ? 9 : 11,
            vertical: 9,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: Colors.white),
              if (label != null) ...[
                const SizedBox(width: 5),
                Text(
                  label!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
