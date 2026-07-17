# LoveKey TestFlight Build 55／56 專項稽核（2026-07-17）

## 結論

你在 TestFlight 看到 Build 56 是正確的。Build 56 已進入「內部測試」，但它不是 Build 55 的後續修正版，而是從另一條較舊的 `master` 程式線自動產生。Build 56 缺少 Build 55 已完成的 P0 登入、鍵盤授權與後端強化，因此不可拿來做最終驗收，也不可綁定 1.0.4 送審。

目前最安全的做法不是改回 Build 55 送審，而是從已完整 QA 的程式線產生 Build 57，再做一次 TestFlight 實機與 Apple Sandbox 驗收。

## Apple 官方狀態

以下狀態由 App Store Connect API 唯讀查詢確認：

| 項目 | 狀態 | 判定 |
| --- | --- | --- |
| TestFlight 最新 Build | 56，VALID | 已在內部測試，可供內部測試員看到與下載 |
| Build 56 內部測試 | IN_BETA_TESTING | 已啟用 |
| Build 56 外部測試 | READY_FOR_BETA_SUBMISSION | 尚未確認通過外部 Beta Review |
| App Store 1.0.4 綁定 Build | 55，VALID | Build 56 並未取代它 |
| App Store 1.0.4 | PREPARE_FOR_SUBMISSION | 尚未正式送審 |
| 公開版本 | 1.0.2，READY_FOR_SALE | 目前商店使用者下載到的仍是 1.0.2 |
| 週／年／永久商品 | READY_TO_SUBMIT | 尚未與 1.0.4 一起送審 |

## Build 來源與差異

### Build 55

- GitHub Actions Run：`29393032911`
- Git commit：`baea678cff178e2b0f6c3cb98a3033b548141b26`
- 來源分支：`agent/p0-release-validation`
- 包含：帳號服務、Email／Google／Apple 登入、鍵盤 access token 同步、RevenueCat 使用者同步、Worker 安全強化及相關測試。
- 已綁定 App Store 1.0.4，但不是最後一次完整 QA 所測的精確 commit。

### Build 56

- GitHub Actions Run：`29402123801`
- Git commit：`a28428d680708aed9897a51e7c4c436d7e35087c`
- 來源分支：`master`
- 觸發原因：推送「Publish LoveKey terms and usage guide」文件 commit 後，release workflow 自動執行。
- Build 號較大不代表功能較新；它與 Build 55 是平行分支，並非 Build 55 的後續版本。
- 相對 Build 55 缺少多項 P0 程式與測試，不能視為升級版。

## 核心 AI 鍵盤阻塞

正式 Proxy `POST /v1/keyboard-reply` 已要求請求 metadata，缺少時會回傳：

```text
401 {"error":"request_metadata_required"}
```

Build 56 的 iOS 鍵盤擴充實際請求只有 `X-Device-Fingerprint`，沒有送出：

- `X-Request-Timestamp`
- `X-Request-Nonce`
- `X-Request-Signature`
- `Authorization: Bearer ...`

因此 Build 56 即使可以安裝與開啟，核心 AI 鍵盤請求仍會在正式 Proxy 驗證階段被拒絕。主 App 內存在簽章 helper 不能補救鍵盤擴充，因為實際發送鍵盤請求的是 `KeyboardViewController.swift`。

## 完整 QA 實際驗證的版本

完整 Codemagic QA 驗證的是：

- Commit：`68804aad1d0555ffbda98532aa74b5b5a320e14c`
- 分支：`qa/ios-autonomous-qa`
- Draft PR：[#2](https://github.com/zli426491-byte/ai-love-keyboard/pull/2)
- `flutter analyze`：0 問題
- Flutter 測試：27／27
- 對話邏輯：14／14
- UI 專項：11／11
- Integration Test：1／1
- iOS Simulator：build、安裝、啟動通過

此 commit 位於 Build 55 的 P0 程式線上，並包含後續 QA 修復；它既不是 Build 55，也不是 Build 56，目前尚未上傳 TestFlight。

## 發布決策

1. 不以 Build 56 做最終驗收或送審。
2. 暫時不要提交 App Store 1.0.4，也不要開始付費買量。
3. 將 QA 修復整理回 P0 發布線，重跑完整 QA 後產生 Build 57。
4. Build 57 上傳後，以實體 iPhone 驗證登入、第三方鍵盤、AI 生成／填入、週／年／永久商品、Sandbox 購買與恢復購買。
5. 實機通過後，才把 App Store 1.0.4 綁定改為 Build 57 並提交 IAP 與版本審核。
6. release workflow 已在 QA 分支修正：文件 push 不再自動發布 TestFlight，且 release 前必須通過 analyze、tests、iOS Simulator QA、P0 契約與 IPA metadata gate。

## 可追溯證據

- [Build 55 GitHub Actions](https://github.com/zli426491-byte/ai-love-keyboard/actions/runs/29393032911)
- [Build 56 GitHub Actions](https://github.com/zli426491-byte/ai-love-keyboard/actions/runs/29402123801)
- [完整 QA Draft PR #2](https://github.com/zli426491-byte/ai-love-keyboard/pull/2)
