import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:UniSync/features/admin/controllers/admin_controllers.dart';
import 'package:UniSync/features/admin/view/admin_panel_screen.dart';

/// Wraps any widget in a hidden route to the admin panel: tap it
/// [requiredTaps] times in quick succession, or long-press it.
///
/// This is discovery, not access. The gesture is available to every user
/// because hiding it in the widget tree would be meaningless — anyone can
/// decompile the app and find it. What actually protects the panel is the
/// allowlist check inside [AdminPanelScreen], the optional passcode, and the
/// Firestore rules behind both. A non-admin who finds this gesture reaches a
/// "restricted" screen and nothing else.
///
/// Deliberately silent until the last tap: counting out "3 more taps…" would
/// advertise that something is here.
class SecretAdminGesture extends ConsumerStatefulWidget {
  const SecretAdminGesture({
    super.key,
    required this.child,
    this.requiredTaps = 6,
  });

  final Widget child;
  final int requiredTaps;

  /// Taps must land within this of each other, otherwise the run resets.
  /// Long enough to be achievable, short enough that ordinary repeated
  /// taps over a session never accumulate into a trigger.
  static const _tapWindow = Duration(milliseconds: 900);

  @override
  ConsumerState<SecretAdminGesture> createState() => _SecretAdminGestureState();
}

class _SecretAdminGestureState extends ConsumerState<SecretAdminGesture> {
  int _taps = 0;
  Timer? _resetTimer;

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  void _registerTap() {
    _resetTimer?.cancel();
    _taps++;

    if (_taps >= widget.requiredTaps) {
      _taps = 0;
      _open();
      return;
    }

    _resetTimer = Timer(SecretAdminGesture._tapWindow, () => _taps = 0);
  }

  void _open() {
    // A short buzz is the only acknowledgement. Someone who triggered this
    // deliberately knows what it means; someone who did it by accident just
    // feels a tick and then sees a screen telling them it is restricted.
    HapticFeedback.mediumImpact();

    // Access may have been granted since launch, and the check is cached for
    // the session — refresh it so a freshly added admin doesn't have to
    // restart the app.
    ref.invalidate(isSuperUserProvider);
    ref.invalidate(adminAccessConfigProvider);

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _registerTap,
      onLongPress: _open,
      child: widget.child,
    );
  }
}
