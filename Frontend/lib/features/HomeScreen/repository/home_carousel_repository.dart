import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:UniSync/features/HomeScreen/models/home_carousel_item.dart';

class HomeCarouselRepository {
  HomeCarouselRepository(this._firestore);

  final FirebaseFirestore _firestore;

  Future<List<HomeCarouselItem>> fetchCarouselItems() async {
    final snapshot = await _firestore
        .collection('home_carousel')
        .where('isActive', isEqualTo: true)
        .orderBy('order')
        .get();

    // Keep a doc if it has anything to show at all. Artwork now comes from
    // the `art` enum, so an imageless banner is valid — but so is an
    // image-only one with no title, which an earlier title-only filter was
    // wrongly discarding.
    final items = snapshot.docs
        .map(HomeCarouselItem.fromFirestore)
        .where((item) =>
            item.title.trim().isNotEmpty ||
            item.subtitle.trim().isNotEmpty ||
            item.imageUrl.trim().isNotEmpty)
        .toList();

    items.sort((a, b) => a.order.compareTo(b.order));
    return items;
  }

  Future<void> addCarouselItem({
    required String imageUrl,
    required String title,
    required String subtitle,
    required HomeCarouselActionType actionType,
    required String actionValue,
    required int order,
    bool isActive = true,
  }) async {
    await _firestore.collection('home_carousel').add({
      'imageUrl': imageUrl.trim(),
      'title': title.trim(),
      'subtitle': subtitle.trim(),
      'actionType': homeCarouselActionTypeToValue(actionType),
      'actionValue': actionValue.trim(),
      'isActive': isActive,
      'order': order,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
