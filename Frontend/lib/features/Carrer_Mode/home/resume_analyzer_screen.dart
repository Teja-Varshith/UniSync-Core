import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:UniSync/constants/constant.dart';
import 'package:UniSync/features/Carrer_Mode/services/resume_service.dart';

class ResumeAnalyzerScreen extends ConsumerStatefulWidget {
  const ResumeAnalyzerScreen({super.key});

  @override
  ConsumerState<ResumeAnalyzerScreen> createState() =>
      _ResumeAnalyzerScreenState();
}

class _ResumeAnalyzerScreenState extends ConsumerState<ResumeAnalyzerScreen> {
  bool _isLoading = false;
  ResumeAnalysisResult? _result;

  Future<void> _analyze() async {
    try {
      final text = await ResumeService.pickAndExtractText();
      if (text == null) return; // User canceled

      if (text.trim().isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Could not extract text from this PDF.')),
          );
        }
        return;
      }

      setState(() => _isLoading = true);

      final result = await ResumeService.analyzeResume(text);

      setState(() {
        _result = result;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Analysis failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UniSyncColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: UniSyncColors.backgroundPrimary,
        elevation: 0,
        iconTheme: const IconThemeData(color: UniSyncColors.textPrimary),
        title: const Text(
          'Resume Analysis',
          style: TextStyle(
            fontFamily: 'Syne',
            color: UniSyncColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Hero Section ──
            const Text(
              'Get real-time insights on your resume.',
              style: TextStyle(
                fontSize: 16,
                color: UniSyncColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // ── Upload Card ──
            if (_result == null && !_isLoading)
              GestureDetector(
                onTap: _analyze,
                child: Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: UniSyncColors.surfaceCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: UniSyncColors.accent.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: const [
                      Icon(Icons.upload_file,
                          size: 48, color: UniSyncColors.accent),
                      SizedBox(height: 16),
                      Text(
                        'Upload PDF to Analyze',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: UniSyncColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'We will evaluate your ATS score and provide actionable feedback.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: UniSyncColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Loading State ──
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: const [
                    CircularProgressIndicator(color: UniSyncColors.accent),
                    SizedBox(height: 20),
                    Text(
                      'Arya is analyzing your resume...',
                      style: TextStyle(
                        fontFamily: 'Syne',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: UniSyncColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Checking ATS compatibility and formatting.',
                      style: TextStyle(
                        fontSize: 13,
                        color: UniSyncColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

            // ── Results View ──
            if (_result != null && !_isLoading) ...[
              // Score Circle
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: UniSyncColors.surfaceCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: UniSyncColors.borderSubtle),
                ),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          height: 120,
                          width: 120,
                          child: CircularProgressIndicator(
                            value: _result!.atsScore / 100,
                            strokeWidth: 12,
                            backgroundColor: UniSyncColors.border,
                            color: _getScoreColor(_result!.atsScore),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${_result!.atsScore}',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: _getScoreColor(_result!.atsScore),
                              ),
                            ),
                            const Text(
                              'ATS Score',
                              style: TextStyle(
                                fontSize: 12,
                                color: UniSyncColors.textMuted,
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Summary
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: UniSyncColors.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: UniSyncColors.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Summary',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: UniSyncColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _result!.summary,
                      style: const TextStyle(
                        fontSize: 14,
                        color: UniSyncColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Pros
              if (_result!.pros.isNotEmpty) ...[
                const Text(
                  'What you did well',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: UniSyncColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                ..._result!.pros.map((p) => _buildListItem(p, true)),
                const SizedBox(height: 20),
              ],

              // Cons
              if (_result!.cons.isNotEmpty) ...[
                const Text(
                  'Room for improvement',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: UniSyncColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                ..._result!.cons.map((c) => _buildListItem(c, false)),
              ],

              const SizedBox(height: 32),
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _analyze,
                  icon: const Icon(Icons.refresh, color: UniSyncColors.buttonPrimaryFg),
                  label: const Text(
                    'Analyze Another',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: UniSyncColors.buttonPrimaryBg,
                    foregroundColor: UniSyncColors.buttonPrimaryFg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildListItem(String text, bool isPro) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isPro ? Icons.check_circle : Icons.cancel,
            size: 20,
            color: isPro ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: UniSyncColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }
}
