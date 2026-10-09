import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:UniSync/features/admin/controllers/admin_controllers.dart';

/// Remote kill switches for whole features.
class AdminFeaturesSection extends ConsumerStatefulWidget {
  const AdminFeaturesSection({super.key});

  @override
  ConsumerState<AdminFeaturesSection> createState() =>
      _AdminFeaturesSectionState();
}

class _AdminFeaturesSectionState extends ConsumerState<AdminFeaturesSection> {
  bool _busy = false;

  Future<void> _setAds(bool enabled) async {
    setState(() => _busy = true);
    try {
      await ref.read(adminConfigRepositoryProvider).setAdsEnabled(enabled);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            enabled
                ? 'Ads are on for everyone except ad-free users'
                : 'Ads are off for everyone',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update: $error')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setAttendance(bool enabled) async {
    setState(() => _busy = true);
    try {
      await ref
          .read(adminConfigRepositoryProvider)
          .setAttendanceEnabled(enabled);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            enabled
                ? 'Attendance is now visible to users'
                : 'Attendance is now hidden from users',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update: $error')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final flags = ref.watch(featureFlagsProvider);

    return flags.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _Message('Could not read flags: $error'),
      data: (value) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _FlagTile(
            title: 'Ads',
            description:
                'Master switch for banners, native, interstitials and '
                'app-open. Users who bought ad-free never see ads either '
                'way — turning this back on does not re-enable ads for them.',
            value: value.adsEnabled,
            busy: _busy,
            onChanged: _setAds,
          ),
          const SizedBox(height: 12),
          _FlagTile(
            title: 'Attendance',
            description:
                'When off, the attendance button is removed from the nav bar '
                'and its routes refuse to open. To a user the feature simply '
                'does not exist.',
            value: value.attendanceEnabled,
            busy: _busy,
            onChanged: _setAttendance,
          ),
          const SizedBox(height: 20),
          const _Note(
            'Flags are live. Every open app picks the change up within a '
            'second — no restart, no app update.',
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _FlagTile extends StatelessWidget {
  const _FlagTile({
    required this.title,
    required this.description,
    required this.value,
    required this.busy,
    required this.onChanged,
  });

  final String title;
  final String description;
  final bool value;
  final bool busy;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _StatusChip(enabled: value),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: busy ? null : onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.enabled});
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final color = enabled ? Colors.green : Colors.redAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        enabled ? 'LIVE' : 'HIDDEN',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          color: color,
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(text, textAlign: TextAlign.center),
        ),
      );
}

class _Note extends StatelessWidget {
  const _Note(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          fontSize: 11.5,
          height: 1.45,
          color: Theme.of(context).hintColor,
        ),
      );
}
