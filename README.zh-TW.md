# repo-cleanup

[简体中文](README.md) · [繁體中文](README.zh-TW.md) · [English](README.en.md) · [日本語](README.ja.md)

為 AI 程式開發助手設計的輕量儲存庫整理 skill：清理無用快取、收尾已完成的工作樹、修正過時說明，並精簡 README / AGENTS。

減少磁碟占用與上下文負擔，保留有效成果。已有授權不重複確認，驗證範圍配合實際變更。

## 安裝

使用 [skills CLI](https://github.com/vercel-labs/skills)，安裝至 Codex 個人技能目錄：

```bash
npx skills add Sorasukiawa/repo-cleanup --skill repo-cleanup --agent codex --global
```

也可下載儲存庫，將 `SKILL.md`、`references/` 和 `agents/` 放入個人技能目錄的 `repo-cleanup/`。若已有同名 skill，請先核對來源與個人修改。

## 使用

```text
使用 $repo-cleanup 清理並整理目前的儲存庫，修正過時說明並精簡 README 和 AGENTS。
```

僅檢查：`使用 $repo-cleanup 只做盤點，不修改檔案。`

也可限定為「只清理編譯快取」「只精簡 AGENTS」「收尾已合併的工作樹，保留分支」。

## 運作方式

- 根據引用與用途區分原始碼、快取、交付檔案及歷史資料；忽略規則和檔案年齡不直接決定刪除。
- 核對工作樹的合併狀態與獨有檔案，涵蓋 squash 合併、後續提交與 detached HEAD。
- 文件依保留、移轉、封存、刪除或合併處理，不設定固定刪減比例。
- 遵循目標儲存庫的提交慣例；本機整理不自動擴及遠端刪除或議題更新。
- 分別回報目錄占用減少量、磁碟可用空間增量，以及實際驗證結果。

[SKILL.md](SKILL.md) 是唯一的英文執行入口；[工作樹參考](references/worktrees.md) 按需讀取。助手依使用者語言溝通與撰寫報告，未指定時預設使用簡體中文。四語 README 協助讀者上手，無須同時載入。

這是流程指南，沒有安裝掛鉤或自動刪除程式。已在 Codex 完成格式檢查、隔離儲存庫的執行與唯讀情境驗證，以及合併可達性、detached 提交、squash 合併、後續提交、ignored 檔案和無效參照等 Git 情境檢查；尚未驗證所有助手、作業系統或儲存庫配置。歡迎透過 Issues 提供可重現案例。

## 參考與授權

文件整理思路參考 [agent-md-refactor](https://github.com/softaworks/agent-toolkit/tree/main/skills/agent-md-refactor)，工作樹流程對照 [cleanup-repo](https://github.com/rheged-studio/agent-skills/tree/main/skills/cleanup-repo) 及參考文件中的 Git / GitHub CLI 官方說明。本專案獨立維護。

[MIT](LICENSE) © 2026 Sorasukiawa.
