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
import 'package:UniSync/constants/constant.dart';
import 'package:UniSync/features/auth/auth_repository.dart';
import 'package:UniSync/features/coins/coin_purchase_service.dart';
import 'package:UniSync/models/user_model.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  int _semToYear(int sem) => ((sem + 1) ~/ 2);

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
      backgroundColor: UniSyncColors.backgroundSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EditProfileSheet(
        user: user,
        semToYear: _semToYear,
        onSaved: (updatedUser) {
          ref.read(userProvider.notifier).state = updatedUser;
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
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
      backgroundColor: UniSyncColors.backgroundSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Buy Coins',
                  style: TextStyle(
                    color: UniSyncColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Current balance: $currentCoins coins',
                  style: const TextStyle(
                    color: UniSyncColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: UniSyncColors.surfaceCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: UniSyncColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Iconsax.empty_wallet_add,
                        color: UniSyncColors.accent,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          '100 Coins Pack',
                          style: TextStyle(
                            color: UniSyncColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      NeoPopButton(
                        color: UniSyncColors.accent,
                        bottomShadowColor: UniSyncColors.backgroundPrimary,
                        rightShadowColor: UniSyncColors.backgroundPrimary,
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
                                  backgroundColor: UniSyncColors.error,
                                ),
                              );
                            return;
                          }

                          Navigator.of(ctx).pop();
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 9,
                          ),
                          child: Text(
                            'Rs 9',
                            style: TextStyle(
                              color: UniSyncColors.buttonPrimaryFg,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Uni-Coins can be used to redeem exclusive rewards and access premium features within the app.',
                  style: TextStyle(
                    color: UniSyncColors.textMuted,
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
          backgroundColor: UniSyncColors.error,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    if (user == null) {
      return const Scaffold(
        backgroundColor: UniSyncColors.backgroundPrimary,
        body: Center(child: CircularProgressIndicator(color: UniSyncColors.accent)),
      );
    }

    final bool isPremium = user.hasAdFreeAccess ?? false;

    return Scaffold(
      backgroundColor: UniSyncColors.backgroundPrimary,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── App bar ──────────────────────────────────────────────────
              const _ProfileAppBar(),

              const SizedBox(height: 28),

              // ── Avatar + identity block ──────────────────────────────────
              _buildIdentityBlock(user, isPremium),

              const SizedBox(height: 24),

              // ── CTAs ─────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(children: [
                  _buildUniCoinsCTA(user.coins ?? 0),
                  if (!isPremium) ...[
                    const SizedBox(height: 10),
                    _buildPremiumCTA(),
                  ],
                ]),
              ),

              const SizedBox(height: 28),

              // ── ACCOUNT ──────────────────────────────────────────────────
              const _SectionHeader(label: 'ACCOUNT'),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _GroupCard(rows: [
                  _RowData(
                    icon: Icons.person_outline_rounded,
                    iconColor: UniSyncColors.accent,
                    title: 'Personal Info',
                    subtitle: 'Name, semester, college, bio',
                    onTap: () => _openEditSheet(user),
                  ),
                  _RowData(
                    icon: Icons.fingerprint_rounded,
                    iconColor: const Color(0xFF67B7FF),
                    title: 'User ID',
                    subtitle: _shortUid(user.id!),
                    trailing: _CopyButton(text: user.id!),
                    onTap: () => _copyToClipboard(user.id!),
                  ),
                ]),
              ),

              const SizedBox(height: 24),

              // ── UNISYNC ──────────────────────────────────────────────────
              const _SectionHeader(label: 'UNISYNC'),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _GroupCard(rows: [
                  _RowData(
                    icon: Icons.notifications_active_rounded,
                    iconColor: const Color(0xFF67B7FF),
                    title: "What's New",
                    subtitle: 'Latest updates and announcements',
                    onTap: _showNoticeBoard,
                  ),
                  _RowData(
                    icon: Icons.bug_report_outlined,
                    iconColor: const Color(0xFFFFA94D),
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
                    iconColor: const Color(0xFFFF6B8A),
                    title: 'Follow UniSync',
                    subtitle: 'Launches and updates on Instagram',
                    onTap: () => _openExternal(
                      'https://www.instagram.com/unisyncofficial/',
                    ),
                  ),
                ]),
              ),

              const SizedBox(height: 24),

              // ── LEGAL ────────────────────────────────────────────────────
              const _SectionHeader(label: 'LEGAL'),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _GroupCard(rows: [
                  _RowData(
                    icon: Icons.description_outlined,
                    iconColor: const Color(0xFF3ECF8E),
                    title: 'Terms & Conditions',
                    subtitle: 'Usage rules and agreements',
                    onTap: () => _showLegal('terms'),
                  ),
                  _RowData(
                    icon: Icons.privacy_tip_outlined,
                    iconColor: const Color(0xFF67B7FF),
                    title: 'Privacy Policy',
                    subtitle: 'How we handle your data',
                    onTap: () => _showLegal('privacy'),
                  ),
                ]),
              ),

              const SizedBox(height: 24),

              // ── BILLING ──────────────────────────────────────────────────
              const _SectionHeader(label: 'BILLING'),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _GroupCard(rows: [
                  _RowData(
                    icon: Icons.payment_outlined,
                    iconColor: const Color(0xFF3ECF8E),
                    title: 'Payment issues',
                    subtitle: "Coins not credited? We'll fix it.",
                    onTap: () => _showBillingFaqSheet(
                      title: 'Payment issues',
                      emailSubject: 'UniSync Payment Support',
                    ),
                  ),
                  _RowData(
                    icon: Icons.currency_rupee_rounded,
                    iconColor: const Color(0xFFFFA94D),
                    title: 'Refund request',
                    subtitle: 'Something wrong with your purchase?',
                    onTap: () => _showBillingFaqSheet(
                      title: 'Refund request',
                      emailSubject: 'UniSync Refund Request',
                    ),
                  ),
                ]),
              ),

              const SizedBox(height: 32),

              // ── Log Out ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _LogOutButton(onTap: () => _showLogoutDialog(context, ref)),
              ),

              const SizedBox(height: 32),

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
                              color: UniSyncColors.textMuted.withOpacity(0.6))),
                      const Text('❤️', style: TextStyle(fontSize: 11)),
                      Text(' by Team Aavishkaar',
                          style: TextStyle(
                              fontSize: 11,
                              color: UniSyncColors.textMuted.withOpacity(0.6))),
                    ]),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text('Version(2.10.18) · Thunder',
                        style: TextStyle(
                          fontSize: 10,
                          color: UniSyncColors.textMuted.withOpacity(0.4),
                        )),
                  ),
                ]),
              ),

              const SizedBox(height: 32),
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
      padding: const EdgeInsets.symmetric(horizontal: 24),
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
                color: UniSyncColors.surfaceCard,
                border: Border.all(
                    color: isPremium
                        ? const Color(0xFFFFD700).withOpacity(0.5)
                        : UniSyncColors.accent.withOpacity(0.35),
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
                    color: const Color(0xFFFFD700),
                    border: Border.all(
                        color: UniSyncColors.backgroundPrimary, width: 2),
                  ),
                  child: const Icon(Icons.workspace_premium_rounded,
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
                        color: UniSyncColors.backgroundPrimary, width: 2),
                  ),
                  child: const Icon(Icons.check,
                      size: 13, color: Colors.white),
                ),
              ),
          ]),

          const SizedBox(width: 16),

          // Name + email + bio
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name.isEmpty ? 'Your Name' : user.name,
                  style: GoogleFonts.playfairDisplay(
                    color: UniSyncColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  user.emailId,
                  style: const TextStyle(
                    color: UniSyncColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                if (bio.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    bio,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: UniSyncColors.accentHover,
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
    return NeoPopButton(
      color: const Color(0xFF0C1510),
      bottomShadowColor: const Color(0xFF1A6B4A),
      rightShadowColor: const Color(0xFF1A6B4A),
      depth: 4,
      onTapUp: _openCoinPurchaseSheet,
      onTapDown: () {},
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row — icon + balance
            Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF3ECF8E).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: const Color(0xFF3ECF8E).withOpacity(0.3)),
                ),
                child: const Icon(Iconsax.coin_14,
                    size: 20, color: Color(0xFF3ECF8E)),
              ),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('UniCoins',
                    style: TextStyle(
                      color: UniSyncColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    )),
                const SizedBox(height: 1),
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(
                    '$coins',
                    style: const TextStyle(
                      color: Color(0xFF3ECF8E),
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.5,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('~ ₹${(coins*0.09).toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: UniSyncColors.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        )),
                  ),
                ]),
              ]),
              const Spacer(),
              // Top-up pill button
              NeoPopButton(
                color: const Color(0xFF3ECF8E),
                bottomShadowColor: const Color(0xFF1A6B4A),
                rightShadowColor: const Color(0xFF1A6B4A),
                depth: 3,
                buttonPosition: Position.fullBottom,
                onTapUp: () {
                  _openCoinPurchaseSheet();
                },
                onTapDown: () {},
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.add_rounded, size: 14, color: Colors.black),
                    SizedBox(width: 4),
                    Text('Top Up',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.1,
                        )),
                  ]),
                ),
              ),
            ]),

            const SizedBox(height: 12),
            Divider(color: const Color(0xFF3ECF8E).withOpacity(0.12), height: 1),
            const SizedBox(height: 12),

            // Bottom hint
            Column(
              children: [
                Row(children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 12, color: UniSyncColors.textMuted),
                  const SizedBox(width: 5),
                  Expanded(
                    child: const Text('Use coins to unlock premium features in the app',
                        style: TextStyle(
                          color: UniSyncColors.textMuted,
                          fontSize: 11,
                          height: 1.4,
                        )),
                  ),
                ]),
                SizedBox(height: 3,),
                 Row(children: [
                  const Icon(Icons.stars_sharp,
                      size: 12, color: UniSyncColors.textMuted),
                  const SizedBox(width: 5),
                  Expanded(
                    child: const Text('Soon you will be able to withdraw real money as well!',
                        style: TextStyle(
                          color: UniSyncColors.textMuted,
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
    return NeoPopButton(
      color: const Color(0xFF100E04),
      bottomShadowColor: const Color(0xFF7A5010),
      rightShadowColor: const Color(0xFF7A5010),
      depth: 4,
      onTapUp: _handleAdFreePurchase,
      onTapDown: () {},
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(children: [
          // Icon badge
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.28)),
            ),
            child: const Icon(Icons.workspace_premium_rounded,
                size: 22, color: Color(0xFFFFD700)),
          ),
          const SizedBox(width: 14),

          // Text block
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Text('Go Ad-Free',
                    style: TextStyle(
                      color: UniSyncColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    )),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3ECF8E).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('90% OFF',
                      style: TextStyle(
                        color: Color(0xFF3ECF8E),
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      )),
                ),
              ]),
              const SizedBox(height: 3),
              // Price row
              Row(children: [
                Text('₹99',
                    style: TextStyle(
                      color: UniSyncColors.textMuted,
                      fontSize: 11,
                      decoration: TextDecoration.lineThrough,
                      decorationColor: UniSyncColors.textMuted,
                    )),
                const SizedBox(width: 5),
                const Text('₹10 only',
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    )),
              ]),
              const SizedBox(height: 5),
              // Feature bullets
              const Text('✦  No ads, ever',
                  style: TextStyle(
                    color: UniSyncColors.textSecondary,
                    fontSize: 11,
                    height: 1.5,
                  )),
              const Text('✦  Support the team ❤️',
                  style: TextStyle(
                    color: UniSyncColors.textSecondary,
                    fontSize: 11,
                    height: 1.5,
                  )),
            ]),
          ),

          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_rounded,
              color: Color(0xFFFFD700), size: 18),
        ]),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _buildAvatarFallback(UserModel user) {
    return Center(
      child: Text(
        _initials(user.name),
        style: const TextStyle(
          color: UniSyncColors.accent,
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
      const SnackBar(
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
      backgroundColor: UniSyncColors.backgroundSecondary,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const NoticeBoardModal(),
    );
  }

  void _showLegal(String type) {
    showModalBottomSheet(
      context: context,
      backgroundColor: UniSyncColors.backgroundSecondary,
      shape: const RoundedRectangleBorder(
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
      backgroundColor: UniSyncColors.backgroundSecondary,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
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
        backgroundColor: UniSyncColors.backgroundSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFE05252).withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.logout_rounded,
                    color: Color(0xFFE05252), size: 18),
              ),
              const SizedBox(height: 14),
              const Text('Log out?',
                  style: TextStyle(
                    color: UniSyncColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  )),
              const SizedBox(height: 6),
              const Text(
                  "You'll need to log in again to access your profile.",
                  style: TextStyle(
                    color: UniSyncColors.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  )),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: UniSyncColors.textSecondary,
                      side: const BorderSide(color: UniSyncColors.border),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Cancel',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFFE05252),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      ref.read(authControllerProvider).signOut();
                      Routemaster.of(ctx).replace('/');
                    },
                    child: const Text('Log Out',
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
  const _ProfileAppBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1/0,
      color: UniSyncColors.backgroundSecondary,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '#FIX YOUR BUG\'S',
            style: GoogleFonts.dmSans(
              color: UniSyncColors.accent,
              fontSize: 9,
              fontWeight: FontWeight.w500,
              letterSpacing: 2.2,
            ),
          ),
          const SizedBox(height: 3),
          RichText(
            text: TextSpan(children: [
              TextSpan(
                text: 'Profile ',
                style: GoogleFonts.playfairDisplay(
                  color: UniSyncColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              TextSpan(
                text: 'settings',
                style: GoogleFonts.playfairDisplay(
                  color: UniSyncColors.accent,
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
  const _EditField({
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
      style: const TextStyle(
          color: UniSyncColors.textPrimary, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
            color: UniSyncColors.textMuted, fontSize: 12),
        prefixIcon: Icon(icon, size: 16, color: UniSyncColors.textMuted),
        filled: true,
        fillColor: UniSyncColors.backgroundPrimary,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              BorderSide(color: UniSyncColors.border.withOpacity(0.6)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              BorderSide(color: UniSyncColors.border.withOpacity(0.6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
              color: UniSyncColors.accent.withOpacity(0.6), width: 1.2),
        ),
      ),
    );
  }
}

class _LogOutButton extends StatelessWidget {
  const _LogOutButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return NeoPopButton(
      color: const Color(0xFF1C0808),
      bottomShadowColor: const Color(0xFF8B1A1A),
      rightShadowColor: const Color(0xFF8B1A1A),
      depth: 4,
      onTapUp: onTap,
      onTapDown: () {},
      child: const SizedBox(
        width: double.infinity,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, size: 16, color: Color(0xFFE05252)),
              SizedBox(width: 8),
              Text(
                'Log Out',
                style: TextStyle(
                  color: Color(0xFFE05252),
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
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          color: UniSyncColors.textMuted.withOpacity(0.65),
          fontSize: 10,
          fontWeight: FontWeight.w500,
          letterSpacing: 2.0,
        ),
      ),
    );
  }
}

class _RowData {
  const _RowData({
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
  const _GroupCard({required this.rows});
  final List<_RowData> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: UniSyncColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: UniSyncColors.borderSubtle),
      ),
      child: Column(
        children: List.generate(rows.length, (i) {
          final row = rows[i];
          final isLast = i == rows.length - 1;
          return Column(children: [
            _GroupRowTile(row: row),
            if (!isLast)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(height: 0.6, color: UniSyncColors.divider),
              ),
          ]);
        }),
      ),
    );
  }
}

class _GroupRowTile extends StatelessWidget {
  const _GroupRowTile({required this.row});
  final _RowData row;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: row.onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
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
          const SizedBox(width: 13),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(row.title,
                  style: const TextStyle(
                    color: UniSyncColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  )),
              const SizedBox(height: 1),
              Text(row.subtitle,
                  style: const TextStyle(
                    color: UniSyncColors.textSecondary,
                    fontSize: 11,
                    height: 1.3,
                  )),
            ]),
          ),
          if (row.trailing != null)
            row.trailing!
          else
            const Icon(Icons.chevron_right_rounded,
                color: UniSyncColors.textMuted, size: 18),
        ]),
      ),
    );
  }
}

class _CopyButton extends StatefulWidget {
  const _CopyButton({required this.text});
  final String text;

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.text));
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _copy,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _copied
            ? const Icon(Icons.check_rounded,
                key: ValueKey('check'),
                color: Color(0xFF3ECF8E), size: 17)
            : Icon(Icons.copy_rounded,
                key: const ValueKey('copy'),
                color: UniSyncColors.textMuted.withOpacity(0.65),
                size: 16),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// EDIT PROFILE BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _EditProfileSheet extends ConsumerStatefulWidget {
  const _EditProfileSheet({
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
        const SnackBar(content: Text('Enter a valid name (min 3 chars)')),
      );
      return;
    }
    if (_selectedSem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your semester')),
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
          color: UniSyncColors.backgroundSecondary,
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: UniSyncColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Header
              Text(
                'Edit Profile',
                style: GoogleFonts.playfairDisplay(
                  color: UniSyncColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Update your name, semester and bio',
                style: GoogleFonts.dmSans(
                  color: UniSyncColors.textMuted,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 20),

              // Name
              _SheetField(
                controller: _nameCtrl,
                label: 'Display name',
                icon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 12),

              // College — read-only
              _SheetField(
                controller: TextEditingController(
                    text: widget.user.collegeName ?? ''),
                label: 'College',
                icon: Icons.account_balance_outlined,
                readOnly: true,
              ),
              const SizedBox(height: 16),

              // Semester label
              Text(
                'Semester',
                style: GoogleFonts.dmSans(
                  color: UniSyncColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 8),

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
                      duration: const Duration(milliseconds: 180),
                      width: 58,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? UniSyncColors.accent
                            : UniSyncColors.surfaceCard,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected
                              ? UniSyncColors.accent
                              : UniSyncColors.border.withOpacity(0.6),
                        ),
                      ),
                      child: Column(children: [
                        Text(
                          '$sem',
                          style: TextStyle(
                            color: selected
                                ? UniSyncColors.buttonPrimaryFg
                                : UniSyncColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'sem',
                          style: TextStyle(
                            color: selected
                                ? UniSyncColors.buttonPrimaryFg
                                    .withOpacity(0.75)
                                : UniSyncColors.textMuted,
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ]),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),

              // Bio
              _SheetField(
                controller: _aboutCtrl,
                label: 'Bio',
                icon: Icons.notes_rounded,
                maxLines: 3,
              ),
              const SizedBox(height: 20),

              // Save — NeoPopButton
              NeoPopButton(
                color: _saving
                    ? UniSyncColors.textDisabled
                    : UniSyncColors.accent,
                bottomShadowColor: UniSyncColors.backgroundPrimary,
                rightShadowColor: UniSyncColors.backgroundPrimary,
                depth: 4,
                onTapUp: _saving ? null : _save,
                onTapDown: () {},
                child: SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    child: Center(
                      child: _saving
                          ? const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              'Save Changes',
                              style: GoogleFonts.dmSans(
                                color: UniSyncColors.buttonPrimaryFg,
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
  const _SheetField({
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
            ? UniSyncColors.textMuted
            : UniSyncColors.textPrimary,
        fontSize: 13,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(color: UniSyncColors.textMuted, fontSize: 12),
        prefixIcon:
            Icon(icon, size: 16, color: UniSyncColors.textMuted),
        filled: true,
        fillColor: readOnly
            ? UniSyncColors.backgroundPrimary.withOpacity(0.5)
            : UniSyncColors.backgroundPrimary,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
              color: UniSyncColors.border.withOpacity(0.6)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
              color: readOnly
                  ? UniSyncColors.border.withOpacity(0.3)
                  : UniSyncColors.border.withOpacity(0.6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
              color: readOnly
                  ? UniSyncColors.border.withOpacity(0.3)
                  : UniSyncColors.accent.withOpacity(0.6),
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
  const _BillingFaqSheet({
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
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: UniSyncColors.accent.withOpacity(0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.help_outline_rounded,
                  color: UniSyncColors.accent, size: 18),
            ),
            const SizedBox(height: 14),
            Text(title,
                style: const TextStyle(
                  color: UniSyncColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                )),
            const SizedBox(height: 6),
            const Text('Before emailing us, please check these quick answers.',
                style: TextStyle(
                    color: UniSyncColors.textSecondary,
                    fontSize: 12,
                    height: 1.45)),
            const SizedBox(height: 16),
            _FaqPoint(
  question: 'Purchase not showing after switching account?',
  answer:
      'If you purchased ad-free using one Google account but are now logged in with a different account, the purchase will only be linked to the original UniSync account. Please log in with the same account used during purchase to restore access. For any issues, contact us via email.',
),
            const _FaqPoint(
              question: 'Payment succeeded but coins/ad-free did not show up?',
              answer: 'Wait a minute, reopen the app once, then check again.',
            ),
            const _FaqPoint(
              question: 'Money deducted but feature still missing?',
              answer:
                  'Share your account email, purchase time, and item — we\'ll verify it fast.',
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: UniSyncColors.accent,
                  foregroundColor: UniSyncColors.buttonPrimaryFg,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: onEmailTap,
                child: const Text('Email Support',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 8),
            Text('Subject: $emailSubject',
                style: const TextStyle(
                    color: UniSyncColors.textMuted, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _FaqPoint extends StatelessWidget {
  const _FaqPoint({required this.question, required this.answer});
  final String question, answer;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(question,
            style: const TextStyle(
              color: UniSyncColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            )),
        const SizedBox(height: 3),
        Text(answer,
            style: const TextStyle(
              color: UniSyncColors.textSecondary,
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
  const NoticeBoardModal({super.key});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        color: UniSyncColors.backgroundSecondary,
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: UniSyncColors.border,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          Text('What\'s new?',
              style: GoogleFonts.dmSans(
                color: UniSyncColors.accent,
                fontSize: 9,
                fontWeight: FontWeight.w500,
                letterSpacing: 2.2,
              )),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(children: [
              TextSpan(
                  text: 'Latest ',
                  style: GoogleFonts.playfairDisplay(
                    color: UniSyncColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  )),
              TextSpan(
                  text: 'announcements',
                  style: GoogleFonts.playfairDisplay(
                    color: UniSyncColors.accent,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    fontStyle: FontStyle.italic,
                    letterSpacing: -0.3,
                  )),
            ]),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: FutureBuilder(
              future: getNoticesData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: UniSyncColors.accent));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                      child: Text('No notices posted yet.',
                          style: TextStyle(
                              color: UniSyncColors.textSecondary)));
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
  const _NoticeItem(
      {required this.heading,
      required this.description,
      required this.date});
  final String heading, description;
  final Timestamp date;

  @override
  Widget build(BuildContext context) {
    final formatted = DateFormat('dd MMM yyyy').format(date.toDate());
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: UniSyncColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFF67B7FF).withOpacity(0.15)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Text(heading,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: UniSyncColors.textPrimary,
                )),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF67B7FF).withOpacity(0.10),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(formatted,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF67B7FF),
                  fontWeight: FontWeight.w500,
                )),
          ),
        ]),
        const SizedBox(height: 8),
        Text(description,
            style: const TextStyle(
              fontSize: 12,
              color: UniSyncColors.textSecondary,
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
  const LegalOptionsModal({super.key, this.initialTab = 'terms'});
  final String initialTab;

  void _open(BuildContext context, String title, Future<String> future) {
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: UniSyncColors.backgroundSecondary,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => FutureBuilder<String>(
        future: future,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const SizedBox(
                height: 200,
                child: Center(
                    child: CircularProgressIndicator(
                        color: UniSyncColors.accent)));
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
            return const SizedBox(
              height: 200,
              child: Center(
                child: CircularProgressIndicator(
                  color: UniSyncColors.accent,
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
      color: UniSyncColors.backgroundSecondary,
      padding: const EdgeInsets.all(20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(
          child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: UniSyncColors.border,
                  borderRadius: BorderRadius.circular(2))),
        ),
        const SizedBox(height: 20),
        const Text('Legal Information',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: UniSyncColors.textPrimary,
            )),
        const SizedBox(height: 14),
        ListTile(
          tileColor: UniSyncColors.surfaceCard,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          leading: const Icon(Icons.description,
              color: Color(0xFF3ECF8E), size: 20),
          title: const Text('Terms & Conditions',
              style: TextStyle(
                  color: UniSyncColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          trailing: const Icon(Icons.arrow_forward_ios,
              color: UniSyncColors.textMuted, size: 13),
          onTap: () =>
              _open(context, 'Terms & Conditions', fetchTermsText()),
        ),
        const SizedBox(height: 8),
        ListTile(
          tileColor: UniSyncColors.surfaceCard,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          leading:
              const Icon(Icons.privacy_tip, color: Color(0xFF67B7FF), size: 20),
          title: const Text('Privacy Policy',
              style: TextStyle(
                  color: UniSyncColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          trailing: const Icon(Icons.arrow_forward_ios,
              color: UniSyncColors.textMuted, size: 13),
          onTap: () => _open(context, 'Privacy Policy', fetchPolicyText()),
        ),
        const SizedBox(height: 12),
      ]),
    );
  }
}

class LegalDocumentModal extends StatelessWidget {
  const LegalDocumentModal(
      {super.key, required this.title, required this.content});
  final String title, content;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      builder: (context, scrollController) => Container(
        color: UniSyncColors.backgroundSecondary,
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(
            child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: UniSyncColors.border,
                    borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 20),
          Text(title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: UniSyncColors.textPrimary,
              )),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              child: Text(content,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.6,
                    color: UniSyncColors.textSecondary,
                  )),
            ),
          ),
        ]),
      ),
    );
  }
}
