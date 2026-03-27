import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:UniSync/app/providers.dart';
import 'package:UniSync/features/attendance/repository/attendance_repository.dart';
import 'package:UniSync/features/auth/auth_repository.dart';
import 'package:UniSync/models/user_model.dart';



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

  Future<UserModel?> signInAsReviewer(String uid) async {
    final user = await repo.loadUserProfileByUid(uid);
    if (user != null) {
      ref.read(userProvider.notifier).state = user;
      return user;
    }
    return null;
  }

  Future<void> signOut() async {
    try {
      await ref.read(AttendanceRepositoryProvider).disconnectCampX();
    } catch (_) {
      // CampX cleanup is best-effort; sign out should still continue.
    }
    await repo.logOut();
    ref.read(userProvider.notifier).state = null;
  }
}

