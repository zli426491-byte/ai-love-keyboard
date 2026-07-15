# LoveKey P0 平台驗收清單

> 目標：這幾天要上線收錢，先把會阻塞收入的外部平台全部打通。

## 1. Cloudflare Worker

本機檢查結果：

- `wrangler deploy --dry-run` 已通過。
- Worker：`lovekey-proxy`
- KV binding：`KV_USAGE`

已完成：

- Wrangler 已登入，Worker 已部署。
- `OPENAI_API_KEY`、`REVENUECAT_SECRET_API_KEY`、`SUPABASE_URL`、`SUPABASE_ANON_KEY`、`SUPABASE_SERVICE_ROLE_KEY` 已設定為 Worker secrets。

部署確認（需要更新 Worker 程式時才執行）：

```powershell
wrangler deploy
```

- 記下輸出的 workers.dev 網址，例如：

```text
https://lovekey-proxy.xxxxx.workers.dev
```

## 2. GitHub Secrets

GitHub repo 已有：

```text
AI_PROXY_URL
SUPABASE_URL
SUPABASE_ANON_KEY
REVENUECAT_IOS_PUBLIC_KEY
REVENUECAT_ANDROID_PUBLIC_KEY
APP_STORE_CONNECT_API_KEY
APP_STORE_CONNECT_KEY_ID
APP_STORE_CONNECT_ISSUER_ID
CERTIFICATE_PRIVATE_KEY
ANDROID_KEYSTORE_BASE64
ANDROID_KEYSTORE_PASSWORD
ANDROID_KEY_ALIAS
ANDROID_KEY_PASSWORD
```

說明：

- `APP_STORE_CONNECT_API_KEY`：貼 `.p8` 私鑰完整內容。
- `APP_STORE_CONNECT_KEY_ID`：App Store Connect API Key ID。
- `APP_STORE_CONNECT_ISSUER_ID`：App Store Connect Issuer ID。
- `CERTIFICATE_PRIVATE_KEY`：用來建立 iOS 發佈憑證的私鑰密碼/內容，需與目前 CI 簽名流程一致。

可選，等 Meta/Adjust/TikTok 準備好再填：

```text
FACEBOOK_APP_ID
ADJUST_APP_TOKEN
ADJUST_ENVIRONMENT
TIKTOK_PIXEL_ID
```

`AI_PROXY_URL` 必須是 Cloudflare deploy 後的網址。

## 3. GitHub Actions / TestFlight Build

進 GitHub Actions 手動跑 `iOS Release`。

成功條件：

- log 出現：

```text
Runtime AI proxy config injected into LoveKeyboard extension.
```

- 產生 IPA。
- 成功 Upload to TestFlight。

如果失敗，優先看：

- `AI_PROXY_URL secret is empty`
- App Store Connect API key
- signing files / certificate
- keyboard extension profile

## 4. RevenueCat / App Store Connect 商品

產品 ID 必須完全一致：

```text
com.ailovekeyboard.pro.weekly
com.ailovekeyboard.pro.yearly
com.ailovekeyboard.pro.lifetime
```

RevenueCat entitlement：

```text
pro
```

Offering 必須把三個 package 都加進 current/default offering。

## 5. TestFlight 實機驗收

### 鍵盤

- iPhone 設定能看到 LoveKey 鍵盤。
- 可開啟「允許完整取用」。
- LINE 可切到 LoveKey。
- IG 可切到 LoveKey。
- iMessage 可切到 LoveKey。
- 複製一句對方訊息後，LoveKey 能讀取或貼入。
- 選一個模式後可生成 1 則自然回覆。
- 點填入/發送時不閃爍、不當機。
- 失敗時不出現工程字串或英文錯誤。

### Paywall

- 商品價格有載入，不顯示「訂閱方案載入中」卡死。
- 週會員可購買。
- 年度會員可購買。
- 永久會員可購買。
- 購買後 Pro 立即解鎖。
- 關 App 重開後 Pro 仍有效。
- 恢復購買可用。

## 6. 買量前最低事件

正式買量前至少確認 debug log 有：

```text
app_open
paywall_shown
plan_selected
purchase_started
subscription_started
purchase
reply_generated
keyboard_enabled
```

Meta 真正接 SDK 前，可以先用這些 log 驗證流程；正式投放前要換成真 SDK 或 MMP。

## 今日判斷

- 主 App 本機 `flutter analyze` 可過。
- 主 App 本機 `flutter test` 可過。
- 主 App 本機 `flutter build web --release` 可過。
- 敏感 key 掃描可過，沒有發現 client-side `sk-` / `cfat_` key 或追蹤 placeholder。
- Worker `wrangler deploy --dry-run` 可過。
- 已新增 `tools/verify_lovekey_release.ps1`，之後每次發版前可固定跑：

```powershell
cd "C:\Users\AsusGaming\ai_love_keyboard"
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\verify_lovekey_release.ps1
```

- 目前阻塞在：本輪修改尚未 commit/push、需重新產生最終 iOS／Android build，以及 TestFlight／Play 實機購買與恢復購買驗收。
