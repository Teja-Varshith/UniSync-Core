import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:UniSync/features/HomeScreen/models/home_hero_banner.dart';
import 'package:UniSync/features/HomeScreen/widgets/hero_banner/hero_banner_slide.dart';
import 'package:UniSync/features/HomeScreen/widgets/hero_banner/hero_banner_top_bar.dart';

/// Full-bleed hero banner for the top of the home screen.
///
/// **This widget must sit at y = 0** — no `AppBar` above it, and no `SafeArea`
/// that pads the top. The gradient and watermark run underneath the status bar
/// so the clock and battery sit on the artwork; the banner gives that height
/// back through [topInset] so its *visible* content is the same height on a
/// notched device and a flat one.
class HeroBannerCarousel extends StatefulWidget {
  const HeroBannerCarousel({
    super.key,
    required this.banners,
    required this.coins,
    required this.onCoinTap,
    required this.onBannerTap,
  });

  final List<HomeHeroBanner> banners;
  final int coins;
  final VoidCallback onCoinTap;
  final void Function(HomeHeroBanner banner) onBannerTap;

  /// The pill straddles the banner's bottom edge — half on, half off.
  static const double _ctaHeight = 46;
  static const double _ctaOverhang = 23;
  static const double _ctaBreathingRoom = 12;

  /// Start far from zero so the carousel can be swiped backwards immediately
  /// and loops in both directions without ever hitting a bound.
  static const int _initialPage = 10000;

  static const Duration _autoAdvance = Duration(seconds: 5);
  static const Duration _slideTransition = Duration(milliseconds: 550);

  @override
  State<HeroBannerCarousel> createState() => _HeroBannerCarouselState();
}

class _HeroBannerCarouselState extends State<HeroBannerCarousel>
    with SingleTickerProviderStateMixin {
  late final PageController _controller =
      PageController(initialPage: HeroBannerCarousel._initialPage);

  /// Raw, unbounded page. The visible banner is derived with the same modulo
  /// the item builder uses.
  int _page = HeroBannerCarousel._initialPage;

  Timer? _timer;

  /// Drives the CTA's breathing glow.
  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1900),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(HeroBannerCarousel old) {
    super.didUpdateWidget(old);
    // Remote content can arrive after the first build. If the count changes,
    // `_page % count` would silently resolve to a different banner than the
    // one on screen, so reset to a known position.
    if (old.banners.length != widget.banners.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_controller.hasClients) return;
        _controller.jumpToPage(HeroBannerCarousel._initialPage);
        setState(() => _page = HeroBannerCarousel._initialPage);
      });
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _glow.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    // Nothing to advance to with a single banner.
    if (widget.banners.length < 2) return;
    _timer = Timer.periodic(HeroBannerCarousel._autoAdvance, (_) {
      if (!mounted || !_controller.hasClients) return;
      _controller.nextPage(
        duration: HeroBannerCarousel._slideTransition,
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _stopTimer() => _timer?.cancel();

  HomeHeroBanner _bannerAt(int page) =>
      widget.banners[page % widget.banners.length];

  @override
  Widget build(BuildContext context) {
    final banners = widget.banners;
    if (banners.isEmpty) return const SizedBox.shrink();

    final width = MediaQuery.sizeOf(context).width;
    final topInset = MediaQuery.paddingOf(context).top;
    // The banner eats the status bar, so it has to give that height back —
    // otherwise its visible content is shorter on a notched device.
    final bannerHeight = topInset + (width * 0.58).clamp(196.0, 230.0);

    final current = _bannerAt(_page);

    return SizedBox(
      // Room for the pill's overhang plus breathing space below it.
      height: bannerHeight +
          HeroBannerCarousel._ctaOverhang +
          HeroBannerCarousel._ctaBreathingRoom,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── 1. The slides (the only layer that scrolls) ──────────────────
          SizedBox(
            height: bannerHeight,
            // Light status-bar icons for exactly as long as a banner is under
            // them, so the system bar reads as part of the banner rather than
            // a strip of chrome above it.
            child: AnnotatedRegion<SystemUiOverlayStyle>(
              value: const SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.light,
                statusBarBrightness: Brightness.dark,
              ),
              child: NotificationListener<ScrollNotification>(
                // A swipe must not fight the timer.
                onNotification: (notification) {
                  if (notification is ScrollStartNotification) {
                    _stopTimer();
                  } else if (notification is ScrollEndNotification) {
                    _startTimer();
                  }
                  return false;
                },
                child: PageView.builder(
                  controller: _controller,
                  onPageChanged: (page) => setState(() => _page = page),
                  // Unbounded in both directions: no itemCount, and the
                  // builder wraps with modulo, so passing the last banner
                  // continues forward instead of flinging back through every
                  // slide.
                  itemBuilder: (context, index) => RepaintBoundary(
                    child: HeroBannerSlide(
                      banner: _bannerAt(index),
                      topInset: topInset,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── 2. The top bar (fixed) ───────────────────────────────────────
          Positioned(
            top: topInset + HeroBannerTopBar.gap,
            left: 0,
            right: 0,
            child: HeroBannerTopBar(
              coins: widget.coins,
              onCoinTap: widget.onCoinTap,
            ),
          ),

          // ── 3. The CTA pill (fixed, straddling the bottom edge) ──────────
          Positioned(
            top: bannerHeight - HeroBannerCarousel._ctaOverhang,
            left: 0,
            right: 0,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: width * 0.66),
                // Only the label changes between slides — the pill itself
                // belongs to the banner, not to any one slide.
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _CtaPill(
                    key: ValueKey(current.ctaLabel),
                    label: current.ctaLabel,
                    glow: _glow,
                    onTap: () => widget.onBannerTap(current),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Monochrome on purpose: it has to read identically over every palette *and*
/// over the page it half-covers.
class _CtaPill extends StatelessWidget {
  const _CtaPill({
    super.key,
    required this.label,
    required this.glow,
    required this.onTap,
  });

  final String label;
  final Animation<double> glow;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: glow,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(glow.value);
        return Container(
          height: HeroBannerCarousel._ctaHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              HeroBannerCarousel._ctaHeight / 2,
            ),
            boxShadow: [
              // The breathing glow.
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.16 + 0.26 * t),
                blurRadius: 9 + 11 * t,
                spreadRadius: 0.5 + 1.5 * t,
              ),
              // A white glow alone cannot ground the pill where it overhangs
              // onto the pale page below; this drop shadow does.
              const BoxShadow(
                color: Color(0x40000000),
                blurRadius: 14,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: child,
        );
      },
      child: Material(
        color: Colors.black,
        shape: StadiumBorder(
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.9),
            width: 1.4,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    // Ellipsize rather than let a long authored label stretch
                    // the pill off screen.
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
