import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:routemaster/routemaster.dart';
import 'package:UniSync/constants/constant.dart';
import 'package:UniSync/ads%20Manager/add_manager.dart';
import 'package:UniSync/app/providers.dart';
import 'package:UniSync/features/admin/controllers/admin_controllers.dart';
import 'package:UniSync/app/routes.dart';
import 'package:UniSync/app/theme/app_theme.dart';
import 'package:UniSync/app/theme/theme_provider.dart';
import 'package:UniSync/firebase_options.dart';
import 'package:UniSync/firebase_service.dart';
import 'package:UniSync/app/startup_splash_screen.dart';
import 'package:UniSync/models/user_model.dart';

class App extends ConsumerStatefulWidget{
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> with WidgetsBindingObserver {
  String? _lastAnalyticsUserId;
  late Future<void> _startupFuture;

  /// When the app was last backgrounded, or null if it never has been.
  ///
  /// App-open ads fire only on a return from background, never on launch —
  /// opening the app should put the user on the home screen, not in front of
  /// an ad. A null value means this process has not been backgrounded yet,
  /// which is exactly the cold-start case, so the check below covers launch
  /// without needing a separate flag.
  DateTime? _pausedAt;

  /// Firestore-backed providers must not be read before
  /// [Firebase.initializeApp] has run. `build()` executes on the first frame,
  /// well before [_startupFuture] resolves, so watching the ads flag there
  /// unconditionally threw "No Firebase App '[DEFAULT]' has been created".
  /// Flipped once startup finishes, which also rebuilds and subscribes.
  bool _firebaseReady = false;

  /// How long the app must have been in the background before a return
  /// counts as a new session. Flicking to another app for a few seconds and
  /// coming straight back should not be monetised.
  static const _minBackgroundForAppOpen = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startupFuture = _runStartup();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _pausedAt = DateTime.now();
      return;
    }

    if (state != AppLifecycleState.resumed) return;

    final pausedAt = _pausedAt;
    _pausedAt = null;

    // Never on launch: no pause means this is the cold start.
    if (pausedAt == null) return;

    // Nor on a brief task-switch.
    if (DateTime.now().difference(pausedAt) < _minBackgroundForAppOpen) return;

    // This is where app-open actually earns: a real return to the app. The
    // manager's own cooldown, cache window and full-screen guard stop it
    // firing too often or colliding with an interstitial.
    AdManager.instance.showAppOpenAd();
  }

  Future<void> _runStartup() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await FirebaseService.initialize();

    // Without this the Mobile Ads SDK is never started and no format can
    // fill. It was missing on this branch entirely, which is why ads earned
    // nothing here regardless of placement.
    await AdManager.initialize();

    // Pre-load both full-screen formats so the first opportunity to show one
    // isn't wasted warming the cache.
    AdManager.instance
      ..loadInterstitialAd(reset: true)
      ..loadAppOpenAd();

    ref.invalidate(appInitProvider);
    await ref.read(appInitProvider.future);

    if (mounted) setState(() => _firebaseReady = true);
  }

  void _retryStartup() {
    setState(() {
      _firebaseReady = false;
      _startupFuture = _runStartup();
    });
  }

  bool _isGlobalBanAllowed(UserModel user, Set<String> allowedUsers) {
    if (allowedUsers.isEmpty) return false;

    final candidates = <String>{
      (user.id ?? '').trim().toLowerCase(),
      user.emailId.trim().toLowerCase(),
    }..removeWhere((value) => value.isEmpty);

    return candidates.any(allowedUsers.contains);
  }

  

  /// Pushes the remote ads flag into [AdManager].
  ///
  /// Lives in its own widget, mounted only after startup finishes, because
  /// reading the flag touches `FirebaseFirestore.instance`. Called from
  /// `build()` directly it ran on the very first frame — before
  /// `Firebase.initializeApp()` in [_runStartup] had completed — and threw
  /// "No Firebase App '[DEFAULT]' has been created".
  ///
  /// Kept outside [AdManager] so the manager stays free of Riverpod, and
  /// above the router so the switch applies app-wide the moment it flips.

  @override
  Widget build(BuildContext context) {
    // Conditional on purpose: the subscription is created only once Firebase
    // is up, and the setState that flips the flag rebuilds us to do it.
    if (_firebaseReady) {
      AdManager.instance.setAdsEnabled(ref.watch(adsEnabledProvider));
    }

    final userState = ref.watch(userProvider);
    final themeMode = ref.watch(themeModeProvider);

    final analyticsUserId = userState?.id;
    if (_lastAnalyticsUserId != analyticsUserId) {
      _lastAnalyticsUserId = analyticsUserId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FirebaseService.setUserId(analyticsUserId);
        if (userState != null) {
          FirebaseService.setUserProperty(
            name: 'profile_complete',
            value: userState.profileComplete.toString(),
          );
          FirebaseService.setUserProperty(
            name: 'has_ad_free_access',
            value: userState.hasAdFreeAccess.toString(),
          );
          if ((userState.collegeName ?? '').trim().isNotEmpty) {
            FirebaseService.setUserProperty(
              name: 'college_name',
              value: userState.collegeName!.trim(),
            );
          }
          if (userState.semester != null) {
            FirebaseService.setUserProperty(
              name: 'semester',
              value: userState.semester.toString(),
            );
          }
        }
      });
    }

    return FutureBuilder<void>(
      future: _startupFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return MaterialApp(
            title: 'UniSync - AI College Companion',
            debugShowCheckedModeBanner: false,
            scaffoldMessengerKey: rootScaffoldMessengerKey,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeMode,
            home: const StartupSplashScreen(
              statusText: 'Initializing UniSync...',
            ),
          );
        }

        if (snapshot.hasError) {
          return MaterialApp(
            title: 'UniSync - AI College Companion',
            debugShowCheckedModeBanner: false,
            scaffoldMessengerKey: rootScaffoldMessengerKey,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeMode,
            home: StartupSplashScreen(
              statusText: 'Something\'s Wrong...',
              errorText: 'Startup failed. Please try again.',
              onRetry: _retryStartup,
            ),
          );
        }

        if(userState == null){
      return MaterialApp.router(
          title: 'UniSync - AI College Companion',
          debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerDelegate: RoutemasterDelegate(
        routesBuilder: (_) {
          return loggedOutRoutes;
        },
        observers: [FirebaseService.getAnalyticsObserver()],
      ),
      routeInformationParser: const RoutemasterParser(),
        ); 
    }
    else if(userState.profileComplete == false){
      return MaterialApp.router(
        title: 'UniSync - AI College Companion',
          debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerDelegate: RoutemasterDelegate(
        routesBuilder: (_) {
          return completeProfileRoutes;
        },
        observers: [FirebaseService.getAnalyticsObserver()],
      ),
      routeInformationParser: const RoutemasterParser(),
        ); 
    }
    else{
      final flagState = ref.watch(flagStateProvider);
      final globalBanState = ref.watch(globalBanConfigProvider);

      return globalBanState.when(
        skipLoadingOnRefresh: false,
        data: (globalBanConfig) {
          final globalBanMessage = globalBanConfig.message;
          final isAllowedDuringGlobalBan = _isGlobalBanAllowed(
            userState,
            globalBanConfig.allowedUsers,
          );

          if (globalBanMessage != null &&
              globalBanMessage.trim().isNotEmpty &&
              !isAllowedDuringGlobalBan) {
            return MaterialApp(
              title: 'UniSync - AI College Companion',
              debugShowCheckedModeBanner: false,
              scaffoldMessengerKey: rootScaffoldMessengerKey,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: themeMode,
              home: StartupSplashScreen(
                statusText: 'Service Unavailable',
                errorText: globalBanMessage.trim(),
                retryButtonText: 'Refresh Status',
                onRetry: () {
                  ref.invalidate(globalBanConfigProvider);
                  ref.invalidate(flagStateProvider);
                },
              ),
            );
          }

          return flagState.when(
            data: (flags) {
              final userId = (userState.id ?? '').trim();
              final emailId = userState.emailId.trim();
              String? flagValue;

              if (userId.isNotEmpty) {
                flagValue = flags[userId];
              }

              if (flagValue == null && emailId.isNotEmpty) {
                flagValue = flags[emailId] ?? flags[emailId.toLowerCase()];
                if (flagValue == null) {
                  for (final entry in flags.entries) {
                    if (entry.key.trim().toLowerCase() == emailId.toLowerCase()) {
                      flagValue = entry.value;
                      break;
                    }
                  }
                }
              }

              final normalizedFlag = flagValue?.trim().toLowerCase();
              final isFlagged = normalizedFlag != null &&
                  normalizedFlag.isNotEmpty &&
                  normalizedFlag != 'false' &&
                  normalizedFlag != '0' &&
                  normalizedFlag != 'no' &&
                  normalizedFlag != 'none' &&
                  normalizedFlag != 'inactive';

              if (isFlagged) {
                final message = (normalizedFlag == 'true' ||
                        normalizedFlag == '1')
                    ? 'Your account has been restricted. Please contact support.'
                    : flagValue!;
                return MaterialApp(
                  title: 'UniSync - AI College Companion',
                  debugShowCheckedModeBanner: false,
                  scaffoldMessengerKey: rootScaffoldMessengerKey,
                  theme: AppTheme.light,
                  darkTheme: AppTheme.dark,
                  themeMode: themeMode,
                  home: StartupSplashScreen(
                    statusText: 'Account Restricted',
                    errorText: message,
                    retryButtonText: 'Refresh Status',
                    onRetry: () {
                      ref.invalidate(globalBanConfigProvider);
                      ref.invalidate(flagStateProvider);
                    },
                  ),
                );
              }

              return MaterialApp.router(
                title: 'UniSync - AI College Companion',
                debugShowCheckedModeBanner: false,
                scaffoldMessengerKey: rootScaffoldMessengerKey,
                theme: AppTheme.light,
                darkTheme: AppTheme.dark,
                themeMode: themeMode,
                routerDelegate: RoutemasterDelegate(
                  routesBuilder: (_) {
                    return loggedInRoutes;
                  },
                  observers: [FirebaseService.getAnalyticsObserver()],
                ),
                routeInformationParser: const RoutemasterParser(),
              );
            },
            loading: () => MaterialApp(
              title: 'UniSync - AI College Companion',
              debugShowCheckedModeBanner: false,
              scaffoldMessengerKey: rootScaffoldMessengerKey,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: themeMode,
              home: const StartupSplashScreen(
                statusText: 'Checking account status...',
              ),
            ),
            error: (_, __) => MaterialApp(
              title: 'UniSync - AI College Companion',
              debugShowCheckedModeBanner: false,
              scaffoldMessengerKey: rootScaffoldMessengerKey,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: themeMode,
              home: StartupSplashScreen(
                statusText: 'Something\'s Wrong...',
                errorText: 'Could not verify account status. Please try again.',
                onRetry: () => ref.invalidate(flagStateProvider),
              ),
            ),
          );
        },
        loading: () => MaterialApp(
          title: 'UniSync - AI College Companion',
          debugShowCheckedModeBanner: false,
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          home: const StartupSplashScreen(
            statusText: 'Checking account status...',
          ),
        ),
        error: (_, __) => MaterialApp(
          title: 'UniSync - AI College Companion',
          debugShowCheckedModeBanner: false,
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          home: StartupSplashScreen(
            statusText: 'Something\'s Wrong...',
            errorText: 'Could not verify account status. Please try again.',
            onRetry: () {
              ref.invalidate(globalBanConfigProvider);
              ref.invalidate(flagStateProvider);
            },
          ),
        ),
      );
    }
      },
    );
  }
}

