
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisync/constants/constant.dart';
import 'package:unisync/features/interview/controllers/interview_controller.dart';
import 'package:unisync/models/interview_state.dart';
import 'package:unisync/sockets/socket_client.dart';


final socketMethodProvider = Provider<SocketMethods>((ref) => SocketMethods(ref: ref));

class SocketMethods {
  final Ref ref;
  SocketMethods({required this.ref});

  final socket = SocketClient.instance.socket;
  bool _initialized = false;

  String _extractErrorMessage(dynamic data) {
    if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }

    if (data is Map) {
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
    }

    return 'Something went wrong during the interview.';
  }

  void _showSocketError(String message) {
    final messenger = rootScaffoldMessengerKey.currentState;
    if (messenger == null) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          content: AwesomeSnackbarContent(
            title: 'Interview Error',
            message: message,
            contentType: ContentType.failure,
          ),
        ),
      );
  }

  void initListeners() {
    print('initListeners called');
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
      final message = _extractErrorMessage(data);
      _showSocketError(message);
    });
  }

  bool startInterview(String templateId, String userId) {
    if (socket == null || socket!.connected != true) {
      _showSocketError('Server is unreachable. Please try again in a moment.');
      socket?.connect();
      return false;
    }

    socket!.emit("startInterview", {
      'templateId': templateId,
      'userId': userId,
    });
    return true;
  }

  void submitAnswer({required String sessionId, required String answerTranscript}) {
    socket!.emit("submitAnswer", {
      'sessionId': sessionId,
      'answerTranscript': answerTranscript,
    });
  }

  void cancelInterview({required String sessionId}) {
    if (socket == null || socket!.connected != true) {
      return;
    }

    socket!.emit("cancelInterview", {
      'sessionId': sessionId,
    });
  }
}
