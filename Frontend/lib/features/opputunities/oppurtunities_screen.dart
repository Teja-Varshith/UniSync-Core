import 'package:UniSync/features/opputunities/oppurtunities_edit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neopop/neopop.dart';
import 'package:routemaster/routemaster.dart';
import 'package:UniSync/ads%20Manager/add_manager.dart';
import 'package:UniSync/app/theme/app_colors.dart';
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

class OpportunitiesScreen extends ConsumerStatefulWidget {
  OpportunitiesScreen({super.key});

  @override
  ConsumerState<OpportunitiesScreen> createState() =>
      _OpportunitiesScreenState();
}

class _OpportunitiesScreenState extends ConsumerState<OpportunitiesScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSeedingSamples = false;
  bool _hasLoggedScreenView = false;
  final List<OpportunityType> type = [
    OpportunityType.internship,
    OpportunityType.hackathon,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_hasLoggedScreenView) return;
      _hasLoggedScreenView = true;
      FirebaseService.logScreenView(screenName: 'opportunities_screen');
      FirebaseService.logFeatureUsage('opportunities');
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _seedSampleOpportunities() async {
    if (_isSeedingSamples) return;

    setState(() => _isSeedingSamples = true);
    final controller = ref.read(opportunityControllerProvider.notifier);
    final now = DateTime.now();

    final samples = [
      OpportunityModel(
        id: '',
        title: 'Flutter Intern - Mobile Team',
        company: 'UniSync Labs',
        description:
            'Work with the mobile team on real Flutter features, testing, and release workflows.',
        location: 'Hyderabad',
        duration: '3 months',
        requirements: [
          'Basic Flutter knowledge',
          'Dart fundamentals',
          'Git basics'
        ],
        skills: ['Flutter', 'Dart', 'Firebase'],
        applicationLink: 'https://example.com/apply/flutter-intern',
        deadline: now.add(Duration(days: 20)),
        postedDate: now,
        type: OpportunityType.internship,
        stipend: '15000/month',
        isRemote: true,
        isActive: true,
      ),
      OpportunityModel(
        id: '',
        title: 'BuildSprint 2026 Hackathon',
        company: 'UniSync Community',
        description:
            '48-hour hackathon to build student-focused tools with mentoring and demo day.',
        location: 'Bengaluru',
        duration: '48 hours',
        requirements: [
          'Team of 1-4',
          'Laptop',
          'Problem statement submission'
        ],
        skills: ['Problem Solving', 'Flutter', 'AI'],
        applicationLink: 'https://example.com/apply/buildsprint-2026',
        deadline: now.add(Duration(days: 12)),
        postedDate: now,
        type: OpportunityType.hackathon,
        stipend: null,
        isRemote: false,
        isActive: true,
      ),
    ];

    int successCount = 0;
    for (final item in samples) {
      final ok = await controller.addOpportunity(item);
      if (ok) successCount++;
    }

    if (!mounted) return;
    setState(() => _isSeedingSamples = false);

    final isFullSuccess = successCount == samples.length;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor:
              isFullSuccess ? _ui(context).success : _ui(context).warning,
          content: Text(
            isFullSuccess
                ? 'Sample opportunities added (internship + hackathon).'
                : 'Added $successCount/${samples.length} sample opportunities.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final selectedFilter = ref.watch(selectedFiltersProvider);
    final opportunitiesAsync = ref.watch(filteredOpportunitiesProvider);
    final controller = ref.read(opportunityControllerProvider.notifier);

    return Scaffold(
      backgroundColor: _ui(context).backgroundPrimary,
      // floatingActionButton: FloatingActionButton.extended(
      //   heroTag: 'seedOppFab',
      //   backgroundColor: _ui(context).accent,
      //   foregroundColor: _ui(context).backgroundPrimary,
      //   onPressed: _seedSampleOpportunities,
      //   icon: _isSeedingSamples
      //       ? SizedBox(
      //           width: 16,
      //           height: 16,
      //           child: CircularProgressIndicator(
      //             strokeWidth: 2,
      //             color: _ui(context).backgroundPrimary,
      //           ),
      //         )
      //       : Icon(Icons.auto_awesome, size: 18),
      //   label: Text(_isSeedingSamples ? 'Seeding...' : 'Seed Samples'),
      // ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────
            Container(
              color: _ui(context).backgroundSecondary,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(children: [
                            TextSpan(
                              text: 'Explore ',
                              style: TextStyle(
                                color: _ui(context).textPrimary,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            TextSpan(
                              text: 'Opportunities',
                              style: TextStyle(
                                color: _ui(context).accent,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ]),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Hackathons & Internships at one place',
                          style: TextStyle(
                            color: _ui(context).textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Type dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: _ui(context).surfaceCard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _ui(context).border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<OpportunityType>(
                        value: selectedFilter,
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: _ui(context).accent,
                          size: 18,
                        ),
                        dropdownColor: _ui(context).backgroundSecondary,
                        borderRadius: BorderRadius.circular(8),
                        style: TextStyle(
                          color: _ui(context).textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        items: type.map((value) {
                          return DropdownMenuItem<OpportunityType>(
                            value: value,
                            child: Text(
                              value == OpportunityType.internship
                                  ? 'Internships'
                                  : 'Hackathons',
                              style: TextStyle(
                                color: _ui(context).textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (OpportunityType? newType) {
                          if (newType != null) {
                            FirebaseService.logEvent(
                              name: 'opportunity_filter_changed',
                              parameters: {'type': newType.name},
                            );
                            ref.read(selectedFiltersProvider.notifier).state =
                                newType;
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Container(height: 0.8, color: _ui(context).divider),

            // ── Search bar ───────────────────────────────────────
            Container(
              color: _ui(context).backgroundSecondary,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  controller.setSearchQuery(value);
                  FirebaseService.logEvent(
                    name: 'opportunity_search_used',
                    parameters: {
                      'has_query': value.trim().isNotEmpty.toString(),
                    },
                  );
                },
                style: TextStyle(
                  color: _ui(context).textPrimary,
                  fontSize: 13,
                ),
                cursorColor: _ui(context).accent,
                decoration: InputDecoration(
                  hintText: 'Search opportunities...',
                  hintStyle: TextStyle(
                    color: _ui(context).textMuted,
                    fontSize: 13,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: _ui(context).textMuted,
                    size: 18,
                  ),
                  filled: true,
                  fillColor: _ui(context).surfaceCard,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 11),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: _ui(context).border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: _ui(context).border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: _ui(context).accent, width: 1.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),

            Container(height: 0.8, color: _ui(context).divider),

            // ── List ─────────────────────────────────────────────
            Expanded(
              child: opportunitiesAsync.when(
                loading: () => Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: _ui(context).accent),
                  ),
                ),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline_rounded,
                          color: _ui(context).textMuted, size: 36),
                      SizedBox(height: 12),
                      Text(
                        'Unable to load opportunities.',
                        style: TextStyle(
                            color: _ui(context).textSecondary, fontSize: 13),
                      ),
                      SizedBox(height: 16),
                      NeoPopButton(
                        color: _ui(context).accent,
                        bottomShadowColor: _ui(context).backgroundPrimary,
                        rightShadowColor: _ui(context).backgroundPrimary,
                        depth: 4,
                        onTapUp: () =>
                            ref.refresh(opportunitiesStreamProvider),
                        onTapDown: () {},
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          child: Text(
                            'Retry',
                            style: TextStyle(
                              color: _ui(context).backgroundPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                data: (opportunities) {
                  if (opportunities.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            color: _ui(context).surfaceCard,
                            child: Icon(Icons.search_off_rounded,
                                color: _ui(context).textMuted, size: 26),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No opportunities found',
                            style: TextStyle(
                              color: _ui(context).textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Try adjusting your filters or search',
                            style: TextStyle(
                              color: _ui(context).textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
                    itemCount: opportunities.length,
                    separatorBuilder: (_, __) => SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final opportunity = opportunities[index];
                      return OpportunityCard(
                        index: index,
                        opportunity: opportunity,
                        onTap: () =>
                            _navigateToDetails(context, opportunity),
                      );
                    },
                  );
                },
              ),
            ),

            //  // ── BANNER AD below header ───────────────────────────
            // if (!AdManager.instance.isAdFree) ...[
            //   SizedBox(height: 6),
            //   Center(child: AdManager.instance.buildBannerAd()),
            //   SizedBox(height: 6),
            //   Container(height: 0.8, color: _ui(context).divider),
            // ],
          ],
        ),
      ),
    );
  }

  void _navigateToDetails(
      BuildContext context, OpportunityModel opportunity) {
    FirebaseService.logEvent(
      name: 'opportunity_opened',
      parameters: {
        'opportunity_id': opportunity.id,
        'type': opportunity.type.name,
        'company': opportunity.company,
      },
    );
    Routemaster.of(context).push('/opportunity/${opportunity.id}');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  OPPORTUNITY CARD
// ─────────────────────────────────────────────────────────────────────────────

class OpportunityCard extends StatelessWidget {
  final OpportunityModel opportunity;
  final VoidCallback onTap;
  final int index;

  OpportunityCard({
    super.key,
    required this.opportunity,
    required this.onTap,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final isInternship = opportunity.type == OpportunityType.internship;
    final deadlineText = _deadlineText(opportunity.deadline);
    final isExpired = deadlineText == 'Expired';
    final isUrgent = !isExpired &&
        opportunity.deadline.difference(DateTime.now()).inDays <= 3;

    return NeoPopButton(
      color: _ui(context).surfaceCard,
      bottomShadowColor: _ui(context).accent,
      rightShadowColor: _ui(context).accent,
      depth: 4,
      onTapUp: onTap,
      onTapDown: () {},
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Header row ──────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo
                Container(
                  width: 50,
                  height: 50,
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
                              size: 20,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.business_rounded,
                          color: _ui(context).textMuted,
                          size: 20,
                        ),
                ),

                SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        opportunity.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _ui(context).textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
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

                SizedBox(width: 8),

                // Type badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: _ui(context).accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: _ui(context).accent.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    isInternship ? 'Intern' : 'Hackathon',
                    style: TextStyle(
                      color: _ui(context).accent,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 14),
            Container(height: 0.8, color: _ui(context).divider),
            SizedBox(height: 12),

            // ── Meta row ─────────────────────────────────────────
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                _MetaChip(
                  icon: Icons.location_on_rounded,
                  label: opportunity.isRemote
                      ? 'Remote'
                      : opportunity.location,
                ),
                _MetaChip(
                  icon: Icons.access_time_rounded,
                  label: opportunity.duration,
                ),
                if (opportunity.stipend != null)
                  _MetaChip(
                    icon: Icons.currency_rupee_rounded,
                    label: opportunity.stipend!,
                  ),
                // Deadline chip — accent or error
                _MetaChip(
                  icon: Icons.schedule_rounded,
                  label: deadlineText,
                  color: isExpired
                      ? _ui(context).error
                      : isUrgent
                          ? _ui(context).error
                          : _ui(context).accent,
                ),
              ],
            ),

            SizedBox(height: 12),

            // ── Description ──────────────────────────────────────
            Text(
              opportunity.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _ui(context).textSecondary,
                fontSize: 12,
                height: 1.5,
              ),
            ),

            SizedBox(height: 12),

            // ── Skills ───────────────────────────────────────────
            SizedBox(
              height: 28,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: opportunity.skills.length,
                separatorBuilder: (_, __) => SizedBox(width: 6),
                itemBuilder: (context, i) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _ui(context).backgroundSecondary,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: _ui(context).border),
                    ),
                    child: Text(
                      opportunity.skills[i],
                      style: TextStyle(
                        color: _ui(context).textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
            ),

            SizedBox(height: 14),

            // ── CTA ──────────────────────────────────────────────
            Row(
              children: [
                Icon(Icons.bar_chart_rounded,
                    size: 12, color: _ui(context).accent),
                SizedBox(width: 4),
                Text(
                  'View Details',
                  style: TextStyle(
                    color: _ui(context).accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Spacer(),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 11, color: _ui(context).accent),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _deadlineText(DateTime date) {
    final diff = date.difference(DateTime.now()).inDays;
    if (diff < 0) return 'Expired';
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff < 7) return '$diff days left';
    return '${date.day}/${date.month}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  META CHIP
// ─────────────────────────────────────────────────────────────────────────────

class _MetaChip extends StatelessWidget {
  _MetaChip({
    required this.icon,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? _ui(context).textMuted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: chipColor),
        SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: chipColor,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

