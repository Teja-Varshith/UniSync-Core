import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:UniSync/features/HomeScreen/models/home_hero_banner.dart';

class HomeHeroBannerRepository {
  HomeHeroBannerRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(kHomeHeroBannerCollection);

  /// Reads every banner, then filters and sorts in Dart.
  ///
  /// Deliberately *not* `.where('active', isEqualTo: true).orderBy('order')`.
  /// That form needs a composite index, and — worse — Firestore's `orderBy`
  /// silently omits any document missing the sort field, so a banner added
  /// from the console without an `order` value simply never appears and
  /// reports no error. This collection holds a handful of documents, so the
  /// cost of sorting client-side is nil and the behaviour is predictable.
  Future<List<HomeHeroBanner>> fetchBanners() async {
    final snapshot = await _collection.get();

    final banners = snapshot.docs
        .map(HomeHeroBanner.fromFirestore)
        .where((b) => b.active && b.isRenderable)
        .toList();

    banners.sort((a, b) {
      final byOrder = a.order.compareTo(b.order);
      // Stable tiebreak, so two banners sharing an order don't swap places
      // between loads.
      return byOrder != 0 ? byOrder : a.id.compareTo(b.id);
    });

    return banners;
  }

  /// Diagnostic counterpart to [fetchBanners]: reports what was skipped and
  /// why, so "my banner isn't showing" has an answer without a console trip.
  Future<String> describeSkipped() async {
    final snapshot = await _collection.get();
    final problems = <String>[];

    for (final doc in snapshot.docs) {
      final banner = HomeHeroBanner.fromFirestore(doc);
      if (!banner.active) {
        problems.add('${doc.id}: active is not true');
      } else if (!banner.isRenderable) {
        problems.add('${doc.id}: no title, subtitle or image');
      }
    }

    if (snapshot.docs.isEmpty) return 'collection is empty';
    return problems.isEmpty ? 'none' : problems.join('; ');
  }

  Future<void> upsertBanner({
    String? id,
    required String title,
    required String subtitle,
    required String ctaLabel,
    required HeroBannerActionType actionType,
    required String actionValue,
    required int order,
    bool active = true,
    String? palette,
    String? backdrop,
    String? art,
    String? imageUrl,
    String? imageAsset,
    HeroBannerImageMode imageMode = HeroBannerImageMode.art,
  }) async {
    final data = <String, dynamic>{
      'title': title.trim(),
      'subtitle': subtitle.trim(),
      'ctaLabel': ctaLabel.trim(),
      'actionType': actionType.name,
      'actionValue': actionValue.trim(),
      'order': order,
      'active': active,
      if (palette != null) 'palette': palette.trim(),
      if (backdrop != null) 'backdrop': backdrop.trim(),
      if (art != null) 'art': art.trim(),
      'imageUrl': imageUrl?.trim() ?? '',
      'imageAsset': imageAsset?.trim() ?? '',
      'imageMode': imageMode.name,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (id == null) {
      data['createdAt'] = FieldValue.serverTimestamp();
      await _collection.add(data);
    } else {
      await _collection.doc(id).set(data, SetOptions(merge: true));
    }
  }

  Future<void> deleteBanner(String id) => _collection.doc(id).delete();
}
