import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:unisync/features/auth/auth_repository.dart';
import 'package:unisync/models/user_model.dart';

final FirebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn();
});

final userProvider = StateProvider<UserModel?>((ref) {
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

  final email = firebaseUser.email!;
  final name = firebaseUser.displayName ?? "";

  final user = await repo.signInWithGoogleBackendOnly(
    email: email,
    name: name,
  );

  ref.read(userProvider.notifier).state = user;
});

