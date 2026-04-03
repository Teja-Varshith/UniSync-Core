export class PortfolioService {
  constructor(llmClient) {
    this.llm = llmClient;
  }

  /**
   * Generate a single, complete HTML page with inline CSS and JS
   * from the given resume text.
   */
  async generateSinglePagePortfolio(resumeContent) {
    const prompt = `
You are a world-class frontend engineer. Generate a SINGLE, COMPLETE HTML file for a modern, responsive portfolio website.

Rules:
- Output ONLY the raw HTML file content. Nothing else.
- Embed ALL CSS inside a <style> tag in <head>.
- Embed ALL JavaScript inside a <script> tag at the end of <body>.
- Use a modern, dark-themed design with clean typography.
- Make it fully responsive for mobile and desktop.
- Include sections: Hero/Header, About, Skills, Projects, Experience, Achievements, Certifications, Contact.
- Only include sections that have data in the resume.
- Use smooth scrolling and subtle animations.
- Do NOT use any external CDN links or frameworks.
- Do NOT explain anything.
- Do NOT wrap in markdown code fences.

RESUME CONTENT:
<<<
${resumeContent}
>>>
`;

    const html = (await this.llm.generate(prompt)).trim();

    // Strip markdown fences if the LLM wraps them
    return html
      .replace(/^```html?\s*/i, "")
      .replace(/```\s*$/i, "")
      .trim();
  }

  // Legacy: separate HTML/CSS/JS files (kept for backward compat)
  async generatePortfolio(resumeContent) {
    try {
      const htmlPrompt = `
You are a senior frontend engineer.

Generate ONLY valid HTML for a portfolio website.

Rules:
- Output ONLY raw HTML.
- No CSS.
- No JavaScript.
- Use semantic HTML.
- Link to style.css and script.js.
- Use ONLY the resume content.
- Do NOT explain anything.

RESUME:
<<<
${resumeContent}
>>>
`;

      const html = (await this.llm.generate(htmlPrompt)).trim();

      const cssPrompt = `
You are a senior frontend engineer.

Generate ONLY CSS for the following HTML.

Rules:
- Output ONLY CSS.
- No HTML.
- No JavaScript.
- Responsive using Flexbox or Grid.
- Clean, modern design.
- Do NOT invent content.

HTML:
<<<
${html}
>>>
`;

      const css = (await this.llm.generate(cssPrompt)).trim();

      const jsPrompt = `
You are a senior frontend engineer.

Generate ONLY JavaScript for the following website.

Rules:
- Output ONLY JavaScript.
- No HTML.
- No CSS.
- Minimal JS only (smooth scrolling, theme toggle).
- Query ONLY elements that exist in HTML.

HTML:
<<<
${html}
>>>

CSS:
<<<
${css}
>>>
`;

      const javascript = (await this.llm.generate(jsPrompt)).trim();

      return {
        html,
        css,
        javascript,
      };
    } catch (error) {
      console.error("Portfolio generation failed:", error);
      throw error;
    }
  }
}
