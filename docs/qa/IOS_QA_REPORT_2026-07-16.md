# LoveKey iOS QA 報告（2026-07-16）

## 執行摘要

| 項目 | 結果 |
| --- | --- |
| QA 日期 | 2026-07-16（Asia/Taipei） |
| 測試分支 | qa/ios-autonomous-qa |
| 實際測試 commit | 68804aad1d0555ffbda98532aa74b5b5a320e14c |
| Codemagic | Build 7，ID 6a58309b809056750f5a2de1，已完成 |
| iOS Simulator | iOS 26.4.1 |
| Flutter 靜態分析 | 通過，0 問題 |
| Flutter 單元／Widget 測試 | 27/27 通過，0 失敗，0 跳過 |
| 對話邏輯測試 | 14/14 通過，確定性 mock／靜態模式 |
| UI／Widget 專項檢查 | 11/11 通過 |
| iOS Integration Test | 1/1 通過 |
| BrowserStack 實機 | iPhone 15 Pro Max／iOS 17.3，基本啟動流程通過 |
| 未結案問題 | P0：0、P1：0、P2：1、P3：3 |
| 正式環境異動 | 無 |
| 真實扣款 | 無 |

結論：Codemagic 適合作為主要、可重複執行的 iOS QA 環境。BrowserStack 可補充實機安裝與啟動抽查，但免費方案每台裝置只有約兩分鐘，無法完整驗證鍵盤 Extension、允許完整取用及付款流程。

## 實際執行項目

### Codemagic

- flutter analyze：通過，0 問題。
- 完整 Flutter 單元／Widget 測試：27 項通過。
- 對話品質與固定案例測試：14 項通過。
- 響應式與 UI Widget 檢查：11 項通過。
- flutter build ios --simulator：通過。
- Simulator 開機、App 安裝、App 啟動：通過。
- 核心導覽與本機輸入 Integration Test：1 項通過。
- Integration Test 結束後重新安裝一般 App，再擷取正常畫面。
- 已擷取淺色與深色系統外觀下的畫面。

Codemagic 紀錄：
<https://codemagic.io/app/6a57a734c841cfc41acd24de/build/6a58309b809056750f5a2de1>

本機證據：

- C:\Users\AsusGaming\Downloads\ai-love-keyboard_7_artifacts\build\qa\codemagic-ios-qa.log
- C:\Users\AsusGaming\Downloads\ai-love-keyboard_7_artifacts\build\qa\home-light.png
- C:\Users\AsusGaming\Downloads\ai-love-keyboard_7_artifacts\build\qa\home-dark.png
- C:\Users\AsusGaming\Downloads\ai-love-keyboard_7_artifacts\build\qa\ios-integration-test.log

### BrowserStack

- 已上傳並安裝 LoveKey 簽署 IPA。
- 裝置：iPhone 15 Pro Max，iOS 17.3。
- 冷啟動後成功顯示隱私權同意畫面。
- 點擊「我同意」後成功進入 onboarding 身份選擇畫面。
- 之後免費實機時段結束。

BrowserStack 尚未驗證：完整 onboarding、加入第三方鍵盤、允許完整取用、複製／生成／填入、RevenueCat 沙盒商品、恢復購買、深色模式與大字體。

## 本輪已驗證修正

### 鍵盤 Extension 無法安裝

- 修正前嚴重度：P1。
- 現象：Simulator 安裝失敗，顯示 Extension placeholder 屬性無效。
- 根因：LoveKeyboard.appex 沒有正確解析 CFBundleShortVersionString 與 CFBundleVersion。
- 修正：Extension 透過 Flutter build configuration 共用 MARKETING_VERSION 與 CURRENT_PROJECT_VERSION。
- 證據：Codemagic Build 7 成功安裝含鍵盤 Extension 的 App，並通過 Integration Test。
- 狀態：已修復。

### 設定頁互動 assertion

- 修正前嚴重度：P2。
- 現象：Widget 測試發現互動卡片缺少合法 Material ancestor。
- 修正：設定頁操作項目改在 Material 環境內渲染，測試點擊前會先捲動到目標。
- 證據：UI／Widget 11/11 通過。
- 狀態：已修復。

### QA 事件解析與截圖流程

- 修正前嚴重度：P2，屬於測試基礎設施問題。
- 現象：Flutter machine event array 解析錯誤；截圖步驟誤啟動 Integration Test Runner。
- 修正：正確解析事件陣列，並在 Integration Test 前保存一般 App，截圖前重新安裝。
- 證據：Build 7 已顯示正常 LoveKey 隱私權畫面，不再是空白測試 Runner。
- 狀態：已修復。

## 尚未結案

### P2：系統深色模式沒有對應深色主題

- 重現方式：淺色模式啟動並擷取 home-light.png，切換 Simulator 為深色模式、重新啟動並擷取 home-dark.png。
- 預期：如果 App 宣告跟隨系統主題，畫面應在保持可讀性的前提下切換配色。
- 實際：兩張圖片逐位元完全相同。
- 根因：MaterialApp 使用 ThemeMode.system，但 AppTheme.lightTheme 與 AppTheme.darkTheme 最終都使用 Brightness.light。
- 風險：目前只能證明深色系統設定下仍能啟動淺色介面，不能代表 App 已支援真正深色設計。
- 處理：需由產品決定「固定淺色」或「新增完整深色主題」。這是整體視覺設計範圍，因此未自動修改。

### P3：iOS 工具鏈維護警告

1. Flutter 提示未來將要求 UIScene lifecycle。
2. app_tracking_transparency 目前不支援 Flutter iOS Swift Package Manager，未來 Flutter 版本可能改為錯誤。
3. CocoaPods 提示 Runner 使用自訂 base configuration，另有未使用 master specs repo 警告。

以上警告沒有造成 Build 7 失敗，但應在下一次重大 Flutter／Xcode 升級前處理。

## 發布判定

目前程式已通過靜態分析、單元測試、Widget 測試、對話邏輯、Simulator build、Simulator 啟動及核心 Integration Test。

目前仍不能視為完整商業發布驗收，以下項目必須使用 TestFlight 實體 iPhone 與 Apple Sandbox 完成：

- 啟用 LoveKey 第三方鍵盤與「允許完整取用」。
- 在真實聊天 App 複製訊息、生成一則回覆並填入輸入框。
- 驗證週、年、永久商品與當地價格。
- 完成沙盒購買與恢復購買，不得使用真實扣款。
- 驗證鍵盤使用中斷網及恢復。
- 驗證大字體，並決定固定淺色或支援深色。

本輪沒有修改正式 RevenueCat、Supabase 正式資料、真實使用者資料，也沒有產生付費交易。
