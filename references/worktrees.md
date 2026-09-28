# Retire Worktrees and Preserve Their Work

Read this whenever retiring worktrees or branches. A merged PR alone is not a reason to retire a worktree. Check whether it is still needed or suitable for reuse, along with its history, unique files, and active use.

## Choose the Retirement Method

Keep primary, pinned, shared, locked, or in-use worktrees. Being attached to the current chat does not itself mean a managed worktree is in use; verify that no ongoing task or process relies on it before retirement.

- Codex-managed worktrees: when the native tools are available, inspect `list_artifacts` and use `archive_worktree` with the exact worktree identity it returns. The archive preserves a recoverable Git snapshot of committed history, uncommitted changes, unpushed commits, and non-ignored untracked files. Inspect ignored content and preserve anything needed separately before archiving. Completed or abandoned work can be archived within the user's scope without first committing, pushing, or proving it merged. If the request specifically limits cleanup to merged work, still verify that condition using the checks below. Confirm archive success and retain the returned recovery information. Keep the chat and PR open; restore specific archived work with `restore_worktree` when requested or when recovering work archived prematurely.
- Ordinary Git worktrees: use the history checks below, preserve unique files and any commits not otherwise retained, then use `git worktree remove`. A clean Git status does not establish that ignored files are disposable.
- If managed ownership is established but the native workflow is unavailable or refuses the archive, report the specific blocker and continue with other candidates. Do not bypass it with shell removal or delete files merely to make the worktree eligible. Worktrees with initialized submodules or embedded repositories may be unsupported by the native tool; follow its current result.

Keep branches by default. When branch deletion is also requested, verify its history separately; an archived checkout does not itself authorize deleting local or remote branches.

## Choose the Comparison Target

Use the following history checks for ordinary Git retirement, branch cleanup, or a request restricted to merged work. Managed snapshot archival of completed or abandoned work does not require merge proof unless the user's scope requires it.

Determine the target branch from the current goal, repository rules, and remote configuration; do not assume `main` or `origin`. Record the candidate worktree's HEAD and the target branch SHA, then compare those fixed values. Recheck that they have not changed immediately before deletion.

The examples below use Bash. For native PowerShell commands and exit handling, use [Windows cleanup](windows.md). Keep Git and paths in the same Windows or WSL environment.

Below, `wt` is the verified absolute path of the candidate, and `base_ref` is the actual target branch reference:

```bash
git worktree list --porcelain
git -C "$wt" status --porcelain=v1 --untracked-files=all
git -C "$wt" ls-files --others --ignored --exclude-standard
git -C "$wt" rev-parse HEAD
git rev-parse "$base_ref^{commit}"
```

A clean status does not replace checking ignored content. Do not treat a failed port or handle check as evidence that a worktree is idle. Do not run fetch/prune during a read-only inventory. Read the hosting platform when current online merge evidence is needed; refresh local remote-tracking refs only when executing changes and the task calls for it.

## Regular Merges

Run `git merge-base --is-ancestor "$tip_sha" "$base_sha"` using the recorded `tip_sha` and `base_sha`: exit code 0 means the commit history is included, 1 means it is not an ancestor, and other codes indicate a check error. A non-ancestor is not necessarily unmerged; it may have been squash-merged or rebased.

## Squash / Rebase Merges

When the ancestry check fails, inspect merge records on the relevant hosting platform. For GitHub:

```bash
gh pr list --repo "$repo" --head "$branch" --base "$base_branch" --state merged \
  --json number,url,headRefOid,baseRefName,headRepositoryOwner,mergeCommit
```

The repository, source owner/branch, and target branch must match the candidate. A same-named branch or an arbitrary old PR is not evidence. Verify that:

- The PR was merged into the intended target, and its `mergeCommit` is included in the chosen target SHA. If the target reference is too old, report insufficient evidence rather than forcing a conclusion.
- The current local tip SHA exactly matches the PR's `headRefOid`. A mismatch may indicate later commits or rewritten history; keep the candidate and inspect the differences first. A previously merged PR does not account for subsequent work.
- If no hosting record is available, relevant patches and target content can be compared manually. Keep the candidate if the checks are insufficient, and continue with other cleanup. Apparently identical final files do not prove that unique history can be discarded.

## Detached HEAD

Detached HEAD only means HEAD is not attached to a branch. Still inspect uncommitted/untracked/ignored content and active use. Codex-managed archives follow the snapshot workflow above; for ordinary Git removal, check the actual HEAD's reachability:

- HEAD is included in the target, no unique files remain, and the worktree is idle: remove it within existing authorization.
- HEAD is not included in the target: keep it. If the user explicitly wants to remove the worktree while retaining its work, first preserve the SHA with a new branch or tag and archive unique files. Verify preservation before removal; a reference protects only committed history.

## Execution and Results

For ordinary Git worktrees, use `git worktree remove "$wt"` after verifying preservation. If removal is refused, inspect the reason rather than automatically adding force or running reset/stash. When an ordinary worktree's directory is already absent, inspect stale registrations with `git worktree prune --dry-run`, taking care not to mistake a temporarily unmounted worktree for a leftover entry. Use the native workflow above for Codex-managed worktrees.

Local branches, remote branches, and PR/issue status are separate objects. Local repository cleanup does not automatically extend to remote deletion or issue updates. Record the retirement method, preservation or recovery location, and result. Include HEAD, target SHA, and merge evidence when merge verification was required; no additional lengthy report is needed.

References: [Git worktree](https://git-scm.com/docs/git-worktree), [merge-base](https://git-scm.com/docs/git-merge-base), [GitHub PR queries](https://cli.github.com/manual/gh_pr_list).
