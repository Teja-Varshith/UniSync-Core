import {GoogleGenAI} from '@google/genai';
const GEMINI_API_KEY = process.env.GEMINI_API_KEY;

const ai = new GoogleGenAI({apiKey: GEMINI_API_KEY});


export class GeminiResponder {
  GeminiResponder() {};

  async generate(qsn) { 
  const response = await ai.models.generateContent({
    model: 'gemini-2.5-flash',
    contents: qsn,
  });
  return response.candidates[0].content.parts[0].text;

}

}

