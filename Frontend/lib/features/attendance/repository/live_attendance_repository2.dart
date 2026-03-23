import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:UniSync/constants/constant.dart';
import 'package:UniSync/features/attendance/repository/attendance_repository.dart';
import 'package:UniSync/storage/secure_storage.dart';

final LiveAttdncRepositoryProvider2 = Provider((ref) {
  return LiveAttdncRepository2(ref: ref);
});


class LiveAttdncRepository2 {
  final Ref _ref;
  final SecureStorageService _secureStorage = SecureStorageService();

  LiveAttdncRepository2({required Ref ref}) : _ref = ref;


  Future<Map<String, dynamic>?> fetchSubjectAttendance({
  required int subjectId,
  bool tryAgain = true,
}) async {
    final hasSession = await _ref
        .read(AttendanceRepositoryProvider)
        .ensureCampXSession(allowRelogin: tryAgain);

    if (!hasSession) {
      throw Exception('CampX is not connected. Please connect your account.');
    }

    final cookie = (await _secureStorage.getCampXSessionToken()) ?? '';
    final tenantId = (await _secureStorage.getXTenantId()) ?? '';
    final institutionCode = (await _secureStorage.getXInstitutionCode()) ?? '';

    if (cookie.isEmpty || tenantId.isEmpty || institutionCode.isEmpty) {
      throw Exception('CampX session is missing. Please connect again.');
    }

  try {
      final client = HttpClient();

    client.connectionTimeout = const Duration(seconds: 30);
    
    final request = await client.getUrl(
      Uri.parse('$totoourl$subjectId')
    );
    
    // Add headers
    request.headers.add('content-type', 'application/json');
    request.headers.add('user-agent', 'ANDROID');
    request.headers.add('x-tenant-id', tenantId);
    request.headers.add('x-institution-code', institutionCode);
    request.headers.add('Cookie', 'campx_session_key=$cookie; Domain=.campx.in; Path=/;');

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    client.close();

    print('[CampX Subject Attendance] statusCode: ${response.statusCode}');
    print('[CampX Subject Attendance] response body: $responseBody');

    if (response.statusCode == 200) {
      return json.decode(responseBody);
    } else {
      if (tryAgain && (response.statusCode == 401 || response.statusCode == 403)) {
        await _ref.read(AttendanceRepositoryProvider).reloginWithStoredCredentials();
        return fetchSubjectAttendance(subjectId: subjectId, tryAgain: false);
      }
      throw Exception('Failed to fetch subject attendance: ${response.statusCode}');
    }
  } catch (e) {
    print('[CampX Subject Attendance] error: $e');
    rethrow;
  }
}

}
