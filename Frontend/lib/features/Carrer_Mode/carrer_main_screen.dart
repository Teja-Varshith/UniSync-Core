import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:icons_flutter/icons_flutter.dart';
import 'package:routemaster/routemaster.dart';
import 'package:unisync/app/providers.dart';
import 'package:unisync/features/Campus_Mode/view/home_screen.dart';
import 'package:unisync/features/Carrer_Mode/home/career_home_screen.dart';
import 'package:unisync/features/Carrer_Mode/interview/view/interview_results_screen.dart';
import 'package:unisync/features/Carrer_Mode/interview/view/user_interview_details.dart';
import 'package:unisync/features/Carrer_Mode/sub_views/carrer_card_screen.dart';
import 'package:unisync/features/Carrer_Mode/interview/view/carrer_interview_screen.dart';
import 'package:unisync/features/Carrer_Mode/sub_views/carrer_resume_screen.dart';
import 'package:unisync/features/services/appMode.dart';

class CareerScreen extends ConsumerStatefulWidget {
  const CareerScreen({super.key});

  @override
  ConsumerState<CareerScreen> createState() => _CareerScreenState();
}

class _CareerScreenState extends ConsumerState<CareerScreen> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Scrollable Content
           Expanded(child: screens[_page]),
          ],
        ),
      ),
     bottomNavigationBar: SafeArea(
  top: false,
  child: Container(
    height: 72,
    color: Colors.white,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            icon: Icons.home_rounded,
            label: "Home",
            index: 0,
          ),
          _buildNavItem(
            icon: Icons.graphic_eq_rounded,
            label: "Interviews",
            index: 1,
          ),
          _buildNavItem(
            icon: Icons.layers_outlined,
            label: "Cards",
            index: 2,
          ),
          _buildNavItem(
            icon: Icons.description_outlined,
            label: "Resumes",
            index: 3,
          ),
        ],
      ),
    ),
  ),
),

     );
  }

  List<Widget> screens = [
     CareerHomeScreen(),
    //  CarrerInterviewScreen(),
    UserInterviewDetails(),
     CarrerResumeScreen(),

     CarrerCardScreen()
  ];





Widget _buildNavItem({
  required IconData icon,
  required String label,
  required int index,
  bool push = false,
}) {
  final bool isActive = _page == index;

  return GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: () {
      if(push == false){
      setState(() => _page = index);
      }else{
        Routemaster.of(context).push('/carrer-interview-screen');
      }
    }
    ,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 26,
          color: isActive
              ? const Color(0xFF6C5CE7)
              : Colors.grey.shade400,
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive
                ? FontWeight.w600
                : FontWeight.w400,
            color: isActive
                ? const Color(0xFF6C5CE7)
                : Colors.grey.shade400,
            letterSpacing: 0.2,
          ),
        ),
      ],
    ),
  );
}

}
