import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neopop/widgets/buttons/neopop_tilted_button/neopop_tilted_button.dart';
import 'package:unisync/app/providers.dart';
import 'package:unisync/features/auth/auth_controller.dart';
import 'package:unisync/features/auth/view/widget/carosel_item.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _row1 = ScrollController();
  final ScrollController _row2 = ScrollController();
  final ScrollController _row3 = ScrollController();

  bool isLoading = false;

  late final AnimationController _entryAnim;
  late final Animation<double> _cardFade;
  late final Animation<Offset> _cardSlide;

  static const List<String> _items = [
    'assets/icons/item1.svg',
    'assets/icons/item2.svg',
    'assets/icons/item3.svg',
    'assets/icons/item4.svg',
    'assets/icons/item5.svg',
    'assets/icons/item6.svg',
    'assets/icons/item7.svg',
  ];

  @override
  void initState() {
    super.initState();

    _entryAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _cardFade = CurvedAnimation(
      parent: _entryAnim,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    );

    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryAnim,
      curve: const Interval(0.1, 1.0, curve: Curves.easeOutCubic),
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _entryAnim.forward();
      _autoScroll(_row1, speed: 0.6, reverse: false);
      _autoScroll(_row2, speed: 0.8, reverse: true);
      _autoScroll(_row3, speed: 0.4, reverse: false);
    });
  }

  void _autoScroll(
    ScrollController controller, {
    required double speed,
    required bool reverse,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    if (!controller.hasClients) return;

    // Start each row at a different scroll position so images look different
    final max = controller.position.maxScrollExtent;
    if (reverse) {
      controller.jumpTo(max * 0.5);
    } else {
      controller.jumpTo(max * 0.25);
    }

    while (controller.hasClients) {
      await Future.delayed(const Duration(milliseconds: 16));
      if (!controller.hasClients) break;

      final currentMax = controller.position.maxScrollExtent;

      if (reverse) {
        final next = controller.offset - speed;
        controller.jumpTo(next <= 0 ? currentMax * 0.9 : next);
      } else {
        final next = controller.offset + speed;
        controller.jumpTo(next >= currentMax ? currentMax * 0.1 : next);
      }
    }
  }

  @override
  void dispose() {
    _row1.dispose();
    _row2.dispose();
    _row3.dispose();
    _entryAnim.dispose();
    super.dispose();
  }

  Widget _buildCarouselRow(
    ScrollController controller, {
    required double rotate,
    required int startOffset,
  }) {
    // Rotate the items list so each row starts on a different image
    final rotated = [
      ..._items.sublist(startOffset % _items.length),
      ..._items.sublist(0, startOffset % _items.length),
    ];

    return ListView.builder(
      controller: controller,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 1000000,
      itemBuilder: (context, index) {
        final curr = index % rotated.length;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Transform.rotate(
            angle: rotate,
            child: CarouselItem(imagePath: rotated[curr]),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final h = size.height;
    final w = size.width;

    final carouselHeight = h * 0.62;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        children: [
          // ── Carousel rows ──────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: carouselHeight,
            child: ShaderMask(
              shaderCallback: (rect) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black,
                  Colors.black,
                  Colors.transparent,
                ],
                stops: [0.0, 0.1, 0.72, 1.0],
              ).createShader(rect),
              blendMode: BlendMode.dstIn,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SizedBox(
                    height: 110,
                    child: _buildCarouselRow(
                      _row1,
                      rotate: -0.04,
                      startOffset: 0,
                    ),
                  ),
                  SizedBox(
                    height: 110,
                    child: _buildCarouselRow(
                      _row2,
                      rotate: 0.04,
                      startOffset: 3,
                    ),
                  ),
                  SizedBox(
                    height: 110,
                    child: _buildCarouselRow(
                      _row3,
                      rotate: 0.06,
                      startOffset: 5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Grain texture overlay ──────────────────────────────────────
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _GrainPainter()),
            ),
          ),

          // ── Dark gradient overlay (bottom-up) ─────────────────────────
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      const Color(0xFF0A0A0A).withOpacity(0.3),
                      const Color(0xFF0A0A0A).withOpacity(0.9),
                      const Color(0xFF0A0A0A),
                    ],
                    stops: const [0.0, 0.32, 0.52, 0.65],
                  ),
                ),
              ),
            ),
          ),

          // ── Login card ─────────────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SlideTransition(
              position: _cardSlide,
              child: FadeTransition(
                opacity: _cardFade,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                    border: Border(
                      top: BorderSide(
                        color: const Color(0xFFFFD700).withOpacity(0.18),
                        width: 1,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withOpacity(0.07),
                        blurRadius: 50,
                        spreadRadius: 0,
                        offset: const Offset(0, -12),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.9),
                        blurRadius: 30,
                        spreadRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.fromLTRB(
                    w * 0.07,
                    h * 0.028,
                    w * 0.07,
                    h * 0.048,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Drag pill
                      Container(
                        width: 36,
                        height: 3.5,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      SizedBox(height: h * 0.028),

                      // App icon with gold gradient ring
                      Container(
                        width: 68,
                        height: 68,
                        padding: const EdgeInsets.all(2.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFFFD700),
                              Color(0xFF7A5C00),
                              Color(0xFFFFD700),
                            ],
                            stops: [0.0, 0.5, 1.0],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFD700).withOpacity(0.35),
                              blurRadius: 22,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/icons/Uni7.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                      SizedBox(height: h * 0.022),

                      // Headline
                      Text(
                        'Everything college.\nSimplified.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: w * 0.072,
                          height: 1.1,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                          color: Colors.white,
                        ),
                      ),

                      SizedBox(height: h * 0.013),

                      // Subtext
                      Text(
                        'Sign in & dive into the future of tech.\nNo hassle, just innovation.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: w * 0.034,
                          fontWeight: FontWeight.w400,
                          height: 1.65,
                          color: Colors.white.withOpacity(0.38),
                        ),
                      ),

                      SizedBox(height: h * 0.02),

                      // Social proof chip
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFFFD700).withOpacity(0.22),
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.verified_rounded,
                              color: Color(0xFFFFD700),
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Trusted by 3,000+ students',
                              style: TextStyle(
                                fontSize: w * 0.032,
                                fontWeight: FontWeight.w600,
                                color:
                                    const Color(0xFFFFD700).withOpacity(0.85),
                                letterSpacing: 0.1,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: h * 0.026),

                      // CTA button
                      SizedBox(
                        width: double.infinity,
                        child: NeoPopTiltedButton(
                          isFloating: true,
                          onTapUp: isLoading
                              ? null
                              : () async {
                                  setState(() => isLoading = true);
                                  final user = await ref
                                      .read(authControllerProvider)
                                      .signInWithGoogle();
                                  if (user != null) {
                                    ref.read(userProvider.notifier).state =
                                        user;
                                  }
                                  if (mounted) {
                                    setState(() => isLoading = false);
                                  }
                                },
                          decoration: const NeoPopTiltedButtonDecoration(
                            color: Color(0xFFFFD700),
                            plunkColor: Color(0xFF7A5C00),
                            shadowColor: Color(0xFF1A1200),
                            showShimmer: true,
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: h * 0.019),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (isLoading)
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor:
                                          AlwaysStoppedAnimation(Colors.black),
                                    ),
                                  )
                                else ...[
                                  Text(
                                    'Get Started',
                                    style: TextStyle(
                                      fontSize: w * 0.048,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.black,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Colors.black,
                                    size: 20,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: h * 0.016),

                      Text(
                        'By continuing, you agree to our Terms & Privacy Policy.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: w * 0.027,
                          color: Colors.white.withOpacity(0.2),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Subtle static film grain ─────────────────────────────────────────────────
class _GrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.025);
    for (int i = 0; i < 1400; i++) {
      final x = (i * 73.137 + 11.3) % size.width;
      final y = (i * 41.719 + 7.9) % size.height;
      canvas.drawCircle(Offset(x, y), 0.55, paint);
    }
  }

  @override
  bool shouldRepaint(_GrainPainter old) => false;
}
