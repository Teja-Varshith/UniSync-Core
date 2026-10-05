import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:routemaster/routemaster.dart';
import 'package:UniSync/features/HomeScreen/models/home_hero_banner.dart';
import 'package:UniSync/features/HomeScreen/repository/home_hero_banner_repository.dart';
import 'package:url_launcher/url_launcher.dart';

final homeHeroBannerRepositoryProvider =
    Provider<HomeHeroBannerRepository>((ref) {
  return HomeHeroBannerRepository(FirebaseFirestore.instance);
});

final homeHeroBannerControllerProvider =
    AsyncNotifierProvider<HomeHeroBannerController, List<HomeHeroBanner>>(
  HomeHeroBannerController.new,
);

/// Routes a banner is allowed to open. Validated before navigating so an
/// authoring typo shows a message instead of dropping the user on an error
/// page. Keep in sync with `loggedInRoutes` in app/routes.dart.
const _knownRoutes = <String>{
  '/',
  '/peer',
  '/peerProfile',
  '/carrer',
  '/carrer-interview-screen',
  '/startInterviewScreen',
  '/coreInterviewScreen',
  '/interviewResultsScreen',
  '/interview-admin',
  '/settings',
  '/edit-profile',
  '/builderHomeScreen',
  '/cardsQuiz',
  '/reportsScreen',
  '/liveAttendence',
  '/liveAttendance',
  '/campXLogin',
  '/portifolio',
  '/nextUpdatePromo',
  '/userInterviewDetails',
  '/opportunities',
  '/webview',
};

class HomeHeroBannerController extends AsyncNotifier<List<HomeHeroBanner>> {
  @override
  FutureOr<List<HomeHeroBanner>> build() => _fetch();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _fetch());
  }

  /// Never returns an empty list: the bundled defaults stand in whenever
  /// Firestore answers with nothing, so the carousel is never blank.
  Future<List<HomeHeroBanner>> _fetch() async {
    final repo = ref.read(homeHeroBannerRepositoryProvider);
    try {
      final banners = await repo.fetchBanners();
      if (banners.isNotEmpty) {
        debugPrint('[HeroBanner] Loaded ${banners.length} from Firestore: '
            '${banners.map((b) => b.id).join(', ')}');
        return banners;
      }

      // Falling back is correct, but doing it silently is what makes a
      // misconfigured banner impossible to diagnose.
      final reason = await repo.describeSkipped();
      debugPrint('[HeroBanner] No usable banners, showing defaults. '
          'Skipped: $reason');
      return HomeHeroBanner.defaults;
    } catch (error, stack) {
      debugPrint('[HeroBanner] Fetch failed, showing defaults: $error');
      debugPrintStack(stackTrace: stack, maxFrames: 6);
      return HomeHeroBanner.defaults;
    }
  }

  Future<void> onBannerTap(BuildContext context, HomeHeroBanner banner) async {
    final value = banner.actionValue.trim();
    if (value.isEmpty) {
      _showMessage(context, 'This banner has no link yet');
      return;
    }

    switch (banner.actionType) {
      case HeroBannerActionType.url:
        final uri = Uri.tryParse(value);
        if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) {
          _showMessage(context, 'Invalid link on this banner');
          return;
        }
        final launched =
            await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!launched && context.mounted) {
          _showMessage(context, 'Could not open link');
        }
        return;

      case HeroBannerActionType.route:
        final route = value.startsWith('/') ? value : '/$value';
        if (!_knownRoutes.contains(route)) {
          _showMessage(context, 'That one is still being built — hang tight!');
          return;
        }
        Routemaster.of(context).push(route);
        return;
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
