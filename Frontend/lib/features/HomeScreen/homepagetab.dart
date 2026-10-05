// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
//  home_page_tab.dart  â€”  CRED-style redesign (UI only, logic unchanged)
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
//
//  CHANGES (UI only, zero logic changes):
//  â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
//  1. _TopBar  â€” Logo anchored extreme-left (SVG), coins pill improved,
//                profile avatar kept as-is.
//  2. Greeting â€” "Hey, FIRSTNAME ðŸ‘‹" section added BELOW the app-bar,
//                ABOVE the carousel (inside SliverToBoxAdapter).
//  3. QuickActionTile â€” Replaced NeoPopButton shell with a clean CRED-style
//                white/surface Card. NeoPop graphics and all data props kept.
//  4. Section order â€” Appbar â†’ Greeting â†’ Carousel â†’ Quick Actions â†’ 
//                     Featured Projects â†’ Footer   (as requested).
//
//  UNCHANGED:
//  â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
//  â€¢ All providers, controllers, repositories, Firebase reads/writes
//  â€¢ QuickActionTileScheme, QuickActionGraphic, TileSchemes, all painters
//  â€¢ HomeQuickActionConfig, FeaturedProjectConfig factories
//  â€¢ _mergeQuickActions, _toQuickTiles, _resolvedRoute
//  â€¢ _NeoInterviewCard, _HomeCarouselSection
//  â€¢ _FeaturedProjectsSection, _HomeFooter, admin sheets
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•


import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:lottie/lottie.dart';
import 'package:neopop/neopop.dart';
import 'package:routemaster/routemaster.dart';
import 'package:UniSync/ads%20Manager/add_manager.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:UniSync/app/theme/app_colors.dart';
import 'package:UniSync/app/providers.dart';
import 'package:UniSync/constants/constant.dart';
import 'package:UniSync/features/coins/coin_purchase_service.dart';
import 'package:UniSync/features/HomeScreen/controllers/home_carousel_controller.dart';
import 'package:UniSync/features/HomeScreen/controllers/home_hero_banner_controller.dart';
import 'package:UniSync/features/HomeScreen/models/home_hero_banner.dart';
import 'package:UniSync/features/HomeScreen/models/home_carousel_item.dart';
import 'package:UniSync/features/HomeScreen/widgets/hero_banner/hero_banner_carousel.dart';
import 'package:UniSync/features/admin/view/secret_admin_gesture.dart';
import 'package:UniSync/features/HomeScreen/widgets/hero_banner/hero_surface.dart';

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
//  QUICK ACTION TILE SYSTEM  (data model unchanged)
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class QuickActionTileScheme {
  const QuickActionTileScheme({required this.bg, required this.accent});
  final Color bg;
  final Color accent;
}

enum QuickActionGraphic {
  network,
  resume,
  rings,
  dots,
  circuit,
  wave,
  spark,
  none,
}

class _HomePalette {
  const _HomePalette({
    required this.isDark,
    required this.accent,
    required this.onAccent,
    required this.background,
    required this.sectionBackground,
    required this.card,
    required this.cardAlt,
    required this.border,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.success,
  });

  final bool isDark;
  final Color accent;
  final Color onAccent;
  final Color background;
  final Color sectionBackground;
  final Color card;
  final Color cardAlt;
  final Color border;
  final Color divider;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color success;

  factory _HomePalette.of(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return _HomePalette(
      isDark: isDark,
      accent: scheme.primary,
      onAccent: scheme.onPrimary,
      background: theme.scaffoldBackgroundColor,
      sectionBackground:
          isDark ? AppColors.darkSurface : AppColors.lightSurface,
      card: isDark ? AppColors.darkCard : AppColors.lightCard,
      cardAlt: isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt,
      border: isDark ? AppColors.darkBorder : AppColors.lightBorder,
      divider: isDark
          ? AppColors.darkBorder.withValues(alpha: 0.8)
          : AppColors.lightBorder.withValues(alpha: 0.95),
      textPrimary: scheme.onSurface,
      textSecondary:
          isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
      textMuted: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
      success: AppColors.success,
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
//  CRED-STYLE QUICK ACTION CARD
//  Shell changed from NeoPopButton â†’ clean Material card.
//  All content props, graphics, and tap logic are IDENTICAL to before.
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class QuickActionTile extends StatelessWidget {
  const QuickActionTile({
    super.key,
    required this.scheme,
    required this.icon,
    required this.title,
    required this.chipLabel,
    required this.ctaLabel,
    this.route,
    this.externalUrl,
    this.creatorCredit,
    this.onInternalRouteTap,
    this.graphic = QuickActionGraphic.none,
    this.visible = true,
  });

  final QuickActionTileScheme scheme;
  final IconData icon;
  final String title;
  final String chipLabel;
  final String ctaLabel;
  final String? route;
  final String? externalUrl;
  final String? creatorCredit;
  final ValueChanged<String>? onInternalRouteTap;
  final QuickActionGraphic graphic;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    // Anatomy, top to bottom: uppercase title, grey subtitle, then the arrow
    // pinned to the bottom-left with the icon opposite it. Pinning the arrow
    // rather than letting it follow the text means every tile in a row has
    // its affordance on the same baseline, however long its title runs.
    return HeroSurface(
      height: 176,
      onTap: () => _handleTap(context),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.toUpperCase(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: HeroSurface.onSurface(context),
                height: 1.12,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              _subtitle(),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: HeroSurface.onSurfaceMuted(context),
                height: 1.35,
              ),
            ),
            const Spacer(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const HeroArrow(size: 36),
                const Spacer(),
                // The icon is the tile's only non-neutral mark besides the
                // arrow, and it is held back to a tint so it reads as a
                // quiet label rather than a second call to action.
                Icon(
                  icon,
                  size: 42,
                  color: scheme.accent.withValues(alpha: 0.42),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// The tile has a chip label and a creator credit but no real subtitle
  /// field, so the chip becomes the supporting line — it is the only one of
  /// the two that describes the destination.
  String _subtitle() {
    final chip = chipLabel.trim();
    final credit = creatorCredit?.trim() ?? '';
    if (chip.isNotEmpty && credit.isNotEmpty) return '$chip · by $credit';
    if (chip.isNotEmpty) return chip;
    if (credit.isNotEmpty) return 'By $credit';
    return ctaLabel.trim();
  }

  // Tap logic unchanged â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  void _handleTap(BuildContext context) {
    final website = externalUrl?.trim() ?? '';
    if (website.isNotEmpty) {
      final uri = Uri.tryParse(website);
      if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
        launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return;
    }

    final appRoute = route?.trim() ?? '';
    if (appRoute.isNotEmpty) {
      if (onInternalRouteTap != null) {
        onInternalRouteTap!(appRoute);
        return;
      }
      Routemaster.of(context).push(appRoute);
    }
  }
}


// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
//  PALETTE  (unchanged)
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class TileSchemes {
  static const peerConnect =
      QuickActionTileScheme(bg: Color(0xFF0E1E38), accent: Color(0xFF4A90E2));
  static const resumeBuilder =
      QuickActionTileScheme(bg: Color(0xFF1A1207), accent: Color(0xFFE8A838));
  static const events =
      QuickActionTileScheme(bg: Color(0xFF1A0E2B), accent: Color(0xFFB06FD8));
  static const coding =
      QuickActionTileScheme(bg: Color(0xFF0D1A10), accent: Color(0xFF3ECF8E));
  static const mentorship =
      QuickActionTileScheme(bg: Color(0xFF1F0E0E), accent: Color(0xFFE05252));
  static const courses =
      QuickActionTileScheme(bg: Color(0xFF0E1A1F), accent: Color(0xFF38BDF8));
  static const neonOrange =
      QuickActionTileScheme(bg: Color(0xFF2A1408), accent: Color(0xFFFF8A3D));
  static const magenta =
      QuickActionTileScheme(bg: Color(0xFF240C1F), accent: Color(0xFFFF6BCB));
  static const lime =
      QuickActionTileScheme(bg: Color(0xFF14200D), accent: Color(0xFF9BE15D));
  static const cyan =
      QuickActionTileScheme(bg: Color(0xFF0B1F24), accent: Color(0xFF4DE2FF));
  static const coral =
      QuickActionTileScheme(bg: Color(0xFF2A1115), accent: Color(0xFFFF7A8A));
}

class TileColorPreset {
  const TileColorPreset(
      {required this.key, required this.label, required this.scheme});
  final String key;
  final String label;
  final QuickActionTileScheme scheme;
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
//  CONFIG MODELS  (unchanged)
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class HomeQuickActionConfig {
  const HomeQuickActionConfig({
    required this.key,
    required this.title,
    required this.chipLabel,
    required this.ctaLabel,
    required this.route,
    required this.iconKey,
    required this.graphicKey,
    required this.section,
    required this.sortOrder,
    required this.visible,
    this.creatorName,
    this.externalUrl,
    this.bgColorHex,
    this.accentColorHex,
  });

  final String key;
  final String title;
  final String chipLabel;
  final String ctaLabel;
  final String route;
  final String iconKey;
  final String graphicKey;
  final String section;
  final int sortOrder;
  final bool visible;
  final String? creatorName;
  final String? externalUrl;
  final String? bgColorHex;
  final String? accentColorHex;

  factory HomeQuickActionConfig.fromMap(Map<String, dynamic> map, String id) {
    return HomeQuickActionConfig(
      key: (map['key'] ?? id).toString(),
      title: (map['title'] ?? '').toString(),
      chipLabel: (map['chipLabel'] ?? '').toString(),
      ctaLabel: (map['ctaLabel'] ?? '').toString(),
      route: (map['route'] ?? '').toString(),
      iconKey: (map['iconKey'] ?? 'apps').toString(),
      graphicKey: (map['graphicKey'] ?? 'none').toString(),
      section: (map['section'] ?? 'core').toString(),
      sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
      visible: map['visible'] != false,
      creatorName: map['creatorName']?.toString(),
      externalUrl: map['externalUrl']?.toString(),
      bgColorHex: map['bgColorHex']?.toString(),
      accentColorHex: map['accentColorHex']?.toString(),
    );
  }
}

class FeaturedProjectConfig {
  const FeaturedProjectConfig({
    required this.key,
    required this.title,
    required this.websiteUrl,
    required this.visible,
    required this.sortOrder,
    this.chipLabel,
    this.ctaLabel,
    this.graphicKey,
    this.bgColorHex,
    this.accentColorHex,
    this.description,
    this.creatorName,
  });

  final String key;
  final String title;
  final String websiteUrl;
  final bool visible;
  final int sortOrder;
  final String? chipLabel;
  final String? ctaLabel;
  final String? graphicKey;
  final String? bgColorHex;
  final String? accentColorHex;
  final String? description;
  final String? creatorName;

  factory FeaturedProjectConfig.fromMap(Map<String, dynamic> map, String id) {
    return FeaturedProjectConfig(
      key: (map['key'] ?? id).toString(),
      title: (map['title'] ?? '').toString(),
      websiteUrl: (map['websiteUrl'] ?? '').toString(),
      visible: map['visible'] != false,
      sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
      chipLabel: map['chipLabel']?.toString(),
      ctaLabel: map['ctaLabel']?.toString(),
      graphicKey: map['graphicKey']?.toString(),
      bgColorHex: map['bgColorHex']?.toString(),
      accentColorHex: map['accentColorHex']?.toString(),
      description: map['description']?.toString(),
      creatorName: map['creatorName']?.toString(),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
//  PROVIDERS  (unchanged)
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

final homeQuickActionsProvider = AsyncNotifierProvider<
    HomeQuickActionsController, List<HomeQuickActionConfig>>(
  HomeQuickActionsController.new,
);

class HomeQuickActionsController
    extends AsyncNotifier<List<HomeQuickActionConfig>> {
  @override
  Future<List<HomeQuickActionConfig>> build() => _fetchQuickActions();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _fetchQuickActions());
  }

  Future<List<HomeQuickActionConfig>> _fetchQuickActions() async {
    final firestore = ref.read(firebaseFirestoreProvider);
    final snapshot = await firestore
        .collection('config')
        .doc('homepage')
        .collection('quick_actions')
        .orderBy('sortOrder')
        .get();

    return snapshot.docs
        .map((doc) => HomeQuickActionConfig.fromMap(doc.data(), doc.id))
        .toList();
  }
}

final homeFeaturedProjectsProvider = AsyncNotifierProvider<
    HomeFeaturedProjectsController, List<FeaturedProjectConfig>>(
  HomeFeaturedProjectsController.new,
);

class HomeFeaturedProjectsController
    extends AsyncNotifier<List<FeaturedProjectConfig>> {
  @override
  Future<List<FeaturedProjectConfig>> build() => _fetchFeaturedProjects();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _fetchFeaturedProjects());
  }

  Future<List<FeaturedProjectConfig>> _fetchFeaturedProjects() async {
    final firestore = ref.read(firebaseFirestoreProvider);
    final snapshot = await firestore
        .collection('config')
        .doc('homepage')
        .collection('featured_projects')
        .orderBy('sortOrder')
        .get();

    return snapshot.docs
        .map((doc) => FeaturedProjectConfig.fromMap(doc.data(), doc.id))
        .toList();
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
//  ROOT PAGE WIDGET
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

class HomePageTab extends ConsumerStatefulWidget {
  const HomePageTab({super.key, this.onInternalRouteTap});
  final ValueChanged<String>? onInternalRouteTap;

  @override
  ConsumerState<HomePageTab> createState() => _HomePageTabState();
}

class _HomePageTabState extends ConsumerState<HomePageTab> {
  static const List<TileColorPreset> _tileColorPresets = [
    TileColorPreset(
        key: 'peerConnect',
        label: 'Ocean Blue',
        scheme: TileSchemes.peerConnect),
    TileColorPreset(
        key: 'resumeBuilder',
        label: 'Amber Gold',
        scheme: TileSchemes.resumeBuilder),
    TileColorPreset(
        key: 'events', label: 'Violet', scheme: TileSchemes.events),
    TileColorPreset(
        key: 'coding', label: 'Mint Green', scheme: TileSchemes.coding),
    TileColorPreset(
        key: 'mentorship', label: 'Ruby Red', scheme: TileSchemes.mentorship),
    TileColorPreset(
        key: 'courses', label: 'Sky Cyan', scheme: TileSchemes.courses),
    TileColorPreset(
        key: 'neonOrange',
        label: 'Neon Orange',
        scheme: TileSchemes.neonOrange),
    TileColorPreset(
        key: 'magenta', label: 'Magenta Pop', scheme: TileSchemes.magenta),
    TileColorPreset(key: 'lime', label: 'Lime Fresh', scheme: TileSchemes.lime),
    TileColorPreset(key: 'cyan', label: 'Aqua Glow', scheme: TileSchemes.cyan),
    TileColorPreset(
        key: 'coral', label: 'Coral Bloom', scheme: TileSchemes.coral),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await ref.read(coinPurchaseServiceProvider).initialize();
      } catch (_) {}
    });
  }

  // â”€â”€ All refresh/data logic UNCHANGED â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _refreshHomeData() async {
    await Future.wait([
      ref.read(homeHeroBannerControllerProvider.notifier).refresh(),
      ref.read(homeQuickActionsProvider.notifier).refresh(),
      ref.read(homeFeaturedProjectsProvider.notifier).refresh(),
    ]);
  }

  Future<void> _openCoinPurchaseSheet() async {
    final user = ref.read(userProvider);
    final currentCoins = user?.coins ?? 0;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: UniSyncColors.backgroundSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (ctx) {
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
                    color: UniSyncColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Current balance: $currentCoins coins',
                  style: const TextStyle(
                    color: UniSyncColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: UniSyncColors.surfaceCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: UniSyncColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Iconsax.empty_wallet_add,
                        color: UniSyncColors.accent,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          '100 Coins Pack',
                          style: TextStyle(
                            color: UniSyncColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      NeoPopButton(
                        color: UniSyncColors.accent,
                        bottomShadowColor: UniSyncColors.backgroundPrimary,
                        rightShadowColor: UniSyncColors.backgroundPrimary,
                        depth: 3,
                        onTapDown: () {},
                        onTapUp: () async {
                          final error = await ref
                              .read(coinPurchaseServiceProvider)
                              .buy100CoinsPack();
                          if (!mounted) return;
                          if (error != null) {
                            rootScaffoldMessengerKey.currentState
                              ?..hideCurrentSnackBar()
                              ..showSnackBar(
                                SnackBar(
                                  content: Text(error),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: UniSyncColors.error,
                                ),
                              );
                            return;
                          }
                          Navigator.of(ctx).pop();
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 14, vertical: 9),
                          child: Text(
                            'Rs 9',
                            style: TextStyle(
                              color: UniSyncColors.buttonPrimaryFg,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Uni-Coins can be used to redeem exclusive rewards and access premium features within the app.',
                  style: TextStyle(
                    color: UniSyncColors.textMuted,
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

  Future<void> _showAddCarouselDocSheet() async {
    final imageCtrl = TextEditingController();
    final titleCtrl = TextEditingController();
    final subtitleCtrl = TextEditingController();
    final actionValueCtrl = TextEditingController();
    final orderCtrl = TextEditingController(text: '0');
    var actionType = HomeCarouselActionType.url;
    var isActive = true;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: UniSyncColors.backgroundSecondary,
      builder: (context) =>
          StatefulBuilder(builder: (context, setModalState) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Add Carousel Doc (Temporary)',
                      style: TextStyle(
                          color: UniSyncColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  _inputField(controller: imageCtrl, label: 'Image URL *'),
                  const SizedBox(height: 10),
                  _inputField(controller: titleCtrl, label: 'Title *'),
                  const SizedBox(height: 10),
                  _inputField(controller: subtitleCtrl, label: 'Subtitle'),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                      child: DropdownButtonFormField<HomeCarouselActionType>(
                        initialValue: actionType,
                        decoration:
                            const InputDecoration(labelText: 'Action Type *'),
                        dropdownColor: UniSyncColors.surfaceCard,
                        items: const [
                          DropdownMenuItem(
                              value: HomeCarouselActionType.url,
                              child: Text('url')),
                          DropdownMenuItem(
                              value: HomeCarouselActionType.route,
                              child: Text('route')),
                        ],
                        onChanged: (v) {
                          if (v != null)
                            setModalState(() => actionType = v);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _inputField(
                            controller: orderCtrl,
                            label: 'Order',
                            keyboardType: TextInputType.number)),
                  ]),
                  const SizedBox(height: 10),
                  _inputField(
                      controller: actionValueCtrl,
                      label: actionType == HomeCarouselActionType.url
                          ? 'URL *'
                          : 'Route path *'),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    value: isActive,
                    onChanged: (v) => setModalState(() => isActive = v),
                    title: const Text('Active'),
                    activeThumbColor: UniSyncColors.accent,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (imageCtrl.text.trim().isEmpty ||
                            titleCtrl.text.trim().isEmpty ||
                            actionValueCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Please fill all required fields')));
                          return;
                        }
                        await ref
                            .read(homeCarouselControllerProvider.notifier)
                            .createCarouselItem(
                              imageUrl: imageCtrl.text,
                              title: titleCtrl.text,
                              subtitle: subtitleCtrl.text,
                              actionType: actionType,
                              actionValue: actionValueCtrl.text,
                              order:
                                  int.tryParse(orderCtrl.text.trim()) ?? 0,
                              isActive: isActive,
                            );
                        if (!mounted) return;
                        Navigator.of(this.context).pop();
                        ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(
                                content: Text('Carousel document added')));
                      },
                      child: const Text('Add to Firebase'),
                    ),
                  ),
                ]),
          ),
        );
      }),
    );
    imageCtrl.dispose();
    titleCtrl.dispose();
    subtitleCtrl.dispose();
    actionValueCtrl.dispose();
    orderCtrl.dispose();
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
  }) =>
      TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(labelText: label));

  // â”€â”€ Default data (unchanged) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  List<HomeQuickActionConfig> _defaultCoreQuickActions() => const [
        HomeQuickActionConfig(
          key: 'peer_connect',
          title: 'Peer\nConnect',
          chipLabel: '100+ Peers',
          ctaLabel: 'Connect',
          route: '/peer',
          iconKey: 'people',
          graphicKey: 'network',
          section: 'core',
          sortOrder: 1,
          visible: true,
          bgColorHex: '#0E1E38',
          accentColorHex: '#4A90E2',
        ),
        HomeQuickActionConfig(
          key: 'attendance',
          title: 'Live\nAttendance',
          chipLabel: 'Track in real time',
          ctaLabel: 'Track now',
          route: '/liveAttendence',
          iconKey: 'calendar',
          graphicKey: 'rings',
          section: 'core',
          sortOrder: 2,
          visible: true,
          bgColorHex: '#1A1207',
          accentColorHex: '#E8A838',
        ),
        HomeQuickActionConfig(
          key: 'aptitude',
          title: 'Aptitude\nPractice',
          chipLabel: 'Daily challenge',
          ctaLabel: 'Start',
          route: '/nextUpdatePromo',
          iconKey: 'bolt',
          graphicKey: 'spark',
          section: 'core',
          sortOrder: 3,
          visible: true,
          bgColorHex: '#0D1A10',
          accentColorHex: '#3ECF8E',
        ),
        HomeQuickActionConfig(
          key: 'uni_cards',
          title: 'Uni\nCards',
          chipLabel: 'Bite-sized prep',
          ctaLabel: 'Open',
          route: '/nextUpdatePromo',
          iconKey: 'style',
          graphicKey: 'wave',
          section: 'core',
          sortOrder: 4,
          visible: true,
          bgColorHex: '#240C1F',
          accentColorHex: '#FF6BCB',
        ),
      ];

  List<FeaturedProjectConfig> _defaultFeaturedProjects() => const [
        FeaturedProjectConfig(
          key: 'devfolio_showcase',
          title: 'DevFolio Showcase',
          websiteUrl: 'https://example.com/devfolio',
          visible: true,
          sortOrder: 1,
          chipLabel: 'Web platform',
          ctaLabel: 'Visit site',
          graphicKey: 'wave',
          bgColorHex: '#101626',
          accentColorHex: '#5AA9FF',
          description: 'Student portfolio and project showcase.',
          creatorName: 'Ananya R',
        ),
        FeaturedProjectConfig(
          key: 'examradar',
          title: 'ExamRadar',
          websiteUrl: 'https://example.com/examradar',
          visible: true,
          sortOrder: 2,
          chipLabel: 'Prep assistant',
          ctaLabel: 'Explore',
          graphicKey: 'spark',
          bgColorHex: '#1A1207',
          accentColorHex: '#E8A838',
          description: 'Tracks exam patterns and quick weekly prep plans.',
          creatorName: 'Rahul K',
        ),
        FeaturedProjectConfig(
          key: 'hostel_hub',
          title: 'Hostel Hub',
          websiteUrl: 'https://example.com/hostelhub',
          visible: true,
          sortOrder: 3,
          chipLabel: 'Campus utility',
          ctaLabel: 'Open app',
          graphicKey: 'network',
          bgColorHex: '#14200D',
          accentColorHex: '#9BE15D',
          description: 'Roommate finder and hostel issue tracker.',
          creatorName: 'Siri M',
        ),
      ];

  // â”€â”€ Helper methods (all unchanged) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  IconData _iconFromKey(String key) {
    switch (key.toLowerCase()) {
      case 'people':
        return Icons.people_alt_rounded;
      case 'calendar':
        return Icons.calendar_month_rounded;
      case 'bolt':
        return Icons.bolt_rounded;
      case 'style':
        return Icons.style_rounded;
      case 'description':
        return Icons.description_rounded;
      case 'event':
        return Icons.event_rounded;
      case 'code':
        return Icons.code_rounded;
      default:
        return Icons.apps_rounded;
    }
  }

  QuickActionGraphic _graphicFromKey(String key) {
    switch (key.toLowerCase()) {
      case 'network':
        return QuickActionGraphic.network;
      case 'resume':
        return QuickActionGraphic.resume;
      case 'rings':
        return QuickActionGraphic.rings;
      case 'dots':
        return QuickActionGraphic.dots;
      case 'circuit':
        return QuickActionGraphic.circuit;
      case 'wave':
        return QuickActionGraphic.wave;
      case 'spark':
        return QuickActionGraphic.spark;
      default:
        return QuickActionGraphic.none;
    }
  }

  String _colorToHex(Color color) {
    final value =
        color.value.toRadixString(16).padLeft(8, '0').toUpperCase();
    return '#${value.substring(2)}';
  }

  bool _isValidWebUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  String? _normalizeWebUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    if (_isValidWebUrl(trimmed)) return trimmed;
    final withScheme = 'https://$trimmed';
    if (_isValidWebUrl(withScheme)) return withScheme;
    return null;
  }

  Color _parseHexColor(String? hex, Color fallback) {
    if (hex == null || hex.trim().isEmpty) return fallback;
    final value = hex.replaceAll('#', '').trim();
    if (value.length != 6 && value.length != 8) return fallback;
    final normalized = value.length == 6 ? 'FF$value' : value;
    return Color(int.tryParse(normalized, radix: 16) ?? fallback.value);
  }

  QuickActionTileScheme _schemeFor(HomeQuickActionConfig config) {
    final lowerKey = config.key.toLowerCase();
    QuickActionTileScheme base;
    switch (lowerKey) {
      case 'peer_connect':
        base = TileSchemes.peerConnect;
        break;
      case 'attendance':
        base = TileSchemes.resumeBuilder;
        break;
      case 'aptitude':
        base = TileSchemes.coding;
        break;
      case 'uni_cards':
        base = TileSchemes.magenta;
        break;
      default:
        base = config.section.toLowerCase() == 'core'
            ? TileSchemes.events
            : TileSchemes.cyan;
    }
    final bg = _parseHexColor(config.bgColorHex, base.bg);
    final accent = _parseHexColor(config.accentColorHex, base.accent);
    return QuickActionTileScheme(bg: bg, accent: accent);
  }

  Future<void> _seedHomeConfig() async {
    final firestore = ref.read(firebaseFirestoreProvider);
    final homepageRef = firestore.collection('config').doc('homepage');
    final quickBatch = firestore.batch();
    for (final item in _defaultCoreQuickActions()) {
      final docRef = homepageRef.collection('quick_actions').doc(item.key);
      quickBatch.set(
          docRef,
          {
            'key': item.key,
            'title': item.title,
            'chipLabel': item.chipLabel,
            'ctaLabel': item.ctaLabel,
            'route': item.route,
            'externalUrl': item.externalUrl ?? '',
            'section': item.section,
            'iconKey': item.iconKey,
            'graphicKey': item.graphicKey,
            'bgColorHex': item.bgColorHex,
            'accentColorHex': item.accentColorHex,
            'creatorName': item.creatorName ?? '',
            'visible': item.visible,
            'sortOrder': item.sortOrder,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true));
    }
    for (final item in _defaultFeaturedProjects()) {
      final docRef =
          homepageRef.collection('featured_projects').doc(item.key);
      quickBatch.set(
          docRef,
          {
            'key': item.key,
            'title': item.title,
            'description': item.description ?? '',
            'websiteUrl': item.websiteUrl,
            'chipLabel': item.chipLabel ?? 'Student build',
            'ctaLabel': item.ctaLabel ?? 'Open project',
            'graphicKey': item.graphicKey ?? 'none',
            'bgColorHex': item.bgColorHex,
            'accentColorHex': item.accentColorHex,
            'creatorName': item.creatorName ?? '',
            'visible': item.visible,
            'sortOrder': item.sortOrder,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true));
    }
    await quickBatch.commit();
  }

  List<HomeQuickActionConfig> _mergeQuickActions(
      List<HomeQuickActionConfig> remote) {
    final merged = [...remote];
    merged.sort((a, b) {
      final sa = a.section.toLowerCase() == 'core' ? 0 : 1;
      final sb = b.section.toLowerCase() == 'core' ? 0 : 1;
      if (sa != sb) return sa.compareTo(sb);
      return a.sortOrder.compareTo(b.sortOrder);
    });
    return merged;
  }

  List<QuickActionTile> _toQuickTiles(List<HomeQuickActionConfig> configs) {
    return configs
        .where((c) => c.visible)
        .map((config) => QuickActionTile(
              scheme: _schemeFor(config),
              icon: _iconFromKey(config.iconKey),
              title: config.title,
              chipLabel: config.chipLabel,
              ctaLabel: config.ctaLabel,
              route: _resolvedRoute(config),
              externalUrl: config.externalUrl,
              creatorCredit: config.section.toLowerCase() == 'core'
                  ? null
                  : config.creatorName,
              onInternalRouteTap: widget.onInternalRouteTap,
              graphic: _graphicFromKey(config.graphicKey),
              visible: config.visible,
            ))
        .toList();
  }

  String _resolvedRoute(HomeQuickActionConfig config) {
    final key = config.key.toLowerCase();
    if (key == 'aptitude' || key == 'uni_cards') return '/nextUpdatePromo';
    return config.route;
  }

  Future<void> _showAdminToolsSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: UniSyncColors.backgroundSecondary,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Temporary Admin Tools',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: UniSyncColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.view_carousel_rounded),
                  title: const Text('Add Carousel Doc'),
                  onTap: () {
                    Navigator.pop(context);
                    _showAddCarouselDocSheet();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.tune_rounded),
                  title: const Text('Manage Home Config'),
                  onTap: () {
                    Navigator.pop(context);
                    _showHomeConfigSheet();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showHomeConfigSheet() async {
    final keyCtrl = TextEditingController();
    final titleCtrl = TextEditingController();
    final chipCtrl = TextEditingController();
    final ctaCtrl = TextEditingController();
    final routeCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    final creatorCtrl = TextEditingController();
    final orderCtrl = TextEditingController(text: '0');
    final descriptionCtrl = TextEditingController();
    final projectChipCtrl = TextEditingController(text: 'Student build');
    final projectCtaCtrl = TextEditingController(text: 'Open project');
    final bgColorCtrl = TextEditingController(text: '#0E1E38');
    final accentColorCtrl = TextEditingController(text: '#4A90E2');
    var isQuickAction = true;
    var visible = true;
    var section = 'core';
    var iconKey = 'apps';
    var graphicKey = 'none';
    var colorPresetKey = 'peerConnect';

    final firestore = ref.read(firebaseFirestoreProvider);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: UniSyncColors.backgroundSecondary,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Home Config (Temporary)',
                    style: TextStyle(
                      color: UniSyncColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Quick Action'),
                        selected: isQuickAction,
                        onSelected: (_) =>
                            setModalState(() => isQuickAction = true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Featured Project'),
                        selected: !isQuickAction,
                        onSelected: (_) =>
                            setModalState(() => isQuickAction = false),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  _inputField(
                      controller: keyCtrl, label: 'Key (optional)'),
                  const SizedBox(height: 8),
                  _inputField(controller: titleCtrl, label: 'Title *'),
                  const SizedBox(height: 8),
                  if (isQuickAction) ...[
                    _inputField(
                        controller: chipCtrl, label: 'Chip label *'),
                    const SizedBox(height: 8),
                    _inputField(
                        controller: ctaCtrl, label: 'CTA label *'),
                    const SizedBox(height: 8),
                    _inputField(
                        controller: routeCtrl, label: 'App route'),
                    const SizedBox(height: 8),
                    _inputField(
                        controller: urlCtrl,
                        label: 'External URL (optional)'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: section,
                      decoration:
                          const InputDecoration(labelText: 'Section'),
                      items: const [
                        DropdownMenuItem(
                            value: 'core', child: Text('core')),
                        DropdownMenuItem(
                            value: 'external', child: Text('external')),
                      ],
                      onChanged: (v) {
                        if (v != null)
                          setModalState(() => section = v);
                      },
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: iconKey,
                      decoration:
                          const InputDecoration(labelText: 'Icon key'),
                      items: const [
                        DropdownMenuItem(
                            value: 'apps', child: Text('apps')),
                        DropdownMenuItem(
                            value: 'people', child: Text('people')),
                        DropdownMenuItem(
                            value: 'calendar', child: Text('calendar')),
                        DropdownMenuItem(
                            value: 'bolt', child: Text('bolt')),
                        DropdownMenuItem(
                            value: 'style', child: Text('style')),
                        DropdownMenuItem(
                            value: 'description',
                            child: Text('description')),
                      ],
                      onChanged: (v) {
                        if (v != null)
                          setModalState(() => iconKey = v);
                      },
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: graphicKey,
                      decoration:
                          const InputDecoration(labelText: 'Graphic key'),
                      items: const [
                        DropdownMenuItem(
                            value: 'none', child: Text('none')),
                        DropdownMenuItem(
                            value: 'network', child: Text('network')),
                        DropdownMenuItem(
                            value: 'resume', child: Text('resume')),
                        DropdownMenuItem(
                            value: 'rings', child: Text('rings')),
                        DropdownMenuItem(
                            value: 'dots', child: Text('dots')),
                        DropdownMenuItem(
                            value: 'circuit', child: Text('circuit')),
                        DropdownMenuItem(
                            value: 'wave', child: Text('wave')),
                        DropdownMenuItem(
                            value: 'spark', child: Text('spark')),
                      ],
                      onChanged: (v) {
                        if (v != null)
                          setModalState(() => graphicKey = v);
                      },
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: colorPresetKey,
                      decoration: const InputDecoration(
                          labelText: 'Tile color theme'),
                      items: _tileColorPresets
                          .map((preset) => DropdownMenuItem(
                                value: preset.key,
                                child: Text(preset.label),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        final selected = _tileColorPresets
                            .firstWhere((item) => item.key == v);
                        setModalState(() {
                          colorPresetKey = v;
                          bgColorCtrl.text =
                              _colorToHex(selected.scheme.bg);
                          accentColorCtrl.text =
                              _colorToHex(selected.scheme.accent);
                        });
                      },
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Selected: bg ${bgColorCtrl.text} Â· accent ${accentColorCtrl.text}',
                      style: const TextStyle(
                        color: UniSyncColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ] else ...[
                    _inputField(
                        controller: descriptionCtrl,
                        label: 'Description'),
                    const SizedBox(height: 8),
                    _inputField(
                        controller: projectChipCtrl,
                        label: 'Chip label'),
                    const SizedBox(height: 8),
                    _inputField(
                        controller: projectCtaCtrl, label: 'CTA label'),
                    const SizedBox(height: 8),
                    _inputField(
                        controller: urlCtrl, label: 'Website URL *'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: graphicKey,
                      decoration:
                          const InputDecoration(labelText: 'Graphic key'),
                      items: const [
                        DropdownMenuItem(
                            value: 'none', child: Text('none')),
                        DropdownMenuItem(
                            value: 'network', child: Text('network')),
                        DropdownMenuItem(
                            value: 'resume', child: Text('resume')),
                        DropdownMenuItem(
                            value: 'rings', child: Text('rings')),
                        DropdownMenuItem(
                            value: 'dots', child: Text('dots')),
                        DropdownMenuItem(
                            value: 'circuit', child: Text('circuit')),
                        DropdownMenuItem(
                            value: 'wave', child: Text('wave')),
                        DropdownMenuItem(
                            value: 'spark', child: Text('spark')),
                      ],
                      onChanged: (v) {
                        if (v != null)
                          setModalState(() => graphicKey = v);
                      },
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: colorPresetKey,
                      decoration: const InputDecoration(
                          labelText: 'Tile color theme'),
                      items: _tileColorPresets
                          .map((preset) => DropdownMenuItem(
                                value: preset.key,
                                child: Text(preset.label),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        final selected = _tileColorPresets
                            .firstWhere((item) => item.key == v);
                        setModalState(() {
                          colorPresetKey = v;
                          bgColorCtrl.text =
                              _colorToHex(selected.scheme.bg);
                          accentColorCtrl.text =
                              _colorToHex(selected.scheme.accent);
                        });
                      },
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Selected: bg ${bgColorCtrl.text} Â· accent ${accentColorCtrl.text}',
                      style: const TextStyle(
                        color: UniSyncColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  _inputField(
                      controller: creatorCtrl,
                      label: 'Creator name (for credits)'),
                  const SizedBox(height: 8),
                  _inputField(
                    controller: orderCtrl,
                    label: 'Sort order',
                    keyboardType: TextInputType.number,
                  ),
                  SwitchListTile(
                    value: visible,
                    onChanged: (v) =>
                        setModalState(() => visible = v),
                    title: const Text('Visible'),
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: UniSyncColors.accent,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (titleCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Title is required')),
                          );
                          return;
                        }
                        final normalizedUrl =
                            _normalizeWebUrl(urlCtrl.text);
                        if (isQuickAction &&
                            (chipCtrl.text.trim().isEmpty ||
                                ctaCtrl.text.trim().isEmpty)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Chip and CTA are required for quick action')),
                          );
                          return;
                        }
                        if (isQuickAction &&
                            routeCtrl.text.trim().isEmpty &&
                            urlCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Provide either app route or external URL')),
                          );
                          return;
                        }
                        if (isQuickAction &&
                            urlCtrl.text.trim().isNotEmpty &&
                            normalizedUrl == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Enter a valid external URL (http/https)')),
                          );
                          return;
                        }
                        if (!isQuickAction &&
                            urlCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Website URL is required for project')),
                          );
                          return;
                        }
                        if (!isQuickAction && normalizedUrl == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Enter a valid website URL (http/https)')),
                          );
                          return;
                        }
                        final docId = keyCtrl.text.trim().isEmpty
                            ? DateTime.now()
                                .millisecondsSinceEpoch
                                .toString()
                            : keyCtrl.text.trim();
                        final order =
                            int.tryParse(orderCtrl.text.trim()) ?? 0;

                        if (isQuickAction) {
                          await firestore
                              .collection('config')
                              .doc('homepage')
                              .collection('quick_actions')
                              .doc(docId)
                              .set({
                            'key': docId,
                            'title': titleCtrl.text.trim(),
                            'chipLabel': chipCtrl.text.trim(),
                            'ctaLabel': ctaCtrl.text.trim(),
                            'route': routeCtrl.text.trim(),
                            'externalUrl': normalizedUrl ?? '',
                            'section': section,
                            'iconKey': iconKey,
                            'graphicKey': graphicKey,
                            'bgColorHex': bgColorCtrl.text.trim(),
                            'accentColorHex':
                                accentColorCtrl.text.trim(),
                            'creatorName': creatorCtrl.text.trim(),
                            'visible': visible,
                            'sortOrder': order,
                            'updatedAt': FieldValue.serverTimestamp(),
                          }, SetOptions(merge: true));
                        } else {
                          await firestore
                              .collection('config')
                              .doc('homepage')
                              .collection('featured_projects')
                              .doc(docId)
                              .set({
                            'key': docId,
                            'title': titleCtrl.text.trim(),
                            'description': descriptionCtrl.text.trim(),
                            'websiteUrl': normalizedUrl,
                            'chipLabel': projectChipCtrl.text.trim(),
                            'ctaLabel': projectCtaCtrl.text.trim(),
                            'graphicKey': graphicKey,
                            'bgColorHex': bgColorCtrl.text.trim(),
                            'accentColorHex':
                                accentColorCtrl.text.trim(),
                            'creatorName': creatorCtrl.text.trim(),
                            'visible': visible,
                            'sortOrder': order,
                            'updatedAt': FieldValue.serverTimestamp(),
                          }, SetOptions(merge: true));
                        }

                        if (!mounted) return;
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(
                              content: Text('Home config updated')),
                        );
                      },
                      child: const Text('Save to Firebase'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Quick Action Visibility',
                    style: TextStyle(
                      color: UniSyncColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: firestore
                        .collection('config')
                        .doc('homepage')
                        .collection('quick_actions')
                        .orderBy('sortOrder')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData ||
                          snapshot.data!.docs.isEmpty) {
                        return const Text(
                          'No quick actions in config yet.',
                          style: TextStyle(
                              color: UniSyncColors.textSecondary),
                        );
                      }
                      final docs = snapshot.data!.docs;
                      return Column(
                        children: docs.map((doc) {
                          final data = doc.data();
                          return SwitchListTile(
                            title: Text(
                              (data['title'] ?? doc.id).toString(),
                              style: const TextStyle(
                                  color: UniSyncColors.textPrimary),
                            ),
                            subtitle: Text(
                              (data['section'] ?? 'core').toString(),
                              style: const TextStyle(
                                  color: UniSyncColors.textMuted),
                            ),
                            value: data['visible'] != false,
                            onChanged: (value) {
                              doc.reference.set({'visible': value},
                                  SetOptions(merge: true));
                            },
                            contentPadding: EdgeInsets.zero,
                            activeThumbColor: UniSyncColors.accent,
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Featured Project Visibility',
                    style: TextStyle(
                      color: UniSyncColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: firestore
                        .collection('config')
                        .doc('homepage')
                        .collection('featured_projects')
                        .orderBy('sortOrder')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData ||
                          snapshot.data!.docs.isEmpty) {
                        return const Text(
                          'No featured projects in config yet.',
                          style: TextStyle(
                              color: UniSyncColors.textSecondary),
                        );
                      }
                      final docs = snapshot.data!.docs;
                      return Column(
                        children: docs.map((doc) {
                          final data = doc.data();
                          return Row(
                            children: [
                              Expanded(
                                child: SwitchListTile(
                                  title: Text(
                                    (data['title'] ?? doc.id)
                                        .toString(),
                                    style: const TextStyle(
                                        color: UniSyncColors.textPrimary),
                                  ),
                                  subtitle: Text(
                                    (data['creatorName'] ??
                                            'Creator not set')
                                        .toString(),
                                    style: const TextStyle(
                                        color: UniSyncColors.textMuted),
                                  ),
                                  value: data['visible'] != false,
                                  onChanged: (value) {
                                    doc.reference.set({'visible': value},
                                        SetOptions(merge: true));
                                  },
                                  contentPadding: EdgeInsets.zero,
                                  activeThumbColor: UniSyncColors.accent,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                    Icons.delete_outline_rounded),
                                color: UniSyncColors.error,
                                onPressed: () => doc.reference.delete(),
                              ),
                            ],
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    keyCtrl.dispose();
    titleCtrl.dispose();
    chipCtrl.dispose();
    ctaCtrl.dispose();
    routeCtrl.dispose();
    urlCtrl.dispose();
    creatorCtrl.dispose();
    orderCtrl.dispose();
    descriptionCtrl.dispose();
    projectChipCtrl.dispose();
    projectCtaCtrl.dispose();
    bgColorCtrl.dispose();
    accentColorCtrl.dispose();
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  //  BUILD â€” section order:
  //  SliverAppBar (logo left | coins | avatar)
  //  â†’ Greeting
  //  â†’ Carousel
  //  â†’ Quick Actions section (Interview card + tile grid)
  //  â†’ Featured Projects
  //  â†’ Footer
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  @override
  Widget build(BuildContext context) {
    final palette = _HomePalette.of(context);
    final user = ref.watch(userProvider);
    final bannerState = ref.watch(homeHeroBannerControllerProvider);
    final quickActionsState = ref.watch(homeQuickActionsProvider);
    final featuredProjectsState = ref.watch(homeFeaturedProjectsProvider);

    ref.listen(userProvider, (previous, next) {
      AdManager.instance.setAdFree(next?.hasAdFreeAccess ?? false);
    });

    final mergedQuickActions = _mergeQuickActions(
      quickActionsState.valueOrNull ?? const [],
    );
    final visibleTiles = _toQuickTiles(mergedQuickActions);
    final featuredProjects =
        (featuredProjectsState.valueOrNull ?? const [])
            .where((item) => item.visible)
            .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return Scaffold(
      // Same ground the card groups sit on, so there is no seam where a
      // section ends and the scaffold shows through.
      backgroundColor: HeroSurface.pageTint(context),
      // The hero banner starts at y = 0: no AppBar, and `top: false` so the
      // SafeArea never pads above it. The banner runs under the status bar
      // and gives that height back itself.
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: palette.accent,
          onRefresh: _refreshHomeData,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // â”€â”€ 1. HERO BANNER â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    // First child of the body, flush to the top, zero padding
                    // above it. The banner carries the top bar that the
                    // SliverAppBar used to.
                    _HomeHeroBannerSection(
                      bannerState: bannerState,
                      coins: user?.coins ?? 0,
                      onCoinTap: _openCoinPurchaseSheet,
                    ),

                    // â”€â”€ 2. GREETING + QUICK ACTIONS (one section) â”€â”€â”€â”€â”€â”€â”€â”€
                    // These used to be two blocks: a standalone greeting,
                    // then a "#BUILT FOR YOU / Level up your game" header.
                    // Two intros stacked cost ~150px before any content, and
                    // the generic header said less than the greeting does.
                    // The greeting is now the section's own heading.
                    // Cards are grouped inside one white container on a
                    // faintly tinted ground rather than floating loose on the
                    // page. The group is what makes a set of plain white
                    // cards read as deliberate instead of unstyled.
                    Container(
                      color: HeroSurface.pageTint(context),
                      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: HeroSurface.groupSurface(context),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding:
                                const EdgeInsets.fromLTRB(14, 18, 14, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding:
                                      EdgeInsets.only(left: 2, bottom: 14),
                                  child: HeroSectionTitle('Built for you'),
                                ),

                                // Wide lead tile
                                _NeoInterviewCard(
                                  parentContext: context,
                                  onInternalRouteTap:
                                      widget.onInternalRouteTap,
                                ),
                                const SizedBox(height: 12),

                                // 2-column tile grid
                                if (visibleTiles.isNotEmpty)
                                  _TileGrid(tiles: visibleTiles),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // â”€â”€ 5. FEATURED PROJECTS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    if (featuredProjects.isNotEmpty)
                      _FeaturedProjectsSection(
                        projects: featuredProjects,
                        onSubmitTap: _showFeaturedProjectApplySheet,
                      ),

                    const SizedBox(height: 14),

                    // â”€â”€ 6. FOOTER â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    const _HomeFooter(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Uri _featuredProjectEmailUri() {
    return Uri(
      scheme: 'mailto',
      path: 'hello.unisync@gmail.com',
      queryParameters: const {'subject': 'Featured Project Submission'},
    );
  }

  Future<void> _openFeaturedProjectEmail() async {
    final uri = _featuredProjectEmailUri();
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _showFeaturedProjectApplySheet() {
    final palette = _HomePalette.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: palette.sectionBackground,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _FeaturedProjectApplySheet(
        onApplyTap: _openFeaturedProjectEmail,
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
//  â‘  REDESIGNED TOP BAR
//  Layout: [Logo (extreme left)]  Â·Â·Â·  [Coins pill]  [Avatar]
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€


// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
//  GRID WRAPPER  (unchanged)
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _TileGrid extends StatelessWidget {
  const _TileGrid({required this.tiles});
  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < tiles.length; i += 2) {
      final isLast = i + 1 >= tiles.length;
      rows.add(Row(children: [
        Expanded(child: tiles[i]),
        if (!isLast) ...[
          const SizedBox(width: 12),
          Expanded(child: tiles[i + 1])
        ] else
          const Spacer(),
      ]));
      if (i + 2 < tiles.length) rows.add(const SizedBox(height: 12));
    }
    return Column(children: rows);
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
//  REST: unchanged components
//  (_SpotlightHeader, _NeoInterviewCard, _HomeCarouselSection,
//   _CarouselCard, _PageIndicator, _FeaturedProjectsSection,
//   _FeaturedProjectApplySheet, _FaqPoint, _HomeFooter, etc.)
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€



class _HomeHeroBannerSection extends ConsumerWidget {
  const _HomeHeroBannerSection({
    required this.bannerState,
    required this.coins,
    required this.onCoinTap,
  });

  final AsyncValue<List<HomeHeroBanner>> bannerState;
  final int coins;
  final VoidCallback onCoinTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The controller already guarantees a non-empty list — it substitutes the
    // bundled defaults whenever Firestore answers with nothing — so the only
    // case left here is the very first frame, before the future resolves.
    final banners = bannerState.valueOrNull ?? HomeHeroBanner.defaults;

    return HeroBannerCarousel(
      banners: banners,
      coins: coins,
      onCoinTap: onCoinTap,
      onBannerTap: (banner) => ref
          .read(homeHeroBannerControllerProvider.notifier)
          .onBannerTap(context, banner),
    );
  }
}

/// Compact sign-off that closes the page like an app, not a website.
///
/// The old footer was a tall editorial column — headline, subhead, byline,
/// links, status dot — which read as a marketing site someone had scrolled to
/// the bottom of. This is one screen-width card instead: soft overlapping
/// clouds in the brand colors, an oversized line of copy sitting on them, and
/// the legal bits shrunk to a single row.
/// Compact sign-off that closes the page like an app, not a website.
///
/// The old footer was a tall editorial column — headline, subhead, byline,
/// links, status dot — which read as a marketing site someone had scrolled to
/// the bottom of. This is the same information at a glance: one line of copy,
/// one attribution, one row of legal text.
class _HomeFooter extends StatelessWidget {
  const _HomeFooter();

  @override
  Widget build(BuildContext context) {
    final palette = _HomePalette.of(context);

    // Sits on the same tinted ground as the sections above, with its top
    // corners rounded so the page closes on a curve instead of a hard edge —
    // the footer reads as the last card in the stack rather than a strip
    // bolted to the bottom.
    return Container(
      width: double.infinity,
      color: HeroSurface.pageTint(context),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: HeroSurface.groupSurface(context),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 26, 20, 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // The whole footer is carried by this one line, the way an app
            // signs off with a remark instead of a sitemap.
            Text(
              'Made in college chaos.',
              style: TextStyle(
                color: HeroSurface.onSurface(context),
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'A product by UniApps (Team Aavishkaar)',
              style: TextStyle(
                color: HeroSurface.onSurfaceMuted(context),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),

            const SizedBox(height: 20),
            Row(
              children: [
                // Hidden route to the admin panel: six quick taps, or a
                // long press. The copyright line is a good host because
                // nobody taps it on purpose, so the gesture cannot fire by
                // accident during normal use.
                SecretAdminGesture(
                  child: Text(
                    '© 2026 UniSync',
                    style: TextStyle(
                      color: HeroSurface.onSurfaceMuted(context),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Container(
                  width: 3,
                  height: 3,
                  decoration: BoxDecoration(
                    color: HeroSurface.onSurfaceMuted(context),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 9),
                InkWell(
                  onTap: () => launchUrl(
                    Uri.parse('https://unisyncapp.in'),
                    mode: LaunchMode.externalApplication,
                  ),
                  child: Text(
                    'unisyncapp.in',
                    style: TextStyle(
                      color: palette.accent,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'Made in India',
                  style: TextStyle(
                    color: HeroSurface.onSurfaceMuted(context),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedProjectsSection extends StatelessWidget {
  const _FeaturedProjectsSection({
    required this.projects,
    required this.onSubmitTap,
  });
  final List<FeaturedProjectConfig> projects;
  final VoidCallback onSubmitTap;

  Color _parseHexColor(String? hex, Color fallback) {
    if (hex == null || hex.trim().isEmpty) return fallback;
    final value = hex.replaceAll('#', '').trim();
    if (value.length != 6 && value.length != 8) return fallback;
    final normalized = value.length == 6 ? 'FF$value' : value;
    return Color(int.tryParse(normalized, radix: 16) ?? fallback.value);
  }

  @override
  Widget build(BuildContext context) {
    final palette = _HomePalette.of(context);

    return Container(
      width: double.infinity,
      color: HeroSurface.pageTint(context),
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Container(
        decoration: BoxDecoration(
          color: HeroSurface.groupSurface(context),
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.only(bottom: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // The same plain, heavy, left-aligned title as the group
                // above — one heading style for the whole page.
                const HeroSectionTitle('Built by fellow students'),
                const SizedBox(height: 6),
                Text(
                  'Turn your project into a product with real users.',
                  style: TextStyle(
                    color: HeroSurface.onSurfaceMuted(context),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 220,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 22, right: 22),
              itemCount: projects.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final project = projects[index];
                final accent = _parseHexColor(project.accentColorHex, palette.success);
                final creator = (project.creatorName ?? '').trim();
                final desc = (project.description ?? '').trim();
                final chipLabel = (project.chipLabel ?? 'Student build').trim();

                return SizedBox(
                  width: 175,
                  // Same plain white card as the quick-action tiles: the
                  // project's own accent survives only in the small icon, so
                  // a scrolling row of them stays calm.
                  child: HeroSurface(
                    radius: 16,
                    onTap: () {
                      final url = project.websiteUrl.trim();
                      if (url.isNotEmpty) {
                        final uri = Uri.tryParse(url);
                        if (uri != null &&
                            (uri.scheme == 'http' || uri.scheme == 'https')) {
                          launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            project.title.toUpperCase(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: HeroSurface.onSurface(context),
                              height: 1.15,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Expanded(
                            child: Text(
                              desc.isEmpty ? chipLabel : desc,
                              overflow: TextOverflow.fade,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: HeroSurface.onSurfaceMuted(context),
                                height: 1.4,
                              ),
                            ),
                          ),
                          if (creator.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                'By $creator',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: HeroSurface.onSurfaceMuted(context)
                                      .withValues(alpha: 0.75),
                                ),
                              ),
                            ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const HeroArrow(size: 34),
                              const Spacer(),
                              Icon(
                                Icons.travel_explore_rounded,
                                size: 34,
                                color: accent.withValues(alpha: 0.42),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: onSubmitTap,
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Submit your project',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 13,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedProjectApplySheet extends StatelessWidget {
  const _FeaturedProjectApplySheet({required this.onApplyTap});
  final VoidCallback onApplyTap;

  @override
  Widget build(BuildContext context) {
    final palette = _HomePalette.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: palette.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.work_outline_rounded,
                color: palette.accent,
                size: 18,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Get featured on UniSync',
              style: TextStyle(
                color: palette.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Built a student project worth showcasing? Apply to get it reviewed for a featured spot on UniSync.',
              style: TextStyle(
                color: palette.textSecondary,
                fontSize: 12,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            const _FaqPoint(
              question: 'Who can apply?',
              answer:
                  'Any student-built project that is useful, interesting, or genuinely worth discovering by other students.',
            ),
            const _FaqPoint(
              question: 'What should you send?',
              answer:
                  'Share your project name, a short description, what problem it solves, and any link, demo, or screenshot.',
            ),
            const _FaqPoint(
              question: 'How does selection work?',
              answer:
                  'We review submissions manually and feature projects that feel relevant, thoughtful, and valuable.',
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: _NeoShimmerCtaButton(
                label: 'Apply to Feature',
                icon: Icons.auto_awesome_rounded,
                onTapUp: onApplyTap,
                accent: palette.success,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Email: hello.unisync@gmail.com',
              style: TextStyle(color: palette.textMuted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqPoint extends StatelessWidget {
  const _FaqPoint({required this.question, required this.answer});
  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    final palette = _HomePalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question,
              style: TextStyle(
                  color: palette.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 3),
          Text(answer,
              style: TextStyle(
                  color: palette.textSecondary,
                  fontSize: 12,
                  height: 1.45)),
        ],
      ),
    );
  }
}













class _NeoInterviewCard extends StatelessWidget {
  const _NeoInterviewCard({
    required this.parentContext,
    this.onInternalRouteTap,
  });
  final BuildContext parentContext;
  final ValueChanged<String>? onInternalRouteTap;

  void _openInterview() {
    const interviewRoute = '/carrer-interview-screen';
    if (onInternalRouteTap != null) {
      onInternalRouteTap!(interviewRoute);
      return;
    }
    Routemaster.of(parentContext).push(interviewRoute);
  }

  @override
  Widget build(BuildContext context) {
    // The wide tile at the top of the group: copy on the left, art bleeding
    // off the right, arrow on the bottom-left in line with the tiles below.
    // It is the same card as the others, only twice as wide — which is what
    // makes it read as the section's lead item rather than a second banner.
    return HeroSurface(
      onTap: _openInterview,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 0, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // The one gradient on the page below the banner, and it is
                  // on type rather than on a surface — a coloured headline
                  // costs no visual weight, a coloured panel costs a lot.
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [AppColors.secondary, AppColors.tertiary],
                    ).createShader(bounds),
                    child: const Text(
                      'AI MOCK INTERVIEWS',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                        height: 1.15,
                        // Painted over by the shader; must be opaque white.
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Practice live rounds. Get feedback instantly.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: HeroSurface.onSurfaceMuted(context),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // A NeoPop button rather than the plain arrow the small
                  // tiles use: this is the section's primary action, and the
                  // pressed-edge shell gives it weight the others don't have.
                  NeoPopButton(
                    color: AppColors.secondary,
                    bottomShadowColor: AppColors.tertiary,
                    rightShadowColor: AppColors.tertiary,
                    depth: 4,
                    onTapUp: _openInterview,
                    child: const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Start interview',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(
                            Icons.play_arrow_rounded,
                            size: 15,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Sized generously and allowed to run to the card edge, the way
            // the reference lets its illustrations touch the boundary.
            SizedBox(
              width: 108,
              height: 108,
              child: Lottie.asset(
                'assets/animations/span.json',
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────



class _NeoShimmerCtaButton extends StatelessWidget {
  const _NeoShimmerCtaButton({
    required this.label,
    required this.icon,
    required this.onTapUp,
    required this.accent,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTapUp;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return NeoPopTiltedButton(
      isFloating: true,
      decoration: NeoPopTiltedButtonDecoration(
        color: accent,
        plunkColor: accent,
        shadowColor: Colors.black.withValues(alpha: 0.5),
        showShimmer: true,
      ),
      onTapUp: onTapUp,
      child: SizedBox(
        height: 54,
        width: double.maxFinite,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                label,
                style: (theme.textTheme.titleSmall ?? const TextStyle())
                    .copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
