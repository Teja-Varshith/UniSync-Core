import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:routemaster/routemaster.dart';
import 'package:unisync/app/providers.dart';
import 'package:unisync/app/routes.dart';
import 'package:unisync/app/theme/app_theme.dart';
import 'package:unisync/app/theme/theme_provider.dart';
import 'package:unisync/features/auth/auth_controller.dart';
import 'package:unisync/features/auth/view/login_screen.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  @override
  Widget build(BuildContext context) {
    final init = ref.watch(appInitProvider);
    final userState = ref.watch(userProvider);

    return init.when(
        loading: () => MaterialApp(
              debugShowCheckedModeBanner: false,
              home: Scaffold(
                body: Center(
                  child: Lottie.asset('assets/animations/loading.json'),
                ),
              ),
            ),
        error: (e, _) => MaterialApp(
            home: Scaffold(body: Center(child: Text(e.toString())))),
        data: (_) {
          if (userState == null) {
            return MaterialApp.router(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.darkTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: ThemeMode.dark,
              routerDelegate: RoutemasterDelegate(routesBuilder: (_) {
                return loggedOutRoutes;
              }),
              routeInformationParser: const RoutemasterParser(),
            );
          } else if (userState.profileComplete == false) {
            return MaterialApp.router(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.darkTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: ThemeMode.dark,
              routerDelegate: RoutemasterDelegate(routesBuilder: (_) {
                return completeProfileRoutes;
              }),
              routeInformationParser: const RoutemasterParser(),
            );
          } else {
            return MaterialApp.router(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.darkTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: ThemeMode.dark,
              routerDelegate: RoutemasterDelegate(routesBuilder: (_) {
                return loggedInRoutes;
              }),
              routeInformationParser: const RoutemasterParser(),
            );
          }
        });
  }
}
