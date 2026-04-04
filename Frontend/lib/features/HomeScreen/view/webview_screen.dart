import 'package:flutter/material.dart';
import 'package:UniSync/app/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class WebViewScreen extends ConsumerStatefulWidget {
  final String url;
  const WebViewScreen({super.key, required this.url});

  @override
  ConsumerState<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends ConsumerState<WebViewScreen> {
  InAppWebViewController? webViewController;
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    // ── INJECT USER NAME ────────────────────────────────────────────────
    final user = ref.read(userProvider);
    final userName = user?.name ?? 'Guest';

    String url = widget.url.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    final uri = Uri.parse(url);
    final queryParams = Map<String, String>.from(uri.queryParameters);
    queryParams['name'] = userName;
    final finalUri = uri.replace(queryParameters: queryParams);
    // ───────────────────────────────────────────────────────────────────

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(finalUri.toString())),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                useShouldOverrideUrlLoading: true,
                mediaPlaybackRequiresUserGesture: false,
                allowsInlineMediaPlayback: true,
                useOnDownloadStart: true,
                useOnLoadResource: true,
                allowFileAccessFromFileURLs: true,
                allowUniversalAccessFromFileURLs: true,
                // These are critical for Android file selection
                domStorageEnabled: true,
                databaseEnabled: true,
                mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
              ),
              onWebViewCreated: (controller) {
                webViewController = controller;
              },
              onLoadStart: (controller, url) {
                setState(() {
                  _isLoading = true;
                });
              },
              onLoadStop: (controller, url) {
                setState(() {
                  _isLoading = false;
                });
              },
              onProgressChanged: (controller, progress) {
                if (progress == 100) {
                  setState(() {
                    _isLoading = false;
                  });
                }
              },
            ),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }
}
