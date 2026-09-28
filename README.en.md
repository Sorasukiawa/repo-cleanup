# repo-cleanup

[简体中文](README.md) · [繁體中文](README.zh-TW.md) · [English](README.en.md) · [日本語](README.ja.md)

A lightweight skill for AI coding agents: remove unnecessary caches, safely retire unneeded worktrees, and review and organize project documentation such as README / AGENTS when relevant to the task.

Preserve useful work and keep documentation accurate, easy to find, and actionable; reclaim unnecessary storage when needed. Proceed within existing authorization and match validation to the changes.

## Install

Use the [skills CLI](https://github.com/vercel-labs/skills) to install for Codex globally:

```bash
npx skills add Sorasukiawa/repo-cleanup --skill repo-cleanup --agent codex --global
```

Alternatively, download the repository and place `SKILL.md`, `references/`, and `agents/` in `repo-cleanup/` under your personal skills directory. If a skill with the same name already exists, check its source and any local customizations first.

## Use

```text
Use $repo-cleanup to organize this repository within the current goal, review README and AGENTS, fix demonstrated issues, and leave suitable content unchanged.
```

Inspect only: `Use $repo-cleanup to inventory this repository without changing files.`

You can narrow the scope: “only remove build caches,” “only simplify AGENTS,” or “retire merged worktrees and keep the branches.”

## Windows

[Windows guidance](references/windows.md) covers native PowerShell 5.1 / 7, Git Bash, and WSL: literal paths, junctions, file locks, and Git exit codes. WSL is not required. The installation command is unchanged; `npx` requires Node.js.

The guidance has been checked against official documentation and reviewed in scenarios; Windows machine validation is still pending.

## How it works

- Distinguishes source, caches, deliverables, and historical material by references and purpose. Ignore rules and age alone do not justify deletion.
- Checks active use and reuse needs first. Uses native archival for Codex-managed worktrees and preserves unique work before removing ordinary Git worktrees. When merge verification is required, covers squash merges, later commits, and detached HEAD.
- Treats accuracy and usability as the documentation goals, with simplification as an optional means. Keeps suitable content unchanged and adds missing information when needed. README serves readers; AGENTS retains durable project guidance, while phase arrangements belong in progress documents.
- Follows the target repository's commit conventions. Local cleanup does not automatically extend to remote deletion or issue updates.
- For space cleanup, reports reduced directory usage separately from increased free disk space. Documentation-only tasks need no repository-wide storage scan; validation matches the changes.

[SKILL.md](SKILL.md) is the single English instruction entry point; read the [worktree reference](references/worktrees.md) whenever retiring worktrees or branches. Agents use the user's language for conversation and reports, defaulting to Simplified Chinese when unspecified. The four README translations help readers get started and do not need to be loaded together.

This is a workflow guide, with no installation hooks or automatic deletion executable. Validation in Codex includes format checks, execution and read-only scenarios in isolated repositories, and Git fixtures for merge reachability, detached commits, squash merges, later commits, ignored files, and invalid refs. Not every agent, operating system, or repository layout has been tested. Reproducible cases are welcome in Issues.

This documentation and archival workflow update passed format, internal-link, and file-consistency checks. Codex-managed worktree archival and restoration have not yet been exercised.

## References and license

The documentation approach was informed by [agent-md-refactor](https://github.com/softaworks/agent-toolkit/tree/main/skills/agent-md-refactor). The worktree workflow was compared with [cleanup-repo](https://github.com/rheged-studio/agent-skills/tree/main/skills/cleanup-repo) and the official Git / GitHub CLI documentation linked in the reference. This project is independently maintained.

[MIT](LICENSE) © 2026 Sorasukiawa.
