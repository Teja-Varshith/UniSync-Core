import fs from "fs/promises";
import path from "path";

/**
 * Save portfolio files to disk.
 * 
 * For single-page: pass { html } — saves only index.html
 * For multi-file: pass { html, css, javascript } — saves all three
 */
export const savePortfolioFiles = async (folderName, files) => {
  const baseDir = path.join(process.cwd(), "portfolios", folderName);

  // create /portfolios/<folderName>
  await fs.mkdir(baseDir, { recursive: true });

  // Always save index.html
  await fs.writeFile(
    path.join(baseDir, "index.html"),
    files.html,
    "utf-8"
  );

  // Optional: save separate CSS
  if (files.css) {
    await fs.writeFile(
      path.join(baseDir, "style.css"),
      files.css,
      "utf-8"
    );
  }

  // Optional: save separate JS
  if (files.javascript) {
    await fs.writeFile(
      path.join(baseDir, "script.js"),
      files.javascript,
      "utf-8"
    );
  }

  return baseDir;
};
