# LoveKey 尚未解除的阻塞項目

## 已解除的舊阻塞

- Codemagic iOS 26.4.1 Simulator 已成功 build、安裝與啟動。
- iOS 核心 Integration Test 已 1/1 通過。
- LoveKeyboard Extension 版本號繼承問題已修復。
- CI artifacts 已保存並可下載。

因此，「沒有 Mac 所以完全無法執行 iOS Simulator」已不是目前阻塞。

## B-001：實體 iPhone 鍵盤 Extension

- **阻塞測試：** 加入鍵盤、允許完整取用、複製、生成、重試、填入 host app、切換 App、前景／背景。
- **需要：** 使用目前指定 TestFlight build 的實體 iPhone。
- **測試 App：** LINE、Instagram、iMessage。
- **安全限制：** 只能使用測試對話，不得使用正式客戶資料。

## B-002：登入供應商

- **阻塞測試：** Email 註冊／登入、Google 登入與取消、Apple 登入與取消、登出、session 恢復與過期。
- **需要：** 測試帳號及 iOS 上已設定完成的 Google／Apple provider。
- **審核風險：** 若核心功能必須登入，App Review 必須提供有效 demo 帳號與操作說明。

## B-003：RevenueCat 與 Apple 付款生命週期

- **阻塞測試：** 週／年／永久顯示、購買成功、取消、失敗、逾時、恢復購買、重裝、權益持久化與連點。
- **需要：** TestFlight、Apple Sandbox 帳號及 RevenueCat sandbox 資料。
- **安全限制：** 不得真實扣款，不得修改正式商品、entitlement 或 offering。

## B-004：正式 AI endpoint 與錯誤注入

- **阻塞測試：** 真實模型品質、proxy 逾時、生成中斷網、拒答、額度耗盡與模型版本記錄。
- **需要：** 有嚴格預算的測試帳號／endpoint。
- **目前替代證據：** 50 組確定性 fixture、parser 測試、prompt contract 與語意評分。
- **限制：** mock 通過不能宣稱真實模型品質已通過。

## B-005：原生無障礙與裝置矩陣

- **阻塞測試：** VoiceOver、原生焦點、Dynamic Island、鍵盤遮擋、最小支援 iOS、一般尺寸與 Pro Max。
- **深色模式：** 目前程式在淺色／深色系統設定下使用同一套 Brightness.light 主題，需產品決定是否固定淺色。
- **需要：** Codemagic Simulator matrix 加至少一台實體 iPhone。

## B-006：App Store 送審資料

- 1.0.4 仍為 PREPARE_FOR_SUBMISSION。
- 12 個語系的 App 描述與版本更新說明已於 2026-07-17 填寫並回讀驗證。
- 週、年、永久 IAP 均為 READY_TO_SUBMIT，必須與 1.0.4 第一次一起送審。
- 需確認隱私權標籤、審核 demo 帳號、審核操作步驟、合約、稅務與銀行資料。

## B-007：Android 正式發布資格

- Google Play 商家帳戶、稅務與收款資料尚未完成。
- Android 週、年、永久商品尚未完整建立與串接。
- 新個人開發者帳戶須至少 12 名測試人員連續加入封閉測試 14 天。
- 需完成 Play App 內容、資料安全、商店資訊及正式版權限申請。
