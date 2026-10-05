#!/usr/bin/env bash
# Static checks for the skill package: frontmatter, size, links, version, evals, and key safety rules.
# Usage: tests/check-skill.sh
set -uo pipefail

root=$(cd "$(dirname "$0")/.." && pwd -P)
cd "$root" || exit 1
failures=0
pass() { echo "  [PASS] $1"; }
fail() { echo "  [FAIL] $1"; failures=$((failures + 1)); }

frontmatter=$(awk 'NR == 1 && $0 == "---" { on = 1; next } on && $0 == "---" { exit } on' SKILL.md)
field() { printf '%s\n' "$frontmatter" | sed -n "s/^$1: //p"; }

echo "frontmatter"
name=$(field name)
[ "$name" = repo-cleanup ] && pass "name is repo-cleanup" || fail "name is '$name'"
printf '%s' "$name" | grep -Eq '^[a-z0-9]+(-[a-z0-9]+)*$' && pass "name format" || fail "name format"
[ "$(basename "$root")" = "$name" ] && pass "directory matches name" || echo "  [SKIP] directory is $(basename "$root"), not $name (fine for a clone; installs must use $name/)"
desc=$(field description)
[ -n "$desc" ] && [ ${#desc} -le 1024 ] && pass "description length ${#desc} <= 1024" || fail "description length ${#desc}"
compat=$(field compatibility)
[ ${#compat} -le 500 ] && pass "compatibility length ${#compat} <= 500" || fail "compatibility length ${#compat}"
for key in description compatibility; do
  value=$(field "$key")
  case $value in
    \'*|\"*) pass "$key is quoted" ;;
    *': '*|*' #'*) fail "$key contains ': ' or ' #' and must be quoted for YAML" ;;
    *) pass "$key is a safe plain YAML scalar" ;;
  esac
done
version=$(printf '%s\n' "$frontmatter" | sed -n 's/^  version: "\(.*\)"$/\1/p')
[ -n "$version" ] && pass "metadata.version is a quoted string ($version)" || fail "metadata.version missing or unquoted"
changelog_version=$(sed -n 's/^## \([0-9][0-9.]*\).*/\1/p' CHANGELOG.md | head -n 1)
[ "$version" = "$changelog_version" ] && pass "CHANGELOG top entry matches $version" || fail "CHANGELOG top is '$changelog_version'"

echo "size and progressive disclosure"
lines=$(awk 'END { print NR }' SKILL.md)
[ "$lines" -lt 500 ] && pass "SKILL.md has $lines lines (< 500)" || fail "SKILL.md has $lines lines"
words=$(sed '1,/^---$/d' SKILL.md | wc -w | tr -d ' ')
[ "$words" -lt 3500 ] && pass "SKILL.md body has $words words" || fail "SKILL.md body has $words words"
for ref in references/*.md; do
  grep -q "($ref)" SKILL.md && pass "SKILL.md links $ref" || fail "SKILL.md does not link $ref"
done

echo "relative links"
for md in *.md references/*.md; do
  dir=$(dirname "$md")
  grep -o '\]([^)]*)' "$md" | sed 's/^](//; s/)$//' | while IFS= read -r target; do
    case $target in http*|mailto:*|\#*) continue ;; esac
    path=${target%%#*}
    [ -e "$dir/$path" ] || echo "$md -> $target"
  done
done >"${TMPDIR:-/tmp}/repo-cleanup-links.$$"
broken=$(cat "${TMPDIR:-/tmp}/repo-cleanup-links.$$"); rm -f "${TMPDIR:-/tmp}/repo-cleanup-links.$$"
[ -z "$broken" ] && pass "all relative links resolve" || fail "broken links: $broken"

echo "README translations"
for readme in README.md README.zh-TW.md README.en.md README.ja.md; do
  grep -q '(README.md) · \[繁體中文\](README.zh-TW.md) · \[English\](README.en.md) · \[日本語\](README.ja.md)' "$readme" \
    && pass "$readme has the language switcher" || fail "$readme language switcher"
  grep -q -- '--agent claude-code' "$readme" && pass "$readme documents Claude Code install" || fail "$readme lacks Claude Code install"
done

echo "evals"
for json in evals/evals.json evals/trigger-evals.json; do
  if command -v python3 >/dev/null; then
    python3 -m json.tool "$json" >/dev/null 2>&1 && pass "$json parses" || fail "$json does not parse"
  elif command -v node >/dev/null; then
    node -e "JSON.parse(require('fs').readFileSync('$json','utf8'))" && pass "$json parses" || fail "$json does not parse"
  else
    echo "  [SKIP] no python3 or node to parse $json"
  fi
done
grep -q "\"skill_name\": \"$name\"" evals/evals.json && pass "evals skill_name matches" || fail "evals skill_name"

echo "scripts"
for sh in scripts/*.sh tests/*.sh; do
  bash -n "$sh" && pass "$sh syntax" || fail "$sh syntax"
done
if command -v shellcheck >/dev/null; then
  shellcheck -S warning scripts/*.sh tests/*.sh && pass "shellcheck" || fail "shellcheck"
else
  echo "  [SKIP] shellcheck not installed"
fi

echo "key safety rules (regression guards)"
assert_in() { grep -Fq -- "$2" "$1" && pass "$3" || fail "$3 (missing in $1: $2)"; }
assert_in SKILL.md "Common Misjudgments" "SKILL.md keeps the misjudgment table"
assert_in SKILL.md 'never run `git clean -fdX`' "SKILL.md warns against git clean -fdX"
assert_in SKILL.md "deletes ignored files such as \`.env\` without \`--force\`" "SKILL.md states worktree remove deletes ignored files"
assert_in SKILL.md "does not guess the target" "SKILL.md: survey does not guess the target"
assert_in references/worktrees.md "--exclude-standard --directory" "worktrees.md collapses ignored listings"
assert_in references/worktrees.md "headRefOid" "worktrees.md compares the PR head"
assert_in references/worktrees.md "--base" "worktrees.md scopes PR lookup to the target base"
assert_in references/worktrees.md "do not assume \`main\` or \`origin\`" "worktrees.md does not assume main/origin"
assert_in references/worktrees.md "Never force-delete a branch whose tip differs" "worktrees.md guards -D"
assert_in references/windows.md "--exclude-standard --directory" "windows.md collapses ignored listings"
assert_in references/space.md "Never run \`git clean -fdX\`" "space.md warns against git clean -fdX"
assert_in references/hosts.md "archive_worktree" "hosts.md keeps the Codex archive workflow"
assert_in scripts/survey.sh "GIT_OPTIONAL_LOCKS=0" "survey.sh avoids index writes"
if grep -Eq 'git (fetch|prune|worktree (remove|prune|add|lock|unlock)|branch -[dD]|push|clean -f)' scripts/survey.sh; then
  fail "survey.sh contains a mutating Git command"
else
  pass "survey.sh contains no mutating Git command"
fi

echo
if [ "$failures" -eq 0 ]; then echo "check-skill: all checks passed"; else echo "check-skill: $failures check(s) failed"; exit 1; fi
