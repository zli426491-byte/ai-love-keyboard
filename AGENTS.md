# LoveKey QA Rules

- Before editing, record `git status` and work on an isolated branch or worktree. Never overwrite unrelated local changes.
- After code changes, run `flutter analyze`, `flutter test`, `scripts/dialogue_eval.sh`, and `scripts/ui_audit.sh`. Native iOS changes also require `scripts/ios_qa.sh` on macOS or the `ios-qa` workflow.
- Never report a test as passed unless its command actually ran. State `未執行 iOS Simulator 測試` when Xcode and Simulator were not used.
- Never perform a real purchase, alter production users/data, or commit credentials. Purchase checks use StoreKit, Apple Sandbox, RevenueCat test data, or mocks only.
- UI fixes may address overflow, clipping, scrolling, accessibility, state feedback, and clear design-system inconsistencies. Do not redesign the product, brand, navigation, or pricing without explicit approval.
- Bug records must include severity, reproduction, expected/actual behavior, evidence, root cause, changed files, regression test, result, and status.
- Keep QA work reviewable in independent commits or a pull request. Do not merge to `main` or `master` automatically.
- 所有人類可讀的 QA、上線、阻塞與進度報告一律使用繁體中文。英文只保留無法翻譯的指令、API 欄位、程式識別碼與平台原始狀態。
