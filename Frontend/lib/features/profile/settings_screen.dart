import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:neopop/neopop.dart';
import 'package:routemaster/routemaster.dart';
import 'package:UniSync/features/auth/auth_controller.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:UniSync/app/providers.dart';
import 'package:UniSync/app/theme/theme_provider.dart';
import 'package:UniSync/app/theme/app_colors.dart';
import 'package:UniSync/constants/constant.dart';
import 'package:UniSync/features/auth/auth_repository.dart';
import 'package:UniSync/features/coins/coin_purchase_service.dart';
import 'package:UniSync/models/user_model.dart';

SettingsPalette _ui(BuildContext context) => SettingsPalette.of(context);

class SettingsPalette {
  SettingsPalette({
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
    required this.accentHover,
    required this.buttonPrimaryFg,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.onError,
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
  final Color accentHover;
  final Color buttonPrimaryFg;
  final Color success;
  final Color warning;
  final Color error;
  final Color info;
  final Color onError;

  factory SettingsPalette.of(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = AppColors.primary;

    return SettingsPalette(
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
      accent: accent,
      accentSoft: accent.withValues(alpha: 0.14),
      accentHover: accent.withValues(alpha: 0.9),
      buttonPrimaryFg: theme.colorScheme.onPrimary,
      success: AppColors.success,
      warning: AppColors.warning,
      error: theme.colorScheme.error,
      info: AppColors.info,
      onError: theme.colorScheme.onError,
    );
  }
}

class ProfileScreen extends ConsumerStatefulWidget {
  ProfileScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  int _semToYear(int sem) => ((sem + 1) ~/ 2);

  Future<void> _setThemeMode(ThemeMode mode) async {
    await ref.read(themeModeProvider.notifier).setThemeMode(mode);
  }

  String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  IconData _themeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode_rounded;
      case ThemeMode.dark:
        return Icons.dark_mode_rounded;
      case ThemeMode.system:
        return Icons.brightness_auto_rounded;
    }
  }

  Future<void> _showThemeModePicker(ThemeMode selectedThemeMode) async {
    final modes = [ThemeMode.system, ThemeMode.light, ThemeMode.dark];

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: _ui(context).backgroundSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose Theme',
                  style: TextStyle(
                    color: _ui(ctx).textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 12),
                ...modes.map((mode) {
                  final selected = selectedThemeMode == mode;
                  return Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () async {
                          await _setThemeMode(mode);
                          if (mounted) Navigator.of(ctx).pop();
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? _ui(ctx).accent.withOpacity(0.14)
                                : _ui(ctx).surfaceCard,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selected
                                  ? _ui(ctx).accent
                                  : _ui(ctx).border,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _themeIcon(mode),
                                size: 18,
                                color: selected
                                    ? _ui(ctx).accent
                                    : _ui(ctx).textSecondary,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _themeLabel(mode),
                                  style: TextStyle(
                                    color: selected
                                        ? _ui(ctx).accent
                                        : _ui(ctx).textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Icon(
                                selected
                                    ? Icons.check_circle_rounded
                                    : Icons.circle_outlined,
                                size: 18,
                                color: selected
                                    ? _ui(ctx).accent
                                    : _ui(ctx).textMuted,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await ref.read(coinPurchaseServiceProvider).initialize();
      } catch (_) {
        // Billing init is best-effort; action handlers show any user-facing errors.
      }
    });
  }

  void _openEditSheet(UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _ui(context).backgroundSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EditProfileSheet(
        user: user,
        semToYear: _semToYear,
        onSaved: (updatedUser) {
          ref.read(userProvider.notifier).state = updatedUser;
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Profile updated'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }

  Future<void> _openCoinPurchaseSheet() async {
    final user = ref.read(userProvider);
    final currentCoins = user?.coins ?? 0;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: _ui(context).backgroundSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Buy Coins',
                  style: TextStyle(
                    color: _ui(context).textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Current balance: $currentCoins coins',
                  style: TextStyle(
                    color: _ui(context).textSecondary,
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _ui(context).surfaceCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _ui(context).border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Iconsax.empty_wallet_add,
                        color: _ui(context).accent,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '100 Coins Pack',
                          style: TextStyle(
                            color: _ui(context).textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      NeoPopButton(
                        color: _ui(context).accent,
                        bottomShadowColor: _ui(context).backgroundPrimary,
                        rightShadowColor: _ui(context).backgroundPrimary,
                        depth: 3,
                        onTapDown: () {},
                        onTapUp: () async {
                          final error = await ref
                              .read(coinPurchaseServiceProvider)
                              .buy100CoinsPack();

                          if (!mounted) return;

                          if (error != null) {
                            rootScaffoldMessengerKey.currentState
                              ?..hideCurrentSnackBar()
                              ..showSnackBar(
                                SnackBar(
                                  content: Text(error),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: _ui(context).error,
                                ),
                              );
                            return;
                          }

                          Navigator.of(ctx).pop();
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 9,
                          ),
                          child: Text(
                            'Rs 9',
                            style: TextStyle(
                              color: _ui(context).buttonPrimaryFg,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Uni-Coins can be used to redeem exclusive rewards and access premium features within the app.',
                  style: TextStyle(
                    color: _ui(context).textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleAdFreePurchase() async {
    final error = await ref.read(coinPurchaseServiceProvider).buyAdFreeAccess();

    if (!mounted || error == null) return;

    rootScaffoldMessengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(error),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _ui(context).error,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final selectedThemeMode = ref.watch(themeModeProvider);
    final themeLabel = _themeLabel(selectedThemeMode);
    if (user == null) {
      return Scaffold(
        backgroundColor: _ui(context).backgroundPrimary,
        body: Center(child: CircularProgressIndicator(color: _ui(context).accent)),
      );
    }

    final bool isPremium = user.hasAdFreeAccess ?? false;

    return Scaffold(
      backgroundColor: _ui(context).backgroundPrimary,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── App bar ──────────────────────────────────────────────────
              _ProfileAppBar(),

              SizedBox(height: 28),

              // ── Avatar + identity block ──────────────────────────────────
              _buildIdentityBlock(user, isPremium),

              SizedBox(height: 24),

              // ── CTAs ─────────────────────────────────────────────────────
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Column(children: [
                  _buildUniCoinsCTA(user.coins ?? 0),
                  if (!isPremium) ...[
                    SizedBox(height: 10),
                    _buildPremiumCTA(),
                  ],
                ]),
              ),

              SizedBox(height: 28),

              // ── ACCOUNT ──────────────────────────────────────────────────
              _SectionHeader(label: 'ACCOUNT'),
              SizedBox(height: 10),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: _GroupCard(rows: [
                  _RowData(
                    icon: _themeIcon(selectedThemeMode),
                    iconColor: _ui(context).info,
                    title: 'Theme',
                    subtitle: 'Current: $themeLabel',
                    trailing: _ThemeModeChip(label: themeLabel),
                    onTap: () => _showThemeModePicker(selectedThemeMode),
                  ),
                  _RowData(
                    icon: Icons.person_outline_rounded,
                    iconColor: _ui(context).accent,
                    title: 'Personal Info',
                    subtitle: 'Name, semester, college, bio',
                    onTap: () => _openEditSheet(user),
                  ),
                  _RowData(
                    icon: Icons.fingerprint_rounded,
                    iconColor: Color(0xFF67B7FF),
                    title: 'User ID',
                    subtitle: _shortUid(user.id!),
                    trailing: _CopyButton(text: user.id!),
                    onTap: () => _copyToClipboard(user.id!),
                  ),
                ]),
              ),

              SizedBox(height: 24),

              // ── UNISYNC ──────────────────────────────────────────────────
              _SectionHeader(label: 'UNISYNC'),
              SizedBox(height: 10),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: _GroupCard(rows: [
                  _RowData(
                    icon: Icons.notifications_active_rounded,
                    iconColor: Color(0xFF67B7FF),
                    title: "What's New",
                    subtitle: 'Latest updates and announcements',
                    onTap: _showNoticeBoard,
                  ),
                  _RowData(
                    icon: Icons.bug_report_outlined,
                    iconColor: Color(0xFFFFA94D),
                    title: 'Report an issue',
                    subtitle: 'Reach the team directly via email',
                    onTap: () => _openExternal(
                      _supportEmailUrl(
                        subject: 'UniSync Bug Report',
                        extraBody: 'Please describe the bug, screen, and issue details.',
                      ),
                    ),
                  ),
                  _RowData(
                    icon: Icons.rocket_launch_outlined,
                    iconColor: Color(0xFFFF6B8A),
                    title: 'Follow UniSync',
                    subtitle: 'Launches and updates on Instagram',
                    onTap: () => _openExternal(
                      'https://www.instagram.com/unisyncofficial/',
                    ),
                  ),
                ]),
              ),

              SizedBox(height: 24),

              // ── LEGAL ────────────────────────────────────────────────────
              _SectionHeader(label: 'LEGAL'),
              SizedBox(height: 10),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: _GroupCard(rows: [
                  _RowData(
                    icon: Icons.description_outlined,
                    iconColor: Color(0xFF3ECF8E),
                    title: 'Terms & Conditions',
                    subtitle: 'Usage rules and agreements',
                    onTap: () => _showLegal('terms'),
                  ),
                  _RowData(
                    icon: Icons.privacy_tip_outlined,
                    iconColor: Color(0xFF67B7FF),
                    title: 'Privacy Policy',
                    subtitle: 'How we handle your data',
                    onTap: () => _showLegal('privacy'),
                  ),
                ]),
              ),

              SizedBox(height: 24),

              // ── BILLING ──────────────────────────────────────────────────
              _SectionHeader(label: 'BILLING'),
              SizedBox(height: 10),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: _GroupCard(rows: [
                  _RowData(
                    icon: Icons.payment_outlined,
                    iconColor: Color(0xFF3ECF8E),
                    title: 'Payment issues',
                    subtitle: "Coins not credited? We'll fix it.",
                    onTap: () => _showBillingFaqSheet(
                      title: 'Payment issues',
                      emailSubject: 'UniSync Payment Support',
                    ),
                  ),
                  _RowData(
                    icon: Icons.currency_rupee_rounded,
                    iconColor: Color(0xFFFFA94D),
                    title: 'Refund request',
                    subtitle: 'Something wrong with your purchase?',
                    onTap: () => _showBillingFaqSheet(
                      title: 'Refund request',
                      emailSubject: 'UniSync Refund Request',
                    ),
                  ),
                ]),
              ),

              SizedBox(height: 32),

              // ── Log Out ──────────────────────────────────────────────────
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: _LogOutButton(onTap: () => _showLogoutDialog(context, ref)),
              ),

              SizedBox(height: 32),

              // ── Footer ───────────────────────────────────────────────────
              GestureDetector(
                onTap: () => _openExternal(
                    'https://www.linkedin.com/company/unisyncofficial/'),
                child: Column(children: [
                  Center(
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('Made with ',
                          style: TextStyle(
                              fontSize: 11,
                              color: _ui(context).textMuted)),
                      Text('❤️', style: TextStyle(fontSize: 11)),
                      Text(' by Team Aavishkaar',
                          style: TextStyle(
                              fontSize: 11,
                              color: _ui(context).textMuted)),
                    ]),
                  ),
                  SizedBox(height: 4),
                  Center(
                    child: Text('Version(2.9.18) · Thunder',
                        style: TextStyle(
                          fontSize: 10,
                          color: _ui(context).textMuted,
                        )),
                  ),
                ]),
              ),

              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ── Identity block ────────────────────────────────────────────────────────
  Widget _buildIdentityBlock(UserModel user, bool isPremium) {
    final bio = (user.about ?? '').trim();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Stack(clipBehavior: Clip.none, children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _ui(context).surfaceCard,
                border: Border.all(
                    color: isPremium
                        ? Color(0xFFFFD700).withOpacity(0.5)
                        : _ui(context).accent.withOpacity(0.35),
                    width: 2),
              ),
              child: ClipOval(
                child: (user.photoUrl ?? '').trim().isNotEmpty
                    ? Image.network(
                        user.photoUrl!.trim(),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildAvatarFallback(user),
                      )
                    : _buildAvatarFallback(user),
              ),
            ),
            if (isPremium)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFFFD700),
                    border: Border.all(
                        color: _ui(context).backgroundPrimary, width: 2),
                  ),
                  child: Icon(Icons.workspace_premium_rounded,
                      size: 11, color: Colors.black),
                ),
              ),
            if (!isPremium)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF3ECF8E),
                    border: Border.all(
                        color: _ui(context).backgroundPrimary, width: 2),
                  ),
                  child: Icon(Icons.check,
                      size: 13, color: Colors.white),
                ),
              ),
          ]),

          SizedBox(width: 16),

          // Name + email + bio
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name.isEmpty ? 'Your Name' : user.name,
                  style: GoogleFonts.playfairDisplay(
                    color: _ui(context).textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    height: 1.15,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  user.emailId,
                  style: TextStyle(
                    color: _ui(context).textSecondary,
                    fontSize: 12,
                  ),
                ),
                if (bio.isNotEmpty) ...[
                  SizedBox(height: 8),
                  Text(
                    bio,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _ui(context).accentHover,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── UniCoins CTA
  // (edit handled via bottom sheet — see _EditProfileSheet)

  // ── UniCoins CTA ──────────────────────────────────────────────────────────
  Widget _buildUniCoinsCTA(int coins) {
    final palette = _ui(context);
    final ctaColor =
        palette.isDark ? Color(0xFF0C1510) : palette.surfaceCard;
    final ctaShadow =
        palette.isDark ? Color(0xFF1A6B4A) : palette.border;

    return NeoPopButton(
      color: ctaColor,
      bottomShadowColor: ctaShadow,
      rightShadowColor: ctaShadow,
      depth: 4,
      onTapUp: _openCoinPurchaseSheet,
      onTapDown: () {},
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row — icon + balance
            Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: palette.success.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: palette.success.withOpacity(0.3),
                  ),
                ),
                child: Icon(Iconsax.coin_14,
                    size: 20, color: palette.success),
              ),
              SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('UniCoins',
                    style: TextStyle(
                      color: _ui(context).textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    )),
                SizedBox(height: 1),
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(
                    '$coins',
                    style: TextStyle(
                      color: palette.success,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.5,
                      height: 1,
                    ),
                  ),
                  SizedBox(width: 5),
                  Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Text('~ ₹${(coins*0.09).toStringAsFixed(2)}',
                        style: TextStyle(
                          color: _ui(context).accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        )),
                  ),
                ]),
              ]),
              Spacer(),
              // Top-up pill button
              NeoPopButton(
                color: palette.success,
                bottomShadowColor: ctaShadow,
                rightShadowColor: ctaShadow,
                depth: 3,
                buttonPosition: Position.fullBottom,
                onTapUp: () {
                  _openCoinPurchaseSheet();
                },
                onTapDown: () {},
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.add_rounded,
                        size: 14, color: palette.buttonPrimaryFg),
                    SizedBox(width: 4),
                    Text('Top Up',
                        style: TextStyle(
                          color: palette.buttonPrimaryFg,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.1,
                        )),
                  ]),
                ),
              ),
            ]),

            SizedBox(height: 12),
            Divider(color: palette.success.withOpacity(0.12), height: 1),
            SizedBox(height: 12),

            // Bottom hint
            Column(
              children: [
                Row(children: [
                  Icon(Icons.info_outline_rounded,
                      size: 12, color: _ui(context).textMuted),
                  SizedBox(width: 5),
                  Expanded(
                    child: Text('Use coins to unlock premium features in the app',
                        style: TextStyle(
                          color: _ui(context).textMuted,
                          fontSize: 11,
                          height: 1.4,
                        )),
                  ),
                ]),
                SizedBox(height: 3,),
                 Row(children: [
                  Icon(Icons.stars_sharp,
                      size: 12, color: _ui(context).textMuted),
                  SizedBox(width: 5),
                  Expanded(
                    child: Text('Soon you will be able to withdraw real money as well!',
                        style: TextStyle(
                          color: _ui(context).textMuted,
                          fontSize: 11,
                          height: 1.4,
                        )),
                  ),
                ]),
              ],
            ),
          ],
        ),
      ),
    );
  }
  // ── Premium CTA ───────────────────────────────────────────────────────────
  Widget _buildPremiumCTA() {
    final palette = _ui(context);
    final premiumTone = palette.warning;
    final premiumBg =
        palette.isDark ? Color(0xFF100E04) : palette.surfaceCard;
    final premiumShadow =
        palette.isDark ? Color(0xFF7A5010) : palette.border;

    return NeoPopButton(
      color: premiumBg,
      bottomShadowColor: premiumShadow,
      rightShadowColor: premiumShadow,
      depth: 4,
      onTapUp: _handleAdFreePurchase,
      onTapDown: () {},
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(children: [
          // Icon badge
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: premiumTone.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: premiumTone.withOpacity(0.28)),
            ),
            child: Icon(Icons.workspace_premium_rounded,
                size: 22, color: premiumTone),
          ),
          SizedBox(width: 14),

          // Text block
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text('Go Ad-Free',
                    style: TextStyle(
                      color: _ui(context).textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    )),
                SizedBox(width: 6),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: palette.success.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('90% OFF',
                      style: TextStyle(
                        color: palette.success,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      )),
                ),
              ]),
              SizedBox(height: 3),
              // Price row
              Row(children: [
                Text('₹99',
                    style: TextStyle(
                      color: _ui(context).textMuted,
                      fontSize: 11,
                      decoration: TextDecoration.lineThrough,
                      decorationColor: _ui(context).textMuted,
                    )),
                SizedBox(width: 5),
                Text('₹10 only',
                    style: TextStyle(
                      color: premiumTone,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    )),
              ]),
              SizedBox(height: 5),
              // Feature bullets
              Text('✦  No ads, ever',
                  style: TextStyle(
                    color: _ui(context).textSecondary,
                    fontSize: 11,
                    height: 1.5,
                  )),
              Text('✦  Support the team ❤️',
                  style: TextStyle(
                    color: _ui(context).textSecondary,
                    fontSize: 11,
                    height: 1.5,
                  )),
            ]),
          ),

          SizedBox(width: 8),
          Icon(Icons.arrow_forward_rounded, color: premiumTone, size: 18),
        ]),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _buildAvatarFallback(UserModel user) {
    return Center(
      child: Text(
        _initials(user.name),
        style: TextStyle(
          color: _ui(context).accent,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -1,
        ),
      ),
    );
  }

  String _initials(String name) {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  String _shortUid(String uid) {
    if (uid.length <= 12) return uid;
    return '${uid.substring(0, 8)}…${uid.substring(uid.length - 4)}';
  }

  String _supportEmailUrl({
    required String subject,
    String? extraBody,
  }) {
    final userId = ref.read(userProvider)?.id ?? 'unknown';
    final body = StringBuffer()
      ..writeln('User ID: $userId')
      ..writeln()
      ..writeln(extraBody ?? 'Describe your issue here.');

    return Uri(
      scheme: 'mailto',
      path: 'hello.unisync@gmail.com',
      queryParameters: {
        'subject': subject,
        'body': body.toString(),
      },
    ).toString();
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('User ID copied!'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _openExternal(String url) async =>
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  void _showNoticeBoard() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _ui(context).backgroundSecondary,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => NoticeBoardModal(),
    );
  }

  void _showLegal(String type) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _ui(context).backgroundSecondary,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => LegalOptionsModal(initialTab: type),
    );
  }

  void _showBillingFaqSheet({
    required String title,
    required String emailSubject,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _ui(context).backgroundSecondary,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _BillingFaqSheet(
        title: title,
        emailSubject: emailSubject,
        onEmailTap: () => _openExternal(
          _supportEmailUrl(
            subject: emailSubject,
            extraBody: 'Please share your purchase details and what went wrong.',
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext ctx, WidgetRef ref) {
    showDialog(
      context: ctx,
      builder: (_) => Dialog(
        backgroundColor: _ui(context).backgroundSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Color(0xFFE05252).withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.logout_rounded,
                    color: Color(0xFFE05252), size: 18),
              ),
              SizedBox(height: 14),
              Text('Log out?',
                  style: TextStyle(
                    color: _ui(context).textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  )),
              SizedBox(height: 6),
              Text(
                  "You'll need to log in again to access your profile.",
                  style: TextStyle(
                    color: _ui(context).textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  )),
              SizedBox(height: 20),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _ui(context).textSecondary,
                      side: BorderSide(color: _ui(context).border),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text('Cancel',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Color(0xFFE05252),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      ref.read(authControllerProvider).signOut();
                      Routemaster.of(ctx).replace('/');
                    },
                    child: Text('Log Out',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SUPPORTING WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileAppBar extends StatelessWidget {
  _ProfileAppBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1/0,
      color: _ui(context).backgroundSecondary,
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '#FIX YOUR BUG\'S',
            style: GoogleFonts.dmSans(
              color: _ui(context).accent,
              fontSize: 9,
              fontWeight: FontWeight.w500,
              letterSpacing: 2.2,
            ),
          ),
          SizedBox(height: 3),
          RichText(
            text: TextSpan(children: [
              TextSpan(
                text: 'Profile ',
                style: GoogleFonts.playfairDisplay(
                  color: _ui(context).textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              TextSpan(
                text: 'settings',
                style: GoogleFonts.playfairDisplay(
                  color: _ui(context).accent,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  fontStyle: FontStyle.italic,
                  letterSpacing: -0.3,
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _EditField extends StatelessWidget {
  _EditField({
    required this.controller,
    required this.label,
    required this.icon,
    this.maxLines = 1,
  });
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(
          color: _ui(context).textPrimary, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
            color: _ui(context).textMuted, fontSize: 12),
        prefixIcon: Icon(icon, size: 16, color: _ui(context).textMuted),
        filled: true,
        fillColor: _ui(context).backgroundPrimary,
        contentPadding:
            EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              BorderSide(color: _ui(context).border.withOpacity(0.6)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              BorderSide(color: _ui(context).border.withOpacity(0.6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
              color: _ui(context).accent.withOpacity(0.6), width: 1.2),
        ),
      ),
    );
  }
}

class _LogOutButton extends StatelessWidget {
  _LogOutButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = _ui(context);
    final logoutColor =
        palette.isDark ? Color(0xFF1C0808) : palette.surfaceCard;
    final logoutShadow =
        palette.isDark ? Color(0xFF8B1A1A) : palette.border;

    return NeoPopButton(
      color: logoutColor,
      bottomShadowColor: logoutShadow,
      rightShadowColor: logoutShadow,
      depth: 4,
      onTapUp: onTap,
      onTapDown: () {},
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, size: 16, color: palette.error),
              SizedBox(width: 8),
              Text(
                'Log Out',
                style: TextStyle(
                  color: palette.error,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          color: _ui(context).textMuted.withOpacity(0.65),
          fontSize: 10,
          fontWeight: FontWeight.w500,
          letterSpacing: 2.0,
        ),
      ),
    );
  }
}

class _ThemeModeChip extends StatelessWidget {
  _ThemeModeChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _ui(context).surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _ui(context).border.withOpacity(0.7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: _ui(context).textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(width: 4),
          Icon(
            Icons.expand_more_rounded,
            size: 14,
            color: _ui(context).textMuted,
          ),
        ],
      ),
    );
  }
}

class _RowData {
  _RowData({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });
  final IconData icon;
  final Color iconColor;
  final String title, subtitle;
  final VoidCallback onTap;
  final Widget? trailing;
}

class _GroupCard extends StatelessWidget {
  _GroupCard({required this.rows});
  final List<_RowData> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _ui(context).surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _ui(context).borderSubtle),
      ),
      child: Column(
        children: List.generate(rows.length, (i) {
          final row = rows[i];
          final isLast = i == rows.length - 1;
          return Column(children: [
            _GroupRowTile(row: row),
            if (!isLast)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Container(height: 0.6, color: _ui(context).divider),
              ),
          ]);
        }),
      ),
    );
  }
}

class _GroupRowTile extends StatelessWidget {
  _GroupRowTile({required this.row});
  final _RowData row;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: row.onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: row.iconColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(row.icon, color: row.iconColor, size: 17),
          ),
          SizedBox(width: 13),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(row.title,
                  style: TextStyle(
                    color: _ui(context).textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  )),
              SizedBox(height: 1),
              Text(row.subtitle,
                  style: TextStyle(
                    color: _ui(context).textSecondary,
                    fontSize: 11,
                    height: 1.3,
                  )),
            ]),
          ),
          if (row.trailing != null)
            row.trailing!
          else
            Icon(Icons.chevron_right_rounded,
                color: _ui(context).textMuted, size: 18),
        ]),
      ),
    );
  }
}

class _CopyButton extends StatefulWidget {
  _CopyButton({required this.text});
  final String text;

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.text));
    setState(() => _copied = true);
    await Future.delayed(Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _copy,
      child: AnimatedSwitcher(
        duration: Duration(milliseconds: 200),
        child: _copied
            ? Icon(Icons.check_rounded,
                key: ValueKey('check'),
                color: Color(0xFF3ECF8E), size: 17)
            : Icon(Icons.copy_rounded,
                key: ValueKey('copy'),
                color: _ui(context).textMuted.withOpacity(0.65),
                size: 16),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// EDIT PROFILE BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _EditProfileSheet extends ConsumerStatefulWidget {
  _EditProfileSheet({
    required this.user,
    required this.semToYear,
    required this.onSaved,
  });
  final UserModel user;
  final int Function(int) semToYear;
  final ValueChanged<UserModel> onSaved;

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _aboutCtrl;
  int? _selectedSem;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl  = TextEditingController(text: widget.user.name);
    _aboutCtrl = TextEditingController(text: widget.user.about ?? '');
    _selectedSem = widget.user.semester;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _aboutCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Enter a valid name (min 3 chars)')),
      );
      return;
    }
    if (_selectedSem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select your semester')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final repo = ref.read(AuthRepositoryProvider);
      final updated = await repo.updateProfile(
        name:        name,
        collegeName: widget.user.collegeName ?? '',
        semester:    _selectedSem!,
        year:        widget.semToYear(_selectedSem!),
        about:       _aboutCtrl.text.trim(),
      );
      if (!mounted) return;
      if (updated != null) widget.onSaved(updated);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Container(
          color: _ui(context).backgroundSecondary,
          padding: EdgeInsets.fromLTRB(20, 14, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: _ui(context).border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 18),

              // Header
              Text(
                'Edit Profile',
                style: GoogleFonts.playfairDisplay(
                  color: _ui(context).textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Update your name, semester and bio',
                style: GoogleFonts.dmSans(
                  color: _ui(context).textMuted,
                  fontSize: 11,
                ),
              ),
              SizedBox(height: 20),

              // Name
              _SheetField(
                controller: _nameCtrl,
                label: 'Display name',
                icon: Icons.person_outline_rounded,
              ),
              SizedBox(height: 12),

              // College — read-only
              _SheetField(
                controller: TextEditingController(
                    text: widget.user.collegeName ?? ''),
                label: 'College',
                icon: Icons.account_balance_outlined,
                readOnly: true,
              ),
              SizedBox(height: 16),

              // Semester label
              Text(
                'Semester',
                style: GoogleFonts.dmSans(
                  color: _ui(context).textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.4,
                ),
              ),
              SizedBox(height: 8),

              // Semester picker
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(8, (i) {
                  final sem = i + 1;
                  final selected = _selectedSem == sem;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedSem = sem),
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 180),
                      width: 58,
                      padding: EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? _ui(context).accent
                            : _ui(context).surfaceCard,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected
                              ? _ui(context).accent
                              : _ui(context).border.withOpacity(0.6),
                        ),
                      ),
                      child: Column(children: [
                        Text(
                          '$sem',
                          style: TextStyle(
                            color: selected
                                ? _ui(context).buttonPrimaryFg
                                : _ui(context).textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'sem',
                          style: TextStyle(
                            color: selected
                                ? _ui(context).buttonPrimaryFg
                                    .withOpacity(0.75)
                                : _ui(context).textMuted,
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ]),
                    ),
                  );
                }),
              ),
              SizedBox(height: 16),

              // Bio
              _SheetField(
                controller: _aboutCtrl,
                label: 'Bio',
                icon: Icons.notes_rounded,
                maxLines: 3,
              ),
              SizedBox(height: 20),

              // Save — NeoPopButton
              NeoPopButton(
                color: _saving
                    ? _ui(context).textDisabled
                    : _ui(context).accent,
                bottomShadowColor: _ui(context).backgroundPrimary,
                rightShadowColor: _ui(context).backgroundPrimary,
                depth: 4,
                onTapUp: _saving ? null : _save,
                onTapDown: () {},
                child: SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 15),
                    child: Center(
                      child: _saving
                          ? SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              'Save Changes',
                              style: GoogleFonts.dmSans(
                                color: _ui(context).buttonPrimaryFg,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  _SheetField({
    required this.controller,
    required this.label,
    required this.icon,
    this.maxLines = 1,
    this.readOnly = false,
  });
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int maxLines;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      readOnly: readOnly,
      style: TextStyle(
        color: readOnly
            ? _ui(context).textMuted
            : _ui(context).textPrimary,
        fontSize: 13,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            TextStyle(color: _ui(context).textMuted, fontSize: 12),
        prefixIcon:
            Icon(icon, size: 16, color: _ui(context).textMuted),
        filled: true,
        fillColor: readOnly
            ? _ui(context).backgroundPrimary.withOpacity(0.5)
            : _ui(context).backgroundPrimary,
        contentPadding:
            EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
              color: _ui(context).border.withOpacity(0.6)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
              color: readOnly
                  ? _ui(context).border.withOpacity(0.3)
                  : _ui(context).border.withOpacity(0.6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
              color: readOnly
                  ? _ui(context).border.withOpacity(0.3)
                  : _ui(context).accent.withOpacity(0.6),
              width: 1.2),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BILLING FAQ SHEET (unchanged logic, minor style cleanup)
// ─────────────────────────────────────────────────────────────────────────────

class _BillingFaqSheet extends StatelessWidget {
  _BillingFaqSheet({
    required this.title,
    required this.emailSubject,
    required this.onEmailTap,
  });
  final String title, emailSubject;
  final VoidCallback onEmailTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: _ui(context).accent.withOpacity(0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.help_outline_rounded,
                  color: _ui(context).accent, size: 18),
            ),
            SizedBox(height: 14),
            Text(title,
                style: TextStyle(
                  color: _ui(context).textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                )),
            SizedBox(height: 6),
            Text('Before emailing us, please check these quick answers.',
                style: TextStyle(
                    color: _ui(context).textSecondary,
                    fontSize: 12,
                    height: 1.45)),
            SizedBox(height: 16),
            _FaqPoint(
  question: 'Purchase not showing after switching account?',
  answer:
      'If you purchased ad-free using one Google account but are now logged in with a different account, the purchase will only be linked to the original UniSync account. Please log in with the same account used during purchase to restore access. For any issues, contact us via email.',
),
            _FaqPoint(
              question: 'Payment succeeded but coins/ad-free did not show up?',
              answer: 'Wait a minute, reopen the app once, then check again.',
            ),
            _FaqPoint(
              question: 'Money deducted but feature still missing?',
              answer:
                  'Share your account email, purchase time, and item — we\'ll verify it fast.',
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
                onPressed: onEmailTap,
                child: Text('Email Support',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700)),
              ),
            ),
            SizedBox(height: 8),
            Text('Subject: $emailSubject',
                style: TextStyle(
                    color: _ui(context).textMuted, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _FaqPoint extends StatelessWidget {
  _FaqPoint({required this.question, required this.answer});
  final String question, answer;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(question,
            style: TextStyle(
              color: _ui(context).textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            )),
        SizedBox(height: 3),
        Text(answer,
            style: TextStyle(
              color: _ui(context).textSecondary,
              fontSize: 12,
              height: 1.45,
            )),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NOTICE BOARD / LEGAL (logic unchanged, imports kept)
// ─────────────────────────────────────────────────────────────────────────────

Future<List<Map<String, dynamic>>> getNoticesData() async {
  final snap = await FirebaseFirestore.instance.collection('notice').get();
  return snap.docs.map((d) => d.data()).toList();
}

class NoticeBoardModal extends StatelessWidget {
  NoticeBoardModal({super.key});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        color: _ui(context).backgroundSecondary,
        padding: EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: _ui(context).border,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          SizedBox(height: 20),
          Text('What\'s new?',
              style: GoogleFonts.dmSans(
                color: _ui(context).accent,
                fontSize: 9,
                fontWeight: FontWeight.w500,
                letterSpacing: 2.2,
              )),
          SizedBox(height: 4),
          RichText(
            text: TextSpan(children: [
              TextSpan(
                  text: 'Latest ',
                  style: GoogleFonts.playfairDisplay(
                    color: _ui(context).textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  )),
              TextSpan(
                  text: 'announcements',
                  style: GoogleFonts.playfairDisplay(
                    color: _ui(context).accent,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    fontStyle: FontStyle.italic,
                    letterSpacing: -0.3,
                  )),
            ]),
          ),
          SizedBox(height: 20),
          Expanded(
            child: FutureBuilder(
              future: getNoticesData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                      child: CircularProgressIndicator(
                          color: _ui(context).accent));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                      child: Text('No notices posted yet.',
                          style: TextStyle(
                              color: _ui(context).textSecondary)));
                }
                return ListView.builder(
                  controller: scrollController,
                  itemCount: snapshot.data!.length,
                  itemBuilder: (_, i) {
                    final d = snapshot.data![i];
                    return _NoticeItem(
                      heading: d['heading'],
                      description: d['description'],
                      date: d['date'],
                    );
                  },
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}

class _NoticeItem extends StatelessWidget {
  _NoticeItem(
      {required this.heading,
      required this.description,
      required this.date});
  final String heading, description;
  final Timestamp date;

  @override
  Widget build(BuildContext context) {
    final formatted = DateFormat('dd MMM yyyy').format(date.toDate());
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _ui(context).surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: Color(0xFF67B7FF).withOpacity(0.15)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Text(heading,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _ui(context).textPrimary,
                )),
          ),
          SizedBox(width: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: Color(0xFF67B7FF).withOpacity(0.10),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(formatted,
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFF67B7FF),
                  fontWeight: FontWeight.w500,
                )),
          ),
        ]),
        SizedBox(height: 8),
        Text(description,
            style: TextStyle(
              fontSize: 12,
              color: _ui(context).textSecondary,
              height: 1.5,
            )),
      ]),
    );
  }
}

Future<String> fetchPolicyText() async {
  final snap = await FirebaseFirestore.instance
      .collection('texts').doc('policy').get();
  if (snap.exists) return snap.data()!['text'];
  throw Exception('Updating Soon');
}

Future<String> fetchTermsText() async {
  final snap = await FirebaseFirestore.instance
      .collection('texts').doc('t_c').get();
  if (snap.exists) return snap.data()!['text'];
  throw Exception('Updating soon');
}

class LegalOptionsModal extends StatelessWidget {
  LegalOptionsModal({super.key, this.initialTab = 'terms'});
  final String initialTab;

  void _open(BuildContext context, String title, Future<String> future) {
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _ui(context).backgroundSecondary,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => FutureBuilder<String>(
        future: future,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return SizedBox(
                height: 200,
                child: Center(
                    child: CircularProgressIndicator(
                        color: _ui(context).accent)));
          }
          return LegalDocumentModal(
              title: title,
              content: snap.data ?? 'Content unavailable.');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (initialTab == 'terms' || initialTab == 'privacy') {
      final isTerms = initialTab == 'terms';
      return FutureBuilder<String>(
        future: isTerms ? fetchTermsText() : fetchPolicyText(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return SizedBox(
              height: 200,
              child: Center(
                child: CircularProgressIndicator(
                  color: _ui(context).accent,
                ),
              ),
            );
          }
          return LegalDocumentModal(
            title: isTerms ? 'Terms & Conditions' : 'Privacy Policy',
            content: snap.data ?? 'Content unavailable.',
          );
        },
      );
    }

    return Container(
      color: _ui(context).backgroundSecondary,
      padding: EdgeInsets.all(20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(
          child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: _ui(context).border,
                  borderRadius: BorderRadius.circular(2))),
        ),
        SizedBox(height: 20),
        Text('Legal Information',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _ui(context).textPrimary,
            )),
        SizedBox(height: 14),
        ListTile(
          tileColor: _ui(context).surfaceCard,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          leading: Icon(Icons.description,
              color: Color(0xFF3ECF8E), size: 20),
          title: Text('Terms & Conditions',
              style: TextStyle(
                  color: _ui(context).textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          trailing: Icon(Icons.arrow_forward_ios,
              color: _ui(context).textMuted, size: 13),
          onTap: () =>
              _open(context, 'Terms & Conditions', fetchTermsText()),
        ),
        SizedBox(height: 8),
        ListTile(
          tileColor: _ui(context).surfaceCard,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          leading:
              Icon(Icons.privacy_tip, color: Color(0xFF67B7FF), size: 20),
          title: Text('Privacy Policy',
              style: TextStyle(
                  color: _ui(context).textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          trailing: Icon(Icons.arrow_forward_ios,
              color: _ui(context).textMuted, size: 13),
          onTap: () => _open(context, 'Privacy Policy', fetchPolicyText()),
        ),
        SizedBox(height: 12),
      ]),
    );
  }
}

class LegalDocumentModal extends StatelessWidget {
  LegalDocumentModal(
      {super.key, required this.title, required this.content});
  final String title, content;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      builder: (context, scrollController) => Container(
        color: _ui(context).backgroundSecondary,
        padding: EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(
            child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: _ui(context).border,
                    borderRadius: BorderRadius.circular(2))),
          ),
          SizedBox(height: 20),
          Text(title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _ui(context).textPrimary,
              )),
          SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              child: Text(content,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.6,
                    color: _ui(context).textSecondary,
                  )),
            ),
          ),
        ]),
      ),
    );
  }
}


