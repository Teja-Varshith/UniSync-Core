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

    final items = snapshot.docs
        .map(HomeCarouselItem.fromFirestore)
        .where((item) => item.imageUrl.isNotEmpty)
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
