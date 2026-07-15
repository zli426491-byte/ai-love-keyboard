# LoveKey 社群登入設定

登入頁現在支援：

- Email／密碼（既有流程）
- Google 原生登入（iOS／Android）
- Apple 原生登入（iOS）；Android 使用 Supabase Apple OAuth 回呼

所有方式最後都會取得同一個 Supabase `user.id`，再交給 RevenueCat
`logIn(user.id)`。Worker 仍以 Supabase JWT 為登入依據，不會信任裝置上的
Pro 布林值或第三方 Email。

## 1. Supabase

在 Supabase Dashboard → Authentication → Providers：

1. 開啟 Google，填入 Google **Web application client ID** 與 client secret。
2. 開啟 Apple，填入 Apple Developer 的 Services ID／Key 設定。
3. 在 Authentication → URL Configuration → Additional Redirect URLs 加入：

   ```text
   com.ailovekeyboard.app://login-callback
   ```

Google 原生 iOS 登入若依照 Supabase 的 `signInWithIdToken` 流程，請依目前
Supabase 文件設定 Google provider 的 nonce 選項。

## 2. Apple Developer

在 App ID `com.ailovekeyboard.app` 開啟 Sign in with Apple，並在 Xcode
的 Runner target 開啟相同 capability。Apple `.p8` 私密金鑰只放在 Supabase
Provider 或 CI Secret，不得放進 Flutter 專案、App bundle 或 Git。

## 3. Google Cloud

建立並限制以下 OAuth client：

- Web client ID（提供給 Supabase 與 Android serverClientId）
- Android client ID（套件名稱 `com.ailovekeyboard.app`，填入正式簽署憑證 SHA-1／SHA-256）
- iOS client ID（Bundle ID `com.ailovekeyboard.app`）

iOS 還需要 Google 的 `REVERSED_CLIENT_ID` 作為 URL scheme。CI 會將
`GOOGLE_IOS_REVERSED_CLIENT_ID` 替換到 `ios/Runner/Info.plist` 的 placeholder。

## 4. GitHub Actions Secrets

新增以下非私密 OAuth client ID（以 Secret 管理，避免散落在 workflow）：

```text
GOOGLE_WEB_CLIENT_ID
GOOGLE_IOS_CLIENT_ID
GOOGLE_IOS_REVERSED_CLIENT_ID
```

現有 workflow 會將：

- iOS：`GOOGLE_WEB_CLIENT_ID`、`GOOGLE_IOS_CLIENT_ID` 注入 `dart-define`
- Android：`GOOGLE_WEB_CLIENT_ID` 注入 `dart-define`
- iOS：用 `GOOGLE_IOS_REVERSED_CLIENT_ID` 注入 URL scheme

## 5. Build 參數

本機測試時使用自己的公開 client ID：

```powershell
flutter build apk --debug `
  --dart-define=SUPABASE_URL="https://<project>.supabase.co" `
  --dart-define=SUPABASE_ANON_KEY="<publishable-or-anon-key>" `
  --dart-define=GOOGLE_WEB_CLIENT_ID="<web-client-id>"
```

正式 CI 不要把 Apple secret、Google client secret 或服務角色金鑰放入
`dart-define`；它們只能留在 Supabase／GitHub Actions Secret。

## 6. 帳號合併規則

不要用 Email 自動把兩個 Supabase 使用者合併。Apple 的「隱藏我的 Email」
可能產生 relay address。正式做法是讓已登入使用者透過
`linkIdentityWithIdToken` 綁定 Google／Apple identity，所有會員與 RevenueCat
資料只使用同一個 Supabase `user.id`。
