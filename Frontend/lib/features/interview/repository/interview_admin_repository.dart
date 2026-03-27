import 'package:dio/dio.dart';
import 'package:UniSync/constants/constant.dart';

class InterviewAdminRepository {
  InterviewAdminRepository({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 20),
                receiveTimeout: const Duration(seconds: 20),
                sendTimeout: const Duration(seconds: 20),
              ),
            );

  final Dio _dio;

  Future<List<Map<String, dynamic>>> getTemplatesRaw() async {
    final res = await _dio.get('$BASE_URI/carrer/get-templates');
    final map = _asMap(res.data);
    final data = map['data'];
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<Map<String, dynamic>> createTemplate(
    Map<String, dynamic> payload,
  ) async {
    final res = await _dio.post(
      '$BASE_URI/carrer/template',
      data: payload,
    );
    return _asMap(res.data);
  }

  Future<Map<String, dynamic>> updateTemplate(
    String templateId,
    Map<String, dynamic> payload,
  ) async {
    final res = await _dio.patch(
      '$BASE_URI/carrer/template/$templateId',
      data: payload,
    );
    return _asMap(res.data);
  }

  Future<Map<String, dynamic>> createDomain(String domain) async {
    final res = await _dio.post(
      '$BASE_URI/domain/createDomains',
      data: {'domain': domain},
    );
    return _asMap(res.data);
  }

  Future<Map<String, dynamic>> addSubDomains(
    String domain,
    List<Map<String, dynamic>> subDomains,
  ) async {
    final encoded = Uri.encodeComponent(domain);
    final res = await _dio.post(
      '$BASE_URI/domain/$encoded/subdomains',
      data: {'subDomains': subDomains},
    );
    return _asMap(res.data);
  }

  Future<List<Map<String, dynamic>>> getInterviewSessions({
    required String userId,
    required String templateId,
  }) async {
    final res = await _dio.get(
      '$BASE_URI/carrer/getAllReports',
      data: {
        'userId': userId,
        'templateId': templateId,
      },
    );
    final map = _asMap(res.data);
    final data = map['data'];
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }
}
