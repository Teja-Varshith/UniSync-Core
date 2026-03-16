import 'package:dio/dio.dart';
import 'package:unisync/constants/constant.dart';
import 'package:unisync/models/template_model.dart';
class CarrerRepository {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
    ),
  );

  Future<List<TemplateModel>> getTemplates() async {
    try {
      final res = await _dio.get(
        '$BASE_URI/carrer/get-templates',
      );

      if (res.statusCode != 200) {
        throw Exception('Failed to fetch templates');
      }

      final responseMap = res.data as Map<String, dynamic>;

      final List templatesJson = responseMap['data'];

      return templatesJson
          .map((json) => TemplateModel.fromMap(json))
          .toList();
    } on DioException catch (e) {
      final message =
          e.response?.data?['message'] ?? 'Network error';
      throw Exception(message);
    } catch (e) {
      throw Exception('Parsing error: $e');
    }
  }

  Future<TemplateModel> updateTemplate({
    required String templateId,
    required String title,
    required String domain,
    required String icon,
    required List<String> topics,
    required int coinPrice,
  }) async {
    try {
      final res = await _dio.patch(
        '$BASE_URI/carrer/template/$templateId',
        data: {
          'title': title,
          'domain': domain,
          'icon': icon,
          'topics': topics,
          'coinPrice': coinPrice,
        },
      );

      if (res.statusCode != 200) {
        throw Exception('Failed to update template');
      }

      final responseMap = res.data as Map<String, dynamic>;
      final data = responseMap['data'] as Map<String, dynamic>;
      return TemplateModel.fromMap(data);
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? 'Network error';
      throw Exception(message);
    } catch (e) {
      throw Exception('Template update error: $e');
    }
  }

  Future<TemplateModel> createTemplate({
    required String title,
    required String domain,
    required String icon,
    required List<String> topics,
    required int coinPrice,
  }) async {
    try {
      final res = await _dio.post(
        '$BASE_URI/carrer/template',
        data: {
          'title': title,
          'domain': domain,
          'icon': icon,
          'topics': topics,
          'coinPrice': coinPrice,
          'evaluationMetrics': const [],
        },
      );

      if (res.statusCode != 201) {
        throw Exception('Failed to create template');
      }

      final responseMap = res.data as Map<String, dynamic>;
      final data = responseMap['data'] as Map<String, dynamic>;
      return TemplateModel.fromMap(data);
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? 'Network error';
      throw Exception(message);
    } catch (e) {
      throw Exception('Template create error: $e');
    }
  }

  Future<void> deleteTemplate(String templateId) async {
    try {
      final res = await _dio.delete('$BASE_URI/carrer/template/$templateId');

      if (res.statusCode != 200) {
        throw Exception('Failed to delete template');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? 'Network error';
      throw Exception(message);
    } catch (e) {
      throw Exception('Template delete error: $e');
    }
  }

  Future<void> createDomain(String domain) async {
    try {
      final res = await _dio.post(
        '$BASE_URI/domain/createDomains',
        data: {'domain': domain},
      );

      if (res.statusCode != 200) {
        throw Exception('Failed to create domain');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? 'Network error';
      throw Exception(message);
    } catch (e) {
      throw Exception('Domain create error: $e');
    }
  }

  Future<void> deleteDomain(String domain) async {
    try {
      final encodedDomain = Uri.encodeComponent(domain);
      final res = await _dio.delete('$BASE_URI/domain/$encodedDomain');

      if (res.statusCode != 200) {
        throw Exception('Failed to delete domain');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? 'Network error';
      throw Exception(message);
    } catch (e) {
      throw Exception('Domain delete error: $e');
    }
  }

   Future<List<TemplateModel>> getTemplatesByUserId(String userId) async {
    try {
      final res = await _dio.get(
        '$BASE_URI/carrer/getAllUserTemplate/user/$userId',
      );

      if (res.statusCode != 200) {
        throw Exception('Failed to fetch templates');
      }

      final responseMap = res.data as Map<String, dynamic>;

      final List templatesJson = responseMap['data'];

      return templatesJson
          .map((json) => TemplateModel.fromMap(json))
          .toList();
    } on DioException catch (e) {
      final message =
          e.response?.data?['message'] ?? 'Network error $e';
      throw Exception(message);
    } catch (e) {
      throw Exception('Parsing error: $e');
    }
  }
}
