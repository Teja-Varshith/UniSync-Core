import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:neopop/neopop.dart';
import 'package:routemaster/routemaster.dart';
import 'package:UniSync/ads%20Manager/add_manager.dart';
import 'package:UniSync/app/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:UniSync/constants/constant.dart';
import 'package:UniSync/firebase_service.dart';
import 'package:UniSync/features/opputunities/oppurtunities_controller.dart';
import 'package:UniSync/features/opputunities/oppurtunity_model.dart';

_OpportunityPalette _ui(BuildContext context) => _OpportunityPalette.of(context);

class _OpportunityPalette {
  _OpportunityPalette({
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

  factory _OpportunityPalette.of(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return _OpportunityPalette(
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

// ── Apply tap counter (persists for the lifetime of the screen) ───────────────
int _applyTapCount = 0;

class OpportunityDetailsScreen extends ConsumerStatefulWidget {
  final String opportunityId;

  OpportunityDetailsScreen({
    super.key,
    required this.opportunityId,
  });

  @override
  ConsumerState<OpportunityDetailsScreen> createState() =>
      _OpportunityDetailsScreenState();
}

class _OpportunityDetailsScreenState
    extends ConsumerState<OpportunityDetailsScreen> {
  late final Future<OpportunityModel?> _opportunityFuture;

  @override
  void initState() {
    super.initState();
    _opportunityFuture = ref
        .read(opportunityControllerProvider.notifier)
        .getOpportunityById(widget.opportunityId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ui(context).backgroundPrimary,
      body: FutureBuilder<OpportunityModel?>(
        future: _opportunityFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: _ui(context).accent),
              ),
            );
          }

          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data == null) {
            return SafeArea(
              child: Column(
                children: [
                  Container(
                    color: _ui(context).backgroundSecondary,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    child: Row(
                      children: [
                        _BackButton(onTap: () => Routemaster.of(context).pop()),
                        SizedBox(width: 14),
                        Text(
                          'Details',
                          style: TextStyle(
                            color: _ui(context).textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(height: 0.8, color: _ui(context).divider),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline_rounded,
                              color: _ui(context).textMuted, size: 36),
                          SizedBox(height: 12),
                          Text(
                            'Opportunity not found',
                            style: TextStyle(
                              color: _ui(context).textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return OpportunityDetailsView(opportunity: snapshot.data!);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  DETAILS VIEW
// ─────────────────────────────────────────────────────────────────────────────

class OpportunityDetailsView extends StatefulWidget {
  final OpportunityModel opportunity;

  OpportunityDetailsView({super.key, required this.opportunity});

  @override
  State<OpportunityDetailsView> createState() => _OpportunityDetailsViewState();
}

class _OpportunityDetailsViewState extends State<OpportunityDetailsView> {
  bool _hasLoggedScreenView = false;

  OpportunityModel get opportunity => widget.opportunity;

  bool get _isExpired => opportunity.deadline.isBefore(DateTime.now());
  bool get _isInternship => opportunity.type == OpportunityType.internship;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasLoggedScreenView) return;
    _hasLoggedScreenView = true;
    FirebaseService.logScreenView(screenName: 'opportunity_details_screen');
    FirebaseService.logEvent(
      name: 'opportunity_details_viewed',
      parameters: {
        'opportunity_id': opportunity.id,
        'type': opportunity.type.name,
        'company': opportunity.company,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ui(context).backgroundPrimary,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────
            _buildHeader(context),
            Container(height: 0.8, color: _ui(context).divider),

          

            // ── Scrollable body ──────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [

                      // ── BANNER AD below header ───────────────────────────
            if (!AdManager.instance.isAdFree) ...[
              SizedBox(height: 6),
              Center(child: AdManager.instance.buildBannerAd()),
              SizedBox(height: 6),
              Container(height: 0.8, color: _ui(context).divider),
            ],

                    // ── Hero card ──────────────────────────────
                    _HeroCard(opportunity: opportunity),

                    SizedBox(height: 20),

                    // ── Quick info card ────────────────────────
                    _buildSectionLabel('#QUICK INFO'),
                    SizedBox(height: 10),
                    _QuickInfoCard(opportunity: opportunity),

                    SizedBox(height: 24),

                    // ── Description ────────────────────────────
                    _buildSectionLabel('#DETAILS'),
                    SizedBox(height: 10),
                    _ContentCard(
                      child: Text(
                        opportunity.description,
                        style: TextStyle(
                          color: _ui(context).textSecondary,
                          fontSize: 13,
                          height: 1.7,
                        ),
                      ),
                    ),

                    // ── NATIVE AD between description and requirements ──
                    if (!AdManager.instance.isAdFree) ...[
                      SizedBox(height: 20),
                      _NativeAdCard(),
                    ],

                    // ── Requirements ───────────────────────────
                    if (opportunity.requirements.isNotEmpty) ...[
                      SizedBox(height: 24),
                      _buildSectionLabel('#REQUIREMENTS'),
                      SizedBox(height: 10),
                      _ContentCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: opportunity.requirements
                              .map((req) => _RequirementRow(text: req))
                              .toList(),
                        ),
                      ),
                    ],

                    // ── Skills ─────────────────────────────────
                    if (opportunity.skills.isNotEmpty) ...[
                      SizedBox(height: 24),
                      _buildSectionLabel('#SKILLS'),
                      SizedBox(height: 10),
                      _ContentCard(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: opportunity.skills
                              .map((skill) => _SkillChip(label: skill))
                              .toList(),
                        ),
                      ),
                    ],

                    // ── Additional details ─────────────────────
                    SizedBox(height: 24),
                    _buildSectionLabel('#MORE INFO'),
                    SizedBox(height: 10),
                    _AdditionalDetailsCard(opportunity: opportunity),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // ── Apply FAB ─────────────────────────────────────────────
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _ApplyButton(
        isExpired: _isExpired,
        onTap: () => _handleApplyTap(context),
      ),
    );
  }

  // ── 1-in-5 interstitial on Apply tap ──────────────────────────
  void _handleApplyTap(BuildContext context) {
    FirebaseService.logEvent(
      name: 'opportunity_apply_tapped',
      parameters: {
        'opportunity_id': opportunity.id,
        'type': opportunity.type.name,
        'is_expired': _isExpired.toString(),
      },
    );
    _launchApplicationUrl(context);
    // _applyTapCount++;
    // if (!AdManager.instance.isAdFree && _applyTapCount % 5 == 0) {
    //   AdManager.instance.showInterstitialAd(
    //     onDismissed: () => _launchApplicationUrl(context),
    //   );
    // } else {
    //   _launchApplicationUrl(context);
    // }
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: _ui(context).backgroundSecondary,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Row(
        children: [
          _BackButton(onTap: () => Routemaster.of(context).pop()),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#OPPORTUNITY',
                  style: TextStyle(
                    color: _ui(context).accent,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.8,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  opportunity.company,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _ui(context).textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _isExpired
                  ? _ui(context).error.withValues(alpha: 0.12)
                  : _ui(context).accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: _isExpired
                    ? _ui(context).error.withValues(alpha: 0.4)
                    : _ui(context).accent.withValues(alpha: 0.4),
              ),
            ),
            child: Text(
              _isExpired ? 'Closed' : 'Active',
              style: TextStyle(
                color: _isExpired ? _ui(context).error : _ui(context).accent,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        color: _ui(context).accent,
        fontSize: 9,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.8,
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]}, ${date.year}';
  }

  Future<void> _launchApplicationUrl(BuildContext context) async {
    final Uri uri = Uri.parse(opportunity.applicationLink);
    FirebaseService.logEvent(
      name: 'opportunity_application_opened',
      parameters: {
        'opportunity_id': opportunity.id,
        'type': opportunity.type.name,
      },
    );
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $uri');
    }
  }

  void _shareOpportunity(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Working on it — share coming soon!'),
        backgroundColor: _ui(context).accent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  NATIVE AD CARD — inline between sections
// ─────────────────────────────────────────────────────────────────────────────

class _NativeAdCard extends StatefulWidget {
  _NativeAdCard();
  @override
  State<_NativeAdCard> createState() => _NativeAdCardState();
}

class _NativeAdCardState extends State<_NativeAdCard> {
  // ⚠️ Replace with your real native ad unit ID
  // Test ID: 'ca-app-pub-3940256099942544/2247696110'
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
      factoryId: 'small', // registered in MainActivity.kt
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
      height: 100,
      decoration: BoxDecoration(
        color: _ui(context).surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _ui(context).borderSubtle),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: AdWidget(ad: _nativeAd!),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  ALL WIDGETS BELOW UNCHANGED
// ─────────────────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  _HeroCard({required this.opportunity});
  final OpportunityModel opportunity;

  bool get _isInternship => opportunity.type == OpportunityType.internship;

  @override
  Widget build(BuildContext context) {
    final deadlineDiff =
        opportunity.deadline.difference(DateTime.now()).inDays;
    final deadlineLabel = deadlineDiff < 0
        ? 'Expired'
        : deadlineDiff == 0
            ? 'Today'
            : deadlineDiff == 1
                ? 'Tomorrow'
                : '$deadlineDiff days left';
    final deadlineColor = deadlineDiff <= 3
        ? _ui(context).error
        : _ui(context).accent;

    return NeoPopButton(
      color: _ui(context).surfaceCard,
      bottomShadowColor: _ui(context).accent,
      rightShadowColor: _ui(context).accent,
      depth: 4,
      onTapUp: () {},
      onTapDown: () {},
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _ui(context).backgroundSecondary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _ui(context).border),
                  ),
                  child: opportunity.logoUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            opportunity.logoUrl!,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.business_rounded,
                              color: _ui(context).textMuted,
                              size: 22,
                            ),
                          ),
                        )
                      : Icon(Icons.business_rounded,
                          color: _ui(context).textMuted, size: 22),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        opportunity.title,
                        style: TextStyle(
                          color: _ui(context).textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          height: 1.3,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        opportunity.company,
                        style: TextStyle(
                          color: _ui(context).textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 14),
            Container(height: 0.8, color: _ui(context).divider),
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Badge(
                  label: _isInternship ? 'Internship' : 'Hackathon',
                  icon: Icons.work_outline_rounded,
                  color: _ui(context).accent,
                ),
                _Badge(
                  label: deadlineLabel,
                  icon: Icons.schedule_rounded,
                  color: deadlineColor,
                ),
                if (opportunity.isRemote)
                  _Badge(
                    label: 'Remote',
                    icon: Icons.home_outlined,
                    color: _ui(context).accent,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickInfoCard extends StatelessWidget {
  _QuickInfoCard({required this.opportunity});
  final OpportunityModel opportunity;

  @override
  Widget build(BuildContext context) {
    return _ContentCard(
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.location_on_rounded,
            label: 'Location',
            value: opportunity.isRemote ? 'Remote' : opportunity.location,
          ),
          Container(height: 0.8, color: _ui(context).divider,
              margin: const EdgeInsets.symmetric(vertical: 12)),
          _InfoRow(
            icon: Icons.access_time_rounded,
            label: 'Duration',
            value: opportunity.duration,
          ),
          if (opportunity.stipend != null) ...[
            Container(height: 0.8, color: _ui(context).divider,
                margin: const EdgeInsets.symmetric(vertical: 12)),
            _InfoRow(
              icon: Icons.currency_rupee_rounded,
              label: 'Stipend',
              value: opportunity.stipend!,
            ),
          ],
        ],
      ),
    );
  }
}

class _AdditionalDetailsCard extends StatelessWidget {
  _AdditionalDetailsCard({required this.opportunity});
  final OpportunityModel opportunity;

  String _fmt(DateTime d) {
    const m = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${d.day} ${m[d.month - 1]}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return _ContentCard(
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.calendar_today_rounded,
            label: 'Posted',
            value: _fmt(opportunity.postedDate),
          ),
          Container(height: 0.8, color: _ui(context).divider,
              margin: const EdgeInsets.symmetric(vertical: 12)),
          _InfoRow(
            icon: Icons.event_rounded,
            label: 'Deadline',
            value: _fmt(opportunity.deadline),
          ),
          if (opportunity.type == OpportunityType.internship) ...[
            Container(height: 0.8, color: _ui(context).divider,
                margin: const EdgeInsets.symmetric(vertical: 12)),
            _InfoRow(
              icon: Icons.work_outline_rounded,
              label: 'Work Type',
              value: opportunity.isRemote ? 'Remote' : 'On-site',
            ),
          ],
        ],
      ),
    );
  }
}

class _ApplyButton extends StatelessWidget {
  _ApplyButton({required this.isExpired, required this.onTap});
  final bool isExpired;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: NeoPopTiltedButton(
        isFloating: true,
        decoration: NeoPopTiltedButtonDecoration(
          color: isExpired ? _ui(context).textDisabled : _ui(context).accent,
          plunkColor:
              isExpired ? _ui(context).textDisabled : _ui(context).accent,
          shadowColor: Colors.black.withOpacity(_ui(context).isDark ? 0.5 : 0.14),
          showShimmer: !isExpired,
        ),
        onTapUp: isExpired ? () {} : onTap,
        child: SizedBox(
          height: 56,
          width: double.maxFinite,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isExpired)
                  Icon(
                    Icons.rocket_launch_rounded,
                    color: _ui(context).buttonPrimaryFg,
                    size: 18,
                  ),
                if (!isExpired) SizedBox(width: 10),
                Text(
                  isExpired ? 'Application Closed' : 'Apply Now',
                  style: TextStyle(
                    color: isExpired
                        ? _ui(context).backgroundPrimary
                        : _ui(context).buttonPrimaryFg,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContentCard extends StatelessWidget {
  _ContentCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _ui(context).surfaceCard,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _ui(context).border),
      ),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: _ui(context).textMuted),
        SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: _ui(context).textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        Spacer(),
        Text(
          value,
          style: TextStyle(
            color: _ui(context).textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  _Badge({
    required this.label,
    required this.icon,
    required this.color,
  });
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillChip extends StatelessWidget {
  _SkillChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: _ui(context).backgroundSecondary,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _ui(context).border),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: _ui(context).textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _RequirementRow extends StatelessWidget {
  _RequirementRow({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: _ui(context).accent,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: _ui(context).textSecondary,
                fontSize: 13,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  _BackButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return NeoPopButton(
      color: _ui(context).surfaceCard,
      bottomShadowColor: _ui(context).border,
      rightShadowColor: _ui(context).border,
      depth: 3,
      onTapUp: onTap,
      onTapDown: () {},
      child: SizedBox(
        width: 40,
        height: 40,
        child: Center(
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 15,
            color: _ui(context).textMuted,
          ),
        ),
      ),
    );
  }
}

