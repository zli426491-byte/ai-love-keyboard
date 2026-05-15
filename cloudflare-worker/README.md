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
wrangler deploy
```

After deploy, add the Worker URL to GitHub Actions as:

```text
AI_PROXY_URL=https://lovekey-proxy.<your-subdomain>.workers.dev
```

Do not put OpenAI API keys in the app, GitHub repo, or Xcode project.

## Endpoints

- `POST /v1/keyboard-reply`
  - Body: `{ "user_id": "...", "message": "...", "tone": "曖昧", "mode": "接話", "is_pro": true }`
  - Response: `{ "reply": "..." }`
- `POST /v1/chat/completions`
  - Body: `{ "system_prompt": "...", "user_message": "...", "use_heavy_model": false }`
  - Response is compatible with the app's previous chat-completions parser.
