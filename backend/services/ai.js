// import { GeminiResponder } from "./geminiResponder.js";
import { InterviewAIService } from "./interviewAiService.js";
import { OllamaResponder } from "./geminiResponder.js";


// const gemini = new GeminiResponder();
// export const ai = new InterviewAIService(gemini);

const ollama = new OllamaResponder();
export const ai = new InterviewAIService(ollama);