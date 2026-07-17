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
- **狀態：** 已修正，等待 GitHub macOS workflow 驗證。

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
| Flutter 版本 | 3.41.7／Dart 3.11.5 |
| `flutter analyze --no-pub` | 通過，0 問題 |
| 全部單元與 Widget Tests | 27／27 通過 |
| 對話邏輯專項 | 14／14 通過；mock／固定案例，不等同真實模型品質 |
| UI 專項 | 11／11 通過 |
| `flutter build web --release` | 通過 |
| Cloudflare Worker `node --check` | 通過 |
| GitHub Actions `actionlint` | 通過 |
| 追蹤中的敏感檔 | 0 |
| 客戶端 Secret 格式掃描 | 0 |

## iOS Simulator 狀態

本次未執行 iOS Simulator 測試。

原因：目前本機為 Windows，沒有 Xcode 與 iOS Simulator。本次修改推送後，必須由 GitHub `LoveKey iOS QA` 的 macOS runner 重跑 simulator build、安裝、啟動與 Integration Test，不能以本機 Web build 代替。

## 下一個發布門檻

1. GitHub macOS `ios-qa` 全部通過。
2. 從本 QA commit 手動執行 `iOS Release`，輸入確認字串後產生 Build 57。
3. 確認 Build 57 為 `VALID／IN_BETA_TESTING`，且 IPA metadata 報告一致。
4. 使用實體 iPhone 完成第三方鍵盤、登入、AI 生成／填入、Apple Sandbox 購買與恢復購買。
5. 實機全通過後才將 App Store 1.0.4 改綁 Build 57 並送審。
