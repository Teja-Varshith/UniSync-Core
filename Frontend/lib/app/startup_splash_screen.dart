import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// First frame the user sees while Firebase, ads and the session warm up.
///
/// Deliberately plain: a logo, a thin progress line, and a word about what is
/// happening. A splash is looked at for under a second, so anything more —
/// taglines, badges, credits — is read as clutter rather than polish.
class StartupSplashScreen extends StatelessWidget {
  const StartupSplashScreen({
    super.key,
    required this.statusText,
    this.errorText,
    this.onRetry,
    this.retryButtonText = 'Retry',
  });

  final String statusText;
  final String? errorText;
  final VoidCallback? onRetry;
  final String retryButtonText;

  bool get _hasError => errorText != null && errorText!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;

    // The logo ships in two variants and the light-background one carries
    // dark ink. This used to be pinned to the dark variant and then hidden
    // inside a black box so it stayed visible on a light screen — the box
    // was covering for the wrong asset, so picking the right one removes
    // the need for it.
    final logoAsset = isDark
        ? 'assets/svg/unisync_svgremove1.svg'
        : 'assets/svg/unisyncd.svg';

    final muted = theme.hintColor;

    // `unisyncd.svg` has a full-canvas white rectangle baked into it, so on
    // the usual off-white scaffold (#F5F6FA) it shows as a slightly brighter
    // panel behind the mark. Matching the background to the asset's own
    // white hides the seam.
    //
    // The real fix is a logo exported without a background; until then this
    // keeps the splash clean without touching the shared theme.
    final background =
        isDark ? theme.scaffoldBackgroundColor : Colors.white;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(logoAsset, height: 64),
                const SizedBox(height: 40),
                if (_hasError)
                  _ErrorState(
                    message: errorText!,
                    onRetry: onRetry,
                    retryButtonText: retryButtonText,
                  )
                else
                  _LoadingState(
                    statusText: statusText,
                    accent: accent,
                    muted: muted,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState({
    required this.statusText,
    required this.accent,
    required this.muted,
  });

  final String statusText;
  final Color accent;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Narrow and hairline-thin. A full-width bar on a splash reads as a
        // download in progress rather than an app opening.
        SizedBox(
          width: 96,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 2,
              backgroundColor: accent.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          statusText,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: muted,
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
    required this.retryButtonText,
  });

  final String message;
  final VoidCallback? onRetry;
  final String retryButtonText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: theme.colorScheme.error,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
        ),
        if (onRetry != null) ...[
          const SizedBox(height: 20),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              retryButtonText,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
