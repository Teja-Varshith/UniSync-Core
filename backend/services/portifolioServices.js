export class PortfolioService {
  constructor(llmClient) {
    this.llm = llmClient;
  }

  async generatePortfolio(resumeContent) {
    try {
      // 1️⃣ Generate HTML
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

      // 2️⃣ Generate CSS with HTML context
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

      // 3️⃣ Generate JS with HTML + CSS context
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

      // 4️⃣ Final deterministic output
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
