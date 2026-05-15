const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, X-Device-Fingerprint",
};

export default {
  async fetch(request, env) {
    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: CORS_HEADERS });
    }

    if (request.method !== "POST") {
      return json({ error: "method_not_allowed" }, 405);
    }

    if (!env.OPENAI_API_KEY) {
      return json({ error: "server_not_configured" }, 500);
    }

    const url = new URL(request.url);
    let body;
    try {
      body = await request.json();
    } catch {
      return json({ error: "invalid_json" }, 400);
    }

    try {
      if (url.pathname === "/v1/keyboard-reply") {
        return await handleKeyboardReply(body, request, env);
      }

      if (url.pathname === "/v1/chat/completions") {
        return await handleChatCompletion(body, request, env);
      }
    } catch (error) {
      return json({ error: "ai_failed" }, 502);
    }

    return json({ error: "not_found" }, 404);
  },
};

async function handleKeyboardReply(body, request, env) {
  const message = clean(body.message);
  if (!message) return json({ error: "missing_message" }, 400);

  const userId = clean(body.user_id) || deviceId(request);
  const isPro = body.is_pro === true;
  const quota = await checkQuota(env, userId, isPro);
  if (!quota.ok) return json({ error: "quota_exceeded", upgrade: true }, 429);

  const tone = clean(body.tone) || "自然";
  const mode = clean(body.mode) || "接話";
  const instruction = clean(body.instruction);
  const systemPrompt = buildKeyboardSystemPrompt(tone, mode, instruction);

  const content = await callOpenAI(env, {
    model: env.OPENAI_MODEL_LIGHT || "gpt-4o-mini",
    messages: [
      { role: "system", content: systemPrompt },
      { role: "user", content: message },
    ],
    response_format: { type: "json_object" },
    max_tokens: 180,
    temperature: 0.72,
  });

  const reply = parseReply(content);
  if (!reply) return json({ error: "empty_reply" }, 502);

  return json({
    reply,
    usage_remaining: quota.remaining,
  });
}

async function handleChatCompletion(body, request, env) {
  const systemPrompt = clean(body.system_prompt);
  const userMessage = clean(body.user_message);
  if (!systemPrompt || !userMessage) {
    return json({ error: "missing_fields" }, 400);
  }

  const userId = clean(body.user_id) || deviceId(request);
  const isPro = body.is_pro !== false;
  const quota = await checkQuota(env, userId, isPro);
  if (!quota.ok) return json({ error: "quota_exceeded", upgrade: true }, 429);

  const useHeavy = body.use_heavy_model === true;
  const content = await callOpenAI(env, {
    model: useHeavy
      ? env.OPENAI_MODEL_HEAVY || "gpt-4.1-mini"
      : env.OPENAI_MODEL_LIGHT || "gpt-4o-mini",
    messages: [
      { role: "system", content: systemPrompt },
      { role: "user", content: userMessage },
    ],
    response_format: body.response_format || undefined,
    max_tokens: clampNumber(body.max_tokens, 64, 1600, 1024),
    temperature: clampNumber(body.temperature, 0, 1.2, 0.8),
  });

  return json({
    choices: [
      {
        message: { content },
      },
    ],
    usage_remaining: quota.remaining,
  });
}

async function callOpenAI(env, payload) {
  const response = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${env.OPENAI_API_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(payload),
  });

  if (!response.ok) {
    throw new Error(`openai_${response.status}`);
  }

  const data = await response.json();
  return String(data?.choices?.[0]?.message?.content || "").trim();
}

async function checkQuota(env, userId, isPro) {
  if (isPro || !env.KV_USAGE) return { ok: true, remaining: null };

  const limit = clampNumber(env.FREE_DAILY_LIMIT, 1, 100, 3);
  const day = new Date().toISOString().slice(0, 10);
  const key = `usage:${userId}:${day}`;
  const count = Number.parseInt((await env.KV_USAGE.get(key)) || "0", 10) || 0;
  if (count >= limit) return { ok: false, remaining: 0 };

  await env.KV_USAGE.put(key, String(count + 1), { expirationTtl: 86400 });
  return { ok: true, remaining: limit - count - 1 };
}

function buildKeyboardSystemPrompt(tone, mode, instruction) {
  const extra = instruction ? `\n- User selected action: ${instruction}` : "";
  return `
You are LoveKey, an AI keyboard assistant for dating and everyday chat.
The user input is a message from the other person, not a question to you.
Return only a JSON object with one key "replies" and exactly one string item in an array.

Rules:
- Write Traditional Chinese unless the user's message is clearly in another language.
- Match the other person's emotional state before flirting.
- Keep it natural, concise, and usable in chat.
- Do not mention AI, model, prompt, or analysis.
- Do not use pickup-artist wording.
- Do not add quotes or explanations.
- Tone: ${tone}
- Mode: ${mode}${extra}
`.trim();
}

function parseReply(content) {
  const text = clean(content);
  if (!text) return "";

  try {
    const parsed = JSON.parse(text);
    if (Array.isArray(parsed.replies)) return clean(parsed.replies[0]);
    if (typeof parsed.replies === "string") return clean(parsed.replies);
    if (typeof parsed.reply === "string") return clean(parsed.reply);
  } catch {
    return text;
  }

  return "";
}

function deviceId(request) {
  return request.headers.get("X-Device-Fingerprint") || "anonymous";
}

function clean(value) {
  return String(value ?? "").trim();
}

function clampNumber(value, min, max, fallback) {
  const number = Number(value);
  if (!Number.isFinite(number)) return fallback;
  return Math.min(max, Math.max(min, number));
}

function json(payload, status = 200) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: {
      "Content-Type": "application/json; charset=utf-8",
      ...CORS_HEADERS,
    },
  });
}
