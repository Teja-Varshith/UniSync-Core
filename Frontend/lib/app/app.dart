import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:routemaster/routemaster.dart';
import 'package:unisync/app/providers.dart';
import 'package:unisync/app/routes.dart';
import 'package:unisync/features/auth/auth_controller.dart';
import 'package:unisync/features/auth/view/login_screen.dart';

class App extends ConsumerStatefulWidget{
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
      loading: () => const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      error: (e, _) => MaterialApp(home: Text(e.toString())),
      data: (_) {
         if(userState == null){
      return MaterialApp.router(
          debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Poppins',
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
          displayMedium: TextStyle(fontSize: 36, fontWeight: FontWeight.w600),
          displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
          headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
          headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          titleSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
          bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
          bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
          bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w300),
          labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w400),
          ),
      ),
      routerDelegate: RoutemasterDelegate(
        routesBuilder: (_) {
          return loggedOutRoutes;
        }
      ),
      routeInformationParser: const RoutemasterParser(),
        ); 
    }
    else if(userState.profileComplete == false){
      return MaterialApp.router(
          debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Poppins',
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
          displayMedium: TextStyle(fontSize: 36, fontWeight: FontWeight.w600),
          displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
          headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
          headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          titleSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
          bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
          bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
          bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w300),
          labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w400),
          ),
      ),
      routerDelegate: RoutemasterDelegate(
        routesBuilder: (_) {
          return completeProfileRoutes;
        }
      ),
      routeInformationParser: const RoutemasterParser(),
        ); 
    }
    else{
      return MaterialApp.router(
          debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Poppins',
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
          displayMedium: TextStyle(fontSize: 36, fontWeight: FontWeight.w600),
          displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
          headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
          headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          titleSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
          bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
          bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
          bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w300),
          labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w400),
          ),
      ),
      routerDelegate: RoutemasterDelegate(
        routesBuilder: (_) {
          return loggedInRoutes;
        }
      ),
      routeInformationParser: const RoutemasterParser(),
        ); 
    }
      }
    );

  }
}