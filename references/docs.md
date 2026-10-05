# Review and Organize Documentation and Rules

Read this when README, AGENTS.md, CLAUDE.md, or other project documentation is in scope. Contents: goal, checks, destinations, entry documents, collaboration rules, reporting.

## Goal

Documentation should be correct and accessible, supporting its readers and project decisions. Simplification is an optional means when the user requests it or evidence shows redundancy or unnecessary reading overhead; shorter files are not a default goal. Leave suitable content unchanged. Correct, clarify, or add missing information when that better serves the task, even if the document grows.

## Checks

Inspect the affected documents, their readers, their links, and the code or configuration needed to verify their claims:

| Check | How to verify |
| --- | --- |
| Commands work as written | Compare with `package.json` scripts, Makefiles, CI workflows, and tool configuration. Run cheap read-only commands (`--help`, `--version`) when safe; do not run builds only to verify documentation. |
| Claims match the current code | Paths, module names, platforms, versions, environment variables, and feature status against current files and confirmed product scope |
| Links and references resolve | Relative links, anchors, and referenced files, especially after moving content |
| Readers find what they need | README: purpose, setup, and usage for its actual readers. AGENTS.md or CLAUDE.md: commands, constraints, pitfalls, and validation requirements that affect implementation |
| One authoritative location per fact | Duplicates point to one source; translations name the source language they follow |
| Contradictions | List conflicting instructions before rewriting either side |
| Current state versus phase notes | Completed plans and temporary restrictions are not presented as current rules |

## Choose a Destination

When a change is warranted, choose a destination based on content, without a fixed reduction percentage or file count:

| Destination | Criteria |
| --- | --- |
| Keep in the entry document | README purpose, startup instructions needed by its readers, and confirmed current state; project-specific AGENTS or CLAUDE.md conventions that frequently affect implementation |
| Move to an on-demand reference | Still-valid installation, migration, release, language, or framework details needed only for particular tasks; prefer links to existing documentation |
| Historical archive | Plans, decisions, and acceptance evidence from completed phases, with a link for future reference |
| Delete or consolidate | Duplicate explanations, vague slogans, and rules confirmed to be obsolete; keep one authoritative location for each piece of information |

Repair relative links and references after moving content, and avoid creating duplicate documentation while reorganizing it.

## Entry Documents

README serves its actual readers: retain the background, setup, and usage information they need even when the model already knows it. Shape it for the readers of a personal, internal, or public project rather than applying an open-source template by default.

AGENTS.md and CLAUDE.md serve implementation decisions: preserve useful project commands, constraints, pitfalls, and validation requirements regardless of length; remove generic guidance only when it adds no value to those decisions. When one file imports the other (for example a CLAUDE.md containing `@AGENTS.md`), edit the source rather than the import stub, and keep the import working.

Put temporary restrictions and phase arrangements in progress documents with their applicable phase; do not turn unaccepted model suggestions into standing rules. Update phase guidance using the user's current goal and existing authorization.

Do not assume other repositories share an example's technology stack, platform, or commit practices. Base platform descriptions on current evidence, and flag conflicting evidence for verification rather than choosing a conclusion without support. If configuration also needs updating, address the affected checks as part of the change.

## Collaboration Rules

Resolve conflicts using the current user's decisions and the priority of applicable rules. Correct them directly when evidence is sufficient; ask only about unresolved contradictions that affect the result.

When the user asks to relax how an agent collaborates, for example replacing mandatory item-by-item approval or indiscriminate full test runs with autonomous progress and change-matched validation, rewrite only the collaboration rules. Product validation, permissions, privacy, and data protection mechanisms stay unless the user removes them explicitly.

## Reporting

For each changed document, give one line: what changed and the evidence (for example "README: `npm run start` → `npm run dev`, matching package.json scripts"). List suspected problems that could not be verified separately instead of editing them. Include sizes before and after only when the user cares about reduction.
