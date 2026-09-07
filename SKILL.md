---
name: repo-cleanup
description: Use when the user asks to clean up or organize a source repository, assess useful versus redundant files, retire merged worktrees, fix stale project documentation, or shorten README and AGENTS files. Not for general disk cleanup or installed Codex component maintenance.
license: MIT
---

# Repository Cleanup and Organization

Reduce wasted space and reading overhead while preserving useful work. Use the user's language for conversation and reports; if no language is indicated, default to Simplified Chinese. Keep cleanup within the current request, without unrelated application refactoring.

## Follow the Request

- “See what is useful and what can be deleted” or “inspect only”: take a read-only inventory. Do not start services, run builds, delete or edit files, or commit.
- “Clean up, organize, or fix” or “execute the list”: verify the current state, then complete the authorized scope without asking about each item or repeating permission requests.
- If missing facts affect only one item, handle the other confirmed items first. Ask only when essential information is missing or an action clearly exceeds authorization and has substantial impact.

## Establish What Each Item Is For

Identify the host OS, active shell, and actual repository root before choosing commands. On Windows (PowerShell, Git Bash, or WSL), read [Windows cleanup](references/windows.md) for path, link, and file-lock handling. Inspect applicable rules, Git status, worktrees, top-level directory sizes, ignore rules, and build entry points. Search documentation as needed: read its structure and relevant sections first, without loading entire histories just for cleanup.

Determine purpose from entry points, imports, tests, scripts, and release configuration. Treat filenames and modification dates only as clues:

| Type | Default action |
| --- | --- |
| Source code, lockfiles, tests, brand master assets, applicable rules | Keep; trace the purpose of apparent duplicates first |
| Regenerable caches, temporary output, intermediate build files | Verify contents and disk usage, then clean up; avoid deleting and reinstalling all development dependencies |
| Extra worktrees whose work has been merged | Verify branch reachability and all unique files before retiring them |
| Old designs, frozen UI, progress reports, old release packages | May have historical value; archive or consolidate as requested. Frozen does not mean unused |
| Outdated instructions, broken paths, inconsistent configuration | Correct using evidence from current code and confirmed product scope |

`.gitignore` is not a deletion list. Screenshots or JSON read by tests, acceptance evidence in hidden directories, and the only installer in a build directory may all be useful. Do not claim real application behavior has been verified based on browser mocks.

## Clean Up and Retire Worktrees

- Create an exact path list for this round of deletions, checking resolved paths and link boundaries. Check processes or open handles for directories that builds, tests, or services may use; a failed check does not establish that nothing is using them. Do not broaden the scope with recursive globs or follow links to clean up data outside the repository.
- Record the targets' disk usage and available disk space. Keep source code and dependencies still needed; when the goal is only to free space, prioritize caches rather than discarding historical work to save a few KB of documentation.
- Check committed, uncommitted, untracked, and ignored content in each worktree. Move or archive unique material outside the cleanup scope and verify its integrity before using `git worktree remove`; keep worktrees with remaining unique work. Keep branches by default when only retiring worktrees. If the user also requests branch cleanup, handle verified, authorized branches directly. For squash merges or detached HEAD, read [Worktree Verification](references/worktrees.md) as needed; do not infer that work has been merged from a branch name or status.
- When cleaning output directories, distinguish rebuildable intermediates from deliverables that must be kept; copy and verify retained files first when necessary. Uncertainty about one candidate does not block other cleanup.
- Put temporary archives in an existing locally ignored location or one specified by the user. Do not commit private material to Git. Do not automatically delete newly saved archives after cleanup.

## Simplify Documentation and Rules

Choose a destination based on content, without a fixed reduction percentage or file count:

| Destination | Criteria |
| --- | --- |
| Keep in the entry document | README purpose, startup instructions needed by its readers, and confirmed current state; project-specific AGENTS conventions that frequently affect implementation |
| Move to an on-demand reference | Still-valid installation, migration, release, language, or framework details needed only for particular tasks; prefer links to existing documentation |
| Historical archive | Plans, decisions, and acceptance evidence from completed phases, with a link for future reference |
| Delete or consolidate | Duplicate explanations, general knowledge the model already has, vague slogans, and rules confirmed to be obsolete; keep one authoritative location for each piece of information |

Resolve conflicts using the current user's decisions and the priority of applicable rules. Correct them directly when evidence is sufficient; ask only about unresolved contradictions that affect the result. Repair relative links and references after moving content, and avoid creating more duplicate documentation in the name of simplification. Shape the README for the actual readers of a personal, internal, or public project rather than applying an open-source template by default.

When the user asks to relax boundaries, replace mandatory item-by-item approval or indiscriminate full testing with “proceed autonomously once the goal is clear, do not repeat requests for existing authorization, and validate according to the changes.” This adjusts collaboration rules; it does not automatically remove product validation, permissions, privacy, or data protection mechanisms.

Do not assume other repositories share an example's technology stack, platform, or commit practices. Base platform descriptions on current evidence. Flag conflicting evidence for verification rather than choosing a conclusion without support. If configuration also needs updating, address the affected checks as part of the change.

## Verify and Deliver

Confirm that deletion targets are gone, retained material is intact, documentation links work, modified configuration parses, and the Git diff keeps this task's changes separate from the user's changes. Run the necessary affected checks. Documentation cleanup does not require a full build; avoid immediately rebuilding every cache after clearing it without a reason.

Report what was actually cleaned up, documentation sizes before and after simplification, corrections, validation, and unfinished items. Distinguish reduced directory usage from increased free disk space: shared blocks, snapshots, and other processes can affect both. Label estimates when measurement is unavailable. Explain relevant follow-up effects, such as caches needing to rebuild on the next compilation.

Follow repository rules and current authorization for commits, pushes, releases, and communication logs; this skill does not independently require those actions. Preserve the user's uncommitted work as-is.

Example invocation: `Use $repo-cleanup to organize the current repository, remove caches confirmed to be unnecessary and worktrees whose work has been merged, correct outdated instructions, and simplify README and AGENTS.`
