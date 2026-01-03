import mongoose from "mongoose";

const documentSchema = new mongoose.Schema(
  {
    UserId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    slug :{
        type : String,
        required : true
    },
    filepath: {
      type: String,
      required: true,
    },
    fileSize: {
      type: Number,
      required: true,
    },
    extractedText: {
      type: String,
      defualt: "",
    },
    uploadDate: {
      type: Date,
      defualt: Date.now,
    },
    lastAccessed: {
      type: Date,
      defualt: Date.now,
    },
    status: {
      type: String,
      enum: ["processing", "ready", "failed"],
      defualt: "processing",
    },
  },
  { timestamps: true }
);

documentSchema.index({ userId: 1, uploadDate: -1 });

export const Document = mongoose.model("Document", documentSchema);