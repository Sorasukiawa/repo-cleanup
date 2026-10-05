# Retire Worktrees and Branches While Preserving Their Work

Read this whenever retiring worktrees or deleting branches. Contents: gates, target, inventory, merge evidence, decision table, branch deletion, execution.

## Gates

Keep a worktree, or preserve its content first, whenever any of these applies. They come before merge evidence: a fully merged worktree can still hold the only copy of something.

- It is the main worktree, the current session's worktree, pinned, shared, or used by a running task, build, server, or agent session. Being attached to the current chat does not by itself mean a managed worktree is in use; verify that no ongoing task or process relies on it.
- It is locked (`git worktree list --porcelain` shows `locked`). Agent hosts lock worktrees their sessions are using; do not unlock a lock you have not verified as stale.
- An agent host created it: follow [Host-managed worktrees](hosts.md) instead of plain Git removal.
- It has tracked changes or untracked files that are not preserved elsewhere.
- It has ignored content beyond regenerable output. `git worktree remove` deletes ignored files such as `.env` without `--force`, so copy what is needed first.
- It is still useful for reuse, for example a PR under review that will need fixes.

## Choose the Comparison Target

Use the history checks below for ordinary Git retirement, branch cleanup, or a request restricted to merged work. Host snapshot archival of completed or abandoned work does not require merge proof unless the user's scope requires it.

Determine the target branch from the current goal, repository rules, and remote configuration; do not assume `main` or `origin`. Record the candidate's HEAD and the target SHA, compare those fixed values, and recheck that they have not changed immediately before deletion.

## Inventory

`scripts/survey.sh --repo <repo> --base <target-ref>` gathers all of this read-only. The equivalent Bash commands, with `wt` as the verified absolute path of the candidate and `base_ref` as the actual target reference:

```bash
git worktree list --porcelain
git -C "$wt" status --porcelain=v1 --untracked-files=all
git -C "$wt" ls-files --others --ignored --exclude-standard --directory
git -C "$wt" rev-parse HEAD
git rev-parse "$base_ref^{commit}"
git for-each-ref --format='%(refname:short) %(upstream:track) %(worktreepath)' refs/heads
```

`--directory` collapses ignored directories such as `node_modules/` into one line instead of listing every file. For native PowerShell commands and exit handling, use [Windows cleanup](windows.md); keep Git and paths in the same Windows or WSL environment.

Do not run fetch or prune during a read-only inventory, and say that remote-tracking refs may be stale. Read the hosting platform when current merge evidence is needed; refresh local remote-tracking refs only when executing changes and the task calls for it.

## Merge Evidence

**Regular merges.** Run `git merge-base --is-ancestor "$tip_sha" "$base_sha"` with the recorded SHAs: exit 0 means the history is included, 1 means it is not an ancestor, and anything else is a check error. A non-ancestor is not necessarily unmerged; it may have been squash-merged or rebased.

**Squash or rebase merges.** When the ancestry check fails, inspect merge records on the hosting platform. For GitHub:

```bash
gh pr list --repo "$repo" --head "$branch" --base "$base_branch" --state merged \
  --json number,url,headRefOid,baseRefName,headRepositoryOwner,mergeCommit
```

`--base` matters: without it, a PR merged into a stacked or feature base looks like a trunk merge. The repository, source owner and branch, and target branch must match the candidate; a same-named branch or an arbitrary old PR is not evidence. Verify that:

- The PR was merged into the intended target, and its `mergeCommit` is included in the chosen target SHA. If the target reference is too old, report insufficient evidence rather than forcing a conclusion.
- The current local tip SHA exactly matches the PR's `headRefOid`. A mismatch means later commits or rewritten history: keep the candidate and show `git log --oneline <headRefOid>..<tip>`.
- Without a hosting record, relevant patches and target content can be compared manually. Keep the candidate if the checks are insufficient. Apparently identical final files do not prove that unique history can be discarded.

**Detached HEAD** only means HEAD is not on a branch. Check reachability of the actual HEAD the same way, plus uncommitted, untracked, and ignored content and active use.

## Decision Table

Apply after the gates; the first matching row wins.

| Situation | Decision |
| --- | --- |
| Registered but the directory is missing (`prunable`) | Inspect with `git worktree prune --dry-run`; an unmounted drive or unavailable WSL distribution is not a leftover |
| HEAD is an ancestor of the target SHA | Eligible for retirement |
| Merged PR into the target, tip equals `headRefOid`, merge commit in the target | Eligible for retirement |
| Merged PR, but tip differs from `headRefOid` | Keep; show the later commits |
| Commits outside the target and no merge evidence (branch or detached) | Keep. If the user wants the directory gone, first preserve the SHA with a branch or tag and archive unique files, then verify |
| Anything else | Keep and list as pending |

Eligible means safe to retire within the user's scope, not required: a merged PR alone is not a reason to retire a worktree.

## Branch Deletion

Keep branches by default. When branch deletion is in scope, judge each branch with the same evidence:

- A branch checked out in any worktree cannot be deleted; retire that worktree first or keep the branch.
- Ancestor of the target: `git branch -d <branch>`. Git checks against the branch's upstream or the current HEAD, not your chosen target; if it refuses after your recorded ancestry check passed, recheck the SHAs, then `git branch -D` is justified for that branch.
- Squash or rebase merged, with tip equal to `headRefOid` and the merge commit in the target: `git branch -D <branch>`. Never force-delete a branch whose tip differs.
- An upstream marked `[gone]` (from `%(upstream:track)` or `git branch -vv`) is a candidate signal only; it still needs the evidence above.
- Remote branches (`git push <remote> --delete <branch>`) and PR or issue status change only when the user explicitly includes them. An archived checkout does not authorize deleting local or remote branches.
- Record `name sha` for each deleted branch; while the objects remain, `git branch <name> <sha>` restores it.

## Execution and Results

For ordinary Git worktrees, run `git worktree remove "$wt"` after verifying preservation, from outside that worktree. If removal is refused, inspect the reason instead of adding `--force` or running reset or stash. `--force` is acceptable only when the remaining untracked or modified entries are verified regenerable output (for example `dist/`, `*.tsbuildinfo`, a stray lockfile from an accidental install), summarized by pattern in the report, and the removal is within the user's authorization. If a worktree is locked by something verified as gone, `git worktree unlock` first. After removal, clean stale registrations with `git worktree prune` once `--dry-run` shows only real leftovers.

Record the retirement method, the preservation or recovery location, and the result. Include HEAD, target SHA, and merge evidence when merge verification was required; no additional lengthy report is needed.

References: [Git worktree](https://git-scm.com/docs/git-worktree), [merge-base](https://git-scm.com/docs/git-merge-base), [for-each-ref](https://git-scm.com/docs/git-for-each-ref), [GitHub PR queries](https://cli.github.com/manual/gh_pr_list).
