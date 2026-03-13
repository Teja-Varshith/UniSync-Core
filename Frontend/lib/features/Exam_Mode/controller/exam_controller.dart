import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisync/features/Exam_Mode/models/exam_author_model.dart';
import 'package:unisync/features/Exam_Mode/models/exam_subject_model.dart';
import 'package:unisync/features/Exam_Mode/repository/exam_repository.dart';

class ExamSelection {
  final int semester;

  const ExamSelection({
    required this.semester,
  });

  ExamSelection copyWith({
    int? semester,
  }) {
    return ExamSelection(
      semester: semester ?? this.semester,
    );
  }
}

final examSelectionProvider = StateProvider<ExamSelection?>((ref) => null);

final examSubjectsProvider =
    StreamProvider.family<List<ExamSubjectModel>, int>(
  (ref, params) {
    return ref
        .read(examRepositoryProvider)
        .watchSubjects(semester: params);
  },
);

final examSubjectProvider = StreamProvider.family<ExamSubjectModel?, String>((ref, subjectId) {
  return ref.read(examRepositoryProvider).watchSubjectById(subjectId);
});

final subjectAuthorsProvider = StreamProvider.family<List<ExamAuthorModel>, String>((ref, subjectCode) {
  return ref.read(examRepositoryProvider).watchAuthorsForSubjectCode(subjectCode);
});
