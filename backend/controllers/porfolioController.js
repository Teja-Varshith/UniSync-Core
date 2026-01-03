import { Document } from "../models/document.js";
import { portAi } from "../services/ai.js";
import { savePortfolioFiles } from "../utils/savePortifolio.js";

export const generatePortfolioController = async (req, res) => {
  try {
    const { userId } = req.body;

    const document = await Document.findOne({ UserId: userId });
    if (!document) {
      return res.status(404).json({
        success: false,
        message: "document not found",
      });
    }

    // 1️⃣ Generate JSON (html, css, js)
    const files = await portAi.generatePortfolio(document.extractedText);

    // 2️⃣ Save files to disk
    await savePortfolioFiles(userId, files);

    // 3️⃣ Respond with portfolio URL
    return res.status(200).json({
      success: true,
      message: "Portfolio generated successfully",
      url: `/portfolio/${userId}`,
    });
  } catch (error) {
    console.error("error generating portfolio:", error);
    return res.status(500).json({
      success: false,
      message: "error while generating portfolio",
    });
  }
};
