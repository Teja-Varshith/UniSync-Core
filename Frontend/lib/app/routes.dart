import 'package:flutter/material.dart';
import 'package:routemaster/routemaster.dart';
import 'package:UniSync/features/attendance/view/campx_login.dart';
import 'package:UniSync/features/attendance/view/live_attendance_screen.dart';
import 'package:UniSync/features/Carrer_Mode/cards/view/card_quiz.dart';
import 'package:UniSync/features/interview/view/carrer_interview_screen.dart';
import 'package:UniSync/features/interview/view/core_interview_screen.dart';
import 'package:UniSync/features/interview/view/interview_results_screen.dart';
import 'package:UniSync/features/interview/view/start_interview_screen.dart';
import 'package:UniSync/features/Carrer_Mode/portifolio/view/pdf_upload.dart';
import 'package:UniSync/features/HomeScreen/homescreen.dart';
import 'package:UniSync/features/HomeScreen/next_update_promo.dart';
import 'package:UniSync/features/Carrer_Mode/home/resume_analyzer_screen.dart';
import 'package:UniSync/features/auth/view/fill_tank.dart';
import 'package:UniSync/features/auth/view/login_screen.dart';
import 'package:UniSync/features/Carrer_Mode/carrer_main_screen.dart';
import 'package:UniSync/features/builder/view/builder_home_screen.dart';
import 'package:UniSync/features/interview/view/interview_admin_panel_screen.dart';
import 'package:UniSync/features/interview/view/user_interview_details.dart';
import 'package:UniSync/features/peer_connect/peers/peer_profile.dart';
import 'package:UniSync/features/peer_connect/peers/peer_screen.dart';
import 'package:UniSync/features/opputunities/oppurtunities_screen.dart';
import 'package:UniSync/features/opputunities/oppurtunity_detail_screen.dart';
import 'package:UniSync/features/profile/edit_profile_screen.dart';
import 'package:UniSync/features/profile/profile_screen.dart';

final loggedOutRoutes = RouteMap(routes: {
  "/": (_) => MaterialPage(child: LoginScreen()),
});

final completeProfileRoutes = RouteMap(
  routes: {
    '/': (_) => const MaterialPage(child: FillTank()),
  },
);

final loggedInRoutes = RouteMap(routes: {
  // '/': (_) => MaterialPage(child: HomeScreen()),
  '/': (_) => MaterialPage(child: NewHomeScreen()),
  '/peer': (_) => MaterialPage(child: PeerScreen()),
  '/peerProfile': (_) => MaterialPage(child: PeerProfile()),
  "/carrer": (_) => MaterialPage(child: CareerScreen()),
  "/carrer-interview-screen": (_) =>
      MaterialPage(child: CarrerInterviewScreen()),
  "/startInterviewScreen": (_) => MaterialPage(child: StartInterviewScreen()),
  "/coreInterviewScreen": (_) => MaterialPage(child: CoreInterviewScreen()),
  "/interviewResultsScreen": (_) =>
      MaterialPage(child: InterviewResultsScreen()),
  "/interview-admin": (_) => MaterialPage(child: InterviewAdminPanelScreen()),
  // "/profile": (_) => MaterialPage(child: ProfileScreen()),
  "/settings": (_) => MaterialPage(child: ProfileScreen()),
  "/edit-profile": (_) => const MaterialPage(child: EditProfileScreen()),
  "/builderHomeScreen": (_) => MaterialPage(child: BuilderHomeScreen()),
  "/cardsQuiz": (_) => MaterialPage(child: CardQuiz()),
  "/reportsScreen": (_) => MaterialPage(child: InterviewResultsScreen()),
  "/liveAttendence": (_) => MaterialPage(child: LiveAttendence()),
  "/liveAttendance": (_) => MaterialPage(child: LiveAttendence()),
  "/campXLogin": (_) => MaterialPage(child: CampxLoginScreen()),
  "/portifolio": (_) => MaterialPage(child: PdfUpload()),
  "/resume-analyzer": (_) => MaterialPage(child: ResumeAnalyzerScreen()),
  "/nextUpdatePromo": (_) => MaterialPage(child: NextUpdatePromoScreen()),
  "/userInterviewDetails": (_) => MaterialPage(child: UserInterviewDetails()),
  "/opportunities": (_) => MaterialPage(child: OpportunitiesScreen()),
  "/opportunity/:id": (route) => MaterialPage(
        child: OpportunityDetailsScreen(
          opportunityId: route.pathParameters['id'] ?? '',
        ),
      ),
});
