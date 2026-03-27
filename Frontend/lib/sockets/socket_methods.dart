import 'dart:async';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:UniSync/constants/constant.dart';
import 'package:UniSync/features/interview/controllers/interview_controller.dart';
import 'package:UniSync/models/interview_state.dart';
import 'package:UniSync/sockets/socket_client.dart';


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

  Future<bool> warmUpBackend() async {
    const maxAttempts = 5;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final response = await dio.get(
          HEALTHCHECK_URI,
          options: Options(
            sendTimeout: const Duration(seconds: 8),
            receiveTimeout: const Duration(seconds: 8),
          ),
        );

        if (response.statusCode == 200 && response.data is Map && response.data['ok'] == true) {
          return true;
        }
      } catch (_) {
        if (attempt == maxAttempts) {
          return false;
        }
      }

      await Future<void>.delayed(Duration(seconds: attempt));
    }

    return false;
  }

  Future<bool> _ensureConnected() async {
    if (socket == null) {
      return false;
    }

    if (socket!.connected == true) {
      return true;
    }

    final completer = Completer<bool>();

    void handleConnect(dynamic _) {
      if (!completer.isCompleted) {
        completer.complete(true);
      }
    }

    void handleFailure(dynamic _) {
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    }

    socket!.once('connect', handleConnect);
    socket!.once('connect_error', handleFailure);
    socket!.once('disconnect', handleFailure);
    socket!.connect();

    try {
      return await completer.future.timeout(const Duration(seconds: 12));
    } on TimeoutException {
      return false;
    }
  }

  Future<bool> startInterview(
    String templateId,
    String userId, {
    int? questionLimit,
  }) async {
    final backendReady = await warmUpBackend();
    if (!backendReady) {
      _showSocketError('Interview server is waking up. Please try again in a moment.');
      return false;
    }

    final connected = await _ensureConnected();
    if (!connected) {
      _showSocketError('Server is unreachable. Please try again in a moment.');
      return false;
    }

    socket!.emit("startInterview", {
      'templateId': templateId,
      'userId': userId,
      if (questionLimit != null) 'questionLimit': questionLimit,
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
