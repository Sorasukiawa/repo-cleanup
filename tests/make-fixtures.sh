#!/usr/bin/env bash
# Build a disposable fixture repository covering the cleanup scenarios repo-cleanup must judge correctly.
# Usage: tests/make-fixtures.sh <new-or-empty-dir>
# Layout: <dir>/origin.git (bare remote), <dir>/repo (main checkout), <dir>/wt/* (linked worktrees),
#         <dir>/bin/gh (offline PR lookup stub), <dir>/env.sh (puts the stub first on PATH),
#         <dir>/expected.tsv (the decision each scenario should get).
set -euo pipefail

out=${1:?usage: make-fixtures.sh <new-or-empty-dir>}
if [ -e "$out" ] && [ -n "$(ls -A "$out")" ]; then
  echo "make-fixtures.sh: refusing to use non-empty $out" >&2
  exit 2
fi
mkdir -p "$out/wt" "$out/bin" "$out/prs"
out=$(cd "$out" && pwd -P)

# Isolate from the user's Git configuration (signing, hooks, default branch).
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
export GIT_AUTHOR_NAME=fixture GIT_AUTHOR_EMAIL=fixture@example.invalid
export GIT_COMMITTER_NAME=fixture GIT_COMMITTER_EMAIL=fixture@example.invalid

repo=$out/repo
g() { git -C "$repo" "$@"; }
# commit_in <dir> <file> <content> <message>
commit_in() { printf '%s\n' "$3" >"$1/$2" && git -C "$1" add -- "$2" && git -C "$1" commit -q -m "$4"; }
# record_pr <branch> <number> <head sha> <merge commit sha>
record_pr() {
  printf '[{"number":%s,"url":"https://example.invalid/fixture/pull/%s","headRefOid":"%s","baseRefName":"main","headRepositoryOwner":{"login":"fixture"},"mergeCommit":{"oid":"%s"}}]\n' \
    "$2" "$2" "$3" "$4" >"$out/prs/$1.json"
}

git init -q --bare -b main "$out/origin.git"
git init -q -b main "$repo"

cat >"$repo/.gitignore" <<'EOF'
.env
node_modules/
dist/
*.log
EOF
cat >"$repo/package.json" <<'EOF'
{
  "name": "fixture-app",
  "private": true,
  "scripts": {
    "dev": "node src/index.js",
    "build": "node -e \"require('fs').mkdirSync('dist',{recursive:true})\"",
    "test": "node --test"
  }
}
EOF
mkdir -p "$repo/src" "$repo/docs"
printf 'console.log("fixture");\n' >"$repo/src/index.js"
cat >"$repo/README.md" <<'EOF'
# fixture-app

Start the development server:

```bash
npm run start
```

See [setup guide](docs/setup.md) for environment variables.
EOF
cat >"$repo/docs/old-plan.md" <<'EOF'
# Phase 1 plan (completed)

- [x] Scaffold the app
- [x] Add the development server
EOF
g add -A && g commit -q -m "chore: initial commit"
g remote add origin "$out/origin.git"
g push -q -u origin main
g remote set-head origin main

# Ignored content in the main checkout: regenerable output next to a local secret.
mkdir -p "$repo/dist" "$repo/node_modules/left-pad"
printf 'bundle\n' >"$repo/dist/bundle.js"
printf 'module.exports = 1;\n' >"$repo/node_modules/left-pad/index.js"
printf 'API_TOKEN=fixture-not-a-real-secret\n' >"$repo/.env"
printf 'debug\n' >"$repo/debug.log"

# 1. Merged with a merge commit: HEAD is an ancestor of main.
g worktree add -q "$out/wt/merged" -b feat-merged main
commit_in "$out/wt/merged" merged.txt merged "feat: merged work"
g merge -q --no-ff feat-merged -m "Merge feat-merged"

# 2. Squash-merged, local tip equals the PR head.
g worktree add -q "$out/wt/squash" -b feat-squash main
commit_in "$out/wt/squash" squash.txt squash "feat: squash work"
git -C "$out/wt/squash" push -q -u origin feat-squash
g merge -q --squash feat-squash >/dev/null && g commit -q -m "feat: squash work (#2)"
record_pr feat-squash 2 "$(g rev-parse feat-squash)" "$(g rev-parse HEAD)"

# 3. Squash-merged, then a commit was added after the merge.
g worktree add -q "$out/wt/squash-later" -b feat-squash-later main
commit_in "$out/wt/squash-later" later.txt v1 "feat: later work"
git -C "$out/wt/squash-later" push -q -u origin feat-squash-later
g merge -q --squash feat-squash-later >/dev/null && g commit -q -m "feat: later work (#3)"
record_pr feat-squash-later 3 "$(g rev-parse feat-squash-later)" "$(g rev-parse HEAD)"
commit_in "$out/wt/squash-later" later.txt v2 "fix: follow-up after merge"

# 4. Unmerged work with uncommitted and untracked files.
g worktree add -q "$out/wt/wip" -b feat-wip main
commit_in "$out/wt/wip" wip.txt wip "feat: work in progress"
printf 'console.log("edited");\n' >"$out/wt/wip/src/index.js"
printf 'ideas that exist nowhere else\n' >"$out/wt/wip/notes.md"

# 5. Merged, but holds ignored files: a local secret plus regenerable output.
g worktree add -q "$out/wt/ignored" -b feat-ignored main
commit_in "$out/wt/ignored" ignored.txt ignored "feat: ignored-files case"
g merge -q --no-ff feat-ignored -m "Merge feat-ignored"
printf 'LOCAL_TOKEN=only-copy-of-this-value\n' >"$out/wt/ignored/.env"
mkdir -p "$out/wt/ignored/node_modules/pkg" "$out/wt/ignored/dist"
printf 'module.exports = 2;\n' >"$out/wt/ignored/node_modules/pkg/index.js"
printf '{"name":"pkg"}\n' >"$out/wt/ignored/node_modules/pkg/package.json"
printf 'out\n' >"$out/wt/ignored/dist/out.js"

# 6. Detached HEAD reachable from main.
g worktree add -q --detach "$out/wt/detached-merged" main~1

# 7. Detached HEAD with a commit no ref contains.
g worktree add -q --detach "$out/wt/detached-orphan" main
commit_in "$out/wt/detached-orphan" orphan.txt orphan "spike: detached experiment"

# 8. Locked worktree (another session may be using it).
g worktree add -q "$out/wt/locked" -b feat-locked main
g worktree lock --reason "in use by another agent session" "$out/wt/locked"

# 9. Registered worktree whose directory was deleted by hand.
g worktree add -q "$out/wt/vanished" -b feat-vanished main
rm -rf "$out/wt/vanished"

# 10. Branch-only: merged, upstream deleted on the remote ([gone]).
g switch -q -c gone-merged main
commit_in "$repo" gone-merged.txt gm "feat: gone but merged"
g push -q -u origin gone-merged
g switch -q main
g merge -q --no-ff gone-merged -m "Merge gone-merged"

# 11. Branch-only: unmerged, upstream deleted on the remote ([gone]).
g switch -q -c gone-unique main
commit_in "$repo" gone-unique.txt gu "feat: gone and unmerged"
g push -q -u origin gone-unique
g switch -q main

g push -q origin main
git -C "$out/origin.git" branch -q -D gone-merged gone-unique
g fetch -q --prune origin

cat >"$out/bin/gh" <<'EOF'
#!/usr/bin/env bash
# Offline stand-in for `gh pr list --head <branch> --state merged --json ...` in repo-cleanup fixtures.
root=$(cd "$(dirname "$0")/.." && pwd -P)
if [ "${1:-}" != pr ] || [ "${2:-}" != list ]; then
  echo "fixture gh only supports: gh pr list --head <branch> [--base main] [--state merged] [--json ...]" >&2
  exit 1
fi
head=
while [ $# -gt 0 ]; do
  case $1 in --head) head=${2:-}; shift 2 ;; *) shift ;; esac
done
if [ -n "$head" ] && [ -f "$root/prs/$head.json" ]; then cat "$root/prs/$head.json"; else echo '[]'; fi
EOF
chmod +x "$out/bin/gh"
printf 'export PATH="%s/bin:$PATH"\n' "$out" >"$out/env.sh"

cat >"$out/expected.tsv" <<EOF
item	expected	reason
wt/merged	retire	HEAD is an ancestor of main; clean; no ignored files
wt/squash	retire	merged PR #2 into main; local tip equals headRefOid; merge commit is in main
wt/squash-later	keep	merged PR #3 but local tip has a commit after headRefOid
wt/wip	keep	unmerged commit, modified tracked file, untracked notes.md
wt/ignored	preserve .env, then retire	merged, but ignored .env is the only copy; git worktree remove would delete it
wt/detached-merged	retire	detached HEAD reachable from main; clean
wt/detached-orphan	keep	detached commit contained in no ref
wt/locked	keep	locked by another session
wt/vanished	prune registration after dry run	directory already deleted; registration is prunable
branch gone-merged	delete with -d when branch cleanup is in scope	[gone] upstream and ancestor of main
branch gone-unique	keep	[gone] upstream but its commit is not in main
branch feat-squash	delete with -D only after its worktree is retired and branch cleanup is in scope	squash-merged; tip equals PR head
branch feat-squash-later	keep	tip is ahead of the merged PR head
repo/.env	keep	ignored local secret
repo/dist/	removable cache	ignored build output, rebuilt by npm run build
repo/node_modules/	keep unless dependencies are the target	dependency install, not a cache
repo/debug.log	removable	ignored log file
repo/README.md	fix	npm run start does not exist (use npm run dev); docs/setup.md is missing
repo/docs/old-plan.md	keep or archive	completed phase plan with historical value
EOF

echo "fixture ready: $out"
echo "  repo: $out/repo    worktrees: $out/wt    expected decisions: $out/expected.tsv"
echo "  for squash-merge evidence run: source $out/env.sh"
