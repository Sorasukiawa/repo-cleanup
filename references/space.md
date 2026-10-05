# Reclaim Space Inside the Repository

Read this for cache, build-output, and "what can be deleted" tasks. Contents: scope, inventory, candidates by ecosystem, removal, measurement.

## Scope

The scope is the repository root and its registered worktrees. Caches outside it, such as Xcode `~/Library/Developer/Xcode/DerivedData`, `~/.npm`, the pnpm store, `~/.cargo`, Docker images, or Homebrew, are general disk cleanup: mention them only when the user asks about overall disk space, and treat them as a separate task.

## Inventory

List ignored and untracked content collapsed by directory, then measure the candidates:

```bash
git ls-files --others --ignored --exclude-standard --directory
git ls-files --others --exclude-standard --directory
git clean -ndX          # preview only
du -sh -- <candidate>
df -h .
```

`git clean -ndX` is a useful preview of ignored content, but it also lists `.env`, local configuration, and other ignored files that must stay. Never run `git clean -fdX` or `git clean -fdx` on a whole repository or worktree; remove verified paths individually.

Check whether a build, test runner, watcher, or dev server is using a candidate before removing it (for example `lsof +D <dir>` on a small directory, or the listening ports and processes of the project's dev tools). A failed or empty check does not prove the directory is idle.

## Candidates by Ecosystem

Prefer the project's own clean script, then the tool's clean command, over manual removal when they exist and stay inside the repository.

| Ecosystem | Usually regenerable | Prefer | Keep or check first |
| --- | --- | --- | --- |
| JavaScript / TypeScript | `.next/`, `.nuxt/`, `.turbo/`, `.parcel-cache/`, `node_modules/.cache/`, `node_modules/.vite/`, `dist/`, `build/`, `coverage/`, `*.tsbuildinfo` | `npm run clean` or the equivalent project script | `node_modules/` is a dependency install, not a cache: remove only when broken or requested. Lockfiles always stay. |
| Python | `__pycache__/`, `.pytest_cache/`, `.mypy_cache/`, `.ruff_cache/`, `build/`, `*.egg-info/` | Project script | `.venv/` is an environment; keep unless requested |
| Rust | `target/` | `cargo clean` | A full rebuild can take long; mention the cost |
| Swift / Xcode | `.build/` (SwiftPM), project-local `build/` or `DerivedData/` | `swift package clean`, `xcodebuild clean` | `Pods/` only when `Podfile.lock` exists and pods are not committed; `*.xcarchive` and `.ipa` may be the only release build |
| JVM / Android | `build/`, `app/build/`, project `.gradle/` | `./gradlew clean` | `local.properties`, keystores, and signing files stay |
| General | `tmp/`, `.cache/`, `*.log` | | Release packages, installers, screenshots or JSON read by tests, and acceptance evidence |

Keep source code and dependencies still needed. Prioritize large caches over historical documents that save only a few KB.

## Removal

- Remove only paths on the exact list for this round, one verified path at a time (`rm -rf -- "<path>"` in Bash, or the PowerShell form in [Windows cleanup](windows.md)). Never pass globs or a parent directory whose children include unverified links.
- Distinguish rebuildable intermediates from deliverables in output directories; copy and verify retained files first when necessary.
- Avoid deleting and reinstalling all development dependencies. Do not rebuild every cache immediately after clearing it without a reason.
- Confirm each target is gone and retained files are intact.

## Measurement

Record each target's usage before removal and the free disk space before and after. Report reduced directory usage and increased free space separately: hardlinked package stores (pnpm), APFS snapshots and purgeable space, NTFS compression, cloud placeholders, and other running processes can all make them differ. Label estimates when measurement is unavailable, and mention follow-up effects such as the next build taking longer.
