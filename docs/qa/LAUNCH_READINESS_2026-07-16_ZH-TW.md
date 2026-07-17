# LoveKey 正式上線與營運準備報告（2026-07-16）

## 一句話結論

LoveKey 的公開版 1.0.2 已在 App Store 銷售，但準備開始收費與買量的 1.0.4 仍處於「準備提交」；自動化測試已通過，現在真正的發布阻塞是實體 iPhone 鍵盤流程、Apple Sandbox 付款／恢復購買、商店送審資料及 Android 正式版資格。

## 目前伺服器端狀態

以下資料於 2026-07-16 透過 App Store Connect 官方 API 唯讀查詢確認：

| 項目 | 現況 | 判定 |
| --- | --- | --- |
| 公開 App Store 版本 | 1.0.2，READY_FOR_SALE | 已在線，但不是目前準備營運的新版本 |
| 新版本 | 1.0.4，PREPARE_FOR_SUBMISSION | 尚未加入送審 submission |
| 1.0.4 綁定 Build | Build 55，VALID | P0 產品基線，但不是完整 QA 所測的精確 commit |
| TestFlight 最新 Build | Build 56，VALID／IN_BETA_TESTING | 內部測試可見，但由較舊 master 文件 commit 自動產生，核心 AI 鍵盤與正式 Proxy 不相容 |
| 週訂閱 | com.ailovekeyboard.pro.weekly，READY_TO_SUBMIT | 資料齊，但尚未送 Apple 審核 |
| 年訂閱 | com.ailovekeyboard.pro.yearly，READY_TO_SUBMIT | 資料齊，但尚未送 Apple 審核 |
| 永久會員 | com.ailovekeyboard.pro.lifetime，READY_TO_SUBMIT | 資料齊，但尚未送 Apple 審核 |
| App Review 聯絡資料 | 已填 | 通過基本資料檢查 |
| Demo 帳號 | 未填，且標記不需要 | 若核心功能必須登入，這裡必須改為需要並提供有效測試帳號 |
| 商店截圖 | 繁中有 5 張 iPhone、1 張 iPad | 其他 11 個語系目前沒有本地化截圖 |
| 版本更新說明 | 12 個語系均未填 whatsNew | 送審前需補齊 |

Apple 規則重點：

- 第一次送審 App 內購或訂閱時，必須和新的 App 版本一起提交。
- TestFlight 下載的 App 會使用沙盒付款環境，不會產生真實扣款。
- 若某些功能必須登入，App Review 資訊應提供可用 demo 帳號及特殊設定步驟。

### 2026-07-17 Build 56 更正

- Build 56 的確已在 TestFlight 內部測試，不是「尚未出現在 TestFlight」。
- Build 56 不是 Build 55 的後續修正版；兩者來自平行分支。
- Build 56 鍵盤擴充沒有送正式 Proxy 所需的 timestamp、nonce、signature 與登入 token，AI 請求會被 `401 request_metadata_required` 擋下。
- 完整 QA 驗證的是 commit `68804aad1d0555ffbda98532aa74b5b5a320e14c`，目前尚未上傳 TestFlight。
- 最終驗收目標應改為從完整 QA 程式線產生 Build 57。完整證據見 [Build 55／56 專項稽核](TESTFLIGHT_BUILD_55_56_AUDIT_2026-07-17_ZH-TW.md)。

## P0：送出 iOS 1.0.4 前一定要完成

### 1. 實體 iPhone 鍵盤流程

- [ ] 從完整 QA 程式線產生並由 TestFlight 全新安裝 Build 57；不要以 Build 56 驗收。
- [ ] 走完隱私權與 onboarding。
- [ ] 從教學頁跳到 iPhone 設定。
- [ ] 加入 LoveKey 鍵盤並開啟「允許完整取用」。
- [ ] LINE、Instagram、iMessage 各測一次。
- [ ] 複製對方訊息。
- [ ] 切換 LoveKey，選模式與語氣。
- [ ] 每次只產生一則回覆。
- [ ] 回覆可以填入聊天 App 輸入框。
- [ ] 連續點擊不會重複請求、整頁閃爍或當機。
- [ ] 無完整取用、斷網、逾時時有可理解的繁中提示。

### 2. 登入

- [ ] Email 註冊、登入、登出與重新登入。
- [ ] Google 登入成功與取消。
- [ ] Apple 登入成功與取消。
- [ ] 關閉重開後 session 保留。
- [ ] 若 AI 核心功能必須登入，建立 App Review 專用測試帳號並填入審核資料。

### 3. RevenueCat 與 Apple Sandbox

- [ ] Paywall 正確載入週、年、永久及當地貨幣價格。
- [ ] 使用 Sandbox 完成一筆週訂閱。
- [ ] 購買後 pro 權益立即解鎖。
- [ ] 關閉重開後權益保留。
- [ ] 取消付款不會錯誤解鎖。
- [ ] 刪除重裝後「恢復購買」成功。
- [ ] 沒有購買紀錄時，恢復購買有清楚提示。
- [ ] App Store Connect 1.0.4 同時選入週、年、永久三項商品。

### 4. App Store 送審資料

- [ ] 補齊 12 個語系的版本更新說明。
- [ ] 確認 App 描述、截圖、付費功能與實際 App 一致。
- [ ] 審核備註寫明：如何加入鍵盤、開啟完整取用、複製、生成、填入，以及如何開啟 Paywall。
- [ ] 若需要登入，附 demo 帳號。
- [ ] 確認隱私權標籤涵蓋登入資料、剪貼簿內容、AI 處理、訂閱與分析事件。
- [ ] 確認付費 App 合約、稅務及收款銀行資料有效。
- [ ] 將 1.0.4、週訂閱、年訂閱、永久會員加入同一個送審項目。

## P1：開始廣告買量前一定要完成

### 數據與歸因

目前事件名稱與第一方 Worker 上報已存在，但 Facebook、Firebase、Adjust 等正式 SDK 仍是註解／TODO，尚不足以做可靠買量判斷。

- [ ] 接入至少一套真實 Analytics。
- [ ] 若投放 Meta，完成 Meta App Events 或 MMP 歸因。
- [ ] 驗證 app_open、onboarding_complete、keyboard_enabled、paywall_shown、purchase_started、purchase、reply_generated。
- [ ] RevenueCat 與歸因工具能對上實際營收。
- [ ] 建立每日 CPI、試用率、付款率、退款率、ROAS 儀表板。
- [ ] 設定第一輪廣告停損預算，未通過付款事件前不得開正式買量。

### 商店與素材

- [ ] 廣告影片使用目前實際鍵盤流程，不得展示已移除功能。
- [ ] App Store 截圖文字與介面一致。
- [ ] 第一批投放市場至少有對應語言的商店截圖。
- [ ] 素材不得承諾必定脫單、操控對方或保證戀愛成功。
- [ ] 完成客服信箱、退款／訂閱管理說明與評論回覆流程。

## Android 額外阻塞

- [ ] 完成 Google Play 商家帳戶、稅務與收款資料。
- [ ] 建立週、年、永久三項 Google Play 商品。
- [ ] 將三項商品匯入 RevenueCat 並綁定 pro 與 default offering。
- [ ] 建立封閉測試。
- [ ] 至少 12 名測試人員連續加入 14 天。
- [ ] 收集並保存測試回饋。
- [ ] 完成 App 內容、資料安全、商店資訊與政策表單。
- [ ] 申請正式版權限；Google 審核通過後才能發布正式 Android 版本。

## 建議執行順序

1. 今天：整理完整 QA 程式線並產生 Build 57；Build 56 不進行最終驗收。
2. 同步：補 12 個語系更新說明與 App Review demo 帳號／操作備註。
3. 驗收全通過：把 1.0.4 與三項 IAP 一起送 Apple 審核。
4. 審核等待期間：接 Analytics／Meta 歸因、準備原創素材與停損規則。
5. Apple 通過後：先小額驗證，不直接放大預算。
6. Android：立即開始 12 人／14 天封閉測試，因為這是不可壓縮的日曆時間。

## 上線判定

| 階段 | 現在是否通過 |
| --- | --- |
| 程式靜態與自動測試 | 通過 |
| Codemagic iOS Simulator | 通過 |
| BrowserStack 基本實機啟動 | 通過 |
| 實體 iPhone 第三方鍵盤 | 未通過 |
| Sandbox 付款與恢復購買 | 未通過 |
| App Store 1.0.4 送審資料 | 未完成 |
| 真實買量歸因 | 未完成 |
| Android 正式版資格 | 未完成 |

目前決策：可繼續 TestFlight 內部驗收；不可開始正式付費買量；iOS 通過實機與沙盒付款後即可進入送審。

## 官方規則參考

- Apple：<https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-in-app-purchase>
- Apple TestFlight／Sandbox：<https://developer.apple.com/help/app-store-connect/test-a-beta-version/testing-subscriptions-and-in-app-purchases-in-testflight/>
- Apple App Review 資訊：<https://developer.apple.com/app-store/review/>
- Google Play 新個人帳戶測試要求：<https://support.google.com/googleplay/android-developer/answer/14151465>
