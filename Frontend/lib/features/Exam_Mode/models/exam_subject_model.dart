class ExamSubjectModel {
  final String id;
  final String title;
  final String code;
  final String description;
  final int semester;
  final List<String> syllabusUnits;
  final Map<String, String> pyqs;
  final Map<String, String> videoLinks;
  final String? cheatsheetUrl;

  const ExamSubjectModel({
    required this.id,
    required this.title,
    required this.code,
    required this.description,
    required this.semester,
    required this.syllabusUnits,
    required this.pyqs,
    required this.videoLinks,
    this.cheatsheetUrl,
  });

  factory ExamSubjectModel.fromMap(String id, Map<String, dynamic> map) {
    return ExamSubjectModel(
      id: id,
      title: map['title'] ?? '',
      code: map['code'] ?? '',
      description: map['description'] ?? '',
      semester: map['semester'] is int ? map['semester'] as int : 1,
      syllabusUnits: _toStringList(map['syllabusUnits']),
      pyqs: _toStringMap(map['pyqs']),
      videoLinks: _videoLinksFromMap(map),
      cheatsheetUrl: _toNullableString(map['cheatsheetUrl']),
    );
  }

  static Map<String, String> _videoLinksFromMap(Map<String, dynamic> map) {
    final raw = map['videoLinks'] ?? map['ytVideos'] ?? map['videos'];
    return _toStringMap(raw);
  }

  static List<String> _toStringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).where((item) => item.trim().isNotEmpty).toList();
    }
    return const [];
  }

  static Map<String, String> _toStringMap(dynamic value) {
    if (value is Map) {
      return value.map(
        (key, val) => MapEntry(
          key.toString(),
          val.toString(),
        ),
      );
    }
    return const {};
  }

  static String? _toNullableString(dynamic value) {
    if (value == null) return null;
    final normalized = value.toString().trim();
    return normalized.isEmpty ? null : normalized;
  }
}
