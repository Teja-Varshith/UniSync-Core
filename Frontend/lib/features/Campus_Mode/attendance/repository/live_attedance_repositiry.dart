import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:unisync/app/providers.dart';
import 'package:unisync/constants/constant.dart';
import 'package:unisync/models/course_model.dart';
import 'package:unisync/storage/secure_storage.dart';

final LiveAttdncRepositoryProvider = Provider((ref) {
  return LiveAttdncRepository(ref: ref);
});

class LiveAttdncRepository {
  final Ref _ref;

  LiveAttdncRepository({required Ref ref}) : _ref = ref;

  Future<List<CourseModel>> fetchAttendance([bool tryAgain = true]) async {

    print('called attendace');

    final token = _ref.read(userProvider)!.cookie;
    final tenent = await SecureStorageService().getXTenantId();
    final institutionCode = await SecureStorageService().getXInstitutionCode();


    try {
      final response = await http.get(
        Uri.parse(totoUrl),
        headers: {
          'accept': 'application/json',
          'user-agent': 'ANDROID',
          'x-tenant-id': tenent ?? '',
          'x-institution-code': institutionCode ?? '',
          'cookie': 'campx_session_key=$token',
        },
      );

      if (response.statusCode == 200) {
        print('okkkkkkkkkkkkkkkkkkkkkk');
        final List<dynamic> jsonData = json.decode(response.body);
        print(jsonData);
        final data = jsonData.map((item) {
          return CourseModel.fromMap(item as Map<String, dynamic>);
        }).toList();
        print(data);
        return data;
      } else {
        if(tryAgain){
          print('Token expired, trying to refresh...');
          // await _ref.read(authControllerProvider.notifier).refreshUser();
          return await fetchAttendance(false);
        } else {
          throw Exception('Failed to fetch attendance: ${response.statusCode}');
        }
      }
    } catch (e) {
      throw Exception('Failed to fetch attendance: ${e.toString()}');
    }
  }

 

}
