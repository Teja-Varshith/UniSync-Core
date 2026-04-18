import 'dart:math';
import 'dart:math' as Math;
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:iconsax/iconsax.dart';
import 'package:neopop/neopop.dart';
import 'package:routemaster/routemaster.dart';
import 'package:UniSync/ads%20Manager/add_manager.dart';
import 'package:UniSync/app/providers.dart';
import 'package:UniSync/app/theme/app_colors.dart';
import 'package:UniSync/constants/constant.dart';
import 'package:UniSync/features/attendance/repository/attendance_repository.dart';
import 'package:UniSync/features/attendance/controller/attendance_controller.dart';
import 'package:UniSync/features/attendance/view/subject_detail_screen.dart';
import 'package:UniSync/features/coins/coin_purchase_service.dart';
import 'package:UniSync/firebase_service.dart';
import 'package:UniSync/models/course_model.dart';

_AttendancePalette _ui(BuildContext context) => _AttendancePalette.of(context);

class _AttendancePalette {
  _AttendancePalette({
    required this.isDark,
    required this.backgroundPrimary,
    required this.backgroundSecondary,
    required this.surfaceCard,
    required this.surfaceElevated,
    required this.divider,
    required this.border,
    required this.borderSubtle,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textDisabled,
    required this.accent,
    required this.accentSoft,
    required this.buttonPrimaryFg,
    required this.success,
    required this.warning,
    required this.error,
  });

  final bool isDark;
  final Color backgroundPrimary;
  final Color backgroundSecondary;
  final Color surfaceCard;
  final Color surfaceElevated;
  final Color divider;
  final Color border;
  final Color borderSubtle;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textDisabled;
  final Color accent;
  final Color accentSoft;
  final Color buttonPrimaryFg;
  final Color success;
  final Color warning;
  final Color error;

  factory _AttendancePalette.of(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return _AttendancePalette(
      isDark: isDark,
      backgroundPrimary: isDark ? AppColors.darkBg : AppColors.lightBg,
      backgroundSecondary: isDark ? AppColors.darkSurface : AppColors.lightCardAlt,
      surfaceCard: isDark ? AppColors.darkCard : AppColors.lightCard,
      surfaceElevated: isDark ? AppColors.darkCardAlt : AppColors.lightSurface,
      divider: isDark
          ? AppColors.darkBorder.withValues(alpha: 0.9)
          : AppColors.lightBorder.withValues(alpha: 0.9),
      border: isDark ? AppColors.darkBorder : AppColors.lightBorder,
      borderSubtle: isDark
          ? AppColors.darkBorder.withValues(alpha: 0.8)
          : AppColors.lightBorder.withValues(alpha: 0.8),
      textPrimary: theme.colorScheme.onSurface,
      textSecondary: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
      textMuted: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
      textDisabled: isDark
          ? AppColors.darkTextMuted.withValues(alpha: 0.7)
          : AppColors.lightTextMuted.withValues(alpha: 0.8),
      accent: AppColors.primary,
      accentSoft: AppColors.primary.withValues(alpha: 0.14),
      buttonPrimaryFg: theme.colorScheme.onPrimary,
      success: AppColors.success,
      warning: AppColors.warning,
      error: theme.colorScheme.error,
    );
  }
}

class LiveAttendence extends ConsumerStatefulWidget {
  LiveAttendence({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _LiveAttendenceState();
}

class _LiveAttendenceState extends ConsumerState<LiveAttendence>
    with SingleTickerProviderStateMixin {
  static const double _stickyBannerHeight = 50;

Future<void> _openInfoQueryPageHere() async {

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: _ui(context).backgroundSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _ui(context).accent.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.info_outline_rounded,
                    color: _ui(context).accent,
                    size: 20,
                  ),
                ),
                SizedBox(height: 14),
                Text(
                  'Help?',
                  style: TextStyle(
                    color: _ui(context).textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _ui(context).surfaceCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _ui(context).accent.withOpacity(0.13)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '• Only CampX-supported colleges are eligible to use this feature.',
                        style: TextStyle(
                          color: _ui(context).textPrimary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        '• You must use your CampX username and password to connect.',
                        style: TextStyle(
                          color: _ui(context).textPrimary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        '• We do NOT store any of your CampX credentials or personal information. All sensitive data stays only on your device.',
                        style: TextStyle(
                          color: _ui(context).textPrimary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: _ui(context).accent,
                      foregroundColor: _ui(context).buttonPrimaryFg,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Got it',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  // ── logic fields unchanged ─────────────────────────────────────────────────
  double _targetPercentage = 75.0;
  List attendanceData = [];
  bool isLoading = false;
  bool _checkingSession = true;
  bool _campxConnected = false;
  bool _isConnectingCampX = false;
  bool _hideCampXPassword = true;
  final TextEditingController _campxUsernameController =
      TextEditingController();
  final TextEditingController _campxPasswordController =
      TextEditingController();
  bool _promoCardDismissed = false;
  bool _isPurchasingAdFree = false;
  bool _hasLoggedAttendanceScreen = false;

  bool get _hasAdFreeAccess =>
      ref.read(userProvider)?.hasAdFreeAccess ?? AdManager.instance.isAdFree;

  double _floorToDecimals(double value, int decimals) {
    final factor = pow(10, decimals).toDouble();
    return (value * factor).floorToDouble() / factor;
  }

  String _formatPctFloor(double value, {int decimals = 2}) {
    return _floorToDecimals(value, decimals).toStringAsFixed(decimals);
  }

  String _getSavageMessage(AttendanceCalculation calc, bool isGood) {
    if (isGood) {
      return [
        'Chill bro, inka konchem bunk safe 😎',
        'Professor ki favourite student vibes 👀',
        "Attendance overloaded with extra credits 💯",
      ][Math.Random().nextInt(3)];
    } else {
      return [
        'Ayyayyo... danger zone lo unnav 💀',
        'Inka bunk chesthe semester ki bye bye 👋',
        'Attendance chusi lecturer kuda shock avtadu 😭',
      ][Math.Random().nextInt(3)];
    }
  }

  String _getCoolStatus() {
    final list = ['Chill Mode 😎', 'Safe Zone 🔥', 'Mass Attendance 💯'];
    return list[Math.Random().nextInt(list.length)];
  }

  String _getDangerStatus() {
    final list = ['Red Alert 🚨', 'Ela Ila..... 💀', 'Sem Danger 😭', 'kastamee 🚨'];
    return list[Math.Random().nextInt(list.length)];
  }

  String _getMidStatus() {
    final list = ['Careful ra abbai😐', 'Border lo unnav ⚠️', 'Balance cheyyali 👀'];
    return list[Math.Random().nextInt(list.length)];
  }

  void _showAwesomeMessage({
    required String title,
    required String message,
    required ContentType type,
  }) {
    final messenger = rootScaffoldMessengerKey.currentState;
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          content: AwesomeSnackbarContent(
            title: title,
            message: message,
            contentType: type,
          ),
        ),
      );
  }

  String _mapCampXErrorToMessage(Object error) {
    final raw = error.toString().replaceFirst('Exception: ', '').toLowerCase();
    if (raw.contains('invalid') ||
        raw.contains('credential') ||
        raw.contains('username') ||
        raw.contains('password') ||
        raw.contains('401') ||
        raw.contains('403') ||
        raw.contains('unauthorized') ||
        raw.contains('forbidden')) {
      return 'Invalid CampX credentials. Recheck your username and password and try again.';
    }
    if (raw.contains('timeout') ||
        raw.contains('socket') ||
        raw.contains('network') ||
        raw.contains('connection')) {
      return 'Network issue detected. Please check your internet and retry.';
    }
    if (raw.contains('500') ||
        raw.contains('502') ||
        raw.contains('503') ||
        raw.contains('504') ||
        raw.contains('server')) {
      return 'CampX is having trouble right now. Please try again in a minute.';
    }
    return 'Invalid Credentials please confirm or reset your credentials.';
  }

  @override
  void initState() {
    super.initState();
    _bootstrapCampXConnection();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_hasLoggedAttendanceScreen) return;
      _hasLoggedAttendanceScreen = true;
      FirebaseService.logScreenView(screenName: 'attendance_screen');
      FirebaseService.logFeatureUsage('attendance');
    });
  }

  @override
  void dispose() {
    _campxUsernameController.dispose();
    _campxPasswordController.dispose();
    super.dispose();
  }

  Future<void> _bootstrapCampXConnection() async {
    setState(() => _checkingSession = true);
    await FirebaseService.logEvent(name: 'attendance_session_bootstrap_started');
    final connected = await ref
        .read(AttendanceRepositoryProvider)
        .ensureCampXSession(allowRelogin: true);
    if (!mounted) return;
    setState(() {
      _campxConnected = connected;
      _checkingSession = false;
    });
    await FirebaseService.logEvent(
      name: 'attendance_session_bootstrap_result',
      parameters: {'connected': connected.toString()},
    );
    if (connected) ref.invalidate(attendanceProvider);
  }

  Future<void> _disconnectCampX() async {
    await ref.read(AttendanceRepositoryProvider).disconnectCampX();
    if (!mounted) return;
    setState(() => _campxConnected = false);
    ref.invalidate(attendanceProvider);
    _showAwesomeMessage(
      title: 'CampX disconnected',
      message: 'Your session was removed from this device.',
      type: ContentType.warning,
    );
    await FirebaseService.logEvent(name: 'campx_disconnected');
  }

  Future<void> _submitCampXInlineConnect() async {
    final username = _campxUsernameController.text.trim();
    final password = _campxPasswordController.text;
    if (username.isEmpty || password.isEmpty) {
      _showAwesomeMessage(
        title: 'Missing fields',
        message: 'Enter both CampX username and password.',
        type: ContentType.warning,
      );
      return;
    }
    setState(() => _isConnectingCampX = true);
    await FirebaseService.logEvent(name: 'campx_connect_started');
    try {
      await ref
          .read(AttendanceRepositoryProvider)
          .completeCampXLogin(username, password);
      if (!mounted) return;
      setState(() {
        _campxConnected = true;
        _isConnectingCampX = false;
      });
      ref.invalidate(attendanceProvider);
      _showAwesomeMessage(
        title: 'Connected',
        message: 'CampX connected successfully.',
        type: ContentType.success,
      );
      await FirebaseService.logEvent(name: 'campx_connected');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isConnectingCampX = false);
      _showAwesomeMessage(
        title: 'Connection failed',
        message: _mapCampXErrorToMessage(e),
        type: ContentType.failure,
      );
      await FirebaseService.logEvent(name: 'campx_connect_failed');
    }
  }

  Future<void> _confirmAndDisconnectCampX() async {
    final shouldDisconnect = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: _ui(context).backgroundSecondary,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Red icon header
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _ui(context).error.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: _ui(context).error.withOpacity(0.3)),
                ),
                child: Icon(Icons.link_off_rounded,
                    color: _ui(context).error, size: 20),
              ),
              SizedBox(height: 14),
              Text(
                'Disconnect CampX?',
                style: TextStyle(
                  color: _ui(context).textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'You will have to enter your credentials again to view attendance.',
                style: TextStyle(
                  color: _ui(context).textSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _ui(context).textSecondary,
                        side: BorderSide(color: _ui(context).border),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text('Cancel',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: NeoPopButton(
                      color: _ui(context).error,
                      bottomShadowColor: _ui(context).error.withValues(alpha: 0.55),
                      rightShadowColor: _ui(context).error.withValues(alpha: 0.55),
                      depth: 3,
                      onTapUp: () => Navigator.of(context).pop(true),
                      onTapDown: () {},
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: Text('Disconnect',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              )),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (shouldDisconnect == true) await _disconnectCampX();
  }

  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _buyAdFreeAccess() async {
    if (_isPurchasingAdFree || _hasAdFreeAccess) return;
    await FirebaseService.logEvent(name: 'attendance_ad_free_cta_tapped');

    setState(() => _isPurchasingAdFree = true);

    try {
      final error = await ref.read(coinPurchaseServiceProvider).buyAdFreeAccess();

      if (!mounted) return;

      if (error != null) {
        _showAwesomeMessage(
          title: 'Purchase unavailable',
          message: error,
          type: ContentType.failure,
        );
        return;
      }
    } finally {
      if (mounted) {
        setState(() => _isPurchasingAdFree = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final attedanceAsync = ref.watch(attendanceProvider);
    final hasAdFreeAccess =
        ref.watch(userProvider)?.hasAdFreeAccess ?? AdManager.instance.isAdFree;
    final stickyBannerOverlayHeight =
        _stickyBannerHeight + MediaQuery.of(context).padding.bottom;

    if (_checkingSession) {
      return Scaffold(
        backgroundColor: _ui(context).backgroundPrimary,
        body: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: _ui(context).accent,
            ),
          ),
        ),
      );
    }

    if (!_campxConnected) {
      return _buildNotConnectedScreen();
    }

    return Scaffold(
      backgroundColor: _ui(context).backgroundPrimary,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                _appBar(),
                Container(height: 1, color: _ui(context).divider),
                Expanded(
                  child: SingleChildScrollView(
                    physics: BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        if (!hasAdFreeAccess) ...[
                          SizedBox(height: 8),
                          Center(child: AdManager.instance.buildBannerAd()),
                          SizedBox(height: 8),
                        ],
                        if (!hasAdFreeAccess && !_promoCardDismissed)
                          _buildAdFreePromoCard(),
                        _buildTargetSection(attedanceAsync),
                        _buildSubjectwiseAttendance(attedanceAsync),
                        SizedBox(
                          height: 40 +
                              (hasAdFreeAccess ? 0 : stickyBannerOverlayHeight),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (!hasAdFreeAccess)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: _ui(context).backgroundPrimary,
                    border: Border(
                      top: BorderSide(color: _ui(context).divider, width: 0.8),
                    ),
                  ),
                  padding: EdgeInsets.fromLTRB(
                    0,
                    0,
                    0,
                    MediaQuery.of(context).padding.bottom,
                  ),
                  child: SizedBox(
                    height: _stickyBannerHeight,
                    child: Center(child: AdManager.instance.buildBannerAd()),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotConnectedScreen() {
    return Scaffold(
      backgroundColor: _ui(context).backgroundPrimary,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('CONNECT',
                        style: TextStyle(
                          color: _ui(context).accent,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.5,
                        )),


                        NeoPopButton(
                          onTapUp: () => _openInfoQueryPageHere(),
                          color: _ui(context).accent.withOpacity(0.13),
                          bottomShadowColor: _ui(context).accent.withOpacity(0.18),
                          rightShadowColor: _ui(context).accent.withOpacity(0.18),
                          depth: 4,
                          child: SizedBox(
                            width: 38,
                            height: 38,
                            child: Center(
                              child: Icon(
                                Icons.info_outline_rounded,
                                size: 20,
                                color: _ui(context).accent,
                                shadows: [
                                  Shadow(
                                    color: _ui(context).accent,
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                  ],
                ),
                SizedBox(height: 6),
                Text('Link your\nCampX account',
                    style: TextStyle(
                      color: _ui(context).textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                      height: 1.2,
                    )),
                SizedBox(height: 10),
                Text(
                  'Login cheyyi... lekapothe skills eppuduu build cheskuntaav 😭',
                  style: TextStyle(
                    color: _ui(context).textSecondary,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
                SizedBox(height: 32),

                // Credentials card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _ui(context).surfaceCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _ui(context).border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _ui(context).accent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.lock_outline_rounded,
                              size: 16, color: _ui(context).accent),
                        ),
                        SizedBox(width: 10),
                        Text('CampX Credentials',
                            style: TextStyle(
                              color: _ui(context).textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            )),
                      ]),
                      SizedBox(height: 18),
                      _buildTextField(
                        controller: _campxUsernameController,
                        label: 'Username / JNTU No.',
                        icon: Icons.person_outline_rounded,
                        enabled: !_isConnectingCampX,
                      ),
                      SizedBox(height: 12),
                      _buildTextField(
                        controller: _campxPasswordController,
                        label: 'Password',
                        icon: Icons.key_outlined,
                        enabled: !_isConnectingCampX,
                        obscure: _hideCampXPassword,
                        suffixIcon: IconButton(
                          onPressed: _isConnectingCampX
                              ? null
                              : () => setState(() =>
                                  _hideCampXPassword = !_hideCampXPassword),
                          icon: Icon(
                            _hideCampXPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: _ui(context).textMuted,
                            size: 18,
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      NeoPopButton(
                        color: _ui(context).accent,
                        bottomShadowColor: _ui(context).backgroundPrimary,
                        rightShadowColor: _ui(context).backgroundPrimary,
                        depth: 5,
                        buttonPosition: Position.fullBottom,
                        onTapUp:
                            _isConnectingCampX ? null : _submitCampXInlineConnect,
                        onTapDown: () {},
                        child: SizedBox(
                          width: double.infinity,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_isConnectingCampX)
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: _ui(context).buttonPrimaryFg,
                                    ),
                                  )
                                else ...[
                                  Icon(Icons.link_rounded,
                                      size: 17,
                                      color: _ui(context).buttonPrimaryFg),
                                  SizedBox(width: 8),
                                  Text('Link CampX Now',
                                      style: TextStyle(
                                        color: _ui(context).buttonPrimaryFg,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.2,
                                      )),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20),
                Center(
                  child: GestureDetector(
                    onTap: _bootstrapCampXConnection,
                    child: Text('Already have a session? Refresh?',
                        style: TextStyle(
                          color: _ui(context).accent,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor: _ui(context).accent,
                        )),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    bool obscure = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      obscureText: obscure,
      style: TextStyle(
          color: _ui(context).textPrimary, fontSize: 14),
      cursorColor: _ui(context).accent,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
            color: _ui(context).textMuted, fontSize: 13),
        prefixIcon:
            Icon(icon, color: _ui(context).textMuted, size: 18),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: _ui(context).backgroundSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _ui(context).border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _ui(context).border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              BorderSide(color: _ui(context).accent, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  // ── App Bar ─────────────────────────────────────────────────────────────
  Widget _appBar() {
    return Container(
      color: _ui(context).backgroundSecondary,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          NeoPopButton(
            color: _ui(context).surfaceCard,
            bottomShadowColor: _ui(context).border,
            rightShadowColor: _ui(context).border,
            depth: 3,
            onTapUp: () => Navigator.of(context).pop(),
            onTapDown: () {},
            child: SizedBox(
              width: 42,
              height: 42,
              child: Center(
                child: Icon(
                  Icons.arrow_back_rounded,
                  size: 18,
                  color: _ui(context).textSecondary,
                ),
              ),
            ),
          ),
          Spacer(),
          // Disconnect button
          NeoPopButton(
            color: _ui(context).error
                .withValues(alpha: _ui(context).isDark ? 0.18 : 0.12),
            bottomShadowColor: _ui(context).error.withValues(alpha: 0.55),
            rightShadowColor: _ui(context).error.withValues(alpha: 0.55),
            depth: 3,
            onTapUp: _confirmAndDisconnectCampX,
            onTapDown: () {},
            child: SizedBox(
              width: 42,
              height: 42,
              child: Center(
                child: Icon(Icons.link_off_rounded,
                    size: 17, color: _ui(context).error),
              ),
            ),
          ),
          SizedBox(width: 10),
          // Refresh button
          NeoPopButton(
            color: _ui(context).surfaceCard,
            bottomShadowColor: _ui(context).border,
            rightShadowColor: _ui(context).border,
            depth: 3,
            onTapUp: () {
              FirebaseService.logEvent(name: 'attendance_refresh_tapped');
              if (!_hasAdFreeAccess &&
                  Math.Random().nextInt(3) == 0) {
                AdManager.instance.showInterstitialAd();
              }
              ref.invalidate(attendanceProvider);
              ref.refresh(attendanceProvider);
              const snackBar = SnackBar(
                elevation: 0,
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.transparent,
                content: AwesomeSnackbarContent(
                  title: 'Refreshing...',
                  message: 'Fetching latest attendance data, please wait.',
                  contentType: ContentType.warning,
                ),
              );
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(snackBar);
            },
            onTapDown: () {},
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.refresh_rounded,
                    size: 15, color: _ui(context).textSecondary),
                SizedBox(width: 6),
                Text('Refresh',
                    style: TextStyle(
                      color: _ui(context).textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    )),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── Target + Overall Attendance Section (combined) ──────────────────────
  Widget _buildTargetSection(AsyncValue<List<CourseModel>> attendanceAsync) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: NeoPopButton(
        color: _ui(context).surfaceCard,
        bottomShadowColor: _ui(context).border,
        rightShadowColor: _ui(context).border,
        depth: 4,
        onTapUp: () {},
        onTapDown: () {},
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Eyebrow + target input ──────────────────────
              Row(
                children: [
                  Text('#OVERALL',
                      style: TextStyle(
                        color: _ui(context).accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.6,
                      )),
                  Spacer(),
                  // Target input inline
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Target:',
                          style: TextStyle(
                            color: _ui(context).textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          )),
                      SizedBox(width: 8),
                      Container(
                        width: 80,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _ui(context).backgroundSecondary,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: _ui(context).accent.withOpacity(0.5),
                              width: 1.5),
                        ),
                        child: TextFormField(
                          initialValue: _targetPercentage.toStringAsFixed(0),
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _ui(context).accent,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                          cursorColor: _ui(context).accent,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 6, vertical: 7),
                            suffix: Text('%',
                                style: TextStyle(
                                  color: _ui(context).accent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                )),
                          ),
                          onChanged: (value) {
                            final newValue = double.tryParse(value);
                            if (newValue != null &&
                                newValue > 0 &&
                                newValue < 100) {
                              setState(() => _targetPercentage = newValue);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Set your target attendance here ^',
                    style: TextStyle(
                      color: _ui(context).textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ],
              ),

              SizedBox(height: 18),

              // ── Overall stats from async ─────────────────────
              attendanceAsync.when(
                data: (courses) {
                  if (courses.isEmpty) return const SizedBox.shrink();
                  final int totalPresent =
                      courses.fold(0, (s, c) => s + c.present);
                  final int totalClasses =
                      courses.fold(0, (s, c) => s + c.numberOfClasses);
                  final double overallPct = totalClasses > 0
                      ? (totalPresent / totalClasses) * 100
                      : 0.0;
                  final AttendanceCalculation calc =
                      _calculateAttendanceForTarget(
                          totalPresent, totalClasses, _targetPercentage);
                  final isGood = overallPct >= _targetPercentage;
                  final statusColor = isGood
                      ? _ui(context).success
                      : _ui(context).error;
                  final progressFraction =
                      (overallPct / 100).clamp(0.0, 1.0);
                  String overallFutureCalculation = '';

                  if (calc.classesCount > 0) {
                    if (calc.canBunk) {
                      final int futureTotalClasses =
                          totalClasses + calc.classesCount;
                      final double futurePct =
                          (totalPresent / futureTotalClasses) * 100;
                      overallFutureCalculation =
                          '$totalPresent/$totalClasses  ->  $totalPresent/$futureTotalClasses = ${_formatPctFloor(futurePct)}%';
                    } else {
                      final int futurePresent = totalPresent + calc.classesCount;
                      final int futureTotalClasses =
                          totalClasses + calc.classesCount;
                      final double futurePct =
                          (futurePresent / futureTotalClasses) * 100;
                      overallFutureCalculation =
                          '$totalPresent/$totalClasses  ->  $futurePresent/$futureTotalClasses = ${_formatPctFloor(futurePct)}%';
                    }
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Big percentage
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isGood
                                ? Icons.trending_up_rounded
                                : Icons.trending_down_rounded,
                            color: statusColor,
                            size: 26,
                          ),
                          SizedBox(width: 8),
                          Text(
                            '${_formatPctFloor(overallPct)}%',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 14),

                      // Progress bar
                      Stack(
                        children: [
                          Container(
                              height: 4,
                              width: double.infinity,
                              color: _ui(context).backgroundPrimary),
                          FractionallySizedBox(
                            widthFactor: progressFraction,
                            child: Container(height: 4, color: statusColor),
                          ),
                          FractionallySizedBox(
                            widthFactor:
                                (_targetPercentage / 100).clamp(0.0, 1.0),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Container(
                                  width: 2,
                                  height: 4,
                                  color: _ui(context).textPrimary),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('$totalPresent / $totalClasses attended',
                              style: TextStyle(
                                color: _ui(context).textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              )),
                          Text('Target ${_targetPercentage.toInt()}%',
                              style: TextStyle(
                                color: _ui(context).accent.withOpacity(0.6),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              )),
                        ],
                      ),

                      SizedBox(height: 18),
                      Container(height: 0.8, color: _ui(context).divider),
                      SizedBox(height: 18),

                      // Stats row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildCardStat('Total', '$totalClasses',
                              _ui(context).textPrimary),
                          Container(
                              width: 0.8,
                              height: 36,
                              color: _ui(context).divider),
                          _buildCardStat('Present', '$totalPresent',
                              _ui(context).success),
                          Container(
                              width: 0.8,
                              height: 36,
                              color: _ui(context).divider),
                          _buildCardStat(
                              'Absent',
                              '${totalClasses - totalPresent}',
                              _ui(context).error),
                        ],
                      ),

                      SizedBox(height: 18),
                      Container(height: 0.8, color: _ui(context).divider),
                      SizedBox(height: 14),

                      if (overallFutureCalculation.isNotEmpty) ...[
                        Row(children: [
                          Icon(Icons.calculate_outlined,
                              size: 13, color: _ui(context).textMuted),
                          SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              overallFutureCalculation,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _ui(context).textPrimary,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                        ]),
                        SizedBox(height: 8),
                      ],
                      Row(children: [
                        Icon(
                          isGood
                              ? Icons.check_circle_outline_rounded
                              : Icons.warning_amber_rounded,
                          size: 13,
                          color: statusColor,
                        ),
                        SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            calc.message,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ]),
                      // SizedBox(height: 8),
                      // Row(children: [
                      //   Icon(
                      //     isGood
                      //         ? Icons.mood_rounded
                      //         : Icons.warning_amber_rounded,
                      //     size: 13,
                      //     color: statusColor.withOpacity(0.85),
                      //   ),
                      //   SizedBox(width: 7),
                      //   Expanded(
                      //     child: Text(
                      //       _getSavageMessage(calc, isGood),
                      //       style: TextStyle(
                      //         fontSize: 11.5,
                      //         fontWeight: FontWeight.w500,
                      //         color: statusColor.withOpacity(0.85),
                      //         height: 1.4,
                      //       ),
                      //     ),
                      //   ),
                      // ]),
                    ],
                  );
                },
                loading: () => Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: _ui(context).accent)),
                  ),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Subject-wise attendance ─────────────────────────────────────────────
  Widget _buildSubjectwiseAttendance(
      AsyncValue<List<CourseModel>> attendanceAsync) {
    return attendanceAsync.when(
      skipLoadingOnRefresh: false,
      data: (data) {
        if (data.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(top: 60),
            child: Center(
              child: Column(children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: _ui(context).surfaceCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _ui(context).border),
                  ),
                  child: Icon(Icons.school_outlined,
                      color: _ui(context).textMuted, size: 28),
                ),
                SizedBox(height: 16),
                Text('Subjects levu... or life lo clarity levu? 🤡',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _ui(context).textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    )),
                SizedBox(height: 6),
                Text('Sync cheyyi ra, lekapothe guess chesthu brathakali 😭',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _ui(context).textSecondary,
                      fontSize: 13,
                    )),
              ]),
            ),
          );
        }

        final List<Widget> subjectWidgets = [];

        for (int i = 0; i < data.length; i++) {
          final course = data[i];
          final calc = _calculateAttendanceForTarget(
              course.present, course.numberOfClasses, _targetPercentage);
          bool isAboveTarget = course.percentage >= _targetPercentage;
          bool isCritical =
              course.percentage < (_targetPercentage - 10);
          String futureCalcLine = '';
          String futureSavageCaption = '';
          if (calc.classesCount > 0) {
            if (calc.canBunk) {
              int ft = course.numberOfClasses + calc.classesCount;
              double fpct = (course.present / ft) * 100;
              futureCalcLine =
                  '${course.present}/${course.numberOfClasses}  →  ${course.present}/$ft = ${_formatPctFloor(fpct)}%';
              futureSavageCaption = calc.message; // "You cannot skip more than X classes"
            } else {
              int fp = course.present + calc.classesCount;
              int ft = course.numberOfClasses + calc.classesCount;
              double fpct = (fp / ft) * 100;
              futureCalcLine =
                  '${course.present}/${course.numberOfClasses}  →  $fp/$ft = ${_formatPctFloor(fpct)}%';
              futureSavageCaption = calc.message; // "Attend next X classes to reach Y%"
            }
          }
          subjectWidgets.add(_buildSubjectCard(
            course: course,
            calc: calc,
            isAboveTarget: isAboveTarget,
            isCritical: isCritical,
            futureCalculation: futureCalcLine,
            futureSavageCaption: futureSavageCaption,
          ));

          if (i == 2 && !_hasAdFreeAccess) {
            subjectWidgets.add(_NativeAdCard());
          }
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section header
              Row(children: [
                Text('SUBJECTS',
                    style: TextStyle(
                      color: _ui(context).textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.0,
                    )),
                SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _ui(context).accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('${data.length}',
                      style: TextStyle(
                        color: _ui(context).accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      )),
                ),
              ]),
              SizedBox(height: 12),
              ...subjectWidgets,
            ],
          ),
        );
      },
      loading: () => Padding(
        padding: EdgeInsets.all(60),
        child: Center(
          child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: _ui(context).accent)),
        ),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _ui(context).error.withOpacity(0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: _ui(context).error.withOpacity(0.25)),
          ),
          child: Column(children: [
            Icon(Icons.error_outline_rounded,
                color: _ui(context).error, size: 40),
            SizedBox(height: 12),
            Text('Something went wrong',
                style: TextStyle(
                  color: _ui(context).error,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                )),
            SizedBox(height: 6),
            Text('Unable to load attendance data.',
                style: TextStyle(
                  color: _ui(context).textSecondary,
                  fontSize: 12,
                )),
          ]),
        ),
      ),
    );
  }

  // ── Subject Card ────────────────────────────────────────────────────────
  Widget _buildSubjectCard({
    required CourseModel course,
    required dynamic calc,
    required bool isAboveTarget,
    required bool isCritical,
    required String futureCalculation,
    required String futureSavageCaption,
  }) {
    final Color accentColor = isAboveTarget
        ? _ui(context).success
        : isCritical
            ? _ui(context).error
            : _ui(context).warning;

    final Color shadowColor = isAboveTarget
        ? _ui(context).success.withValues(alpha: 0.35)
        : isCritical
            ? _ui(context).error.withValues(alpha: 0.35)
            : _ui(context).warning.withValues(alpha: 0.35);

    final double progressFraction = course.numberOfClasses > 0
        ? (course.present / course.numberOfClasses).clamp(0.0, 1.0)
        : 0.0;

    final String statusLabel = isAboveTarget
        ? _getCoolStatus()
        : isCritical
            ? _getDangerStatus()
            : _getMidStatus();

    final IconData trendIcon = isAboveTarget
        ? Icons.trending_up_rounded
        : isCritical
            ? Icons.trending_down_rounded
            : Icons.trending_flat_rounded;

    void navigate() {
      FirebaseService.logEvent(
        name: 'attendance_subject_opened',
        parameters: {
          'subject_id': course.subjectId,
          'subject_name': course.subjectName,
        },
      );
      if (!_hasAdFreeAccess && Math.Random().nextInt(3) == 0) {
        AdManager.instance.showInterstitialAd(onDismissed: () {
          if (!mounted) return;
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => SubjectDetailsScreen(
              subjectId: course.subjectId,
              subjectName: course.subjectName,
            ),
          ));
        });
      } else {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => SubjectDetailsScreen(
            subjectId: course.subjectId,
            subjectName: course.subjectName,
          ),
        ));
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: NeoPopButton(
        color: _ui(context).surfaceCard,
        bottomShadowColor: shadowColor,
        rightShadowColor: shadowColor,
        depth: 4,
        onTapUp: navigate,
        onTapDown: () {},
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Eyebrow row ──────────────────────────────────
              Row(
                children: [
                  Text(
                    '#SUBJECT',
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.6,
                    ),
                  ),
                  Spacer(),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                          color: accentColor.withOpacity(0.4)),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12),

              // ── Subject name ─────────────────────────────────
              Text(
                course.subjectName,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _ui(context).textPrimary,
                  letterSpacing: -0.3,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              SizedBox(height: 18),

              // ── Big percentage + trend ───────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(trendIcon, color: accentColor, size: 26),
                  SizedBox(width: 8),
                  Text(
                    '${_formatPctFloor(course.percentage)}%',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                      color: accentColor,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 14),

              // ── Progress bar ─────────────────────────────────
              Stack(
                children: [
                  Container(
                    height: 4,
                    width: double.infinity,
                    color: _ui(context).backgroundPrimary,
                  ),
                  FractionallySizedBox(
                    widthFactor: progressFraction,
                    child: Container(height: 4, color: accentColor),
                  ),
                  // Target notch
                  FractionallySizedBox(
                    widthFactor: (_targetPercentage / 100).clamp(0.0, 1.0),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                          width: 2,
                          height: 4,
                          color: _ui(context).textPrimary),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${course.present} / ${course.numberOfClasses} attended',
                    style: TextStyle(
                      color: _ui(context).textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Target ${_targetPercentage.toInt()}%',
                    style: TextStyle(
                      color: _ui(context).accent.withOpacity(0.6),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 18),
              Container(height: 0.8, color: _ui(context).divider),
              SizedBox(height: 18),

              // ── Stats row ────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCardStat('Total',
                      '${course.numberOfClasses}',
                      _ui(context).textPrimary),
                  Container(
                      width: 0.8,
                      height: 36,
                      color: _ui(context).divider),
                  _buildCardStat('Present',
                      '${course.present}',
                      _ui(context).success),
                  Container(
                      width: 0.8,
                      height: 36,
                      color: _ui(context).divider),
                  _buildCardStat('Absent',
                      '${course.absent}',
                      _ui(context).error),
                ],
              ),

              // ── Skip / attend message + future scenario ──────
              if (calc.message.isNotEmpty || futureCalculation.isNotEmpty) ...[
                SizedBox(height: 18),
                Container(height: 0.8, color: _ui(context).divider),
                SizedBox(height: 14),
              ],

              // 1. Calculation line — prominent, shown first
              if (futureCalculation.isNotEmpty) ...[
                Row(children: [
                  Icon(Icons.calculate_outlined,
                      size: 13, color: _ui(context).textMuted),
                  SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      futureCalculation,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _ui(context).textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ]),
                SizedBox(height: 8),
              ],

              // 2. Savage caption below the calc
              if (futureSavageCaption.isNotEmpty) ...[
                Row(children: [
                  Icon(
                    isAboveTarget
                        ? Icons.check_circle_outline_rounded
                        : isCritical
                            ? Icons.warning_amber_rounded
                            : Icons.info_outline_rounded,
                    size: 13,
                    color: accentColor,
                  ),
                  SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      futureSavageCaption,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: accentColor.withOpacity(0.8),
                        height: 1.4,
                      ),
                    ),
                  ),
                ]),
              ] else if (calc.message.isNotEmpty) ...[
                // No future calc — just show the message alone
                Row(children: [
                  Icon(
                    isAboveTarget
                        ? Icons.check_circle_outline_rounded
                        : isCritical
                            ? Icons.warning_amber_rounded
                            : Icons.info_outline_rounded,
                    size: 13,
                    color: accentColor,
                  ),
                  SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      calc.message,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: accentColor,
                        height: 1.4,
                      ),
                    ),
                  ),
                ]),
              ],

              SizedBox(height: 3,),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                Text('Tap for details >',
                    style: TextStyle(
                      color: _ui(context).textMuted,
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                    )),
              ],)

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardStat(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.5,
            )),
        SizedBox(height: 3),
        Text(label,
            style: TextStyle(
              fontSize: 10,
              color: color.withOpacity(0.65),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            )),
      ],
    );
  }

  // ── Ad-Free Promo Card ──────────────────────────────────────────────────
  Widget _buildAdFreePromoCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        decoration: BoxDecoration(
          color: _ui(context).surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _ui(context).accent.withOpacity(0.25)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _ui(context).accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: _ui(context).accent.withOpacity(0.2)),
                ),
                child: Icon(Icons.auto_awesome_rounded,
                    size: 18, color: _ui(context).accent),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Go Ad-Free ✨',
                        style: TextStyle(
                          color: _ui(context).textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        )),
                    SizedBox(height: 2),
                    Text('Ads chusthu unda leva ₹10 lo go ad-free lifetime? 👑',
                        style: TextStyle(
                          color: _ui(context).textSecondary,
                          fontSize: 11,
                          height: 1.4,
                        )),
                    SizedBox(height: 5),
                    // Price row
                    Row(
                      children: [
                        Text(
                          '₹99',
                          style: TextStyle(
                            color: _ui(context).textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: _ui(context).textMuted,
                          ),
                        ),
                        SizedBox(width: 5),
                        Text(
                          '₹10',
                          style: TextStyle(
                            color: _ui(context).accent,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: _ui(context).success.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            '90% OFF',
                            style: TextStyle(
                              color: _ui(context).success,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  NeoPopButton(
                    color: _ui(context).accent,
                    bottomShadowColor: _ui(context).backgroundPrimary,
                    rightShadowColor: _ui(context).backgroundPrimary,
                    depth: 3,
                    onTapUp: _isPurchasingAdFree ? null : _buyAdFreeAccess,
                    onTapDown: () {},
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      child: _isPurchasingAdFree
                          ? SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _ui(context).buttonPrimaryFg,
                              ),
                            )
                          : Text('Upgrade',
                              style: TextStyle(
                                color: _ui(context).buttonPrimaryFg,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              )),
                    ),
                  ),
                  SizedBox(height: 6),
                  GestureDetector(
                    onTap: _isPurchasingAdFree
                        ? null
                        : () => setState(() => _promoCardDismissed = true),
                    child: Text('Not now',
                        style: TextStyle(
                          color: _ui(context).textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        )),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Attendance calculation — logic entirely unchanged ───────────────────
  AttendanceCalculation _calculateAttendanceForTarget(
      int present, int total, double targetPercentage) {
    if (total == 0) {
      return AttendanceCalculation(
          canBunk: false, classesCount: 0, message: 'No classes yet');
    }
    double currentPercentage = (present / total) * 100;
    if (currentPercentage >= targetPercentage) {
      int maxTotalClasses = (present * 100 / targetPercentage).floor();
      int canBunk = max(0, maxTotalClasses - total);
      if (canBunk > 0) {
        return AttendanceCalculation(
          canBunk: true,
          classesCount: canBunk,
          message:
              'You can skip  $canBunk more class${canBunk > 1 ? 'es' : ''}.',
        );
      } else {
        return AttendanceCalculation(
          canBunk: false,
          classesCount: 0,
          message:
              'To maintain ${targetPercentage.toInt()}%, you cannot skip any more classes.',
        );
      }
    } else {
      int needToAttend =
          ((targetPercentage * total - 100 * present) / (100 - targetPercentage))
              .ceil();
      needToAttend = max(0, needToAttend);
      return AttendanceCalculation(
        canBunk: false,
        classesCount: needToAttend,
        message:
            'Attend next $needToAttend class${needToAttend > 1 ? 'es' : ''} to reach ${targetPercentage.toInt()}%',
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  HELPER CLASS — unchanged
// ─────────────────────────────────────────────────────────────────────────────
class AttendanceCalculation {
  final bool canBunk;
  final int classesCount;
  final String message;

  AttendanceCalculation({
    required this.canBunk,
    required this.classesCount,
    required this.message,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
//  NATIVE AD CARD — inserted between subjects
// ─────────────────────────────────────────────────────────────────────────────
class _NativeAdCard extends StatefulWidget {
  _NativeAdCard();
  @override
  State<_NativeAdCard> createState() => _NativeAdCardState();
}

class _NativeAdCardState extends State<_NativeAdCard> {
  static const _nativeAdUnitId = 'ca-app-pub-6840112928410718/4205263143';
  NativeAd? _nativeAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadNativeAd();
  }

  void _loadNativeAd() {
    _nativeAd = NativeAd(
      adUnitId: _nativeAdUnitId,
      factoryId: 'small',
      listener: NativeAdListener(
        onAdLoaded: (_) {
          if (!mounted) return;
          setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('[Ads] NativeAd failed: $error');
          ad.dispose();
        },
      ),
      request: AdRequest(),
    )..load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _nativeAd == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      height: 100,
      decoration: BoxDecoration(
        color: _ui(context).surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _ui(context).borderSubtle),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AdWidget(ad: _nativeAd!),
      ),
    );
  }
}


