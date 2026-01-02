import mongoose from "mongoose";

const questionSchema = new mongoose.Schema(
  {
    subDomainId: {
      type: String,
      required: true,
      lowercase: true,
      trim: true,
      index: true,
    },

    question: {
      type: String,
      required: true,
      trim: true,
    },

    answer: {
      type: String,
      required: true,
      trim: true,
    },

    difficulty: {
      type: String,
      enum: ["easy", "medium", "hard"],
      default: "medium",
    },

    tags: {
      type: [String],
      default: [],
      index: true,
    },

    isActive: {
      type: Boolean,
      default: true,
    },
  },
  { timestamps: true }
);

questionSchema.index(
  { question: 1 },
  { unique: true }
);



export const Question = mongoose.model("Question", questionSchema);
