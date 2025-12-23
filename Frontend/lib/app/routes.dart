import 'package:flutter/material.dart';
import 'package:routemaster/routemaster.dart';
import 'package:unisync/features/auth/view/fill_tank.dart';
import 'package:unisync/features/auth/view/login_screen.dart';
import 'package:unisync/features/homescreen/view/home_screen.dart';

final loggedOutRoutes = RouteMap(
  routes: {
    "/": (_) => MaterialPage(child: LoginScreen()),
  }
);

final completeProfileRoutes = RouteMap(
  routes: {
    '/': (_) => const MaterialPage(child: FillTank()),
  },
);


final loggedInRoutes = RouteMap(
  routes: {
    '/': (_) => MaterialPage(child: HomeScreen())
  }
);