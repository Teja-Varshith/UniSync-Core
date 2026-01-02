import { Domain } from "../models/domains.js";
import { Question } from "../models/questions.js";
import mongoose from "mongoose";

export const createQuestions = async (req, res) => {
  try {
    const { domain, subDomainId, questions } = req.body;
    if (
      !domain ||
      !subDomainId ||
      !Array.isArray(questions) ||
      questions.length === 0
    ) {
      return res.status(400).json({
        success: false,
        message: "domain, subDomainId and non-empty questions array required",
      });
    }

    if (!mongoose.Types.ObjectId.isValid(subDomainId)) {
      return res.status(400).json({
        success: false,
        message: "Invalid subDomainId",
      });
    }

    const normalizedDomain = domain.trim().toLowerCase();


    const domainDoc = await Domain.findOne({ domain: normalizedDomain });

    if (!domainDoc) {
      return res.status(404).json({
        success: false,
        message: "Domain not found",
      });
    }


    const subDomainExists = domainDoc.subDomains.some(
      (sd) => sd._id.toString() === subDomainId
    );

    if (!subDomainExists) {
      return res.status(404).json({
        success: false,
        message: "SubDomain not found in this domain",
      });
    }


    const preparedQuestions = [];

    for (const q of questions) {
      if (!q.question || !q.answer) {
        return res.status(400).json({
          success: false,
          message: "Each question must have question and answer",
        });
      }

      if (
        q.difficulty &&
        !["easy", "medium", "hard"].includes(q.difficulty)
      ) {
        return res.status(400).json({
          success: false,
          message: "Invalid difficulty value",
        });
      }

      preparedQuestions.push({
        domain: normalizedDomain,
        subDomainId,
        question: q.question.trim(),
        answer: q.answer.trim(),
        difficulty: q.difficulty || "medium",
        tags: Array.isArray(q.tags)
          ? q.tags.map((t) => t.toLowerCase().trim())
          : [],
      });
    }


    const inserted = await Question.insertMany(preparedQuestions, {
      ordered: true, // strict: fail on first error
    });

    return res.status(201).json({
      success: true,
      inserted: inserted.length,
    });
  } catch (e) {

    if (e.code === 11000) {
      return res.status(409).json({
        success: false,
        message: "Duplicate question exists in this domain",
      });
    }

    console.error(e);
    return res.status(500).json({
      success: false,
      message: "Internal server error",
    });
  }
};
