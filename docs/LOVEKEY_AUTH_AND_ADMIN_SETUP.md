# LoveKey 帳號、會員驗證與管理摘要

這份文件是正式上線前的必要設定。正式環境採用：

**登入帳號 → RevenueCat 綁定同一個 account ID → Worker 驗證 entitlement → 通過後才呼叫 AI API。**

## 1. Supabase

1. 建立 Supabase 專案，開啟 Email/Password 登入。
2. 設定正式網域與 Email 驗證政策。
3. 記下 Project URL、anon public key；這兩個值會以 build define 放進 App。
4. App 內註冊、登入、登出與刪除帳號都走 Supabase Auth。

## 2. Worker secrets

在 `cloudflare-worker` 目錄執行（不要把值寫入 `wrangler.toml`）：

```powershell
npx wrangler secret put OPENAI_API_KEY
npx wrangler secret put REVENUECAT_SECRET_API_KEY
npx wrangler secret put SUPABASE_URL
npx wrangler secret put SUPABASE_ANON_KEY
npx wrangler secret put SUPABASE_SERVICE_ROLE_KEY
npx wrangler deploy
```

`SUPABASE_SERVICE_ROLE_KEY` 只給 Worker 的帳號刪除 endpoint 使用，絕不能放進 App、GitHub artifact 或前端程式碼。

`wrangler.toml` 的正式旗標必須保持：

```toml
REQUIRE_AUTH = "true"
REQUIRE_ACTIVE_PRO = "true"
REQUIRE_REQUEST_METADATA = "true"
```

缺少 Supabase secret 時 Worker 會 fail closed 回傳 `auth_not_configured`，這是預期的安全狀態，不可用關閉旗標來繞過。

## 3. GitHub Actions secrets

iOS 至少需要：`AI_PROXY_URL`、`REVENUECAT_IOS_PUBLIC_KEY`、`SUPABASE_URL`、`SUPABASE_ANON_KEY`、App Store Connect 與簽名 secrets。

Android 至少需要：`AI_PROXY_URL`、`REVENUECAT_ANDROID_PUBLIC_KEY`、`SUPABASE_URL`、`SUPABASE_ANON_KEY`、`ANDROID_KEYSTORE_BASE64`、`ANDROID_KEYSTORE_PASSWORD`、`ANDROID_KEY_ALIAS`、`ANDROID_KEY_PASSWORD`。

Workflow 會在 build 前檢查空值；任何一項缺少都應讓 build 失敗，不要改成預設值。

## 4. 管理摘要

Worker 提供受保護的：

```text
GET /v1/admin/summary
Authorization: Bearer <Supabase access token>
```

只有 Supabase `app_metadata.role=admin` 或 `ADMIN_EMAILS` 內的 Email 可以讀取。摘要只包含請求數、免費／付費事件、帳號數與最近時間，不保存原始聊天內容。

## 5. 上線前驗收

- 正式 Worker 設為 `REQUIRE_ACTIVE_PRO=true`：未購買帳號呼叫 API 應回 `active_subscription_required`；偽造 `is_pro=true` 不得解鎖。若要測試免費額度，請使用獨立 staging Worker。
- 付費牆在未登入時不得開始購買或恢復購買；先登入，再由 RevenueCat 綁定同一個 account ID。
- iOS、Android 登入同一帳號後，RevenueCat 使用同一個 app user ID；一端購買後另一端恢復購買可取得相同 entitlement。
- 刪除帳號後，Supabase 使用者被刪除、本機 token/用量/金幣紀錄清除，舊 token 再呼叫 Worker 必須失敗。
- 以不同裝置與 IP 測試免費配額、每分鐘 burst、Pro 日額度與重模型日額度。
- 確認 Android/iOS 真機 build 的 API URL、公開 RevenueCat key 與 App Group/鍵盤共享資料均已注入。
