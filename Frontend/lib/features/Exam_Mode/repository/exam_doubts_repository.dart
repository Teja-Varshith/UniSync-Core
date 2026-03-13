import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisync/features/Exam_Mode/models/exam_doubt_comment_model.dart';
import 'package:unisync/features/Exam_Mode/models/exam_doubt_post_model.dart';

final examDoubtsRepositoryProvider = Provider<ExamDoubtsRepository>((ref) {
  return ExamDoubtsRepository(firestore: FirebaseFirestore.instance);
});

class ExamDoubtsRepository {
  final FirebaseFirestore _firestore;

  ExamDoubtsRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  CollectionReference get _postsRef => _firestore.collection('exam_doubts_posts');

  Stream<List<ExamDoubtPost>> watchAllPosts() {
    return _postsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ExamDoubtPost.fromDocument(d)).toList());
  }

  Stream<List<ExamDoubtPost>> watchUserPosts(String uid) {
    return _postsRef
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ExamDoubtPost.fromDocument(d)).toList());
  }

  Future<void> createPost(ExamDoubtPost post) async {
    await _postsRef.doc(post.postId).set(post.toMap());
  }

  Future<void> togglePostLike(String postId, String uid) async {
    final doc = _postsRef.doc(postId);
    final snap = await doc.get();
    if (!snap.exists) return;

    final post = ExamDoubtPost.fromDocument(snap);
    if (post.likedBy.contains(uid)) {
      await doc.update({'likedBy': FieldValue.arrayRemove([uid])});
    } else {
      await doc.update({'likedBy': FieldValue.arrayUnion([uid])});
    }
  }

  Stream<List<ExamDoubtComment>> watchComments(String postId) {
    return _postsRef
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ExamDoubtComment.fromDocument(d)).toList());
  }

  Future<void> addComment(ExamDoubtComment comment) async {
    await _postsRef
        .doc(comment.postId)
        .collection('comments')
        .doc(comment.commentId)
        .set(comment.toMap());

    await _postsRef.doc(comment.postId).update({
      'commentCount': FieldValue.increment(1),
      'isResolved': true,
    });
  }
}
