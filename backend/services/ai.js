// import { GeminiResponder } from "./geminiResponder.js";
import { InterviewAIService } from "./interviewAiService.js";
import { GroqResponder } from "./groqResponder.js";
import { PortfolioService } from "./portifolioServices.js";

// const gemini = new GeminiResponder();
// export const ai = new InterviewAIService(gemini);

const groq = new GroqResponder();
export const ai = new InterviewAIService(groq);
export const portAi = new PortfolioService(groq);