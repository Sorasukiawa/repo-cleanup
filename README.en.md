# repo-cleanup

[简体中文](README.md) · [繁體中文](README.zh-TW.md) · [English](README.en.md) · [日本語](README.ja.md)

A lightweight skill for AI coding agents: remove unnecessary caches, safely retire unneeded worktrees and merged branches, and review and organize project documentation such as README / AGENTS / CLAUDE.md when relevant to the task.

Preserve useful work and keep documentation accurate, easy to find, and actionable; reclaim unnecessary storage when needed. Proceed within existing authorization and match validation to the changes.

## Install

### Claude Code plugin

```bash
claude plugin marketplace add Sorasukiawa/repo-cleanup
```

```bash
claude plugin install repo-cleanup@repo-cleanup
```

Inside a session, `/plugin marketplace add Sorasukiawa/repo-cleanup` and `/plugin install repo-cleanup@repo-cleanup` do the same. To update later, run `claude plugin marketplace update repo-cleanup`, then `claude plugin update repo-cleanup@repo-cleanup`.

### skills CLI (Codex or Claude Code)

Use the [skills CLI](https://github.com/vercel-labs/skills) to install into your personal skills directory:

```bash
npx skills add Sorasukiawa/repo-cleanup --skill repo-cleanup --agent codex --global
```

```bash
npx skills add Sorasukiawa/repo-cleanup --skill repo-cleanup --agent claude-code --global
```

In Claude Code, choose either the plugin or the skills CLI; installing both shows two skills with the same name.

### Manual install

Alternatively, download the repository and place `SKILL.md`, `references/`, `scripts/`, and `agents/` in `repo-cleanup/` under your personal skills directory (`~/.agents/skills/` for Codex, which also reads `~/.codex/skills/`; `~/.claude/skills/` for Claude Code). `tests/` and `evals/` are for maintenance only. If a skill with the same name already exists, check its source and any local customizations first.

## Use

Invoke it as `$repo-cleanup` in Codex. In Claude Code use `/repo-cleanup` (the plugin's full name is `/repo-cleanup:repo-cleanup`; the short form works when no other command shares the name), optionally with a scope such as `/repo-cleanup inspect only`. You can also just describe the task:

```text
Use $repo-cleanup to organize this repository within the current goal, review README and AGENTS, fix demonstrated issues, and leave suitable content unchanged.
```

Inspect only: `Use $repo-cleanup to inventory this repository without changing files.`

You can narrow the scope: “only remove build caches,” “only simplify AGENTS,” “retire merged worktrees and keep the branches,” or “delete merged local branches and leave the remote alone.”

## How it works

- Chooses a mode first: an inspection is strictly read-only (no fetch, build, edit, or deletion); execution completes the authorized scope on its own and collects pending items into one question at the end.
- Reads only the references the task needs: space cleanup, worktrees and branches, host-managed worktrees, documentation, Windows.
- Distinguishes source, caches, local secrets, deliverables, and historical material by references and purpose. Ignore rules and age alone do not justify deletion. The Common Misjudgments table in SKILL.md lists the easiest ways to delete the wrong thing, such as `git worktree remove` also deleting an ignored `.env`.
- Decides by whether something can be regenerated. Unique commits, uncommitted work, secrets and local configuration, user-made assets, and the only copy of a release stay. Anything a build, install, or generator can recreate is a candidate even when a test project references it, with the regeneration path and the impact of deleting it. Every item of 1 GiB or more and the ten largest items appear in the report whatever the decision; large items kept only by judgment go to you, and the status stays PENDING.
- Worktree retirement passes gate checks first (in use, locked, host-managed, unsaved changes or ignored files), then merge evidence: regular merges, squash merges (the local tip must equal the PR's `headRefOid`), and detached HEAD. Codex-managed worktrees use native archival; Claude Code and desktop-app worktrees go through the host first.
- Branches are kept by default. Deletion uses `-d` or `-D` under stated conditions and records `name sha` for restoration. `[gone]` is only a clue. Remotes and issues are never changed automatically.
- Treats accuracy and usability as the documentation goals, with simplification as an optional means. README serves readers; AGENTS / CLAUDE.md retain durable project guidance, while phase arrangements belong in progress documents.
- In Claude Code, the inventory script and read-only `git`, `du`, and `df` queries are pre-approved through `allowed-tools`, so an inventory does not prompt for each command. Deleting, removing, and pushing commands are not included.
- Reports lead with a decision table (item, kind, evidence, size, proposal or result) and end with DONE or PENDING. Space cleanup reports reduced directory usage separately from increased free disk space.

`scripts/survey.sh` takes a read-only inventory in one call: every worktree and local branch, ignored entries (largest first with `--sizes`), and project-owned outputs outside the repository (a custom Cargo target directory, per-task build directories, this project's Xcode DerivedData):

```bash
bash ~/.agents/skills/repo-cleanup/scripts/survey.sh --repo . --base main --sizes
```

This is the path for a skills CLI install for Codex; use `~/.codex/skills/` or `~/.claude/skills/` instead when the skill lives there. As a plugin, the skill gives Claude the script's full path automatically. `--base` is required for comparisons; the script never guesses the target branch. Its output is evidence, and the skill's rules still make the decision.

## Layout

| Path | Purpose |
| --- | --- |
| `SKILL.md` | English instruction entry point: modes, routing, purpose classification, common misjudgments, report format |
| `.claude-plugin/` | Claude Code plugin and marketplace manifests; the repository root is the plugin and `SKILL.md` is its only skill |
| `agents/openai.yaml` | Display name, summary, and default prompt in the Codex interface |
| `references/space.md` | Cleanup scope (including project outputs outside the repository), ecosystem cheat sheet, generated test data, space measurement |
| `references/worktrees.md` | Worktree and branch retirement: gates, merge evidence, decision table, branch deletion |
| `references/hosts.md` | Worktrees managed by Codex, Claude Code, and the Claude desktop app |
| `references/docs.md` | README, AGENTS, CLAUDE.md, and other documentation and rules |
| `references/windows.md` | Native PowerShell, Git Bash, and WSL |
| `scripts/survey.sh` | Read-only inventory script |
| `tests/`, `evals/` | Fixtures, regression tests, behavior and trigger evals |

Agents use the user's language for conversation and reports, defaulting to Simplified Chinese when unspecified. The four README translations help readers get started and do not need to be loaded together.

## Non-goals

- No automatic deletion program or installation hooks; `survey.sh` is read-only.
- No cleanup of shared caches unrelated to the project (global npm / pnpm caches, the cargo registry, Docker, simulator runtimes, and so on), and no maintenance of installed agent tools or skills. Build output the project keeps outside the repository is in scope.
- No remote branch deletion or PR / issue updates by default.
- No removal of useful documentation just to make it shorter.

## Windows

[Windows guidance](references/windows.md) covers native PowerShell 5.1 / 7, Git Bash, and WSL: literal paths, junctions, file locks, and Git exit codes. `survey.sh` runs in Git Bash or WSL; native PowerShell uses the commands in the guidance. WSL is not required, and `npx` requires Node.js.

## Tests and validation

```bash
bash tests/check-skill.sh
```

```bash
bash tests/test-survey.sh
```

`check-skill.sh` checks frontmatter, size, links, the version (consistent across SKILL.md, plugin.json, and CHANGELOG), JSON files, and key safety rules; with `CLAUDE_BIN` set or `claude` on PATH it also runs the official `claude plugin validate --strict`. `test-survey.sh` builds a fixture repository with 11 scenarios in a temporary directory and verifies the inventory script's output and read-only behavior, plus the Git behaviors the references depend on. `evals/evals.json` holds behavior cases to run with an agent, and `evals/trigger-evals.json` holds trigger queries, both compatible with [skill-creator](https://github.com/anthropics/skills/tree/main/skills/skill-creator) (not the `claude plugin eval` format).

See [CHANGELOG.md](CHANGELOG.md) for what changed in each version and how far it was validated. Reproducible cases are welcome in Issues.

## References and license

The documentation approach was informed by [agent-md-refactor](https://github.com/softaworks/agent-toolkit/tree/main/skills/agent-md-refactor) and [claude-md-improver](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/claude-md-management). The worktree workflow was compared with [cleanup-repo](https://github.com/rheged-studio/agent-skills/tree/main/skills/cleanup-repo), [pd:cleanup](https://github.com/peterdrier/skills/tree/main/plugins/pd/skills/cleanup), the finishing-a-development-branch skill in [superpowers](https://github.com/obra/superpowers), and the official Git / GitHub CLI / Claude Code documentation linked in the references. The testing approach follows [skill-creator](https://github.com/anthropics/skills/tree/main/skills/skill-creator) and superpowers' writing-skills. This project is independently maintained.

[MIT](LICENSE) © 2026 Sorasukiawa.
