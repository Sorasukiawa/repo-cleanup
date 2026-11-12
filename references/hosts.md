# Host-Managed Worktrees

Read this with [Worktree verification](worktrees.md) when an agent host created the worktree. The host may track sessions, locks, and recovery data that plain `git worktree remove` would bypass, so ownership decides the retirement method.

## Identify the Owner

Use the strongest evidence available: the host's own listing or tools, then the lock reason in `git worktree list --porcelain`, then location and branch naming. Location alone is a hint, not proof. If the owner cannot be established, treat the worktree as in use and list it as pending.

## Preserve Before Any Host Retirement

A host's snapshot, archive, or "keep branch" option is local recovery data, not preservation. Whatever the host, apply the rules in [Worktree verification](worktrees.md) first: prove the work is merged into the default branch (`git merge-base --is-ancestor`, `git branch --merged`, or the squash-merge record described there); if it is unmerged and the user wants to abandon it, push it to `archive/<original-branch>` on the remote and read it back with `git ls-remote` before retiring; if it has uncommitted changes, do not retire it and hand it to the user.

## Codex

When the native tools are available, inspect `list_artifacts` and use `archive_worktree` with the exact worktree identity it returns.

- The archive preserves a recoverable Git snapshot of committed history, uncommitted changes, unpushed commits, and non-ignored untracked files. Inspect ignored content and preserve anything needed separately before archiving.
- Archive only after the preservation rule above holds: the work is merged into the default branch, or unmerged work the user abandons is on the remote as `archive/<original-branch>` and read back. A worktree with uncommitted changes is not archived; hand it to the user even though the snapshot would keep the changes.
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

## Orca

- Orca-managed worktrees live under `~/orca/workspaces/<project>/<workspace>` by default, and Orca tracks each one with workspace metadata, terminals, and agent sessions. Locate them with `orca worktree list --json` (`orca worktree ps` shows running agents and terminals), not by directory name: several entries can share a path, and a display name is not an identity.
- Treat a workspace with a running agent, an open terminal, or recent activity as in use.
- After the preservation rule above holds, remove it with `orca worktree rm --worktree id:<full-instance-id>` (or another exact selector from the listing). Current Orca hosts keep the local branch by default; pass `--delete-branch` only when branch deletion is in scope, and Orca still keeps branches it cannot prove merged. If the removal is refused, read the reason instead of adding `--force`.
- Do not delete an Orca workspace directory or run plain `git worktree remove` on it while Orca lists it; that leaves Orca's entry and sessions behind. If the CLI cannot reach the Orca runtime, keep the workspace and report the blocker.

## Antigravity

- Antigravity worktrees live under `~/.gemini/antigravity/worktrees/<project>/<name>`. Their branch names often use underscores and carry no tool prefix (for example `fix_login_flow`), so the branch name alone neither identifies the owner nor shows that the work is finished.
- Before retiring one, apply the preservation rule above and confirm that no Antigravity conversation is still working in it: check the app's conversation list and recent file activity in the worktree. If that cannot be established, treat it as in use.
- When no native removal is available, follow the ordinary Git workflow in the worktree reference once these checks pass.

## Other Hosts

When a host created the worktree but no native workflow is available, confirm that no live session or process uses it, then follow the ordinary Git workflow in the worktree reference. If the host refuses or the owner is unclear, keep the worktree and report the blocker.

References: [Claude Code worktrees](https://code.claude.com/docs/en/worktrees).
