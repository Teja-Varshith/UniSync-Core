import { InterviewSession } from "../models/interviewsession.js";

export const reportControllers = async (req, res) => {
  try {
    const { userId, templateId } = req.body;

    if (!userId || !templateId) {
      return res.status(400).json({
        success: false,
        message: "userId and templateId are required",
      });
    }

    const sessions = await InterviewSession.find({
      userId,
      templateId,
    })
      .sort({ createdAt: -1 })
      .lean();

    if (sessions.length === 0) {
      return res.status(200).json({
        success: true,
        message: "No interview sessions found",
        data: [],
        count: 0,
      });
    }

    return res.status(200).json({
      success: true,
      data: sessions,
      count: sessions.length,
    });

  } catch (error) {
    console.error("Error loading interview sessions:", error);
    return res.status(500).json({
      success: false,
      message: "Internal server error",
    });
  }
};
