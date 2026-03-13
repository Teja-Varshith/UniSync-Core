import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisync/features/Exam_Mode/models/exam_author_model.dart';
import 'package:unisync/features/Exam_Mode/models/exam_purchase_model.dart';
import 'package:unisync/features/Exam_Mode/models/exam_subject_model.dart';

final examRepositoryProvider = Provider<ExamRepository>((ref) {
  return ExamRepository(firestore: FirebaseFirestore.instance);
});

class ExamRepository {
  final FirebaseFirestore _firestore;

  ExamRepository({required FirebaseFirestore firestore}) : _firestore = firestore;

  // exam_subjects/{subjectId} => {
  //   title, code, description, semester,
  //   syllabusUnits, pyqs, cheatsheetUrl, videoLinks
  // }
  Stream<List<ExamSubjectModel>> watchSubjects({
    required int semester,
  }) {
    return _firestore
        .collection('exam_subjects')
        .where('semester', isEqualTo: semester)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ExamSubjectModel.fromMap(doc.id, doc.data()))
              .toList()
            ..sort((a, b) {
              return a.title.compareTo(b.title);
            }),
        );
  }

  Stream<ExamSubjectModel?> watchSubjectById(String subjectId) {
    return _firestore.collection('exam_subjects').doc(subjectId).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return ExamSubjectModel.fromMap(snapshot.id, snapshot.data()!);
    });
  }

  Stream<List<ExamAuthorModel>> watchAuthorsForSubjectCode(String subjectCode) {
    return _firestore.collection('authors').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ExamAuthorModel.fromMap(doc.id, doc.data()))
          .where((author) => author.writtenSubjects.containsKey(subjectCode))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
    });
  }

  Future<void> addExamSubject({
    required String title,
    required String code,
    required String description,
    required int semester,
    required List<String> syllabusUnits,
    required Map<String, String> pyqs,
    Map<String, String>? videoLinks,
    String? cheatsheetUrl,
  }) {
    return _firestore.collection('exam_subjects').add({
      'title': title,
      'code': code,
      'description': description,
      'semester': semester,
      'syllabusUnits': syllabusUnits,
      'pyqs': pyqs,
      'videoLinks': videoLinks ?? <String, String>{},
      'cheatsheetUrl': cheatsheetUrl ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addSyllabusUnit({
    required String subjectId,
    required String unitTitle,
  }) {
    return _firestore.collection('exam_subjects').doc(subjectId).update({
      'syllabusUnits': FieldValue.arrayUnion([unitTitle]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addPyq({
    required String subjectId,
    required String title,
    required String pdfUrl,
  }) {
    final key = _safeMapKey(title);
    return _firestore.collection('exam_subjects').doc(subjectId).update({
      'pyqs.$key': pdfUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setCheatsheetUrl({
    required String subjectId,
    required String cheatsheetUrl,
  }) {
    return _firestore.collection('exam_subjects').doc(subjectId).update({
      'cheatsheetUrl': cheatsheetUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addVideoLink({
    required String subjectId,
    required String title,
    required String videoUrl,
  }) {
    final key = _safeMapKey(title);
    return _firestore.collection('exam_subjects').doc(subjectId).update({
      'videoLinks.$key': videoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addAuthor({
    required String name,
    required Map<String, String> writtenSubjects,
    String? productId,
    String? displayPrice,
    Map<String, String>? subjectProductIds,
    Map<String, String>? subjectDisplayPrices,
    Map<String, List<Map<String, String>>>? subjectImportantQuestions,
  }) {
    return _firestore.collection('authors').add({
      'name': name,
      'writtenSubjects': writtenSubjects,
      'productId': productId,
      'displayPrice': displayPrice ?? 'Rs 0',
      'subjectProductIds': subjectProductIds ?? <String, String>{},
      'subjectDisplayPrices': subjectDisplayPrices ?? <String, String>{},
      'subjectImportantQuestions': subjectImportantQuestions ?? <String, List<Map<String, String>>>{},
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> saveExamPurchase(ExamPurchaseModel purchase) {
    final docId = '${purchase.subjectCode}_${purchase.authorId}';
    return _firestore
        .collection('users')
        .doc(purchase.uid)
        .collection('exam_purchases')
        .doc(docId)
        .set(purchase.toMap(), SetOptions(merge: true));
  }

  Future<Set<String>> getPurchasedAuthorIds({
    required String uid,
    required String subjectCode,
  }) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('exam_purchases')
        .where('subjectCode', isEqualTo: subjectCode)
        .where('status', whereIn: ['purchased', 'restored'])
        .get();

    return snapshot.docs
        .map((doc) => doc.data()['authorId']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  Future<double?> getUserAuthorRating({
    required String uid,
    required String authorId,
    required String subjectCode,
  }) async {
    final subjectKey = _safeMapKey(subjectCode);
    final docId = '${subjectKey}_$uid';

    final snapshot = await _firestore
        .collection('authors')
        .doc(authorId)
        .collection('ratings')
        .doc(docId)
        .get();

    if (!snapshot.exists) return null;
    final data = snapshot.data();
    if (data == null) return null;
    final value = data['rating'];
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  Future<void> submitAuthorRating({
    required String uid,
    required String authorId,
    required String subjectCode,
    required double rating,
  }) async {
    final normalizedRating = rating.clamp(1, 5).toDouble();
    final authorRef = _firestore.collection('authors').doc(authorId);
    final subjectKey = _safeMapKey(subjectCode);
    final ratingDocId = '${subjectKey}_$uid';
    final ratingsCollection = authorRef.collection('ratings');
    final ratingDocRef = ratingsCollection.doc(ratingDocId);

    await ratingDocRef.set({
      'uid': uid,
      'authorId': authorId,
      'subjectCode': subjectCode,
      'rating': normalizedRating,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final subjectRatingsSnapshot = await ratingsCollection
        .where('subjectCode', isEqualTo: subjectCode)
        .get();

    double sum = 0;
    var count = 0;
    for (final doc in subjectRatingsSnapshot.docs) {
      final value = doc.data()['rating'];
      final parsed = (value is num)
          ? value.toDouble()
          : double.tryParse(value?.toString() ?? '');
      if (parsed == null) continue;
      sum += parsed;
      count += 1;
    }

    final subjectAverage = count == 0 ? 0.0 : sum / count;
    final authorSnapshot = await authorRef.get();
    final authorData = authorSnapshot.data() ?? <String, dynamic>{};

    final subjectRatings = Map<String, dynamic>.from(
      authorData['subjectRatings'] as Map? ?? <String, dynamic>{},
    );
    final subjectRatingCounts = Map<String, dynamic>.from(
      authorData['subjectRatingCounts'] as Map? ?? <String, dynamic>{},
    );

    subjectRatings[subjectCode] = subjectAverage;
    subjectRatingCounts[subjectCode] = count;

    double weightedSum = 0;
    var weightedCount = 0;
    subjectRatings.forEach((key, avgVal) {
      final avg = (avgVal is num)
          ? avgVal.toDouble()
          : double.tryParse(avgVal.toString()) ?? 0.0;
      final cVal = subjectRatingCounts[key];
      final c = (cVal is num)
          ? cVal.toInt()
          : int.tryParse(cVal?.toString() ?? '') ?? 0;
      if (c <= 0) return;
      weightedSum += avg * c;
      weightedCount += c;
    });

    final overallAverage = weightedCount == 0 ? 0.0 : weightedSum / weightedCount;

    await authorRef.set({
      'subjectRatings': subjectRatings,
      'subjectRatingCounts': subjectRatingCounts,
      'rating': overallAverage,
      'ratingCount': weightedCount,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  String _safeMapKey(String raw) {
    return raw
        .trim()
        .replaceAll('.', ' ')
        .replaceAll('/', ' ')
        .replaceAll('[', ' ')
        .replaceAll(']', ' ')
        .replaceAll('#', ' ')
        .replaceAll(r'$', ' ')
        .replaceAll('*', ' ')
        .replaceAll('~', ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
  }
}
