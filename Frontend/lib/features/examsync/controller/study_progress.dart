import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:UniSync/features/examsync/controller/examsync_controller.dart';
import 'package:UniSync/features/examsync/models/exam_data.dart';
import 'package:UniSync/features/examsync/utils/hash.dart';

/// How the student rated a question after studying it.
enum QuestionMark { known, revise }

/// Stable id for a question: exam + hash of its text, so progress survives
/// authors reordering or inserting questions.
String questionKey(String exam, ImpQuestion q) =>
    '$exam::${fnv1a32(q.question).toRadixString(16)}';

class StudyProgress {
  const StudyProgress({this.marks = const {}, this.saved = const {}});

  final Map<String, QuestionMark> marks;
  final Set<String> saved;

  QuestionMark? markOf(String key) => marks[key];
  bool isSaved(String key) => saved.contains(key);

  /// Questions in [keys] marked as known.
  int knownIn(Iterable<String> keys) =>
      keys.where((k) => marks[k] == QuestionMark.known).length;

  StudyProgress withMark(String key, QuestionMark? mark) {
    final next = {...marks};
    mark == null ? next.remove(key) : next[key] = mark;
    return StudyProgress(marks: next, saved: saved);
  }

  StudyProgress toggleSaved(String key) {
    final next = {...saved};
    next.contains(key) ? next.remove(key) : next.add(key);
    return StudyProgress(marks: marks, saved: next);
  }

  String encode() => jsonEncode({
        'm': {for (final e in marks.entries) e.key: e.value.name},
        's': saved.toList(),
      });

  static StudyProgress decode(String? raw) {
    if (raw == null || raw.isEmpty) return const StudyProgress();
    try {
      final map = jsonDecode(raw);
      if (map is! Map) return const StudyProgress();
      final marks = <String, QuestionMark>{};
      final m = map['m'];
      if (m is Map) {
        for (final e in m.entries) {
          final mark =
              QuestionMark.values.where((v) => v.name == e.value).firstOrNull;
          if (mark != null) marks[e.key.toString()] = mark;
        }
      }
      final s = map['s'];
      return StudyProgress(
        marks: marks,
        saved: s is List ? s.map((e) => e.toString()).toSet() : const {},
      );
    } catch (_) {
      return const StudyProgress();
    }
  }
}

/// Per-subject study progress for the signed-in student, kept on device.
final studyProgressProvider = StateNotifierProvider.autoDispose
    .family<StudyProgressNotifier, StudyProgress, String>((ref, code) {
  final uid = ref.watch(examSyncUidProvider) ?? 'guest';
  return StudyProgressNotifier('examsync_progress::$uid::$code')..restore();
});

class StudyProgressNotifier extends StateNotifier<StudyProgress> {
  StudyProgressNotifier(this._prefsKey) : super(const StudyProgress());

  final String _prefsKey;
  bool _touched = false;

  Future<void> restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = StudyProgress.decode(prefs.getString(_prefsKey));
      if (mounted && !_touched) state = saved;
    } catch (_) {
      // Progress is a convenience; start fresh without it.
    }
  }

  void mark(String key, QuestionMark? mark) => _set(state.withMark(key, mark));

  void toggleSaved(String key) => _set(state.toggleSaved(key));

  void _set(StudyProgress next) {
    _touched = true;
    state = next;
    SharedPreferences.getInstance()
        .then((p) => p.setString(_prefsKey, next.encode()))
        .catchError((_) => false);
  }
}

/// Reading text size for answers, remembered across sessions.
const List<double> kReadingScales = [1.0, 1.15, 1.3];
const String _kReadingScaleKey = 'examsync_reading_scale';

final readingScaleProvider =
    StateNotifierProvider<ReadingScaleNotifier, double>(
        (ref) => ReadingScaleNotifier()..restore());

class ReadingScaleNotifier extends StateNotifier<double> {
  ReadingScaleNotifier() : super(kReadingScales.first);

  Future<void> restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = prefs.getDouble(_kReadingScaleKey);
      if (v != null && kReadingScales.contains(v) && mounted) state = v;
    } catch (_) {}
  }

  /// Steps to the next size, wrapping back to the smallest.
  void cycle() {
    final i = kReadingScales.indexOf(state);
    state = kReadingScales[(i + 1) % kReadingScales.length];
    SharedPreferences.getInstance()
        .then((p) => p.setDouble(_kReadingScaleKey, state))
        .catchError((_) => false);
  }
}
