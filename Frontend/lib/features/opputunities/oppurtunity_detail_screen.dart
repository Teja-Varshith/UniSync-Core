import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neopop/neopop.dart';
import 'package:routemaster/routemaster.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:unisync/constants/constant.dart';
import 'package:unisync/features/opputunities/oppurtunities_controller.dart';
import 'package:unisync/features/opputunities/oppurtunity_model.dart';

class OpportunityDetailsScreen extends ConsumerWidget {
  final String opportunityId;

  const OpportunityDetailsScreen({
    super.key,
    required this.opportunityId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: UniSyncColors.backgroundPrimary,
      body: FutureBuilder<OpportunityModel?>(
        future: ref
            .read(opportunityControllerProvider.notifier)
            .getOpportunityById(opportunityId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: UniSyncColors.accent),
              ),
            );
          }

          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data == null) {
            return SafeArea(
              child: Column(
                children: [
                  // Header
                  Container(
                    color: UniSyncColors.backgroundSecondary,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    child: Row(
                      children: [
                        _BackButton(onTap: () => Routemaster.of(context).pop()),
                        const SizedBox(width: 14),
                        const Text(
                          'Details',
                          style: TextStyle(
                            color: UniSyncColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(height: 0.8, color: UniSyncColors.divider),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              color: UniSyncColors.textMuted, size: 36),
                          const SizedBox(height: 12),
                          const Text(
                            'Opportunity not found',
                            style: TextStyle(
                              color: UniSyncColors.textSecondary,
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

class OpportunityDetailsView extends StatelessWidget {
  final OpportunityModel opportunity;

  const OpportunityDetailsView({super.key, required this.opportunity});

  bool get _isExpired => opportunity.deadline.isBefore(DateTime.now());
  bool get _isInternship => opportunity.type == OpportunityType.internship;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UniSyncColors.backgroundPrimary,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────
            _buildHeader(context),
            Container(height: 0.8, color: UniSyncColors.divider),

            // ── Scrollable body ──────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [

                    // ── Hero card ──────────────────────────────
                    _HeroCard(opportunity: opportunity),

                    const SizedBox(height: 20),

                    // ── Quick info card ────────────────────────
                    _buildSectionLabel('#QUICK INFO'),
                    const SizedBox(height: 10),
                    _QuickInfoCard(opportunity: opportunity),

                    const SizedBox(height: 24),

                    // ── Description ────────────────────────────
                    _buildSectionLabel('#DETAILS'),
                    const SizedBox(height: 10),
                    _ContentCard(
                      child: Text(
                        opportunity.description,
                        style: const TextStyle(
                          color: UniSyncColors.textSecondary,
                          fontSize: 13,
                          height: 1.7,
                        ),
                      ),
                    ),

                    // ── Requirements ───────────────────────────
                    if (opportunity.requirements.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _buildSectionLabel('#REQUIREMENTS'),
                      const SizedBox(height: 10),
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
                      const SizedBox(height: 24),
                      _buildSectionLabel('#SKILLS'),
                      const SizedBox(height: 10),
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
                    const SizedBox(height: 24),
                    _buildSectionLabel('#MORE INFO'),
                    const SizedBox(height: 10),
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
        onTap: () => _launchApplicationUrl(context),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: UniSyncColors.backgroundSecondary,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Row(
        children: [
          _BackButton(onTap: () => Routemaster.of(context).pop()),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '#OPPORTUNITY',
                  style: TextStyle(
                    color: UniSyncColors.accent,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.8,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  opportunity.company,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: UniSyncColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
          ),
          // Expired / Active badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _isExpired
                  ? UniSyncColors.error.withValues(alpha: 0.12)
                  : UniSyncColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: _isExpired
                    ? UniSyncColors.error.withValues(alpha: 0.4)
                    : UniSyncColors.accent.withValues(alpha: 0.4),
              ),
            ),
            child: Text(
              _isExpired ? 'Closed' : 'Active',
              style: TextStyle(
                color: _isExpired ? UniSyncColors.error : UniSyncColors.accent,
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
      style: const TextStyle(
        color: UniSyncColors.accent,
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
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $uri');
    }
  }

  void _shareOpportunity(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Working on it — share coming soon!'),
        backgroundColor: UniSyncColors.accent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  HERO CARD — logo + title + badges
// ─────────────────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.opportunity});
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
        ? UniSyncColors.error
        : UniSyncColors.accent;

    return NeoPopButton(
      color: UniSyncColors.surfaceCard,
      bottomShadowColor: UniSyncColors.accent,
      rightShadowColor: UniSyncColors.accent,
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
                // Logo
                Container(
                  width: 56,
                  height: 56,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: UniSyncColors.backgroundSecondary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: UniSyncColors.border),
                  ),
                  child: opportunity.logoUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            opportunity.logoUrl!,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.business_rounded,
                              color: UniSyncColors.textMuted,
                              size: 22,
                            ),
                          ),
                        )
                      : const Icon(Icons.business_rounded,
                          color: UniSyncColors.textMuted, size: 22),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        opportunity.title,
                        style: const TextStyle(
                          color: UniSyncColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        opportunity.company,
                        style: const TextStyle(
                          color: UniSyncColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            Container(height: 0.8, color: UniSyncColors.divider),
            const SizedBox(height: 12),

            // Badges
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Badge(
                  label: _isInternship ? 'Internship' : 'Hackathon',
                  icon: Icons.work_outline_rounded,
                  color: UniSyncColors.accent,
                ),
                _Badge(
                  label: deadlineLabel,
                  icon: Icons.schedule_rounded,
                  color: deadlineColor,
                ),
                if (opportunity.isRemote)
                  const _Badge(
                    label: 'Remote',
                    icon: Icons.home_outlined,
                    color: UniSyncColors.accent,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  QUICK INFO CARD
// ─────────────────────────────────────────────────────────────────────────────

class _QuickInfoCard extends StatelessWidget {
  const _QuickInfoCard({required this.opportunity});
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
          Container(height: 0.8, color: UniSyncColors.divider,
              margin: const EdgeInsets.symmetric(vertical: 12)),
          _InfoRow(
            icon: Icons.access_time_rounded,
            label: 'Duration',
            value: opportunity.duration,
          ),
          if (opportunity.stipend != null) ...[
            Container(height: 0.8, color: UniSyncColors.divider,
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

// ─────────────────────────────────────────────────────────────────────────────
//  ADDITIONAL DETAILS CARD
// ─────────────────────────────────────────────────────────────────────────────

class _AdditionalDetailsCard extends StatelessWidget {
  const _AdditionalDetailsCard({required this.opportunity});
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
          Container(height: 0.8, color: UniSyncColors.divider,
              margin: const EdgeInsets.symmetric(vertical: 12)),
          _InfoRow(
            icon: Icons.event_rounded,
            label: 'Deadline',
            value: _fmt(opportunity.deadline),
          ),
          if (opportunity.type == OpportunityType.internship) ...[
            Container(height: 0.8, color: UniSyncColors.divider,
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

// ─────────────────────────────────────────────────────────────────────────────
//  APPLY BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class _ApplyButton extends StatelessWidget {
  const _ApplyButton({required this.isExpired, required this.onTap});
  final bool isExpired;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: NeoPopButton(
        color: isExpired ? UniSyncColors.surfaceCard : UniSyncColors.accent,
        bottomShadowColor: UniSyncColors.backgroundPrimary,
        rightShadowColor: UniSyncColors.backgroundPrimary,
        depth: isExpired ? 2 : 5,
        onTapUp: isExpired ? () {} : onTap,
        onTapDown: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!isExpired)
                const Icon(Icons.rocket_launch_rounded,
                    color: UniSyncColors.backgroundPrimary, size: 18),
              if (!isExpired) const SizedBox(width: 10),
              Text(
                isExpired ? 'Application Closed' : 'Apply Now',
                style: TextStyle(
                  color: isExpired
                      ? UniSyncColors.textMuted
                      : UniSyncColors.backgroundPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SHARED SMALL WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _ContentCard extends StatelessWidget {
  const _ContentCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: UniSyncColors.surfaceCard,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: UniSyncColors.border),
      ),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
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
        Icon(icon, size: 15, color: UniSyncColors.textMuted),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: UniSyncColors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: UniSyncColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
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
          const SizedBox(width: 5),
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
  const _SkillChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: UniSyncColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: UniSyncColors.border),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: UniSyncColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _RequirementRow extends StatelessWidget {
  const _RequirementRow({required this.text});
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
            decoration: const BoxDecoration(
              color: UniSyncColors.accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: UniSyncColors.textSecondary,
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
  const _BackButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: UniSyncColors.surfaceCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: UniSyncColors.border),
        ),
        child: const Center(
          child: Icon(Icons.arrow_back_ios_new_rounded,
              size: 15, color: UniSyncColors.textMuted),
        ),
      ),
    );
  }
}