# 更新记录

版本号写在 `SKILL.md` 的 `metadata.version`，与本文件最上面的条目保持一致（`tests/check-skill.sh` 会检查）。

## 1.1.0 — 2026-10-05

### 结构

- `SKILL.md` 改为路由入口：模式判断、按任务读取的参考表、用途分类、常见误判表、报告格式、验证与交付。
- 拆出 `references/space.md`（空间清理）、`references/docs.md`（文档与规则整理）、`references/hosts.md`（宿主托管工作区）。纯文档任务不再读工作区和空间规则，反之亦然。
- Codex 原生归档流程从 `worktrees.md` 移入 `hosts.md`，内容不变；新增 Claude Code 和 Claude 桌面端工作区的处理方式。
- 原先散落在多个文件的“X 不等于 Y”提醒，集中为 `SKILL.md` 中的「Common Misjudgments」表。

### 新增

- `scripts/survey.sh`：只读盘点脚本，一次输出全部 worktree（ref、HEAD、锁定和 prunable 标记、改动数、未跟踪数、ignored 条目数、领先提交数、是否已包含在目标中）、折叠后的 ignored 条目，以及本地分支的上游状态（含 `[gone]`）。它不 fetch、不写入，也不猜测目标分支；中文等非 ASCII 文件名按原样输出。
- 固定报告格式：先给决策表（项目｜类型｜证据｜大小｜建议或结果），结尾标明 DONE 或 PENDING，待定事项合并成一次提问。
- 分支删除步骤：祖先关系已合并的用 `-d`；squash 合并的只在本地 tip 等于 `headRefOid` 时用 `-D`；`[gone]` 只作为候选线索；删除时记录 `name sha` 以便恢复。
- `worktrees.md` 新增门槛检查和“首条匹配即生效”的决策表；`--force` 仅限已核实为可再生产物的情况。
- 清理后在文档和笔记中搜索已删除的工作区、分支和路径名称，同步更新过时引用。
- `space.md` 新增各生态可再生目录速查表、优先使用工具自带清理命令、仓库外缓存不在范围内，以及 pnpm 硬链接、APFS 快照对空间统计的影响。
- `docs.md` 新增文档检查清单（命令可执行、陈述与代码一致、链接有效、读者能找到所需信息、单一事实来源、矛盾、阶段与现状），以及 CLAUDE.md 导入 AGENTS.md 时的处理方式。
- 新增判断文件是否无用时的误报排查清单（动态加载、配置和 CI 引用、平台清单文件等），可借助项目已配置的 knip、Periphery、vulture 作为证据。

### 修正

- ignored 文件列表统一加上 `--directory`，避免 `node_modules/` 逐文件展开。
- 明确写出 `git worktree remove` 不加 `--force` 也会删除 ignored 的 `.env`，以及 `git clean -ndX` 会把 `.env` 列为可删除。
- PR 查询说明为什么必须带 `--base`。
- 原 SKILL.md 中“放宽协作边界”一段改写为通用说明，移入 `docs.md`。

### 元数据与测试

- frontmatter 新增 `compatibility` 和 `metadata.version`；description 补充 CLAUDE.md、本地分支和只读盘点等触发场景。
- `tests/make-fixtures.sh`：生成 11 种场景的离线夹具仓库，附带离线 `gh` 存根和 `expected.tsv`。
- `tests/test-survey.sh`：盘点脚本的回归测试（包括只读性验证），以及参考文档所依赖的 Git 行为测试。
- `tests/check-skill.sh`：frontmatter、行数、链接、版本、eval JSON、脚本语法和关键安全规则检查。
- `evals/evals.json`（6 个行为用例，第 6 个需在 Codex 应用中手动运行）和 `evals/trigger-evals.json`（中英文共 20 条触发与不触发查询）。
- README 新增 Claude Code 安装与调用方式；繁中和日文 README 标注以简体中文版为准。

### 验证状态

- 已验证：`tests/check-skill.sh` 和 `tests/test-survey.sh` 在 macOS（Git 2.54，Bash 3.2）上全部通过。
- 未验证：`evals/` 中的行为用例和触发率尚未用 agent 实际运行；Codex 托管工作区的归档与恢复仍未实测；Windows 实机和 Linux 未运行测试。

## 1.0.0 — 2026-09-28

首个记录版本，汇总 2026-09-06 至 2026-09-28 的提交：

- 发布仓库整理 skill 与四语言 README。
- 工作区退役核验：固定 SHA 比较、squash 合并的 `headRefOid` 核对、detached HEAD、ignored 文件检查。
- Windows 适配：原生 PowerShell、Git Bash、WSL 的路径、联接点、文件占用与退出码处理。
- 区分 Codex 托管归档与普通 Git 工作区移除；文档整理以准确易用为目标，精简只是可选手段。
- 验证状态：Codex 中完成格式检查和隔离仓库场景验证；当时未实测 Codex 托管归档与恢复，也未在 Windows 实机验证。
