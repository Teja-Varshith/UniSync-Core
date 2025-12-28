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
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            _appBar(context),
            Expanded(
              child: rprts.when(
                error: (error, _) => Center(
                  child: Text(
                    error.toString(),
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                data: (data) {
                  if (data.isEmpty) {
                    return const Center(
                      child: Text('No interview reports found'),
                    );
                  }
                  return ListView.builder(
                    itemCount: data.length,
                    padding: const EdgeInsets.all(16),
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
        return const Color(0xFF4CAF50);
      case 'in_progress':
        return const Color(0xFF2196F3);
      case 'failed':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  Color _getCardColor() {
    final colors = [
      const Color(0xFFFFF9E6),
      const Color(0xFFE8F5E9),
      const Color(0xFFE3F2FD),
      const Color(0xFFFCE4EC),
      const Color(0xFFF3E5F5),
    ];
    return colors[widget.sessionNumber % colors.length];
  }

  Color _getScoreColor(int score) {
    if (score >= 70) return const Color(0xFF4CAF50);
    if (score >= 50) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.session.finalReport;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _getCardColor(),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => expanded = !expanded),
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
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Icon(expanded ? Icons.expand_less : Icons.expand_more),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 14, color: Color(0xFF757575)),
                      const SizedBox(width: 6),
                      Text(
                        _formatDate(widget.session.startedAt),
                        style: const TextStyle(fontSize: 13, color: Color(0xFF757575)),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.access_time, size: 14, color: Color(0xFF757575)),
                      const SizedBox(width: 6),
                      Text(
                        _formatTime(widget.session.startedAt),
                        style: const TextStyle(fontSize: 13, color: Color(0xFF757575)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          widget.session.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(),
                          ),
                        ),
                      ),
                      if (report != null) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getScoreColor(report.overallScore ?? 0).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Score: ${report.overallScore ?? 0}/100',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _getScoreColor(report.overallScore ?? 0),
                            ),
                          ),
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
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFE0E0E0))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection('Summary', report.summary),
                  if (report.skillBreakdown != null) ...[
                    const SizedBox(height: 16),
                    _buildSkills(report.skillBreakdown!),
                  ],
                  if (report.strengths.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildList('Strengths', report.strengths),
                  ],
                  if (report.weaknesses.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildList('Weaknesses', report.weaknesses),
                  ],
                  if (report.improvementPlan.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildPlan(report.improvementPlan),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(content, style: const TextStyle(fontSize: 13, height: 1.5)),
      ],
    );
  }

  Widget _buildSkills(SkillBreakdown skills) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Skills', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        _buildSkillRow('Technical', skills.technical ?? 0),
        _buildSkillRow('Problem Solving', skills.problemSolving ?? 0),
        _buildSkillRow('Communication', skills.communication ?? 0),
        _buildSkillRow('Confidence', skills.confidence ?? 0),
      ],
    );
  }

  Widget _buildSkillRow(String label, int value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Text('#', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          Text('$value/100', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildList(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('#', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(item, style: const TextStyle(fontSize: 13, height: 1.5))),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildPlan(List<ImprovementItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Improvement Plan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ...items.map((item) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('#', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.area, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(item.suggestion, style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}

Widget _appBar(BuildContext context) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0))),
    ),
    child: Row(
      children: [
        IconButton(
          onPressed: () => Routemaster.of(context).replace("/startInterviewScreen"),
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 12),
        const Text(
          "Interview Reports",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}