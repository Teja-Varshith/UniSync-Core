import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:UniSync/constants/constant.dart';

/// Sends push notifications by asking the backend to do it.
///
/// The app never holds an FCM server key. Doing so would mean shipping, in
/// every APK, the ability to push a notification to the entire userbase —
/// extractable by anyone who decompiles the app. Instead the app proves who
/// it is with a Firebase ID token and the server decides whether that
/// identity is allowed to send.
class AdminNotificationService {
  AdminNotificationService(this._dio);

  final Dio _dio;

  /// Absolute, built from [BASE_URI] — the same convention every other
  /// repository in the app follows.
  ///
  /// A relative path would depend on the injected Dio's `baseUrl`, and there
  /// are two `dioProvider`s in this codebase: the one in constant.dart has no
  /// base URL at all, and the one in providers.dart still points at an old
  /// LAN address. Building the full URL here removes that ambiguity.
  ///
  /// [BASE_URI] already ends in `/api`, and the route is mounted at
  /// `/api/admin/notifications`, so only the remainder belongs here.
  static const _path = '$BASE_URI/admin/notifications/send';

  Future<AdminSendResult> send({
    required String title,
    required String body,
    required AdminSendTarget target,
    String? token,
    String? uid,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const AdminSendResult.failure('You are not signed in');
    }

    // Force-refresh so a token that expired while the panel sat open does
    // not produce a confusing 401.
    final idToken = await user.getIdToken(true);

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _path,
        data: {
          'title': title.trim(),
          'body': body.trim(),
          'target': target.wireName,
          if (token != null && token.trim().isNotEmpty) 'token': token.trim(),
          if (uid != null && uid.trim().isNotEmpty) 'uid': uid.trim(),
        },
        options: Options(
          headers: {'Authorization': 'Bearer $idToken'},
          // Read the server's own error message instead of letting Dio throw
          // on a 4xx — the backend explains refusals in the body.
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      final data = response.data ?? const {};
      if (response.statusCode == 200 && data['ok'] == true) {
        return AdminSendResult.success(
          'Sent (${data['messageId'] ?? 'no id'})',
        );
      }
      return AdminSendResult.failure(
        (data['error'] ?? 'Send failed (${response.statusCode})').toString(),
      );
    } on DioException catch (error) {
      final serverMessage = error.response?.data is Map
          ? (error.response!.data as Map)['error']
          : null;
      return AdminSendResult.failure(
        (serverMessage ?? error.message ?? 'Network error').toString(),
      );
    }
  }
}

enum AdminSendTarget {
  all('all'),
  token('token'),
  uid('uid');

  const AdminSendTarget(this.wireName);
  final String wireName;
}

class AdminSendResult {
  const AdminSendResult.success(this.message) : ok = true;
  const AdminSendResult.failure(this.message) : ok = false;

  final bool ok;
  final String message;
}
