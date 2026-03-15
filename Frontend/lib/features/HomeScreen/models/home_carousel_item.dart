import 'package:cloud_firestore/cloud_firestore.dart';

enum HomeCarouselActionType {
  url,
  route,
}

String homeCarouselActionTypeToValue(HomeCarouselActionType type) {
  switch (type) {
    case HomeCarouselActionType.route:
      return 'route';
    case HomeCarouselActionType.url:
      return 'url';
  }
}

class HomeCarouselItem {
  const HomeCarouselItem({
    required this.id,
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    required this.actionType,
    required this.actionValue,
    required this.isActive,
    required this.order,
  });

  final String id;
  final String imageUrl;
  final String title;
  final String subtitle;
  final HomeCarouselActionType actionType;
  final String actionValue;
  final bool isActive;
  final int order;

  factory HomeCarouselItem.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    return HomeCarouselItem(
      id: doc.id,
      imageUrl: (data['imageUrl'] ?? '').toString(),
      title: (data['title'] ?? '').toString(),
      subtitle: (data['subtitle'] ?? '').toString(),
      actionType: _parseActionType((data['actionType'] ?? '').toString()),
      actionValue: (data['actionValue'] ?? '').toString(),
      isActive: data['isActive'] is bool ? data['isActive'] as bool : true,
      order: data['order'] is int
          ? data['order'] as int
          : int.tryParse((data['order'] ?? '0').toString()) ?? 0,
    );
  }

  static HomeCarouselActionType _parseActionType(String value) {
    switch (value.toLowerCase().trim()) {
      case 'route':
      case 'app':
      case 'in_app':
      case 'inapp':
        return HomeCarouselActionType.route;
      case 'url':
      default:
        return HomeCarouselActionType.url;
    }
  }
}
