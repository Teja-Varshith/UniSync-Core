import { type } from "os";

InterviewExchange = {
  sessionId: ObjectId,

  templateSnapshot: {
    templateId: ObjectId,
    domain: String,
    evaluationMetrics: [String],
    targetCompany: {
        type: String,
        default: "Not Specified"
    }
  },

  systemPrompt: String,

  interviewState: {
    type: String,
    enum: ["asking", "waitingForAnswer", "evaluating", "completed"],
  },

  questions: [
    {
      text: String,
    }
  ],

  answers: [
    {
      transcript: String,
    }
  ],

  limits: Number,

  meta: {
    questionsAsked: Number,
    startedAt: Date,
    lastActivityAt: Date,
  }
};
