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
      },

      verdict: {
        type: String,
        enum: ["Strong Hire", "Hire", "Borderline", "Reject"],
      },

      skillBreakdown: {
        technical: Number,
        problemSolving: Number,
        communication: Number,
        confidence: Number,
      },

      strengths: [String],
      weaknesses: [String],

      improvementPlan: [
        {
          area: String,
          suggestion: String,
        },
      ],

      summary: {
        type: String,
      },
    },
  },
  { timestamps: true }
);

export const InterviewSession = mongoose.model("InterviewSession", interviewSessionSchema);
