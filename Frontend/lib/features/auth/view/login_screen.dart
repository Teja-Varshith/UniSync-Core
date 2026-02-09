import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lottie/lottie.dart';
import 'package:routemaster/routemaster.dart';
import 'package:unisync/app/providers.dart';
import 'package:unisync/features/auth/auth_controller.dart';
import 'package:unisync/features/auth/auth_repository.dart';
import 'package:unisync/features/auth/view/widget/carosel_item.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final ScrollController _row1 = ScrollController();
  final ScrollController _row2 = ScrollController();
  final ScrollController _row3 = ScrollController();

  bool isLoading = false;



  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoScroll(_row1, 0.6);
      _autoScroll(_row2, 0.8);
      _autoScroll(_row3, 0.4);
    });
  }

  void _autoScroll(ScrollController controller, double speed) async {
    while (controller.hasClients) {
      await Future.delayed(const Duration(milliseconds: 16));
      if (controller.hasClients) {
        controller.jumpTo(controller.offset + speed);
      }
    }
  }

  @override
  void dispose() {
    _row1.dispose();
    _row2.dispose();
    _row3.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final height = size.height;
    final width = size.width;

    // Calculate responsive login card height
    final loginCardHeight = height * 0.35; // ~35% of screen
    final carouselAreaHeight = height - loginCardHeight;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: Stack(
          children: [
            /// ================= BACKGROUND CAROUSELS =================
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: carouselAreaHeight,
              child: ShaderMask(
                shaderCallback: (rect) {
                  return const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black,
                      Colors.black,
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.1, 0.75, 1.0],
                  ).createShader(rect);
                },
                blendMode: BlendMode.dstIn,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SizedBox(
                      height: 110,
                      child: _buildCarouselRow(_row1, rotate: -0.04),
                    ),
                    SizedBox(
                      height: 110,
                      child: _buildCarouselRow(_row2, rotate: 0.04),
                    ),
                    SizedBox(
                      height: 110,
                      child: _buildCarouselRow(_row3, rotate: 0.06),
                    ),
                  ],
                ),
              ),
            ),

            /// ================= LOGIN CARD =================
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF222222),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.6),
                      blurRadius: 20,
                      spreadRadius: 5,
                      offset: const Offset(0, -10),
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.05),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                padding: EdgeInsets.fromLTRB(
                  width * 0.05,
                  height * 0.05,
                  width * 0.08,
                  height * 0.03,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black54)
                      ),
                      height: 60,
                      child: ClipOval(
                        child: Image.asset(
                          'assets/icons/Uni7.png'
                        ),
                      ),
                    ),
                    // const CarouselItem(imagePath: 'assets/icons/Uni7.png'),
                    SizedBox(height: height * 0.02),
                    Text(
                      'Everything college. Simplified.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: width * 0.065, // Responsive font size
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: height * 0.015),
                    Text(
                      'Sign in & dive into the future of tech.\nNo hassle, just innovation.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFFB3B3B3),
                        fontSize: width * 0.032, // Responsive font size
                        fontWeight: FontWeight.w600,
                      ),
                    ),


                    SizedBox(height: 4,),

                    Container(
                      
                      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white12, //  Color(0xFF2A2A2A),
          width: 1,
        ),
      ),
                      
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline_rounded,color: Colors.green,),
                            SizedBox(width: 3),
                            Text('Trusted by 3k+ students', style: TextStyle(color: Colors.white),),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: height * 0.01),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isLoading
                            ? null
                            : () async {
                                setState(() => isLoading = true);
                                final user = await ref
                                    .read(authControllerProvider)
                                    .signInWithGoogle();
                                if (user != null) {
                                  ref.read(userProvider.notifier).state = user;
                                }
                                setState(() => isLoading = false);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            vertical: height * 0.02,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: isLoading
                            ? const SizedBox()
                            : const Icon(Icons.rocket_launch, size: 20),
                        label: isLoading
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation(
                                            Colors.white),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Signing you in securely...',
                                    style: TextStyle(
                                      fontSize: width * 0.038,

                                      color: Colors.white,                                      
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                                ],
                              )
                            : Text(
                                'Continue with Google',
                                style: TextStyle(
                                  fontSize: width * 0.04,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= SINGLE CAROUSEL ROW =================
  Widget _buildCarouselRow(
    ScrollController controller, {
    required double rotate,
  }) {
     List<String> items = [
    'assets/icons/item1.svg',
    'assets/icons/item2.svg',
    'assets/icons/item3.svg',
    'assets/icons/item4.svg',
    'assets/icons/item5.svg',
    'assets/icons/item6.svg',
    'assets/icons/item7.svg',
  ];
    return ListView.builder(
      controller: controller,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 1000000, // fake infinity, real performance
      itemBuilder: (context, index) {
        int curr = index%items.length;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Transform.rotate(
            angle: rotate,
            child:  CarouselItem(
              imagePath: items[curr],
            ),
          ),
        );
      },
    );
  }
}