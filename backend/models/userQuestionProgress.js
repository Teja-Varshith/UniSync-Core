import mongoose from "mongoose";

const userQuestionProgressSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      required: true,
      index: true,
    },

    questionId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Question",
      required: true,
      index: true,
    },

    status: {
      type: String,
      enum: ["known", "dont_know", "review"],
      required: true,
    },

    attempts: {
      type: Number,
      default: 1,
    },

    lastSeenAt: {
      type: Date,
      default: Date.now,
    },
  },
  { timestamps: true }
);

/**
 * One user → one status per question
 */
userQuestionProgressSchema.index(
  { userId: 1, questionId: 1 },
  { unique: true }
);

export const UserQuestionProgress = mongoose.model(
  "UserQuestionProgress",
  userQuestionProgressSchema
);
