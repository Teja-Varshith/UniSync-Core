// import { GeminiResponder } from "./geminiResponder.js";
import { InterviewAIService } from "./interviewAiService.js";
import { OllamaResponder } from "./geminiResponder.js";
import { PortfolioService } from "./portifolioServices.js";

// const gemini = new GeminiResponder();
// export const ai = new InterviewAIService(gemini);

const ollama = new OllamaResponder();
export const ai = new InterviewAIService(ollama);
export const portAi = new PortfolioService(ollama);