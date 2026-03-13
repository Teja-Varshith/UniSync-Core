import 'package:cloud_firestore/cloud_firestore.dart';

class ExamDoubtPost {
  final String postId;
  final String uid;
  final String authorName;
  final String? authorAvatar;
  final String title;
  final String description;
  final String? imageUrl;
  final List<String> tags;
  final List<String> likedBy;
  final int commentCount;
  final bool isResolved;
  final DateTime createdAt;

  const ExamDoubtPost({
    required this.postId,
    required this.uid,
    required this.authorName,
    required this.authorAvatar,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.tags,
    required this.likedBy,
    required this.commentCount,
    required this.isResolved,
    required this.createdAt,
  });

  factory ExamDoubtPost.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
    final createdRaw = data['createdAt'];

    return ExamDoubtPost(
      postId: doc.id,
      uid: (data['uid'] ?? '').toString(),
      authorName: (data['authorName'] ?? 'Student').toString(),
      authorAvatar: data['authorAvatar']?.toString(),
      title: (data['title'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      imageUrl: data['imageUrl']?.toString(),
      tags: ((data['tags'] as List?) ?? const [])
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList(),
      likedBy: ((data['likedBy'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      commentCount: (data['commentCount'] as num?)?.toInt() ?? 0,
      isResolved: data['isResolved'] == true,
      createdAt: createdRaw is Timestamp
          ? createdRaw.toDate()
          : DateTime.tryParse(createdRaw?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'postId': postId,
      'uid': uid,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'tags': tags,
      'likedBy': likedBy,
      'commentCount': commentCount,
      'isResolved': isResolved,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
