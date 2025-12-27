
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisync/features/Carrer_Mode/interview/interview_controller.dart';
import 'package:unisync/models/interview_state.dart';
import 'package:unisync/sockets/socket_client.dart';


final socketMethodProvider = StateProvider((ref) => SocketMethods(ref: ref));
// final exchangeProvider = StateProvider<ExchangeModel>((ref) => {});
// final interviewListenerProvider = StateProvider<InterviewStateModel?>((ref) {
//   return null;
// });

class SocketMethods {
  final Ref ref;
  SocketMethods({required this.ref});
  final socket = SocketClient.instance.socket;

  void startInterview(String templateId, String userId) {
    print('Starting interview with templateId: $templateId and userId: $userId');
    socket!.emit("startInterview", {
      'templateId' : templateId,
      'userId' : userId,
    });
  }
  
  void onAnswerSubmitted({required String answerTranscript, required String sessionId}) {
    print('Submitting answer: $answerTranscript for sessionId: $sessionId');
    socket!.emit("submitAnswer", {
      'answerTranscript' : answerTranscript,
      'sessionId' : sessionId,
    });
  }
  
  void outroQuestionListener(BuildContext context) {
    socket!.on("outroQuestion", (data) {
      print("Outro question data from backend is $data");
        ref.read(interviewControllerProvider.notifier).onOutroQuestionReceived(
        outro: data["outro"],
        sessionId: data["sessionId"],
      );

      ref.read(interviewControllerProvider.notifier).state = ref.read(interviewControllerProvider.notifier).state.copyWith(
        interviewState: InterviewState.completed,
      );



      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Outro Question: ${data}"),
        ),
      );
    });
  }


  void interviewQuestionListener(BuildContext context) {
    socket!.on("questionAsked", (data) {
      print("Question asked data from backend is $data");
      // ref.read(interviewListenerProvider.notifier).state = 
      // InterviewStateModel(interviewState: InterviewState.asking).copyWith(
      //   questionreceived: data["question"],
      //   micOn: false,
      //   questions: ref.read(interviewListenerProvider)?.questions != null
      //     ? [...ref.read(interviewListenerProvider)!.questions!, data["question"]]
      //     : [data["question"]],
      //     answers: [],
      // );

      ref.read(interviewControllerProvider.notifier).onQuestionReceived(
        question: data["question"],
        sessionId: data["sessionId"],
      );


      // print(ref.read(interviewListenerProvider));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("New Question: ${data}"),
        ),
      );
    });
  }

  void errorListener(BuildContext context) {

    // end interview and go bkk


    socket!.on("error", (data) {
      print("Error from backend is $data");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${data}"),
        ),
      );
    });
  }




}
