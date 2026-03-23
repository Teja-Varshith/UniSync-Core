import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:UniSync/constants/constant.dart';

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
    return Scaffold(
      backgroundColor: const Color(0xFF0C0C0A),
      body: SafeArea(
        child: Stack(
          children: [
            // ── Main centered content ────────────────────────────
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Logo ────────────────────────────────────
                    Center(
                      child: Container(
                        width: 100,
                        height: 100,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: UniSyncColors.accent.withOpacity(0.14),
                          ),
                        ),
                        child: SvgPicture.asset(
                          'assets/svg/unisync_svgremove1.svg',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Tagline only — logo already has the name ─
                    Text(
                      'AI College Companion App',
                      style: GoogleFonts.dmSans(
                        color: Colors.white.withOpacity(0.28),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 52),

                    // ── Progress / error ─────────────────────────
                    if (_hasError) ...[
                      Text(
                        errorText!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(
                          color: UniSyncColors.error,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                      ),
                      if (onRetry != null) ...[
                        const SizedBox(height: 20),
                        OutlinedButton(
                          onPressed: onRetry,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: UniSyncColors.accent,
                            side: BorderSide(
                              color: UniSyncColors.accent.withOpacity(0.5),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 28, vertical: 11),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            retryButtonText,
                            style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ] else ...[
                      SizedBox(
                        width: 200,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: const LinearProgressIndicator(
                            minHeight: 2,
                            backgroundColor: Color(0xFF1E1E1C),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              UniSyncColors.accent,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        statusText,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(
                          color: Colors.white.withOpacity(0.28),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ── Made in India pinned bottom ──────────────────────
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Text(
                'Made with ❤️ by Team Aavishkaar',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 10.5,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
