# LoveKey 上線前驗收清單

> 更新日期：2026-06-04
> 目的：判斷 AI 戀愛鍵盤是否可以正式上架收費、開始買量。
> 結論規則：所有 P0 必須通過；P1 至少不能影響購買、AI 回覆、鍵盤啟用與審核。

## 目前結論

暫定狀態：不建議直接正式賣。可以先推 TestFlight 做內部驗收。

主要原因：
- iOS 鍵盤 extension 必須用 TestFlight 實機驗證，Web/Flutter test 無法覆蓋。
- RevenueCat 產品必須在 TestFlight 沙盒完成真實購買、恢復購買、Pro 解鎖驗證。
- GitHub Actions 必須確認已設定 `AI_PROXY_URL` secret，否則正式 IPA 的鍵盤 AI endpoint 不會注入。

## 已完成的自動檢查

- [x] `flutter analyze`：通過。
- [x] `flutter test`：通過。
- [x] `flutter build web --release`：通過。
- [x] App 端未在 `lib/`、`ios/` 搜到 OpenAI `sk-` 私鑰。
- [x] AI 主 App 走 backend proxy：`AI_PROXY_URL`。
- [x] iOS 鍵盤 extension 沒硬編 OpenAI key。
- [x] GitHub iOS workflow 有 build 前注入 `AI_PROXY_URL` 到鍵盤 extension 的步驟。
- [x] RevenueCat iOS Public SDK Key 已設定。
- [x] 首頁 / 盲盒 / Paywall 相關 UI 可 Web build。

## P0：正式賣之前必須通過

### 1. RevenueCat / App Store IAP

- [ ] TestFlight 裝新版 build。
- [ ] Paywall 能載入產品，不出現「RevenueCat 尚未載入產品」。
- [ ] 週會員可購買。
- [ ] 年度會員可購買。
- [ ] 永久會員可購買。
- [ ] 購買後 App 內 Pro 狀態立即解鎖。
- [ ] 關掉 App 再打開，Pro 狀態仍保留。
- [ ] 恢復購買可用。
- [ ] Apple ID 設定裡能看到訂閱。
- [ ] App Store Connect 產品 ID 與程式內一致：
  - `com.ailovekeyboard.pro.weekly`
  - `com.ailovekeyboard.pro.yearly`
  - `com.ailovekeyboard.pro.lifetime`

### 2. AI Proxy

- [ ] Cloudflare Worker 已部署。
- [ ] Worker 已設定 `OPENAI_API_KEY` secret。
- [ ] Worker 已綁定 `KV_USAGE`。
- [ ] Worker `/v1/chat/completions` 可回應。
- [ ] Worker `/v1/keyboard-reply` 可回應。
- [ ] GitHub Secrets 已設定 `AI_PROXY_URL`。
- [ ] GitHub build log 顯示 `Runtime AI proxy config injected into LoveKeyboard extension.`
- [ ] TestFlight 版鍵盤不顯示「AI 尚未設定」。

### 3. iOS 鍵盤核心流程

- [ ] iPhone 設定中可看到 LoveKey 鍵盤。
- [ ] 可啟用「允許完整取用」。
- [ ] LINE 可切到 LoveKey 鍵盤。
- [ ] IG 可切到 LoveKey 鍵盤。
- [ ] iMessage 可切到 LoveKey 鍵盤。
- [ ] 複製對方訊息後，鍵盤可讀取或貼入對話。
- [ ] 選擇「接話 / 破冰 / 邀約 / 安撫 / 自訂」後可產生回覆。
- [ ] 每次只生成一則回覆，避免浪費 API。
- [ ] 點「發送 / 填入」不整個畫面閃爍。
- [ ] 回覆可填入聊天 App 輸入框。
- [ ] 沒有完整取用權限時，提示文案清楚。
- [ ] 沒網路時，提示文案清楚。
- [ ] AI 回覆語氣自然，不出現「高情商的回覆」「AI 建議如下」等模板痕跡。

### 4. Onboarding / 教學

- [ ] 教學已符合新版鍵盤流程。
- [ ] 第 1 步：長按對方訊息並複製。
- [ ] 第 2 步：切到 LoveKey 鍵盤。
- [ ] 第 3 步：選模式 / 語氣。
- [ ] 第 4 步：生成並填入回覆。
- [ ] 教學不再描述舊版三句回覆流程。
- [ ] 「打開 iPhone 設定」能跳設定頁。

### 5. 審核風險

- [ ] App 描述沒有提到尚未實作的 Pro 功能。
- [ ] 截圖與實際功能一致。
- [ ] 付款文案清楚說明會透過 App Store 完成。
- [ ] 免費次數 / 訂閱解鎖內容描述一致。
- [ ] 不承諾保證戀愛成功、必定脫單、操控對方等高風險文案。

## P1：上線後買量前必須通過

- [ ] Analytics 真實 SDK 已接入，不能只 debug log。
- [ ] 至少追蹤：
  - App open
  - Onboarding complete
  - Keyboard guide open
  - Paywall shown
  - Purchase started
  - Purchase success
  - AI reply generated
  - Keyboard reply generated
- [ ] 廣告素材與 App 內流程一致。
- [ ] App Store 截圖多語系與實際 UI 一致。
- [ ] 隱私權政策與資料使用說明更新。

## 本機目前能確認的狀態

可通過：
- Flutter 靜態檢查。
- Flutter widget 測試。
- Web release build。
- 主 App 基本頁面可渲染。
- AI key 沒直接放在 App client。

仍需實機確認：
- iOS 鍵盤 extension。
- iOS 貼上 / 填入行為。
- RevenueCat 真實商品載入與付款。
- Pro 權益解鎖。
- TestFlight build 的 `AI_PROXY_URL` 注入結果。

## 下一次 TestFlight 驗收順序

1. 安裝最新 TestFlight。
2. 開 App，走完整 onboarding。
3. 打開鍵盤教學，跳 iPhone 設定啟用鍵盤與完整取用。
4. 在 LINE 複製一句對方訊息。
5. 切到 LoveKey 鍵盤。
6. 選一種模式產生回覆。
7. 確認可填入 / 發送，不閃爍。
8. 開 Paywall，測週會員購買。
9. 關 App 重開，確認 Pro 狀態。
10. 測恢復購買。
