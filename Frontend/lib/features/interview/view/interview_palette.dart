import 'package:flutter/material.dart';
import 'package:UniSync/app/theme/app_colors.dart';

class InterviewPalette {
  InterviewPalette({
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
    required this.accentHover,
    required this.accentPressed,
    required this.buttonPrimaryBg,
    required this.buttonPrimaryFg,
    required this.buttonPrimaryStroke,
    required this.buttonPrimaryHover,
    required this.buttonPrimaryPressed,
    required this.buttonSecondaryBg,
    required this.buttonSecondaryFg,
    required this.buttonSecondaryBorder,
    required this.buttonSecondaryHover,
    required this.buttonSecondaryPressed,
    required this.buttonGhostFg,
    required this.buttonGhostHover,
    required this.buttonGhostPressed,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.onSuccess,
    required this.onWarning,
    required this.onError,
    required this.onInfo,
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
  final Color accentHover;
  final Color accentPressed;

  final Color buttonPrimaryBg;
  final Color buttonPrimaryFg;
  final Color buttonPrimaryStroke;
  final Color buttonPrimaryHover;
  final Color buttonPrimaryPressed;

  final Color buttonSecondaryBg;
  final Color buttonSecondaryFg;
  final Color buttonSecondaryBorder;
  final Color buttonSecondaryHover;
  final Color buttonSecondaryPressed;

  final Color buttonGhostFg;
  final Color buttonGhostHover;
  final Color buttonGhostPressed;

  final Color success;
  final Color warning;
  final Color error;
  final Color info;

  final Color onSuccess;
  final Color onWarning;
  final Color onError;
  final Color onInfo;

  factory InterviewPalette.of(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = AppColors.primary;
    return InterviewPalette(
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
      accent: accent,
      accentSoft: accent.withValues(alpha: 0.14),
      accentHover: accent.withValues(alpha: 0.9),
      accentPressed: accent.withValues(alpha: 0.75),
      buttonPrimaryBg: accent,
      buttonPrimaryFg: theme.colorScheme.onPrimary,
      buttonPrimaryStroke: accent.withValues(alpha: 0.8),
      buttonPrimaryHover: accent.withValues(alpha: 0.9),
      buttonPrimaryPressed: accent.withValues(alpha: 0.75),
      buttonSecondaryBg: isDark ? AppColors.darkCard : AppColors.lightCard,
      buttonSecondaryFg: theme.colorScheme.onSurface,
      buttonSecondaryBorder: isDark ? AppColors.darkBorder : AppColors.lightBorder,
      buttonSecondaryHover: isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt,
      buttonSecondaryPressed: isDark
          ? AppColors.darkCard.withValues(alpha: 0.92)
          : AppColors.lightCardAlt.withValues(alpha: 0.92),
      buttonGhostFg: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
      buttonGhostHover: accent.withValues(alpha: 0.12),
      buttonGhostPressed: accent.withValues(alpha: 0.18),
      success: AppColors.success,
      warning: AppColors.warning,
      error: theme.colorScheme.error,
      info: AppColors.info,
      onSuccess: isDark ? AppColors.darkBg : AppColors.lightBg,
      onWarning: isDark ? AppColors.darkBg : AppColors.lightBg,
      onError: theme.colorScheme.onError,
      onInfo: isDark ? AppColors.darkBg : AppColors.lightBg,
    );
  }
}
