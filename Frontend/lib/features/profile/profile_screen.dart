
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:neopop/neopop.dart';
import 'package:routemaster/routemaster.dart';
import 'package:UniSync/app/providers.dart';
import 'package:UniSync/constants/constant.dart';
import 'package:UniSync/features/auth/auth_controller.dart';
import 'package:UniSync/models/user_model.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.read(userProvider);

    return Scaffold(
      backgroundColor: UniSyncColors.backgroundPrimary,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(user!),
              _buildQuickActionsSection(),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Divider(color: UniSyncColors.divider),
              ),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildHeader(UserModel user) {
  return Container(
    height: 250,
    width: double.infinity,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      borderRadius: const BorderRadius.only(
        bottomLeft:  Radius.circular(40),
        bottomRight: Radius.circular(40),
      ),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF141414),
          Color(0xFF0E1813),
          Color(0xFF0B0B0D),
        ],
      ),
      border: Border.all(color: UniSyncColors.borderSubtle),
    ),
    child: Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end:   Alignment.bottomRight,
                colors: [
                  UniSyncColors.accent.withOpacity(0.07),
                  Colors.transparent,
                  const Color(0xFF3ECF8E).withOpacity(0.09),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: -30,
          right: -20,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: UniSyncColors.accent.withOpacity(0.08),
            ),
          ),
        ),
        Positioned(
          bottom: 18,
          right: 20,
          child: Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF3ECF8E).withOpacity(0.25),
              ),
            ),
          ),
        ),
        _buildBackButton(),
        _buildProfileInfo(user),
      ],
    ),
  );
}

 
  // Stack(children: [
  //       Container(child: Image.asset('assets/icons/profile_bg.png')),
  //         _buildBackButton(),
  //   _buildProfileInfo(user),
  //     ]
  //       ),

  Widget _buildBackButton() {
    return Positioned(
      top: 10,
      left: 10,
      child: GestureDetector(
                    onTap: () => Routemaster.of(context).pop(),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: UniSyncColors.surfaceCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: UniSyncColors.border),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        size: 20,
                        color: UniSyncColors.textPrimary,
                      ),
                    ),
                  ),
    );
  }

 Widget _buildProfileInfo(UserModel user) => Positioned(
  bottom: 18,
  left:   16,
  right:  16,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: UniSyncColors.accent.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: UniSyncColors.accent.withOpacity(0.22)),
        ),
        child: const Text(
          '#PROFILE',
          style: TextStyle(
            color: UniSyncColors.accent,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.8,
          ),
        ),
      ),
      const SizedBox(height: 12),
      Text(
        user.name.isEmpty ? 'Not Found' : user.name,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: UniSyncColors.textPrimary,
          letterSpacing: -0.6,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        user.emailId,
        style: const TextStyle(
          fontSize: 14,
          color: UniSyncColors.textSecondary,
        ),
      ),
      if (user.year != null) ...[
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF3ECF8E).withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF3ECF8E).withOpacity(0.2)),
          ),
          child: Text(
            'B.Tech · Sem ${user.year}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF3ECF8E),
            ),
          ),
        ),
      ],
    ],
  ),
);


  Widget _buildQuickActionsSection() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '#ACCOUNT',
              style: TextStyle(
                color: UniSyncColors.accent,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.8,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Your space',
              style: TextStyle(
                color: UniSyncColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Manage support links, legal info, and your UniSync setup.',
              style: TextStyle(
                color: UniSyncColors.textSecondary,
                fontSize: 12,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            _buildTilesGrid(),

          ],
        ),
      ),
    );
  }

  Widget _buildTilesGrid() {
    return Column(
      children: [
        _buildNoticeBoardTile(),
        const SizedBox(height: 8),
        const Divider(color: UniSyncColors.divider, thickness: 1),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildActionTile(
                title: 'Settings',
                subtitle: 'App preferences and support shortcuts',
                icon: Icons.settings,
                color: Colors.teal,
                onTap: () => Routemaster.of(context).push('/settings'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
                  child: _buildActionTile(
                    title: 'Follow Us!',
                    subtitle: 'Show us some love on Instagram',
                    icon: Icons.share,
                    color: Colors.indigo,
                    onTap: _openInstagram,
                  ),
                ),
          ],
        ),
        SizedBox(height: 10,),
        Row(
          children: [
            Expanded(
              child: _buildActionTile(
                title: 'Report Issues/bugs',
                subtitle: 'Connect via Email',
                icon: Icons.bug_report,
                color: Colors.orange,
                onTap: _openGmail,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionTile(
                title: 'Legal',
                subtitle: 'Privacy Policy and T&C',
                icon: Icons.policy,
                color: Colors.green,
                onTap: _showLegalOptions,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return NeoPopButton(
      color: UniSyncColors.surfaceCard,
      bottomShadowColor: color,
      rightShadowColor: color,
      depth: 3,
      onTapUp: onTap,
      onTapDown: () {},
      child: SizedBox(
        height: 108,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.28)),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: UniSyncColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: UniSyncColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  
Widget _buildNoticeBoardTile() {
    return NeoPopButton(
      color: const Color(0xFF121A24),
      bottomShadowColor: const Color(0xFF67B7FF),
      rightShadowColor: const Color(0xFF67B7FF),
      depth: 4,
      onTapUp: _showNoticeBoard,
      onTapDown: () {},
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF67B7FF).withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF67B7FF).withOpacity(0.24)),
              ),
              child: const Icon(Icons.notifications_active_rounded, color: Color(0xFF67B7FF), size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notice Board',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: UniSyncColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Latest announcements',
                    style: TextStyle(
                      fontSize: 13,
                      color: UniSyncColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Color(0xFF67B7FF),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }





  Widget _buildBackgroundPattern() {
    return Stack(
      children: [
        Positioned(
          right: -20,
          top: -20,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.1),
            ),
          ),
        ),
        Positioned(
          right: 20,
          bottom: -30,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.05),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoticeBoardContent() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.campaign, color: Colors.white, size: 24),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withOpacity(0.8),
                size: 16,
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '📢 Notice Board',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Latest college updates and announcements',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: NeoPopTiltedButton(
              isFloating: true,
              decoration: const NeoPopTiltedButtonDecoration(
                color: Color(0xFFFF5C74),
                plunkColor: Color(0xFFFF5C74),
                shadowColor: Colors.black,
                showShimmer: false,
              ),
              onTapUp: () => _showLogoutDialog(context),
              child: const SizedBox(
                height: 56,
                child: Center(
                  child: Text(
                    'Log Out',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: UniSyncColors.onError,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
             onTap: () => launchUrl(
            Uri.parse(
                'https://www.linkedin.com/company/unisyncofficial/'),
            mode: LaunchMode.externalApplication,
          ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Made with ',
                  style: TextStyle(
                    fontSize: 13,
                    color: UniSyncColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Text('❤️', style: TextStyle(fontSize: 13)),
                Text(
                  ' by Team Aavishkaar',
                  style: TextStyle(
                    fontSize: 13,
                    color: UniSyncColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.rocket_launch, size: 16, color: Colors.pink[400]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Action methods
  void _openInstagram() async {
    const url = 'https://www.instagram.com/unisyncofficial/';
    await launchUrl(Uri.parse(url));
    
  }

  void _openGmail() async {
    const url = 'mailto:varshithteja86@gmail.com?subject=UniSync Bug Report';
    await launchUrl(Uri.parse(url));
  }

  void _showNoticeBoard() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: UniSyncColors.backgroundSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const NoticeBoardModal(),
    );
  }

  void _showLegalOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: UniSyncColors.backgroundSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const LegalOptionsModal(),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: UniSyncColors.surfaceCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Are you sure?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: UniSyncColors.textPrimary,
            ),
          ),
          content: const Text(
            'Do you really want to log out? You\'ll need to log in again to access your profile.',
            style: TextStyle(
              fontSize: 16,
              color: UniSyncColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: UniSyncColors.textMuted),
              ),
            ),
            TextButton(
              onPressed: () async {
                ref.read(authControllerProvider).signOut();
                Routemaster.of(context).replace('/');
              },
              child: const Text(
                'Log Out',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}

Future<List<Map<String,dynamic>>> getNoticesData() async{
  final snapshot = await FirebaseFirestore.instance.collection('notice').get();
  return snapshot.docs.map((eachd) => eachd.data()).toList();
}

// Separate modal widgets for better organization
class NoticeBoardModal extends StatefulWidget {
  const NoticeBoardModal({super.key});

  @override
  State<NoticeBoardModal> createState() => _NoticeBoardModalState();
}

class _NoticeBoardModalState extends State<NoticeBoardModal> {
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      builder: (context, scrollController) => Container(
        color: UniSyncColors.backgroundSecondary,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHandle(),
            const SizedBox(height: 20),
            const Text(
              '📢 College Notice Board',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: UniSyncColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: FutureBuilder(
                future: getNoticesData(),
                builder: (context,snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: UniSyncColors.accent),
            );
          } else if (snapshot.hasError) {
            return const Center(
              child: Text(
                "Our servers are busy right now.",
                style: TextStyle(color: UniSyncColors.textSecondary),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "No notices posted yet.",
                style: TextStyle(color: UniSyncColors.textSecondary),
              ),
            );
          } else {
            final d = snapshot.data!;
            return ListView.builder(
              itemCount: d.length,
              itemBuilder: (context,index){
                final l = d[index];
                return _buildNoticeItem(
                  l['heading'],
                  l['description'],
                  l['date'],
                  );
              }
            );
          }
                }
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: UniSyncColors.border,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildNoticeItem(String heading, String description, Timestamp date) {
    String formattedDate = DateFormat('dd MMM yyyy').format(date.toDate());
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: UniSyncColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF67B7FF).withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  heading,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: UniSyncColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF67B7FF).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  formattedDate,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF67B7FF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(
              fontSize: 14,
              color: UniSyncColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class LegalOptionsModal extends StatefulWidget {
  const LegalOptionsModal({super.key});

  @override
  State<LegalOptionsModal> createState() => _LegalOptionsModalState();
}

Future<String> fetchPolicyText() async {
  final snapshot = await FirebaseFirestore.instance
      .collection('texts')
      .doc('policy')
      .get();

  if (snapshot.exists) {
    return snapshot.data()!['text'];
  } else {
    throw Exception('Updating Soon');
  }
}

Future<String> fetchTermsText() async {
  final snapshot = await FirebaseFirestore.instance
      .collection('texts')
      .doc('t_c')
      .get();

  if (snapshot.exists) {
    return snapshot.data()!['text'];
  } else {
    throw Exception('Updating soon');
  }
}


class _LegalOptionsModalState extends State<LegalOptionsModal> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: UniSyncColors.backgroundSecondary,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: UniSyncColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Legal Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: UniSyncColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          FutureBuilder(
            future: fetchPolicyText(),
            builder: (context,snapshot){

              if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: LinearProgressIndicator(color: UniSyncColors.accent),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: const TextStyle(color: UniSyncColors.textSecondary),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "No data found",
                style: TextStyle(color: UniSyncColors.textSecondary),
              ),
            );
          } else {

            final data = snapshot.data!;
              
            return ListTile(
              tileColor: UniSyncColors.surfaceCard,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              leading: const Icon(Icons.description, color: Color(0xFF3ECF8E)),
              title: const Text('Terms & Conditions', style: TextStyle(color: UniSyncColors.textPrimary)),
              trailing: const Icon(Icons.arrow_forward_ios, color: UniSyncColors.textMuted),
              onTap: () {
                Navigator.pop(context);
                _showTermsAndConditions(context,data);
              },
            );
            }
            }
          ),
          FutureBuilder(
            future: fetchTermsText(),
            builder: (context,snapshot){

              if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: LinearProgressIndicator(color: UniSyncColors.accent),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: const TextStyle(color: UniSyncColors.textSecondary),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "No data found",
                style: TextStyle(color: UniSyncColors.textSecondary),
              ),
            );
          } else {
            final data = snapshot.data!;
            return ListTile(
              tileColor: UniSyncColors.surfaceCard,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              leading: const Icon(Icons.privacy_tip, color: Color(0xFF67B7FF)),
              title: const Text('Privacy Policy', style: TextStyle(color: UniSyncColors.textPrimary)),
              trailing: const Icon(Icons.arrow_forward_ios, color: UniSyncColors.textMuted),
              onTap: () {
                Navigator.pop(context);
                _showPrivacyPolicy(context,data);
              },
            );
          }
            }
          ),
        ],
      ),
    );
  }

  void _showTermsAndConditions(BuildContext, String content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: UniSyncColors.backgroundSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) =>  LegalDocumentModal(
        title: 'Terms & Conditions',
        content: content
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context, String content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: UniSyncColors.backgroundSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) =>  LegalDocumentModal(
        title: 'Privacy Policy',
        content: content
      ),
    );
  }
}

class LegalDocumentModal extends StatelessWidget {
  final String title;
  final String content;

  const LegalDocumentModal({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      builder: (context, scrollController) => Container(
        color: UniSyncColors.backgroundSecondary,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: UniSyncColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: UniSyncColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                  child: Text(
                    content,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: UniSyncColors.textSecondary,
                    ),
                  ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
