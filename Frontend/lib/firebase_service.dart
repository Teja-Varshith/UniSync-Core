import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_in_app_messaging/firebase_in_app_messaging.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  FirebaseService._();

  static FirebaseAnalytics? _analytics;
  static FirebaseInAppMessaging? _fiam;
  static FirebaseAnalyticsObserver? _observer;
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      _analytics = FirebaseAnalytics.instance;
      _fiam = FirebaseInAppMessaging.instance;

      await _analytics?.setAnalyticsCollectionEnabled(true);
      await _fiam?.setMessagesSuppressed(false);
      await _fiam?.setAutomaticDataCollectionEnabled(true);
      await logAppOpen();

      _initialized = true;

      if (kDebugMode) {
        debugPrint('Firebase analytics and IAM initialized successfully');
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Firebase analytics initialization error: $error');
      }
    }
  }

  static FirebaseAnalytics get analytics {
    final instance = _analytics;
    if (instance == null) {
      throw Exception(
        'FirebaseService not initialized. Call FirebaseService.initialize() first.',
      );
    }
    return instance;
  }

  static FirebaseInAppMessaging get inAppMessaging {
    final instance = _fiam;
    if (instance == null) {
      throw Exception(
        'FirebaseService not initialized. Call FirebaseService.initialize() first.',
      );
    }
    return instance;
  }

  static FirebaseAnalyticsObserver getAnalyticsObserver() {
    _observer ??= FirebaseAnalyticsObserver(analytics: analytics);
    return _observer!;
  }

  static Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    try {
      await analytics.logEvent(name: name, parameters: parameters);
      if (kDebugMode) {
        debugPrint('Analytics event logged: $name');
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Analytics event error: $error');
      }
    }
  }

  static Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    try {
      await analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass ?? screenName,
      );
      if (kDebugMode) {
        debugPrint('Screen view logged: $screenName');
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Screen view logging error: $error');
      }
    }
  }

  static Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    try {
      await analytics.setUserProperty(name: name, value: value);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Set user property error: $error');
      }
    }
  }

  static Future<void> setUserId(String? userId) async {
    try {
      await analytics.setUserId(id: userId);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Set user ID error: $error');
      }
    }
  }

  static Future<void> logAppOpen() async {
    await logEvent(name: 'app_open');
  }

  static Future<void> logButtonClick(String buttonName) async {
    await logEvent(
      name: 'button_click',
      parameters: {'button_name': buttonName},
    );
  }

  static Future<void> logFeatureUsage(String featureName) async {
    await logEvent(
      name: 'feature_used',
      parameters: {'feature_name': featureName},
    );
  }

  static Future<void> logAdImpression({
    required String adPlatform,
    required String adFormat,
    String? adUnitName,
  }) async {
    await logEvent(
      name: 'ad_impression',
      parameters: {
        'ad_platform': adPlatform,
        'ad_format': adFormat,
        if (adUnitName != null) 'ad_unit_name': adUnitName,
      },
    );
  }

  static Future<void> setInAppMessagingEnabled(bool enabled) async {
    try {
      await inAppMessaging.setMessagesSuppressed(!enabled);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('In-app messaging toggle error: $error');
      }
    }
  }

  static Future<void> triggerInAppMessage(String eventName) async {
    await logEvent(name: eventName);
  }
}
