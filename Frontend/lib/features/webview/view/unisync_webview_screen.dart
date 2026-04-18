import 'package:UniSync/app/providers.dart';
import 'package:UniSync/app/theme/app_colors.dart';
import 'package:UniSync/features/coins/coin_purchase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:routemaster/routemaster.dart';
import 'package:url_launcher/url_launcher.dart';

// Replace with your actual imports
// import 'package:your_app/core/colors.dart';
// import 'package:your_app/providers/user_provider.dart';
// import 'package:your_app/providers/coin_purchase_provider.dart';

// ── Firestore provider: fetches the base URL from config/webview ──────────────
final webviewUrlProvider = FutureProvider<String>((ref) async {
  final doc = await FirebaseFirestore.instance
      .collection('config')
      .doc('webview')
      .get();
  return doc.data()?['url'] as String? ?? '';
});

// ─────────────────────────────────────────────────────────────────────────────

class WebViewPage extends ConsumerStatefulWidget {
  const WebViewPage({super.key});

  @override
  ConsumerState<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends ConsumerState<WebViewPage> {
  InAppWebViewController? _webViewController;
  bool _isLoading = true;
  double _loadingProgress = 0;

  // ── External domains that open outside the app ────────────────────────────
  final List<String> _externalDomains = [
    'youtube.com',
    'youtu.be',
    'play.google.com',
    'apps.apple.com',
    'twitter.com',
    'x.com',
    'instagram.com',
    'facebook.com',
    'wa.me',
    'whatsapp.com',
    't.me',
  ];

  bool _isExternalLink(Uri uri) {
    final host = uri.host.toLowerCase();
    return _externalDomains.any(
      (domain) => host == domain || host.endsWith('.$domain'),
    );
  }

  /// Appends ?uid= to whatever URL comes from Firestore
  String _buildUrl(String baseUrl) {
    final uid = ref.read(userProvider)?.id ?? '';
    if (baseUrl.isEmpty) return '';
    return Uri.parse(baseUrl)
        .replace(queryParameters: uid.isNotEmpty ? {'uid': uid} : null)
        .toString();
  }

  // ── Coin purchase bottom sheet ─────────────────────────────────────────────
  Future<void> _openCoinPurchaseSheet() async {
    final user = ref.read(userProvider);
    final currentCoins = user?.coins ?? 0;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkSurface
          : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Buy Coins',
                  style: TextStyle(
                    color: AppColors.catHealth,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Current balance: $currentCoins coins',
                  style: const TextStyle(
                    color: AppColors.darkTextSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.catSalary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.lightBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Iconsax.empty_wallet_add,
                        color: Colors.black,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          '100 Coins Pack',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      FilledButton(
                        onPressed: () async {
                          final error = await ref
                              .read(coinPurchaseServiceProvider)
                              .buy100CoinsPack();
                          if (!mounted) return;
                          if (error != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(error),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: AppColors.danger,
                              ),
                            );
                            return;
                          }
                          if (Navigator.of(sheetContext).canPop()) {
                            Navigator.of(sheetContext).pop();
                          }
                        },
                        child: const Text('Rs 9'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Uni-Coins can be used to redeem exclusive rewards and access premium features within the app.',
                  style: TextStyle(
                    color: AppColors.lightTextSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── App bar ────────────────────────────────────────────────────────────────
  Widget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final coinAccent = AppColors.success;
    final resolvedColors = isDark
        ? const [AppColors.darkCard, AppColors.darkCardAlt]
        : const [AppColors.lightCard, AppColors.lightCardAlt];

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 0.8,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          InkWell(
            onTap: () async {
              if (_webViewController != null &&
                  await _webViewController!.canGoBack()) {
                _webViewController!.goBack();
              } else {
                Routemaster.of(context).replace('/');
              }
            },
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: resolvedColors[0],
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: _openCoinPurchaseSheet,
            borderRadius: BorderRadius.circular(999),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: LinearGradient(
                  colors: [
                    coinAccent.withValues(alpha: isDark ? 0.22 : 0.16),
                    coinAccent.withValues(alpha: isDark ? 0.10 : 0.08),
                  ],
                ),
                border: Border.all(
                  color: coinAccent.withValues(alpha: 0.38),
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: coinAccent.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: coinAccent.withValues(alpha: 0.36),
                        ),
                      ),
                      child: Icon(
                        Iconsax.coin_1,
                        size: 13,
                        color: coinAccent,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      '${ref.watch(userProvider)?.coins ?? 0}',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'coins',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.78),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final urlAsync = ref.watch(webviewUrlProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_webViewController != null &&
            await _webViewController!.canGoBack()) {
          _webViewController!.goBack();
        } else {
          if (context.mounted) Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),

              // Loading bar
              if (_isLoading)
                LinearProgressIndicator(
                  value: _loadingProgress > 0 ? _loadingProgress : null,
                  minHeight: 2,
                  backgroundColor: Colors.transparent,
                  color: AppColors.success,
                ),

              Expanded(
                child: urlAsync.when(
                  // ── Firestore fetch in progress ──────────────────────────
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),

                  // ── Firestore fetch failed ───────────────────────────────
                  error: (e, _) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.wifi_off_rounded,
                            size: 40, color: Colors.grey),
                        const SizedBox(height: 12),
                        const Text(
                          'Failed to load page',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          e.toString(),
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () =>
                              ref.invalidate(webviewUrlProvider),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),

                  // ── URL ready — build WebView ─────────────────────────────
                  data: (baseUrl) {
                    if (baseUrl.isEmpty) {
                      return const Center(
                        child: Text('No URL configured.'),
                      );
                    }

                    final url = _buildUrl(baseUrl);

                    return InAppWebView(
                      initialUrlRequest: URLRequest(
                        url: WebUri(url),
                      ),
                      initialSettings: InAppWebViewSettings(
                        useHybridComposition: true,
                        useShouldOverrideUrlLoading: true,
                        mediaPlaybackRequiresUserGesture: false,
                        javaScriptEnabled: true,
                        domStorageEnabled: true,
                        allowsInlineMediaPlayback: true,
                        supportZoom: false,
                      ),
                      onWebViewCreated: (controller) {
                        _webViewController = controller;
                      },
                      onLoadStart: (controller, url) {
                        setState(() => _isLoading = true);
                      },
                      onProgressChanged: (controller, progress) {
                        setState(
                            () => _loadingProgress = progress / 100);
                      },
                      onLoadStop: (controller, url) {
                        setState(() => _isLoading = false);
                      },
                      onReceivedError: (controller, request, error) {
                        setState(() => _isLoading = false);
                      },
                      shouldOverrideUrlLoading:
                          (controller, navigationAction) async {
                        final uri = navigationAction.request.url;
                        if (uri == null) {
                          return NavigationActionPolicy.CANCEL;
                        }

                        final scheme = uri.scheme.toLowerCase();

                        // Non-http(s) schemes → open externally
                        if (scheme != 'http' && scheme != 'https') {
                          final canLaunch = await canLaunchUrl(uri);
                          if (canLaunch) await launchUrl(uri);
                          return NavigationActionPolicy.CANCEL;
                        }

                        // External domains → system browser
                        if (_isExternalLink(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                          return NavigationActionPolicy.CANCEL;
                        }

                        return NavigationActionPolicy.ALLOW;
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}