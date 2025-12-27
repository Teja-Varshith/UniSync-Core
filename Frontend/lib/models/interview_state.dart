// ignore_for_file: public_member_api_docs, sort_constructors_first
enum InterviewState{
  asking,
  waitingForAnswer,
  evaluating,
  completed
}

class InterviewStateModel {
  final InterviewState interviewState;
  final String? sessionId;
  final bool micOn;
  final String? questionreceived;
  final bool isRecording;
  final String? answerToSend;
  final List<String>? questions;
  final List<String>? answers;
  InterviewStateModel({
    required this.interviewState,
    this.sessionId,
    this.micOn = false,
    this.questionreceived,
    this.isRecording = false,
    this.answerToSend,
    this.questions,
    this.answers,
  });

 



  InterviewStateModel copyWith({
    InterviewState? interviewState,
    String? sessionId,
    bool? micOn,
    String? questionreceived,
    bool? isRecording,
    String? answerToSend,
    List<String>? questions,
    List<String>? answers,
  }) {
    return InterviewStateModel(
      interviewState: interviewState ?? this.interviewState,
      sessionId: sessionId ?? this.sessionId,
      micOn: micOn ?? this.micOn,
      questionreceived: questionreceived ?? this.questionreceived,
      isRecording: isRecording ?? this.isRecording,
      answerToSend: answerToSend ?? this.answerToSend,
      questions: questions ?? this.questions,
      answers: answers ?? this.answers,
    );
  }
}
