import { portAi } from "../services/ai.js";
import { savePortfolioFiles } from "../utils/savePortifolio.js";

export const generatePortfolioFromTextController = async (req, res) => {
  try {
    const { userId, resumeText, slug } = req.body;

    if (!userId || !resumeText || !slug) {
      return res.status(400).json({
        success: false,
        message: "userId, resumeText, and slug are required",
      });
    }

    // 1️⃣ Generate a single complete HTML page
    const html = await portAi.generateSinglePagePortfolio(resumeText);

    // 2️⃣ Save to disk at portfolios/{slug}/index.html
    await savePortfolioFiles(slug, { html });

    // 3️⃣ Respond
    return res.status(200).json({
      success: true,
      message: "Portfolio generated successfully",
      url: `/me/${slug}`,
    });
  } catch (error) {
    console.error("error generating portfolio from text:", error);
    return res.status(500).json({
      success: false,
      message: "error while generating portfolio",
    });
  }
};
