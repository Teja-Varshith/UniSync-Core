import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:UniSync/features/admin/controllers/admin_data_controllers.dart';
import 'package:UniSync/features/admin/repository/admin_notification_service.dart';

class AdminNotificationsSection extends ConsumerStatefulWidget {
  const AdminNotificationsSection({super.key});

  @override
  ConsumerState<AdminNotificationsSection> createState() =>
      _AdminNotificationsSectionState();
}

class _AdminNotificationsSectionState
    extends ConsumerState<AdminNotificationsSection> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _targetController = TextEditingController();

  AdminSendTarget _target = AdminSendTarget.all;
  bool _sending = false;
  String? _result;
  bool _resultOk = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  bool get _needsTarget => _target != AdminSendTarget.all;

  Future<void> _send() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    if (title.isEmpty || body.isEmpty) {
      setState(() {
        _resultOk = false;
        _result = 'Title and message are both required';
      });
      return;
    }
    if (_needsTarget && _targetController.text.trim().isEmpty) {
      setState(() {
        _resultOk = false;
        _result = _target == AdminSendTarget.token
            ? 'Paste a device token'
            : 'Enter a user id';
      });
      return;
    }

    // A broadcast cannot be recalled, so it gets a confirmation step that
    // single-device sends do not.
    if (_target == AdminSendTarget.all) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Send to everyone?'),
          content: Text(
            'This goes to every user with the app installed, immediately, '
            'and cannot be recalled.\n\n"$title"',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Send to all'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    setState(() {
      _sending = true;
      _result = null;
    });

    final outcome = await ref.read(adminNotificationServiceProvider).send(
          title: title,
          body: body,
          target: _target,
          token: _target == AdminSendTarget.token
              ? _targetController.text
              : null,
          uid: _target == AdminSendTarget.uid ? _targetController.text : null,
        );

    if (!mounted) return;
    setState(() {
      _sending = false;
      _resultOk = outcome.ok;
      _result = outcome.message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Title',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _bodyController,
          minLines: 3,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Message',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'SEND TO',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: theme.hintColor,
          ),
        ),
        const SizedBox(height: 8),
        SegmentedButton<AdminSendTarget>(
          segments: const [
            ButtonSegment(value: AdminSendTarget.all, label: Text('Everyone')),
            ButtonSegment(value: AdminSendTarget.uid, label: Text('User id')),
            ButtonSegment(value: AdminSendTarget.token, label: Text('Token')),
          ],
          selected: {_target},
          onSelectionChanged: (values) => setState(() {
            _target = values.first;
            _result = null;
          }),
        ),
        if (_needsTarget) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _targetController,
            decoration: InputDecoration(
              labelText: _target == AdminSendTarget.token
                  ? 'Device FCM token'
                  : 'User id (uid)',
              helperText: _target == AdminSendTarget.uid
                  // Tokens rotate; a uid always resolves to the current one.
                  ? 'Looks the token up server-side, so it is never stale'
                  : 'Copy from the Users tab',
              helperMaxLines: 2,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ],
        const SizedBox(height: 20),
        SizedBox(
          height: 46,
          child: FilledButton.icon(
            onPressed: _sending ? null : _send,
            icon: _sending
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send_rounded, size: 18),
            label: Text(_sending ? 'Sending…' : 'Send notification'),
          ),
        ),
        if (_result != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (_resultOk ? Colors.green : Colors.redAccent)
                  .withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: (_resultOk ? Colors.green : Colors.redAccent)
                    .withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _resultOk ? Icons.check_circle_outline : Icons.error_outline,
                  size: 17,
                  color: _resultOk ? Colors.green : Colors.redAccent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _result!,
                    style: const TextStyle(fontSize: 12, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        Text(
          'Sends go through the backend, which verifies your Firebase ID '
          'token against the super-user list before calling FCM. The app '
          'holds no server key, so a decompiled APK cannot be used to push '
          'to your users.\n\n'
          'Broadcasts use the "all_users" topic, which every device '
          'subscribes to on launch. A user who has not opened the app since '
          'this build shipped will not receive broadcasts until they do.',
          style: TextStyle(
            fontSize: 11,
            height: 1.5,
            color: theme.hintColor,
          ),
        ),
      ],
    );
  }
}
