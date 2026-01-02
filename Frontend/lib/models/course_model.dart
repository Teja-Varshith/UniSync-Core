import 'dart:convert';
class CourseModel {
  final int subjectId;
  final String subjectName;
  final String refCode;
  final int numberOfClasses;
  final int present;
  final int absent;
  final double percentage;
  
  CourseModel({
    required this.subjectId,
    required this.subjectName,
    required this.refCode,
    required this.numberOfClasses,
    required this.present,
    required this.absent,
    required this.percentage,
  });


  CourseModel copyWith({
    int? subjectId,
    String? subjectName,
    String? refCode,
    int? numberOfClasses,
    int? present,
    int? absent,
    double? percentage,
  }) {
    return CourseModel(
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      refCode: refCode ?? this.refCode,
      numberOfClasses: numberOfClasses ?? this.numberOfClasses,
      present: present ?? this.present,
      absent: absent ?? this.absent,
      percentage: percentage ?? this.percentage,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'subjectId': subjectId,
      'subjectName': subjectName,
      'refCode': refCode,
      'numberOfClasses': numberOfClasses,
      'present': present,
      'absent': absent,
      'percentage': percentage,
    };
  }

  factory CourseModel.fromMap(Map<String, dynamic> map) {
    return CourseModel(
      subjectId: map['subjectId'] as int,
      subjectName: map['subjectName'] as String,
      refCode: map['refCode'] as String,
      numberOfClasses: map['numberOfClasses'] as int,
      present: map['present'] as int,
      absent: map['absent'] as int,
      percentage: (map['percentage'] ?? 0.0).toDouble(),
    );
  }

  String toJson() => json.encode(toMap());

  factory CourseModel.fromJson(String source) => CourseModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'CourseModel(subjectId: $subjectId, subjectName: $subjectName, refCode: $refCode, numberOfClasses: $numberOfClasses, present: $present, absent: $absent, percentage: $percentage)';
  }

  @override
  bool operator ==(covariant CourseModel other) {
    if (identical(this, other)) return true;
  
    return 
      other.subjectId == subjectId &&
      other.subjectName == subjectName &&
      other.refCode == refCode &&
      other.numberOfClasses == numberOfClasses &&
      other.present == present &&
      other.absent == absent &&
      other.percentage == percentage;
  }

  @override
  int get hashCode {
    return subjectId.hashCode ^
      subjectName.hashCode ^
      refCode.hashCode ^
      numberOfClasses.hashCode ^
      present.hashCode ^
      absent.hashCode ^
      percentage.hashCode;
  }
}
