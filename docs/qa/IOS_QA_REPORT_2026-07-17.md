# LoveKey iOS QA 與發布流程修正報告（2026-07-17）

## 本次目標

修正 Build 56 暴露出的錯誤發布流程，確保下一個 TestFlight Build 只能從具備 P0 登入、鍵盤授權、完整 QA 與 IPA 驗證的程式線產生。

## 已完成修正

### P0：文件 push 自動發布 TestFlight

- **實際行為：** `master` 任一 push 都會執行 `ios-release.yml`，文件 commit 因此產生回歸的 Build 56。
- **預期行為：** 只有明確的人工發布操作才能上傳 TestFlight。
- **根因：** release workflow 同時監聽 `push: master` 與 `workflow_dispatch`，且上傳前沒有 QA gate。
- **修正：** 移除 push trigger，改為手動觸發並要求輸入 `UPLOAD_TESTFLIGHT`。
- **回歸保護：** release job 在上傳前強制執行 Flutter、對話、UI、iOS Simulator 與 Integration Tests。
- **狀態：** 已修正，GitHub macOS workflow 已驗證通過。

### P0：舊程式線可再次發布

- **實際行為：** Build 56 鍵盤缺少 request metadata 與登入 token，仍可被 release workflow 打包上傳。
- **預期行為：** 缺少 P0 鍵盤授權契約時，發布必須立即失敗。
- **修正：** 增加 account service、`X-Request-Signature`、`Authorization` 與 client secret 掃描不變條件。
- **狀態：** 已修正，靜態契約已比對通過。

### P1：IPA 主 App 與鍵盤資料不同步

- **風險：** 主 App／鍵盤擴充的 Bundle ID、版本或 Build 號不一致，可能造成安裝、TestFlight 或審核問題。
- **修正：** 上傳前直接解析 IPA，驗證主 App 與鍵盤 Bundle ID、版本、Build 號一致，並確認沒有殘留 `__AI_PROXY_URL__`。
- **狀態：** 已加入 release gate；需由下一次 macOS release build 實際執行。

## 本機實際測試結果

| 測試 | 結果 |
| --- | --- |
| 本機 Flutter 版本 | 3.41.7／Dart 3.11.5 |
| `flutter analyze --no-pub` | 通過，0 問題 |
| 全部單元與 Widget Tests | 29／29 通過 |
| 對話邏輯專項 | 14／14 通過；mock／固定案例，不等同真實模型品質 |
| UI 專項 | 11／11 通過 |
| `flutter build web --release` | 通過 |
| Cloudflare Worker `node --check` | 通過 |
| GitHub Actions `actionlint` | 通過 |
| 追蹤中的敏感檔 | 0 |
| 客戶端 Secret 格式掃描 | 0 |

## iOS Simulator 狀態

GitHub Actions Run [29548206130](https://github.com/zli426491-byte/ai-love-keyboard/actions/runs/29548206130) 已在 macOS runner 實際執行 iOS Simulator 測試：

- Flutter 3.44.6／Dart 3.12.2。
- Xcode 26.5。
- iPhone 17 Pro／iOS 26.2 Simulator 成功啟動。
- iOS Simulator build 通過。
- 核心導覽與本機輸入 Integration Test 1／1 通過。

本機仍為 Windows，無法執行 Xcode；上述結論來自實際 macOS Simulator 執行證據，不是以 Web build 代替。

## App Store Connect 資料修正

- 1.0.4 的 12 個語系已填入各語系 App 描述與版本更新內容。
- 描述已明確說明需要 LoveKey 帳號、AI 生成功能需要 Pro，以及週／年／永久三種 App 內購買方式。
- 更新前資料已保存於本機 QA artifact，更新後已透過 App Store Connect API 回讀逐欄驗證。
- 尚未自動提交 App Review，也尚未更換 1.0.4 綁定 Build。

## 下一個發布門檻

1. 從本 QA commit 手動執行 `iOS Release`，輸入確認字串後產生 Build 57。
2. 確認 Build 57 為 `VALID／IN_BETA_TESTING`，且 IPA metadata 報告一致。
3. 使用實體 iPhone 完成第三方鍵盤、登入、AI 生成／填入、Apple Sandbox 購買與恢復購買。
4. 實機全通過後才將 App Store 1.0.4 改綁 Build 57 並送審。
