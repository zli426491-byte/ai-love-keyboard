# LoveKey 1.0.4 App Review 備註草稿

## 使用方式

這份文件是送審前草稿，不含帳號密碼。建立專用審核帳號並完成 Build 57 實機／Apple Sandbox 驗收後，再把下方英文內容貼到 App Store Connect 的 App Review Notes。

請勿把帳號密碼寫入 Git、這份文件或公開客服信箱。

## 送審前人工填寫

- Demo 帳號 Email：`<APP_REVIEW_DEMO_EMAIL>`
- Demo 帳號密碼：只填 App Store Connect，不寫入本檔
- 指定 Build：57
- 測試裝置與 iOS：`<REAL_DEVICE_AND_IOS_VERSION>`
- Sandbox 週／年／永久與恢復購買：`<PASS／FAIL>`

## 建議貼給 Apple 的英文內容

```text
Thank you for reviewing LoveKey 1.0.4 (Build 57).

LoveKey helps users create one suggested reply from text they intentionally copy from a conversation. The AI reply feature requires a LoveKey account, an active Pro entitlement, and network access.

Demo account:
Email: <APP_REVIEW_DEMO_EMAIL>
Password: <ENTER_ONLY_IN_APP_STORE_CONNECT>

How to test the main app:
1. Launch LoveKey and sign in with the demo account.
2. On the Home screen, paste a sample message into the reply field.
3. Select a reply mode and tone.
4. Tap the button to generate one reply.
5. The Pro paywall can be opened from the crown/Pro entry on the Home screen or from the Profile tab.

How to enable and test the keyboard extension:
1. Open iOS Settings > General > Keyboard > Keyboards > Add New Keyboard.
2. Select "AI 戀愛鍵盤" (LoveKey).
3. Open the LoveKey keyboard entry and enable "Allow Full Access". Full Access is required for the keyboard to contact the LoveKey service and read text the user has intentionally copied.
4. Open Messages or another chat app and long-press the globe key to select the LoveKey keyboard.
5. Copy a test message in the chat app.
6. Return to the input field, open LoveKey, select a mode and tone, then generate one suggested reply.
7. Tap the insert/fill action to place the suggestion into the chat input field. The user can edit it before sending. LoveKey never sends a message automatically.

In-App Purchases:
- Weekly subscription: com.ailovekeyboard.pro.weekly
- Yearly subscription: com.ailovekeyboard.pro.yearly
- Lifetime non-consumable: com.ailovekeyboard.pro.lifetime

All purchases use Apple's In-App Purchase system. Prices are loaded from the App Store for the reviewer's storefront. The Restore Purchases action is available on the Pro paywall.

Privacy note:
LoveKey only processes text the user chooses to paste or copy for the purpose of generating a reply. The app does not send messages automatically. Account deletion is available from the LoveKey account screen.

If the keyboard cannot access the network, please confirm that "Allow Full Access" is enabled and that the demo account is signed in inside the main LoveKey app.
```

## 送審前檢查

- [ ] Demo 帳號可登入且不需要一次性驗證碼。
- [ ] Demo 帳號具備審核所需 Pro 權益，或 Apple Sandbox 可順利購買。
- [ ] 英文路徑與 Build 57 實際畫面一致。
- [ ] 帳號刪除入口可用。
- [ ] 隱私權標籤與「剪貼簿文字、AI 處理、帳號、購買」實際資料流一致。
- [ ] App Store Connect 只填必要帳密，不把 Secret 或正式使用者資料交給審核。
