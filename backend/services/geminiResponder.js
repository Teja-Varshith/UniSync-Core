// import {GoogleGenAI} from '@google/genai';
// const GEMINI_API_KEY = process.env.GEMINI_API_KEY;

// const ai = new GoogleGenAI({apiKey: GEMINI_API_KEY});


// export class GeminiResponder {
//   GeminiResponder() {};

//   async generate(qsn) { 
//   const response = await ai.models.generateContent({
//     model: 'gemini-2.5-flash',
//     contents: qsn,
//   });
//   return response.candidates[0].content.parts[0].text;

// }

// }

export class OllamaResponder {
  constructor(model = "llama3.1:8b") {
    this.model = model;
    this.baseUrl = "http://localhost:11434/api/generate";
  }

  async generate(prompt) {
    const response = await fetch(this.baseUrl, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        model: this.model,
        prompt,
        stream: false,
      }),
    });

    if (!response.ok) {
      const err = await response.text();
      throw new Error(`Ollama error: ${err}`);
    }

    const data = await response.json();
    console.log("sending response from the llammaaa");
    return data.response;
  }
}
