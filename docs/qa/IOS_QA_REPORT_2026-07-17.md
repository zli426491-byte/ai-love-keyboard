# LoveKey iOS QA 與發布流程修正報告（2026-07-17）

## 本次目標

修正 Build 56 暴露出的錯誤發布流程，並從具備 P0 登入、鍵盤授權、完整 QA 與 IPA 驗證的程式線產生 TestFlight Build 57。

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

### P0：發布環境誤用 Cleanup App 的 RevenueCat iOS 金鑰

- **實際行為：** 舊金鑰的 current offering 只回傳 `com.cleanupapp.cleaner.weekly` 與 `com.cleanupapp.cleaner.yearly`，LoveKey 週／年／永久三項方案都無法正確載入。
- **根因：** GitHub `REVENUECAT_IOS_PUBLIC_KEY` 指向 Cleanup App，而不是 RevenueCat 的 LoveKey iOS App。
- **修正：** 已改用 LoveKey iOS 公開 SDK 金鑰；唯讀 API 已確認 default offering 包含 `com.ailovekeyboard.pro.weekly`、`com.ailovekeyboard.pro.yearly`、`com.ailovekeyboard.pro.lifetime`，且三項都綁定 `pro` entitlement。
- **回歸保護：** `tools/check_revenuecat_offering.py` 會在每次 iOS release 前查核 current offering；指向錯誤專案或缺少任一商品時立即停止，不進行 build 或上傳。
- **每日監控：** 每日 iOS QA 已改為台北時間 02:00 執行，並在有 GitHub Secret 時同步執行同一個唯讀 offering 預檢。
- **安全性：** 預檢只讀取 offering，不購買、不變更商品、不輸出金鑰。
- **狀態：** 雲端設定已修正，Build 57 已成功通過預檢並上傳；仍需以 Apple Sandbox 完成購買與恢復購買。

### P1：IPA 主 App 與鍵盤資料不同步

- **風險：** 主 App／鍵盤擴充的 Bundle ID、版本或 Build 號不一致，可能造成安裝、TestFlight 或審核問題。
- **修正：** 上傳前直接解析 IPA，驗證主 App 與鍵盤 Bundle ID、版本、Build 號一致，並確認沒有殘留 `__AI_PROXY_URL__`。
- **狀態：** 已加入 release gate，Build 57 的正式 IPA 已實際通過主 App／鍵盤擴充 metadata 驗證。

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
| GitHub Actions workflow 語法與實際執行 | 通過；本機未安裝 `actionlint`，以 GitHub 執行結果驗證 |
| RevenueCat 發布預檢單元測試 | 4／4 通過 |
| RevenueCat LoveKey offering 唯讀預檢 | 通過，週／年／永久 3 項齊全 |
| 追蹤中的敏感檔 | 0 |
| 客戶端 Secret 格式掃描 | 0 |

## iOS Simulator 狀態

GitHub Actions Run [29550621933](https://github.com/zli426491-byte/ai-love-keyboard/actions/runs/29550621933) 已針對 commit `66bd55feffe83231e7f5f7bc413db2cb0a96db29` 在 macOS runner 實際執行 iOS Simulator 測試：

- Flutter 3.44.6／Dart 3.12.2。
- Xcode 26.5。
- iPhone 17 Pro／iOS 26.2 Simulator 成功啟動。
- iOS Simulator build 通過。
- 核心導覽與本機輸入 Integration Test 1／1 通過。

本機仍為 Windows，無法執行 Xcode；上述結論來自實際 macOS Simulator 執行證據，不是以 Web build 代替。

## TestFlight Build 57 發布結果

- GitHub Actions Release Run [29551119177](https://github.com/zli426491-byte/ai-love-keyboard/actions/runs/29551119177) 完整通過。
- 發布前重新執行 Flutter、對話、UI、iOS Simulator 與 Integration Tests，全部通過。
- App Store Connect 原最高 Build 為 56，流程自動設定新 Build 為 57。
- IPA 版本為 1.0.4（57）。
- 主 App Bundle ID：`com.ailovekeyboard.app`。
- 鍵盤擴充 Bundle ID：`com.ailovekeyboard.app.keyboard`。
- Apple 上傳工具回報零錯誤。
- App Store Connect API 回讀：Build 57 為 `VALID`，且已出現在 `Internal Testing` 群組。
- 本次沒有真實扣款、沒有送 App Review，也沒有更換 1.0.4 目前綁定的 Build。

## App Store Connect 資料修正

- 1.0.4 的 12 個語系已填入各語系 App 描述與版本更新內容。
- 描述已明確說明需要 LoveKey 帳號、AI 生成功能需要 Pro，以及週／年／永久三種 App 內購買方式。
- 更新前資料已保存於本機 QA artifact，更新後已透過 App Store Connect API 回讀逐欄驗證。
- 尚未自動提交 App Review，也尚未更換 1.0.4 綁定 Build。

## 下一個發布門檻

1. 使用實體 iPhone 從 TestFlight 全新安裝 Build 57。
2. 完成第三方鍵盤、登入、AI 生成／填入、斷網恢復與多 App 測試。
3. 使用 Apple Sandbox 完成週、年、永久商品、取消與恢復購買驗收；不得真實扣款。
4. 實機全通過後才將 App Store 1.0.4 改綁 Build 57，連同三項 IAP 一起送審。
5. 人工核准並合併發布流程 Pull Request，避免預設分支繼續使用舊的自動發布規則。
