import mongoose from "mongoose";

const templateSchema = new mongoose.Schema(
  {
    title: {
      type: String,
      required: true,
    },
    topics: [
      {
        type: String,
      },
    ],
    evaluationMetrics: [
      {
        topic: {
          type: String,
          required: true,
          trim: true,
        },
        description: {
          type: String,
          required: true,
        },
      },
    ],
    domain: {
      type: String,
    },
    icon: {
      type: String,
      required: true,
    },
  },
  { timestamps: true }
);

export const Template = mongoose.model("Template", templateSchema);
