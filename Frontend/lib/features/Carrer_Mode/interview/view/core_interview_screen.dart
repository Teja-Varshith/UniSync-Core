import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:routemaster/routemaster.dart';
import 'package:unisync/features/Carrer_Mode/interview/controllers/interview_controller.dart';
import 'package:unisync/models/interview_state.dart';
import 'package:unisync/sockets/socket_methods.dart';

class CoreInterviewScreen extends ConsumerStatefulWidget {
  const CoreInterviewScreen({super.key});

  @override
  ConsumerState<CoreInterviewScreen> createState() =>
      _CoreInterviewScreenState();
}

class _CoreInterviewScreenState
    extends ConsumerState<CoreInterviewScreen> {
  @override
  Widget build(BuildContext context) {
    ref.listen(interviewControllerProvider, (prev, next) {
      if (next.interviewState == InterviewState.completed) {
        Routemaster.of(context).push('/carrer');
      }
    });

    final interview = ref.watch(interviewControllerProvider);
    final controller =
        ref.read(interviewControllerProvider.notifier);

    final micEnabled =
        interview.interviewState ==
                InterviewState.waitingForAnswer ||
            interview.isRecording;

    final isRecording = interview.isRecording;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0B),
      body: SafeArea(
        child: Column(
          children: [
            // ───────── TOP BAR ─────────
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: ()  {
                      showExitInterviewDialog(context, Navigator.of(context).pop);  // TODO: add the intervie end logics
                    },
                    icon: const Icon(Icons.close,
                        color: Colors.white70),
                  ),
                  const Spacer(),
                  const Text(
                    'UniSync',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      showInterviewHelpDialog(context);
                    },
                    icon: const Icon(Icons.help_outline,
                        color: Colors.white54),
                  ),
                ],
              ),
            ),

            Divider(color: Colors.white10),

            const SizedBox(height: 24),

            // ───────── AVATAR ─────────
            _Avatar(interview),

            const SizedBox(height: 20),

            // ───────── STATUS ─────────
            _InterviewStatus(interview),

            const SizedBox(height: 20),

            // ───────── QUESTION ─────────
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24),
                child: SingleChildScrollView(
                  physics:
                      const BouncingScrollPhysics(),
                  child: Text(
                    interview.questionreceived ??
                        "Waiting for interviewer…",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                      height: 1.6,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ───────── MIC CONTROLS ─────────
            Column(
              children: [
                GestureDetector(
                  onTap: micEnabled
                      ? () {
                          if (!isRecording) {
                            controller.startRecording();
                          } else {
                            controller
                                .stopRecordingAndSend();
                          }
                        }
                      : null,
                  child: Opacity(
                    opacity: micEnabled ? 1 : 0.4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 14),
                      decoration: BoxDecoration(
                        color: isRecording
                            ? Colors.redAccent
                            : Colors.white,
                        borderRadius:
                            BorderRadius.circular(32),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isRecording
                                ? Icons.stop
                                : Icons.mic,
                            color: isRecording
                                ? Colors.white
                                : Colors.black,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            isRecording
                                ? "Stop & Submit"
                                : "Speak Now",
                            style: TextStyle(
                              color: isRecording
                                  ? Colors.white
                                  : Colors.black,
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
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _helperText(InterviewStateModel interview) {
    if (interview.interviewState ==
        InterviewState.evaluating) {
      return "Evaluating your answer…";
    }
    if (interview.isRecording) {
      return "Speak clearly. Tap stop when finished.";
    }
    if (interview.interviewState ==
        InterviewState.waitingForAnswer) {
      return "Tap to start answering";
    }
    return "Listen carefully to the interviewer";
  }

  @override
  void dispose() {
    ref.read(voiceServiceProvider).stopSpeaking();
    super.dispose();
  }
}

// ───────── AVATAR ─────────
class _Avatar extends StatelessWidget {
  final InterviewStateModel interview;
  const _Avatar(this.interview);

  @override
  Widget build(BuildContext context) {
    Color ringColor;
    switch (interview.interviewState) {
      case InterviewState.asking:
        ringColor = Colors.blueAccent;
        break;
      case InterviewState.waitingForAnswer:
        ringColor = Colors.grey;
        break;
      case InterviewState.evaluating:
        ringColor = Colors.orangeAccent;
        break;
      default:
        ringColor = Colors.grey.shade800;
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
            border:
                Border.all(color: ringColor, width: 2),
          ),
        ),
        const CircleAvatar(
          radius: 64,
          backgroundColor: Colors.black,
          child: Icon(Icons.smart_toy,
              color: Colors.white, size: 56),
        ),
      ],
    );
  }
}

// ───────── STATUS TEXT ─────────
class _InterviewStatus extends StatelessWidget {
  final InterviewStateModel interview;
  const _InterviewStatus(this.interview);

  @override
  Widget build(BuildContext context) {
    String text;
    Color color;

    switch (interview.interviewState) {
      case InterviewState.asking:
        text = "Interviewer is speaking";
        color = Colors.blueAccent;
        break;
      case InterviewState.waitingForAnswer:
        text = "Your turn to answer";
        color = Colors.white70;
        break;
      case InterviewState.evaluating:
        text = "Evaluating your response";
        color = Colors.orangeAccent;
        break;
      default:
        text = "Preparing interview";
        color = Colors.white54;
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
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Interview Help',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          '• Listen carefully to the interviewer.\n\n'
          '• When it is your turn, tap "Speak Now" and answer clearly.\n\n'
          '• Tap "Stop & Submit" once you finish your answer.\n\n'
          '• While evaluating, please wait. This may take a few seconds.\n\n'
          '• Avoid background noise for best results.',
          style: TextStyle(fontSize: 15, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Got it',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      );
    },
  );
}


void showExitInterviewDialog(BuildContext context, VoidCallback onExit) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Exit Interview?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Don't worry we will save your progress",
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Stay',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onExit();  
            },
            child: const Text(
              'Exit',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      );
    },
  );
}
