import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:neopop/neopop.dart';
import 'package:routemaster/routemaster.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:unisync/constants/constant.dart';
import 'package:unisync/features/attendance/repository/attendance_repository.dart';
import 'package:unisync/storage/secure_storage.dart';

class CampxLoginScreen extends ConsumerStatefulWidget {
  const CampxLoginScreen({super.key});

  @override
  ConsumerState<CampxLoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<CampxLoginScreen> {
  bool _isloading = false;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isPasswordVisible = false;

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
      return 'Invalid CampX credentials. Check your username and password and try again.';
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

    return 'Unable to sign in to CampX right now. Please try again.';
  }

  @override
  void initState() {
    super.initState();
    _prefillStoredCredentials();
  }

  Future<void> _prefillStoredCredentials() async {
    final storage = SecureStorageService();
    final savedUser = await storage.getCampXUsername();
    final savedPass = await storage.getCampXPassword();
    if (!mounted) return;
    setState(() {
      if ((savedUser ?? '').isNotEmpty) emailController.text = savedUser!;
      if ((savedPass ?? '').isNotEmpty) passwordController.text = savedPass!;
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _showDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: UniSyncColors.backgroundSecondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: UniSyncColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // eyebrow
                const Text(
                  '#HELP',
                  style: TextStyle(
                    color: UniSyncColors.accent,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.8,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'How to Sign In?',
                  style: TextStyle(
                    color: UniSyncColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 14),
                Container(height: 0.8, color: UniSyncColors.divider),
                const SizedBox(height: 14),
                const Text(
                  'Use your JNTU Number or College Email registered on CampX along with your password to sign in.\n\nYour password is the one you set during your CampX registration.\n\nIf you face any issues, please contact hello.unisync@gmail.com',
                  style: TextStyle(
                    color: UniSyncColors.textSecondary,
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: NeoPopButton(
                    color: UniSyncColors.accent,
                    bottomShadowColor: UniSyncColors.backgroundPrimary,
                    rightShadowColor: UniSyncColors.backgroundPrimary,
                    depth: 3,
                    onTapUp: () => Navigator.pop(context),
                    onTapDown: () {},
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Text(
                        'Got it',
                        style: TextStyle(
                          color: UniSyncColors.backgroundPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Future<void> login() async {
      if (_formKey.currentState!.validate()) {
        setState(() => _isloading = true);
        try {
          await ref.read(AttendanceRepositoryProvider).completeCampXLogin(
                emailController.text.trim(),
                passwordController.text,
              );
          if (!mounted) return;
          Routemaster.of(context).replace('/liveAttendence');
        } catch (e) {
          if (!mounted) return;
          _showAwesomeMessage(
            title: 'CampX login failed',
            message: _mapCampXErrorToMessage(e),
            type: ContentType.failure,
          );
        } finally {
          if (mounted) setState(() => _isloading = false);
        }
      }
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: UniSyncColors.backgroundPrimary,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [

                      // ── Top bar ────────────────────────────────────────
                      Container(
                        color: UniSyncColors.backgroundSecondary,
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '#CAMPUS MODE',
                                    style: TextStyle(
                                      color: UniSyncColors.accent,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.8,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  RichText(
                                    text: const TextSpan(children: [
                                      TextSpan(
                                        text: 'Camp',
                                        style: TextStyle(
                                          color: UniSyncColors.textPrimary,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      TextSpan(
                                        text: 'X Login',
                                        style: TextStyle(
                                          color: UniSyncColors.accent,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                    ]),
                                  ),
                                ],
                              ),
                            ),
                            // Help button
                            GestureDetector(
                              onTap: () => _showDialog(context),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: UniSyncColors.surfaceCard,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: UniSyncColors.border),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.question_mark_rounded,
                                    size: 16,
                                    color: UniSyncColors.textMuted,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      Container(height: 0.8, color: UniSyncColors.divider),

                      // ── Lottie ─────────────────────────────────────────
                      Container(
                        color: UniSyncColors.backgroundSecondary,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Lottie.asset(
                          'assets/animations/login_lottie.json',
                          height: 200,
                        ),
                      ),

                      Container(height: 0.8, color: UniSyncColors.divider),

                      // ── Form card ──────────────────────────────────────
                      Expanded(
                        child: Container(
                          color: UniSyncColors.backgroundPrimary,
                          padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [

                                // Tagline
                                const Text(
                                  'Your Campus,\nYour Vibe.',
                                  style: TextStyle(
                                    color: UniSyncColors.textPrimary,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Use your College Credentials to sign in instantly.',
                                  style: TextStyle(
                                    color: UniSyncColors.textSecondary,
                                    fontSize: 13,
                                    height: 1.5,
                                  ),
                                ),

                                const SizedBox(height: 28),

                                // ── JNTU / Email field ─────────────────
                                _UniSyncTextField(
                                  controller: emailController,
                                  label: 'JNTU No / Email',
                                  keyboardType: TextInputType.emailAddress,
                                  prefixIcon: Icons.school_outlined,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Example: 23341XXXXX';
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 16),

                                // ── Password field ─────────────────────
                                _UniSyncTextField(
                                  controller: passwordController,
                                  label: 'Password',
                                  prefixIcon: Icons.lock_outline_rounded,
                                  obscureText: !_isPasswordVisible,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isPasswordVisible
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      size: 18,
                                      color: UniSyncColors.textMuted,
                                    ),
                                    onPressed: () => setState(
                                        () => _isPasswordVisible = !_isPasswordVisible),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Password? Brain go brrrrr';
                                    }
                                    if (value.length < 3) return "Don't lie guys";
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 28),

                                // ── Login button ───────────────────────
                                _isloading
                                    ? Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: UniSyncColors.surfaceCard,
                                          border: Border.all(color: UniSyncColors.border),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: const [
                                            SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: UniSyncColors.accent,
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            Text(
                                              'Signing you securely...',
                                              style: TextStyle(
                                                color: UniSyncColors.textSecondary,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : NeoPopButton(
                                        color: UniSyncColors.accent,
                                        bottomShadowColor: UniSyncColors.backgroundPrimary,
                                        rightShadowColor: UniSyncColors.backgroundPrimary,
                                        depth: 5,
                                        onTapUp: login,
                                        onTapDown: () {},
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(vertical: 16),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.rocket_launch_rounded,
                                                color: UniSyncColors.backgroundPrimary,
                                                size: 18,
                                              ),
                                              SizedBox(width: 10),
                                              Text(
                                                "Let's Go.....",
                                                style: TextStyle(
                                                  color: UniSyncColors.backgroundPrimary,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: 0.3,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                const SizedBox(height: 20),

                                // ── Secure note ────────────────────────
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(
                                      Icons.lock_rounded,
                                      size: 11,
                                      color: UniSyncColors.textMuted,
                                    ),
                                    SizedBox(width: 5),
                                    Text(
                                      'Your credentials are stored securely on-device',
                                      style: TextStyle(
                                        color: UniSyncColors.textMuted,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  UNISYNC TEXT FIELD
// ─────────────────────────────────────────────────────────────────────────────

class _UniSyncTextField extends StatelessWidget {
  const _UniSyncTextField({
    required this.controller,
    required this.label,
    required this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final FormFieldValidator<String> validator;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(
        color: UniSyncColors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      cursorColor: UniSyncColors.accent,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: UniSyncColors.textMuted,
          fontSize: 13,
        ),
        floatingLabelStyle: const TextStyle(
          color: UniSyncColors.accent,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: UniSyncColors.surfaceCard,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, size: 18, color: UniSyncColors.textMuted)
            : null,
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: UniSyncColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: UniSyncColors.accent, width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: UniSyncColors.error),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: UniSyncColors.error, width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
        errorStyle: const TextStyle(
          color: UniSyncColors.error,
          fontSize: 11,
        ),
      ),
      validator: validator,
    );
  }
}