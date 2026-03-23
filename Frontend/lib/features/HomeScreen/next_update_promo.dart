import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:UniSync/constants/constant.dart';

class NextUpdatePromoScreen extends StatelessWidget {
  const NextUpdatePromoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UniSyncColors.backgroundPrimary,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF171714),
              UniSyncColors.backgroundPrimary,
              Color(0xFF080808),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TopBar(
                  onBack: () => Navigator.of(context).pop(),
                ),
                const SizedBox(height: 22),
                const _HeroSection(),
                const SizedBox(height: 22),
                const _SectionCard(
                  eyebrow: 'ABOUT UNISYNC',
                  title: 'Why UniSync Exists',
                  body:
                      'UniSync is being built to reduce the noise of student life and turn scattered portals, updates, and growth opportunities into one cleaner experience. We want the app to feel like a real companion for campus life, not just another utility.',
                  bullets: [
                    'Make student life feel simpler and more organized',
                    'Bring practical tools and growth into one place',
                    'Build something students actually enjoy opening every day',
                  ],
                ),
                const SizedBox(height: 18),
                const _SectionCard(
                  eyebrow: 'WHAT WE ARE BUILDING',
                  title: 'What Comes Next',
                  body:
                      'This feature is actively being worked on right now and is planned to release very soon. The goal is not just to ship a page, but to bring a more complete, polished, and valuable UniSync experience into the hands of students.',
                  bullets: [
                    'More refined workflows across the product',
                    'Better discovery for useful student opportunities',
                    'Sharper design, smoother flow, and stronger product clarity',
                  ],
                ),
                // const SizedBox(height: 18),
                // const _MiniRoadmap(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: onBack,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: UniSyncColors.surfaceCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: UniSyncColors.border),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: UniSyncColors.textPrimary,
            ),
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: UniSyncColors.accentSoft,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: UniSyncColors.accent.withValues(alpha: 0.35),
            ),
          ),
          child: Text(
            'NEXT UPDATE',
            style: GoogleFonts.dmSans(
              color: UniSyncColors.accent,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.8,
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: UniSyncColors.border),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF232319),
            Color(0xFF121212),
            Color(0xFF0B0B0D),
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x28000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'IN ACTIVE DEVELOPMENT',
            style: GoogleFonts.dmSans(
              color: UniSyncColors.accent,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.2,
            ),
          ),
          const SizedBox(height: 10),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'This feature is being ',
                  style: GoogleFonts.playfairDisplay(
                    color: UniSyncColors.textPrimary,
                    fontSize: 33,
                    fontWeight: FontWeight.w700,
                    height: 1.08,
                    letterSpacing: -0.6,
                  ),
                ),
                TextSpan(
                  text: 'worked on',
                  style: GoogleFonts.playfairDisplay(
                    color: UniSyncColors.accent,
                    fontSize: 33,
                    fontWeight: FontWeight.w700,
                    fontStyle: FontStyle.italic,
                    height: 1.08,
                    letterSpacing: -0.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'We are actively building this experience right now and it will be releasing very soon. Thanks for the patience while we shape it properly.',
            style: GoogleFonts.dmSans(
              color: UniSyncColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: UniSyncColors.surfaceCard.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: UniSyncColors.accent.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              'Releasing soon on UniSync',
              style: GoogleFonts.dmSans(
                color: UniSyncColors.textPrimary,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.bullets,
  });

  final String eyebrow;
  final String title;
  final String body;
  final List<String> bullets;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: UniSyncColors.surfaceCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: UniSyncColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow,
            style: GoogleFonts.dmSans(
              color: UniSyncColors.accent,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.playfairDisplay(
              color: UniSyncColors.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              height: 1.12,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: GoogleFonts.dmSans(
              color: UniSyncColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.75,
            ),
          ),
          const SizedBox(height: 16),
          ...bullets.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 7),
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: UniSyncColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: GoogleFonts.dmSans(
                        color: UniSyncColors.textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniRoadmap extends StatelessWidget {
  const _MiniRoadmap();

  @override
  Widget build(BuildContext context) {
    const items = [
      ('Now', 'Refining the foundation and polishing student essentials'),
      ('Next', 'Layering in better discovery, guidance, and experience quality'),
      ('Later', 'Growing UniSync into the everyday operating system for college life'),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: UniSyncColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ROADMAP FEEL',
            style: GoogleFonts.dmSans(
              color: UniSyncColors.accent,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Where We\'re Headed',
            style: GoogleFonts.playfairDisplay(
              color: UniSyncColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 62,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: UniSyncColors.accentSoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      item.$1,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        color: UniSyncColors.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.$2,
                      style: GoogleFonts.dmSans(
                        color: UniSyncColors.textSecondary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        height: 1.65,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
