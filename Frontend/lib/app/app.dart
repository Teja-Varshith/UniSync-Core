import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:routemaster/routemaster.dart';
import 'package:UniSync/ads%20Manager/add_manager.dart';
import 'package:UniSync/constants/constant.dart';
import 'package:UniSync/app/providers.dart';
import 'package:UniSync/app/routes.dart';
import 'package:UniSync/firebase_options.dart';
import 'package:UniSync/firebase_service.dart';
import 'package:UniSync/app/startup_splash_screen.dart';
import 'package:UniSync/models/user_model.dart';

class App extends ConsumerStatefulWidget{
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  String? _lastAnalyticsUserId;
  late Future<void> _startupFuture;

  @override
  void initState() {
    super.initState();
    _startupFuture = _runStartup();
  }

  Future<void> _runStartup() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await FirebaseService.initialize();
  
    ref.invalidate(appInitProvider);
    await ref.read(appInitProvider.future);
  }

  void _retryStartup() {
    setState(() {
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

  

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);
    final theme = buildUniSyncDarkTheme();

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
            theme: theme,
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
            theme: theme,
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
      theme: theme,
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
      theme: theme,
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
              theme: theme,
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
                  theme: theme,
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
                theme: theme,
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
              theme: theme,
              home: const StartupSplashScreen(
                statusText: 'Checking account status...',
              ),
            ),
            error: (_, __) => MaterialApp(
              title: 'UniSync - AI College Companion',
              debugShowCheckedModeBanner: false,
              scaffoldMessengerKey: rootScaffoldMessengerKey,
              theme: theme,
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
          theme: theme,
          home: const StartupSplashScreen(
            statusText: 'Checking account status...',
          ),
        ),
        error: (_, __) => MaterialApp(
          title: 'UniSync - AI College Companion',
          debugShowCheckedModeBanner: false,
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          theme: theme,
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
