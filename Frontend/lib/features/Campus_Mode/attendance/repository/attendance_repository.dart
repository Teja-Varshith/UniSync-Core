import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:unisync/app/providers.dart';
import 'package:unisync/constants/constant.dart';
import 'package:unisync/models/user_model.dart';
import 'package:unisync/storage/secure_storage.dart';

final AttendanceRepositoryProvider = Provider((ref) {
  return AttendanceRepository(ref: ref);
});

class AttendanceRepository {
  final Ref _ref;

  AttendanceRepository({required Ref ref}): _ref = ref;


  Future<UserModel>  completeCampXLogin(String username , String password) async{
    final url = Uri.parse('https://api.campx.in/auth-server/auth-v2/login-mobile');

  final body = {
    "loginId": username,
  "password": password,
  "deviceType": "mobile",
  "clientName": "Unknown",
  "os": "Android",
  "osVersion": "15",
  "loginType": "USER"
  // "latitude": 0.00000,
  // "longitude": 0.0000
  };

  try {
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'user-agent': 'ANDROID',
        'x-tenant-id': '',
        'x-institution-code': '',
      },
      body: jsonEncode(body),
    );

    print(response.body);

    // if (response.statusCode != 201) throw Exception("Login failed");

    final jsonData = jsonDecode(response.body);

    final accessToken = jsonData['session']['token'];
    if (accessToken == null) throw Exception("Token missing");
    final institutionCode = jsonData['session']['institutionCode'];
    final tenantId = jsonData['session']['subDomain'];

    await SecureStorageService().setIds(tenantId, institutionCode);

    final updatedUser = _ref.read(userProvider);

final newUser = updatedUser!.copyWith(
  cookie: accessToken,
  institutionCode: institutionCode,
  campXPassword: password,
  campXUsername: username, 
  tenantId: tenantId,
);

_ref.read(userProvider.notifier).state = newUser;

    final _dio = Dio();

    final res = await _dio.post(
      "$BASE_URI/auth/updateTenantDetails",
      data: {
        "emailId" : updatedUser.emailId,
        "accessToken" : accessToken,
        "tenantId": tenantId,
        "password": password,
        "institutionCode": institutionCode
      }
    );

    return UserModel.fromMap(res.data["user"]);



    return updatedUser;
  } catch (e) {
    rethrow;
  }
  }
}