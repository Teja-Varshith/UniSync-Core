import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:unisync/app/providers.dart';
import 'package:unisync/constants/constant.dart';
import 'package:unisync/models/user_model.dart';
import 'package:unisync/storage/secure_storage.dart';

final AttendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository(ref: ref);
});

class AttendanceRepository {
  final Ref _ref;

  AttendanceRepository({required Ref ref}) : _ref = ref;

  Future<void> _syncUserToFirebase(UserModel user) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(firebaseUser.uid)
        .set(
      {
        ...user.toMap(),
        'firebaseUid': firebaseUser.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<UserModel> completeCampXLogin(String username, String password) async {
    final currentUser = _ref.read(userProvider);
    if (currentUser == null) {
      throw Exception('User not available');
    }

    final url = Uri.parse(anyUrl);
    final body = {
      'loginId': username,
      'password': password,
      'deviceType': 'mobile',
      'clientName': 'Unknown',
      'os': 'Android',
      'osVersion': '15',
      'loginType': 'USER',
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

      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
      final session = jsonData['session'] as Map<String, dynamic>?;
      final accessToken = session?['token'] as String?;
      final institutionCode = session?['institutionCode'] as String?;
      final tenantId = session?['subDomain'] as String?;

      if (accessToken == null || institutionCode == null || tenantId == null) {
        throw Exception('CampX login response is missing session details');
      }

      await SecureStorageService().setIds(tenantId, institutionCode);

      final optimisticUser = currentUser.copyWith(
        cookie: accessToken,
        institutionCode: institutionCode,
        campXPassword: password,
        campXUsername: username,
        tenantId: tenantId,
      );
      _ref.read(userProvider.notifier).state = optimisticUser;

      final res = await Dio().post(
        '$BASE_URI/auth/updateTenantDetails',
        data: {
          'emailId': currentUser.emailId,
          'accessToken': accessToken,
          'tenantId': tenantId,
          'password': password,
          'institutionCode': institutionCode,
          'campXUsername': username,
        },
      );

      final persistedUser = UserModel.fromMap(
        res.data['user'] as Map<String, dynamic>,
      );
      _ref.read(userProvider.notifier).state = persistedUser;
      await _syncUserToFirebase(persistedUser);

      return persistedUser;
    } catch (e) {
      rethrow;
    }
  }
}
