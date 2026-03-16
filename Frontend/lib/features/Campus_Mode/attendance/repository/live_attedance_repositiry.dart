import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:unisync/constants/constant.dart';
import 'package:unisync/features/Campus_Mode/attendance/repository/attendance_repository.dart';
import 'package:unisync/models/course_model.dart';
import 'package:unisync/storage/secure_storage.dart';

final LiveAttdncRepositoryProvider = Provider((ref) {
  return LiveAttdncRepository(ref: ref);
});

class LiveAttdncRepository {
  final Ref _ref;

  LiveAttdncRepository({required Ref ref}) : _ref = ref;

  Future<List<CourseModel>> fetchAttendance([bool tryAgain = true]) async {
    final hasSession = await _ref
        .read(AttendanceRepositoryProvider)
        .ensureCampXSession(allowRelogin: tryAgain);

    if (!hasSession) {
      throw Exception('CampX is not connected. Please connect your account.');
    }

    final secureStorage = SecureStorageService();
    final token = await secureStorage.getCampXSessionToken();
    final tenant = await secureStorage.getXTenantId();
    final institutionCode = await secureStorage.getXInstitutionCode();

    if ((token ?? '').isEmpty ||
        (tenant ?? '').isEmpty ||
        (institutionCode ?? '').isEmpty) {
      throw Exception('CampX session is missing. Please connect again.');
    }


    try {
      final response = await http.get(
        Uri.parse(totoUrl),
        headers: {
          'accept': 'application/json',
          'user-agent': 'ANDROID',
          'x-tenant-id': tenant ?? '',
          'x-institution-code': institutionCode ?? '',
          'cookie': 'campx_session_key=$token',
        },
      );

      print('[CampX Attendance] statusCode: ${response.statusCode}');
      print('[CampX Attendance] response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        final data = jsonData.map((item) {
          return CourseModel.fromMap(item as Map<String, dynamic>);
        }).toList();
        return data;
      } else {
        if (tryAgain && (response.statusCode == 401 || response.statusCode == 403)) {
          await _ref.read(AttendanceRepositoryProvider).reloginWithStoredCredentials();
          return await fetchAttendance(false);
        } else {
          throw Exception('Failed to fetch attendance: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('[CampX Attendance] error: $e');
      throw Exception('Failed to fetch attendance: ${e.toString()}');
    }
  }

 

}
