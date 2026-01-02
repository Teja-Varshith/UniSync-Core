// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class UserModel {
  final String? id;
  final String name;
  final bool profileComplete;
  final String? photoUrl;
  final String emailId;
  final String? collegeName;
  final String? tenantId;
  final String? cookie;
  final String? institutionCode;
  final String? campXPassword;
  final String? campXUsername;
  final int? year;
  final int? semester;
  final String? about;

  UserModel({
    this.institutionCode,
    this.cookie,
    this.id,
    required this.name,
    required this.profileComplete,
    this.photoUrl,
    required this.emailId,
    this.collegeName,
    this.tenantId,
    this.campXPassword,
    this.campXUsername,
    this.year,
    this.semester,
    this.about,
  });

  UserModel copyWith({
    String? institutionCode,
    String? cookie,
    String? id,
    String? name,
    bool? profileComplete,
    String? photoUrl,
    String? emailId,
    String? collegeName,
    String? tenantId,
    String? campXPassword,
    String? campXUsername,
    int? year,
    int? semester,
    String? about,
  }) {
    return UserModel(
      institutionCode: institutionCode ?? this.institutionCode,
      cookie: cookie ?? this.cookie,
      id: id ?? this.id,
      name: name ?? this.name,
      profileComplete: profileComplete ?? this.profileComplete,
      photoUrl: photoUrl ?? this.photoUrl,
      emailId: emailId ?? this.emailId,
      collegeName: collegeName ?? this.collegeName,
      tenantId: tenantId ?? this.tenantId,
      campXPassword: campXPassword ?? this.campXPassword,
      campXUsername: campXUsername ?? this.campXUsername,
      year: year ?? this.year,
      semester: semester ?? this.semester,
      about: about ?? this.about,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'institutionCode': institutionCode,
      'cookie' : cookie,
      'id': id,
      'name': name,
      'profileComplete': profileComplete,
      'photoUrl': photoUrl,
      'emailId': emailId,
      'collegeName': collegeName,
      'tenantId': tenantId,
      'campXPassword': campXPassword,
      'campXUsername': campXUsername,
      'year': year,
      'semester': semester,
      'about': about,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
  return UserModel(
    id: map['_id'] as String?,
    name: map['name'] ?? '',
    profileComplete: map['profileComplete'] ?? false,
    photoUrl: map['photoUrl'] as String?,
    emailId: map['emailId'] ?? '',
    collegeName: map['collegeName'] as String?,
    tenantId: map['tenantId'] as String?,
    institutionCode: map['institutionCode'] as String?,
    cookie: map['accessToken'] as String?,
    campXPassword: map['password'] as String?,
    campXUsername: map['campXUsername'] as String?,
    year: map['year'] as int?,
    semester: map['semester'] as int?,
    about: map['about'] as String?,
  );
}


  String toJson() => json.encode(toMap());

  factory UserModel.fromJson(String source) => UserModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name,  cookie: $cookie profileComplete: $profileComplete, photoUrl: $photoUrl, emailId: $emailId, collegeName: $collegeName, tenantId: $tenantId, campXPassword: $campXPassword, campXUsername: $campXUsername, year: $year, semester: $semester, about: $about, institutionCode: $institutionCode)';
  }

}
