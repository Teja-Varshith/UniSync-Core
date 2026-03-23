import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:UniSync/features/auth/auth_repository.dart';
import 'package:UniSync/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final firebaseFirestoreProvider = Provider((ref)=>FirebaseFirestore.instance);
final FirebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn();
});

final userProvider = StateProvider<UserModel?>((ref) {
  return null;
});

final flagStateProvider = FutureProvider<Map<String, String>>((ref) async {
  final firestore = ref.watch(firebaseFirestoreProvider);
  final snapshot = await firestore
      .collection('config')
      .doc('user_flags')
      .get();
  final data = snapshot.data();
  if (data == null) return <String, String>{};

  dynamic rawFlags =
      data['flags'] ?? data['userFlags'] ?? data['flaggedUsers'];
  if (rawFlags is! Map) {
    rawFlags = data;
  }

  final parsedFlags = <String, String>{};
  (rawFlags as Map).forEach((key, value) {
    final userId = key.toString().trim();
    if (userId.isEmpty || value == null) return;

    if (value is String || value is bool || value is num) {
      final normalized = value.toString().trim();
      if (normalized.isNotEmpty) {
        parsedFlags[userId] = normalized;
      }
      return;
    }

    if (value is Map) {
      final statusValue =
          value['status'] ?? value['reason'] ?? value['value'];
      if (statusValue == null) return;
      final normalized = statusValue.toString().trim();
      if (normalized.isNotEmpty) {
        parsedFlags[userId] = normalized;
      }
    }
  });

  return parsedFlags;
});

final globalBanMessageProvider = FutureProvider<String?>((ref) async {
  final firestore = ref.watch(firebaseFirestoreProvider);
  final snapshot = await firestore
      .collection('config')
      .doc('user_flags')
      .get();
  final data = snapshot.data();
  if (data == null) return null;

  final dynamic banAll = data['banAll'] ?? data['banall'];
  if (banAll == null) return null;

  if (banAll is String) {
    final message = banAll.trim();
    return message.isEmpty ? null : message;
  }

  if (banAll is bool) {
    if (!banAll) return null;
    final message = (data['banAllMessage'] ?? data['banallMessage'])
        ?.toString()
        .trim();
    if (message == null || message.isEmpty) {
      return 'Service is temporarily unavailable. Please try again later.';
    }
    return message;
  }

  if (banAll is Map) {
    final enabled = banAll['enabled'] == true || banAll['active'] == true;
    if (!enabled) return null;

    final message =
        (banAll['message'] ?? banAll['reason'] ?? banAll['text'])
            ?.toString()
            .trim();
    if (message == null || message.isEmpty) {
      return 'Service is temporarily unavailable. Please try again later.';
    }
    return message;
  }

  return null;
});

final dioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      baseUrl: "http://10.185.91.196:3000",
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
});

final appInitProvider = FutureProvider<void>((ref) async {
  final auth = FirebaseAuth.instance;
  final repo = ref.read(AuthRepositoryProvider);

  final firebaseUser = auth.currentUser;

  if (firebaseUser == null) {
    ref.read(userProvider.notifier).state = null;
    return;
  }

  final user = await repo.loadCurrentUserProfile();

  ref.read(userProvider.notifier).state = user;
});

