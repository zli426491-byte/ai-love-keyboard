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
wrangler secret put SUPABASE_URL
wrangler secret put SUPABASE_ANON_KEY
wrangler secret put SUPABASE_SERVICE_ROLE_KEY
wrangler deploy
```

## Account and entitlement gate

The app now supports a migration path for a shared account identity. Configure
the client with `SUPABASE_URL` and `SUPABASE_ANON_KEY`, and configure the Worker
with the same public Supabase values. The app sends the Supabase access token;
the Worker validates it through `/auth/v1/user` before using the account ID as
the quota identity. RevenueCat is logged in with that same account ID on both
iOS and Android, then the Worker verifies the `pro` entitlement server-side.

The checked-in production defaults are fail-closed. Do not ship a release or
start paid acquisition while either Supabase secret is missing:

```toml
REQUIRE_AUTH = "true"
REQUIRE_ACTIVE_PRO = "true"
```

After both native builds include account login, RevenueCat binding, and the
Authorization header, deploy with both flags set to `true`. Requests without
a valid account or active entitlement will then be rejected before OpenAI is
called. A Worker with missing Supabase configuration intentionally returns
`auth_not_configured` rather than silently allowing anonymous API traffic.

The protected `GET /v1/admin/summary` endpoint requires a Supabase access token
whose `app_metadata.role` is `admin`, or an email listed in `ADMIN_EMAILS`.
It returns aggregate quota metadata only; raw chat messages are never stored.
The authenticated `POST /v1/account/delete` endpoint permanently deletes the
Supabase user through the service-role key; the key never ships in the app.

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
- Pro heavy-model: 50 requests/day per account/device actor.
- IP burst ceiling: 120 requests/minute across rotating client identifiers.
- Free-tier IP ceiling: 60 requests/day across rotating client identifiers.
- Pro IP ceiling: 1,000 requests/day.

The Worker also caps request sizes, allow-lists `response_format`, times out
OpenAI (20 seconds) and RevenueCat (5 seconds), fails closed when RevenueCat
cannot verify Pro, and sends `Cache-Control: no-store` on API responses. The
KV path is only a local fallback; production deployments must keep the
`QUOTA_COUNTER` binding enabled so quota increments remain atomic.

These controls limit spend and credential abuse, but a client-provided device
fingerprint is not an identity proof. `user_id` in the JSON body is ignored for
quota accounting. Before paid acquisition, add native Apple App Attest and
Android Play Integrity verification at the Worker, then bind the verified
device/app instance to the RevenueCat app-user ID.

`REQUIRE_ACTIVE_PRO=true` is required for production paid access; every request
without an active RevenueCat `pro` entitlement returns
`403 active_subscription_required` before OpenAI is called. The free tier is
for local preview/staging only and must use a separate Worker environment.

The timestamp/nonce/signature headers are checked for freshness, shape, and
best-effort nonce replay protection when KV is available. They are not a
secret and are not authentication. Set `REQUIRE_REQUEST_METADATA=true` only
after every released keyboard build sends those headers.

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
