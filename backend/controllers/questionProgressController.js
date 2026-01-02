import { UserQuestionProgress } from "../models/userQuestionProgress.js";
import mongoose from "mongoose";
import {Question} from "../models/questions.js"

export const updateQuestionProgress = async (req, res) => {
  try {
    
    const { userId, questionId, status } = req.body;

    if (
      !questionId ||
      !mongoose.Types.ObjectId.isValid(questionId) ||
      !["known", "dont_know", "review"].includes(status)
    ) {
      return res.status(400).json({
        success: false,
        message: "Invalid questionId or status",
      });
    }

    const progress = await UserQuestionProgress.findOne({
      userId,
      questionId,
    });

    // If already exists → update
    if (progress) {
      progress.status = status;
      progress.attempts += 1;
      progress.lastSeenAt = new Date();
      await progress.save();

      return res.status(200).json({
        success: true,
        message: "Progress updated",
      });
    }

    // First time user sees this question
    await UserQuestionProgress.create({
      userId,
      questionId,
      status,
    });

    return res.status(201).json({
      success: true,
      message: "Progress created",
    });
  } catch (e) {
    console.error(e);
    return res.status(500).json({
      success: false,
      message: "Internal server error",
    });
  }
};


export const getNextQuestion = async (req, res) => {
  try {
    const { userId, domain, subDomainId } = req.body;

    console.log("\n================ GET NEXT QUESTION ================");
    console.log("RAW BODY:", req.body);

    if (!userId || !domain || !subDomainId) {
      console.log("❌ Missing required fields");
      return res.status(400).json({
        success: false,
        message: "userId, domain and subDomainId are required",
      });
    }

    const normalizedDomain = domain.trim().toLowerCase();
    console.log("normalizedDomain:", normalizedDomain);
    console.log("subDomainId (as received):", subDomainId);

    // 1️⃣ Get all progress records for user
    const progress = await UserQuestionProgress.find({
      userId,
    }).select("questionId status");

    console.log("progress length:", progress.length);
    console.log("progress data:", progress);

    const knownIds = new Set();
    const dontKnowIds = [];
    const reviewIds = [];

    for (const p of progress) {
      if (p.status === "known") knownIds.add(p.questionId); // ❗ DO NOT toString
      if (p.status === "dont_know") dontKnowIds.push(p.questionId);
      if (p.status === "review") reviewIds.push(p.questionId);
    }

    console.log("knownIds:", Array.from(knownIds));
    console.log("dontKnowIds:", dontKnowIds);
    console.log("reviewIds:", reviewIds);

    // 🔍 BASE CHECK: do questions even exist?
    const baseCount = await Question.countDocuments({
      domain: normalizedDomain,
      subDomainId,
      isActive: true,
    });

    console.log("BASE QUESTION COUNT:", baseCount);

    // 2️⃣ Priority 1: dont_know
    let question = await Question.findOne({
      _id: { $in: dontKnowIds },
      subDomainId,
      isActive: true,
    });

    console.log("dont_know question:", question?._id || null);

    if (question) {
      return res.status(200).json({
        success: true,
        question,
      });
    }

    // 3️⃣ Priority 2: review
    question = await Question.findOne({
      _id: { $in: reviewIds },
      subDomainId,
      isActive: true,
    });

    console.log("review question:", question?._id || null);

    if (question) {
      return res.status(200).json({
        success: true,
        question,
      });
    }

    // 4️⃣ Priority 3: unseen questions
    const unseenCount = await Question.countDocuments({
      subDomainId,
      isActive: true,
      _id: { $nin: Array.from(knownIds) },
    });

    console.log("UNSEEN COUNT:", unseenCount);

    question = await Question.findOne({
      subDomainId,
      isActive: true,
      _id: { $nin: Array.from(knownIds) },
    });

    console.log("FINAL QUESTION:", question?._id || null);

    if (!question) {
      console.log("❌ No more questions left");
      return res.status(200).json({
        success: true,
        message: "No more questions left",
      });
    }

    return res.status(200).json({
      success: true,
      question,
    });
  } catch (e) {
    console.error("🔥 ERROR:", e);
    return res.status(500).json({
      success: false,
      message: "Internal server error",
    });
  }
};
