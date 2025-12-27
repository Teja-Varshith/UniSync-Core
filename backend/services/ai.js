import { GeminiResponder } from "./geminiResponder.js";
import { InterviewAIService } from "./interviewAiService.js";


const gemini = new GeminiResponder();
export const ai = new InterviewAIService(gemini);