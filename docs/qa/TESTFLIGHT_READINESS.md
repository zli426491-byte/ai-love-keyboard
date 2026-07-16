# LoveKey TestFlight 驗收狀態

## 判定

**可以繼續內部 TestFlight 實機驗收。**

**在下列實機清單通過前，不可送 App Store 1.0.4，也不可開始付費買量。**

## 已完成證據

- Flutter dependencies 可正常解析。
- flutter analyze：0 問題。
- Flutter 單元／Widget 測試：27/27 通過。
- 對話邏輯：14/14 通過，明確標記為 mock／靜態模式。
- 50 組繁體中文固定對話案例涵蓋必要情境。
- UI／Widget 專項：11/11 通過。
- Codemagic iOS 26.4.1 Simulator build、安裝、啟動成功。
- iOS Integration Test：1/1 通過。
- BrowserStack iPhone 15 Pro Max／iOS 17.3 完成安裝、冷啟動與進入 onboarding。

## 實體 iPhone 退出清單

以下項目必須以 Build 55 或後續明確指定的驗收 build 完成：

- [ ] 從 TestFlight 全新安裝。
- [ ] 接受隱私權提示，完成並重跑 onboarding。
- [ ] 加入 LoveKey 鍵盤並開啟「允許完整取用」。
- [ ] LINE、Instagram、iMessage 各複製一則訊息。
- [ ] 每個 host app 產生一則回覆、重試並填入。
- [ ] 測試空白、短句、長句、多行、emoji、特殊符號。
- [ ] 快速連點不會重複請求或讓整個鍵盤閃爍。
- [ ] 測試斷網、慢網、逾時與模型拒答。
- [ ] 顯示週、年、永久商品及當地價格。
- [ ] 完成 Apple Sandbox 購買成功、取消與失敗。
- [ ] 有／無購買紀錄時各測一次恢復購買。
- [ ] 重啟、登出登入及重裝後驗證 pro 權益。
- [ ] Email、Google、Apple 登入成功與取消流程。
- [ ] 驗證小尺寸 iPhone、一般尺寸與 Pro Max。
- [ ] 驗證大字體、VoiceOver、Safe Area 與鍵盤遮擋。
- [ ] 決定固定淺色或新增真正深色主題。
- [x] Codemagic iOS QA 成功並保存 artifacts。

## 目前商店狀態

2026-07-16 App Store Connect API 唯讀查詢結果：

- Build 55：VALID，已綁定 App Store 1.0.4。
- Build 56：VALID，但不是目前 1.0.4 綁定 build。
- App Store 1.0.4：PREPARE_FOR_SUBMISSION。
- 公開版本：1.0.2，READY_FOR_SALE。
- 週、年、永久商品：READY_TO_SUBMIT，尚未送審。

## 收費準備判定

Paywall UI 已通過 Flutter 測試，但當地價格、購買、取消、恢復購買與權益持久化仍需要 Apple Sandbox 實機證據。未完成前，不可用廣告導入付費流量。
