# Host-Managed Worktrees

Read this with [Worktree verification](worktrees.md) when an agent host created the worktree. The host may track sessions, locks, and recovery data that plain `git worktree remove` would bypass, so ownership decides the retirement method.

## Identify the Owner

Use the strongest evidence available: the host's own listing or tools, then the lock reason in `git worktree list --porcelain`, then location and branch naming. Location alone is a hint, not proof. If the owner cannot be established, treat the worktree as in use and list it as pending.

## Codex

When the native tools are available, inspect `list_artifacts` and use `archive_worktree` with the exact worktree identity it returns.

- The archive preserves a recoverable Git snapshot of committed history, uncommitted changes, unpushed commits, and non-ignored untracked files. Inspect ignored content and preserve anything needed separately before archiving.
- Completed or abandoned work can be archived within the user's scope without first committing, pushing, or proving it merged. If the request limits cleanup to merged work, still verify that condition with the worktree reference.
- Confirm archive success and retain the returned recovery information. Keep the chat and PR open; restore specific archived work with `restore_worktree` when requested or when recovering work archived prematurely.
- If the native workflow is unavailable or refuses the archive, report the specific blocker and continue with other candidates. Do not bypass it with shell removal or delete files merely to make the worktree eligible. Worktrees with initialized submodules or embedded repositories may be unsupported by the native tool; follow its current result.

## Claude Code

- Sessions started with `claude --worktree <name>`, worktrees entered with `EnterWorktree`, and subagents with `isolation: worktree` live under `.claude/worktrees/<name>/` on branches named `worktree-<name>` by default. Claude Code marks the worktrees it creates in their Git metadata.
- A running session, subagent, or backgrounded session holds a `git worktree lock` on its worktree. Treat locked worktrees as in use. Claude Code releases locks of sessions whose process has exited during its periodic sweep and never releases locks the user set.
- On interactive exit, Claude Code checks the worktree and either removes a clean one or asks whether to keep it. Its periodic sweep removes subagent and background-session worktrees older than `cleanupPeriodDays` only when they hold no changes, untracked files, or unpushed commits.
- To leave a worktree from inside its own session, use `ExitWorktree`. Do not remove another live session's worktree from the shell.
- Worktrees the sweep keeps, and those left by non-interactive `-p` runs, are ordinary Git worktrees for retirement purposes once no live session uses them: apply the gates and evidence in the worktree reference, preserve their work, then `git worktree remove`.

## Claude Desktop App

Session worktrees belong to the app's sessions. Prefer the app's own cleanup (Settings › Storage, "Clean up inactive sessions", or the equivalent host tool when one is available): it keeps the sessions, conversations, and branches, skips running, pinned, or recently used sessions, and asks the user before removing anything. Discarding a kept worktree with uncommitted changes is permanent and needs the user's explicit request. Do not delete an app session's worktree with shell commands while the session exists.

## Other Hosts

When a host created the worktree but no native workflow is available, confirm that no live session or process uses it, then follow the ordinary Git workflow in the worktree reference. If the host refuses or the owner is unclear, keep the worktree and report the blocker.

References: [Claude Code worktrees](https://code.claude.com/docs/en/worktrees).
