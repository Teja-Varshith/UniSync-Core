import 'package:cloud_firestore/cloud_firestore.dart';

/// Coins needed to unlock Pakka Pass when a subject has no `price`.
const int kDefaultPakkaPassPrice = 50;

enum CourseType {
  core('Core'),
  elective('Electives');

  const CourseType(this.label);
  final String label;

  static CourseType fromRaw(String? raw) {
    final value = (raw ?? '').toLowerCase();
    return value.contains('elective') ? CourseType.elective : CourseType.core;
  }
}

class Subject {
  const Subject({
    required this.courseCode,
    required this.subjectName,
    required this.courseTypeLabel,
    required this.semester,
    required this.noOfUnits,
    required this.customTags,
    required this.price,
    this.description,
    this.createdAt,
  });

  final String courseCode;
  final String subjectName;

  /// Raw value, e.g. "Professional Core". Shown as-is in the subject hero.
  final String courseTypeLabel;
  final int semester;
  final int noOfUnits;
  final List<String> customTags;
  final int price;
  final String? description;
  final DateTime? createdAt;

  CourseType get courseType => CourseType.fromRaw(courseTypeLabel);
  bool get isFree => price <= 0;

  factory Subject.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) =>
      Subject.fromMap(doc.id, doc.data() ?? const {});

  factory Subject.fromMap(String id, Map<String, dynamic> data) {
    final code = _str(data['courseCode']);
    final desc = _str(data['description']);
    return Subject(
      courseCode: code.isNotEmpty ? code : id,
      subjectName: _str(data['subjectName']).isNotEmpty
          ? _str(data['subjectName'])
          : (code.isNotEmpty ? code : id),
      courseTypeLabel: _str(data['courseType']).isNotEmpty
          ? _str(data['courseType'])
          : 'Professional Core',
      semester: _int(data['semester']) ?? 0,
      noOfUnits: _int(data['noOfUnits']) ?? 0,
      customTags: (data['customTags'] is List)
          ? (data['customTags'] as List)
              .map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toList()
          : const [],
      price: _int(data['price']) ?? kDefaultPakkaPassPrice,
      description: desc.isEmpty ? null : desc,
      createdAt: _date(data['createdAt']),
    );
  }
}

String _str(Object? v) => v == null ? '' : v.toString().trim();

int? _int(Object? v) {
  if (v is num) return v.toInt();
  if (v is String) return num.tryParse(v.trim())?.toInt();
  return null;
}

DateTime? _date(Object? v) {
  if (v is Timestamp) return v.toDate();
  if (v is DateTime) return v;
  if (v is String) return DateTime.tryParse(v);
  if (v is num) return DateTime.fromMillisecondsSinceEpoch(v.toInt());
  return null;
}
