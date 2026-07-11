# LoveKey Backend Proxy

Cloudflare Worker used to keep model API keys out of the iOS keyboard extension and Flutter app.

## Deploy

```bash
cd cloudflare-worker
npm install -g wrangler
wrangler login
wrangler kv:namespace create KV_USAGE
```

Copy the returned KV namespace id into `wrangler.toml`, then set the OpenAI key as a Cloudflare secret:

```bash
wrangler secret put OPENAI_API_KEY
wrangler secret put REVENUECAT_SECRET_API_KEY
wrangler deploy
```

After deploy, add the Worker URL to GitHub Actions as:

```text
AI_PROXY_URL=https://lovekey-proxy.<your-subdomain>.workers.dev
```

Do not put OpenAI API keys in the app, GitHub repo, or Xcode project.

## P0 abuse controls

Production uses the `QuotaCounter` Durable Object with SQLite storage for an
atomic per-IP burst limit and a per-actor daily/minute quota. The current
defaults are:

- Free: 3 requests/day and 30 requests/minute per actor/IP pair.
- Pro: 300 requests/day and 60 requests/minute per actor/IP pair.
- IP burst ceiling: 120 requests/minute across rotating client identifiers.

The Worker also caps request sizes, allow-lists `response_format`, times out
OpenAI (20 seconds) and RevenueCat (5 seconds), fails closed when RevenueCat
cannot verify Pro, and sends `Cache-Control: no-store` on API responses. The
KV path is only a local fallback; production deployments must keep the
`QUOTA_COUNTER` binding enabled so quota increments remain atomic.

These controls limit spend and credential abuse, but a client-provided device
fingerprint is not an identity proof. Before paid acquisition, add native
Apple App Attest and Android Play Integrity verification at the Worker (P1),
then bind the verified device/app instance to the RevenueCat app-user ID.

## Endpoints

- `POST /v1/keyboard-reply`
  - Body: `{ "user_id": "...", "message": "...", "tone": "曖昧", "mode": "接話", "revenuecat_app_user_id": "..." }`
  - The `is_pro` flag is not trusted. The Worker verifies RevenueCat's `pro`
    entitlement with `REVENUECAT_SECRET_API_KEY` and fails closed when the
    secret or entitlement is unavailable.
  - Response: `{ "reply": "..." }`
- `POST /v1/chat/completions`
  - Body: `{ "system_prompt": "...", "user_message": "...", "use_heavy_model": false }`
  - Response is compatible with the app's previous chat-completions parser.
