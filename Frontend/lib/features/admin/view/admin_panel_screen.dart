import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:UniSync/features/admin/controllers/admin_controllers.dart';
import 'package:UniSync/features/admin/repository/admin_config_repository.dart';
import 'package:UniSync/features/admin/view/sections/admin_features_section.dart';
import 'package:UniSync/features/admin/view/sections/admin_notifications_section.dart';
import 'package:UniSync/features/admin/view/sections/admin_opportunities_section.dart';
import 'package:UniSync/features/admin/view/sections/admin_users_section.dart';

/// Super-user only control panel.
///
/// Two gates before anything renders: the signed-in account must be on the
/// `app_config/access` allowlist, and — if one is configured — a passcode
/// must be entered. Neither is a security boundary on its own; both only
/// control what this UI shows. The actual protection is Firestore security
/// rules on the documents this panel writes, and the ID-token check on the
/// notification endpoint.
class AdminPanelScreen extends ConsumerStatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  ConsumerState<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends ConsumerState<AdminPanelScreen> {
  bool _unlocked = false;

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(isSuperUserProvider);

    return access.when(
      loading: () => const _AdminScaffold(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const _AdminScaffold(child: _Denied()),
      data: (isSuperUser) {
        if (!isSuperUser) return const _AdminScaffold(child: _Denied());

        final config = ref.watch(adminAccessConfigProvider).valueOrNull;
        final needsPasscode = (config?.requiresPasscode ?? false) && !_unlocked;

        if (needsPasscode) {
          return _AdminScaffold(
            child: _PasscodeGate(
              onSubmit: (value) {
                if (config!.matchesPasscode(value)) {
                  setState(() => _unlocked = true);
                  return null;
                }
                return 'Incorrect passcode';
              },
            ),
          );
        }

        return const _AdminTabs();
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _AdminScaffold extends StatelessWidget {
  const _AdminScaffold({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin')),
      body: child,
    );
  }
}

class _Denied extends ConsumerWidget {
  const _Denied();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline_rounded,
                size: 40, color: Theme.of(context).disabledColor),
            const SizedBox(height: 14),
            const Text(
              'This area is restricted.',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 6),
            Text(
              'Your account is not on the super-user list.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).hintColor),
            ),
            const SizedBox(height: 24),
            _AccessDiagnostic(
              config: ref.watch(adminAccessConfigProvider),
              raw: ref.watch(adminAccessRawProvider).valueOrNull,
            ),
          ],
        ),
      ),
    );
  }
}

/// Explains *why* access was refused, so a misconfigured allowlist can be
/// told apart from a working one without a console trip.
///
/// Shown in release builds too, because the allowlist lives in Firestore and
/// diagnosing it from a shipped build is the whole point. It reports the
/// *size* of each list rather than its contents: the counts are enough to
/// tell "document missing or unreadable" from "document fine, your account
/// is not in it", while printing the actual admin emails would hand a list
/// of targets to anyone who stumbles onto this screen.
class _AccessDiagnostic extends StatelessWidget {
  const _AccessDiagnostic({required this.config, this.raw});

  final AsyncValue<AdminAccessConfig> config;

  /// What the document looked like on arrival, before parsing.
  final String? raw;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);

    final lines = <String>[
      'signed in : ${user?.email ?? '(no email)'}',
      'uid       : ${user?.uid ?? '(none)'}',
      ...config.when(
        loading: () => const ['config    : reading…'],
        // The failure text matters more than anything else here: a
        // permission-denied read and an empty document look identical
        // from the outside, and need opposite fixes.
        error: (error, _) => [
          'config    : READ FAILED',
          '$error',
        ],
        data: (value) => [
          'emails[]  : ${value.emails.length} entr'
              '${value.emails.length == 1 ? 'y' : 'ies'}',
          'uids[]    : ${value.uids.length} entr'
              '${value.uids.length == 1 ? 'y' : 'ies'}',
          'matched   : ${value.allows(uid: user?.uid, email: user?.email)}',
        ],
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WHAT THE APP READ',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
              color: theme.hintColor,
            ),
          ),
          const SizedBox(height: 8),
          ...lines.map(
            (line) => Text(
              line,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 10.5,
                height: 1.6,
              ),
            ),
          ),
          if (raw != null) ...[
            const SizedBox(height: 10),
            Divider(height: 1, color: theme.dividerColor),
            const SizedBox(height: 10),
            Text(
              raw!,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'If "project" is not the Firebase project you edited, the app is '
            'pointed at a different one. If "exists" is false the document '
            'is at another path. If emails is not List, it was saved as the '
            'wrong type.',
            style: TextStyle(
              fontSize: 10,
              height: 1.4,
              color: theme.hintColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _PasscodeGate extends StatefulWidget {
  const _PasscodeGate({required this.onSubmit});

  /// Returns an error message, or null when the passcode is accepted.
  final String? Function(String value) onSubmit;

  @override
  State<_PasscodeGate> createState() => _PasscodeGateState();
}

class _PasscodeGateState extends State<_PasscodeGate> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _error = widget.onSubmit(_controller.text));
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shield_outlined, size: 36),
            const SizedBox(height: 16),
            const Text(
              'Enter admin passcode',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              obscureText: true,
              autofocus: true,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                errorText: _error,
                isDense: true,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                child: const Text('Unlock'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _AdminTabs extends StatelessWidget {
  const _AdminTabs();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin'),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Features'),
              Tab(text: 'Opportunities'),
              Tab(text: 'Users & Payments'),
              Tab(text: 'Notifications'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            AdminFeaturesSection(),
            AdminOpportunitiesSection(),
            AdminUsersSection(),
            AdminNotificationsSection(),
          ],
        ),
      ),
    );
  }
}
