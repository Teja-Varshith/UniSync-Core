import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisync/features/Carrer_Mode/interview/services/voice_service.dart';
import 'package:unisync/models/interview_state.dart';
import 'package:unisync/sockets/socket_methods.dart';
import 'package:permission_handler/permission_handler.dart';




Future<bool> ensureMicPermission() async {
  final status = await Permission.microphone.request();
  return status.isGranted;
}



final voiceServiceProvider = Provider((ref) {
  final service = VoiceService();
  service.init();
  return service;
});

final interviewControllerProvider =
    StateNotifierProvider<InterviewController, InterviewStateModel>(
  (ref) => InterviewController(ref),
);

class InterviewController extends StateNotifier<InterviewStateModel> {
  InterviewController(this.ref)
      : super(InterviewStateModel(
        interviewState: InterviewState.asking,
      ));

  final Ref ref;

  String _currentTranscript = "";


  void onQuestionReceived({required String question, required String sessionId}) async{
    state = state.copyWith(
      interviewState: InterviewState.asking,
      questionRecived: question,
      sessionId: sessionId,
    );
    final voice = ref.read(voiceServiceProvider);

    await voice.speak(question, () {
      state = state.copyWith(
        interviewState: InterviewState.waitingForAnswer,
      );
    });
  }

  Future<void> startRecording() async {
  final granted = await ensureMicPermission();
  if (!granted) return;

  state = state.copyWith(isRecording: true);

  _currentTranscript = "";

  await ref.read(voiceServiceProvider).startListening((text) {
    _currentTranscript = text;
  });
}


  Future<void> stopRecordingAndSend() async {
  final transcript =
      await ref.read(voiceServiceProvider).stopListening();

  state = state.copyWith(
    isRecording: false,
    interviewState: InterviewState.evaluating,
  );

  if (transcript.isEmpty) return;

  print(transcript);
  // ref.read(socketMethodProvider).sendAnswer(transcript);
}


   void onInterviewCompleted() {
    state = state.copyWith(interviewState: InterviewState.completed);
  }

  // void micOn() {
  //   state = state.copyWith(
  //     micOn: true,
  //     interviewState: InterviewState.waitingForAnswer,
  //   );
  // }

  // Future<void> micOffAndSubmit(String transcript) async {
  //   state = state.copyWith(
  //     micOn: false,
  //     interviewState: InterviewState.evaluating,
  //   );

    // ref.read(socketMethodProvider).sendAnswer(transcript);
  }

  // void onNewQuestion(String question) {
  //   state = state.copyWith(
  //     phase: InterviewPhase.asking,
  //     currentQuestion: question,
  //   );
  // }

  // void onCompleted(InterviewReport report) {
  //   state = state.copyWith(
  //     phase: InterviewPhase.completed,
  //     report: report,
  //   );
  // }

  // void onError(String message) {
  //   state = state.copyWith(
  //     phase: InterviewPhase.error,
  //     error: message,
  //   );
  // }
