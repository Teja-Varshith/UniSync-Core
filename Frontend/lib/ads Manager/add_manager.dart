import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

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

  /// Call this once after loading your UserModel.
  /// Pass [hasAdFreeAccess] from your user object.
  void setAdFree(bool value) {
    _adFree = value;
    if (_adFree) _disposeAll(); // release any loaded ads immediately
  }

  bool get isAdFree => _adFree;

  // ── SDK init ─────────────────────────────
  /// Call once in main() before runApp().
  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  // ═══════════════════════════════════════════
  //  1. INTERSTITIAL AD
  // ═══════════════════════════════════════════
  InterstitialAd? _interstitialAd;
  int _interstitialAttempts = 0;
  static const _maxLoadAttempts = 3;

  /// Pre-load an interstitial (call early, e.g. after login).
  void loadInterstitialAd() {
    if (_adFree) return;

    InterstitialAd.load(
      adUnitId: _AdIds.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialAttempts = 0;
          debugPrint('[Ads] Interstitial loaded');
        },
        onAdFailedToLoad: (error) {
          _interstitialAttempts++;
          _interstitialAd = null;
          debugPrint('[Ads] Interstitial failed: $error (attempt $_interstitialAttempts)');
          if (_interstitialAttempts < _maxLoadAttempts) loadInterstitialAd();
        },
      ),
    );
  }

  /// Show the interstitial. Pass optional [onDismissed] callback.
  void showInterstitialAd({VoidCallback? onDismissed}) {
    if (_adFree || _interstitialAd == null) {
      debugPrint('[Ads] Interstitial not ready or ad-free user');
      onDismissed?.call();
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        loadInterstitialAd(); // pre-load next
        onDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        loadInterstitialAd();
        onDismissed?.call();
      },
    );

    _interstitialAd!.show();
    _interstitialAd = null;
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
    if (_adFree) return const SizedBox.shrink();
    return _BannerAdWidget();
  }

  // ═══════════════════════════════════════════
  //  3. APP OPEN AD
  // ═══════════════════════════════════════════
  AppOpenAd? _appOpenAd;
  bool _isShowingAppOpen = false;
  DateTime? _appOpenLoadTime;
  static const _appOpenCacheDuration = Duration(hours: 4);

  void loadAppOpenAd() {
    if (_adFree) return;

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
    if (_adFree) { onDismissed?.call(); return; }
    if (!_isAppOpenAdValid) {
      debugPrint('[Ads] AppOpen not available');
      loadAppOpenAd();
      onDismissed?.call();
      return;
    }
    if (_isShowingAppOpen) return;

    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) => _isShowingAppOpen = true,
      onAdDismissedFullScreenContent: (ad) {
        _isShowingAppOpen = false;
        ad.dispose();
        _appOpenAd = null;
        loadAppOpenAd();
        onDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowingAppOpen = false;
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

  @override
  void initState() {
    super.initState();
    _loadBanner();
  }

  void _loadBanner() {
    final ad = BannerAd(
      adUnitId: _AdIds.banner,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) return;
          setState(() => _bannerAd = ad as BannerAd);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('[Ads] Banner failed: $error');
          ad.dispose();
        },
      ),
    );
    ad.load();
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