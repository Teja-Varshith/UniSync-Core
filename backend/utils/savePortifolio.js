import fs from "fs/promises";
import path from "path";

export const savePortfolioFiles = async (userId, files) => {
  const baseDir = path.join(process.cwd(), "portfolios", userId);

  // create /portfolios/<userId>
  await fs.mkdir(baseDir, { recursive: true });

  await fs.writeFile(
    path.join(baseDir, "index.html"),
    files.html,
    "utf-8"
  );

  await fs.writeFile(
    path.join(baseDir, "style.css"),
    files.css,
    "utf-8"
  );

  await fs.writeFile(
    path.join(baseDir, "script.js"),
    files.javascript,
    "utf-8"
  );

  return baseDir;
};
