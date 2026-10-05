# repo-cleanup

[简体中文](README.md) · [繁體中文](README.zh-TW.md) · [English](README.en.md) · [日本語](README.ja.md)

面向 AI 编程助手的轻量仓库整理 skill：清理无用缓存、妥善退役闲置工作区和已合并分支，并按需检查与整理 README / AGENTS / CLAUDE.md 等项目文档。

保留有效成果，让文档准确、易查找、能指导操作；需要释放空间时清理无用占用。已有授权不重复确认，验证规模与改动相称。

## 安装

### Claude Code 插件

```bash
claude plugin marketplace add Sorasukiawa/repo-cleanup
```

```bash
claude plugin install repo-cleanup@repo-cleanup
```

会话里也可以用 `/plugin marketplace add Sorasukiawa/repo-cleanup` 和 `/plugin install repo-cleanup@repo-cleanup`。之后更新先运行 `claude plugin marketplace update repo-cleanup`，再运行 `claude plugin update repo-cleanup@repo-cleanup`。

### skills CLI（Codex 或 Claude Code）

使用 [skills CLI](https://github.com/vercel-labs/skills) 安装到个人技能目录：

```bash
npx skills add Sorasukiawa/repo-cleanup --skill repo-cleanup --agent codex --global
```

```bash
npx skills add Sorasukiawa/repo-cleanup --skill repo-cleanup --agent claude-code --global
```

插件和 skills CLI 在 Claude Code 中二选一即可，同时安装会出现两个同名 skill。

### 手动安装

也可下载仓库，将 `SKILL.md`、`references/`、`scripts/` 和 `agents/` 放入个人技能目录（Codex 为 `~/.codex/skills/`，Claude Code 为 `~/.claude/skills/`）的 `repo-cleanup/` 下。`tests/` 和 `evals/` 只用于维护，可以不放。已有同名 skill 时，先核对来源和个人修改。

## 使用

Codex 用 `$repo-cleanup`；Claude Code 用 `/repo-cleanup`（插件安装时完整名称是 `/repo-cleanup:repo-cleanup`，没有重名时可直接用 `/repo-cleanup`），并可附带范围，例如 `/repo-cleanup 只做盘点`。也可以直接描述需求：

```text
使用 $repo-cleanup 按本次目标整理当前仓库，检查 README 和 AGENTS，修正确有依据的问题，合适的内容保持原样。
```

只检查：`使用 $repo-cleanup 只做盘点，不修改文件。`

也可限定为“只清理编译缓存”“只精简 AGENTS”“收尾已合并工作区，保留分支”“删除已合并的本地分支，远端不动”。

## 工作方式

- 先判断模式：只盘点时完全只读（不 fetch、不构建、不删改）；执行时在授权范围内自主完成，待定事项最后合并成一次提问。
- 按任务只读取需要的参考：空间清理、工作区与分支、宿主托管工作区、文档、Windows。
- 根据引用和用途区分源码、缓存、本地机密、交付件与历史资料；忽略规则和文件年龄不直接决定删除。SKILL.md 中的「常见误判」表列出了最容易误删的情况，例如 `git worktree remove` 会连带删除 ignored 的 `.env`。
- 工作区退役先过门槛检查（在用、锁定、宿主托管、未保存的改动或 ignored 文件），再看合并证据：普通合并、squash 合并（本地 tip 必须等于 PR 的 `headRefOid`）、detached HEAD。Codex 托管工作区使用原生归档，Claude Code 和桌面端工作区优先交给宿主处理。
- 分支默认保留；删除时 `-d` 和 `-D` 各有条件，并记录 `name sha` 以便恢复。`[gone]` 只是线索。远端和工单不会自动改动。
- 文档以准确、易用为目标，精简只是可选手段。README 服务读者，AGENTS / CLAUDE.md 保留项目决策需要的长期约定，阶段安排放入进度文档。
- 在 Claude Code 中，盘点脚本和只读的 git、`du`、`df` 查询已通过 `allowed-tools` 预先授权，盘点时不会逐条弹出权限确认；删除、移除、推送类命令不在其中。
- 报告先给决策表（项目｜类型｜证据｜大小｜建议或结果），结尾标明 DONE 或 PENDING。释放空间时，目录占用减少与磁盘空闲增长分开报告。

`scripts/survey.sh` 可以一次性只读盘点所有 worktree 和本地分支：

```bash
bash ~/.codex/skills/repo-cleanup/scripts/survey.sh --repo . --base main --sizes
```

通过 skills CLI 装到 Claude Code 时路径为 `~/.claude/skills/repo-cleanup/scripts/survey.sh`；以插件安装时，skill 会自动给出脚本的完整路径。`--base` 必须明确指定，脚本不会猜测目标分支。它的输出只是证据，最终判断仍按 skill 规则进行。

## 文件结构

| 路径 | 作用 |
| --- | --- |
| `SKILL.md` | 英文执行入口：模式、路由、用途分类、常见误判、报告格式 |
| `.claude-plugin/` | Claude Code 插件与 marketplace 清单；仓库根目录就是插件，`SKILL.md` 是其中唯一的 skill |
| `agents/openai.yaml` | Codex 界面中的显示名称、简介和默认提示 |
| `references/space.md` | 缓存与构建产物清理、各生态速查、空间统计 |
| `references/worktrees.md` | 工作区与分支退役：门槛、合并证据、决策表、分支删除 |
| `references/hosts.md` | Codex、Claude Code、Claude 桌面端托管的工作区 |
| `references/docs.md` | README、AGENTS、CLAUDE.md 等文档与规则整理 |
| `references/windows.md` | 原生 PowerShell、Git Bash、WSL 适配 |
| `scripts/survey.sh` | 只读盘点脚本 |
| `tests/`、`evals/` | 夹具、回归测试、行为与触发评估 |

助手按用户语言交流和输出报告，未指定时默认简体中文。四语言 README 帮助读者上手，无需同时加载。

## 不做什么

- 不包含自动删除程序或安装钩子；`survey.sh` 只读。
- 不清理仓库外的缓存（Xcode DerivedData、npm / pnpm 全局缓存、Docker 等），也不维护已安装的 agent 工具或 skill。
- 不默认删除远端分支、修改 PR 或工单状态。
- 不为了缩短篇幅而删除有用的文档内容。

## Windows

提供原生 PowerShell 5.1 / 7、Git Bash 和 WSL 的[适配指引](references/windows.md)，涵盖特殊字符路径、目录联接、文件占用及 Git 退出码。`survey.sh` 可在 Git Bash 或 WSL 中运行；原生 PowerShell 使用指引中的命令。无需为了使用 skill 安装 WSL，使用 `npx` 需要 Node.js。

## 测试与验证

```bash
bash tests/check-skill.sh
```

```bash
bash tests/test-survey.sh
```

`check-skill.sh` 检查 frontmatter、行数、链接、版本号（SKILL.md、plugin.json、CHANGELOG 三处一致）、JSON 文件和关键安全规则；设置 `CLAUDE_BIN` 或 PATH 中有 `claude` 时，还会运行官方的 `claude plugin validate --strict`。`test-survey.sh` 在临时目录生成 11 种场景的夹具仓库，验证盘点脚本的输出和只读性，以及参考文档所依赖的 Git 行为。`evals/evals.json` 是用 agent 运行的行为用例，`evals/trigger-evals.json` 是触发评估查询，格式与 [skill-creator](https://github.com/anthropics/skills/tree/main/skills/skill-creator) 兼容（不是 `claude plugin eval` 的格式）。

各版本改了什么、验证到什么程度，见 [CHANGELOG.md](CHANGELOG.md)。欢迎通过 Issues 提供可复现案例。

## 参考与许可

文档整理思路参考 [agent-md-refactor](https://github.com/softaworks/agent-toolkit/tree/main/skills/agent-md-refactor) 和 [claude-md-improver](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/claude-md-management)。工作区流程对照了 [cleanup-repo](https://github.com/rheged-studio/agent-skills/tree/main/skills/cleanup-repo)、[pd:cleanup](https://github.com/peterdrier/skills/tree/main/plugins/pd/skills/cleanup)、[superpowers](https://github.com/obra/superpowers) 的 finishing-a-development-branch，以及参考文档中的 Git / GitHub CLI / Claude Code 官方说明。测试方式参考 [skill-creator](https://github.com/anthropics/skills/tree/main/skills/skill-creator) 和 superpowers 的 writing-skills。本项目独立维护。

[MIT](LICENSE) © 2026 Sorasukiawa.
