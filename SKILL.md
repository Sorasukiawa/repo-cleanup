---
name: repo-cleanup
description: Use when the user asks to clean up or organize a source repository, assess useful versus redundant files, retire unneeded worktrees, or review and organize project documentation such as README and AGENTS. Not for general disk cleanup or installed Codex component maintenance.
license: MIT
---

# Repository Cleanup and Organization

Keep repository contents useful and documentation accurate, easy to navigate, and actionable; reclaim unnecessary storage when requested. Use the user's language for conversation and reports; if no language is indicated, default to Simplified Chinese. Keep cleanup within the current request, without unrelated application refactoring.

## Follow the Request

- “See what is useful and what can be deleted” or “inspect only”: take a read-only inventory. Do not start services, run builds, delete or edit files, or commit.
- “Clean up, organize, or fix” or “execute the list”: verify the current state, then complete the authorized scope without asking about each item or repeating permission requests.
- If missing facts affect only one item, handle the other confirmed items first. Ask only when essential information is missing or an action clearly exceeds authorization and has substantial impact.

## Establish What Each Item Is For

Identify the host OS, active shell, and actual repository root before choosing commands. Inspect applicable rules and Git status, then match the inventory to the requested work:

- Space cleanup: inspect candidate sizes, ignore rules, regeneration paths, and relevant process or file usage; measure available disk space.
- Worktree or branch retirement: read [Worktree Verification](references/worktrees.md) for every such task, identify ownership and active use, and check history and unique content as required by the retirement method.
- Documentation cleanup: inspect the affected documents, their readers, links, and the code or configuration needed to verify their claims. A documentation-only task does not require a repository-wide size or worktree audit.

For Windows filesystem cleanup or worktree operations, read [Windows cleanup](references/windows.md) for path, link, and file-lock handling. Read documentation structure and relevant sections first, without loading entire histories just for cleanup.

Determine purpose from entry points, imports, tests, scripts, and release configuration. Treat filenames and modification dates only as clues:

| Type | Default action |
| --- | --- |
| Source code, lockfiles, tests, brand master assets, applicable rules | Keep; trace the purpose of apparent duplicates first |
| Regenerable caches, temporary output, intermediate build files | Verify contents and disk usage, then clean up; avoid deleting and reinstalling all development dependencies |
| Worktrees considered for retirement | Check ongoing use and reuse needs, then preserve their work using the appropriate managed or ordinary Git workflow; a merged PR alone is not a reason to retire a worktree |
| Old designs, frozen UI, progress reports, old release packages | May have historical value; archive or consolidate as requested. Frozen does not mean unused |
| Outdated instructions, broken paths, inconsistent configuration | Correct using evidence from current code and confirmed product scope |

`.gitignore` is not a deletion list. Screenshots or JSON read by tests, acceptance evidence in hidden directories, and the only installer in a build directory may all be useful. Do not claim real application behavior has been verified based on browser mocks.

## Clean Up and Retire Worktrees

- Create an exact path list for this round of deletions, checking resolved paths and link boundaries. Check processes or open handles for directories that builds, tests, or services may use; a failed check does not establish that nothing is using them. Do not broaden the scope with recursive globs or follow links to clean up data outside the repository.
- When reclaiming space, record the targets' disk usage and available disk space. Keep source code and dependencies still needed; prioritize caches rather than discarding historical work to save a few KB of documentation.
- For worktree retirement, follow [Worktree Verification](references/worktrees.md). Use the native archive workflow for Codex-managed worktrees; use `git worktree remove` for ordinary Git worktrees after preserving unique work. Inspect committed, uncommitted, untracked, and ignored content in both cases. Keep branches by default when only retiring worktrees; handle branch cleanup separately when authorized.
- When cleaning output directories, distinguish rebuildable intermediates from deliverables that must be kept; copy and verify retained files first when necessary. Uncertainty about one candidate does not block other cleanup.
- Put temporary archives in an existing locally ignored location or one specified by the user. Do not commit private material to Git. Do not automatically delete newly saved archives after cleanup.

## Review and Organize Documentation and Rules

Review documentation when it is part of the requested scope. The goal is correct, accessible information that supports readers and project decisions. Simplification is an optional means when the user requests it or evidence shows redundancy or unnecessary reading overhead; shorter files are not a default goal. Leave suitable content unchanged. Correct, clarify, or add missing information when that better serves the task, even if the document grows.

When a change is warranted, choose a destination based on content, without a fixed reduction percentage or file count:

| Destination | Criteria |
| --- | --- |
| Keep in the entry document | README purpose, startup instructions needed by its readers, and confirmed current state; project-specific AGENTS conventions that frequently affect implementation |
| Move to an on-demand reference | Still-valid installation, migration, release, language, or framework details needed only for particular tasks; prefer links to existing documentation |
| Historical archive | Plans, decisions, and acceptance evidence from completed phases, with a link for future reference |
| Delete or consolidate | Duplicate explanations, vague slogans, and rules confirmed to be obsolete; keep one authoritative location for each piece of information |

README serves its actual readers: retain the background, setup, and usage information they need even when the model already knows it. AGENTS serves implementation decisions: preserve useful project commands, constraints, pitfalls, and validation requirements regardless of length; remove generic guidance only when it adds no value to those decisions. Put temporary restrictions and phase arrangements in progress documents with their applicable phase; do not turn unaccepted model suggestions into standing rules. Update phase guidance using the user's current goal and existing authorization.

Resolve conflicts using the current user's decisions and the priority of applicable rules. Correct them directly when evidence is sufficient; ask only about unresolved contradictions that affect the result. Repair relative links and references after moving content, and avoid creating duplicate documentation while reorganizing it. Shape the README for the actual readers of a personal, internal, or public project rather than applying an open-source template by default.

When the user asks to relax boundaries, replace mandatory item-by-item approval or indiscriminate full testing with “proceed autonomously once the goal is clear, do not repeat requests for existing authorization, and validate according to the changes.” This adjusts collaboration rules; it does not automatically remove product validation, permissions, privacy, or data protection mechanisms.

Do not assume other repositories share an example's technology stack, platform, or commit practices. Base platform descriptions on current evidence. Flag conflicting evidence for verification rather than choosing a conclusion without support. If configuration also needs updating, address the affected checks as part of the change.

## Verify and Deliver

Verify the affected outcomes: deletion targets are gone and retained material is intact; managed archives report success and retain recovery information; moved or edited documentation links resolve; changed configuration parses. Review the Git diff against the initial state to distinguish this task's changes from the user's changes. Run the necessary affected checks. Documentation cleanup does not require a full build; avoid immediately rebuilding every cache after clearing it without a reason.

Report actual changes, validation, and unfinished items. Include documentation sizes before and after only when the user cares about reduction. For space cleanup, distinguish reduced directory usage from increased free disk space: shared blocks, snapshots, and other processes can affect both. Label estimates when measurement is unavailable. Explain relevant follow-up effects, such as caches needing to rebuild on the next compilation.

Follow repository rules and current authorization for commits, pushes, releases, and communication logs; this skill does not independently require those actions. Preserve the user's uncommitted work as-is.

Example invocation: `Use $repo-cleanup to organize the current repository, remove unnecessary caches, retire worktrees no longer needed after preserving their work, and review README and AGENTS for accuracy and usability. Fix demonstrated issues and leave suitable content unchanged.`
