import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:UniSync/features/auth/auth_repository.dart';
import 'package:UniSync/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:UniSync/constants/constant.dart';

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

class GlobalBanConfig {
  const GlobalBanConfig({
    required this.message,
    required this.allowedUsers,
  });

  final String? message;
  final Set<String> allowedUsers;
}

bool _isTruthyValue(dynamic value) {
  if (value == true) return true;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    return normalized == 'true' ||
        normalized == '1' ||
        normalized == 'yes' ||
        normalized == 'active' ||
        normalized == 'enabled';
  }
  return false;
}

Set<String> _parseAllowedUsers(dynamic raw) {
  final allowedUsers = <String>{};

  void addCandidate(dynamic candidate) {
    final normalized = candidate?.toString().trim().toLowerCase();
    if (normalized != null && normalized.isNotEmpty) {
      allowedUsers.add(normalized);
    }
  }

  if (raw is List) {
    for (final entry in raw) {
      addCandidate(entry);
    }
    return allowedUsers;
  }

  if (raw is String) {
    final normalized = raw.trim();
    if (normalized.isEmpty) return allowedUsers;
    for (final entry in normalized.split(',')) {
      addCandidate(entry);
    }
    return allowedUsers;
  }

  if (raw is Map) {
    raw.forEach((key, value) {
      if (_isTruthyValue(value)) {
        addCandidate(key);
      }
    });
  }

  return allowedUsers;
}

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

final globalBanConfigProvider = FutureProvider<GlobalBanConfig>((ref) async {
  final firestore = ref.watch(firebaseFirestoreProvider);
  final snapshot = await firestore
      .collection('config')
      .doc('user_flags')
      .get();
  final data = snapshot.data();
  if (data == null) {
    return const GlobalBanConfig(
      message: null,
      allowedUsers: <String>{},
    );
  }

  final dynamic banAll = data['banAll'] ?? data['banall'];
  final allowedUsers = <String>{
    ..._parseAllowedUsers(
      data['allowedUsers'] ?? data['allowUsers'] ?? data['whitelistedUsers'],
    ),
  };

  if (banAll is Map) {
    allowedUsers.addAll(
      _parseAllowedUsers(
        banAll['allowedUsers'] ??
            banAll['allowUsers'] ??
            banAll['whitelistedUsers'],
      ),
    );
  }

  if (banAll == null) {
    return GlobalBanConfig(
      message: null,
      allowedUsers: allowedUsers,
    );
  }

  String? message;

  if (banAll is String) {
    final parsedMessage = banAll.trim();
    message = parsedMessage.isEmpty ? null : parsedMessage;
  } else if (banAll is bool) {
    if (banAll) {
      final parsedMessage = (data['banAllMessage'] ?? data['banallMessage'])
          ?.toString()
          .trim();
      message = (parsedMessage == null || parsedMessage.isEmpty)
          ? 'Service is temporarily unavailable. Please try again later.'
          : parsedMessage;
    }
  } else if (banAll is Map) {
    final enabled = banAll['enabled'] == true || banAll['active'] == true;
    if (enabled) {
      final parsedMessage =
          (banAll['message'] ?? banAll['reason'] ?? banAll['text'])
              ?.toString()
              .trim();
      message = (parsedMessage == null || parsedMessage.isEmpty)
          ? 'Service is temporarily unavailable. Please try again later.'
          : parsedMessage;
    }
  }

  return GlobalBanConfig(
    message: message,
    allowedUsers: allowedUsers,
  );
});

final dioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      baseUrl: BASE_URI,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
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

