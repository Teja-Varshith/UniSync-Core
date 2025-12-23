import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisync/app/providers.dart';
import 'package:unisync/features/auth/auth_repository.dart';
import 'package:unisync/models/user_model.dart';



final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController(
    ref: ref,
    repo: ref.read(AuthRepositoryProvider),
  );
});

class AuthController {
  final Ref ref;
  final AuthRepository repo;

  AuthController({
    required this.ref,
    required this.repo,
  });

  Future<UserModel?> signInWithGoogle() async {
    final user = await repo.signInWithGoogle();
    if (user != null) {
      ref.read(userProvider.notifier).state = user;
      return user;
    }
    return null;
  }

  Future<void> signOut() async {
    await repo.logOut();
    ref.read(userProvider.notifier).state = null;
  }
}

