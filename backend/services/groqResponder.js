export class GroqResponder {
  constructor({
    // model = "llama-3.1-8b-instant",
    model = "GPT OSS 20B",
    apiKey = process.env.GROQ_API_KEY || process.env.GROK_API_KEY,
    baseUrl = "https://api.groq.com/openai/v1/chat/completions",
  } = {}) {
    this.model = model;
    this.baseUrl = baseUrl;
    this.currentKeyIndex = 0;

    this.apiKeys = this._collectApiKeys(apiKey);
  }

  _collectApiKeys(primaryApiKey) {
    const multiFromEnv = String(process.env.GROQ_API_KEYS || "")
      .split(/[;,\n]/)
      .map((k) => k.trim())
      .filter(Boolean);

    const ordered = [
      ...(primaryApiKey ? [String(primaryApiKey).trim()] : []),
      ...multiFromEnv,
      ...(process.env.GROQ_API_KEY ? [String(process.env.GROQ_API_KEY).trim()] : []),
      ...(process.env.GROK_API_KEY ? [String(process.env.GROK_API_KEY).trim()] : []),
    ].filter(Boolean);

    return [...new Set(ordered)];
  }

  _shouldRotateKey(statusCode, errorText) {
    if ([401, 403, 429].includes(statusCode)) {
      return true;
    }

    const normalized = String(errorText || "").toLowerCase();
    return (
      normalized.includes("quota") ||
      normalized.includes("rate limit") ||
      normalized.includes("too many requests") ||
      normalized.includes("insufficient") ||
      normalized.includes("exceeded") ||
      normalized.includes("credits")
    );
  }

  async _callWithKey(prompt, apiKey) {
    const response = await fetch(this.baseUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        model: this.model,
        messages: [
          {
            role: "user",
            content: prompt,
          },
        ],
        temperature: 0.7,
      }),
    });

    if (!response.ok) {
      const errText = await response.text();
      const error = new Error(`Groq error (${response.status}): ${errText}`);
      error.statusCode = response.status;
      error.rawBody = errText;
      throw error;
    }

    const data = await response.json();
    const text = data?.choices?.[0]?.message?.content;

    if (!text || typeof text !== "string") {
      throw new Error("Groq returned an empty response.");
    }

    return text;
  }

  async generate(prompt) {
    if (this.apiKeys.length === 0) {
      throw new Error(
        "Groq API key is missing. Set GROQ_API_KEY or GROQ_API_KEYS in environment."
      );
    }

    let lastError;
    const totalKeys = this.apiKeys.length;

    for (let attempt = 0; attempt < totalKeys; attempt++) {
      const keyIndex = (this.currentKeyIndex + attempt) % totalKeys;
      const key = this.apiKeys[keyIndex];

      try {
        const text = await this._callWithKey(prompt, key);
        this.currentKeyIndex = keyIndex;
        return text;
      } catch (error) {
        lastError = error;

        const rotate = this._shouldRotateKey(error.statusCode, error.rawBody || error.message);
        const isLastAttempt = attempt === totalKeys - 1;

        if (!rotate || isLastAttempt) {
          break;
        }
      }
    }

    throw lastError || new Error("Groq request failed.");
  }
}