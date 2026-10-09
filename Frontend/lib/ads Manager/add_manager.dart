import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:UniSync/firebase_service.dart';

// ─────────────────────────────────────────────
//  AD UNIT IDs  (swap test IDs before release)
// ─────────────────────────────────────────────
class _AdIds {
  // static const interstitial = 'ca-app-pub-6840112928410718/5254620936';
  // static const banner       = 'ca-app-pub-6840112928410718/1054270136';
  // static const appOpen      = 'ca-app-pub-6840112928410718/6095074012';

  static const interstitial = 'ca-app-pub-6840112928410718/5254620936';
  static const banner       = 'ca-app-pub-6840112928410718/7540071176';
  static const appOpen      = 'ca-app-pub-6840112928410718/2229569590';

}

// ─────────────────────────────────────────────
//  CENTRAL AD MANAGER
//  Usage:  AdManager.instance
// ─────────────────────────────────────────────
class AdManager {
  AdManager._();
  static final instance = AdManager._();

  // ── Ad-free flag ──────────────────────────
  bool _adFree = false;

  /// Remote master switch, flipped from the admin panel.
  ///
  /// Independent of [_adFree]: this turns ads off for *everyone at once*,
  /// while [_adFree] turns them off for one paying user. Premium users are
  /// therefore exempt in both directions — switching ads back on globally
  /// never re-enables them for someone who has paid.
  bool _adsEnabled = true;

  /// Call this once after loading your UserModel.
  /// Pass [hasAdFreeAccess] from your user object.
  void setAdFree(bool value) {
    _adFree = value;
    if (_adFree) _disposeAll(); // release any loaded ads immediately
  }

  bool get isAdFree => _adFree;

  /// Whether ads may be shown to this user right now. Every ad path checks
  /// this rather than [_adFree] alone.
  bool get _suppressAds => _adFree || !_adsEnabled;

  /// True when ads are actually being served, so screens can drop the space
  /// they reserve for a banner instead of leaving a gap.
  bool get adsVisible => !_suppressAds;

  /// Called when the remote flag changes. Turning ads off releases anything
  /// cached immediately; turning them back on re-warms the full-screen
  /// formats so the next opportunity isn't wasted.
  void setAdsEnabled(bool value) {
    if (_adsEnabled == value) return;
    _adsEnabled = value;
    debugPrint('[Ads] Global ads ${value ? 'enabled' : 'disabled'}');

    if (!value) {
      _disposeAll();
      return;
    }
    if (!_adFree) {
      loadInterstitialAd(reset: true);
      loadAppOpenAd();
    }
  }

  // ── SDK init ─────────────────────────────
  /// Call once in main() before runApp().
  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  // ── Full-screen traffic cop ───────────────
  /// Interstitial and app-open ads must never overlap: the second `show()`
  /// is silently dropped by the SDK and its dismiss callback never fires.
  bool _isShowingFullScreenAd = false;

  bool get isShowingFullScreenAd => _isShowingFullScreenAd;

  // ═══════════════════════════════════════════
  //  1. INTERSTITIAL AD
  // ═══════════════════════════════════════════
  InterstitialAd? _interstitialAd;
  bool _isLoadingInterstitial = false;
  int _interstitialAttempts = 0;
  Timer? _interstitialRetryTimer;
  DateTime? _lastInterstitialShown;

  /// Last load failure, handy when debugging "ads never show" reports.
  /// Code 0 = internal, 1 = invalid request (usually a wrong/stale ad unit id),
  /// 2 = network, 3 = no fill.
  LoadAdError? lastInterstitialError;

  static const _maxLoadAttempts = 5;

  /// Minimum gap between two interstitials, so a user tapping around the
  /// attendance screen doesn't get a full-screen ad on every tap.
  static const _interstitialCooldown = Duration(minutes: 2);

  bool get isInterstitialReady => _interstitialAd != null;

  /// Pre-load an interstitial (call early, e.g. after login, and again
  /// whenever a screen that shows interstitials is opened).
  ///
  /// Pass [reset] on a user-driven entry point to clear the failed-attempt
  /// counter — otherwise a bad cold start (no network, no fill) would leave
  /// the app without interstitials for the rest of the session.
  void loadInterstitialAd({bool reset = false}) {
    if (_suppressAds) return;
    if (reset) {
      _interstitialAttempts = 0;
      _interstitialRetryTimer?.cancel();
      _interstitialRetryTimer = null;
    }
    if (_interstitialAd != null || _isLoadingInterstitial) return;
    if (_interstitialAttempts >= _maxLoadAttempts) {
      debugPrint('[Ads] Interstitial: giving up until next reset');
      return;
    }

    _isLoadingInterstitial = true;
    InterstitialAd.load(
      adUnitId: _AdIds.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _isLoadingInterstitial = false;
          _interstitialAd = ad;
          _interstitialAttempts = 0;
          lastInterstitialError = null;
          debugPrint('[Ads] Interstitial loaded');
        },
        onAdFailedToLoad: (error) {
          _isLoadingInterstitial = false;
          _interstitialAd = null;
          lastInterstitialError = error;
          _interstitialAttempts++;
          debugPrint(
              '[Ads] Interstitial failed: $error (attempt $_interstitialAttempts)');
          FirebaseService.logEvent(
            name: 'ad_interstitial_load_failed',
            parameters: {
              'code': error.code,
              'domain': error.domain,
              'message': error.message,
              'attempt': _interstitialAttempts,
            },
          );
          if (_interstitialAttempts < _maxLoadAttempts) {
            // Back off instead of burning all attempts in the same second —
            // most failures here are transient (no network / no fill).
            final delay = Duration(seconds: 2 << (_interstitialAttempts - 1));
            _interstitialRetryTimer?.cancel();
            _interstitialRetryTimer =
                Timer(delay, () => loadInterstitialAd());
          }
        },
      ),
    );
  }

  /// Show the interstitial if one is cached. Pass optional [onDismissed],
  /// which is always invoked exactly once (immediately when no ad is ready),
  /// so it is safe to use for navigation.
  void showInterstitialAd({VoidCallback? onDismissed}) {
    if (_suppressAds) {
      onDismissed?.call();
      return;
    }
    if (_isShowingFullScreenAd) {
      debugPrint('[Ads] Another full-screen ad is on screen');
      onDismissed?.call();
      return;
    }

    final ad = _interstitialAd;
    if (ad == null) {
      debugPrint('[Ads] Interstitial not ready (${lastInterstitialError ?? 'still loading'})');
      loadInterstitialAd(reset: true); // self-heal for the next attempt
      onDismissed?.call();
      return;
    }

    _interstitialAd = null; // take ownership before showing
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) {
        _isShowingFullScreenAd = true;
        _lastInterstitialShown = DateTime.now();
      },
      onAdDismissedFullScreenContent: (ad) {
        _isShowingFullScreenAd = false;
        ad.dispose();
        loadInterstitialAd(reset: true); // pre-load next
        onDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowingFullScreenAd = false;
        debugPrint('[Ads] Interstitial failed to show: $error');
        ad.dispose();
        loadInterstitialAd(reset: true);
        onDismissed?.call();
      },
    );

    ad.show();
  }

  /// Cooldown-aware version of [showInterstitialAd] — use this from screens
  /// instead of rolling your own random gate. Returns whether an ad is being
  /// shown; [onDismissed] still runs either way.
  bool maybeShowInterstitialAd({VoidCallback? onDismissed}) {
    if (_suppressAds) {
      onDismissed?.call();
      return false;
    }

    final last = _lastInterstitialShown;
    if (last != null &&
        DateTime.now().difference(last) < _interstitialCooldown) {
      loadInterstitialAd(); // keep one warm for after the cooldown
      onDismissed?.call();
      return false;
    }

    if (_interstitialAd == null) {
      loadInterstitialAd(reset: true);
      onDismissed?.call();
      return false;
    }

    showInterstitialAd(onDismissed: onDismissed);
    return true;
  }

  // ═══════════════════════════════════════════
  //  2. BANNER AD
  // ═══════════════════════════════════════════

  /// Returns a ready [BannerAd] widget wrapped in a [Container].
  /// Place this anywhere in your widget tree.
  ///
  /// Example:
  ///   AdManager.instance.buildBannerAd()
  Widget buildBannerAd() {
    if (_suppressAds) return const SizedBox.shrink();
    return _BannerAdWidget();
  }

  // ═══════════════════════════════════════════
  //  3. APP OPEN AD
  // ═══════════════════════════════════════════
  AppOpenAd? _appOpenAd;
  DateTime? _appOpenLoadTime;
  DateTime? _lastAppOpenShown;

  /// Google requires a cached app-open ad to be discarded after four hours.
  static const _appOpenCacheDuration = Duration(hours: 4);

  /// Minimum gap between two app-open shows. App-open is meant to fire on
  /// most returns to the app, so this is short — it exists only to stop a
  /// user flicking between apps from being shown an ad every few seconds.
  static const _appOpenCooldown = Duration(seconds: 45);

  void loadAppOpenAd() {
    if (_suppressAds) return;

    AppOpenAd.load(
      adUnitId: _AdIds.appOpen,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          _appOpenLoadTime = DateTime.now();
          debugPrint('[Ads] AppOpen loaded');
        },
        onAdFailedToLoad: (error) {
          debugPrint('[Ads] AppOpen failed: $error');
        },
      ),
    );
  }

  bool get _isAppOpenAdValid {
    if (_appOpenAd == null || _appOpenLoadTime == null) return false;
    return DateTime.now().difference(_appOpenLoadTime!) < _appOpenCacheDuration;
  }

  void showAppOpenAd({VoidCallback? onDismissed}) {
    if (_suppressAds) { onDismissed?.call(); return; }

    final last = _lastAppOpenShown;
    if (last != null && DateTime.now().difference(last) < _appOpenCooldown) {
      onDismissed?.call();
      return;
    }

    if (!_isAppOpenAdValid) {
      debugPrint('[Ads] AppOpen not available');
      loadAppOpenAd();
      onDismissed?.call();
      return;
    }
    if (_isShowingFullScreenAd) {
      onDismissed?.call();
      return;
    }

    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) {
        _isShowingFullScreenAd = true;
        _lastAppOpenShown = DateTime.now();
      },
      onAdDismissedFullScreenContent: (ad) {
        _isShowingFullScreenAd = false;
        ad.dispose();
        _appOpenAd = null;
        loadAppOpenAd();
        onDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowingFullScreenAd = false;
        ad.dispose();
        _appOpenAd = null;
        loadAppOpenAd();
        onDismissed?.call();
      },
    );

    _appOpenAd!.show();
  }

  // ═══════════════════════════════════════════
  //  DISPOSE ALL
  // ═══════════════════════════════════════════
  void _disposeAll() {
    _interstitialRetryTimer?.cancel();
    _interstitialRetryTimer = null;
    _isLoadingInterstitial = false;
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _appOpenAd?.dispose();
    _appOpenAd = null;
  }

  void dispose() => _disposeAll();
}

// ─────────────────────────────────────────────
//  BANNER AD WIDGET  (self-contained)
// ─────────────────────────────────────────────
class _BannerAdWidget extends StatefulWidget {
  const _BannerAdWidget();
  @override
  State<_BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<_BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _loadStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The adaptive size depends on screen width, which needs a BuildContext
    // with MediaQuery — not available in initState. Guarded so a dependency
    // change (rotation, theme) doesn't kick off a second load.
    if (_loadStarted) return;
    _loadStarted = true;
    _loadBanner();
  }

  Future<void> _loadBanner() async {
    // Anchored adaptive banners fill the device width and let the SDK pick
    // an optimal height, which fills better and earns more than the fixed
    // 320x50 AdSize.banner this used to request.
    final width = MediaQuery.sizeOf(context).width.truncate();
    final size =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);

    if (!mounted) return;

    // The SDK returns null when it cannot work out a size for this screen.
    // Falling back keeps a banner rather than losing the placement entirely.
    final adSize = size ?? AdSize.banner;

    final ad = BannerAd(
      adUnitId: _AdIds.banner,
      size: adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            // The widget went away mid-load; without this the ad leaks.
            ad.dispose();
            return;
          }
          setState(() => _bannerAd = ad as BannerAd);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('[Ads] Banner failed: $error');
          ad.dispose();
        },
      ),
    );
    await ad.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_bannerAd == null) return const SizedBox.shrink();
    return SizedBox(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}