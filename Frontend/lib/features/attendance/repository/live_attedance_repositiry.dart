import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:UniSync/app/providers.dart';
import 'package:UniSync/constants/constant.dart';
import 'package:UniSync/features/attendance/repository/attendance_repository.dart';
import 'package:UniSync/models/course_model.dart';
import 'package:UniSync/storage/secure_storage.dart';

const _subjectsBaseUrl = 'https://api.campx.in/student-api/subjects';
const _subjectAttendanceBaseUrl =
    'https://api.campx.in/student-api/student-attendance/subject-attendance/';
const _studentProfileUrl =
    'https://api.campx.in/student-api/users/student-profile';

final LiveAttdncRepositoryProvider = Provider((ref) {
  return LiveAttdncRepository(ref: ref);
});

class LiveAttdncRepository {
  final Ref _ref;

  LiveAttdncRepository({required Ref ref}) : _ref = ref;

  // ── shared headers helper ───────────────────────────────────────────────
  Future<Map<String, String>?> _buildHeaders() async {
    final secureStorage = SecureStorageService();
    final token = await secureStorage.getCampXSessionToken();
    final tenant = await secureStorage.getXTenantId();
    final institutionCode = await secureStorage.getXInstitutionCode();

    if ((token ?? '').isEmpty ||
        (tenant ?? '').isEmpty ||
        (institutionCode ?? '').isEmpty) {
      return null;
    }

    return {
      'accept': 'application/json',
      'user-agent': 'BROWSER',
      'x-tenant-id': tenant ?? '',
      'x-institution-code': institutionCode ?? '',
      'cookie': 'campx_session_key=$token',
    };
  }

  // ── main entry point ────────────────────────────────────────────────────
  Future<List<CourseModel>> fetchAttendance([bool tryAgain = true]) async {
    final hasSession = await _ref
        .read(AttendanceRepositoryProvider)
        .ensureCampXSession(allowRelogin: tryAgain);

    if (!hasSession) {
      throw Exception('CampX is not connected. Please connect your account.');
    }

    final headers = await _buildHeaders();
    if (headers == null) {
      throw Exception('CampX session is missing. Please connect again.');
    }

    try {
      // ── Step 1: try primary attendance URL ──────────────────────────────
      final primaryResponse = await http.get(
        Uri.parse(totoUrl),
        headers: headers,
      );

      print('[CampX Attendance] statusCode: ${primaryResponse.statusCode}');
      print('[CampX Attendance] response body: ${primaryResponse.body}');

      if (primaryResponse.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(primaryResponse.body);

        if (jsonData.isNotEmpty) {
          return jsonData
              .map((item) => CourseModel.fromMap(item as Map<String, dynamic>))
              .toList();
        }

        // Primary returned [] — fall through to fallback
        print('[CampX Attendance] Primary returned empty, trying fallback...');
        return await _fetchAttendanceFallback(headers);
      } else if (tryAgain &&
          (primaryResponse.statusCode == 401 ||
              primaryResponse.statusCode == 403)) {
        await _ref
            .read(AttendanceRepositoryProvider)
            .reloginWithStoredCredentials();
        return await fetchAttendance(false);
      } else {
        throw Exception(
            'Failed to fetch attendance: ${primaryResponse.statusCode}');
      }
    } catch (e) {
      print('[CampX Attendance] error: $e');
      rethrow;
    }
  }

  // ── fallback: subjects list + per-subject attendance ────────────────────
  Future<List<CourseModel>> _fetchAttendanceFallback(
    Map<String, String> headers,
  ) async {
    final subjects = await _fetchSubjectsWithAttendance(headers);

    if (subjects.isEmpty) {
      print('[CampX Fallback] No subjects with attendance found');
      return [];
    }

    print(
        '[CampX Fallback] Found ${subjects.length} subjects, fetching per-subject attendance...');

    final results = await Future.wait(
      subjects.map((s) => _fetchSingleSubjectAttendance(
            headers: headers,
            subjectId: s['id'] as int,
            subjectName: s['name'] as String,
            refCode: s['refCode'] as String,
          )),
    );

    return results.whereType<CourseModel>().toList();
  }

  // ── fetch subjects — userProvider.semester first, profile API as fallback
  Future<List<Map<String, dynamic>>> _fetchSubjectsWithAttendance(
    Map<String, String> headers,
  ) async {
    // Always try userProvider.semester first — it should always have a value
    final userSemNo = _ref.read(userProvider)?.semester;

    if (userSemNo != null) {
      final subjects = await _fetchSubjectsForSemNo(headers, userSemNo);

      if (subjects.isNotEmpty) {
        return subjects;
      }

      // userProvider semNo gave empty/error — try profile API
      print(
          '[CampX Subjects] semNo=$userSemNo returned empty, trying profile API fallback...');
    }

    // Fallback: fetch semNo fresh from profile API
    final profileSemNo = await _fetchSemNoFromProfile(headers);

    if (profileSemNo == null) {
      print('[CampX Subjects] Could not determine semNo from profile API');
      return [];
    }

    // Avoid hitting the same semNo twice
    if (profileSemNo == userSemNo) {
      print(
          '[CampX Subjects] Profile semNo=$profileSemNo same as userProvider, giving up');
      return [];
    }

    return await _fetchSubjectsForSemNo(headers, profileSemNo);
  }

  // ── hit subjects API for a given semNo ──────────────────────────────────
  Future<List<Map<String, dynamic>>> _fetchSubjectsForSemNo(
    Map<String, String> headers,
    int semNo,
  ) async {
    try {
      final url = Uri.parse('$_subjectsBaseUrl?semNo=$semNo');
      final response = await http.get(url, headers: headers);

      print('[CampX Subjects] semNo=$semNo statusCode: ${response.statusCode}');

      if (response.statusCode != 200) return [];

      final List<dynamic> data = json.decode(response.body);

      final subjects = data
          .whereType<Map<String, dynamic>>()
          .where((s) => s['hasAttendance'] == true)
          .map((s) => {
                'id': s['id'] as int,
                'name': s['name'] as String,
                'refCode': s['refCode'] as String,
              })
          .toList();

      print(
          '[CampX Subjects] semNo=$semNo found ${subjects.length} subjects with attendance');

      return subjects;
    } catch (e) {
      print('[CampX Subjects] semNo=$semNo error: $e');
      return [];
    }
  }

  // ── fetch semNo from student profile API ─────────────────────────────────
  Future<int?> _fetchSemNoFromProfile(Map<String, String> headers) async {
    try {
      final response = await http.get(
        Uri.parse(_studentProfileUrl),
        headers: headers,
      );

      print('[CampX Profile] statusCode: ${response.statusCode}');

      if (response.statusCode != 200) return null;

      final Map<String, dynamic> data = json.decode(response.body);
      final semNo = data['student']?['semNo'];

      print('[CampX Profile] semNo from profile: $semNo');

      if (semNo == null) return null;
      return semNo is int ? semNo : int.tryParse(semNo.toString());
    } catch (e) {
      print('[CampX Profile] error: $e');
      return null;
    }
  }

  // ── fetch attendance for a single subject ────────────────────────────────
  Future<CourseModel?> _fetchSingleSubjectAttendance({
    required Map<String, String> headers,
    required int subjectId,
    required String subjectName,
    required String refCode,
  }) async {
    try {
      final url = Uri.parse('$_subjectAttendanceBaseUrl$subjectId');
      final response = await http.get(url, headers: headers);

      print(
          '[CampX SubjectAttendance] $subjectName statusCode: ${response.statusCode}');

      if (response.statusCode != 200) return null;

      final Map<String, dynamic> data = json.decode(response.body);

      final int totalClasses = (data['totalClasses'] ?? 0) as int;
      final int present = (data['present'] ?? 0) as int;
      final int absent = totalClasses - present;
      final double percentage =
          totalClasses > 0 ? (present / totalClasses) * 100 : 0.0;

      return CourseModel(
        subjectId: subjectId,
        subjectName: subjectName,
        refCode: refCode,
        numberOfClasses: totalClasses,
        present: present,
        absent: absent,
        percentage: percentage,
      );
    } catch (e) {
      print('[CampX SubjectAttendance] $subjectName error: $e');
      return null;
    }
  }
}