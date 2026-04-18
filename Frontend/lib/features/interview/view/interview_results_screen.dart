import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:UniSync/features/interview/controllers/reports_controller.dart';
import 'package:UniSync/features/interview/view/interview_palette.dart';
import 'package:UniSync/models/interview_report_model.dart';

InterviewPalette _ui(BuildContext context) => InterviewPalette.of(context);

class InterviewResultsScreen extends ConsumerStatefulWidget {
  const InterviewResultsScreen({super.key});

  @override
  ConsumerState<InterviewResultsScreen> createState() =>
      _InterviewResultsScreenState();
}

class _InterviewResultsScreenState
    extends ConsumerState<InterviewResultsScreen> {
  @override
  Widget build(BuildContext context) {
    final rprts = ref.watch(ReportsControllerProvider);

    return Scaffold(
      backgroundColor: _ui(context).backgroundPrimary,
      body: SafeArea(
        child: Column(children: [

          // ── App bar ────────────────────────────────────────────
          Container(
            color: _ui(context).backgroundSecondary,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(children: [
              // NeoPopButton(
              //   color: _ui(context).surfaceCard,
              //   bottomShadowColor: _ui(context).border,
              //   rightShadowColor: _ui(context).border,
              //   depth: 3,
              //   onTapUp: () => Routemaster.of(context)
              //       .replace('/startInterviewScreen'),
              //   onTapDown: () {},
              //   child: const SizedBox(
              //     width: 40, height: 40,
              //     child: Center(
              //       child: Icon(Icons.arrow_back_ios_new_rounded,
              //           size: 16, color: _ui(context).textPrimary),
              //     ),
              //   ),
              // ),
              // const SizedBox(width: 14),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('#PERFORMANCE', style: TextStyle(
                  color: _ui(context).accent, fontSize: 9,
                  fontWeight: FontWeight.w700, letterSpacing: 1.8,
                )),
                const SizedBox(height: 2),
                RichText(text: TextSpan(children: [
                  TextSpan(text: 'Interview ',
                      style: TextStyle(
                        color: _ui(context).textPrimary, fontSize: 18,
                        fontWeight: FontWeight.w800, letterSpacing: -0.4,
                      )),
                  TextSpan(text: 'reports',
                      style: TextStyle(
                        color: _ui(context).accent, fontSize: 18,
                        fontWeight: FontWeight.w800, letterSpacing: -0.4,
                      )),
                ])),
              ]),
            ]),
          ),

          Container(height: 0.8, color: _ui(context).divider),

          // ── Content ────────────────────────────────────────────
          Expanded(
            child: rprts.when(
              loading: () => Center(
                child: SizedBox(width: 24, height: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: _ui(context).accent)),
              ),
              error: (error, _) => Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.error_outline_rounded,
                      color: _ui(context).textMuted, size: 36),
                  const SizedBox(height: 12),
                  Text(
                    'Could not fetch interview reports.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: _ui(context).textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () {
                      ref.read(ReportsControllerProvider.notifier).refresh();
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Refresh'),
                    style: TextButton.styleFrom(
                      foregroundColor: _ui(context).accent,
                    ),
                  ),
                ]),
              ),
              data: (data) {
                if (data.isEmpty) {
                  return Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                      Container(
                        width: 60, height: 60,
                        color: _ui(context).surfaceCard,
                        child: Icon(Icons.description_outlined,
                            color: _ui(context).textMuted, size: 26),
                      ),
                      const SizedBox(height: 16),
                      Text('No reports yet',
                          style: TextStyle(
                            color: _ui(context).textPrimary, fontSize: 15,
                            fontWeight: FontWeight.w700,
                          )),
                      const SizedBox(height: 6),
                      Text('Complete an interview to see your report',
                          style: TextStyle(
                            color: _ui(context).textSecondary, fontSize: 12,
                          )),
                    ]),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
                  itemCount: data.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => ReportCard(
                    session:       data[index],
                    sessionNumber: data.length - index,
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  REPORT CARD
// ─────────────────────────────────────────────────────────────────────────────
class ReportCard extends StatefulWidget {
  const ReportCard({
    super.key,
    required this.session,
    required this.sessionNumber,
  });

  final InterviewSession session;
  final int sessionNumber;

  @override
  State<ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends State<ReportCard> {
  bool _expanded = false;

  // ── unchanged logic helpers ──────────────────────────────────────────────
  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('MMM dd, yyyy').format(date.toLocal());
  }

  String _formatTime(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('hh:mm a').format(date.toLocal());
  }

  Color _getStatusColorWithContext(BuildContext context) {
    switch (widget.session.status.toLowerCase()) {
      case 'completed':   return const Color(0xFF3ECF8E);
      case 'in_progress': return const Color(0xFF4A90E2);
      case 'failed':      return const Color(0xFFE05252);
      default:            return _ui(context).textMuted;
    }
  }

  Color _getScoreColor(int score) {
    if (score >= 70) return const Color(0xFF3ECF8E);
    if (score >= 50) return const Color(0xFFE8A838);
    return const Color(0xFFE05252);
  }
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final report       = widget.session.finalReport;
    final statusColor  = _getStatusColorWithContext(context);
    final scoreColor   = report != null
        ? _getScoreColor(report.overallScore ?? 0) : null;

    return Container(
      decoration: BoxDecoration(
        color: _ui(context).surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _ui(context).borderSubtle),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [

        // ── Colour accent top stripe ───────────────────────────
        Container(height: 2, color: statusColor),

        // ── Header row (always visible) ────────────────────────
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Row(children: [
                  // Session number
                  Text('Session #${widget.sessionNumber}',
                      style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800,
                        color: _ui(context).textPrimary, letterSpacing: -0.2,
                      )),
                  const Spacer(),
                  // Expand chevron
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.keyboard_arrow_down_rounded,
                        size: 20, color: _ui(context).textMuted),
                  ),
                ]),

                const SizedBox(height: 10),

                // Date + time
                Row(children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 12, color: _ui(context).textMuted),
                  const SizedBox(width: 5),
                  Text(_formatDate(widget.session.startedAt),
                      style: TextStyle(
                        fontSize: 12, color: _ui(context).textMuted,
                      )),
                  const SizedBox(width: 14),
                  Icon(Icons.access_time_rounded,
                      size: 12, color: _ui(context).textMuted),
                  const SizedBox(width: 5),
                  Text(_formatTime(widget.session.startedAt),
                      style: TextStyle(
                        fontSize: 12, color: _ui(context).textMuted,
                      )),
                ]),

                const SizedBox(height: 10),

                // Status + score pills
                Row(children: [
                  _Pill(
                    label: widget.session.status.toUpperCase(),
                    color: statusColor,
                  ),
                  if (report != null) ...[
                    const SizedBox(width: 8),
                    _Pill(
                      label: 'Score ${report.overallScore ?? 0}/100',
                      color: scoreColor!,
                    ),
                  ],
                ]),
              ],
            ),
          ),
        ),

        // ── Expanded detail ────────────────────────────────────
        if (_expanded && report != null)
          Container(
            decoration: BoxDecoration(
              border: Border(
                  top: BorderSide(color: _ui(context).divider)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                _DetailSection(title: 'Summary', content: report.summary),

                if (report.skillBreakdown != null) ...[
                  const SizedBox(height: 20),
                  _SkillsSection(skills: report.skillBreakdown!),
                ],

                if (widget.session.questions.isNotEmpty &&
                    widget.session.answers.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _QaSection(
                    questions: widget.session.questions,
                    answers:   widget.session.answers,
                  ),
                ],

                if (report.strengths.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _BulletSection(
                    title: 'Strengths',
                    items: report.strengths,
                    color: const Color(0xFF3ECF8E),
                  ),
                ],

                if (report.weaknesses.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _BulletSection(
                    title: 'Weaknesses',
                    items: report.weaknesses,
                    color: const Color(0xFFE05252),
                  ),
                ],

                if (report.improvementPlan.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _ImprovementSection(items: report.improvementPlan),
                ],
              ],
            ),
          ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SUB-WIDGETS  (all logic unchanged, only styling updated)
// ─────────────────────────────────────────────────────────────────────────────

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(_) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(5),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Text(label, style: TextStyle(
      fontSize: 10, fontWeight: FontWeight.w700,
      color: color, letterSpacing: 0.4,
    )),
  );
}

// ── Section label — same eyebrow pattern as home page ────────────────────────
class _EyebrowLabel extends StatelessWidget {
  const _EyebrowLabel({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(), style: TextStyle(
    color: _ui(context).accent, fontSize: 9,
    fontWeight: FontWeight.w700, letterSpacing: 1.6,
  ));
}

// ── Summary / text section ────────────────────────────────────────────────────
class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.content});
  final String title, content;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _EyebrowLabel(text: title),
      const SizedBox(height: 8),
      Text(content, style: TextStyle(
        fontSize: 13, height: 1.55,
        color: _ui(context).textSecondary,
      )),
    ],
  );
}

// ── Skills breakdown ──────────────────────────────────────────────────────────
class _SkillsSection extends StatelessWidget {
  const _SkillsSection({required this.skills});
  final SkillBreakdown skills;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _EyebrowLabel(text: 'Skill Breakdown'),
      const SizedBox(height: 12),
      _SkillBar(label: 'Technical',       value: skills.technical      ?? 0),
      _SkillBar(label: 'Problem Solving', value: skills.problemSolving ?? 0),
      _SkillBar(label: 'Communication',   value: skills.communication  ?? 0),
      _SkillBar(label: 'Confidence',      value: skills.confidence     ?? 0),
    ],
  );
}

class _SkillBar extends StatelessWidget {
  const _SkillBar({required this.label, required this.value});
  final String label;
  final int value;

  Color get _barColor {
    if (value >= 70) return const Color(0xFF3ECF8E);
    if (value >= 50) return const Color(0xFFE8A838);
    return const Color(0xFFE05252);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text(label, style: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w500,
          color: _ui(context).textSecondary,
        ))),
        Text('$value', style: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w700, color: _barColor,
        )),
        Text('/100', style: TextStyle(
          fontSize: 11, color: _ui(context).textMuted,
        )),
      ]),
      const SizedBox(height: 5),
      // Progress bar
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: value / 100,
          minHeight: 5,
          backgroundColor: _ui(context).border,
          valueColor: AlwaysStoppedAnimation(_barColor),
        ),
      ),
    ]),
  );
}

// ── Q&A section ───────────────────────────────────────────────────────────────
class _QaSection extends StatelessWidget {
  const _QaSection({required this.questions, required this.answers});
  final List<Question> questions;
  final List<Answer>   answers;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _EyebrowLabel(text: 'Questions & Answers'),
      const SizedBox(height: 12),
      ...List.generate(questions.length, (i) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: _ui(context).backgroundSecondary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _ui(context).borderSubtle),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Question
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: _ui(context).divider)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                margin: const EdgeInsets.only(top: 1),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: _ui(context).accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('Q${i + 1}', style: TextStyle(
                  fontSize: 9, fontWeight: FontWeight.w800,
                  color: _ui(context).accent,
                )),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(questions[i].text, style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: _ui(context).textPrimary, height: 1.4,
              ))),
            ]),
          ),
          // Answer
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              i < answers.length
                  ? answers[i].transcript
                  : 'No response recorded',
              style: TextStyle(
                fontSize: 12, color: _ui(context).textSecondary, height: 1.45,
              ),
            ),
          ),
        ]),
      )),
    ],
  );
}

// ── Bullet list (strengths / weaknesses) ─────────────────────────────────────
class _BulletSection extends StatelessWidget {
  const _BulletSection({
    required this.title, required this.items, required this.color,
  });
  final String title;
  final List<String> items;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _EyebrowLabel(text: title),
      const SizedBox(height: 10),
      ...items.map((e) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            margin: const EdgeInsets.only(top: 5),
            width: 5, height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(e, style: TextStyle(
            fontSize: 13, color: _ui(context).textSecondary, height: 1.45,
          ))),
        ]),
      )),
    ],
  );
}

// ── Improvement plan ─────────────────────────────────────────────────────────
class _ImprovementSection extends StatelessWidget {
  const _ImprovementSection({required this.items});
  final List<ImprovementItem> items;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _EyebrowLabel(text: 'Improvement Plan'),
      const SizedBox(height: 12),
      ...items.map((item) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _ui(context).backgroundSecondary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _ui(context).borderSubtle),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 6, height: 6,
            margin: const EdgeInsets.only(top: 5),
            decoration: BoxDecoration(
              color: _ui(context).accent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.area, style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: _ui(context).textPrimary,
              )),
              const SizedBox(height: 4),
              Text(item.suggestion, style: TextStyle(
                fontSize: 12, color: _ui(context).textSecondary, height: 1.45,
              )),
            ],
          )),
        ]),
      )),
    ],
  );
}





