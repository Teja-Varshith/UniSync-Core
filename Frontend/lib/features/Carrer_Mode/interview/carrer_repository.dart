import 'package:dio/dio.dart';
import 'package:unisync/constants/constant.dart';
import 'package:unisync/models/template_model.dart';
class CarrerRepository {
  Future<List<TemplateModel>> getTemplates() async {
    try {
      final dio = Dio();

      final res = await dio.get(
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
}
