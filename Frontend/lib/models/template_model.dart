// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:collection/collection.dart';

class TemplateModel {
  final String id;
  final String title;
  final List<String> topics;
  final List<EvaluationMetric> evaluationMetrics;
  final String domain;
  final String icon;

  TemplateModel({
    required this.id,
    required this.title,
    required this.topics,
    required this.evaluationMetrics,
    required this.domain,
    required this.icon,
  });

  factory TemplateModel.fromMap(Map<String, dynamic> map) {
    final metricsJson =
        map['evaluationMetrics'] ??
        map['evaluationMetrics'] ??
        [];

    return TemplateModel(
      id: map['_id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      topics: List<String>.from(map['topics'] ?? []),
      evaluationMetrics: (metricsJson as List)
          .map(
            (e) => EvaluationMetric.fromMap(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
      domain: map['domain']?.toString() ?? '',
      icon: map['icon']?.toString() ?? '',
    );
  }

  @override
  String toString() {
    return 'TemplateModel(id: $id, title: $title, topics: $topics, evaluationMetrics: $evaluationMetrics, domain: $domain, icon: $icon)';
  }


  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        topics.hashCode ^
        evaluationMetrics.hashCode ^
        domain.hashCode ^
        icon.hashCode;
  }
}

class EvaluationMetric {
  final String topic;
  final String description;

  EvaluationMetric({
    required this.topic,
    required this.description,
  });

  factory EvaluationMetric.fromMap(Map<String, dynamic> map) {
    return EvaluationMetric(
      topic: map['topic']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
    );
  }

  @override
  String toString() =>
      'EvaluationMetric(topic: $topic, description: $description)';

  @override
  bool operator ==(covariant EvaluationMetric other) {
    if (identical(this, other)) return true;

    return other.topic == topic && other.description == description;
  }

  @override
  int get hashCode => topic.hashCode ^ description.hashCode;
}
