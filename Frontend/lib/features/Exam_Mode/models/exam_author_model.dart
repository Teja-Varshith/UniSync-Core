class ExamImportantQuestion {
  final String question;
  final String answerHtml;

  const ExamImportantQuestion({
    required this.question,
    required this.answerHtml,
  });
}

class ExamAuthorModel {
  final String id;
  final String name;
  final Map<String, String> writtenSubjects;
  final String? productId;
  final Map<String, String> subjectProductIds;
  final String displayPrice;
  final Map<String, String> subjectDisplayPrices;
  final double rating;
  final int ratingCount;
  final Map<String, double> subjectRatings;
  final Map<String, int> subjectRatingCounts;
  final Map<String, List<ExamImportantQuestion>> subjectImportantQuestions;

  const ExamAuthorModel({
    required this.id,
    required this.name,
    required this.writtenSubjects,
    this.productId,
    required this.subjectProductIds,
    required this.displayPrice,
    required this.subjectDisplayPrices,
    required this.rating,
    required this.ratingCount,
    required this.subjectRatings,
    required this.subjectRatingCounts,
    required this.subjectImportantQuestions,
  });

  factory ExamAuthorModel.fromMap(String id, Map<String, dynamic> map) {
    return ExamAuthorModel(
      id: id,
      name: map['name'] ?? '',
      writtenSubjects: _toStringMap(map['writtenSubjects']),
      productId: _toNullableString(map['productId']),
      subjectProductIds: _toStringMap(map['subjectProductIds']),
      displayPrice: _toNullableString(map['displayPrice']) ?? 'Rs 0',
      subjectDisplayPrices: _toStringMap(map['subjectDisplayPrices']),
      rating: _toDouble(map['rating']),
      ratingCount: _toInt(map['ratingCount']),
      subjectRatings: _toDoubleMap(map['subjectRatings']),
      subjectRatingCounts: _toIntMap(map['subjectRatingCounts']),
      subjectImportantQuestions: _parseImportantQuestions(map),
    );
  }

  String? samplePdfFor(String subjectCode) {
    return writtenSubjects[subjectCode];
  }

  String? productIdFor(String subjectCode) {
    return subjectProductIds[subjectCode] ?? productId;
  }

  String displayPriceFor(String subjectCode) {
    return subjectDisplayPrices[subjectCode] ?? displayPrice;
  }

  double ratingFor(String subjectCode) {
    return subjectRatings[subjectCode] ?? rating;
  }

  int ratingCountFor(String subjectCode) {
    return subjectRatingCounts[subjectCode] ?? ratingCount;
  }

  List<ExamImportantQuestion> importantQuestionsFor(String subjectCode) {
    return subjectImportantQuestions[subjectCode] ?? const [];
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

  static Map<String, double> _toDoubleMap(dynamic value) {
    if (value is Map) {
      return value.map(
        (key, val) => MapEntry(
          key.toString(),
          _toDouble(val),
        ),
      );
    }
    return const {};
  }

  static Map<String, int> _toIntMap(dynamic value) {
    if (value is Map) {
      return value.map(
        (key, val) => MapEntry(
          key.toString(),
          _toInt(val),
        ),
      );
    }
    return const {};
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  static int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String? _toNullableString(dynamic value) {
    if (value == null) return null;
    final normalized = value.toString().trim();
    return normalized.isEmpty ? null : normalized;
  }

  static Map<String, List<ExamImportantQuestion>> _parseImportantQuestions(
    Map<String, dynamic> map,
  ) {
    const candidateKeys = [
      'subjectImportantQuestions',
      'importantQuestionsBySubject',
      'importantQuestions',
    ];

    for (final key in candidateKeys) {
      final parsed = _fromSubjectMap(map[key]);
      if (parsed.isNotEmpty) return parsed;
    }

    return const {};
  }

  static Map<String, List<ExamImportantQuestion>> _fromSubjectMap(dynamic value) {
    if (value is! Map) return const {};

    final result = <String, List<ExamImportantQuestion>>{};
    value.forEach((subjectKey, rawList) {
      final subjectCode = subjectKey.toString().trim();
      if (subjectCode.isEmpty) return;
      final parsedList = _parseQuestionList(rawList);
      if (parsedList.isNotEmpty) {
        result[subjectCode] = parsedList;
      }
    });
    return result;
  }

  static List<ExamImportantQuestion> _parseQuestionList(dynamic value) {
    if (value is List) {
      final list = <ExamImportantQuestion>[];
      for (final item in value) {
        final parsed = _parseQuestionItem(item);
        if (parsed != null) list.add(parsed);
      }
      return list;
    }

    if (value is Map) {
      final list = <ExamImportantQuestion>[];

      // Supports nested shapes like:
      // subjectCode -> examType(mid1/final) -> [ { question, answerHtml, ... } ]
      // by recursively flattening nested maps/lists into question entries.
      value.forEach((questionKey, answerValue) {
        if (answerValue is List || answerValue is Map) {
          list.addAll(_parseQuestionList(answerValue));
          return;
        }

        final question = questionKey.toString().trim();
        final answerHtml = answerValue?.toString().trim() ?? '';
        if (question.isEmpty || answerHtml.isEmpty) return;
        list.add(ExamImportantQuestion(question: question, answerHtml: answerHtml));
      });

      return list;
    }

    return const [];
  }

  static ExamImportantQuestion? _parseQuestionItem(dynamic item) {
    if (item is Map) {
      final question = _pickString(item, const [
        'question',
        'questionText',
        'q',
        'title',
      ]);
      final answerHtml = _pickString(item, const [
        'answerHtml',
        'htmlAnswer',
        'answer',
        'a',
        'content',
      ]);
      if (question != null && answerHtml != null) {
        return ExamImportantQuestion(question: question, answerHtml: answerHtml);
      }
    }

    if (item is String) {
      final parts = item.split('|');
      if (parts.length >= 2) {
        final question = parts.first.trim();
        final answerHtml = parts.sublist(1).join('|').trim();
        if (question.isNotEmpty && answerHtml.isNotEmpty) {
          return ExamImportantQuestion(question: question, answerHtml: answerHtml);
        }
      }
    }

    return null;
  }

  static String? _pickString(Map<dynamic, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return null;
  }
}
