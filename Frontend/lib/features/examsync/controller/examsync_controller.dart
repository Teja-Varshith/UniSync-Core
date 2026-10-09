import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:UniSync/app/providers.dart';
import 'package:UniSync/features/examsync/models/exam_data.dart';
import 'package:UniSync/features/examsync/models/subject.dart';
import 'package:UniSync/features/examsync/repository/examsync_repository.dart';

/// ExamSync identifies students by their UniSync user id (the same id the
/// web app received as `?uid=`). Null when signed out.
final examSyncUidProvider = Provider<String?>((ref) {
  final id = ref.watch(userProvider.select((u) => u?.id))?.trim() ?? '';
  return id.isEmpty ? null : id;
});

final examSyncCollegeIdProvider = Provider<String>((ref) => kExamSyncCollegeId);

/// Live coin balance from `users/{uid}`. Null when unknown.
final examSyncCoinsProvider = StreamProvider.autoDispose<int?>((ref) {
  final uid = ref.watch(examSyncUidProvider);
  if (uid == null) return Stream.value(null);
  return ref.watch(examSyncRepositoryProvider).coins(uid);
});

// ── Filters ────────────────────────────────────────────────────────────────

const Map<int, List<int>> kSemestersByYear = {
  1: [1, 2],
  2: [3, 4],
  3: [5, 6],
  4: [7, 8],
};

const String kFiltersPrefsKey = 'examsync_filters';

class ExamSyncFilters {
  const ExamSyncFilters({
    required this.year,
    required this.semester,
    this.courseType = CourseType.core,
  });

  final int year;
  final int semester;
  final CourseType courseType;

  /// Changing year keeps the semester when it belongs to the new year,
  /// otherwise picks that year's first semester.
  ExamSyncFilters withYear(int newYear) {
    final options = kSemestersByYear[newYear] ?? const [1];
    return ExamSyncFilters(
      year: newYear,
      semester: options.contains(semester) ? semester : options.first,
      courseType: courseType,
    );
  }

  ExamSyncFilters copyWith({int? semester, CourseType? courseType}) =>
      ExamSyncFilters(
        year: year,
        semester: semester ?? this.semester,
        courseType: courseType ?? this.courseType,
      );

  /// Accepts only a consistent year/semester pair.
  static ExamSyncFilters? tryCreate(int? year, int? semester) {
    if (year == null || semester == null) return null;
    final options = kSemestersByYear[year];
    if (options == null || !options.contains(semester)) return null;
    return ExamSyncFilters(year: year, semester: semester);
  }

  static ExamSyncFilters? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw);
      if (map is! Map) return null;
      return tryCreate(
        (map['year'] as num?)?.toInt(),
        (map['semester'] as num?)?.toInt(),
      );
    } catch (_) {
      return null;
    }
  }

  String encode() => jsonEncode({'year': year, 'semester': semester});
}

final examSyncFiltersProvider =
    StateNotifierProvider<ExamSyncFiltersNotifier, ExamSyncFilters>((ref) {
  final user = ref.read(userProvider);
  // Until saved filters load, start from the student's own profile, falling
  // back to 3rd year (the only cohort live today).
  final initial = ExamSyncFilters.tryCreate(user?.year, user?.semester) ??
      ExamSyncFilters.tryCreate(
        user?.year,
        kSemestersByYear[user?.year]?.first,
      ) ??
      const ExamSyncFilters(year: 3, semester: 5);
  return ExamSyncFiltersNotifier(initial)..restore();
});

class ExamSyncFiltersNotifier extends StateNotifier<ExamSyncFilters> {
  ExamSyncFiltersNotifier(super.initial);

  bool _touched = false;

  Future<void> restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = ExamSyncFilters.decode(prefs.getString(kFiltersPrefsKey));
      // A tap made while prefs were loading wins over the saved value.
      if (saved != null && mounted && !_touched) {
        state = saved.copyWith(courseType: state.courseType);
      }
    } catch (_) {
      // Prefs are a convenience; the defaults are fine without them.
    }
  }

  void setYear(int year) => _set(state.withYear(year));
  void setSemester(int semester) => _set(state.copyWith(semester: semester));

  /// Course type is a view toggle and isn't persisted.
  void setCourseType(CourseType type) =>
      state = state.copyWith(courseType: type);

  void _set(ExamSyncFilters next) {
    _touched = true;
    state = next;
    SharedPreferences.getInstance()
        .then((p) => p.setString(kFiltersPrefsKey, next.encode()))
        .catchError((_) => false);
  }
}

// ── Content ────────────────────────────────────────────────────────────────

final examSyncSubjectsProvider =
    FutureProvider.autoDispose.family<List<Subject>, int>((ref, semester) {
  return ref
      .watch(examSyncRepositoryProvider)
      .subjectsForSemester(ref.watch(examSyncCollegeIdProvider), semester);
});

final examSyncSubjectProvider =
    FutureProvider.autoDispose.family<Subject?, String>((ref, code) {
  return ref
      .watch(examSyncRepositoryProvider)
      .subject(ref.watch(examSyncCollegeIdProvider), code);
});

class SubjectContent {
  const SubjectContent({
    required this.syllabus,
    required this.notes,
    required this.pyqs,
  });

  final List<SyllabusUnit> syllabus;
  final List<Resource> notes;
  final List<Resource> pyqs;
}

final examSyncSubjectContentProvider = FutureProvider.autoDispose
    .family<SubjectContent, String>((ref, code) async {
  final repo = ref.watch(examSyncRepositoryProvider);
  final cid = ref.watch(examSyncCollegeIdProvider);
  final docs = await Future.wait([
    repo.examData(cid, code, 'syllabus'),
    repo.examData(cid, code, 'notes'),
    repo.examData(cid, code, 'pyqs'),
  ]);
  return SubjectContent(
    syllabus: SyllabusUnit.listFrom(docs[0]),
    notes: Resource.listFrom(ResourceKind.notes, docs[1]),
    pyqs: Resource.listFrom(ResourceKind.pyq, docs[2]),
  );
});

/// Whether the student has unlocked Pakka Pass for a subject.
final examSyncHasAccessProvider =
    FutureProvider.autoDispose.family<bool, String>((ref, code) async {
  final uid = ref.watch(examSyncUidProvider);
  if (uid == null) return false;
  return ref
      .watch(examSyncRepositoryProvider)
      .hasPaid(ref.watch(examSyncCollegeIdProvider), code, uid);
});

final examSyncImpQuestionsProvider = FutureProvider.autoDispose
    .family<ImpQuestionBank, String>((ref, code) async {
  final doc = await ref
      .watch(examSyncRepositoryProvider)
      .examData(ref.watch(examSyncCollegeIdProvider), code, 'ImpQuestions');
  return ImpQuestionBank.fromDoc(doc);
});

/// Last open tab per subject, kept for the session only.
final examSyncLastTabProvider = StateProvider<Map<String, int>>((ref) => {});

/// Runs the unlock and keeps UniSync's cached user in step with the new
/// balance so the rest of the app shows the same number.
Future<void> unlockPakkaPass(WidgetRef ref, Subject subject) async {
  final uid = ref.read(examSyncUidProvider);
  if (uid == null) throw const UnlockException(UnlockFailure.other);
  final after = await ref.read(examSyncRepositoryProvider).unlockPakkaPass(
        collegeId: ref.read(examSyncCollegeIdProvider),
        code: subject.courseCode,
        uid: uid,
        price: subject.price,
      );
  final user = ref.read(userProvider);
  if (after != null && user != null && user.id == uid) {
    ref.read(userProvider.notifier).state = user.copyWith(coins: after);
  }
  ref.invalidate(examSyncHasAccessProvider(subject.courseCode));
}
