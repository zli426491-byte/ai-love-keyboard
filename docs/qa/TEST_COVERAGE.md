# LoveKey 測試覆蓋矩陣

| 功能 | 測試方式 | 狀態 | 說明 |
| --- | --- | --- | --- |
| Flutter 靜態分析 | flutter analyze | 通過 | 0 問題 |
| Flutter 單元／Widget | flutter test | 通過 | 29/29 |
| 對話 parser／品質 | dialogue_eval | 通過 | 14/14，mock／靜態模式 |
| UI 響應式／Widget | ui_audit | 通過 | 11/11 |
| iOS Simulator build | Codemagic／GitHub Actions | 通過 | iOS 26.4.1；GitHub iOS 26.2 |
| Simulator 安裝／啟動 | simctl | 通過 | 一般 App 可正常顯示 |
| iOS 核心 Integration | Flutter Integration Test | 通過 | 1/1；GitHub Run 29548206130 |
| BrowserStack 實機安裝／冷啟動 | iPhone 15 Pro Max／iOS 17.3 | 基本通過 | 免費時段只測到 onboarding |
| iOS 鍵盤加入／完整取用 | 實體 TestFlight | 未驗證 | 需要實體 iPhone |
| LINE／IG／iMessage 複製生成填入 | 實體 TestFlight | 未驗證 | 發布 P0 |
| Email／Google／Apple 登入 | 實體 TestFlight | 未驗證 | 發布 P0 |
| 週／年／永久當地價格 | Apple Sandbox | 未驗證 | 發布 P0 |
| RevenueCat LoveKey offering 契約 | 唯讀 API + Python 單元測試 | 4／4 通過；三商品齊全 | 發布 gate |
| 購買／取消／恢復／重裝 | Apple Sandbox | 未驗證 | 發布 P0 |
| 真實模型品質 | 測試 endpoint | 未驗證 | mock 不等於正式模型 |
| 斷網／慢網／逾時 | 實體／代理錯誤注入 | 未驗證 | 發布 P0 |
| 大字體 | Widget + 實體 | 部分通過 | Widget 已覆蓋，原生仍需實機 |
| 深色模式 | Simulator 截圖 | 未通過產品要求 | 目前固定 Brightness.light |
| VoiceOver | 實體／Simulator | 未驗證 | 發布前建議 |
| Android 內部測試 | Play Console | 已發布 | 正式版仍受商家帳戶與封閉測試阻塞 |

## 永久自動化

- scripts/dialogue_eval.sh：對話邏輯。
- scripts/ui_audit.sh：響應式與 Widget UI。
- scripts/ios_qa.sh：macOS／iOS QA。
- scripts/codemagic_ios_simulator_qa.sh：Codemagic Simulator、Integration、截圖與 artifacts。
- .github/workflows/ios-qa.yml：GitHub iOS QA。
- Codemagic workflow lovekey-ios-simulator-qa：每日或手動執行。

## 目前覆蓋解讀

自動化已能阻擋 parser、明顯模板回覆、Widget overflow、Simulator build／install 及基本導覽回歸。第三方鍵盤、完整取用、host app 填入、社交登入及付款生命週期仍只能靠 TestFlight 實機驗收，不能用 build 成功代替。
