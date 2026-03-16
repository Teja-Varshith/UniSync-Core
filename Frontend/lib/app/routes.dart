import 'package:flutter/material.dart';
import 'package:routemaster/routemaster.dart';
import 'package:unisync/features/Campus_Mode/attendance/view/campx_login.dart';
import 'package:unisync/features/Campus_Mode/attendance/view/live_attendance_screen.dart';
import 'package:unisync/features/Carrer_Mode/cards/view/card_quiz.dart';
import 'package:unisync/features/Carrer_Mode/interview/view/carrer_interview_screen.dart';
import 'package:unisync/features/Carrer_Mode/interview/view/core_interview_screen.dart';
import 'package:unisync/features/Carrer_Mode/interview/view/interview_results_screen.dart';
import 'package:unisync/features/Carrer_Mode/interview/view/start_interview_screen.dart';
import 'package:unisync/features/Carrer_Mode/portifolio/view/pdf_upload.dart';
import 'package:unisync/features/HomeScreen/homescreen.dart';
import 'package:unisync/features/HomeScreen/next_update_promo.dart';
import 'package:unisync/features/auth/view/fill_tank.dart';
import 'package:unisync/features/auth/view/login_screen.dart';
import 'package:unisync/features/Carrer_Mode/carrer_main_screen.dart';
import 'package:unisync/features/builder/view/builder_home_screen.dart';
import 'package:unisync/features/peer_connect/peers/peer_profile.dart';
import 'package:unisync/features/peer_connect/peers/peer_screen.dart';
import 'package:unisync/features/profile/profile_screen.dart';

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
    // '/': (_) => MaterialPage(child: HomeScreen()),
    '/': (_) => MaterialPage(child: NewHomeScreen()),
    '/peer': (_) => MaterialPage(child: PeerScreen()),
    '/peerProfile': (_) => MaterialPage(child: PeerProfile()),
    "/carrer": (_) => MaterialPage(child: CareerScreen()),
    "/carrer-interview-screen": (_) => MaterialPage(child: CarrerInterviewScreen()),
    "/startInterviewScreen": (_) => MaterialPage(child: StartInterviewScreen()),
    "/coreInterviewScreen" : (_) => MaterialPage(child: CoreInterviewScreen()),
    "/interviewResultsScreen": (_) => MaterialPage(child: InterviewResultsScreen()),
    "/profile": (_) => MaterialPage(child: ProfileScreen()),
    "/builderHomeScreen": (_) => MaterialPage(child: BuilderHomeScreen()),
    "/cardsQuiz": (_) => MaterialPage(child: CardQuiz()),
    "/reportsScreen": (_) => MaterialPage(child: InterviewResultsScreen()),
    "/liveAttendence": (_) => MaterialPage(child: LiveAttendence()),
    "/campXLogin": (_) => MaterialPage(child: CampxLoginScreen()),
    "/portifolio": (_) => MaterialPage(child: PdfUpload()),
    "/nextUpdatePromo": (_) => MaterialPage(child: NextUpdatePromoScreen()),
  }
);