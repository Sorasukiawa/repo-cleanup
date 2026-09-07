# repo-cleanup

[简体中文](README.md) · [繁體中文](README.zh-TW.md) · [English](README.en.md) · [日本語](README.ja.md)

A lightweight skill for AI coding agents: remove unnecessary caches, retire completed worktrees, fix stale instructions, and simplify README / AGENTS files.

Reduce disk usage and context overhead while preserving useful work. Proceed within existing authorization and match validation to the changes.

## Install

Use the [skills CLI](https://github.com/vercel-labs/skills) to install for Codex globally:

```bash
npx skills add Sorasukiawa/repo-cleanup --skill repo-cleanup --agent codex --global
```

Alternatively, download the repository and place `SKILL.md`, `references/`, and `agents/` in `repo-cleanup/` under your personal skills directory. If a skill with the same name already exists, check its source and any local customizations first.

## Use

```text
Use $repo-cleanup to organize this repository, fix stale instructions, and simplify README and AGENTS.
```

Inspect only: `Use $repo-cleanup to inventory this repository without changing files.`

You can narrow the scope: “only remove build caches,” “only simplify AGENTS,” or “retire merged worktrees and keep the branches.”

## Windows

[Windows guidance](references/windows.md) covers native PowerShell 5.1 / 7, Git Bash, and WSL: literal paths, junctions, file locks, and Git exit codes. WSL is not required. The installation command is unchanged; `npx` requires Node.js.

The guidance has been checked against official documentation and reviewed in scenarios; Windows machine validation is still pending.

## How it works

- Distinguishes source, caches, deliverables, and historical material by references and purpose. Ignore rules and age alone do not justify deletion.
- Checks worktree merge status and unique files, including squash merges, later commits, and detached HEAD.
- Keeps, moves, archives, deletes, or consolidates documentation without a fixed reduction target.
- Follows the target repository's commit conventions. Local cleanup does not automatically extend to remote deletion or issue updates.
- Reports reduced directory usage separately from increased free disk space, alongside actual verification results.

[SKILL.md](SKILL.md) is the single English instruction entry point; the [worktree reference](references/worktrees.md) is read only when needed. Agents use the user's language for conversation and reports, defaulting to Simplified Chinese when unspecified. The four README translations help readers get started and do not need to be loaded together.

This is a workflow guide, with no installation hooks or automatic deletion executable. Validation in Codex includes format checks, execution and read-only scenarios in isolated repositories, and Git fixtures for merge reachability, detached commits, squash merges, later commits, ignored files, and invalid refs. Not every agent, operating system, or repository layout has been tested. Reproducible cases are welcome in Issues.

## References and license

The documentation approach was informed by [agent-md-refactor](https://github.com/softaworks/agent-toolkit/tree/main/skills/agent-md-refactor). The worktree workflow was compared with [cleanup-repo](https://github.com/rheged-studio/agent-skills/tree/main/skills/cleanup-repo) and the official Git / GitHub CLI documentation linked in the reference. This project is independently maintained.

[MIT](LICENSE) © 2026 Sorasukiawa.
