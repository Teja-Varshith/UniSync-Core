import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisync/features/Exam_Mode/models/exam_doubt_comment_model.dart';
import 'package:unisync/features/Exam_Mode/models/exam_doubt_post_model.dart';
import 'package:unisync/features/Exam_Mode/repository/exam_doubts_repository.dart';

final examAllDoubtsProvider = StreamProvider<List<ExamDoubtPost>>((ref) {
  return ref.read(examDoubtsRepositoryProvider).watchAllPosts();
});

final examMyDoubtsProvider = StreamProvider<List<ExamDoubtPost>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) {
    return Stream<List<ExamDoubtPost>>.value(const <ExamDoubtPost>[]);
  }
  return ref.read(examDoubtsRepositoryProvider).watchUserPosts(uid);
});

final examDoubtCommentsProvider =
    StreamProvider.family<List<ExamDoubtComment>, String>((ref, postId) {
  return ref.read(examDoubtsRepositoryProvider).watchComments(postId);
});
