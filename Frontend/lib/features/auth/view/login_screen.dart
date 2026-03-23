import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neopop/neopop.dart';
import 'package:UniSync/app/providers.dart';
import 'package:UniSync/constants/constant.dart';
import 'package:UniSync/features/auth/auth_controller.dart';

final playStoreReviewerAccessProvider = StreamProvider<bool>((ref) {
  if (PLAYSTORE_REVIEWER_UID.trim().isEmpty) {
    return Stream<bool>.value(false);
  }

  final firestore = ref.watch(firebaseFirestoreProvider);

  return firestore
      .collection('config')
      .doc('reviewer_access')
      .snapshots()
      .map((snapshot) {
        final data = snapshot.data();
        if (data == null) return false;
        return data['enabled'] == true;
      });
});


class _WordCloudBackground extends StatefulWidget {
  const _WordCloudBackground();

  @override
  State<_WordCloudBackground> createState() => _WordCloudBackgroundState();
}

class _WordCloudBackgroundState extends State<_WordCloudBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  // ── CONFIGURE YOUR HIGHLIGHTS HERE ──────────────────────────────────
  static const List<_WordDef> _highlightWords = [
_WordDef('INNOVATE', xFrac: 0.10, yFrac: 0.04, size: 22, angleDeg: -4.0, color: const Color(0xFFFFD72F)),
_WordDef('LAUNCH',   xFrac: 0.62, yFrac: 0.08, size: 20, angleDeg:  3.5, color: Colors.white),

// brand anchor
_WordDef('UNISYNC',  xFrac: 0.30, yFrac: 0.20, size: 30, angleDeg: -2.5, color: Colors.white),

// main highlights
_WordDef('CREATE',   xFrac: 0.08, yFrac: 0.38, size: 30, angleDeg: -2.5, color: const Color(0xFFFFD72F)),
_WordDef('CONNECT',  xFrac: 0.68, yFrac: 0.35, size: 28, angleDeg:  3.0, color: const Color(0xFFFFD72F)),
_WordDef('BUILD',    xFrac: 0.35, yFrac: 0.55, size: 26, angleDeg: -1.5, color: const Color(0xFFFFD72F)),

// secondary highlight
_WordDef('EXPLORE',  xFrac: 0.54, yFrac: 0.44, size: 24, angleDeg:  2.0, color: Colors.white),

// closing highlight
_WordDef('GROW',     xFrac: 0.40, yFrac: 0.70, size: 26, angleDeg: -3.0, color: const Color(0xFFFFD72F)),
  ];
  // ─────────────────────────────────────────────────────────────────────

  static const List<_WordDef> _noiseWords = [
    // — top zone (was empty before)
    _WordDef('HACKATHON',   xFrac: 0.04, yFrac: 0.02, size: 11, angleDeg:  2.0),
    _WordDef('STARTUP',     xFrac: 0.28, yFrac: 0.00, size: 10, angleDeg: -3.0),
    _WordDef('OPENSOURCE',  xFrac: 0.50, yFrac: 0.03, size:  9, angleDeg:  1.5),
    _WordDef('DEVS',        xFrac: 0.76, yFrac: 0.01, size: 11, angleDeg: -2.5),
    _WordDef('COLLAB',      xFrac: 0.88, yFrac: 0.05, size: 10, angleDeg:  3.0),
    _WordDef('ITERATE',     xFrac: 0.38, yFrac: 0.12, size: 10, angleDeg: -1.5),
    _WordDef('PITCH',       xFrac: 0.82, yFrac: 0.10, size: 11, angleDeg:  2.5),
    // — mid / bottom (unchanged words, now with tilt)
    _WordDef('PROJECTS',    xFrac: 0.62, yFrac: 0.04, size: 10, angleDeg:  1.0),
    _WordDef('IDEAS',       xFrac: 0.78, yFrac: 0.08, size: 13, angleDeg: -2.0),
    _WordDef('COMMUNITY',   xFrac: 0.88, yFrac: 0.02, size: 11, angleDeg:  3.5),
    _WordDef('CREATORS',    xFrac: 0.02, yFrac: 0.16, size: 11, angleDeg: -1.0),
    _WordDef('TECH',        xFrac: 0.14, yFrac: 0.20, size: 12, angleDeg:  2.0),
    _WordDef('DEV',         xFrac: 0.24, yFrac: 0.14, size: 10, angleDeg: -3.5),
    _WordDef('COLLAB',      xFrac: 0.45, yFrac: 0.17, size: 11, angleDeg:  1.5),
    _WordDef('NETWORK',     xFrac: 0.58, yFrac: 0.13, size: 13, angleDeg: -2.0),
    _WordDef('SHIP',        xFrac: 0.70, yFrac: 0.19, size: 10, angleDeg:  3.0),
    _WordDef('MENTORS',     xFrac: 0.91, yFrac: 0.22, size: 11, angleDeg: -1.5),
    _WordDef('INTERNS',     xFrac: 0.06, yFrac: 0.30, size: 12, angleDeg:  2.5),
    _WordDef('PORTFOLIO',   xFrac: 0.22, yFrac: 0.27, size: 10, angleDeg: -2.0),
    _WordDef('SKILLS',      xFrac: 0.48, yFrac: 0.29, size: 11, angleDeg:  1.0),
    _WordDef('LEARN',       xFrac: 0.68, yFrac: 0.31, size: 10, angleDeg: -3.0),
    _WordDef('BUILDERS',    xFrac: 0.85, yFrac: 0.26, size: 12, angleDeg:  2.0),
    _WordDef('EVENTS',      xFrac: 0.03, yFrac: 0.50, size: 11, angleDeg: -1.5),
    _WordDef('CLUBS',       xFrac: 0.18, yFrac: 0.53, size: 10, angleDeg:  3.0),
    _WordDef('FRIENDS',     xFrac: 0.29, yFrac: 0.47, size: 12, angleDeg: -2.5),
    _WordDef('CREATIVE',    xFrac: 0.82, yFrac: 0.50, size: 11, angleDeg:  1.5),
    _WordDef('FOCUS',       xFrac: 0.91, yFrac: 0.55, size: 10, angleDeg: -2.0),
    _WordDef('GOALS',       xFrac: 0.05, yFrac: 0.62, size: 10, angleDeg:  2.5),
    _WordDef('NETWORKING',  xFrac: 0.20, yFrac: 0.67, size: 12, angleDeg: -1.0),
    _WordDef('ASSIGNMENTS', xFrac: 0.44, yFrac: 0.68, size: 11, angleDeg:  3.0),
    _WordDef('SCHEDULE',    xFrac: 0.65, yFrac: 0.63, size: 10, angleDeg: -2.0),
    _WordDef('PEERS',       xFrac: 0.80, yFrac: 0.68, size: 12, angleDeg:  1.5),
    _WordDef('WORKSHOPS',   xFrac: 0.25, yFrac: 0.79, size: 10, angleDeg: -3.0),
    _WordDef('COMMUNITY',   xFrac: 0.50, yFrac: 0.77, size: 12, angleDeg:  2.0),
    _WordDef('PORTFOLIO',   xFrac: 0.72, yFrac: 0.80, size: 11, angleDeg: -1.5),
    _WordDef('CAREER',      xFrac: 0.18, yFrac: 0.91, size: 12, angleDeg:  3.5),
    _WordDef('FUTURE',      xFrac: 0.40, yFrac: 0.89, size: 11, angleDeg: -2.0),
    _WordDef('CREATORS',    xFrac: 0.62, yFrac: 0.92, size: 10, angleDeg:  1.0),
    _WordDef('SKILLS',      xFrac: 0.80, yFrac: 0.87, size: 12, angleDeg: -3.5),
  ];

  // radians conversion done once at use-site to keep consts clean
  static double _deg2rad(double deg) => deg * 0.017453292519943295;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  double _carouselHeight(Size size) => size.height * 0.65;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final areaH = _carouselHeight(size);

    return ShaderMask(
      shaderCallback: (rect) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          Colors.black,
          Colors.black,
          Colors.transparent,
        ],
        stops: [0.0, 0.12, 0.72, 1.0],
      ).createShader(rect),
      blendMode: BlendMode.dstIn,
      child: Stack(
        children: [
          // ── NOISE — fully static, zero rebuild cost
          for (final w in _noiseWords)
            Positioned(
              left: w.xFrac * size.width,
              top: w.yFrac * areaH,
              child: Transform.rotate(
                angle: _deg2rad(w.angleDeg),
                alignment: Alignment.centerLeft,
                child: Text(
                  w.label,
                  style: TextStyle(
                    fontSize: w.size.toDouble(),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: Colors.white.withValues(alpha: 0.07),
                  ),
                ),
              ),
            ),

          // ── HIGHLIGHTS — staggered pulse, single controller
          for (int i = 0; i < _highlightWords.length; i++)
            Positioned(
              left: _highlightWords[i].xFrac * size.width,
              top: _highlightWords[i].yFrac * areaH,
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (_, __) {
                  final t = ((_pulse.value + i * (1.0 / _highlightWords.length)) % 1.0);
                  final opacity = 0.6 + 0.4 * Curves.easeInOut.transform(
                    t < 0.5 ? t * 2 : (1.0 - t) * 2,
                  );
                  return Opacity(
                    opacity: opacity,
                    child: Transform.rotate(
                      angle: _deg2rad(_highlightWords[i].angleDeg),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _highlightWords[i].label,
                        style: TextStyle(
                          fontSize: _highlightWords[i].size.toDouble(),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: _highlightWords[i].color ?? UniSyncColors.accent,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

@immutable
class _WordDef {
  final String label;
  final double xFrac;
  final double yFrac;
  final int size;
  final double angleDeg; // positive = clockwise tilt, negative = counter-clockwise
  final Color? color;

  const _WordDef(
    this.label, {
    required this.xFrac,
    required this.yFrac,
    required this.size,
    this.angleDeg = 0.0,
    this.color,
  });
}
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class NeoPopLogoButton extends StatefulWidget {
  final VoidCallback? onPressed;

  const NeoPopLogoButton({super.key, this.onPressed});

  @override
  State<NeoPopLogoButton> createState() => _NeoPopLogoButtonState();
}

class _NeoPopLogoButtonState extends State<NeoPopLogoButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pressAnimation;

  static const double _size = 70.0;
  static const double _shadowOffsetX = 5.0;
  static const double _shadowOffsetY = 5.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 150),
    );
    _pressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _controller.forward();

  void _onTapUp(TapUpDetails _) async {
    HapticFeedback.mediumImpact();
    await _controller.reverse();
    widget.onPressed?.call();
  }

  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _pressAnimation,
        builder: (context, _) {
          final press = _pressAnimation.value;

          // Default: face is at (0,0) — shadow peeks at bottom-right
          // Pressed: face moves TO the shadow offset — covers it
          final faceLeft = press * _shadowOffsetX;
          final faceTop = press * _shadowOffsetY;

          return SizedBox(
            width: _size + _shadowOffsetX,
            height: _size + _shadowOffsetY,
            child: Stack(
              children: [
                // ── SHADOW — fixed bottom-right, always visible by default
                Positioned(
                  left: _shadowOffsetX,
                  top: _shadowOffsetY,
                  child: Container(
                    width: _size,
                    height: _size,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF8A8A8A),
                    ),
                  ),
                ),

                // ── TOP FACE — starts at (0,0), slides into shadow on press
                Positioned(
                  left: faceLeft,
                  top: faceTop,
                  child: Container(
                    width: _size,
                    height: _size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(
                        color: const Color(0xFFDDDDDD),
                        width: 1,
                      ),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/icons/UniSync1.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class VerticalWordColumn extends StatelessWidget {
  final List<String> words;

  const VerticalWordColumn({super.key, required this.words});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: words.map((word) {
        final highlight =
            word == "SYNC" || word == "UNI" || word == "EXAMS";

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            word,
            style: TextStyle(
              color: highlight
                  ? UniSyncColors.accent
                  : UniSyncColors.textMuted.withValues(alpha: 0.2),
              fontWeight: highlight ? FontWeight.w700 : FontWeight.w400,
              fontSize: 22,
            ),
          ),
        );
      }).toList(),
    );
  }
}





class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool isLoading = false;
  bool isReviewerLoading = false;
  final List<String> headlineTexts = [
    'Everything college. Simplified.',
    'The only College Companion you need.',
    'Networking, Growth, Projects all at one Place.',
    'One app for your college journey.',
  ];
  int activeHeadlineIndex = 0;

  void _showNextHeadline() {
    setState(() {
      activeHeadlineIndex = (activeHeadlineIndex + 1) % headlineTexts.length;
    });
  }

  bool get _hasReviewerAccess => PLAYSTORE_REVIEWER_UID.trim().isNotEmpty;



  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final height = size.height;
    final width = size.width;
    final textTheme = Theme.of(context).textTheme;
    final reviewerAccessToggle = ref.watch(playStoreReviewerAccessProvider);
    final reviewerAccessEnabled =
        reviewerAccessToggle.maybeWhen(data: (enabled) => enabled, orElse: () => false);

    // Calculate responsive login card height
    final loginCardHeight = height * 0.35; // ~35% of screen
    final carouselAreaHeight = height - loginCardHeight;

    return Scaffold(
      backgroundColor: UniSyncColors.backgroundPrimary,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
  top: 0,
  left: 0,
  right: 0,
  height: carouselAreaHeight,
  child: _WordCloudBackground(),
),
            /// ================= LOGIN CARD =================
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: UniSyncColors.surfaceCard,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 20,
                      spreadRadius: 5,
                      offset: const Offset(0, -10),
                    ),
                    BoxShadow(
                      color: UniSyncColors.borderSubtle.withValues(alpha: 0.6),
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

                    NeoPopLogoButton(
                      onPressed: _showNextHeadline,
                    ),
                    // Container(
                    //   decoration: BoxDecoration(
                    //     shape: BoxShape.circle,
                    //     border: Border.all(color: UniSyncColors.borderSubtle)
                    //   ),
                    //   height: 70,
                    //   child: ClipOval(
                    //     child: Image.asset(
                    //       'assets/icons/UniSync1.png'
                    //     ),
                    //   ),
                    // ),

                    // const CarouselItem(imagePath: 'assets/icons/Uni7.png'),
                    SizedBox(height: height * 0.02),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.18),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: Text(
                        headlineTexts[activeHeadlineIndex],
                        key: ValueKey(headlineTexts[activeHeadlineIndex]),
                        textAlign: TextAlign.center,
                        style: textTheme.headlineSmall?.copyWith(
                          color: UniSyncColors.textPrimary,
                          fontSize: width * 0.065, // Responsive font size
                          height: 1.2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    SizedBox(height: height * 0.015),
                    // Sign in text
Text(
  'Sign in & dive into newer experiences.\nNo hassle, just innovation.',
  textAlign: TextAlign.center,
  style: textTheme.bodyMedium?.copyWith(
    color: UniSyncColors.textMuted,
    fontSize: width * 0.032,
    fontWeight: FontWeight.w400, // lighter feels softer
    height: 1.5,                 // breathe between lines
    letterSpacing: 0.1,
  ),
),

const SizedBox(height: 10),

// Badge
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [
        UniSyncColors.success.withOpacity(0.12),
        UniSyncColors.success.withOpacity(0.04),
      ],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ),
    borderRadius: BorderRadius.circular(24),
    border: Border.all(
      color: UniSyncColors.success.withOpacity(0.4),
      width: 1,
    ),
  ),
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  child: Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFFFD72F).withOpacity(0.12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD72F).withOpacity(0.45),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: const Icon(
        Icons.favorite,
        size: 11,
        color: Color(0xFFFFD72F),
      ),
    ),

    const SizedBox(width: 8),

    Text(
      'Loved by 5k+ students',
      style: textTheme.bodySmall?.copyWith(
        color: Colors.white.withOpacity(0.85),
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        fontSize: width * 0.030,
      ),
    ),
  ],
)
),
                    SizedBox(height: height * 0.01),

                    SizedBox(
                      width: double.infinity,
                      child: NeoPopButton(
                        color: UniSyncColors.backgroundPrimary,
                        
                        bottomShadowColor: UniSyncColors.border,
                        rightShadowColor: UniSyncColors.borderSubtle,
                        depth: 6,
                        parentColor: Colors.transparent,
                        buttonPosition: Position.fullBottom,
                        enabled: !isLoading,
                        onTapDown: () => HapticFeedback.selectionClick(),
                        onTapUp: () async {
                          if (isLoading) {
                            return;
                          }
                          setState(() => isLoading = true);
                          final user = await ref
                              .read(authControllerProvider)
                              .signInWithGoogle();
                          if (user != null) {
                            ref.read(userProvider.notifier).state = user;
                          }
                          if (mounted) {
                            setState(() => isLoading = false);
                          }
                        },
                        border: Border.all(
                          color: Colors.white,//UniSyncColors.buttonPrimaryStroke,
                          width: 1.5,
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: height * 0.02,
                            horizontal: 14,
                          ),
                          child: Center(
                            child: isLoading
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation(
                                              UniSyncColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Signing you in securely...',
                                        style: TextStyle(
                                          fontSize: width * 0.038,
                                          color: UniSyncColors.textPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.rocket_launch,
                                        size: 20,
                                        color: UniSyncColors.textPrimary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Continue with Google',
                                        style: TextStyle(
                                          fontSize: width * 0.04,
                                          fontWeight: FontWeight.w700,
                                          color: UniSyncColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                    if (_hasReviewerAccess && reviewerAccessEnabled) ...[
                      SizedBox(height: height * 0.014),
                      Text(
                        'Use below signin option(temporary) for playstore review if you cant use google signin',
                        textAlign: TextAlign.center,
                        style: textTheme.bodySmall?.copyWith(
                          color: UniSyncColors.textMuted,
                          fontSize: width * 0.029,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: NeoPopButton(
                          color: UniSyncColors.surfaceElevated,
                          bottomShadowColor: UniSyncColors.accent,
                          rightShadowColor: UniSyncColors.accent,
                          depth: 5,
                          parentColor: Colors.transparent,
                          buttonPosition: Position.fullBottom,
                          enabled: !isLoading && !isReviewerLoading,
                          onTapDown: () => HapticFeedback.selectionClick(),
                          onTapUp: () async {
                            if (isLoading || isReviewerLoading) {
                              return;
                            }
                            setState(() => isReviewerLoading = true);
                            final user = await ref
                                .read(authControllerProvider)
                                .signInAsReviewer(PLAYSTORE_REVIEWER_UID);
                            if (user != null) {
                              ref.read(userProvider.notifier).state = user;
                            }
                            if (mounted) {
                              setState(() => isReviewerLoading = false);
                            }
                          },
                          border: Border.all(
                            color: UniSyncColors.border,
                            width: 1.2,
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: height * 0.018,
                              horizontal: 14,
                            ),
                            child: Center(
                              child: isReviewerLoading
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation(
                                              UniSyncColors.accent,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Opening reviewer access...',
                                          style: TextStyle(
                                            fontSize: width * 0.036,
                                            color: UniSyncColors.textPrimary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.visibility_outlined,
                                          size: 18,
                                          color: UniSyncColors.accent,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Reviewer Access',
                                          style: TextStyle(
                                            fontSize: width * 0.038,
                                            fontWeight: FontWeight.w700,
                                            color: UniSyncColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
