# LoveKey 上線前狀態（2026-07-12）

## 已完成

- Cloudflare Worker `lovekey-proxy` 已部署；目前已設定 `OPENAI_API_KEY`、`REVENUECAT_SECRET_API_KEY`、`SUPABASE_URL`、`SUPABASE_ANON_KEY`、`SUPABASE_SERVICE_ROLE_KEY`。
- GitHub Actions 必要 Secrets 已設定：iOS signing/App Store Connect、Android 四個 signing secrets、`AI_PROXY_URL`、兩平台 RevenueCat public key、Supabase URL/anon key。
- Google Play Console 已建立 `LoveKey AI 戀愛鍵盤`（`com.ailovekeyboard.app`）。RevenueCat service account 已加入，狀態為有效且永不過期，並授予官方要求的三項帳戶權限。
- Worker 使用 Supabase Auth 與 RevenueCat entitlement 做伺服器端驗證；不信任 client 傳入的 `is_pro`。
- `flutter analyze`、Flutter tests、敏感金鑰掃描與 Worker dry-run 已通過。

## 目前阻斷項

1. 本機工作樹仍有本輪程式、CI 與文件修改尚未 commit/push；最新成功 CI build 尚未包含這批最終修改。
2. 已修正 `tools/verify_lovekey_release.ps1` 的舊版 entitlement 誤報，需重新跑完整驗證。
3. 需以最新 commit 重新執行 iOS／Android GitHub Actions，產生最終 IPA／AAB。
4. Android AAB 尚未上傳到 Play Console 內部／封閉測試軌，尚未完成 Android 實機購買與恢復購買。
5. RevenueCat Google Play 憑證可能仍在同步（通常 24–36 小時）；需確認三個產品與 `pro` entitlement，以及 Google Real-time Developer Notifications。
6. 尚未完成最新 iOS TestFlight 與 Android 實機驗收：鍵盤完整取用、LINE／IG／iMessage、週／年／永久購買、刪除重裝後恢復購買。
7. App Attest／Play Integrity 尚未接入 Worker；在大額買量前必須完成，不能以可偽造 client header 取代。

## 解鎖順序

```text
修正驗證腳本
→ 完整驗證
→ commit/push 本輪修改
→ 重新產生 iOS IPA／Android AAB
→ TestFlight／Play 內部或封閉測試實機驗收
→ 確認 RevenueCat／RTDN
→ 接入 App Attest／Play Integrity
→ 才批准買量
```

## 安全提醒

`SUPABASE_SERVICE_ROLE_KEY` 與 RevenueCat Secret API key 只放在 Cloudflare Worker secret，不要放進 GitHub Secrets、App 或商店建置參數。
