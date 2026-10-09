import 'package:UniSync/features/examsync/utils/numeric_keys.dart';

/// Prep Pack exam keys, in display order. Stored exactly as these strings.
const List<String> kExamKeys = ['Mid 1', 'Mid 2', 'Sem'];

String examLabel(String key) => key == 'Sem' ? 'Semester' : key;

/// Tag keys as stored in Firestore. Kept unchanged so existing questions
/// still match; students see [tagLabel] instead.
const String kDefaultTag = 'Pakka Chadavali Amma';
const String kSecondaryTag = 'Evi kooda chudali';
const List<String> kDefaultTags = [kDefaultTag, kSecondaryTag];

/// Display name for a tag. The two default keys read like a promise of
/// marks, so they are shown with neutral study wording.
String tagLabel(String tag) => switch (tag) {
      kDefaultTag => 'High-priority revision',
      kSecondaryTag => 'Also worth revising',
      _ => tag,
    };

/// Every `exam_data` document wraps its payload in `data`. Older documents
/// put the map at the root instead.
Map<String, dynamic> unwrapData(Map<String, dynamic>? doc) {
  if (doc == null) return const {};
  final data = doc['data'];
  if (data is Map) return Map<String, dynamic>.from(data);
  if (doc.containsKey('data')) return const {};
  return doc;
}

class SyllabusUnit {
  const SyllabusUnit({
    required this.number,
    required this.name,
    required this.topics,
  });

  final int number;
  final String name;
  final List<String> topics;

  static List<String> splitTopics(Object? raw) => (raw ?? '')
      .toString()
      .split(',')
      .map((t) => t.trim())
      .where((t) => t.isNotEmpty)
      .toList();

  static List<SyllabusUnit> listFrom(Map<String, dynamic>? doc) {
    final entries = sortedNumericEntries(unwrapData(doc));
    final units = <SyllabusUnit>[];
    for (var i = 0; i < entries.length; i++) {
      final key = entries[i].key;
      final value = entries[i].value;
      final number = int.tryParse(key.trim()) ?? i + 1;
      if (value is Map) {
        final name = (value['name'] ?? '').toString().trim();
        units.add(SyllabusUnit(
          number: number,
          name: name.isEmpty ? 'Unit $number' : name,
          topics: splitTopics(value['topics']),
        ));
      } else if (value is String) {
        // Legacy: the unit is just its topics string.
        units.add(SyllabusUnit(
          number: number,
          name: 'Unit $number',
          topics: splitTopics(value),
        ));
      }
    }
    return units;
  }
}

enum ResourceKind { notes, pyq }

/// A PDF row: a note (`title`) or a previous-year paper (`tag`).
class Resource {
  const Resource({required this.kind, required this.title, this.link});

  final ResourceKind kind;
  final String title;
  final String? link;

  bool get hasLink => link != null && link!.isNotEmpty;

  static List<Resource> listFrom(ResourceKind kind, Map<String, dynamic>? doc) {
    final titleField = kind == ResourceKind.notes ? 'title' : 'tag';
    final fallback = kind == ResourceKind.notes ? 'Notes' : 'Question paper';
    final out = <Resource>[];
    for (final entry in sortedNumericEntries(unwrapData(doc))) {
      final value = entry.value;
      if (value is! Map) continue;
      final title = (value[titleField] ?? value['title'] ?? value['tag'] ?? '')
          .toString()
          .trim();
      final link = (value['link'] ?? '').toString().trim();
      out.add(Resource(
        kind: kind,
        title: title.isEmpty ? '$fallback ${entry.key}' : title,
        link: link.isEmpty ? null : link,
      ));
    }
    return out;
  }
}

class ImpQuestion {
  const ImpQuestion({
    required this.question,
    required this.answerHtml,
    required this.tag,
  });

  final String question;
  final String answerHtml;
  final String tag;
}

/// `ImpQuestions` grouped as exam key → questions (numerically ordered).
class ImpQuestionBank {
  const ImpQuestionBank(this.byExam);

  final Map<String, List<ImpQuestion>> byExam;

  List<ImpQuestion> forExam(String exam) => byExam[exam] ?? const [];

  factory ImpQuestionBank.fromDoc(Map<String, dynamic>? doc) {
    final data = unwrapData(doc);
    final byExam = <String, List<ImpQuestion>>{};
    for (final exam in kExamKeys) {
      final questions = <ImpQuestion>[];
      for (final entry in sortedNumericEntries(data[exam])) {
        final value = entry.value;
        if (value is! Map) continue;
        final question = (value['question'] ?? '').toString().trim();
        if (question.isEmpty) continue;
        final tag = (value['tag'] ?? '').toString().trim();
        questions.add(ImpQuestion(
          question: question,
          answerHtml: (value['answer'] ?? '').toString(),
          tag: tag.isEmpty ? kDefaultTag : tag,
        ));
      }
      byExam[exam] = questions;
    }
    return ImpQuestionBank(byExam);
  }
}

/// Tags shown for one exam: defaults, then the subject's custom tags, then
/// any other tag that appears on a question. Custom tags show even when they
/// have no questions yet.
List<String> orderedTags(List<String> customTags, List<ImpQuestion> questions) {
  final seen = <String>{};
  final out = <String>[];
  void add(String t) {
    if (t.isNotEmpty && seen.add(t)) out.add(t);
  }

  kDefaultTags.forEach(add);
  customTags.forEach(add);
  for (final q in questions) {
    add(q.tag);
  }
  return out;
}
