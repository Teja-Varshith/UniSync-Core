import mongoose from "mongoose";

const interviewSessionSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    templateId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Template",
      required: true,
    },
    status: {
      type: String,
      enum: ["completed", "aborted", "inProgress"],
    },

    startedAt: {
      type: Date,
      default: Date.now,
    },

    endedAt: {
      type: Date,
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

    finalReport: {
  overallScore: {
    type: Number,
    min: 0,
    max: 100,
    default: null,
  },

  verdict: {
    type: String,
    enum: ["Strong Hire", "Hire", "Borderline", "Reject"],
    default: null,
  },

  skillBreakdown: {
    technical: {
      type: Number,
      min: 0,
      max: 100,
      default: null,
    },
    problemSolving: {
      type: Number,
      min: 0,
      max: 100,
      default: null,
    },
    communication: {
      type: Number,
      min: 0,
      max: 100,
      default: null,
    },
    confidence: {
      type: Number,
      min: 0,
      max: 100,
      default: null,
    },
  },

  strengths: {
    type: [String],
    default: [],
  },

  weaknesses: {
    type: [String],
    default: [],
  },

  improvementPlan: {
    type: [
      {
        area: { type: String },
        suggestion: { type: String },
      },
    ],
    default: [],
  },

  summary: {
    type: String,
    default: "",
  },

  generatedAt: {
    type: Date,
    default: Date.now,
  },
}

  },
  { timestamps: true }
);

export const InterviewSession = mongoose.model("InterviewSession", interviewSessionSchema);
