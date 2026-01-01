import 'dart:convert';

import 'package:collection/collection.dart';

// ignore_for_file: public_member_api_docs, sort_constructors_first
class DomainModel {
  final String id;
  final String domain;
  final List<SubDomains> subDomain;
  DomainModel({
    required this.id,
    required this.domain,
    required this.subDomain,
  });

  DomainModel copyWith({
    String? domain,
    List<SubDomains>? subDomain,
  }) {
    return DomainModel(
      id: id,
      domain: domain ?? this.domain,
      subDomain: subDomain ?? this.subDomain,
    );
  }


 factory DomainModel.fromMap(Map<String, dynamic> map) {
  final rawSubDomains = map['subDomains'];

  return DomainModel(
    id: map['_id'] as String,
    domain: map['domain'] as String,
    subDomain: rawSubDomains == null
        ? []
        : (rawSubDomains as List)
            .map((e) => SubDomains.fromMap(e as Map<String, dynamic>))
            .toList(),
  );
}


  factory DomainModel.fromJson(String source) => DomainModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'DomainModel(domain: $domain, subDomain: $subDomain)';
}

class SubDomains {
  final String label;
  final String logo;
  SubDomains({
    required this.label,
    required this.logo,
  });

  SubDomains copyWith({
    String? label,
    String? logo,
  }) {
    return SubDomains(
      label: label ?? this.label,
      logo: logo ?? this.logo,
    );
  }


  factory SubDomains.fromMap(Map<String, dynamic> map) {
    return SubDomains(
      label: map['label'] as String,
      logo: map['logo'] as String,
    );
  }
}
