# LoveKey 上線前狀態（2026-07-15）

## 結論

LoveKey 已進入「內部實機驗收」階段，但目前仍不應直接提交正式上架或開始買量。

- iOS：程式、CI、TestFlight、Apple 登入與 RevenueCat iOS 商品已接通，等待 Build 55 實機驗收。
- Android：開發人員驗證與最新內部測試版本已完成；Google Play 商家帳戶尚未設定，因此 Android 付費商品仍無法建立。
- 共同阻塞：購買、恢復購買、鍵盤貼上／生成／填入流程尚未在真實裝置完成 P0 驗收。

## 已完成

### 程式與後端

- `flutter analyze`：通過，0 issue。
- `flutter test`：5 項全部通過。
- Client 敏感金鑰掃描：通過。
- Cloudflare Worker dry-run：通過。
- Worker 已要求 Supabase 登入與 RevenueCat `pro` 權益驗證。
- iOS／Android release signing gate：通過。
- Supabase Email、Google、Apple provider 已啟用。
- Apple App ID `com.ailovekeyboard.app` 已啟用 Sign in with Apple。

### iOS / App Store Connect

- App Store Connect App：LoveKey，Bundle ID `com.ailovekeyboard.app`。
- TestFlight Build 55：`VALID`，已加入 `Internal Testing`。
- App Store 版本 1.0.4 已綁定 Build 55，狀態仍為 `PREPARE_FOR_SUBMISSION`。
- 內部測試群組已有主要 Gmail 帳號與 QQ 測試帳號。
- 正式商店目前仍是 1.0.2；1.0.4 尚未送審。

### RevenueCat iOS

- 正確專案：LoveKey（Project ID `8f0595c6`）。
- Entitlement：`pro` / LoveKey Pro。
- `pro` 已綁定三個 App Store 商品：
  - `com.ailovekeyboard.pro.weekly`
  - `com.ailovekeyboard.pro.yearly`
  - `com.ailovekeyboard.pro.lifetime`
- Default offering 已包含週、年、永久三個 package。
- iOS App configuration 的 Bundle ID 正確。

### Google Play / RevenueCat Android

- Android 開發人員驗證：已完成。
- Play package：`com.ailovekeyboard.app`。
- Play 內部測試最新版：`LoveKey P0 驗收 fd01c8a`，版本名稱 1.0.4、`versionCode 7`，已提供給內部測試人員。
- RevenueCat Play Store app configuration 已建立。
- RevenueCat Google service account：有效。
- Google developer notifications / RTDN：已連線。
- Android CI 已改為使用 GitHub Actions run number 當唯一 `versionCode`，避免再次被 Play 拒絕重複版本。
- 最終 Android 產物：
  - `C:\Users\AsusGaming\Downloads\LoveKey-fd01c8a\android-aab\app-release.aab`
  - `C:\Users\AsusGaming\Downloads\LoveKey-fd01c8a\android-apk\app-release.apk`

## P0 阻塞

### 1. iPhone 實機驗收

使用 TestFlight Build 55 完成以下流程，任何一項失敗都先不要送審：

1. Email、Google、Apple 三種登入至少各測一次。
2. 啟用 LoveKey 鍵盤與「允許完整取用」。
3. LINE、Instagram、iMessage 各測一次：複製對方訊息、切換 LoveKey、選模式與語氣、生成一則回覆、填入輸入框。
4. 確認生成／填入時畫面不閃爍、不當機、不出現工程錯誤字串。
5. 週會員、年度會員、永久會員逐一確認能載入當地價格。
6. 至少完成一筆 Sandbox 購買，確認 `pro` 立即解鎖。
7. 關閉並重開 App，確認 `pro` 保留。
8. 刪除重裝後測試「恢復購買」。

### 2. Google Play 商家帳戶

Play Console 目前明確顯示「如要透過這款應用程式營利，請設定商家帳戶」。這一步需要帳戶持有人本人填寫法定名稱、地址、稅務與收款銀行資料，不能由程式自動代填。

商家帳戶完成後依序執行：

1. 建立週訂閱 `com.ailovekeyboard.pro.weekly`。
2. 建立年訂閱 `com.ailovekeyboard.pro.yearly`。
3. 建立單次產品 `com.ailovekeyboard.pro.lifetime`。
4. 在 RevenueCat 匯入三個 Google Play 商品。
5. 將三個商品掛到 `pro` entitlement 與 default offering 對應 package。
6. 使用 License tester 完成購買與恢復購買驗收。

### 3. Google Play 正式版資格

此帳戶目前須先完成 Google 規定的封閉測試：

- 至少 12 名測試人員選擇參加。
- 連續執行至少 14 天。
- 完成 Play Console 的 App 內容、商店資訊、資料安全與政策工作。

在這些條件完成前，Android 可以內部／封閉測試，但不能申請正式版發布。

## P1（開始買量前）

- 接入真實 Analytics / MMP，不只保留 debug event。
- 驗證 `app_open`、`onboarding_complete`、`paywall_shown`、`purchase_started`、`purchase`、`reply_generated`、`keyboard_enabled`。
- 確認 App Store / Google Play 截圖與目前鍵盤流程一致。
- 確認隱私權政策涵蓋登入、剪貼簿、AI 處理、訂閱與分析事件。
- RevenueCat 帳號 Email 仍未確認，應由帳戶持有人完成確認。

## 建議發布順序

1. 先用 Build 55 完成 iOS P0 實機驗收。
2. 通過後送出 App Store 1.0.4 與三個 IAP 商品。
3. 同時完成 Google Play 商家帳戶與 12 人／14 天封閉測試。
4. Android 最新 AAB 上傳內部測試，再建立商品與 RevenueCat 對應。
5. 兩平台付費與恢復購買都通過後，才開始廣告買量。
