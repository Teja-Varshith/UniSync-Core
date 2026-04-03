import 'package:UniSync/features/Carrer_Mode/portifolio_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:routemaster/routemaster.dart';
import 'package:UniSync/features/Carrer_Mode/home/career_home_screen.dart';
import 'package:UniSync/features/interview/view/user_interview_details.dart';

class CareerScreen extends ConsumerStatefulWidget {
  const CareerScreen({super.key});

  @override
  ConsumerState<CareerScreen> createState() => _CareerScreenState();
}

class _CareerScreenState extends ConsumerState<CareerScreen> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Scrollable Content
           Expanded(
             child: Container(
               color: Colors.black,
               child: screens[_page],
             ),
           ),
          ],
        ),
      ),
     bottomNavigationBar: SafeArea(
  top: false,
  child: Container(
    height: 72,
    color: const Color(0xFF111111),
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
            icon: Icons.work_outline,
            label: "Portfolio",
            index: 2,
          ),
        ],
      ),
    ),
  ),
),

     );
  }

  late final List<Widget> screens = [
     CareerHomeScreen(
       onTabChanged: (index) {
         setState(() {
           _page = index;
         });
       },
     ),
    //  CarrerInterviewScreen(),
    UserInterviewDetails(),
    PortfolioBuilder(),
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
            ? Colors.white
            : Colors.grey.shade600,
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
              ? Colors.white
              : Colors.grey.shade600,
            letterSpacing: 0.2,
          ),
        ),
      ],
    ),
  );
}

}
