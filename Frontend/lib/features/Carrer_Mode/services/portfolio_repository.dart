import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:UniSync/app/providers.dart';
import 'package:UniSync/models/portifolo_model.dart';

final portfolioRepositoryProvider = Provider<PortfolioRepository>((ref) {
  return PortfolioRepository(
    firestore: ref.read(firebaseFirestoreProvider),
  );
});

class PortfolioRepository {
  final FirebaseFirestore _firestore;
  static const _collection = 'portfolios';

  PortfolioRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  CollectionReference<Map<String, dynamic>> get _portfoliosRef =>
      _firestore.collection(_collection);

  /// Fetch the portfolio for a given user.
  Future<PortifoloModel?> getPortfolio(String userId) async {
    try {
      final doc = await _portfoliosRef.doc(userId).get();
      if (!doc.exists || doc.data() == null) return null;
      return PortifoloModel.fromMap(doc.data()!);
    } catch (e) {
      throw Exception('Failed to fetch portfolio: $e');
    }
  }

  /// Create or update (merge) the portfolio document for the user.
  Future<void> savePortfolio(String userId, PortifoloModel portfolio) async {
    try {
      await _portfoliosRef.doc(userId).set(
            portfolio.copyWith(userId: userId).toMap(),
            SetOptions(merge: true),
          );
    } catch (e) {
      throw Exception('Failed to save portfolio: $e');
    }
  }
}
