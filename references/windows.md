# Windows Repository Cleanup

Read this for Windows-hosted tasks. Use the existing shell and tools; installing WSL, switching shells, or changing machine configuration is not required for cleanup.

## Match the Shell and Filesystem

- Native PowerShell (Windows PowerShell 5.1 or PowerShell 7): use Windows Git and Windows paths. Check `$PSVersionTable.PSVersion` and `Get-Command git`. Bash `rm -rf`, `VAR=value`, and backslash line continuations are not PowerShell syntax. Keep native commands on one line; use `$LASTEXITCODE` immediately after Git, not `$?`, to distinguish non-ancestry from an error.
- Git Bash: use the Bash worktree examples with paths valid in that shell, such as `/d/Projects/example`. Windows file locks still apply.
- WSL: use the distribution's Git and Linux paths for its repositories. Do not mix Windows Git metadata or path strings with WSL Git during one cleanup. If their inventories disagree, establish the actual repository and environment before removing worktrees or pruning registrations. An unavailable distribution or drive is not a stale worktree.

## Paths, Links, and Occupancy

Use `-LiteralPath` for PowerShell filesystem operations so spaces, Unicode, and brackets are handled literally. Inspect the candidate and its ancestor path components for reparse points; `Resolve-Path` alone is not proof that a junction stays inside the repository. Inspect immediate children before descending:

```powershell
# First verify the candidate's ancestor components; do not cross an unresolved link.
$entry = Get-Item -LiteralPath $candidate -Force -ErrorAction Stop
$entry | Select-Object FullName, Attributes, LinkType, Target
if ($entry.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Inspect link target before enumeration' }
Get-ChildItem -LiteralPath $candidate -Force -ErrorAction Stop | Select-Object FullName, Attributes, LinkType, Target
```

Treat the `ReparsePoint` attribute as a reason to identify the target and type, not as proof of disposable content. Junctions, symbolic links, and cloud placeholders need different handling. Traverse ordinary directories explicitly, checking each level; do not recurse through an unverified reparse point or count its external target as repository usage. `-Force` includes hidden items here; it does not bypass permissions. Do not use a recursive deletion on a parent until its descendant link boundaries are verified. When link semantics remain unclear, retain that candidate and continue elsewhere.

On a sharing violation, identify the exact owning process with available Resource Monitor / Process Explorer / Sysinternals Handle facilities. A process-name list is not a file-handle check. After a failed removal, recheck both the directory and Git registration for partial changes. Release the relevant build or dev-server handle within existing authorization and retry when new evidence resolves the cause; otherwise retain the item and report the blocker. Do not mass-kill editors, force-close handles, or change ACLs merely to complete cleanup.

For a verified ordinary cache directory, use `Remove-Item -LiteralPath $candidate -Recurse -Force -ErrorAction Stop` only after the normal retention and occupancy checks, then confirm absence with `Test-Path -LiteralPath $candidate`. Use `git worktree remove` for registered worktrees. Long-path or access errors are failures to resolve, not reasons to bypass checks by switching environments or changing system policy.

## PowerShell Worktree Checks

Use actual values for `$wt`, `$baseRef`, and (for PR queries) `$repo`, `$branch`, `$baseBranch`. Run from the verified repository. The merge and unique-file criteria in [worktrees.md](worktrees.md) still apply.

```powershell
git worktree list --porcelain
if ($LASTEXITCODE -ne 0) { throw 'Cannot list worktrees' }
git -C "$wt" status --porcelain=v1 --untracked-files=all
if ($LASTEXITCODE -ne 0) { throw 'Cannot read worktree status' }
git -C "$wt" ls-files --others --ignored --exclude-standard
if ($LASTEXITCODE -ne 0) { throw 'Cannot list ignored files' }
$tipSha = git -C "$wt" rev-parse --verify HEAD
if ($LASTEXITCODE -ne 0) { throw 'Cannot resolve worktree HEAD' }
$baseSha = git rev-parse --verify "${baseRef}^{commit}"
if ($LASTEXITCODE -ne 0) { throw 'Cannot resolve target commit' }
git merge-base --is-ancestor "$tipSha" "$baseSha"
$ancestorExit = $LASTEXITCODE
if ($ancestorExit -gt 1 -or $ancestorExit -lt 0) { throw 'Ancestry check failed' }
# 0: history included; 1: inspect squash/rebase evidence. Neither proves the directory disposable.
gh pr list --repo "$repo" --head "$branch" --base "$baseBranch" --state merged --json number,url,headRefOid,baseRefName,headRepositoryOwner,mergeCommit
if ($LASTEXITCODE -ne 0) { throw 'Cannot query merge evidence' }
```

Inspect each inventory command's result and exit code before proceeding; an empty result after failure is not a clean worktree. `gh` is optional: use the hosting UI/API if available, or retain candidates lacking sufficient merge evidence. Recheck the recorded SHAs immediately before removal.

## Measurements and Documentation

Report logical file sizes separately from allocated storage and volume free space. NTFS compression, hardlinks, cloud placeholders, and WSL virtual disks can make them differ. WSL free space is not automatically reclaimed Windows host space; VHD compaction is a separate task. Preserve repository encoding and line endings when editing docs; do not change `core.autocrlf` globally or turn a small edit into whole-file newline churn.

References: [PowerShell parsing](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_parsing), [literal paths and directory enumeration](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/get-childitem), [native exit codes](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_automatic_variables), [Handle](https://learn.microsoft.com/en-us/sysinternals/downloads/handle), [WSL filesystems](https://learn.microsoft.com/en-us/windows/wsl/filesystems).
