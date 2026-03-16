import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  final SecureStorageService _secureStorage = SecureStorageService();

  AttendanceRepository({required Ref ref}): _ref = ref;

  Future<void> _syncCampXToFirebase(UserModel user) async {
    if (user.id == null || user.id!.isEmpty) return;
    final firestore = _ref.read(firebaseFirestoreProvider) as FirebaseFirestore;
    await firestore.collection('users').doc(user.id).set({
      'cookie': user.cookie,
      'tenantId': user.tenantId,
      'institutionCode': user.institutionCode,
      'campXUsername': user.campXUsername,
      'campXPassword': user.campXPassword,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<UserModel> _persistCampXSession({
    required String username,
    required String password,
    required String accessToken,
    required String institutionCode,
    required String tenantId,
  }) async {
    await _secureStorage.persistCampXSession(
      token: accessToken,
      tenantId: tenantId,
      institutionCode: institutionCode,
      username: username,
      password: password,
    );

    final currentUser = _ref.read(userProvider);
    if (currentUser == null) {
      throw Exception('User not found. Please sign in again.');
    }

    final newUser = currentUser.copyWith(
      cookie: accessToken,
      institutionCode: institutionCode,
      campXPassword: password,
      campXUsername: username,
      tenantId: tenantId,
    );

    _ref.read(userProvider.notifier).state = newUser;
    await _syncCampXToFirebase(newUser);

    try {
      final dioClient = Dio();
      await dioClient.post(
        '$BASE_URI/auth/updateTenantDetails',
        data: {
          'emailId': newUser.emailId,
          'accessToken': accessToken,
          'tenantId': tenantId,
          'password': password,
          'institutionCode': institutionCode,
        },
      );
    } catch (_) {
      // Fire-and-forget backend sync should not block attendance flow.
    }

    return newUser;
  }

  Future<UserModel>  completeCampXLogin(String username , String password) async{
    final url = Uri.parse(anyUrl);
    final normalizedUsername = username.trim().toUpperCase();

    final body = {
      'loginId': normalizedUsername,
      'password': password,
      'deviceType': 'mobile',
      'clientName': 'Unknown',
      'os': 'Android',
      'osVersion': '15',
      'loginType': 'USER'
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

      print('[CampX Login] statusCode: ${response.statusCode}');
      print('[CampX Login] response body: ${response.body}');

      final jsonData = jsonDecode(response.body);

      final accessToken = jsonData['session']['token'];
      if (accessToken == null) throw Exception('Token missing');
      final institutionCode = jsonData['session']['institutionCode'];
      final tenantId = jsonData['session']['subDomain'];

      return _persistCampXSession(
        username: normalizedUsername,
        password: password,
        accessToken: accessToken.toString(),
        institutionCode: institutionCode.toString(),
        tenantId: tenantId.toString(),
      );
    } catch (e) {
      print('[CampX Login] error: $e');
      rethrow;
    }
  }

  Future<bool> hasSavedCampXSession() async {
    final token = await _secureStorage.getCampXSessionToken();
    final tenantId = await _secureStorage.getXTenantId();
    final institutionCode = await _secureStorage.getXInstitutionCode();
    return (token ?? '').isNotEmpty &&
        (tenantId ?? '').isNotEmpty &&
        (institutionCode ?? '').isNotEmpty;
  }

  Future<bool> ensureCampXSession({bool allowRelogin = true}) async {
    final token = await _secureStorage.getCampXSessionToken();
    final tenantId = await _secureStorage.getXTenantId();
    final institutionCode = await _secureStorage.getXInstitutionCode();

    if ((token ?? '').isNotEmpty &&
        (tenantId ?? '').isNotEmpty &&
        (institutionCode ?? '').isNotEmpty) {
      final user = _ref.read(userProvider);
      if (user != null &&
          ((user.cookie ?? '').isEmpty ||
              (user.tenantId ?? '').isEmpty ||
              (user.institutionCode ?? '').isEmpty)) {
        _ref.read(userProvider.notifier).state = user.copyWith(
          cookie: token,
          tenantId: tenantId,
          institutionCode: institutionCode,
        );
      }
      return true;
    }

    if (!allowRelogin) return false;
    try {
      await reloginWithStoredCredentials();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<UserModel> reloginWithStoredCredentials() async {
    final username = await _secureStorage.getCampXUsername();
    final password = await _secureStorage.getCampXPassword();

    if ((username ?? '').isEmpty || (password ?? '').isEmpty) {
      throw Exception('CampX credentials not found. Please connect again.');
    }

    return completeCampXLogin(username!, password!);
  }

  Future<void> disconnectCampX() async {
    await _secureStorage.clearCampXSession();
    final user = _ref.read(userProvider);
    if (user == null) return;

    final updated = user.copyWith(
      cookie: '',
      tenantId: '',
      institutionCode: '',
      campXUsername: '',
      campXPassword: '',
    );

    _ref.read(userProvider.notifier).state = updated;
    await _syncCampXToFirebase(updated);
  }
}