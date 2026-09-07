# repo-cleanup

[简体中文](README.md) · [繁體中文](README.zh-TW.md) · [English](README.en.md) · [日本語](README.ja.md)

面向 AI 编程助手的轻量仓库整理 skill：清理无用缓存、收尾已完成的工作区、修正过时说明，并精简 README / AGENTS。

减少磁盘占用与上下文负担，保留有效成果。已有授权不重复确认，验证规模与改动相称。

## 安装

使用 [skills CLI](https://github.com/vercel-labs/skills)，安装到 Codex 个人技能目录：

```bash
npx skills add Sorasukiawa/repo-cleanup --skill repo-cleanup --agent codex --global
```

也可下载仓库，将 `SKILL.md`、`references/` 和 `agents/` 放入个人技能目录的 `repo-cleanup/`。已有同名 skill 时，先核对来源和个人修改。

## 使用

```text
使用 $repo-cleanup 清理和整理当前仓库，修正过时说明并精简 README 和 AGENTS。
```

只检查：`使用 $repo-cleanup 只做盘点，不修改文件。`

也可限定为“只清理编译缓存”“只精简 AGENTS”“收尾已合并工作区，保留分支”。

## Windows

提供原生 PowerShell 5.1 / 7、Git Bash 和 WSL 的[适配指引](references/windows.md)，涵盖特殊字符路径、目录联接、文件占用及 Git 退出码。无需为了使用 skill 安装 WSL；安装命令不变，使用 `npx` 需要 Node.js。

已核对官方文档并进行场景审查，尚未完成 Windows 实机验证。

## 工作方式

- 根据引用和用途区分源码、缓存、交付件与历史资料；忽略规则和文件年龄不直接决定删除。
- 核对工作区合并状态与独有文件，覆盖 squash 合并、后续提交和 detached HEAD。
- 文档按保留、迁移、归档、删除或合并处理，不设置固定删减比例。
- 遵循目标仓库的提交约定；本地整理不自动扩展为远端删除或工单更新。
- 分别报告目录占用减少与磁盘空闲增长，以及实际验证结果。

[SKILL.md](SKILL.md) 是唯一英文执行入口；[工作区参考](references/worktrees.md) 按需读取。助手按用户语言交流和输出报告，未指定时默认简体中文。四语言 README 帮助读者上手，无需同时加载。

这是流程指南，没有安装钩子或自动删除程序。Codex 中已完成格式检查、隔离仓库的执行与只读场景验证，以及合并可达性、detached 提交、squash 合并、后续提交、ignored 文件和无效引用等 Git 场景检查；未验证所有助手、操作系统或仓库布局。欢迎通过 Issues 提供可复现案例。

## 参考与许可

文档整理思路参考 [agent-md-refactor](https://github.com/softaworks/agent-toolkit/tree/main/skills/agent-md-refactor)，工作区流程对照 [cleanup-repo](https://github.com/rheged-studio/agent-skills/tree/main/skills/cleanup-repo) 及参考文档中的 Git / GitHub CLI 官方说明。本项目独立维护。

[MIT](LICENSE) © 2026 Sorasukiawa.
