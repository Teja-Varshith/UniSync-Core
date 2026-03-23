import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:UniSync/constants/constant.dart';

class BlockedScreen extends StatelessWidget {
  const BlockedScreen({
    super.key,
    required this.message,
    required this.onRefresh,
  });

  final String message;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C0C0A),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: UniSyncColors.error.withOpacity(0.12),
                    border: Border.all(
                      color: UniSyncColors.error.withOpacity(0.35),
                    ),
                  ),
                  child: const Icon(
                    Icons.block_rounded,
                    color: UniSyncColors.error,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'Access Blocked',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    color: Colors.white.withOpacity(0.74),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                OutlinedButton(
                  onPressed: onRefresh,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: UniSyncColors.accent,
                    side: BorderSide(
                      color: UniSyncColors.accent.withOpacity(0.5),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Refresh Status',
                    style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
