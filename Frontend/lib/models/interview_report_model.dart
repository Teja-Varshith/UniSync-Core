import 'dart:convert';

class InterviewReportResponse {
  final bool success;
  final List<InterviewSession> data;
  final int count;

  InterviewReportResponse({
    required this.success,
    required this.data,
    required this.count,
  });

  factory InterviewReportResponse.fromJson(Map<String, dynamic> json) {
    return InterviewReportResponse(
      success: json['success'] ?? false,
      data: (json['data'] as List)
          .map((e) => InterviewSession.fromJson(e))
          .toList(),
      count: json['count'] ?? 0,
    );
  }
}

class InterviewSession {
  final String id;
  final String userId;
  final String templateId;
  final String status;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final List<Question> questions;
  final List<Answer> answers;
  final FinalReport? finalReport;

  InterviewSession({
    required this.id,
    required this.userId,
    required this.templateId,
    required this.status,
    this.startedAt,
    this.endedAt,
    required this.questions,
    required this.answers,
    this.finalReport,
  });

  factory InterviewSession.fromJson(Map<String, dynamic> json) {
    // Parse finalReport string to object if it exists
    FinalReport? parsedFinalReport;
    if (json['finalReport'] != null && json['finalReport'] is String) {
      try {
        // jsonDecode automatically handles \n, \t, and other escape sequences
        final reportString = json['finalReport'] as String;
        final reportJson = jsonDecode(reportString) as Map<String, dynamic>;
        parsedFinalReport = FinalReport.fromJson(reportJson);
      } catch (e) {
        print('Error parsing finalReport: $e');
        print('Raw finalReport string: ${json['finalReport']}');
        parsedFinalReport = null;
      }
    } else if (json['finalReport'] != null && json['finalReport'] is Map) {
      parsedFinalReport = FinalReport.fromJson(json['finalReport']);
    }

    return InterviewSession(
      id: json['_id'],
      userId: json['userId'],
      templateId: json['templateId'],
      status: json['status'],
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'])
          : null,
      endedAt: json['endedAt'] != null 
          ? DateTime.parse(json['endedAt']) 
          : null,
      questions: (json['questions'] as List? ?? [])
          .map((e) => Question.fromJson(e))
          .toList(),
      answers: (json['answers'] as List? ?? [])
          .map((e) => Answer.fromJson(e))
          .toList(),
      finalReport: parsedFinalReport,
    );
  }
}

class Question {
  final String id;
  final String text;

  Question({
    required this.id,
    required this.text,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['_id'],
      text: json['text'],
    );
  }
}

class Answer {
  final String id;
  final String transcript;

  Answer({
    required this.id,
    required this.transcript,
  });

  factory Answer.fromJson(Map<String, dynamic> json) {
    return Answer(
      id: json['_id'],
      transcript: json['transcript'],
    );
  }
}

class FinalReport {
  final int? overallScore;
  final String? verdict;
  final SkillBreakdown? skillBreakdown;
  final List<String> strengths;
  final List<String> weaknesses;
  final List<ImprovementItem> improvementPlan;
  final String summary;
  final DateTime? generatedAt;

  FinalReport({
    this.overallScore,
    this.verdict,
    this.skillBreakdown,
    required this.strengths,
    required this.weaknesses,
    required this.improvementPlan,
    required this.summary,
    this.generatedAt,
  });

  factory FinalReport.fromJson(Map<String, dynamic> json) {
    return FinalReport(
      overallScore: json['overallScore'],
      verdict: json['verdict'],
      skillBreakdown: json['skillBreakdown'] != null
          ? SkillBreakdown.fromJson(json['skillBreakdown'])
          : null,
      strengths: List<String>.from(json['strengths'] ?? []),
      weaknesses: List<String>.from(json['weaknesses'] ?? []),
      improvementPlan: (json['improvementPlan'] as List? ?? [])
          .map((e) => ImprovementItem.fromJson(e))
          .toList(),
      summary: json['summary'] ?? '',
      generatedAt: json['generatedAt'] != null
          ? DateTime.parse(json['generatedAt'])
          : null,
    );
  }
}

class SkillBreakdown {
  final int? technical;
  final int? problemSolving;
  final int? communication;
  final int? confidence;

  SkillBreakdown({
    this.technical,
    this.problemSolving,
    this.communication,
    this.confidence,
  });

  factory SkillBreakdown.fromJson(Map<String, dynamic> json) {
    return SkillBreakdown(
      technical: json['technical'],
      problemSolving: json['problemSolving'],
      communication: json['communication'],
      confidence: json['confidence'],
    );
  }
}

class ImprovementItem {
  final String area;
  final String suggestion;

  ImprovementItem({
    required this.area,
    required this.suggestion,
  });

  factory ImprovementItem.fromJson(Map<String, dynamic> json) {
    return ImprovementItem(
      area: json['area'],
      suggestion: json['suggestion'],
    );
  }
}