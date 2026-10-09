import 'package:flutter/material.dart';
import 'package:UniSync/features/examsync/theme/es_theme.dart';

enum EsToastType { success, warning, error }

/// Non-blocking toast in the NeoPOP style. Auto-dismisses after 3–5s.
void showEsToast(
  BuildContext context,
  String message, {
  EsToastType type = EsToastType.success,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  final (color, icon, seconds) = switch (type) {
    EsToastType.success => (EsColors.success, Icons.check_circle_rounded, 3),
    EsToastType.warning => (EsColors.warning, Icons.info_rounded, 4),
    EsToastType.error => (EsColors.error, Icons.error_rounded, 5),
  };
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        padding: EdgeInsets.zero,
        duration: Duration(seconds: seconds),
        content: Semantics(
          liveRegion: true,
          child: Container(
            decoration: BoxDecoration(
              color: EsColors.surfaceElevated,
              border: Border(left: BorderSide(color: color, width: 4)),
              boxShadow: const [
                BoxShadow(color: Colors.black, offset: Offset(3, 3)),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: EsText.body(size: 13.5, weight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
}
