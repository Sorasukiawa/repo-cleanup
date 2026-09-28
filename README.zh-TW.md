# repo-cleanup

[简体中文](README.md) · [繁體中文](README.zh-TW.md) · [English](README.en.md) · [日本語](README.ja.md)

為 AI 程式開發助手設計的輕量儲存庫整理 skill：清理無用快取、妥善退役閒置工作樹，並按需檢查與整理 README / AGENTS 等專案文件。

保留有效成果，讓文件準確、容易查找、能指導操作；需要釋放空間時清理無用占用。已有授權不重複確認，驗證範圍配合實際變更。

## 安裝

使用 [skills CLI](https://github.com/vercel-labs/skills)，安裝至 Codex 個人技能目錄：

```bash
npx skills add Sorasukiawa/repo-cleanup --skill repo-cleanup --agent codex --global
```

也可下載儲存庫，將 `SKILL.md`、`references/` 和 `agents/` 放入個人技能目錄的 `repo-cleanup/`。若已有同名 skill，請先核對來源與個人修改。

## 使用

```text
使用 $repo-cleanup 按本次目標整理目前的儲存庫，檢查 README 和 AGENTS，修正有明確依據的問題，合適的內容保持原樣。
```

僅檢查：`使用 $repo-cleanup 只做盤點，不修改檔案。`

也可限定為「只清理編譯快取」「只精簡 AGENTS」「收尾已合併的工作樹，保留分支」。

## Windows

提供原生 PowerShell 5.1 / 7、Git Bash 與 WSL 的[適配指引](references/windows.md)，涵蓋特殊字元路徑、目錄連接、檔案占用及 Git 結束代碼。無須為了使用 skill 安裝 WSL；安裝指令不變，使用 `npx` 需要 Node.js。

已核對官方文件並進行情境審查，尚未完成 Windows 實機驗證。

## 運作方式

- 根據引用與用途區分原始碼、快取、交付檔案及歷史資料；忽略規則和檔案年齡不直接決定刪除。
- 先核對工作樹是否仍在使用或適合重用；Codex 管理的工作樹使用原生封存，一般 Git 工作樹保存獨有成果後移除。需要核驗合併時，涵蓋 squash 合併、後續提交與 detached HEAD。
- 文件以準確、易用為目標，精簡僅是按需手段；合適的內容保持原樣，缺失的資訊可以補充。README 服務讀者，AGENTS 保留專案決策所需的長期約定，階段安排放入進度文件。
- 遵循目標儲存庫的提交慣例；本機整理不自動擴及遠端刪除或議題更新。
- 釋放空間時分別回報目錄占用減少量與磁碟可用空間增量；僅整理文件無須掃描整個儲存庫的空間，驗證配合實際變更。

[SKILL.md](SKILL.md) 是唯一的英文執行入口；涉及工作樹或分支退役時讀取[工作樹參考](references/worktrees.md)。助手依使用者語言溝通與撰寫報告，未指定時預設使用簡體中文。四語 README 協助讀者上手，無須同時載入。

這是流程指南，沒有安裝掛鉤或自動刪除程式。已在 Codex 完成格式檢查、隔離儲存庫的執行與唯讀情境驗證，以及合併可達性、detached 提交、squash 合併、後續提交、ignored 檔案和無效參照等 Git 情境檢查；尚未驗證所有助手、作業系統或儲存庫配置。歡迎透過 Issues 提供可重現案例。

本次文件與封存流程更新完成了格式、內部連結及檔案一致性檢查，尚未實測 Codex 管理的工作樹封存與還原。

## 參考與授權

文件整理思路參考 [agent-md-refactor](https://github.com/softaworks/agent-toolkit/tree/main/skills/agent-md-refactor)，工作樹流程對照 [cleanup-repo](https://github.com/rheged-studio/agent-skills/tree/main/skills/cleanup-repo) 及參考文件中的 Git / GitHub CLI 官方說明。本專案獨立維護。

[MIT](LICENSE) © 2026 Sorasukiawa.
