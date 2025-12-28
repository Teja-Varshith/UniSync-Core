export class InterviewAIService {
  constructor(llmClient) {
    this.llm = llmClient;
  }

  async buildSystemPrompt(templateSnapshot, userProfile = {}) {
    console.log("called buildSystemPromt");
    return `
You are a professional technical interviewer.

Domain: ${templateSnapshot.domain}
Target Company: ${templateSnapshot.targetCompany}
Evaluation Metrics: ${templateSnapshot.evaluationMetrics}

}

Ask clear, concise interview questions.
Ask follow-up questions if answers are shallow.
also start the interview by greeting the candidate and asking for the introduction.
`;
  }

  async generateQuestion(exchange) {
   try{
     console.log("called generateQuestion");
    const prompt = `
${exchange.systemPrompt}

Questions asked so far: ${exchange.meta.questionsAsked} , ${exchange.questions
      .map((q) => q.text)
      .join(" | ")} and their answers given by user: ${exchange.answers
      .map((a) => a.transcript)
      .join(" | ")}

Ask the next interview question.
Return ONLY the question text.
`;

    const response = await this.llm.generate(prompt);
    console.log("Generated question");

    return response;
   } catch (err){
    console.log("Error in generateQuestion:", err);
    throw err;
   }
  }

  async evaluateAnswer(exchange, answerTranscript) {
    const prompt = `
${exchange.systemPrompt}

Question:
${exchange.currentQuestion.text}

Candidate Answer:
${answerTranscript}

Evaluate the answer.
and just return the text for the next qsn in natural langugae like if followup is required you can ask like great can you go deeper on this and expain this that ih so as you touched this let me ask you one more thing like that
and if its the user first qsn then go through then greet the user and ask the furst qsn
`;

    const response = await this.llm.generate(prompt);
    return JSON.parse(response.text);
  }

  async generateFinalReport(exchange) {
    try{
      console.log("genratefinalReport is called");
    const prompt = `
You are an interview evaluation engine.

STRICT RULES:
- Return ONLY valid JSON
- No markdown
- No explanations
- No extra text
- Numbers must be between 0 and 100

JSON SCHEMA:
{
  "overallScore": number,
  "skillBreakdown": {
    "technical": number,
    "problemSolving": number,
    "communication": number,
    "confidence": number
  },
  "strengths": string[],
  "weaknesses": string[],
  "improvementPlan": {
    "area": string,
    "suggestion": string
  }[],
  "summary": string
}

Interview Data:
Questions: ${exchange.questions.map(q => q.text).join(" | ")}
Answers: ${exchange.answers.map(a => a.transcript).join(" | ")}

Return ONLY the JSON object.
`;

 const response = await this.llm.generate(prompt);
    console.log("report generated");

    return response;




}catch(err){
  console.log("error found in genratefinalReport", + err);
  throw(err);
}
  }

  async generateOutro(exchange) {
   try{
     console.log("generateOutro called");
    const prompt = `
You are concluding a technical interview.

Thank the candidate for their time.
Give a short, professional closing message.
Do NOT ask any questions.
Do NOT mention scores or results.
Keep it under 2 sentences.

Return ONLY the outro text.
Context:
Questions: ${exchange.questions.map(q => q.text).join(" | ")}
Answers: ${exchange.answers.map(a => a.transcript).join(" | ")}

`;

    const response = await this.llm.generate(prompt);
    return response;
  }catch(e){
    console.log("generateoutro er", + e);
    throw(e);
  }
  }
}
