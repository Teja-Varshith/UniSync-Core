import 'dart:math';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neopop/neopop.dart';
import 'package:routemaster/routemaster.dart';
import 'package:unisync/constants/constant.dart';
import 'package:unisync/features/attendance/repository/attendance_repository.dart';
import 'package:unisync/features/attendance/controller/attendance_controller.dart';
import 'package:unisync/features/attendance/view/subject_detail_screen.dart';
import 'package:unisync/models/course_model.dart';

class LiveAttendence extends ConsumerStatefulWidget {
  const LiveAttendence({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _LiveAttendenceState();
}

class _LiveAttendenceState extends ConsumerState<LiveAttendence> {
  // ── logic fields unchanged ─────────────────────────────────────────────────
  double _targetPercentage = 75.0;
  List attendanceData = [];
  bool isLoading = false;
  bool _checkingSession = true;
  bool _campxConnected = false;
  bool _isConnectingCampX = false;
  bool _hideCampXPassword = true;
  final TextEditingController _campxUsernameController = TextEditingController();
  final TextEditingController _campxPasswordController = TextEditingController();

  double _floorToDecimals(double value, int decimals) {
    final factor = pow(10, decimals).toDouble();
    return (value * factor).floorToDouble() / factor;
  }

  String _formatPctFloor(double value, {int decimals = 2}) {
    return _floorToDecimals(value, decimals).toStringAsFixed(decimals);
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

    return 'Inavlid Credentials please confirm or reset your credentials.';
  }

  @override
  void initState() {
    super.initState();
    _bootstrapCampXConnection();
  }

  @override
  void dispose() {
    _campxUsernameController.dispose();
    _campxPasswordController.dispose();
    super.dispose();
  }

  Future<void> _bootstrapCampXConnection() async {
    setState(() => _checkingSession = true);
    final connected = await ref
        .read(AttendanceRepositoryProvider)
        .ensureCampXSession(allowRelogin: true);
    if (!mounted) return;
    setState(() {
      _campxConnected = connected;
      _checkingSession = false;
    });
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
    } catch (e) {
      if (!mounted) return;
      setState(() => _isConnectingCampX = false);
      _showAwesomeMessage(
        title: 'Connection failed',
        message: _mapCampXErrorToMessage(e),
        type: ContentType.failure,
      );
    }
  }

  Future<void> _confirmAndDisconnectCampX() async {
    final shouldDisconnect = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: UniSyncColors.backgroundSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Disconnect CampX?',
                style: TextStyle(
                  color: UniSyncColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'You will have to enter your credentials again to view attendance',
                style: TextStyle(
                  color: UniSyncColors.textSecondary,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE05252),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Disconnect'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (shouldDisconnect == true) {
      await _disconnectCampX();
    }
  }
  // ── logic methods end ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final attedanceAsync = ref.watch(attendanceProvider);

    // ── Checking session ──────────────────────────────────────────
    if (_checkingSession) {
      return const Scaffold(
        backgroundColor: UniSyncColors.backgroundPrimary,
        body: Center(child: SizedBox(width: 24, height: 24,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: UniSyncColors.accent))),
      );
    }

    // ── Not connected ─────────────────────────────────────────────
    if (!_campxConnected) {
      return Scaffold(
        backgroundColor: UniSyncColors.backgroundPrimary,
        body: SafeArea(
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                  Container(
                    width: 64, height: 64,
                    color: UniSyncColors.surfaceCard,
                    child: const Icon(Icons.link_off_rounded,
                        color: UniSyncColors.textMuted, size: 28),
                  ),
                  const SizedBox(height: 20),
                  const Text('CampX is not linked yet',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: UniSyncColors.textPrimary,
                        fontSize: 20, fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      )),
                  const SizedBox(height: 8),
                  const Text(
                    'No stress, your attendance sync is just one step away.\nLink CampX to unlock live stats and subject-wise tracking.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: UniSyncColors.textSecondary,
                      fontSize: 13, height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: UniSyncColors.surfaceCard,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: UniSyncColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CampX Credentials',
                          style: TextStyle(
                            color: UniSyncColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _campxUsernameController,
                          enabled: !_isConnectingCampX,
                          style: const TextStyle(
                            color: UniSyncColors.textPrimary,
                            fontSize: 13,
                          ),
                          cursorColor: UniSyncColors.accent,
                          decoration: InputDecoration(
                            labelText: 'CampX Username / JNTU No',
                            labelStyle: const TextStyle(
                              color: UniSyncColors.textMuted,
                              fontSize: 13,
                            ),
                            filled: true,
                            fillColor: UniSyncColors.backgroundSecondary,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: UniSyncColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: UniSyncColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: UniSyncColors.accent,
                                width: 1.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _campxPasswordController,
                          enabled: !_isConnectingCampX,
                          obscureText: _hideCampXPassword,
                          style: const TextStyle(
                            color: UniSyncColors.textPrimary,
                            fontSize: 13,
                          ),
                          cursorColor: UniSyncColors.accent,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            labelStyle: const TextStyle(
                              color: UniSyncColors.textMuted,
                              fontSize: 13,
                            ),
                            suffixIcon: IconButton(
                              onPressed: _isConnectingCampX
                                  ? null
                                  : () => setState(() {
                                        _hideCampXPassword = !_hideCampXPassword;
                                      }),
                              icon: Icon(
                                _hideCampXPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: UniSyncColors.textMuted,
                                size: 18,
                              ),
                            ),
                            filled: true,
                            fillColor: UniSyncColors.backgroundSecondary,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: UniSyncColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: UniSyncColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: UniSyncColors.accent,
                                width: 1.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 14),
                        NeoPopButton(
                          color: UniSyncColors.accent,
                          bottomShadowColor: UniSyncColors.backgroundPrimary,
                          rightShadowColor: UniSyncColors.backgroundPrimary,
                          depth: 4,
                          buttonPosition: Position.fullBottom,
                          onTapUp: _isConnectingCampX ? null : _submitCampXInlineConnect,
                          onTapDown: () {},
                          child: SizedBox(
                            width: double.infinity,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.login_rounded, size: 16, color: UniSyncColors.buttonPrimaryFg),
                                  const SizedBox(width: 8),
                                  if (_isConnectingCampX)
                                    const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: UniSyncColors.buttonPrimaryFg,
                                      ),
                                    )
                                  else
                                    const Text(
                                      'Link CampX now',
                                      style: TextStyle(
                                        color: UniSyncColors.buttonPrimaryFg,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _bootstrapCampXConnection,
                    child: const Text('Try session sync again',
                        style: TextStyle(
                          color: UniSyncColors.accent, fontSize: 13,
                          fontWeight: FontWeight.w600,
                        )),
                  ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // ── Main screen ───────────────────────────────────────────────
    return Scaffold(
      backgroundColor: UniSyncColors.backgroundPrimary,
      body: SafeArea(
        child: Column(children: [

          // App bar
          _appBar(),
          Container(height: 0.8, color: UniSyncColors.divider),

          Expanded(
            child: SingleChildScrollView(
              child: Column(children: [
                _buildTargetSection(),
                _buildTotalAttendance(attedanceAsync),
                _buildSubjectwiseAttendance(attedanceAsync),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  // ── App bar ─────────────────────────────────────────────────────
  Widget _appBar() {
    return Container(
      color: UniSyncColors.backgroundSecondary,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('#ATTENDANCE', style: TextStyle(
                  color: UniSyncColors.accent, fontSize: 9,
                  fontWeight: FontWeight.w700, letterSpacing: 1.8,
                )),
                const SizedBox(height: 4),
                RichText(text: const TextSpan(children: [
                  TextSpan(text: 'Smart ',
                      style: TextStyle(
                        color: UniSyncColors.textPrimary, fontSize: 24,
                        fontWeight: FontWeight.w800, letterSpacing: -0.5,
                      )),
                  TextSpan(text: 'attendance',
                      style: TextStyle(
                        color: UniSyncColors.accent, fontSize: 24,
                        fontWeight: FontWeight.w800, letterSpacing: -0.5,
                      )),
                ])),
                const SizedBox(height: 2),
                const Text('Attend classes like a pro 😎', style: TextStyle(
                  color: UniSyncColors.textMuted, fontSize: 12,
                )),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              NeoPopButton(
                color: const Color(0xFF2A0A0A),
                bottomShadowColor: const Color(0xFFE05252),
                rightShadowColor: const Color(0xFFE05252),
                depth: 3,
                onTapUp: _confirmAndDisconnectCampX,
                onTapDown: () {},
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: Center(
                    child: Icon(Icons.link_off_rounded,
                        size: 16, color: Color(0xFFE05252)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              NeoPopButton(
                color: UniSyncColors.surfaceCard,
                bottomShadowColor: UniSyncColors.border,
                rightShadowColor: UniSyncColors.border,
                depth: 3,
                onTapUp: () {
                  ref.invalidate(attendanceProvider);
                  ref.refresh(attendanceProvider);
                  const snackBar = SnackBar(
                    elevation: 0,
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.transparent,
                    content: AwesomeSnackbarContent(
                      title: 'Attendance Refreshing....',
                      message: 'Fetching latest attendance data, please wait.',
                      contentType: ContentType.warning,
                    ),
                  );
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(snackBar);
                },
                onTapDown: () {},
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.refresh_rounded,
                        size: 14, color: UniSyncColors.textSecondary),
                    SizedBox(width: 5),
                    Text('Refresh', style: TextStyle(
                      color: UniSyncColors.textSecondary,
                      fontSize: 12, fontWeight: FontWeight.w600,
                    )),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Target section ─────────────────────────────────────────────
  Widget _buildTargetSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: UniSyncColors.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: UniSyncColors.borderSubtle),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('TARGET ATTENDANCE', style: TextStyle(
            color: UniSyncColors.textMuted, fontSize: 9,
            fontWeight: FontWeight.w700, letterSpacing: 1.6,
          )),
          SizedBox(width: 10),
          Container(
            width: 84,
            height: 36,
            decoration: BoxDecoration(
              color: UniSyncColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: UniSyncColors.accent.withOpacity(0.4)),
            ),
            child: TextFormField(
              initialValue: _targetPercentage.toStringAsFixed(0),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: UniSyncColors.accent,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
              cursorColor: UniSyncColors.accent,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                suffix: Text(
                  '%',
                  style: TextStyle(
                    color: UniSyncColors.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              onChanged: (value) {
                final newValue = double.tryParse(value);
                if (newValue != null && newValue > 0 && newValue < 100) {
                  setState(() => _targetPercentage = newValue);
                }
              },
            ),
          ),
        ]),
        const SizedBox(height: 8),
        const Text(
          'Set your target — see how many classes you can skip 🤫',
          style: TextStyle(
            color: UniSyncColors.textSecondary,
            fontSize: 12, height: 1.4,
          ),
        ),
      ]),
    );
  }

  // ── Total attendance banner — logic unchanged ──────────────────
  Widget _buildTotalAttendance(AsyncValue<List<CourseModel>> attendanceAsync) {
    return attendanceAsync.when(
      // skipLoadingOnRefresh: false,
      data: (courses) {
        if (courses.isEmpty) return const SizedBox.shrink();

        int totalPresent   = courses.fold(0, (s, c) => s + c.present);
        int totalClasses   = courses.fold(0, (s, c) => s + c.numberOfClasses);
        double overallPct  = totalClasses > 0
            ? (totalPresent / totalClasses) * 100 : 0.0;
        AttendanceCalculation calc = _calculateAttendanceForTarget(
            totalPresent, totalClasses, _targetPercentage);

        final isGood = overallPct >= _targetPercentage;
        final bannerColor = isGood
            ? const Color(0xFF3ECF8E) : const Color(0xFFE05252);

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: bannerColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: bannerColor.withOpacity(0.35)),
          ),
          child: Row(children: [
            Expanded(
              flex: 3,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildCompactStat('Present',
                      totalPresent.toString(), bannerColor),
                  _buildCompactStat('Total',
                      totalClasses.toString(), bannerColor),
                  _buildCompactStat('Overall',
                      '${_formatPctFloor(overallPct)}%', bannerColor),
                ],
              ),
            ),
            Container(width: 1, height: 30,
                color: bannerColor.withOpacity(0.25),
                margin: const EdgeInsets.symmetric(horizontal: 12)),
            Expanded(
              flex: 3,
              child: Text(calc.message, style: TextStyle(
                color: bannerColor, fontSize: 12, fontWeight: FontWeight.w600,
              ), textAlign: TextAlign.center, maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ),
          ]),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: SizedBox(width: 24, height: 24,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: UniSyncColors.accent))),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildCompactStat(String title, String value, Color color) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(value, style: TextStyle(
        fontSize: 16, fontWeight: FontWeight.w700, color: color,
      )),
      Text(title, style: TextStyle(
        fontSize: 10, color: color.withOpacity(0.7), fontWeight: FontWeight.w500,
      )),
    ]);
  }

  // ── Subject-wise attendance — logic unchanged ──────────────────
  Widget _buildSubjectwiseAttendance(
      AsyncValue<List<CourseModel>> attendanceAsync) {
    return attendanceAsync.when(
      skipLoadingOnRefresh: false,
      data: (data) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (data.isEmpty) ...[
              const SizedBox(height: 60),
              Center(child: Column(children: [
                Container(width: 56, height: 56,
                    color: UniSyncColors.surfaceCard,
                    child: const Icon(Icons.school_outlined,
                        color: UniSyncColors.textMuted, size: 24)),
                const SizedBox(height: 14),
                const Text('No data yet',
                    style: TextStyle(
                      color: UniSyncColors.textPrimary,
                      fontSize: 15, fontWeight: FontWeight.w700,
                    )),
                const SizedBox(height: 6),
                const Text('Attendance data is not being updated yet',
                    style: TextStyle(
                      color: UniSyncColors.textSecondary, fontSize: 12,
                    )),
              ])),
            ],
            const SizedBox(height: 16),
            ...data.map((course) {
              final calc = _calculateAttendanceForTarget(
                  course.present, course.numberOfClasses, _targetPercentage);
              bool isAboveTarget = course.percentage >= _targetPercentage;
              bool isCritical = course.percentage < (_targetPercentage - 10);
              String futureCalculation = '';
              if (calc.classesCount > 0) {
                if (calc.canBunk) {
                  int fp = course.present;
                  int ft = course.numberOfClasses + calc.classesCount;
                  double fpct = (fp / ft) * 100;
                  futureCalculation =
                      '→ $fp/$ft = ${_formatPctFloor(fpct)}%';
                } else {
                  int fp = course.present + calc.classesCount;
                  int ft = course.numberOfClasses + calc.classesCount;
                  double fpct = (fp / ft) * 100;
                  futureCalculation =
                      '→ $fp/$ft = ${_formatPctFloor(fpct)}%';
                }
              }
              return _buildSubjectCard(
                course: course, calc: calc,
                isAboveTarget: isAboveTarget, isCritical: isCritical,
                futureCalculation: futureCalculation,
              );
            }),
          ]),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: SizedBox(width: 24, height: 24,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: UniSyncColors.accent))),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFE05252).withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: const Color(0xFFE05252).withOpacity(0.3)),
          ),
          child: Column(children: [
            const Icon(Icons.error_outline_rounded,
                color: Color(0xFFE05252), size: 36),
            const SizedBox(height: 10),
            const Text('Something went wrong!', style: TextStyle(
              color: Color(0xFFE05252), fontSize: 14,
              fontWeight: FontWeight.w700,
            )),
            const SizedBox(height: 6),
            const Text('Unable to load attendance data.',
                style: TextStyle(
                  color: UniSyncColors.textSecondary, fontSize: 12,
                )),
          ]),
        ),
      ),
    );
  }

  // ── Subject card — logic unchanged ─────────────────────────────
  Widget _buildSubjectCard({
    required CourseModel course,
    required dynamic calc,
    required bool isAboveTarget,
    required bool isCritical,
    required String futureCalculation,
  }) {
    Color accentColor = isAboveTarget
        ? const Color(0xFF3ECF8E)
        : isCritical
            ? const Color(0xFFE05252)
            : const Color(0xFFE8A838);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => SubjectDetailsScreen(
                subjectId: course.subjectId,
                subjectName: course.subjectName,
              ))),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: UniSyncColors.surfaceCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: accentColor.withOpacity(0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Header ──────────────────────────────────────
                Row(children: [
                  Expanded(
                    child: Text(course.subjectName,
                        style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700,
                          color: UniSyncColors.textPrimary,
                          letterSpacing: -0.2,
                        ), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 10),
                  // Percentage badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: accentColor.withOpacity(0.3)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(
                        isAboveTarget
                            ? Icons.trending_up_rounded
                            : isCritical
                                ? Icons.trending_down_rounded
                                : Icons.trending_flat_rounded,
                        size: 12, color: accentColor,
                      ),
                      const SizedBox(width: 4),
                      Text('${_formatPctFloor(course.percentage)}%',
                          style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700,
                            color: accentColor,
                          )),
                    ]),
                  ),
                ]),

                const SizedBox(height: 12),

                // ── Stats chips ──────────────────────────────────
                Row(children: [
                  _buildSubjectStatChip('Present',
                      '${course.present}', const Color(0xFF3ECF8E)),
                  const SizedBox(width: 8),
                  _buildSubjectStatChip('Absent',
                      '${course.absent}', const Color(0xFFE05252)),
                  const SizedBox(width: 8),
                  _buildSubjectStatChip('Total',
                      '${course.numberOfClasses}',
                      UniSyncColors.textMuted),
                ]),

                const SizedBox(height: 12),

                // ── Action container ─────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: accentColor.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(
                          isAboveTarget
                              ? Icons.check_circle_outline_rounded
                              : isCritical
                                  ? Icons.warning_amber_rounded
                                  : Icons.info_outline_rounded,
                          size: 14, color: accentColor,
                        ),
                        const SizedBox(width: 7),
                        Expanded(child: Text(calc.message,
                            style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600,
                              color: accentColor,
                            ))),
                      ]),
                      if (futureCalculation.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: UniSyncColors.backgroundSecondary,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: UniSyncColors.borderSubtle),
                          ),
                          child: Row(children: [
                            const Icon(Icons.calculate_outlined,
                                size: 13, color: UniSyncColors.textMuted),
                            const SizedBox(width: 8),
                            Expanded(
                              child: RichText(text: TextSpan(children: [
                                TextSpan(
                                  text: '${course.present}/${course.numberOfClasses} ',
                                  style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w700,
                                    color: UniSyncColors.textPrimary,
                                  ),
                                ),
                                TextSpan(
                                  text: futureCalculation,
                                  style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600,
                                    color: accentColor,
                                  ),
                                ),
                              ])),
                            ),
                          ]),
                        ),
                      ],
                    ],
                  ),
                ),

                // ── Tap hint ─────────────────────────────────────
                const SizedBox(height: 10),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: const [
                  Text('Tap for details', style: TextStyle(
                    fontSize: 11, color: UniSyncColors.textMuted,
                  )),
                  SizedBox(width: 3),
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 10, color: UniSyncColors.textMuted),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 5, height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text('$label: ', style: const TextStyle(
          fontSize: 11, color: UniSyncColors.textMuted,
          fontWeight: FontWeight.w500,
        )),
        Text(value, style: TextStyle(
          fontSize: 11, color: color, fontWeight: FontWeight.w700,
        )),
      ]),
    );
  }

  // ── Attendance calculation — logic entirely unchanged ──────────
  AttendanceCalculation _calculateAttendanceForTarget(
      int present, int total, double targetPercentage) {
    if (total == 0) {
      return AttendanceCalculation(
          canBunk: false, classesCount: 0, message: 'No classes yet');
    }
    double currentPercentage = (present / total) * 100;
    if (currentPercentage >= targetPercentage) {
      int maxTotalClasses =
          (present * 100 / targetPercentage).floor();
      int canBunk = max(0, maxTotalClasses - total);
      if (canBunk > 0) {
        return AttendanceCalculation(
          canBunk: true, classesCount: canBunk,
          message:
              'You can Skip $canBunk more class${canBunk > 1 ? 'es' : ''}',
        );
      } else {
        return AttendanceCalculation(
          canBunk: false, classesCount: 0,
          message:
              "To maintain ${targetPercentage.toInt()}% you shouldn't skip any further classes.",
        );
      }
    } else {
      int needToAttend = ((targetPercentage * total - 100 * present) /
              (100 - targetPercentage))
          .ceil();
      needToAttend = max(0, needToAttend);
      return AttendanceCalculation(
        canBunk: false, classesCount: needToAttend,
        message:
            'Attend next $needToAttend class${needToAttend > 1 ? 'es' : ''} to reach ${targetPercentage.toInt()}%',
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  HELPER CLASS  — unchanged
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