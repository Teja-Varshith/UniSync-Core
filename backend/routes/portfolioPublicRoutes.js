import express from "express";
import path from "path";
import { Document } from "../models/document.js";

const router = express.Router();

router.get("/:slug", async (req, res) => {
  try {
    console.log("called");
    const { slug } = req.params;

    // 1️⃣ find user by username
    const doc = await Document.findOne({ slug : slug });
    if (!doc) {
      return res.status(404).send("Portfolio not found");
    }

    // 2️⃣ resolve portfolio path
    const portfolioPath = path.join(
      process.cwd(),
      "portfolios",
      doc.UserId.toString(),
      "index.html"
    );

    console.log(portfolioPath);

    // 3️⃣ send HTML
  return  res.redirect(`/portfolio/${doc.UserId}`);

   // return res.redirect(portfolioPath);
  } catch (err) {
    console.error(err);
    return res.status(500).send("Something broke");
  }
});

export default router;
