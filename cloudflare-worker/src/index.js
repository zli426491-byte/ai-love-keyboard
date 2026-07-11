import { DurableObject } from "cloudflare:workers";

const CORS_HEADERS = {
  // Native apps do not need CORS; only the public web preview is allowed.
  "Access-Control-Allow-Origin": "https://zli426491-byte.github.io",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers":
    "Content-Type, X-Device-Fingerprint, X-Request-Timestamp, X-Request-Nonce, X-Request-Signature",
};

const MAX_BODY_BYTES = 32 * 1024;
const MAX_MESSAGE_LENGTH = 2000;
const MAX_SYSTEM_PROMPT_LENGTH = 6000;
const MAX_IDENTIFIER_LENGTH = 128;
const OPENAI_TIMEOUT_MS = 20000;
const REVENUECAT_TIMEOUT_MS = 5000;

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

    const declaredLength = Number(request.headers.get("Content-Length") || 0);
    if (declaredLength > MAX_BODY_BYTES) {
      return json({ error: "request_too_large" }, 413);
    }

    const url = new URL(request.url);
    let body;
    try {
      body = await request.json();
    } catch {
      return json({ error: "invalid_json" }, 400);
    }

    if (!body || typeof body !== "object" || Array.isArray(body)) {
      return json({ error: "invalid_body" }, 400);
    }
    if (new TextEncoder().encode(JSON.stringify(body)).byteLength > MAX_BODY_BYTES) {
      return json({ error: "request_too_large" }, 413);
    }
    const validationError = validateBody(body);
    if (validationError) return json({ error: validationError }, 400);

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
  const message = redactPii(boundedString(body.message, MAX_MESSAGE_LENGTH));
  if (!message) return json({ error: "missing_message" }, 400);

  const userId = boundedIdentifier(body.user_id) || deviceId(request);
  const isPro = await resolveProAccess(body, env);
  const usage = await checkUsage(env, request, userId, isPro);
  if (usage.unavailable) return json({ error: "server_not_configured" }, 503);
  if (!usage.ok) {
    return json(
      usage.reason === "rate"
        ? { error: "rate_limited", retry_after: usage.retryAfter }
        : { error: "quota_exceeded", upgrade: true },
      429,
    );
  }

  const tone = boundedString(body.tone, 64) || "自然";
  const mode = boundedString(body.mode, 64) || "接話";
  const instruction = boundedString(body.instruction, 500);
  const systemPrompt =
    boundedString(body.system_prompt, MAX_SYSTEM_PROMPT_LENGTH) ||
    buildKeyboardSystemPrompt(tone, mode, instruction);

  const content = await callOpenAI(env, {
    model: env.OPENAI_MODEL_LIGHT || "gpt-4o-mini",
    messages: [
      { role: "system", content: systemPrompt },
      { role: "user", content: message },
    ],
    response_format: { type: "json_object" },
    max_tokens: 180,
    temperature: 0.45,
  });

  const reply = parseReply(content);
  if (!reply) return json({ error: "empty_reply" }, 502);

  return json({
    reply,
    usage_remaining: usage.remaining,
  });
}

async function handleChatCompletion(body, request, env) {
  const systemPrompt = boundedString(body.system_prompt, MAX_SYSTEM_PROMPT_LENGTH);
  const userMessage = redactPii(boundedString(body.user_message, MAX_MESSAGE_LENGTH));
  if (!systemPrompt || !userMessage) {
    return json({ error: "missing_fields" }, 400);
  }

  const userId = boundedIdentifier(body.user_id) || deviceId(request);
  // Never trust the client-provided is_pro flag. Verify RevenueCat below.
  const isPro = await resolveProAccess(body, env);
  const usage = await checkUsage(env, request, userId, isPro);
  if (usage.unavailable) return json({ error: "server_not_configured" }, 503);
  if (!usage.ok) {
    return json(
      usage.reason === "rate"
        ? { error: "rate_limited", retry_after: usage.retryAfter }
        : { error: "quota_exceeded", upgrade: true },
      429,
    );
  }

  // Heavy models and large responses are paid-only server decisions.
  const useHeavy = isPro && body.use_heavy_model === true;
  const maxTokens = isPro
    ? clampNumber(body.max_tokens, 64, 1600, 1024)
    : clampNumber(body.max_tokens, 64, 600, 512);
  const content = await callOpenAI(env, {
    model: useHeavy
      ? env.OPENAI_MODEL_HEAVY || "gpt-4.1-mini"
      : env.OPENAI_MODEL_LIGHT || "gpt-4o-mini",
    messages: [
      { role: "system", content: systemPrompt },
      { role: "user", content: userMessage },
    ],
    response_format: safeResponseFormat(body.response_format),
    max_tokens: maxTokens,
    temperature: clampNumber(body.temperature, 0, 1.2, 0.8),
  });

  return json({
    choices: [
      {
        message: { content },
      },
    ],
    usage_remaining: usage.remaining,
  });
}

async function callOpenAI(env, payload) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), OPENAI_TIMEOUT_MS);
  try {
    const response = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${env.OPENAI_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(payload),
      signal: controller.signal,
    });

    if (!response.ok) {
      throw new Error(`openai_${response.status}`);
    }

    const data = await response.json();
    return String(data?.choices?.[0]?.message?.content || "").trim();
  } finally {
    clearTimeout(timeout);
  }
}

async function checkUsage(env, request, userId, isPro) {
  const ip = clean(request.headers.get("CF-Connecting-IP")) || "unknown-ip";
  const actor = boundedIdentifier(userId) || "anonymous";
  const minuteLimit = isPro
    ? clampNumber(env.PRO_REQUESTS_PER_MINUTE, 1, 120, 60)
    : clampNumber(env.REQUESTS_PER_MINUTE, 1, 120, 30);
  const dailyLimit = isPro
    ? clampNumber(env.PRO_DAILY_LIMIT, 1, 10000, 300)
    : clampNumber(env.FREE_DAILY_LIMIT, 1, 100, 3);

  // An IP-only burst limit prevents attackers from rotating arbitrary client IDs.
  const ipResult = await incrementUsage(env, `ip:${ip}`, null, clampNumber(
    env.IP_REQUESTS_PER_MINUTE,
    1,
    600,
    120,
  ));
  if (ipResult.unavailable) return ipResult;
  if (!ipResult.ok) return { ...ipResult, reason: "rate" };

  const actorResult = await incrementUsage(
    env,
    `actor:${actor}:${ip}`,
    dailyLimit,
    minuteLimit,
  );
  if (actorResult.unavailable) return actorResult;
  if (!actorResult.ok) {
    return {
      ...actorResult,
      reason: actorResult.dailyExceeded ? "quota" : "rate",
    };
  }

  return actorResult;
}

async function incrementUsage(env, key, dailyLimit, minuteLimit) {
  if (env.QUOTA_COUNTER) {
    try {
      const id = env.QUOTA_COUNTER.idFromName(key);
      const response = await env.QUOTA_COUNTER.get(id).fetch(
        "https://quota-counter/check",
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ key, dailyLimit, minuteLimit }),
        },
      );
      if (!response.ok) return { ok: false, unavailable: true, remaining: null };
      return await response.json();
    } catch {
      return { ok: false, unavailable: true, remaining: null };
    }
  }

  // Local fallback only. Production uses the atomic Durable Object above.
  if (!env.KV_USAGE) return { ok: false, unavailable: true, remaining: null };
  const minuteBucket = Math.floor(Date.now() / 60000);
  const day = new Date().toISOString().slice(0, 10);
  const minuteKey = `fallback:${key}:minute:${minuteBucket}`;
  const count = Number.parseInt((await env.KV_USAGE.get(minuteKey)) || "0", 10) || 0;
  if (count >= minuteLimit) {
    return {
      ok: false,
      retryAfter: 60 - (Math.floor(Date.now() / 1000) % 60),
      remaining: 0,
    };
  }

  const dayKey = `fallback:${key}:day:${day}`;
  const dayCount = Number.parseInt((await env.KV_USAGE.get(dayKey)) || "0", 10) || 0;
  if (dailyLimit !== null && dayCount >= dailyLimit) {
    return { ok: false, retryAfter: 0, remaining: 0, dailyExceeded: true };
  }

  await env.KV_USAGE.put(minuteKey, String(count + 1), { expirationTtl: 120 });
  if (dailyLimit !== null) {
    await env.KV_USAGE.put(dayKey, String(dayCount + 1), { expirationTtl: 172800 });
  }
  return {
    ok: true,
    remaining: dailyLimit === null ? null : Math.max(0, dailyLimit - dayCount - 1),
    retryAfter: 0,
    dailyExceeded: false,
  };
}

async function resolveProAccess(body, env) {
  const appUserId = boundedIdentifier(body.revenuecat_app_user_id);
  if (!appUserId || !env.REVENUECAT_SECRET_API_KEY) return false;

  const cacheKey = `entitlement:${appUserId}`;
  if (env.KV_USAGE) {
    const cached = await env.KV_USAGE.get(cacheKey);
    if (cached === "active") return true;
    if (cached === "inactive") return false;
  }

  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), REVENUECAT_TIMEOUT_MS);
    const response = await fetch(
      `https://api.revenuecat.com/v1/subscribers/${encodeURIComponent(appUserId)}`,
      {
        headers: {
          Authorization: `Bearer ${env.REVENUECAT_SECRET_API_KEY}`,
          Accept: "application/json",
        },
        signal: controller.signal,
      },
    );
    try {
      if (!response.ok) {
        if (env.KV_USAGE) {
          await env.KV_USAGE.put(cacheKey, "inactive", { expirationTtl: 60 });
        }
        return false;
      }

      const data = await response.json();
      const entitlement = data?.subscriber?.entitlements?.[
        env.REVENUECAT_ENTITLEMENT_ID || "pro"
      ];
      const expires = entitlement?.expires_date;
      const lifetime = expires === null || expires === undefined;
      const hasValidFutureExpiry =
        typeof expires === "string" &&
        !Number.isNaN(Date.parse(expires)) &&
        Date.parse(expires) > Date.now();
      const active = Boolean(entitlement && (lifetime || hasValidFutureExpiry));
      if (env.KV_USAGE) {
        await env.KV_USAGE.put(cacheKey, active ? "active" : "inactive", {
          expirationTtl: 60,
        });
      }
      return active;
    } finally {
      clearTimeout(timeout);
    }
  } catch {
    // Fail closed: an unavailable RevenueCat API must never unlock Pro.
    return false;
  }
}

function buildKeyboardSystemPrompt(tone, mode, instruction) {
  const extra = instruction ? `\n- User selected action: ${instruction}` : "";
  return `
You are LoveKey, an AI keyboard assistant for dating and everyday chat.
The user input is a message from the other person, not a question to you.
Return only a JSON object with one key "replies" and exactly one string item in an array.

Rules:
- Reply in the same language as the user's message. For Traditional Chinese, use natural Taiwan phrasing.
- First classify the situation: daily chat, tired/stressed, flirting, cold reply, logistics, food/date plan, conflict, joke/profanity, or unclear.
- Match the situation before applying the tone. If the other person is tired, comfort first. If they are joking, answer lightly. If they are angry, lower pressure and acknowledge.
- If the message means "隨便 / 你決定 / 都可以", do not say "驚喜". Choose a simple low-pressure next step instead.
- Keep it paste-ready: 1 short message, usually under 32 Chinese characters unless context needs one extra clause.
- Avoid generic phrases like "我懂你的意思", "高情商", "我會陪你", unless they clearly fit the exact message.
- Do not invent dates, places, relationship history, promises, restaurants, or plans that the user did not provide.
- Avoid exaggerated certainty such as "你一定會喜歡", "保證", "絕對", unless the user already said it.
- Prefer one natural next step or one easy question when it helps the conversation continue.
- Do not mention AI, model, prompt, template, analysis, or the app.
- Do not use pickup-artist wording, manipulation, guilt, pressure, explicit sexual content, insults, or fake intimacy.
- Do not add quotes, numbering, labels, or explanations.
- Tone: ${tone}
- Mode: ${mode}${extra}

Style examples to learn from, not copy blindly:
- "幹免費的喔" -> {"replies":["對啊，這麼好康我也想確認一下 😂"]}
- "我今天真的有點累" -> {"replies":["辛苦了，先休息一下，晚點再慢慢聊。"]}
- "隨便啦 你決定就好" -> {"replies":["那我來安排一個輕鬆的，你只要負責出現。"]}
- "哈哈哈" -> {"replies":["笑這麼開心，快說你剛剛想到什麼。"]}
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
  return boundedIdentifier(request.headers.get("X-Device-Fingerprint")) || "anonymous";
}

function clean(value) {
  return String(value ?? "").trim();
}

function boundedString(value, maxLength) {
  if (typeof value !== "string") return "";
  return value.trim().slice(0, maxLength);
}

function boundedIdentifier(value) {
  const identifier = boundedString(value, MAX_IDENTIFIER_LENGTH);
  return /^[A-Za-z0-9._:@=+$\-]+$/.test(identifier) ? identifier : "";
}

function redactPii(value) {
  return value
    .replace(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/gi, "[redacted-email]")
    .replace(/(?:\+?886[- .]?)?0?9\d{2}[- .]?\d{3}[- .]?\d{3}/g, "[redacted-phone]")
    .replace(/\b[A-Z][12]\d{8}\b/gi, "[redacted-id]");
}

function validateBody(body) {
  const stringFields = {
    user_id: MAX_IDENTIFIER_LENGTH,
    revenuecat_app_user_id: MAX_IDENTIFIER_LENGTH,
    message: MAX_MESSAGE_LENGTH,
    user_message: MAX_MESSAGE_LENGTH,
    system_prompt: MAX_SYSTEM_PROMPT_LENGTH,
    tone: 64,
    mode: 64,
    instruction: 500,
  };
  for (const [field, maxLength] of Object.entries(stringFields)) {
    if (
      body[field] !== undefined &&
      (typeof body[field] !== "string" || body[field].length > maxLength)
    ) {
      return `invalid_${field}`;
    }
  }
  if (body.is_pro !== undefined && typeof body.is_pro !== "boolean") {
    return "invalid_is_pro";
  }
  if (
    body.use_heavy_model !== undefined &&
    typeof body.use_heavy_model !== "boolean"
  ) {
    return "invalid_use_heavy_model";
  }
  return null;
}

function safeResponseFormat(value) {
  if (!value || typeof value !== "object" || Array.isArray(value)) return undefined;
  return value.type === "json_object" ? { type: "json_object" } : undefined;
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
      "Cache-Control": "no-store",
      ...CORS_HEADERS,
    },
  });
}

export class QuotaCounter extends DurableObject {
  constructor(ctx, env) {
    super(ctx, env);
    this.sql = ctx.storage.sql;
    this.sql.exec(`
      CREATE TABLE IF NOT EXISTS usage_counters (
        key TEXT PRIMARY KEY,
        minute_bucket INTEGER NOT NULL,
        minute_count INTEGER NOT NULL,
        day_bucket TEXT NOT NULL,
        day_count INTEGER NOT NULL
      )
    `);
  }

  async fetch(request) {
    if (request.method !== "POST") return new Response("method_not_allowed", { status: 405 });

    let body;
    try {
      body = await request.json();
    } catch {
      return new Response("invalid_json", { status: 400 });
    }

    const key = boundedString(body?.key, 256);
    const minuteLimit = clampNumber(body?.minuteLimit, 1, 600, 30);
    const dailyLimit =
      body?.dailyLimit === null || body?.dailyLimit === undefined
        ? null
        : clampNumber(body.dailyLimit, 1, 10000, 3);
    if (!key) return new Response("invalid_key", { status: 400 });

    const now = Math.floor(Date.now() / 1000);
    const minuteBucket = Math.floor(now / 60);
    const dayBucket = new Date(now * 1000).toISOString().slice(0, 10);
    const row = this.sql
      .exec(
        "SELECT minute_bucket, minute_count, day_bucket, day_count FROM usage_counters WHERE key = ?",
        key,
      )
      .toArray()[0];
    const minuteCount = row?.minute_bucket === minuteBucket ? Number(row.minute_count) : 0;
    const dayCount = row?.day_bucket === dayBucket ? Number(row.day_count) : 0;

    if (minuteCount >= minuteLimit) {
      return Response.json({
        ok: false,
        retryAfter: 60 - (now % 60),
        remaining: dailyLimit === null ? null : Math.max(0, dailyLimit - dayCount),
        dailyExceeded: false,
      });
    }
    if (dailyLimit !== null && dayCount >= dailyLimit) {
      return Response.json({
        ok: false,
        retryAfter: 0,
        remaining: 0,
        dailyExceeded: true,
      });
    }

    const nextDayCount = dayCount + (dailyLimit === null ? 0 : 1);
    this.sql.exec(
      `INSERT INTO usage_counters (key, minute_bucket, minute_count, day_bucket, day_count)
       VALUES (?, ?, 1, ?, ?)
       ON CONFLICT(key) DO UPDATE SET
         minute_bucket = excluded.minute_bucket,
         minute_count = excluded.minute_count,
         day_bucket = excluded.day_bucket,
         day_count = excluded.day_count`,
      key,
      minuteBucket,
      dayBucket,
      nextDayCount,
    );

    return Response.json({
      ok: true,
      retryAfter: 0,
      remaining: dailyLimit === null ? null : Math.max(0, dailyLimit - nextDayCount),
      dailyExceeded: false,
    });
  }
}
