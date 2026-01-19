import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:unisync/app/providers.dart';
import 'package:unisync/constants/constant.dart';

final LiveAttdncRepositoryProvider2 = Provider((ref) {
  return LiveAttdncRepository2(ref: ref);
});


class LiveAttdncRepository2 {
  final Ref _ref;

  LiveAttdncRepository2({required Ref ref}) : _ref = ref;


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
      Uri.parse(totoourl + '/${subjectId}')
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
