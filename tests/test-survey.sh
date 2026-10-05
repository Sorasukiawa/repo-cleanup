#!/usr/bin/env bash
# Regression tests for scripts/survey.sh and for the Git behaviors the skill's references rely on.
# Builds fresh fixtures in a temporary directory; touches nothing else.
# Usage: tests/test-survey.sh [--keep]
set -uo pipefail

here=$(cd "$(dirname "$0")" && pwd -P)
skill=$(cd "$here/.." && pwd -P)
tmp=$(mktemp -d "${TMPDIR:-/tmp}/repo-cleanup-test.XXXXXX") && tmp=$(cd "$tmp" && pwd -P)
[ "${1:-}" = --keep ] && echo "keeping fixtures in $tmp" || trap 'rm -rf "$tmp"' EXIT

export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
export GIT_AUTHOR_NAME=fixture GIT_AUTHOR_EMAIL=fixture@example.invalid
export GIT_COMMITTER_NAME=fixture GIT_COMMITTER_EMAIL=fixture@example.invalid

failures=0
pass() { echo "  [PASS] $1"; }
fail() { echo "  [FAIL] $1"; failures=$((failures + 1)); }
check() { if [ "$2" = "$3" ]; then pass "$1"; else fail "$1 (expected '$3', got '$2')"; fi; }

fx=$tmp/fx
bash "$skill/tests/make-fixtures.sh" "$fx" >/dev/null || { echo "fixture build failed"; exit 1; }
repo=$fx/repo

# Column of a worktree row (tab-separated, matched by path suffix) or a branch row (matched by name).
wt_col() { awk -F'\t' -v p="$fx/wt/$1" -v c="$2" '$1 == p { print $c; exit }' "$tmp/survey.out"; }
br_col() { awk -F'\t' -v b="$1" -v c="$2" '/^## local branches/ { on = 1; next } on && $1 == b { print $c; exit }' "$tmp/survey.out"; }

printf 'log\n' >"$repo/构建日志.log"

echo "survey.sh: read-only"
stamp=$tmp/stamp
touch "$stamp"
sleep 1
bash "$skill/scripts/survey.sh" --repo "$repo" --base main --sizes >"$tmp/survey.out" 2>"$tmp/survey.err"
check "exit code 0" "$?" 0
check "no stderr output" "$(cat "$tmp/survey.err")" ""
changed=$(find "$fx" -newer "$stamp" -print | head -n 5)
check "no file under the fixture changed (index, refs, worktrees)" "$changed" ""

echo "survey.sh: worktree rows (path ref head flags tracked untracked ignored ahead in_base)"
check "merged: in base" "$(wt_col merged 9)" yes
check "merged: clean" "$(wt_col merged 5)/$(wt_col merged 6)/$(wt_col merged 7)" 0/0/0
check "squash: not an ancestor (needs PR evidence)" "$(wt_col squash 9)" no
check "squash-later: two commits ahead" "$(wt_col squash-later 8)" 2
check "wip: one tracked change" "$(wt_col wip 5)" 1
check "wip: one untracked file" "$(wt_col wip 6)" 1
check "ignored: in base" "$(wt_col ignored 9)" yes
check "ignored: three collapsed ignored entries" "$(wt_col ignored 7)" 3
check "detached-merged: detached and in base" "$(wt_col detached-merged 2) $(wt_col detached-merged 9)" "(detached) yes"
check "detached-orphan: one commit outside base" "$(wt_col detached-orphan 8) $(wt_col detached-orphan 9)" "1 no"
case $(wt_col locked 4) in locked*) pass "locked: flagged with reason" ;; *) fail "locked: flag missing" ;; esac
case $(wt_col vanished 4) in *prunable*missing*) pass "vanished: prunable and missing" ;; *) fail "vanished: flags '$(wt_col vanished 4)'" ;; esac
grep -q "^$fx/wt/ignored	\.env	" "$tmp/survey.out" && pass "ignored .env listed" || fail "ignored .env not listed"
grep -q "^$fx/wt/wip	?? notes.md" "$tmp/survey.out" && pass "untracked notes.md listed" || fail "untracked notes.md not listed"
grep -q "^$repo	构建日志.log	[0-9]*K$" "$tmp/survey.out" && pass "non-ASCII ignored name printed verbatim with size" || fail "non-ASCII ignored name escaped or unsized"

echo "survey.sh: branch rows (branch tip upstream track worktree ahead in_base)"
check "gone-merged: [gone] and in base" "$(br_col gone-merged 4) $(br_col gone-merged 7)" "[gone] yes"
check "gone-unique: [gone] but not in base" "$(br_col gone-unique 4) $(br_col gone-unique 7)" "[gone] no"
check "feat-squash: checked out in its worktree" "$(br_col feat-squash 5)" "$fx/wt/squash"

echo "survey.sh: arguments"
bash "$skill/scripts/survey.sh" --repo "$repo" --base no-such-ref >/dev/null 2>&1
check "unresolvable --base exits 2" "$?" 2
bash "$skill/scripts/survey.sh" --repo "$tmp" >/dev/null 2>&1
check "non-repository exits 2" "$?" 2
nobase=$(bash "$skill/scripts/survey.sh" --repo "$repo")
printf '%s\n' "$nobase" | grep -q '^base	(not set' && pass "no --base: target is not guessed" || fail "no --base: unexpected base line"

echo "fixture gh stub: squash-merge evidence"
pr_head() { PATH="$fx/bin:$PATH" gh pr list --head "$1" --base main --state merged --json headRefOid | sed -n 's/.*"headRefOid":"\([0-9a-f]*\)".*/\1/p'; }
check "feat-squash: tip equals headRefOid" "$(pr_head feat-squash)" "$(git -C "$repo" rev-parse feat-squash)"
[ "$(pr_head feat-squash-later)" != "$(git -C "$repo" rev-parse feat-squash-later)" ] && pass "feat-squash-later: tip differs from headRefOid" || fail "feat-squash-later: tip should differ"
merge_oid=$(PATH="$fx/bin:$PATH" gh pr list --head feat-squash --json mergeCommit | sed -n 's/.*"oid":"\([0-9a-f]*\)".*/\1/p')
git -C "$repo" merge-base --is-ancestor "$merge_oid" main && pass "feat-squash: mergeCommit is in main" || fail "feat-squash: mergeCommit not in main"
check "unknown branch: empty result" "$(PATH="$fx/bin:$PATH" gh pr list --head nope --state merged --json number)" "[]"

echo "documented Git behaviors (references/*.md depend on these)"
full=$(git -C "$fx/wt/ignored" ls-files --others --ignored --exclude-standard | awk 'END { print NR }')
collapsed=$(git -C "$fx/wt/ignored" ls-files --others --ignored --exclude-standard --directory | awk 'END { print NR }')
[ "$collapsed" -lt "$full" ] && pass "--directory collapses ignored directories ($full -> $collapsed lines)" || fail "--directory did not collapse"
git -C "$repo" clean -ndX | grep -q '^Would remove \.env$' && pass "git clean -ndX lists .env as removable" || fail "git clean -ndX does not list .env"
git -C "$repo" merge-base --is-ancestor feat-merged main; check "merge-base --is-ancestor: 0 when included" "$?" 0
git -C "$repo" merge-base --is-ancestor feat-wip main; check "merge-base --is-ancestor: 1 when not included" "$?" 1
git -C "$repo" merge-base --is-ancestor 0000000000000000000000000000000000000000 main 2>/dev/null; rc=$?
[ "$rc" -gt 1 ] && pass "merge-base --is-ancestor: >1 on error ($rc)" || fail "merge-base --is-ancestor: error code $rc"

probe=$tmp/probe
git -C "$repo" worktree add -q "$probe" -b probe main
printf 'SECRET=1\n' >"$probe/.env"
git -C "$repo" worktree remove "$probe"; rc=$?
[ "$rc" -eq 0 ] && [ ! -e "$probe/.env" ] && pass "git worktree remove deletes ignored .env without --force" || fail "worktree remove kept ignored files (rc=$rc)"
git -C "$repo" worktree add -q "$probe" probe
printf 'note\n' >"$probe/notes.md"
git -C "$repo" worktree remove "$probe" 2>/dev/null; rc=$?
[ "$rc" -ne 0 ] && [ -e "$probe/notes.md" ] && pass "git worktree remove refuses untracked files" || fail "worktree remove did not refuse untracked files"
git -C "$repo" branch -d gone-merged >/dev/null 2>&1; check "git branch -d deletes a branch merged into HEAD" "$?" 0
git -C "$repo" branch -d gone-unique >/dev/null 2>&1; rc=$?
[ "$rc" -ne 0 ] && pass "git branch -d refuses an unmerged branch" || fail "git branch -d deleted an unmerged branch"
git -C "$repo" worktree prune --dry-run -v 2>&1 | grep -q vanished && pass "worktree prune --dry-run reports the vanished registration" || fail "prune --dry-run missed the vanished worktree"

echo
if [ "$failures" -eq 0 ]; then echo "test-survey: all checks passed"; else echo "test-survey: $failures check(s) failed"; exit 1; fi
