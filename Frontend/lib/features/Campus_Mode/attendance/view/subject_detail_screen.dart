import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neopop/neopop.dart';
import 'package:unisync/constants/constant.dart';
import 'package:unisync/features/Campus_Mode/attendance/repository/live_attendance_repository2.dart';

final subjectAttendanceProvider =
    FutureProvider.family<Map<String, dynamic>?, int>((ref, subjectId) {
  return ref
      .read(LiveAttdncRepositoryProvider2)
      .fetchSubjectAttendance(subjectId: subjectId);
});

class SubjectDetailsScreen extends ConsumerWidget {
  final int subjectId;
  final String subjectName;

  const SubjectDetailsScreen({
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

    return Scaffold(
      backgroundColor: UniSyncColors.backgroundPrimary,
      body: SafeArea(
        child: Column(
          children: [
            _AppBar(subjectName: subjectName),
            Container(height: 0.8, color: UniSyncColors.divider),
            Expanded(child: _buildBody(attendanceAsync, ref)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
      AsyncValue<Map<String, dynamic>?> attendanceAsync, WidgetRef ref) {
    return attendanceAsync.when(
      loading: () => const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: UniSyncColors.accent),
        ),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: UniSyncColors.textMuted, size: 36),
            const SizedBox(height: 12),
            const Text(
              'Unable to load attendance.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: UniSyncColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            NeoPopButton(
              color: UniSyncColors.accent,
              bottomShadowColor: UniSyncColors.backgroundPrimary,
              rightShadowColor: UniSyncColors.backgroundPrimary,
              depth: 4,
              onTapUp: () => ref.invalidate(subjectAttendanceProvider(subjectId)),
              onTapDown: () {},
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Text(
                  'Retry',
                  style: TextStyle(
                    color: UniSyncColors.backgroundPrimary,
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
                  color: UniSyncColors.surfaceCard,
                  child: const Icon(Icons.warning_amber_rounded,
                      color: UniSyncColors.textMuted, size: 26),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No data available',
                  style: TextStyle(
                    color: UniSyncColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'No attendance records found for this subject',
                  style: TextStyle(
                      color: UniSyncColors.textSecondary, fontSize: 12),
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
                color: UniSyncColors.surfaceCard,
                bottomShadowColor: UniSyncColors.accent,
                rightShadowColor: UniSyncColors.accent,
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
                          const Text(
                            '#ATTENDANCE SUMMARY',
                            style: TextStyle(
                              color: UniSyncColors.accent,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.8,
                            ),
                          ),
                          const Spacer(),
                          // Safe / At-risk badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSafe
                                  ? UniSyncColors.accent.withValues(alpha: 0.12)
                                  : UniSyncColors.error.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: isSafe
                                    ? UniSyncColors.accent.withValues(alpha: 0.4)
                                    : UniSyncColors.error.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              isSafe ? 'Safe' : 'At Risk',
                              style: TextStyle(
                                color: isSafe
                                    ? UniSyncColors.accent
                                    : UniSyncColors.error,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Big percentage
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isSafe
                                ? Icons.trending_up_rounded
                                : Icons.trending_down_rounded,
                            color: isSafe
                                ? UniSyncColors.accent
                                : UniSyncColors.error,
                            size: 28,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$attendancePercentage%',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                              color: isSafe
                                  ? UniSyncColors.accent
                                  : UniSyncColors.error,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      Container(height: 0.8, color: UniSyncColors.divider),
                      const SizedBox(height: 18),

                      // Stats row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _StatChip(
                              label: 'Total',
                              value: totalClasses.toString(),
                              color: UniSyncColors.textPrimary),
                          Container(
                              width: 0.8,
                              height: 36,
                              color: UniSyncColors.divider),
                          _StatChip(
                              label: 'Present',
                              value: present.toString(),
                              color: UniSyncColors.accent),
                          Container(
                              width: 0.8,
                              height: 36,
                              color: UniSyncColors.divider),
                          _StatChip(
                              label: 'Absent',
                              value: absent.toString(),
                              color: UniSyncColors.error),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Class History header ─────────────────────────────
              if (timeline.isNotEmpty) ...[
                Row(
                  children: [
                    const Text(
                      '#CLASS HISTORY',
                      style: TextStyle(
                        color: UniSyncColors.accent,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.8,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: UniSyncColors.surfaceCard,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: UniSyncColors.border),
                      ),
                      child: Text(
                        '${timeline.length} classes',
                        style: const TextStyle(
                          color: UniSyncColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // ── Timeline list ────────────────────────────────────
              timeline.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 48),
                          Container(
                            width: 60,
                            height: 60,
                            color: UniSyncColors.surfaceCard,
                            child: const Icon(
                              Icons.calendar_today_outlined,
                              color: UniSyncColors.textMuted,
                              size: 26,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No classes found',
                            style: TextStyle(
                              color: UniSyncColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: timeline.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 10),
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
  const _AppBar({required this.subjectName});
  final String subjectName;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: UniSyncColors.backgroundSecondary,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
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
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '#SUBJECT DETAILS',
                  style: TextStyle(
                    color: UniSyncColors.accent,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subjectName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: UniSyncColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Attendance Details',
                  style: TextStyle(
                    color: UniSyncColors.textMuted,
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
  const _StatChip({
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
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: UniSyncColors.textMuted,
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
  const _ClassCard({
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
      color: UniSyncColors.surfaceCard,
      bottomShadowColor:
          isPresent ? UniSyncColors.accent : UniSyncColors.error,
      rightShadowColor:
          isPresent ? UniSyncColors.accent : UniSyncColors.error,
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
                    ? UniSyncColors.accent.withValues(alpha: 0.12)
                    : UniSyncColors.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isPresent
                      ? UniSyncColors.accent.withValues(alpha: 0.35)
                      : UniSyncColors.error.withValues(alpha: 0.35),
                ),
              ),
              child: Center(
                child: Icon(
                  isPresent
                      ? Icons.check_rounded
                      : Icons.close_rounded,
                  color:
                      isPresent ? UniSyncColors.accent : UniSyncColors.error,
                  size: 18,
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formattedDate,
                    style: const TextStyle(
                      color: UniSyncColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Period $orderNumber  ·  $fromTime – $toTime',
                    style: const TextStyle(
                      color: UniSyncColors.textSecondary,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // P / A badge
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isPresent
                    ? UniSyncColors.accent
                    : UniSyncColors.error,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  isPresent ? 'P' : 'A',
                  style: const TextStyle(
                    color: UniSyncColors.backgroundPrimary,
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