import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:UniSync/app/providers.dart';

final firebaseNotificationServiceProvider =
    Provider<FirebaseNotificationService>((ref) {
  final service = FirebaseNotificationService(ref);
  ref.onDispose(service.dispose);
  return service;
});

class FirebaseNotificationService {
  FirebaseNotificationService(this._ref);

  static const String _foregroundChannelId = 'unisync_foreground_channel';
  static const String _foregroundChannelName = 'UniSync Foreground Alerts';
  static const String _foregroundChannelDescription =
      'Shows notifications while the app is open.';

  final Ref _ref;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  StreamSubscription<String>? _tokenRefreshSub;
  bool _localNotificationsReady = false;

  Future<void> initNotification() async {
    if (_tokenRefreshSub != null) return;

    try {
      final settings = await _firebaseMessaging.requestPermission();
      final isAllowed =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      if (!isAllowed) {
        if (kDebugMode) {
          debugPrint('[Notifications] permission not granted.');
        }
        return;
      }

      await _syncCurrentToken();

      _tokenRefreshSub ??= _firebaseMessaging.onTokenRefresh.listen(
        _storeToken,
        onError: (error) {
          if (kDebugMode) {
            debugPrint('[Notifications] token refresh error: $error');
          }
        },
      );
    } on MissingPluginException catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[Notifications] firebase_messaging plugin is not ready: $error. '
          'Do a full app restart after adding the plugin.',
        );
      }
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('[Notifications] init failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    }
  }

  Future<void> _syncCurrentToken() async {
    final token = await _firebaseMessaging.getToken();
    await _storeToken(token);
  }

  Future<void> initLocalNotifications() async {
    if (_localNotificationsReady) return;

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _foregroundChannelId,
            _foregroundChannelName,
            description: _foregroundChannelDescription,
            importance: Importance.max,
          ),
        );

    _localNotificationsReady = true;
  }

  Future<void> showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await initLocalNotifications();

    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        _foregroundChannelId,
        _foregroundChannelName,
        channelDescription: _foregroundChannelDescription,
        importance: Importance.max,
        priority: Priority.high,
      ),
    );

    await flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      notificationDetails,
    );
  }

  Future<void> _storeToken(String? token) async {
    if (token == null || token.trim().isEmpty) return;
    final normalizedToken = token.trim();

    final user = _ref.read(userProvider);
    final userId = user?.id?.trim();
    if (userId == null || userId.isEmpty) {
      if (kDebugMode) {
        debugPrint('[Notifications] token skipped, no signed-in user.');
      }
      return;
    }

    final firestore = _ref.read(firebaseFirestoreProvider) as FirebaseFirestore;
    await firestore.collection('users').doc(userId).set(
      {
        'fcmToken': normalizedToken,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    if (user != null && user.fcmToken != normalizedToken) {
      _ref.read(userProvider.notifier).state =
          user.copyWith(fcmToken: normalizedToken);
    }

    if (kDebugMode) {
      debugPrint('[Notifications] FCM token saved for uid=$userId');
    }
  }

  void dispose() {
    _tokenRefreshSub?.cancel();
  }
}
