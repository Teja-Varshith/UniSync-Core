import 'package:flutter_test/flutter_test.dart';
import 'package:UniSync/features/examsync/controller/examsync_controller.dart';
import 'package:UniSync/features/examsync/models/exam_data.dart';
import 'package:UniSync/features/examsync/models/subject.dart';
import 'package:UniSync/features/examsync/utils/hash.dart';
import 'package:UniSync/features/examsync/utils/numeric_keys.dart';

void main() {
  group('fnv1a32', () {
    test('matches reference FNV-1a values', () {
      expect(fnv1a32(''), 0x811c9dc5);
      expect(fnv1a32('a'), 0xe40c292c);
      expect(fnv1a32('foobar'), 0xbf9cf968);
    });
  });

  group('numeric keys', () {
    test('sort numerically, not lexically', () {
      final keys = ['10', '2', '1', '11', '3']..sort(compareNumericKeys);
      expect(keys, ['1', '2', '3', '10', '11']);
    });
  });

  group('syllabus', () {
    test('parses units, splits topics, sorts numerically', () {
      final units = SyllabusUnit.listFrom({
        'data': {
          '10': {'name': 'Ten', 'topics': 'a, b'},
          '2': {'name': 'Parsing', 'topics': 'LL(1), LR(0) ,, SLR '},
          '1': {'name': '', 'topics': ''},
        },
      });
      expect(units.map((u) => u.number), [1, 2, 10]);
      expect(units[0].name, 'Unit 1');
      expect(units[0].topics, isEmpty);
      expect(units[1].topics, ['LL(1)', 'LR(0)', 'SLR']);
    });

    test('handles legacy string units', () {
      final units = SyllabusUnit.listFrom({
        'data': {'3': 'x, y'},
      });
      expect(units.single.name, 'Unit 3');
      expect(units.single.topics, ['x', 'y']);
    });

    test('missing document yields empty list', () {
      expect(SyllabusUnit.listFrom(null), isEmpty);
    });
  });

  group('resources', () {
    test('notes use title, pyqs use tag, missing link kept as disabled', () {
      final notes = Resource.listFrom(ResourceKind.notes, {
        'data': {
          '2': {'title': 'Unit 2', 'link': ''},
          '1': {'title': 'Unit 1', 'link': 'https://x/1.pdf'},
        },
      });
      expect(notes.map((n) => n.title), ['Unit 1', 'Unit 2']);
      expect(notes[0].hasLink, isTrue);
      expect(notes[1].hasLink, isFalse);

      final pyqs = Resource.listFrom(ResourceKind.pyq, {
        'data': {
          '1': {'tag': 'Mid-1 2024', 'link': 'https://x/p.pdf'},
        },
      });
      expect(pyqs.single.title, 'Mid-1 2024');
    });
  });

  group('ImpQuestions', () {
    test('groups by exam, defaults missing tag, falls back to root map', () {
      final bank = ImpQuestionBank.fromDoc({
        'Mid 1': {
          '2': {'question': 'Q2', 'answer': '<p>a</p>', 'tag': 'Custom'},
          '1': {'question': 'Q1', 'answer': '<p>b</p>'},
        },
        'Sem': {},
      });
      final mid1 = bank.forExam('Mid 1');
      expect(mid1.map((q) => q.question), ['Q1', 'Q2']);
      expect(mid1.first.tag, kDefaultTag);
      expect(bank.forExam('Mid 2'), isEmpty);
      expect(bank.forExam('Sem'), isEmpty);
    });

    test('ordered tags include defaults and empty custom tags', () {
      final tags = orderedTags(['Extra'], const [
        ImpQuestion(question: 'q', answerHtml: '', tag: 'Other'),
      ]);
      expect(tags, [...kDefaultTags, 'Extra', 'Other']);
    });

    test('exam label', () {
      expect(examLabel('Sem'), 'Semester');
      expect(examLabel('Mid 1'), 'Mid 1');
    });
  });

  group('Subject', () {
    test('defaults price to 50 and parses course type', () {
      final s = Subject.fromMap('23CS015', {
        'subjectName': 'SPM',
        'courseType': 'Professional Elective',
        'semester': 5,
        'customTags': ['A', ' ', 'B'],
      });
      expect(s.courseCode, '23CS015');
      expect(s.price, kDefaultPakkaPassPrice);
      expect(s.courseType, CourseType.elective);
      expect(s.customTags, ['A', 'B']);
    });

    test('price 0 is free', () {
      expect(Subject.fromMap('x', {'price': 0}).isFree, isTrue);
    });
  });

  group('filters', () {
    test('changing year keeps a valid semester, else picks the first', () {
      const f = ExamSyncFilters(year: 3, semester: 6);
      expect(f.withYear(3).semester, 6);
      expect(f.withYear(4).semester, 7);
    });

    test('decode rejects inconsistent pairs', () {
      expect(ExamSyncFilters.decode('{"year":3,"semester":6}')?.semester, 6);
      expect(ExamSyncFilters.decode('{"year":3,"semester":2}'), isNull);
      expect(ExamSyncFilters.decode('garbage'), isNull);
    });
  });
}
