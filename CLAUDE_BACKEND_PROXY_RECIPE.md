# Backend Proxy — 30 行代碼把 OpenAI key 從 client 拔出來

> 目的：解決硬編碼 API key 安全問題
> 推薦：**Cloudflare Workers**（免費額度 100k req/天、部署 5 分鐘、不需信用卡）
> 備案：Firebase Cloud Functions（如果你已在用 Firebase）
> 完整部署時間：**30 分鐘上線**

---

## 為什麼必須做這件事

```
現況（壞）：
  iPhone App ──[硬編碼 sk-xxx]──> OpenAI API

問題：
  - 任何人解包 IPA → 拿到你的 key
  - 別人用你的 key 燒額度
  - OpenAI 風控可能直接停權你的帳號
  - 無法做 per-user 額度管理
  - 無法做免費試用控制

正解（好）：
  iPhone App ──[user_id]──> 你的 Worker ──[sk-xxx]──> OpenAI API
                              ↓
                          [檢查訂閱、計次]
```

---

## 方案 A — Cloudflare Workers（強烈推薦）

### 為什麼 Cloudflare

| 維度 | Cloudflare Workers | Firebase Cloud Functions |
|---|---|---|
| 免費額度 | **10 萬 req/天**（夠你前 3 個月用） | 200 萬 req/月（但需綁信用卡） |
| 冷啟動 | **0ms**（V8 isolate） | 1-3 秒 |
| 部署 | `wrangler deploy` 一行 | `firebase deploy` 但要設定多 |
| Region | 全球 200+ 節點 | 預設 US-Central |
| 適合 | 新手 + 不想被綁 Google 生態 | 已用 Firebase 其他服務 |

---

## Step 1 — 註冊 Cloudflare + 安裝 wrangler

```bash
# 1. 註冊 (免費): https://dash.cloudflare.com/sign-up
# 2. 安裝 wrangler
npm install -g wrangler

# 3. 登入
wrangler login
```

---

## Step 2 — 建立 Worker 專案

```bash
# 在 D:\ 或任何位置
npm create cloudflare@latest lovekey-proxy
# 選擇:
#   - Hello World Worker
#   - TypeScript
#   - No git
#   - No deploy

cd lovekey-proxy
```

---

## Step 3 — 寫 Worker 代碼（30 行核心邏輯）

**檔案：`src/index.ts`**

```typescript
export interface Env {
  OPENAI_API_KEY: string;        // 從 wrangler secret 拿
  KV_USAGE: KVNamespace;          // Cloudflare KV，存 user 用量
}

export default {
  async fetch(req: Request, env: Env): Promise<Response> {
    if (req.method !== "POST") return new Response("Use POST", { status: 405 });

    // 1. 解析 client 請求
    const { user_id, message, tone, mode, is_pro } = await req.json<any>();
    if (!user_id || !message) return json({ error: "missing fields" }, 400);

    // 2. 額度檢查（免費用戶每日 3 次）
    if (!is_pro) {
      const today = new Date().toISOString().slice(0, 10);
      const key = `usage:${user_id}:${today}`;
      const count = parseInt(await env.KV_USAGE.get(key) || "0");
      if (count >= 3) return json({ error: "quota_exceeded", upgrade: true }, 429);
      await env.KV_USAGE.put(key, String(count + 1), { expirationTtl: 86400 });
    }

    // 3. 呼叫 OpenAI
    const prompt = buildPrompt(message, tone, mode);
    const r = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${env.OPENAI_API_KEY}`,
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        model: "gpt-4o-mini",  // 便宜模型，1M token 約 $0.15
        messages: [{ role: "user", content: prompt }],
        max_tokens: 100,
        temperature: 0.8
      })
    });

    if (!r.ok) return json({ error: "ai_failed" }, 500);
    const data = await r.json<any>();
    const reply = data.choices[0].message.content.trim();
    return json({ reply });
  }
};

function json(obj: any, status = 200) {
  return new Response(JSON.stringify(obj), {
    status,
    headers: { "Content-Type": "application/json" }
  });
}

function buildPrompt(message: string, tone: string, mode: string): string {
  return `你是戀愛聊天助手「戀語」。對方訊息：「${message}」。請用「${tone}」語氣，在「${mode}」情境下，給一句 ≤30 字的回覆，繁體中文，直接給回覆，不要解釋。`;
}
```

---

## Step 4 — 設定 KV + 環境變數

```bash
# 1. 建立 KV namespace（存 usage）
wrangler kv:namespace create KV_USAGE
# 把回傳的 id 貼到 wrangler.toml

# 2. 設定 OpenAI key 為 secret（不會進 git）
wrangler secret put OPENAI_API_KEY
# 貼上你的 sk-xxx
```

**`wrangler.toml`** 範例：

```toml
name = "lovekey-proxy"
main = "src/index.ts"
compatibility_date = "2026-05-01"

[[kv_namespaces]]
binding = "KV_USAGE"
id = "貼上剛剛的 id"
```

---

## Step 5 — 部署（30 秒）

```bash
wrangler deploy

# 回傳：
# Published lovekey-proxy
# https://lovekey-proxy.YOUR-SUBDOMAIN.workers.dev
```

**就這樣**，proxy 上線了。

---

## Step 6 — 改 iOS Swift 端

**舊代碼（壞）**：

```swift
// KeyboardViewController.swift
let openaiKey = "sk-proj-xxxxxxxxxx"  // ❌ 硬編碼
let url = URL(string: "https://api.openai.com/v1/chat/completions")!
```

**新代碼（好）**：

```swift
// KeyboardViewController.swift
struct AIReplyService {
    static let proxyUrl = "https://lovekey-proxy.YOUR-SUBDOMAIN.workers.dev"

    static func generate(message: String, tone: String, mode: String, isPro: Bool, userId: String) async throws -> String {
        var req = URLRequest(url: URL(string: proxyUrl)!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: [
            "user_id": userId,
            "message": message,
            "tone": tone,
            "mode": mode,
            "is_pro": isPro
        ])

        let (data, _) = try await URLSession.shared.data(for: req)
        let result = try JSONDecoder().decode([String: String].self, from: data)
        guard let reply = result["reply"] else { throw NSError(domain: "AI", code: 1) }
        return reply
    }
}
```

**完全不再有 OpenAI key**。

---

## Step 7 — 改 Flutter Dart 端

```dart
// lib/services/ai_reply_service.dart
class AIReplyService {
  static const _proxyUrl = 'https://lovekey-proxy.YOUR-SUBDOMAIN.workers.dev';

  static Future<String> generate({
    required String userId,
    required String message,
    required String tone,
    required String mode,
    required bool isPro,
  }) async {
    final res = await http.post(
      Uri.parse(_proxyUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'message': message,
        'tone': tone,
        'mode': mode,
        'is_pro': isPro,
      }),
    );

    if (res.statusCode == 429) {
      throw QuotaExceededException();
    }
    if (res.statusCode != 200) {
      throw AIServiceException();
    }

    return jsonDecode(res.body)['reply'];
  }
}

class QuotaExceededException implements Exception {}
class AIServiceException implements Exception {}
```

---

## Step 8 — 把所有硬編碼 key 刪掉

```bash
# 在 ai_love_keyboard 根目錄
grep -r "sk-proj" lib/ ios/ android/
grep -r "sk-svca" lib/ ios/ android/
grep -r "OPENAI" lib/ ios/ android/ | grep -v _deprecated

# 找到的每個位置都刪
# 確認後 commit
```

---

## 成本估算

| 用量 | Cloudflare Worker | OpenAI gpt-4o-mini |
|---|---|---|
| 1,000 req/day | $0（免費額度內） | ~$0.15/天（$4.5/月） |
| 10,000 req/day | $0（仍在 10 萬/天免費內） | ~$1.5/天（$45/月） |
| 100,000 req/day | ~$5/月（超過免費需付） | ~$15/天（$450/月） |

**結論**：
- 1 萬日活前：proxy 完全免費，OpenAI 月 $45
- 10 萬日活：proxy 月 $5，OpenAI 月 $450
- 訂閱 $9.99/月 × 1000 付費用戶 = $9,990/月收入，遠超成本

---

## 進階：加 Streaming（讓 AI 回覆流式出現）

**Worker 端改動**：

```typescript
// 把 OpenAI 呼叫改成 stream: true
body: JSON.stringify({
  model: "gpt-4o-mini",
  messages: [{ role: "user", content: prompt }],
  stream: true   // ← 加這個
})

// 然後 return Response 用 stream:
return new Response(r.body, {
  headers: {
    "Content-Type": "text/event-stream",
    "Cache-Control": "no-cache"
  }
});
```

**iOS 端**用 `URLSession.bytes(for:)` 處理 SSE。
**Flutter 端**用 `http.Client.send()` + Stream<List<int>> 處理。

詳細實作見規格 v1.1 第 9.3 節。

---

## 方案 B — Firebase Cloud Functions（如果已用 Firebase）

如果你已經接 Firebase Analytics / Crashlytics，可以省一個服務。

```bash
# 安裝
npm install -g firebase-tools
firebase init functions  # 選 TypeScript

# 寫一樣的邏輯在 functions/src/index.ts
# 設定 OpenAI key:
firebase functions:secrets:set OPENAI_API_KEY

# 部署
firebase deploy --only functions
```

代碼結構幾乎一樣，只是 entry point 改：

```typescript
import * as functions from "firebase-functions";
import { defineSecret } from "firebase-functions/params";

const openaiKey = defineSecret("OPENAI_API_KEY");

export const generateReply = functions
  .runWith({ secrets: [openaiKey] })
  .https.onRequest(async (req, res) => {
    // ... 同上邏輯
  });
```

**缺點**：冷啟動 1-3 秒（鍵盤體驗有感）、必須綁信用卡

---

## 紅線提醒

| ❌ 千萬不要 | ✅ 該做 |
|---|---|
| 把 OpenAI key 寫進 client | 全部走 proxy |
| 用 `localStorage` / `SharedPreferences` 存 key | KV / Secret Manager |
| 沒 user 識別就免費發 | 用 IDFV / firebase uid 計次 |
| 信任 client 傳的 `is_pro: true` | 從 RevenueCat webhook 驗證 |
| 用 gpt-4 | 用 gpt-4o-mini（便宜 30x，效果夠） |

---

## 30 分鐘部署 Checklist

- [ ] 1. 註冊 Cloudflare（免費）
- [ ] 2. `npm install -g wrangler && wrangler login`
- [ ] 3. `npm create cloudflare@latest lovekey-proxy`
- [ ] 4. 把 `src/index.ts` 換成上面的代碼
- [ ] 5. `wrangler kv:namespace create KV_USAGE` 並貼 id 到 wrangler.toml
- [ ] 6. `wrangler secret put OPENAI_API_KEY`
- [ ] 7. `wrangler deploy`
- [ ] 8. 改 `KeyboardViewController.swift` 用新 proxyUrl
- [ ] 9. 改 `lib/services/ai_reply_service.dart` 用新 proxyUrl
- [ ] 10. `grep -r "sk-" lib/ ios/` 確認沒有殘留
- [ ] 11. 推 TestFlight build 測試
- [ ] 12. 確認 paywall 額度檢查正常

**完成 = 安全合規 + 可上架**
