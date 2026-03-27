import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:UniSync/features/interview/services/voice_service.dart';
import 'package:UniSync/models/interview_state.dart';
import 'package:UniSync/sockets/socket_methods.dart';
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
  bool _isOutroSpeaking = false;
  bool _pendingCompletion = false;


  void onQuestionReceived({required String question, required String sessionId}) async{
    state = state.copyWith(
      interviewState: InterviewState.asking,
      questionreceived: question,
      sessionId: sessionId,
    );
    final voice = ref.read(voiceServiceProvider);

    await voice.speak(question, () {
      state = state.copyWith(
        interviewState: InterviewState.waitingForAnswer,
      );
    });
  }

  void onOutroQuestionReceived({required String outro, required String sessionId}) async{
    _isOutroSpeaking = true;

    state = state.copyWith(
      sessionId: sessionId,
      questionreceived: outro,
      isRecording: false,
      interviewState: InterviewState.evaluating,
    );

    final voice = ref.read(voiceServiceProvider);

    await voice.speak(outro, () {
      _isOutroSpeaking = false;
      if (_pendingCompletion) {
        _pendingCompletion = false;
        state = state.copyWith(interviewState: InterviewState.completed);
      }
    });
  }


  Future<void> startRecording() async {
  final granted = await ensureMicPermission();
  if (!granted) return;

  state = state.copyWith(isRecording: true,interviewState: InterviewState.waitingForAnswer);

  _currentTranscript = "";

  await ref.read(voiceServiceProvider).startListening((text) {
    _currentTranscript = text;
  });
}




  Future<void> stopRecordingAndSend() async {
  await ref.read(voiceServiceProvider).stopListening();

  state = state.copyWith(
    isRecording: false,
    interviewState: InterviewState.evaluating,
  );

  if (_currentTranscript.trim().isEmpty) {
    startRecording();
    return;
  }

  print(_currentTranscript);
  ref.read(socketMethodProvider).submitAnswer(answerTranscript: _currentTranscript, sessionId: state.sessionId!);
}

   // TODO: NAVIGATE TO TH E RESULTS PAGE
   void onInterviewCompleted() {
    if (_isOutroSpeaking) {
      _pendingCompletion = true;
      return;
    }
    state = state.copyWith(interviewState: InterviewState.completed);
  }

  void resetInterview() {
    _currentTranscript = "";
    _isOutroSpeaking = false;
    _pendingCompletion = false;
    state = InterviewStateModel(
      interviewState: InterviewState.asking,
      sessionId: null,
      questionreceived: null,
      isRecording: false,
      answerToSend: null,
      questions: null,
      answers: null,
    );
  }

 }