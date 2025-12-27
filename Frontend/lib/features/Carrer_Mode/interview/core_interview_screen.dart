import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisync/features/Carrer_Mode/interview/interview_controller.dart';
import 'package:unisync/models/interview_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisync/features/Carrer_Mode/interview/interview_controller.dart';
import 'package:unisync/models/interview_state.dart';
import 'package:unisync/sockets/socket_methods.dart';

class CoreInterviewScreen extends ConsumerStatefulWidget {
  const CoreInterviewScreen({super.key});

  @override
  ConsumerState<CoreInterviewScreen> createState() =>
      _CoreInterviewScreenState();
}

class _CoreInterviewScreenState extends ConsumerState<CoreInterviewScreen> {
  @override
  void initState() {
    super.initState();
  //    WidgetsBinding.instance.addPostFrameCallback((_) {
  //   final initial = ref.read(interviewListenerProvider);

  //   if (initial != null && initial.questionRecived != null) {
  //     ref
  //       .read(interviewControllerProvider.notifier)
  //       .onQuestionReceived(initial.questionRecived!);
  //   }
  // });
  }

  @override
  Widget build(BuildContext context) {
    final interview = ref.watch(interviewControllerProvider);
    final controller = ref.read(interviewControllerProvider.notifier);


    final micEnabled =
    interview.interviewState == InterviewState.waitingForAnswer ||
    interview.isRecording;


  final isRecording = interview.isRecording;


    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0B),
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const Spacer(),
            _Avatar(interview),
            const SizedBox(height: 24),
            _QuestionText(interview.questionRecived),
            const Spacer(),
            Column(
              children: [
                GestureDetector(
                  onTap: micEnabled
                      ? () {
                          if (!isRecording) {
                            // User explicitly starts recording
                            controller.startRecording();
                          } else {
                            // User explicitly ends & submits
                            controller.stopRecordingAndSend();
                          }
                        }
                      : null,
                  child: Opacity(
                    opacity: micEnabled ? 1.0 : 0.35,
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isRecording ? Colors.redAccent : Colors.white,
                      ),
                      child: Icon(
                        isRecording
                            ? Icons.close // ✖ stop & submit
                            : Icons.mic, // 🎤 ready to start
                        color: isRecording ? Colors.white : Colors.black,
                        size: 32,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  !micEnabled
                      ? "Listen to the interviewer"
                      : isRecording
                          ? "Tap ✖ to stop & submit"
                          : "Tap 🎤 to start answering",
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
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

  @override
  void dispose() {
    // Later: stop TTS / STT cleanly if needed
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
        Container(
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: ringColor, width: 2),
          ),
        ),
        const CircleAvatar(
          radius: 70,
          backgroundColor: Colors.black,
          child: Icon(Icons.smart_toy, color: Colors.white, size: 64),
        ),
      ],
    );
  }
}

class _QuestionText extends StatelessWidget {
  final String? text;

  const _QuestionText(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        text ?? "Waiting for interviewer…",
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 18,
          height: 1.5,
        ),
      ),
    );
  }
}
