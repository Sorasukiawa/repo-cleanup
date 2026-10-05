# Reclaim Space Used by a Project

Read this for cache, build-output, generated-data, and "what can be deleted" tasks. Contents: scope, inventory, candidates by ecosystem, generated test data, removal, measurement.

## Scope

The scope is everything the project produces: the repository root, its registered worktrees, and project-owned outputs outside the repository. A path outside the repository is project-owned when the project directs output there or names it after the project:

- a Cargo `target-dir` in `.cargo/config.toml`, or a `CARGO_TARGET_DIR` / `--target-dir` the project's scripts or docs use, including per-task directories such as `/tmp/<project>-<task>`;
- an `xcodebuild -derivedDataPath`, and Xcode `~/Library/Developer/Xcode/DerivedData/<Project>-<hash>` folders whose `info.plist` `WorkspacePath` points into this repository or one of its worktrees (including worktrees since removed);
- render, export, or test output directories named in the project's scripts, docs, AGENTS.md, or CLAUDE.md.

Shared caches that serve every project, such as `~/.npm`, the pnpm store, `~/.cargo/registry`, Homebrew, Docker images, simulator runtimes, or Xcode's shared module caches, stay out of scope; mention them only when the user asks about overall disk space, as a separate task.

## Inventory

`scripts/survey.sh --sizes` lists ignored entries largest first and the project-owned outputs it can find outside the repository. Treat its outputs list as candidates: confirm ownership (a "name match only" DerivedData folder may belong to another checkout with the same name) and check that nothing is using them. Also read the project's build scripts and agent rules for output locations the survey cannot infer.

Without the script, list ignored and untracked content collapsed by directory, then measure the candidates:

```bash
git ls-files --others --ignored --exclude-standard --directory
git ls-files --others --exclude-standard --directory
git clean -ndX          # preview only
du -sh -- <candidate>
df -h .
```

`git clean -ndX` is a useful preview of ignored content, but it also lists `.env`, local configuration, and other ignored files that must stay. Never run `git clean -fdX` or `git clean -fdx` on a whole repository or worktree; remove verified paths individually.

A collapsed entry such as `distribution/` can hide most of the space. Descend into any entry of 1 GiB or more until the parts are distinguishable (installers, generated media, build caches, evidence) before deciding.

Check whether a build, test runner, watcher, or dev server is using a candidate before removing it (for example `lsof +D <dir>` on a small directory, or the listening ports and processes of the project's dev tools). A failed or empty check does not prove the directory is idle. A directory an active task is writing to stays, even if it is regenerable.

When free space is low (under about 10 GiB or 5 % of the volume) or the user says space is short, sort the candidates by size, handle the largest regenerable ones first, and report the total reclaimed and the total still reclaimable after the user's decisions.

## Candidates by Ecosystem

Prefer the project's own clean script, then the tool's clean command, over manual removal when they exist and stay within the project's outputs.

| Ecosystem | Usually regenerable | Prefer | Keep or check first |
| --- | --- | --- | --- |
| JavaScript / TypeScript | `.next/`, `.nuxt/`, `.turbo/`, `.parcel-cache/`, `node_modules/.cache/`, `node_modules/.vite/`, `dist/`, `build/`, `coverage/`, `*.tsbuildinfo` | `npm run clean` or the equivalent project script | `node_modules/` is a dependency install, not a cache: remove only when broken or requested. Lockfiles always stay. |
| Python | `__pycache__/`, `.pytest_cache/`, `.mypy_cache/`, `.ruff_cache/`, `build/`, `*.egg-info/` | Project script | `.venv/` is an environment; keep unless requested |
| Rust | `target/`, or the project's custom `target-dir` and per-task target directories | `cargo clean`, `cargo clean --target-dir <dir>` | A full rebuild can take long; mention the cost. Keep a release build that is the only copy of a deliverable |
| Swift / Xcode | `.build/` (SwiftPM), project-local `build/`, a custom `-derivedDataPath`, and this project's `DerivedData/<Project>-<hash>` | `swift package clean`, `xcodebuild clean` | `Pods/` only when `Podfile.lock` exists and pods are not committed; `*.xcarchive` and `.ipa` may be the only release build. DerivedData of a workspace that no longer exists is stale |
| JVM / Android | `build/`, `app/build/`, project `.gradle/` | `./gradlew clean` | `local.properties`, keystores, and signing files stay |
| General | `tmp/`, `.cache/`, `*.log` | | Release packages, installers, screenshots or JSON read by tests, and small acceptance evidence |

Keep source code and dependencies still needed. Prioritize large caches over historical documents that save only a few KB.

## Generated Test Data

Test runs often leave the largest files in a project: synthetic footage, proxies, previews, NLE or render exports, database snapshots, and failed-run temporaries. Split each run directory into two parts:

- **The record**: generator scripts, logs, thread dumps, screenshots, JSON or Markdown reports, and project files (for example FCP libraries, Resolve projects, XML). These are small; keep them.
- **The bulk**: media and data the generator or a re-run can recreate. Propose deleting it, with its size, the regeneration command, and what goes offline until it is regenerated (projects that reference the files, a retest that needs them). Failed-run samples are worth keeping only while someone is investigating that failure; say so and let the user decide.

In an inspect-only or narrowly scoped task (for example "clean build caches"), list the bulk as pending with a recommendation instead of deleting it. Do not silently keep it.

## Removal

- Remove only paths on the exact list for this round, one verified path at a time (`rm -rf -- "<path>"` in Bash, or the PowerShell form in [Windows cleanup](windows.md)). Never pass globs or a parent directory whose children include unverified links.
- Distinguish rebuildable intermediates from deliverables in output directories; copy and verify retained files first when necessary.
- Avoid deleting and reinstalling all development dependencies. Do not rebuild every cache immediately after clearing it without a reason.
- Confirm each target is gone and retained files are intact.

## Measurement

Record each target's usage before removal and the free disk space before and after. Report reduced directory usage and increased free space separately: hardlinked package stores (pnpm), APFS snapshots and purgeable space, NTFS compression, cloud placeholders, and other running processes can all make them differ. Label estimates when measurement is unavailable, and mention follow-up effects such as the next build taking longer or media needing regeneration before a retest.
