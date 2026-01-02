import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:unisync/app/providers.dart';

final LiveAttdncRepositoryProvider2 = Provider((ref) {
  return LiveAttdncRepository2(ref: ref);
});


class LiveAttdncRepository2 {
  final Ref _ref;

  LiveAttdncRepository2({required Ref ref}) : _ref = ref;

//   Future<String> getAttendance() async {
//     final cookie = _ref.read(userProvider)?.token??'';
//       final client = HttpClient();


//   try {
//     final request = await client.getUrl(
//       Uri.parse('https://api.campx.in/student-api/student-attendance?fromDate=&toDate=')
//     );

//     request.headers.set('accept', 'application/json');
//     request.headers.set('user-agent', 'ANDROID');
//     request.headers.set('x-tenant-id', 'gmrit');
//     request.headers.set('x-institution-code', 'gmrit'); 
//     request.headers.set('cookie', cookie);

//     final response = await request.close();
//     final responseBody = await response.transform(utf8.decoder).join();
//     print(responseBody);

//     return responseBody;
//   } catch (e) {
//     throw Exception("Failed to fetch attendance: $e");
//   } finally {
//     client.close();
//   }
// }

  Future<Map<String, dynamic>?> fetchSubjectAttendance({
  required int subjectId,
}) async {
      final cookie = _ref.read(userProvider)?.cookie??'';
      final tenantId = _ref.read(userProvider)?.tenantId??'';
      final institutionCode = _ref.read(userProvider)?.institutionCode??'';

  try {
      final client = HttpClient();

    client.connectionTimeout = const Duration(seconds: 30);
    
    final request = await client.getUrl(
      Uri.parse('https://api.campx.in/student-api/student-attendance/subject-attendance/$subjectId')
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

    if (response.statusCode == 200) {
      print(responseBody);
      return json.decode(responseBody);
    } else {
      print('API Error: ${response.statusCode}');
      return null;
    }
  } catch (e) {
    print('Error: $e');
    return null;
  }
}

}
