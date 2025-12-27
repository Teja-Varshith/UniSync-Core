
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
  

  void interviewQuestionListener(BuildContext context) {
    socket!.on("questionAsked", (data) {
      print("Question asked data from backend is $data");
      // ref.read(interviewListenerProvider.notifier).state = 
      // InterviewStateModel(interviewState: InterviewState.asking).copyWith(
      //   questionRecived: data["question"],
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
