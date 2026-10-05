# repo-cleanup

[简体中文](README.md) · [繁體中文](README.zh-TW.md) · [English](README.en.md) · [日本語](README.ja.md)

> 本譯文以簡體中文版為準，更新可能稍有落後。

為 AI 程式開發助手設計的輕量儲存庫整理 skill：清理無用快取、妥善退役閒置工作樹與已合併分支，並按需檢查與整理 README / AGENTS / CLAUDE.md 等專案文件。

保留有效成果，讓文件準確、容易查找、能指導操作；需要釋放空間時清理無用占用。已有授權不重複確認，驗證範圍配合實際變更。

## 安裝

### Claude Code 外掛

```bash
claude plugin marketplace add Sorasukiawa/repo-cleanup
```

```bash
claude plugin install repo-cleanup@repo-cleanup
```

在工作階段中也可以使用 `/plugin marketplace add Sorasukiawa/repo-cleanup` 和 `/plugin install repo-cleanup@repo-cleanup`。之後更新請先執行 `claude plugin marketplace update repo-cleanup`，再執行 `claude plugin update repo-cleanup@repo-cleanup`。

### skills CLI（Codex 或 Claude Code）

使用 [skills CLI](https://github.com/vercel-labs/skills) 安裝至個人技能目錄：

```bash
npx skills add Sorasukiawa/repo-cleanup --skill repo-cleanup --agent codex --global
```

```bash
npx skills add Sorasukiawa/repo-cleanup --skill repo-cleanup --agent claude-code --global
```

在 Claude Code 中，外掛與 skills CLI 擇一即可，同時安裝會出現兩個同名 skill。

### 手動安裝

也可下載儲存庫，將 `SKILL.md`、`references/`、`scripts/` 和 `agents/` 放入個人技能目錄（Codex 為 `~/.agents/skills/`，`~/.codex/skills/` 也會被讀取；Claude Code 為 `~/.claude/skills/`）的 `repo-cleanup/`。`tests/` 和 `evals/` 僅供維護使用。若已有同名 skill，請先核對來源與個人修改。

## 使用

Codex 使用 `$repo-cleanup`；Claude Code 使用 `/repo-cleanup`（以外掛安裝時完整名稱為 `/repo-cleanup:repo-cleanup`，沒有重名時可直接使用 `/repo-cleanup`），並可附帶範圍，例如 `/repo-cleanup 只做盤點`。也可以直接描述需求：

```text
使用 $repo-cleanup 按本次目標整理目前的儲存庫，檢查 README 和 AGENTS，修正有明確依據的問題，合適的內容保持原樣。
```

僅檢查：`使用 $repo-cleanup 只做盤點，不修改檔案。`

也可限定為「只清理編譯快取」「只精簡 AGENTS」「收尾已合併的工作樹，保留分支」「刪除已合併的本機分支，遠端不動」。

## 運作方式

- 先判斷模式：僅盤點時完全唯讀（不 fetch、不建置、不刪改）；執行時在授權範圍內自主完成，待定事項最後合併成一次提問。
- 依任務只讀取需要的參考：空間清理、工作樹與分支、宿主管理的工作樹、文件、Windows。
- 根據引用與用途區分原始碼、快取、本機機密、交付檔案及歷史資料；忽略規則和檔案年齡不直接決定刪除。SKILL.md 的「常見誤判」表列出最容易誤刪的情況，例如 `git worktree remove` 會連帶刪除 ignored 的 `.env`。
- 依能否重新產生來判斷：獨有提交、未提交變更、機密與本機設定、使用者製作的素材、唯一的發布包保留；建置、安裝或產生器能重建的內容，即使被測試工程引用也列為候選，並寫明重建方式與刪除影響。≥1 GiB 的項目與體積前十的項目不論結論都會出現在報告中，依判斷保留的大項交由你決定，狀態標為 PENDING。
- 工作樹退役先通過門檻檢查（使用中、已鎖定、宿主管理、未保存的變更或 ignored 檔案），再看合併證據：一般合併、squash 合併（本機 tip 必須等於 PR 的 `headRefOid`）、detached HEAD。Codex 管理的工作樹使用原生封存，Claude Code 與桌面版的工作樹優先交由宿主處理。
- 分支預設保留；刪除時 `-d` 與 `-D` 各有條件，並記錄 `name sha` 以便還原。`[gone]` 只是線索。遠端與議題不會自動變更。
- 文件以準確、易用為目標，精簡僅是按需手段。README 服務讀者，AGENTS / CLAUDE.md 保留專案決策所需的長期約定，階段安排放入進度文件。
- 在 Claude Code 中，盤點腳本與唯讀的 git、`du`、`df` 查詢已透過 `allowed-tools` 預先授權，盤點時不會逐條跳出權限確認；刪除、移除、推送類指令不在其中。
- 報告先給決策表（項目｜類型｜證據｜大小｜建議或結果），結尾標明 DONE 或 PENDING。釋放空間時，分別回報目錄占用減少量與磁碟可用空間增量。

`scripts/survey.sh` 可一次唯讀盤點所有工作樹、本機分支、忽略檔案（加上 `--sizes` 時依體積由大到小排列），以及儲存庫外的專案產物（自訂 Cargo target 目錄、依任務產生的建置目錄、本專案的 Xcode DerivedData）：

```bash
bash ~/.agents/skills/repo-cleanup/scripts/survey.sh --repo . --base main --sizes
```

上面是 skills CLI 安裝至 Codex 時的路徑；安裝在 `~/.codex/skills/` 或 `~/.claude/skills/` 時請換成對應目錄。以外掛安裝時，skill 會自動提供腳本的完整路徑。`--base` 必須明確指定，腳本不會猜測目標分支。其輸出只是證據，最終判斷仍依 skill 規則。

## 檔案結構

| 路徑 | 用途 |
| --- | --- |
| `SKILL.md` | 英文執行入口：模式、路由、用途分類、常見誤判、報告格式 |
| `.claude-plugin/` | Claude Code 外掛與 marketplace 清單；儲存庫根目錄即外掛，`SKILL.md` 是其中唯一的 skill |
| `agents/openai.yaml` | Codex 介面中的顯示名稱、簡介與預設提示 |
| `references/space.md` | 清理範圍（含儲存庫外的專案產物）、各生態速查、測試產生資料、空間統計 |
| `references/worktrees.md` | 工作樹與分支退役：門檻、合併證據、決策表、分支刪除 |
| `references/hosts.md` | Codex、Claude Code、Claude 桌面版管理的工作樹 |
| `references/docs.md` | README、AGENTS、CLAUDE.md 等文件與規則整理 |
| `references/windows.md` | 原生 PowerShell、Git Bash、WSL 適配 |
| `scripts/survey.sh` | 唯讀盤點腳本 |
| `tests/`、`evals/` | 測試夾具、回歸測試、行為與觸發評估 |

助手依使用者語言溝通與撰寫報告，未指定時預設使用簡體中文。四語 README 協助讀者上手，無須同時載入。

## 不做什麼

- 不包含自動刪除程式或安裝掛鉤；`survey.sh` 為唯讀。
- 不清理與專案無關的共用快取（npm / pnpm 全域快取、cargo registry、Docker、模擬器執行環境等），也不維護已安裝的 agent 工具或 skill。專案自己放在儲存庫外的建置產物在清理範圍內。
- 不預設刪除遠端分支或修改 PR / 議題狀態。
- 不為縮短篇幅而刪除有用的文件內容。

## Windows

提供原生 PowerShell 5.1 / 7、Git Bash 與 WSL 的[適配指引](references/windows.md)，涵蓋特殊字元路徑、目錄連接、檔案占用及 Git 結束代碼。`survey.sh` 可在 Git Bash 或 WSL 執行；原生 PowerShell 請使用指引中的指令。無須為了使用 skill 安裝 WSL，使用 `npx` 需要 Node.js。

## 測試與驗證

```bash
bash tests/check-skill.sh
```

```bash
bash tests/test-survey.sh
```

`check-skill.sh` 檢查 frontmatter、行數、連結、版本號（SKILL.md、plugin.json、CHANGELOG 三處一致）、JSON 檔案與關鍵安全規則；設定 `CLAUDE_BIN` 或 PATH 中有 `claude` 時，也會執行官方的 `claude plugin validate --strict`。`test-survey.sh` 在暫存目錄產生含 11 種情境的夾具儲存庫，驗證盤點腳本的輸出與唯讀性，以及參考文件所依賴的 Git 行為。`evals/evals.json` 是以 agent 執行的行為案例，`evals/trigger-evals.json` 是觸發評估查詢，格式與 [skill-creator](https://github.com/anthropics/skills/tree/main/skills/skill-creator) 相容（並非 `claude plugin eval` 的格式）。

各版本的變更與驗證程度請見 [CHANGELOG.md](CHANGELOG.md)。歡迎透過 Issues 提供可重現案例。

## 參考與授權

文件整理思路參考 [agent-md-refactor](https://github.com/softaworks/agent-toolkit/tree/main/skills/agent-md-refactor) 與 [claude-md-improver](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/claude-md-management)。工作樹流程對照 [cleanup-repo](https://github.com/rheged-studio/agent-skills/tree/main/skills/cleanup-repo)、[pd:cleanup](https://github.com/peterdrier/skills/tree/main/plugins/pd/skills/cleanup)、[superpowers](https://github.com/obra/superpowers) 的 finishing-a-development-branch，以及參考文件中的 Git / GitHub CLI / Claude Code 官方說明。測試方式參考 [skill-creator](https://github.com/anthropics/skills/tree/main/skills/skill-creator) 與 superpowers 的 writing-skills。本專案獨立維護。

[MIT](LICENSE) © 2026 Sorasukiawa.
