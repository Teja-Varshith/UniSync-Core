import 'dart:convert';
import 'package:collection/collection.dart';

class PeerModel {
  final String? userId;
  final String name;
  final String? collegeName;
  final String? profileLink;
  final List<String> skills;
  final String? gitHubLink;
  final String linkedinLink;
  final List<String> traits;
  final List<String> likedBy;
  final String bio;
  final bool isPublic;
  final String? cardStyle; 
  final DateTime lastActive;

  PeerModel({
    this.userId,
    this.likedBy = const [],
    required this.name,
    this.collegeName,
    this.profileLink,
    required this.skills,
    this.gitHubLink,
    required this.linkedinLink,
    this.cardStyle,
    this.traits = const [],
    required this.bio,
    required this.isPublic,
    required this.lastActive,
  });

  factory PeerModel.fromJson(Map<String, dynamic> json) {
    return PeerModel(
      userId: json['userId'],
      name: json['name'],
      collegeName: json['collegeName'] as String?,
      likedBy: List<String>.from(json['likedBy'] ?? []),
      cardStyle: json['cardStyle'] as String? ?? 'minimal',
      profileLink: json['profileLink'],
      skills: List<String>.from(json['skills']),
      gitHubLink: json['gitHubLink'],
      linkedinLink: json['linkedinLink'],
      traits: List<String>.from(json['traits'] ?? []),
      bio: json['bio'],
      isPublic: json['isPublic'],
      lastActive: DateTime.parse(json['lastActive']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'collegeName': collegeName,
      'cardStyle': cardStyle,
      'likedBy': likedBy,
      'skills': skills,
      'profileLink': profileLink,
      'gitHubLink': gitHubLink,
      'linkedinLink': linkedinLink,
      'traits': traits,
      'bio': bio,
      'isPublic': isPublic,
      'lastActive': lastActive.toIso8601String(),
    };
  }

  PeerModel copyWith({
    required String userId,
    String? name,
    String? collegeName,
    String? profileLink,
    List<String>? skills,
    String? gitHubLink,
    String? linkedinLink,
    String? cardStyle,
    List<String>? traits,
    String? bio,
    bool? isPublic,
    DateTime? lastActive,
    List<String>? likedBy,
  }) {
    return PeerModel(
      userId: userId,
      name: name ?? this.name,
      collegeName: collegeName ?? this.collegeName,
      likedBy: likedBy ?? this.likedBy,
      profileLink: profileLink ?? this.profileLink,
      skills: skills ?? this.skills,
      cardStyle: cardStyle ?? this.cardStyle,
      gitHubLink: gitHubLink ?? this.gitHubLink,
      linkedinLink: linkedinLink ?? this.linkedinLink,
      traits: traits ?? this.traits,
      bio: bio ?? this.bio,
      isPublic: isPublic ?? this.isPublic,
      lastActive: lastActive ?? this.lastActive,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'userId': userId,
      'name': name,
      'collegeName': collegeName,
      'skills': skills,
      'profileLink': profileLink,
      'cardStyle': cardStyle,
      'gitHubLink': gitHubLink,
      'linkedinLink': linkedinLink,
      'traits': traits,
      'bio': bio,
      'isPublic': isPublic,
      'lastActive': lastActive.millisecondsSinceEpoch,
    };
  }

  @override
  String toString() {
    return 'PeerModel(userId: $userId, name: $name, collegeName: $collegeName, skills: $skills, cardStyle: $cardStyle, gitHubLink: $gitHubLink, linkedinLink: $linkedinLink, traits: $traits, bio: $bio, isPublic: $isPublic, lastActive: $lastActive)';
  }
}
