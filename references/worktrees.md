# Verify Worktree Merges and Unique Work

Read this only when retiring worktrees or branches. Merge status and whether a directory can be deleted are separate questions: a merged worktree may still contain unique files or be in use by a task.

## Choose the Comparison Target

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

A clean status does not replace checking ignored content. Keep locked or active worktrees and those belonging to the current task. Do not treat a failed port or handle check as evidence that a worktree is idle. Do not run fetch/prune during a read-only inventory. Read the hosting platform when current online merge evidence is needed; refresh local remote-tracking refs only when executing changes and the task calls for it.

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

Detached HEAD only means HEAD is not attached to a branch. Still check the actual HEAD's reachability, uncommitted/untracked/ignored content, and whether the worktree is in use.

- HEAD is included in the target, no unique files remain, and the worktree is idle: remove it within existing authorization.
- HEAD is not included in the target: keep it. If the user explicitly wants to remove the worktree while retaining its work, first preserve the SHA with a new branch or tag and archive unique files. Verify preservation before removal; a reference protects only committed history.

## Execution and Results

Use `git worktree remove "$wt"`. If removal is refused, inspect the reason rather than automatically adding force or running reset/stash. When the directory is already absent, inspect stale registrations with `git worktree prune --dry-run`, taking care not to mistake a temporarily unmounted worktree for a leftover entry.

Local branches, remote branches, and PR/issue status are separate objects. Local repository cleanup does not automatically extend to remote deletion or issue updates. Record each item's HEAD, target SHA, merge evidence, and the location of preserved material; no additional lengthy report is needed.

References: [Git worktree](https://git-scm.com/docs/git-worktree), [merge-base](https://git-scm.com/docs/git-merge-base), [GitHub PR queries](https://cli.github.com/manual/gh_pr_list).
