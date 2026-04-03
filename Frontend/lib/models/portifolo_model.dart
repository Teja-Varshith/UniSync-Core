import 'dart:convert';

// ── Sub-models ────────────────────────────────────────────────────────────────

class ProjectItem {
  final String name;
  final String description;
  final List<String> tags;

  const ProjectItem({
    required this.name,
    required this.description,
    this.tags = const [],
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'tags': tags,
      };

  factory ProjectItem.fromMap(Map<String, dynamic> map) => ProjectItem(
        name: map['name'] ?? '',
        description: map['description'] ?? '',
        tags: List<String>.from(map['tags'] ?? []),
      );

  ProjectItem copyWith({
    String? name,
    String? description,
    List<String>? tags,
  }) =>
      ProjectItem(
        name: name ?? this.name,
        description: description ?? this.description,
        tags: tags ?? this.tags,
      );
}

class SkillItem {
  final String name;
  final bool isHighlighted;

  const SkillItem({
    required this.name,
    this.isHighlighted = false,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'isHighlighted': isHighlighted,
      };

  factory SkillItem.fromMap(Map<String, dynamic> map) => SkillItem(
        name: map['name'] ?? '',
        isHighlighted: map['isHighlighted'] ?? false,
      );

  SkillItem copyWith({String? name, bool? isHighlighted}) => SkillItem(
        name: name ?? this.name,
        isHighlighted: isHighlighted ?? this.isHighlighted,
      );
}

class ExperienceItem {
  final String role;
  final String org;
  final String date;
  final bool isActive;

  const ExperienceItem({
    required this.role,
    required this.org,
    this.date = '',
    this.isActive = false,
  });

  Map<String, dynamic> toMap() => {
        'role': role,
        'org': org,
        'date': date,
        'isActive': isActive,
      };

  factory ExperienceItem.fromMap(Map<String, dynamic> map) => ExperienceItem(
        role: map['role'] ?? '',
        org: map['org'] ?? '',
        date: map['date'] ?? '',
        isActive: map['isActive'] ?? false,
      );

  ExperienceItem copyWith({
    String? role,
    String? org,
    String? date,
    bool? isActive,
  }) =>
      ExperienceItem(
        role: role ?? this.role,
        org: org ?? this.org,
        date: date ?? this.date,
        isActive: isActive ?? this.isActive,
      );
}

class AchievementItem {
  final String title;
  final String description;
  final String date;

  const AchievementItem({
    required this.title,
    this.description = '',
    this.date = '',
  });

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'date': date,
      };

  factory AchievementItem.fromMap(Map<String, dynamic> map) => AchievementItem(
        title: map['title'] ?? '',
        description: map['description'] ?? '',
        date: map['date'] ?? '',
      );

  AchievementItem copyWith({
    String? title,
    String? description,
    String? date,
  }) =>
      AchievementItem(
        title: title ?? this.title,
        description: description ?? this.description,
        date: date ?? this.date,
      );
}

class CertificationItem {
  final String name;
  final String issuer;
  final String date;
  final String? credentialUrl;

  const CertificationItem({
    required this.name,
    required this.issuer,
    this.date = '',
    this.credentialUrl,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'issuer': issuer,
        'date': date,
        'credentialUrl': credentialUrl,
      };

  factory CertificationItem.fromMap(Map<String, dynamic> map) =>
      CertificationItem(
        name: map['name'] ?? '',
        issuer: map['issuer'] ?? '',
        date: map['date'] ?? '',
        credentialUrl: map['credentialUrl'] as String?,
      );

  CertificationItem copyWith({
    String? name,
    String? issuer,
    String? date,
    String? credentialUrl,
  }) =>
      CertificationItem(
        name: name ?? this.name,
        issuer: issuer ?? this.issuer,
        date: date ?? this.date,
        credentialUrl: credentialUrl ?? this.credentialUrl,
      );
}

// ── Main portfolio model ──────────────────────────────────────────────────────

class PortifoloModel {
  final String? userId;
  final String name;
  final String role;
  final String tagline;
  final String email;
  final String phone;
  final String about;
  final List<ProjectItem> projects;
  final List<SkillItem> skills;
  final List<ExperienceItem> experience;
  final List<AchievementItem> achievements;
  final List<CertificationItem> certifications;
  final String resumeText;
  final String slug;
  final String portfolioUrl;

  const PortifoloModel({
    this.userId,
    this.name = '',
    this.role = '',
    this.tagline = '',
    this.email = '',
    this.phone = '',
    this.about = '',
    this.projects = const [],
    this.skills = const [],
    this.experience = const [],
    this.achievements = const [],
    this.certifications = const [],
    this.resumeText = '',
    this.slug = '',
    this.portfolioUrl = '',
  });

  /// Auto-computed completion percentage based on how many sections are filled.
  /// Sections: role, tagline, phone, about, projects, skills, experience,
  ///           achievements, certifications  (9 sections total).
  int get completionPct {
    int filled = 0;
    const total = 9;
    if (role.isNotEmpty) filled++;
    if (tagline.isNotEmpty) filled++;
    if (phone.isNotEmpty) filled++;
    if (about.isNotEmpty) filled++;
    if (projects.isNotEmpty) filled++;
    if (skills.isNotEmpty) filled++;
    if (experience.isNotEmpty) filled++;
    if (achievements.isNotEmpty) filled++;
    if (certifications.isNotEmpty) filled++;
    return ((filled / total) * 100).round();
  }

  // ── Serialisation ─────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'name': name,
        'role': role,
        'tagline': tagline,
        'email': email,
        'phone': phone,
        'about': about,
        'projects': projects.map((p) => p.toMap()).toList(),
        'skills': skills.map((s) => s.toMap()).toList(),
        'experience': experience.map((e) => e.toMap()).toList(),
        'achievements': achievements.map((a) => a.toMap()).toList(),
        'certifications': certifications.map((c) => c.toMap()).toList(),
        'resumeText': resumeText,
        'slug': slug,
        'portfolioUrl': portfolioUrl,
      };

  factory PortifoloModel.fromMap(Map<String, dynamic> map) => PortifoloModel(
        userId: map['userId'] as String?,
        name: map['name'] ?? '',
        role: map['role'] ?? '',
        tagline: map['tagline'] ?? '',
        email: map['email'] ?? '',
        phone: map['phone'] ?? '',
        about: map['about'] ?? '',
        projects: (map['projects'] as List<dynamic>?)
                ?.map((p) => ProjectItem.fromMap(p as Map<String, dynamic>))
                .toList() ??
            [],
        skills: (map['skills'] as List<dynamic>?)
                ?.map((s) => SkillItem.fromMap(s as Map<String, dynamic>))
                .toList() ??
            [],
        experience: (map['experience'] as List<dynamic>?)
                ?.map(
                    (e) => ExperienceItem.fromMap(e as Map<String, dynamic>))
                .toList() ??
            [],
        achievements: (map['achievements'] as List<dynamic>?)
                ?.map(
                    (a) => AchievementItem.fromMap(a as Map<String, dynamic>))
                .toList() ??
            [],
        certifications: (map['certifications'] as List<dynamic>?)
                ?.map((c) =>
                    CertificationItem.fromMap(c as Map<String, dynamic>))
                .toList() ??
            [],
        resumeText: map['resumeText'] ?? '',
        slug: map['slug'] ?? '',
        portfolioUrl: map['portfolioUrl'] ?? '',
      );

  String toJson() => json.encode(toMap());

  factory PortifoloModel.fromJson(String source) =>
      PortifoloModel.fromMap(json.decode(source) as Map<String, dynamic>);

  // ── copyWith ──────────────────────────────────────────────────────────────

  PortifoloModel copyWith({
    String? userId,
    String? name,
    String? role,
    String? tagline,
    String? email,
    String? phone,
    String? about,
    List<ProjectItem>? projects,
    List<SkillItem>? skills,
    List<ExperienceItem>? experience,
    List<AchievementItem>? achievements,
    List<CertificationItem>? certifications,
    String? resumeText,
    String? slug,
    String? portfolioUrl,
  }) =>
      PortifoloModel(
        userId: userId ?? this.userId,
        name: name ?? this.name,
        role: role ?? this.role,
        tagline: tagline ?? this.tagline,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        about: about ?? this.about,
        projects: projects ?? this.projects,
        skills: skills ?? this.skills,
        experience: experience ?? this.experience,
        achievements: achievements ?? this.achievements,
        certifications: certifications ?? this.certifications,
        resumeText: resumeText ?? this.resumeText,
        slug: slug ?? this.slug,
        portfolioUrl: portfolioUrl ?? this.portfolioUrl,
      );

  @override
  String toString() =>
      'PortifoloModel(userId: $userId, name: $name, role: $role, completion: $completionPct%)';
}