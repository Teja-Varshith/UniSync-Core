import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:routemaster/routemaster.dart';
import 'package:UniSync/features/interview/controllers/interview_controller.dart';
import 'package:UniSync/features/interview/view/interview_palette.dart';
import 'package:UniSync/models/interview_state.dart';
import 'package:UniSync/sockets/socket_methods.dart';

InterviewPalette _ui(BuildContext context) => InterviewPalette.of(context);

class CoreInterviewScreen extends ConsumerStatefulWidget {
  const CoreInterviewScreen({super.key});

  @override
  ConsumerState<CoreInterviewScreen> createState() => _CoreInterviewScreenState();
}

class _CoreInterviewScreenState extends ConsumerState<CoreInterviewScreen> {
  Future<bool> _confirmExitInterview() async {
    final shouldExit = await showExitInterviewDialog(context);
    if (shouldExit && mounted) {
      final sessionId = ref.read(interviewControllerProvider).sessionId;
      if (sessionId != null && sessionId.isNotEmpty) {
        ref.read(socketMethodProvider).cancelInterview(sessionId: sessionId);
      }

      ref.read(voiceServiceProvider).stopSpeaking();
      ref.read(interviewControllerProvider.notifier).resetInterview();
      Routemaster.of(context).replace('/carrer-interview-screen');
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(interviewControllerProvider, (prev, next) {
      if (next.interviewState == InterviewState.completed) {
        Routemaster.of(context).replace('/reportsScreen');
      }
    });

    final interview = ref.watch(interviewControllerProvider);
    final controller = ref.read(interviewControllerProvider.notifier);

    final micEnabled =
        interview.interviewState == InterviewState.waitingForAnswer || interview.isRecording;
    final isRecording = interview.isRecording;

    return WillPopScope(
      onWillPop: _confirmExitInterview,
      child: Scaffold(
        backgroundColor: _ui(context).backgroundPrimary,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _confirmExitInterview,
                      icon: Icon(Icons.close, color: _ui(context).textSecondary),
                    ),
                    const Spacer(),
                    Text(
                      'UniSync',
                      style: TextStyle(
                        color: _ui(context).textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => showInterviewHelpDialog(context),
                      icon: Icon(Icons.help_outline, color: _ui(context).textMuted),
                    ),
                  ],
                ),
              ),
              Divider(color: _ui(context).divider),
              const SizedBox(height: 24),
              _Avatar(interview),
              const SizedBox(height: 20),
              _InterviewStatus(interview),
              const SizedBox(height: 20),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Text(
                      interview.questionreceived ?? 'Waiting for interviewer...',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _ui(context).textSecondary,
                        fontSize: 18,
                        height: 1.6,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Column(
                children: [
                  GestureDetector(
                    onTap: micEnabled
                        ? () {
                            if (!isRecording) {
                              controller.startRecording();
                            } else {
                              controller.stopRecordingAndSend();
                            }
                          }
                        : null,
                    child: Opacity(
                      opacity: micEnabled ? 1 : 0.4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                        decoration: BoxDecoration(
                          color: isRecording ? _ui(context).error : _ui(context).accent,
                          borderRadius: BorderRadius.circular(32),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isRecording ? Icons.stop : Icons.mic,
                              color:
                                  isRecording ? _ui(context).onError : _ui(context).buttonPrimaryFg,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              isRecording ? 'Stop & Submit' : 'Speak Now',
                              style: TextStyle(
                                color: isRecording
                                    ? _ui(context).onError
                                    : _ui(context).buttonPrimaryFg,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _helperText(interview),
                    style: TextStyle(
                      color: _ui(context).textMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  String _helperText(InterviewStateModel interview) {
    if (interview.interviewState == InterviewState.evaluating) {
      return 'Evaluating your answer...';
    }
    if (interview.isRecording) {
      return 'Speak clearly. Tap stop when finished.';
    }
    if (interview.interviewState == InterviewState.waitingForAnswer) {
      return 'Tap to start answering';
    }
    return 'Listen carefully to the interviewer';
  }

  @override
  void dispose() {
    ref.read(voiceServiceProvider).stopSpeaking();
    super.dispose();
  }
}

class _Avatar extends StatelessWidget {
  final InterviewStateModel interview;
  const _Avatar(this.interview);

  @override
  Widget build(BuildContext context) {
    Color ringColor;
    switch (interview.interviewState) {
      case InterviewState.asking:
        ringColor = _ui(context).info;
        break;
      case InterviewState.waitingForAnswer:
        ringColor = _ui(context).accent;
        break;
      case InterviewState.evaluating:
        ringColor = _ui(context).warning;
        break;
      default:
        ringColor = _ui(context).borderSubtle;
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: ringColor, width: 2),
          ),
        ),
        CircleAvatar(
          radius: 64,
          backgroundColor: _ui(context).surfaceCard,
          child: Icon(Icons.smart_toy, color: _ui(context).accent, size: 56),
        ),
      ],
    );
  }
}

class _InterviewStatus extends StatelessWidget {
  final InterviewStateModel interview;
  const _InterviewStatus(this.interview);

  @override
  Widget build(BuildContext context) {
    String text;
    Color color;

    switch (interview.interviewState) {
      case InterviewState.asking:
        text = 'Interviewer is speaking';
        color = _ui(context).info;
        break;
      case InterviewState.waitingForAnswer:
        text = 'Your turn to answer';
        color = _ui(context).accent;
        break;
      case InterviewState.evaluating:
        text = 'Evaluating your response';
        color = _ui(context).warning;
        break;
      default:
        text = 'Preparing interview';
        color = _ui(context).textMuted;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

void showInterviewHelpDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: _ui(dialogContext).backgroundSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Interview Help',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: _ui(dialogContext).textPrimary,
          ),
        ),
        content: Text(
          '- Listen carefully to the interviewer.\n\n'
          '- When it is your turn, tap "Speak Now" and answer clearly.\n\n'
          '- Tap "Stop & Submit" once you finish your answer.\n\n'
          '- While evaluating, please wait. This may take a few seconds.\n\n'
          '- Avoid background noise for best results.',
          style: TextStyle(
            color: _ui(dialogContext).textSecondary,
            fontSize: 15,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Got it',
              style: TextStyle(
                color: _ui(dialogContext).accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    },
  );
}

Future<bool> showExitInterviewDialog(BuildContext context) async {
  final shouldExit = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: _ui(dialogContext).backgroundSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Exit Interview?',
          style: TextStyle(
            color: _ui(dialogContext).textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          "Don't worry we will save your progress",
          style: TextStyle(
            color: _ui(dialogContext).textSecondary,
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Stay',
              style: TextStyle(color: _ui(dialogContext).textMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              'Exit',
              style: TextStyle(color: _ui(dialogContext).error),
            ),
          ),
        ],
      );
    },
  );
  return shouldExit ?? false;
}
