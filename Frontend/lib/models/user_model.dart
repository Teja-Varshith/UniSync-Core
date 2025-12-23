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
  final String? campXPassword;
  final String? campXUsername;
  final int? year;
  final int? semester;
  final String? about;

  UserModel({
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
      id: map['_id'] != null ? map['_id'] as String : null,
      name: map['name'] as String,
      profileComplete: map['profileComplete'] as bool,
      photoUrl: map['photoUrl'] != null ? map['photoUrl'] as String : null,
      emailId: map['emailId'] as String,
      collegeName: map['collegeName'] != null ? map['collegeName'] as String : null,
      tenantId: map['tenantId'] != null ? map['tenantId'] as String : null,
      campXPassword: map['campXPassword'] != null ? map['campXPassword'] as String : null,
      campXUsername: map['campXUsername'] != null ? map['campXUsername'] as String : null,
      year: map['year'] != null ? map['year'] as int : null,
      semester: map['semester'] != null ? map['semester'] as int : null,
      about: map['about'] != null ? map['about'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserModel.fromJson(String source) => UserModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, profileComplete: $profileComplete, photoUrl: $photoUrl, emailId: $emailId, collegeName: $collegeName, tenantId: $tenantId, campXPassword: $campXPassword, campXUsername: $campXUsername, year: $year, semester: $semester, about: $about)';
  }

  @override
  bool operator ==(covariant UserModel other) {
    if (identical(this, other)) return true;
  
    return 
      other.id == id &&
      other.name == name &&
      other.profileComplete == profileComplete &&
      other.photoUrl == photoUrl &&
      other.emailId == emailId &&
      other.collegeName == collegeName &&
      other.tenantId == tenantId &&
      other.campXPassword == campXPassword &&
      other.campXUsername == campXUsername &&
      other.year == year &&
      other.semester == semester &&
      other.about == about;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      name.hashCode ^
      profileComplete.hashCode ^
      photoUrl.hashCode ^
      emailId.hashCode ^
      collegeName.hashCode ^
      tenantId.hashCode ^
      campXPassword.hashCode ^
      campXUsername.hashCode ^
      year.hashCode ^
      semester.hashCode ^
      about.hashCode;
  }
}
