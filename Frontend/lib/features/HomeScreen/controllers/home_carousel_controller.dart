import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:routemaster/routemaster.dart';
import 'package:UniSync/features/HomeScreen/models/home_carousel_item.dart';
import 'package:UniSync/features/HomeScreen/repository/home_carousel_repository.dart';
import 'package:url_launcher/url_launcher.dart';

final homeCarouselRepositoryProvider = Provider<HomeCarouselRepository>((ref) {
  return HomeCarouselRepository(FirebaseFirestore.instance);
});

final homeCarouselControllerProvider =
    AsyncNotifierProvider<HomeCarouselController, List<HomeCarouselItem>>(
  HomeCarouselController.new,
);

/// Routes a banner is allowed to open. Validated before navigating so an
/// authoring typo shows a "still being built" message instead of dropping the
/// user on an error page. Keep in sync with `loggedInRoutes` in app/routes.dart.
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

class HomeCarouselController extends AsyncNotifier<List<HomeCarouselItem>> {
  @override
  FutureOr<List<HomeCarouselItem>> build() => _fetch();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _fetch());
  }

  /// Never returns an empty list: the bundled defaults stand in until remote
  /// content answers, and whenever it answers with nothing — empty collection,
  /// no network, rejected read. The carousel is never blank.
  Future<List<HomeCarouselItem>> _fetch() async {
    try {
      final items =
          await ref.read(homeCarouselRepositoryProvider).fetchCarouselItems();
      if (items.isEmpty) {
        // Falling back is correct, but doing it silently makes "my banner
        // isn't showing" impossible to diagnose — say so.
        debugPrint(
          '[Carousel] Query returned 0 usable banners; showing defaults. '
          'Check that each doc has isActive == true (boolean, not "true"), '
          'a numeric `order` field (docs missing `order` are excluded by '
          'orderBy), and a title or imageUrl.',
        );
        return HomeCarouselItem.defaults;
      }
      debugPrint('[Carousel] Loaded ${items.length} banner(s) from Firestore: '
          '${items.map((i) => i.id).join(', ')}');
      return items;
    } catch (error, stack) {
      // A missing composite index for (isActive, order) throws here with a
      // console link to create it. Swallowing that silently is how a real
      // configuration error looks identical to an empty collection.
      debugPrint('[Carousel] Fetch failed, showing defaults: $error');
      debugPrintStack(stackTrace: stack, maxFrames: 6);
      return HomeCarouselItem.defaults;
    }
  }

  Future<void> createCarouselItem({
    required String imageUrl,
    required String title,
    required String subtitle,
    required HomeCarouselActionType actionType,
    required String actionValue,
    required int order,
    bool isActive = true,
  }) async {
    await ref.read(homeCarouselRepositoryProvider).addCarouselItem(
          imageUrl: imageUrl,
          title: title,
          subtitle: subtitle,
          actionType: actionType,
          actionValue: actionValue,
          order: order,
          isActive: isActive,
        );

    await refresh();
  }

  Future<void> onBannerTap(BuildContext context, HomeCarouselItem item) async {
    switch (item.actionType) {
      case HomeCarouselActionType.url:
        final uri = Uri.tryParse(item.actionValue);
        if (uri == null) {
          _showMessage(context, 'Invalid URL in banner');
          return;
        }

        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );

        if (!launched && context.mounted) {
          _showMessage(context, 'Could not open link');
        }
        return;

      case HomeCarouselActionType.route:
        if (item.actionValue.trim().isEmpty) {
          _showMessage(context, 'Invalid in-app route');
          return;
        }

        final raw = item.actionValue.trim();
        final route = raw.startsWith('/') ? raw : '/$raw';

        // An unknown route means someone typo'd the banner doc. Say so
        // instead of dropping the user on an error page.
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
