---
name: repo-cleanup
description: Use when the user asks to clean up, tidy, or audit a source repository, such as deciding which files, caches, build output, worktrees, or local branches are still needed; retiring finished worktrees or merged branches after preserving their work; reclaiming space inside the repository; or reviewing and organizing project documentation like README, AGENTS.md, or CLAUDE.md. Also use for read-only inventories of what can be deleted. Not for general disk cleanup outside the repository, global package caches, or maintaining installed agent tools and skills.
license: MIT
compatibility: Requires git. gh is optional for squash-merge evidence. scripts/survey.sh needs Bash (macOS, Linux, Git Bash, or WSL); native PowerShell steps are in references/windows.md.
metadata:
  version: "1.1.0"
---

# Repository Cleanup and Organization

Keep repository contents useful and documentation accurate, easy to navigate, and actionable; reclaim unnecessary storage when requested. Use the user's language for conversation and reports; if no language is indicated, default to Simplified Chinese. Keep cleanup within the current request, without unrelated application refactoring.

Deleting the wrong thing is the expensive failure here: a worktree that looks finished may hold the only copy of a secret, a note, or a later commit. Every rule below exists to keep that from happening without turning cleanup into item-by-item approval.

## Choose the Mode

- "See what is useful and what can be deleted" or "inspect only": take a read-only inventory. Do not start services, run builds, fetch, prune, delete or edit files, or commit.
- "Clean up, organize, or fix" or "execute the list": verify the current state, then complete the authorized scope without asking about each item or repeating permission requests.
- If missing facts affect only some items, finish the confirmed items first and collect the rest as pending. Ask only when essential information is missing or an action clearly exceeds authorization and has substantial impact; put all open questions in one message.

## Route the Task

Identify the host OS, active shell, actual repository root, applicable rules (AGENTS.md, CLAUDE.md, contributing guides), and Git status before choosing commands. Then read only what the task needs:

| Task | Read |
| --- | --- |
| Caches, build output, large or unknown files, "what can be deleted" | [Space cleanup](references/space.md) |
| Retiring worktrees or deleting branches | [Worktree verification](references/worktrees.md) |
| Worktrees created by an agent host (Codex, Claude Code, the Claude desktop app) | [Host-managed worktrees](references/hosts.md), together with worktree verification |
| README, AGENTS.md, CLAUDE.md, or other documentation and rules | [Documentation](references/docs.md) |
| Windows filesystem, PowerShell, or WSL | [Windows cleanup](references/windows.md) |

A documentation-only task needs no size or worktree audit, and a cache cleanup needs no documentation review. Read documentation structure and relevant sections first, without loading entire histories just for cleanup.

For worktree and branch inventories, `scripts/survey.sh` in this skill's directory (not the target repository) collects everything in one read-only call: `bash <skill-dir>/scripts/survey.sh --repo <repo> --base <target-ref> [--sizes]`. It never fetches or writes and does not guess the target. Its output is evidence for the rules below, not a decision. Without Bash, run the commands in the worktree reference instead.

## Establish What Each Item Is For

Determine purpose from entry points, imports, tests, scripts, CI, and release configuration. Treat filenames and modification dates only as clues:

| Type | Default action |
| --- | --- |
| Source code, lockfiles, tests, brand master assets, applicable rules | Keep; trace the purpose of apparent duplicates first |
| Regenerable caches, temporary output, intermediate build files | Verify contents and disk usage, then clean up; avoid deleting and reinstalling all development dependencies |
| Local configuration and secrets (`.env`, `*.local`, keys, certificates) | Keep, even though they are ignored; never copy them into Git |
| Worktrees and branches considered for retirement | Check ongoing use and reuse needs, then preserve their work through the appropriate host or ordinary Git workflow |
| Old designs, frozen UI, progress reports, old release packages | May have historical value; archive or consolidate as requested |
| Outdated instructions, broken paths, inconsistent configuration | Correct using evidence from current code and confirmed product scope |

Before calling a file unused, rule out the usual false positives: dynamic imports and reflection, paths in configuration, scripts, or CI, platform manifests and resource bundles (for example `Info.plist`, asset catalogs, Android resources), test fixtures, and anything loaded by string name. Unused-code tools already configured in the project, such as knip, Periphery, or vulture, are useful evidence; do not add new dependencies just for cleanup.

## Common Misjudgments

| It looks like | What is actually true |
| --- | --- |
| The path is in `.gitignore`, so it can go | Ignore rules are not a deletion list. `.env`, local configuration, test screenshots, acceptance evidence, and the only installer in a build directory are often ignored. |
| `git status` is clean, so nothing would be lost | Status hides ignored files, and `git worktree remove` deletes ignored files such as `.env` without `--force`. |
| `git clean -ndX` lists it, so it is junk | It also lists `.env` and local configuration. Use it as a candidate preview; never run `git clean -fdX` on a whole repository or worktree. |
| The PR was merged, so the worktree is finished | A merged PR alone is not a reason to retire a worktree: check later commits, unique files, ongoing use, and reuse. |
| The branch is not an ancestor, so it is unmerged | It may have been squash-merged or rebased; look for hosting evidence first. |
| A merged PR exists, so the branch can go | Only if the local tip equals the PR's `headRefOid` and the merge commit is in the target. Otherwise later work exists. |
| The upstream is `[gone]`, so it was merged | The remote branch was deleted. That is a candidate signal, not merge evidence. |
| A port, process, or handle check found nothing | A failed or empty check does not prove a directory is idle. |
| It is frozen, old, or untouched for months | Frozen does not mean unused; age is a clue, not evidence. |
| The directory shrank, so free space grew by the same amount | Shared blocks, hardlinks, snapshots, and other processes can make them differ. |
| A browser mock or unit test passes, so the app works | Do not claim real application behavior has been verified from mocks. |

## Execute Within Scope

- Write an exact path list for each round of deletions, checking resolved paths and link boundaries. Do not broaden the scope with recursive globs or follow links to data outside the repository.
- Check processes or open handles for directories that builds, tests, or services may use before removing them.
- Preserve before removing: copy needed ignored files, keep commits reachable from a branch or tag, and verify the copy. Uncertainty about one candidate does not block the others.
- Put temporary archives in an existing locally ignored location or one the user specifies. Do not commit private material. Do not automatically delete newly saved archives after cleanup.
- Keep branches by default when only retiring worktrees. Local branches, remote branches, and PR or issue status are separate objects; local cleanup does not extend to remote deletion or issue updates unless the user asks.
- If a removal is refused, read the reason instead of adding `--force`, `reset`, or `stash`.

## Report

Write the report in the user's language. Lead with the decision table; summarize leftovers by pattern (`dist/**`, `*.tsbuildinfo`) rather than dumping file lists.

```text
Scope: <what was requested>   Mode: inspect only | executed   Status: DONE | PENDING (<n> items)

| Item | Kind | Evidence | Size | Proposal or result |
| wt/feat-a (feat-a) | worktree | ancestor of main@1a2b3c4; clean; no ignored files | 12 MB | retired |
| dist/ | build output | ignored; rebuilt by `npm run build` | 340 MB | removed |
| .env | local secret | ignored; only copy | 1 KB | kept |
| wt/spike | worktree | 3 commits not in main; no PR | 4 MB | kept |

Pending: one numbered list, each with the open question or the exact command the user must run.
Verification: what was checked and how.
Follow-up: effects such as caches rebuilding on the next build.
```

Use `DONE` only when every authorized action is complete and verified and nothing waits on the user; items kept on purpose do not block it. For space cleanup, report reduced directory usage separately from increased free disk space, and label estimates. Include documentation sizes only when the user cares about reduction.

## Verify and Deliver

Verify the affected outcomes: deletion targets are gone and retained material is intact; host archives report success and keep their recovery information; moved or edited documentation links resolve; changed configuration parses. Search the project's documentation and notes for the names of removed worktrees, branches, and paths, and update stale references. Review the Git diff against the initial state to distinguish this task's changes from the user's. Run the checks the changes affect; documentation cleanup does not require a full build, and cleared caches do not need to be rebuilt immediately without a reason.

Follow repository rules and current authorization for commits, pushes, releases, and communication logs; this skill does not independently require those actions. Preserve the user's uncommitted work as-is.

Example invocation (Codex `$repo-cleanup`, Claude Code `/repo-cleanup`): `Use repo-cleanup to organize the current repository, remove unnecessary caches, retire worktrees no longer needed after preserving their work, and review README and AGENTS for accuracy and usability. Fix demonstrated issues and leave suitable content unchanged.`
