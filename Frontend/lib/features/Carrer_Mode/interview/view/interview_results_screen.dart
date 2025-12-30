import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:routemaster/routemaster.dart';
import 'package:unisync/features/Carrer_Mode/interview/controllers/reports_controller.dart';
import 'package:unisync/models/interview_report_model.dart';

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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _appBar(context),


            Divider(),

            Expanded(
              child: rprts.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, _) => Center(
                  child: Text(
                    error.toString(),
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
                data: (data) {
                  if (data.isEmpty) {
                    return const Center(
                      child: Text(
                        'No interview reports found',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      return ReportCard(
                        session: data[index],
                        sessionNumber: data.length - index,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReportCard extends StatefulWidget {
  final InterviewSession session;
  final int sessionNumber;

  const ReportCard({
    super.key,
    required this.session,
    required this.sessionNumber,
  });

  @override
  State<ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends State<ReportCard> {
  bool expanded = false;

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('MMM dd, yyyy').format(date);
  }

  String _formatTime(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('hh:mm a').format(date);
  }

  Color _getStatusColor() {
    switch (widget.session.status.toLowerCase()) {
      case 'completed':
        return const Color(0xFF16A34A);
      case 'in_progress':
        return const Color(0xFF2563EB);
      case 'failed':
        return const Color(0xFFDC2626);
      default:
        return Colors.grey;
    }
  }

  Color _getScoreColor(int score) {
    if (score >= 70) return const Color(0xFF16A34A);
    if (score >= 50) return const Color(0xFFF59E0B);
    return const Color(0xFFDC2626);
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.session.finalReport;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => expanded = !expanded),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Session #${widget.sessionNumber}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      Icon(
                        expanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.grey.shade600,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 6),
                      Text(
                        _formatDate(widget.session.startedAt),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.access_time,
                          size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 6),
                      Text(
                        _formatTime(widget.session.startedAt),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _pill(
                        widget.session.status.toUpperCase(),
                        _getStatusColor(),
                      ),
                      if (report != null) ...[
                        const SizedBox(width: 10),
                        _pill(
                          'Score ${report.overallScore ?? 0}/100',
                          _getScoreColor(
                              report.overallScore ?? 0),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (expanded && report != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _section('Summary', report.summary),
                  if (report.skillBreakdown != null) ...[
                    const SizedBox(height: 16),
                    _skills(report.skillBreakdown!),
                  ],
                  if (widget.session.questions.isNotEmpty &&
                      widget.session.answers.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _qaSection(
                      widget.session.questions,
                      widget.session.answers,
                    ),
                  ],
                  if (report.strengths.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _list('Strengths', report.strengths),
                  ],
                  if (report.weaknesses.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _list('Weaknesses', report.weaknesses),
                  ],
                  if (report.improvementPlan.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _plan(report.improvementPlan),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _section(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(
            fontSize: 13,
            height: 1.5,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  Widget _qaSection(List<Question> questions, List<Answer> answers) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Questions & Answers',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...List.generate(
          questions.length,
          (i) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  questions[i].text,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  i < answers.length
                      ? answers[i].transcript
                      : 'No response recorded',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _skills(SkillBreakdown skills) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Skills',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        _skill('Technical', skills.technical ?? 0),
        _skill('Problem Solving', skills.problemSolving ?? 0),
        _skill('Communication', skills.communication ?? 0),
        _skill('Confidence', skills.confidence ?? 0),
      ],
    );
  }

  Widget _skill(String label, int value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Text(
            '$value/100',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _list(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              '• $e',
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }

  Widget _plan(List<ImprovementItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Improvement Plan',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map(
          (item) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.area,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.suggestion,
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}


Widget _appBar(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
    child: Row(
      children: [
        IconButton(
          onPressed: () => Routemaster.of(context).replace("/startInterviewScreen"),
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 20),
          splashRadius: 20,
        ),
        const SizedBox(width: 4),
        const Text(
          "Interview Rports",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}