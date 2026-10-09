import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:UniSync/app/providers.dart';
import 'package:UniSync/features/examsync/models/subject.dart';

/// College whose content students see. Content lives under
/// `examsync/{collegeId}`; the web student pages still read
/// `examsync/admins`, which has no subjects (see the brief, §8.1).
const String kExamSyncCollegeId = 'gmrit';

final examSyncRepositoryProvider = Provider<ExamSyncRepository>((ref) {
  return ExamSyncRepository(ref.read(firebaseFirestoreProvider));
});

enum UnlockFailure { insufficientCoins, noUserDoc, other }

class UnlockException implements Exception {
  const UnlockException(this.reason);
  final UnlockFailure reason;

  String get message => switch (reason) {
        UnlockFailure.insufficientCoins =>
          'You don’t have enough coins for this.',
        UnlockFailure.noUserDoc =>
          'We couldn’t find your coin wallet. Please try again.',
        UnlockFailure.other => 'Unlock failed. No coins were taken.',
      };
}

/// Read-mostly access to `examsync/{collegeId}`. The only write is
/// [unlockPrepPack]. Never reads the college document itself: it holds
/// `admins` / `examites` with passwords.
class ExamSyncRepository {
  ExamSyncRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _subjects(String collegeId) =>
      _db.collection('examsync').doc(collegeId).collection('subjects');

  /// Subjects for one semester, newest first. Sorting happens here rather
  /// than with `orderBy` so the query needs no composite index.
  Future<List<Subject>> subjectsForSemester(
      String collegeId, int semester) async {
    final snap =
        await _subjects(collegeId).where('semester', isEqualTo: semester).get();
    final list = snap.docs.map(Subject.fromFirestore).toList()
      ..sort((a, b) {
        final ad = a.createdAt, bd = b.createdAt;
        if (ad == null && bd == null) return 0;
        if (ad == null) return 1;
        if (bd == null) return -1;
        return bd.compareTo(ad);
      });
    return list;
  }

  Future<Subject?> subject(String collegeId, String code) async {
    final doc = await _subjects(collegeId).doc(code).get();
    if (!doc.exists) return null;
    return Subject.fromFirestore(doc);
  }

  /// One of `syllabus`, `notes`, `pyqs`, `ImpQuestions`.
  Future<Map<String, dynamic>?> examData(
    String collegeId,
    String code,
    String docId,
  ) async {
    final doc = await _subjects(collegeId)
        .doc(code)
        .collection('exam_data')
        .doc(docId)
        .get();
    return doc.data();
  }

  DocumentReference<Map<String, dynamic>> _paidRef(
    String collegeId,
    String code,
    String uid,
  ) =>
      _subjects(collegeId).doc(code).collection('paid_users').doc(uid);

  Future<bool> hasPaid(String collegeId, String code, String uid) async {
    final doc = await _paidRef(collegeId, code, uid).get();
    return doc.exists;
  }

  Stream<int?> coins(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((snap) {
      final value = snap.data()?['coins'];
      return value is num ? value.toInt() : null;
    });
  }

  /// Charges [price] coins and records the purchase in one transaction, so a
  /// double tap or a failure half-way can never take coins without unlocking
  /// (or unlock twice). Returns the balance after the unlock, or null for a
  /// free subject.
  ///
  /// If the user already has a `paid_users` record nothing is charged.
  Future<int?> unlockPrepPack({
    required String collegeId,
    required String code,
    required String uid,
    required int price,
  }) async {
    final userRef = _db.collection('users').doc(uid);
    final paidRef = _paidRef(collegeId, code, uid);
    try {
      return await _db.runTransaction<int?>((tx) async {
        final paid = await tx.get(paidRef);
        if (price <= 0) {
          if (!paid.exists) {
            tx.set(
                paidRef, {'paidAt': DateTime.now().toUtc().toIso8601String()});
          }
          return null;
        }

        final user = await tx.get(userRef);
        if (!user.exists) throw const UnlockException(UnlockFailure.noUserDoc);
        final raw = user.data()?['coins'];
        final coins = raw is num ? raw.toInt() : 0;
        if (paid.exists) return coins;
        if (coins < price) {
          throw const UnlockException(UnlockFailure.insufficientCoins);
        }

        final after = coins - price;
        tx.update(userRef, {'coins': after});
        tx.set(paidRef, {'paidAt': DateTime.now().toUtc().toIso8601String()});
        return after;
      });
    } on UnlockException {
      rethrow;
    } catch (_) {
      throw const UnlockException(UnlockFailure.other);
    }
  }
}
