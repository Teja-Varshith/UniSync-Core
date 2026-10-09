import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:UniSync/features/admin/repository/admin_config_repository.dart';

final adminConfigRepositoryProvider = Provider<AdminConfigRepository>((ref) {
  return AdminConfigRepository(FirebaseFirestore.instance);
});

// ─────────────────────────────────────────────────────────────────────────────
//  FEATURE FLAGS
// ─────────────────────────────────────────────────────────────────────────────

/// Live feature flags for the whole app.
///
/// Falls back to permissive defaults on error, so a Firestore outage can
/// never hide a working feature from every user at once.
final featureFlagsProvider = StreamProvider<AppFeatureFlags>((ref) {
  return ref
      .watch(adminConfigRepositoryProvider)
      .watchFeatureFlags()
      .handleError((Object error) {
    debugPrint('[FeatureFlags] watch failed, using defaults: $error');
  });
});

/// Master ads switch. Read by the app shell, which pushes it into
/// [AdManager] — the manager itself has no Riverpod dependency.
final adsEnabledProvider = Provider<bool>((ref) {
  return ref.watch(featureFlagsProvider).maybeWhen(
        data: (flags) => flags.adsEnabled,
        orElse: () => AppFeatureFlags.defaults.adsEnabled,
      );
});

/// Convenience read used by the nav bar and the attendance routes.
final attendanceEnabledProvider = Provider<bool>((ref) {
  return ref.watch(featureFlagsProvider).maybeWhen(
        data: (flags) => flags.attendanceEnabled,
        orElse: () => AppFeatureFlags.defaults.attendanceEnabled,
      );
});

// ─────────────────────────────────────────────────────────────────────────────
//  ADMIN ACCESS
// ─────────────────────────────────────────────────────────────────────────────

/// Whether the signed-in account is on the super-user allowlist.
///
/// This decides only whether the admin entry point is *visible*. It is not a
/// security boundary — anything the panel writes must also be restricted by
/// Firestore security rules, because a determined user can call Firestore
/// directly regardless of what the UI shows them.
final isSuperUserProvider = FutureProvider<bool>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    debugPrint('[AdminAccess] denied: nobody is signed in');
    return false;
  }

  try {
    final config =
        await ref.watch(adminConfigRepositoryProvider).fetchAccessConfig();
    final allowed = config.allows(uid: user.uid, email: user.email);

    // Denials here are silent by design, which makes a misconfigured
    // allowlist impossible to tell apart from a working one. Log enough to
    // settle it without a console trip.
    if (!allowed) {
      debugPrint(
        '[AdminAccess] denied.\n'
        '  signed in as : ${user.email} (${user.uid})\n'
        '  allowed uids : ${config.uids.isEmpty ? '(none)' : config.uids}\n'
        '  allowed mails: ${config.emails.isEmpty ? '(none)' : config.emails}\n'
        '  If both lists are empty the app_config/access document is '
        'missing, the fields are not arrays, or your rules block reading it.',
      );
    } else {
      debugPrint('[AdminAccess] granted to ${user.email}');
    }
    return allowed;
  } catch (error) {
    // Fail closed. An unreadable allowlist means no admin UI, never open UI.
    debugPrint(
      '[AdminAccess] denied: could not read app_config/access — $error\n'
      '  A permission-denied here means your Firestore rules do not let a '
      'signed-in user read that document.',
    );
    return false;
  }
});

/// Deliberately does **not** swallow errors.
///
/// It used to catch and return [AdminAccessConfig.denyAll], which has empty
/// lists — making a permission-denied read indistinguishable from a document
/// with nobody in it. Those two need completely different fixes, so the error
/// has to survive for the UI to report it. Access itself still fails closed:
/// [isSuperUserProvider] treats any error as "not an admin".
final adminAccessConfigProvider = FutureProvider<AdminAccessConfig>((ref) async {
  return ref.watch(adminConfigRepositoryProvider).fetchAccessConfig();
});

/// Raw description of the access document, for the diagnostic panel.
final adminAccessRawProvider = FutureProvider<String>((ref) async {
  return ref.watch(adminConfigRepositoryProvider).describeAccessDoc();
});
