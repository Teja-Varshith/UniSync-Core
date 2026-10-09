import 'package:cloud_firestore/cloud_firestore.dart';

/// A user as the admin panel needs to see them — a flat view over the
/// `users` document, deliberately not reusing [UserModel], which carries
/// CampX credentials the panel has no business displaying.
class AdminUserRecord {
  const AdminUserRecord({
    required this.uid,
    required this.name,
    required this.email,
    required this.jntuNumber,
    required this.collegeName,
    required this.coins,
    required this.hasAdFreeAccess,
    required this.fcmToken,
    required this.year,
    required this.semester,
  });

  final String uid;
  final String name;
  final String email;

  /// The JNTU roll number. Stored as `campXUsername` because it doubles as
  /// the CampX login — the CampX form labels the same field "JNTU No / Email".
  final String jntuNumber;

  final String collegeName;
  final int coins;
  final bool hasAdFreeAccess;
  final String fcmToken;
  final int? year;
  final int? semester;

  bool get hasFcmToken => fcmToken.trim().isNotEmpty;

  factory AdminUserRecord.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return AdminUserRecord(
      uid: doc.id,
      name: _str(data['name']),
      email: _str(data['emailId']),
      jntuNumber: _str(data['campXUsername']),
      collegeName: _str(data['collegeName']),
      coins: (data['coins'] as num?)?.toInt() ?? 0,
      hasAdFreeAccess:
          data['hasAdFreeAccess'] is bool ? data['hasAdFreeAccess'] as bool : false,
      fcmToken: _str(data['fcmToken']),
      year: (data['year'] as num?)?.toInt(),
      semester: (data['semester'] as num?)?.toInt(),
    );
  }

  static String _str(Object? v) => (v ?? '').toString().trim();
}

// ─────────────────────────────────────────────────────────────────────────────

class AdminPaymentRecord {
  const AdminPaymentRecord({
    required this.uid,
    required this.purchaseId,
    required this.productId,
    required this.status,
    required this.coins,
    required this.purchasedAt,
  });

  final String uid;
  final String purchaseId;
  final String productId;
  final String status;
  final int coins;
  final DateTime? purchasedAt;

  factory AdminPaymentRecord.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    // A coinPurchases doc lives at users/{uid}/coinPurchases/{purchaseId},
    // so the owning uid is the grandparent's id.
    final uid = doc.reference.parent.parent?.id ?? '';
    return AdminPaymentRecord(
      uid: uid,
      purchaseId: doc.id,
      productId: (data['productId'] ?? '').toString(),
      status: (data['status'] ?? 'unknown').toString(),
      coins: (data['coins'] as num?)?.toInt() ?? 0,
      purchasedAt: (data['purchasedAt'] ?? data['createdAt']) is Timestamp
          ? ((data['purchasedAt'] ?? data['createdAt']) as Timestamp).toDate()
          : null,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class AdminUsersRepository {
  AdminUsersRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  /// Look a user up by JNTU number, email, or document id.
  ///
  /// Firestore has no case-insensitive or partial matching, so this tries the
  /// exact forms a roll number is realistically stored in (as typed, upper,
  /// lower) rather than pretending to do a fuzzy search.
  Future<List<AdminUserRecord>> searchUsers(String rawQuery) async {
    final query = rawQuery.trim();
    if (query.isEmpty) return const [];

    final results = <String, AdminUserRecord>{};

    Future<void> runQuery(String field, String value) async {
      final snap = await _users.where(field, isEqualTo: value).limit(20).get();
      for (final doc in snap.docs) {
        results[doc.id] = AdminUserRecord.fromDoc(doc);
      }
    }

    final variants = <String>{query, query.toUpperCase(), query.toLowerCase()};

    for (final variant in variants) {
      await runQuery('campXUsername', variant);
    }
    if (query.contains('@')) {
      await runQuery('emailId', query.toLowerCase());
    }

    // Last resort: the query might be a raw uid.
    if (results.isEmpty) {
      final byId = await _users.doc(query).get();
      if (byId.exists) results[byId.id] = AdminUserRecord.fromDoc(byId);
    }

    return results.values.toList();
  }

  Future<AdminUserRecord?> getUser(String uid) async {
    final doc = await _users.doc(uid).get();
    return doc.exists ? AdminUserRecord.fromDoc(doc) : null;
  }

  Future<void> setAdFree(String uid, bool value) async {
    await _users.doc(uid).set(
      {'hasAdFreeAccess': value},
      SetOptions(merge: true),
    );
  }

  Future<void> setCoins(String uid, int coins) async {
    await _users.doc(uid).set(
      {'coins': coins < 0 ? 0 : coins},
      SetOptions(merge: true),
    );
  }

  /// Purchases for one user.
  Future<List<AdminPaymentRecord>> paymentsForUser(String uid) async {
    final snap = await _users.doc(uid).collection('coinPurchases').get();
    final records = snap.docs.map(AdminPaymentRecord.fromDoc).toList();
    records.sort(_newestFirst);
    return records;
  }

  /// Every purchase across every user, newest first.
  ///
  /// A collection-group read with no `where`/`orderBy` needs no composite
  /// index, so sorting happens in Dart. Capped because this grows with the
  /// userbase and the panel only ever shows a page of it.
  Future<List<AdminPaymentRecord>> recentPayments({int limit = 100}) async {
    final snap = await _firestore
        .collectionGroup('coinPurchases')
        .limit(limit)
        .get();
    final records = snap.docs.map(AdminPaymentRecord.fromDoc).toList();
    records.sort(_newestFirst);
    return records;
  }

  static int _newestFirst(AdminPaymentRecord a, AdminPaymentRecord b) {
    final at = a.purchasedAt;
    final bt = b.purchasedAt;
    if (at == null && bt == null) return 0;
    if (at == null) return 1;
    if (bt == null) return -1;
    return bt.compareTo(at);
  }
}
