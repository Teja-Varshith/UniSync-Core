import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neopop/neopop.dart';
import 'package:UniSync/ads%20Manager/add_manager.dart';
import 'package:UniSync/app/providers.dart';
import 'package:UniSync/app/theme/app_colors.dart';
import 'package:UniSync/constants/constant.dart';
import 'package:UniSync/features/attendance/repository/live_attendance_repository2.dart';

final subjectAttendanceProvider =
    FutureProvider.family<Map<String, dynamic>?, int>((ref, subjectId) {
  return ref
      .read(LiveAttdncRepositoryProvider2)
      .fetchSubjectAttendance(subjectId: subjectId);
});

_AttendancePalette _ui(BuildContext context) => _AttendancePalette.of(context);

class _AttendancePalette {
  const _AttendancePalette({
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

  factory _AttendancePalette.of(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return _AttendancePalette(
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

class SubjectDetailsScreen extends ConsumerWidget {
  final int subjectId;
  final String subjectName;

  SubjectDetailsScreen({
    super.key,
    required this.subjectId,
    required this.subjectName,
  });

  double _floorToDecimals(double value, int decimals) {
    final factor = math.pow(10, decimals).toDouble();
    return (value * factor).floorToDouble() / factor;
  }

  String _formatPctFloor(double value, {int decimals = 2}) {
    return _floorToDecimals(value, decimals).toStringAsFixed(decimals);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendanceAsync = ref.watch(subjectAttendanceProvider(subjectId));
    final hasAdFreeAccess =
        ref.watch(userProvider)?.hasAdFreeAccess ?? AdManager.instance.isAdFree;

    return Scaffold(
      backgroundColor: _ui(context).backgroundPrimary,
      body: SafeArea(
        child: Column(
          children: [
            _AppBar(subjectName: subjectName),
            Container(height: 0.8, color: _ui(context).divider),
            Expanded(child: _buildBody(context, attendanceAsync, ref)),
            if (!hasAdFreeAccess) ...[
              Container(height: 0.8, color: _ui(context).divider),
              SizedBox(height: 8),
              Center(child: AdManager.instance.buildBannerAd()),
              SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AsyncValue<Map<String, dynamic>?> attendanceAsync, WidgetRef ref) {
    return attendanceAsync.when(
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
              'Unable to load attendance.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: _ui(context).textSecondary, fontSize: 13),
            ),
            SizedBox(height: 16),
            NeoPopButton(
              color: _ui(context).accent,
              bottomShadowColor: _ui(context).backgroundPrimary,
              rightShadowColor: _ui(context).backgroundPrimary,
              depth: 4,
              onTapUp: () => ref.invalidate(subjectAttendanceProvider(subjectId)),
              onTapDown: () {},
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
      data: (attendanceData) {
        if (attendanceData == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  color: _ui(context).surfaceCard,
                  child: Icon(Icons.warning_amber_rounded,
                      color: _ui(context).textMuted, size: 26),
                ),
                SizedBox(height: 16),
                Text(
                  'No data available',
                  style: TextStyle(
                    color: _ui(context).textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'No attendance records found for this subject',
                  style: TextStyle(
                      color: _ui(context).textSecondary, fontSize: 12),
                ),
              ],
            ),
          );
        }

        final totalClasses = attendanceData['totalClasses'] ?? 0;
        final present = attendanceData['present'] ?? 0;
        final timeline = attendanceData['timeline'] as List<dynamic>? ?? [];
        final absent = totalClasses - present;
        final attendancePercentage = totalClasses > 0
            ? _formatPctFloor((present / totalClasses) * 100)
            : '0.00';
        final pct = double.parse(attendancePercentage);
        final isSafe = pct >= 75;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              // ── Summary card ────────────────────────────────────
              NeoPopButton(
                color: _ui(context).surfaceCard,
                bottomShadowColor: _ui(context).accent,
                rightShadowColor: _ui(context).accent,
                depth: 4,
                onTapUp: () {},
                onTapDown: () {},
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [

                      // Eyebrow
                      Row(
                        children: [
                          Text(
                            '#ATTENDANCE SUMMARY',
                            style: TextStyle(
                              color: _ui(context).accent,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.8,
                            ),
                          ),
                          Spacer(),
                          // Safe / At-risk badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSafe
                                  ? _ui(context).accent.withValues(alpha: 0.12)
                                  : _ui(context).error.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: isSafe
                                    ? _ui(context).accent.withValues(alpha: 0.4)
                                    : _ui(context).error.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              isSafe ? 'Safe' : 'At Risk',
                              style: TextStyle(
                                color: isSafe
                                    ? _ui(context).accent
                                    : _ui(context).error,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 18),

                      // Big percentage
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isSafe
                                ? Icons.trending_up_rounded
                                : Icons.trending_down_rounded,
                            color: isSafe
                                ? _ui(context).accent
                                : _ui(context).error,
                            size: 28,
                          ),
                          SizedBox(width: 8),
                          Text(
                            '$attendancePercentage%',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                              color: isSafe
                                  ? _ui(context).accent
                                  : _ui(context).error,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 18),

                      Container(height: 0.8, color: _ui(context).divider),
                      SizedBox(height: 18),

                      // Stats row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _StatChip(
                              label: 'Total',
                              value: totalClasses.toString(),
                              color: _ui(context).textPrimary),
                          Container(
                              width: 0.8,
                              height: 36,
                              color: _ui(context).divider),
                          _StatChip(
                              label: 'Present',
                              value: present.toString(),
                              color: _ui(context).accent),
                          Container(
                              width: 0.8,
                              height: 36,
                              color: _ui(context).divider),
                          _StatChip(
                              label: 'Absent',
                              value: absent.toString(),
                              color: _ui(context).error),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 24),

              // ── Class History header ─────────────────────────────
              if (timeline.isNotEmpty) ...[
                Row(
                  children: [
                    Text(
                      '#CLASS HISTORY',
                      style: TextStyle(
                        color: _ui(context).accent,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.8,
                      ),
                    ),
                    Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _ui(context).surfaceCard,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: _ui(context).border),
                      ),
                      child: Text(
                        '${timeline.length} classes',
                        style: TextStyle(
                          color: _ui(context).textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
              ],

              // ── Timeline list ────────────────────────────────────
              timeline.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: 48),
                          Container(
                            width: 60,
                            height: 60,
                            color: _ui(context).surfaceCard,
                            child: Icon(
                              Icons.calendar_today_outlined,
                              color: _ui(context).textMuted,
                              size: 26,
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No classes found',
                            style: TextStyle(
                              color: _ui(context).textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: timeline.length,
                      separatorBuilder: (_, __) =>
                          SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final classData = timeline[index];
                        final isPresent = classData['status'] == false;
                        final date = classData['date'] ?? '';
                        final fromTime = classData['fromTime'] ?? '';
                        final toTime = classData['toTime'] ?? '';
                        final orderNumber = classData['orderNumber'] ?? 0;

                        DateTime? parsedDate;
                        try {
                          parsedDate = DateTime.parse(date);
                        } catch (_) {}

                        final formattedDate = parsedDate != null
                            ? '$date (${_getWeekday(parsedDate.weekday)})'
                            : date;

                        return _ClassCard(
                          isPresent: isPresent,
                          formattedDate: formattedDate,
                          orderNumber: orderNumber,
                          fromTime: fromTime,
                          toTime: toTime,
                        );
                      },
                    ),
            ],
          ),
        );
      },
    );
  }

  String _getWeekday(int weekday) {
    const weekdays = [
      'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
    ];
    return weekdays[weekday - 1];
  }

  String _getMonth(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  APP BAR
// ─────────────────────────────────────────────────────────────────────────────

class _AppBar extends StatelessWidget {
  _AppBar({required this.subjectName});
  final String subjectName;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _ui(context).backgroundSecondary,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Back button
          NeoPopButton(
            color: _ui(context).surfaceCard,
            bottomShadowColor: _ui(context).border,
            rightShadowColor: _ui(context).border,
            depth: 3,
            onTapUp: () => Navigator.of(context).pop(),
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
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#SUBJECT DETAILS',
                  style: TextStyle(
                    color: _ui(context).accent,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.8,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  subjectName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _ui(context).textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Attendance Details',
                  style: TextStyle(
                    color: _ui(context).textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  STAT CHIP
// ─────────────────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: _ui(context).textMuted,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  CLASS CARD
// ─────────────────────────────────────────────────────────────────────────────

class _ClassCard extends StatelessWidget {
  _ClassCard({
    required this.isPresent,
    required this.formattedDate,
    required this.orderNumber,
    required this.fromTime,
    required this.toTime,
  });

  final bool isPresent;
  final String formattedDate;
  final dynamic orderNumber;
  final String fromTime;
  final String toTime;

  @override
  Widget build(BuildContext context) {
    return NeoPopButton(
      color: _ui(context).surfaceCard,
      bottomShadowColor:
          isPresent ? _ui(context).accent : _ui(context).error,
      rightShadowColor:
          isPresent ? _ui(context).accent : _ui(context).error,
      depth: 3,
      onTapUp: () {},
      onTapDown: () {},
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          children: [
            // Status icon block
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isPresent
                    ? _ui(context).accent.withValues(alpha: 0.12)
                    : _ui(context).error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isPresent
                      ? _ui(context).accent.withValues(alpha: 0.35)
                      : _ui(context).error.withValues(alpha: 0.35),
                ),
              ),
              child: Center(
                child: Icon(
                  isPresent
                      ? Icons.check_rounded
                      : Icons.close_rounded,
                  color:
                      isPresent ? _ui(context).accent : _ui(context).error,
                  size: 18,
                ),
              ),
            ),

            SizedBox(width: 12),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formattedDate,
                    style: TextStyle(
                      color: _ui(context).textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Period $orderNumber  ·  $fromTime – $toTime',
                    style: TextStyle(
                      color: _ui(context).textSecondary,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(width: 8),

            // P / A badge
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isPresent
                    ? _ui(context).accent
                    : _ui(context).error,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  isPresent ? 'P' : 'A',
                  style: TextStyle(
                    color: _ui(context).backgroundPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
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

