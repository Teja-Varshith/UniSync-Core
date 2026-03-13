import 'package:cloud_firestore/cloud_firestore.dart';

class ExamDoubtComment {
  final String commentId;
  final String postId;
  final String uid;
  final String authorName;
  final String message;
  final List<String> likedBy;
  final DateTime createdAt;

  const ExamDoubtComment({
    required this.commentId,
    required this.postId,
    required this.uid,
    required this.authorName,
    required this.message,
    required this.likedBy,
    required this.createdAt,
  });

  factory ExamDoubtComment.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
    final createdRaw = data['createdAt'];

    return ExamDoubtComment(
      commentId: doc.id,
      postId: (data['postId'] ?? '').toString(),
      uid: (data['uid'] ?? '').toString(),
      authorName: (data['authorName'] ?? 'Student').toString(),
      message: (data['message'] ?? '').toString(),
      likedBy: ((data['likedBy'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      createdAt: createdRaw is Timestamp
          ? createdRaw.toDate()
          : DateTime.tryParse(createdRaw?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'commentId': commentId,
      'postId': postId,
      'uid': uid,
      'authorName': authorName,
      'message': message,
      'likedBy': likedBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
