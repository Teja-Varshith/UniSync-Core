
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisync/features/Carrer_Mode/interview/controllers/interview_controller.dart';
import 'package:unisync/models/interview_state.dart';
import 'package:unisync/sockets/socket_client.dart';


final socketMethodProvider = Provider<SocketMethods>((ref) => SocketMethods(ref: ref));

class SocketMethods {
  final Ref ref;
  SocketMethods({required this.ref});

  final socket = SocketClient.instance.socket;
  bool _initialized = false;

  void initListeners() {
    if (_initialized) return;
    _initialized = true;

    socket!.on("questionAsked", (data) {
      ref.read(interviewControllerProvider.notifier).onQuestionReceived(
        question: data["question"],
        sessionId: data["sessionId"],
      );
    });

    socket!.on("interviewCompleted", (data) {
      final sessionId = data["sessionId"];
      final report = data["report"];
      ref.read(interviewControllerProvider.notifier).onInterviewCompleted(

      );
    });

    socket!.on("outroQuestion", (data) {
      ref.read(interviewControllerProvider.notifier).onOutroQuestionReceived(
        outro: data["outro"],
        sessionId: data["sessionId"],
      );
    });

    socket!.on("error", (data) {
      // ref.read(interviewControllerProvider.notifier).onError(data); 
    });
  }

  void startInterview(String templateId, String userId) {
    socket!.emit("startInterview", {
      'templateId': templateId,
      'userId': userId,
    });
  }

  void submitAnswer({required String sessionId, required String answerTranscript}) {
    socket!.emit("submitAnswer", {
      'sessionId': sessionId,
      'answerTranscript': answerTranscript,
    });
  }
}
