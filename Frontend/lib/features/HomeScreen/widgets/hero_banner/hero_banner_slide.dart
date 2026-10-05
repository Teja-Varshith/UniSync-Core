import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:UniSync/features/HomeScreen/models/hero_banner_style.dart';
import 'package:UniSync/features/HomeScreen/models/home_hero_banner.dart';
import 'package:UniSync/features/HomeScreen/widgets/hero_banner/hero_banner_backdrop.dart';
import 'package:UniSync/features/HomeScreen/widgets/hero_banner/hero_banner_top_bar.dart';

/// One slide of the hero banner: gradient → watermark → imagery → text,
/// back to front, with a rule along the bottom edge.
class HeroBannerSlide extends StatelessWidget {
  const HeroBannerSlide({
    super.key,
    required this.banner,
    required this.topInset,
  });

  final HomeHeroBanner banner;

  /// Status bar height. The gradient and imagery run underneath the status
  /// bar; only the text is pushed clear of it.
  final double topInset;

  @override
  Widget build(BuildContext context) {
    final palette = banner.palette;
    final fullBleed = banner.isFullBleedImage;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.start, palette.end],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (fullBleed) ...[
            // The image is the slide. It replaces the watermark entirely —
            // a texture over a photograph only muddies both.
            _CoverImage(banner: banner),
            // `full` mode draws no scrim: there is no app copy to protect,
            // and a scrim would only dull artwork that is already finished.
            if (banner.showsCopy) _CoverScrim(palette: palette),
          ] else ...[
            HeroBannerBackdrop(backdrop: banner.backdrop),
            _Artwork(banner: banner, topInset: topInset),
          ],

          if (banner.showsCopy)
            _SlideText(
              banner: banner,
              topInset: topInset,
              dimmed: fullBleed,
            ),

          // The rule that separates the banner from the page below, derived
          // from this banner's own hue so it never reads as a stray accent.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(height: 3, color: palette.edgeRule),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Full-bleed custom image.
class _CoverImage extends StatelessWidget {
  const _CoverImage({required this.banner});

  final HomeHeroBanner banner;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: _resolveImage(banner, BoxFit.cover) ?? const SizedBox.shrink(),
    );
  }
}

/// Keeps the copy legible over an arbitrary image the app has never seen.
///
/// Tinted with the banner's own palette rather than neutral black, so a cover
/// image still belongs to the same set as the gradient-only slides.
class _CoverScrim extends StatelessWidget {
  const _CoverScrim({required this.palette});

  final HeroBannerPalette palette;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
              colors: [
                palette.end.withValues(alpha: 0.92),
                palette.end.withValues(alpha: 0.55),
                palette.start.withValues(alpha: 0.20),
              ],
              stops: const [0.0, 0.52, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Centre-right artwork: a custom image in `art` mode, else the bundled SVG.
class _Artwork extends StatelessWidget {
  const _Artwork({required this.banner, required this.topInset});

  final HomeHeroBanner banner;
  final double topInset;

  @override
  Widget build(BuildContext context) {
    final art = _resolveImage(banner, BoxFit.contain) ?? _bundledArt(banner);
    if (art == null) return const SizedBox.shrink();

    return Positioned.fill(
      // Pad down by the status bar height so the art stays optically centred
      // in the part of the banner you can actually see.
      top: topInset,
      child: IgnorePointer(
        child: Align(
          alignment: Alignment.centerRight,
          child: FractionallySizedBox(
            widthFactor: 0.36,
            heightFactor: 0.68,
            // Push a few px past the right edge: artwork that bleeds reads as
            // part of the banner, artwork that fits reads as a thumbnail.
            child: Transform.translate(
              offset: const Offset(4, 0),
              child: art,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Remote URL → bundled asset → null. Every path falls back to the shipped
/// SVG on error, so a dead URL leaves a complete-looking banner.
Widget? _resolveImage(HomeHeroBanner banner, BoxFit fit) {
  final fallback = _bundledArt(banner);

  final asset = banner.imageAsset;
  final url = banner.imageUrl;

  Widget? assetImage() {
    if (asset == null) return null;
    return asset.toLowerCase().endsWith('.svg')
        ? SvgPicture.asset(asset, fit: fit)
        : Image.asset(
            asset,
            fit: fit,
            errorBuilder: (_, __, ___) => fallback ?? const SizedBox.shrink(),
          );
  }

  if (url != null) {
    if (url.toLowerCase().endsWith('.svg')) {
      return SvgPicture.network(
        url,
        fit: fit,
        placeholderBuilder: (_) =>
            assetImage() ?? fallback ?? const SizedBox.shrink(),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      placeholder: (_, __) =>
          assetImage() ?? fallback ?? const SizedBox.shrink(),
      errorWidget: (_, __, ___) =>
          assetImage() ?? fallback ?? const SizedBox.shrink(),
    );
  }

  return assetImage();
}

Widget? _bundledArt(HomeHeroBanner banner) {
  final asset = banner.art.asset;
  if (asset == null) return null;
  return SvgPicture.asset(asset, fit: BoxFit.contain);
}

// ─────────────────────────────────────────────────────────────────────────────

class _SlideText extends StatelessWidget {
  const _SlideText({
    required this.banner,
    required this.topInset,
    required this.dimmed,
  });

  final HomeHeroBanner banner;
  final double topInset;

  /// Over a cover image the copy needs a shadow; over a flat gradient it
  /// would only look smudged.
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final title = banner.title.trim();
    final subtitle = banner.subtitle.trim();
    if (title.isEmpty && subtitle.isEmpty) return const SizedBox.shrink();

    final shadows = dimmed
        ? const [Shadow(color: Color(0x99000000), blurRadius: 12)]
        : const <Shadow>[];

    return Positioned.fill(
      child: Align(
        alignment: Alignment.bottomLeft,
        child: FractionallySizedBox(
          // A cover image has no artwork column to avoid, so the copy gets
          // the extra width.
          widthFactor: dimmed ? 0.78 : 0.62,
          alignment: Alignment.bottomLeft,
          child: Padding(
            // Bottom-anchored, not centred: centring splits the leftover
            // height evenly and leaves an oversized gap under the subtitle.
            // Pinning the block down makes that gap a fixed 30 and collects
            // the slack at the top, where the status bar already sits in it.
            padding: EdgeInsets.fromLTRB(
              20,
              topInset + HeroBannerTopBar.reserved,
              16,
              30,
            ),
            // Copy is authored in Firestore and the banner is a fixed height,
            // so text scaling has to be capped or a large-text device
            // overflows the slide.
            child: MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.15,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title.isNotEmpty)
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              height: 1.18,
                              shadows: shadows,
                            ),
                      ),
                    ),
                  // Title and subtitle are one unit; the air belongs around
                  // the block, not inside it.
                  if (title.isNotEmpty && subtitle.isNotEmpty)
                    const SizedBox(height: 5),
                  if (subtitle.isNotEmpty)
                    Flexible(
                      child: Text(
                        subtitle,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.42,
                          color: Colors.white.withValues(alpha: 0.82),
                          shadows: shadows,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
