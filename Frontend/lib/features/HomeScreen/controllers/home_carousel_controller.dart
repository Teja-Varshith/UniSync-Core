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

class HomeCarouselController extends AsyncNotifier<List<HomeCarouselItem>> {
  @override
  FutureOr<List<HomeCarouselItem>> build() {
    return ref.read(homeCarouselRepositoryProvider).fetchCarouselItems();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(
      await ref.read(homeCarouselRepositoryProvider).fetchCarouselItems(),
    );
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

        final route = item.actionValue.startsWith('/')
            ? item.actionValue
            : '/${item.actionValue}';

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
