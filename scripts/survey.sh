#!/usr/bin/env bash
# Read-only inventory of worktrees and local branches for the repo-cleanup skill.
# It never fetches, prunes, locks, or writes: GIT_OPTIONAL_LOCKS=0 keeps `git status` from refreshing the index.
# Usage: survey.sh [--repo <path>] [--base <target-ref>] [--sizes]
#   --base   target to compare against (ancestry and commits ahead); never guessed
#   --sizes  add `du -sk` sizes for collapsed ignored entries (slower on large trees)
set -u
export GIT_OPTIONAL_LOCKS=0 LC_ALL=C

repo=. base= sizes=0
while [ $# -gt 0 ]; do
  case $1 in
    --repo) repo=${2:?--repo needs a path}; shift 2 ;;
    --base) base=${2:?--base needs a ref}; shift 2 ;;
    --sizes) sizes=1; shift ;;
    -h|--help) sed -n '2,6p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "survey.sh: unknown argument: $1" >&2; exit 2 ;;
  esac
done

top=$(git -C "$repo" rev-parse --show-toplevel 2>/dev/null) || { echo "survey.sh: not inside a Git work tree: $repo" >&2; exit 2; }
base_sha=
if [ -n "$base" ]; then
  base_sha=$(git -C "$top" rev-parse --verify --quiet "$base^{commit}") || { echo "survey.sh: cannot resolve --base $base" >&2; exit 2; }
fi

# Print non-ASCII paths verbatim instead of octal-escaped, so `du` and readers see real names.
git() { command git -c core.quotePath=false "$@"; }
count() { awk 'END { print NR }'; }

# Prints "<commits ahead of base>\t<yes|no|err>" for a commit, or "-\t-" without --base.
compare() {
  [ -n "$base_sha" ] || { printf -- '-\t-'; return; }
  local ahead rc
  ahead=$(git -C "$top" rev-list --count "$base_sha..$1" 2>/dev/null) || ahead=err
  git -C "$top" merge-base --is-ancestor "$1" "$base_sha" 2>/dev/null; rc=$?
  case $rc in 0) printf '%s\tyes' "$ahead" ;; 1) printf '%s\tno' "$ahead" ;; *) printf '%s\terr' "$ahead" ;; esac
}

echo "# repo-cleanup survey (read-only, no fetch; remote-tracking refs may be stale)"
printf 'root\t%s\n' "$top"
if [ -n "$base" ]; then
  printf 'base\t%s\t%s\n' "$base" "$base_sha"
else
  hints=$(git -C "$top" for-each-ref --format='%(refname:short)->%(symref:short)' 'refs/remotes/*/HEAD' | tr '\n' ' ')
  printf 'base\t(not set; pass --base <target>. remote HEADs: %s)\n' "${hints:-none}"
fi

# Fields are separated by \037 (unit separator): unlike tab, read does not merge empty fields.
US=$'\037'

# Worktree records from porcelain output: path, head, ref, flags
records=$(git -C "$top" worktree list --porcelain | awk -v us="$US" '
  function flush() { if (path != "") print path us head us ref us flags; path = head = ref = flags = "" }
  /^worktree / { flush(); path = substr($0, 10); next }
  /^HEAD /     { head = substr($0, 6); next }
  /^branch /   { ref = substr($0, 8); sub(/^refs\/heads\//, "", ref); next }
  /^detached/  { ref = "(detached)"; next }
  /^bare/      { ref = "(bare)"; flags = flags "bare,"; next }
  /^locked/    { r = substr($0, 8); flags = flags "locked" (r != "" ? "(" r ")" : "") ","; next }
  /^prunable/  { flags = flags "prunable,"; next }
  END { flush() }')

echo
echo "## worktrees"
printf 'path\tref\thead\tflags\ttracked_changes\tuntracked\tignored_entries\tahead\tin_base\tlast_commit\n'
first=1
details=
while IFS=$US read -r path head ref flags; do
  [ -n "$path" ] || continue
  [ $first -eq 1 ] && flags="main,$flags" && first=0
  [ "$path" = "$top" ] && flags="current,$flags"
  tracked=- untracked=- ignored=- last=-
  if [ ! -d "$path" ]; then
    flags="${flags}missing,"
  elif [ "$ref" != "(bare)" ]; then
    if status=$(git -C "$path" status --porcelain=v1 --untracked-files=all 2>/dev/null); then
      tracked=$(printf '%s\n' "$status" | grep -v '^??' | grep -c . || true)
      untracked=$(printf '%s\n' "$status" | grep -c '^??' || true)
      [ "$tracked$untracked" = 00 ] || details="$details$path"$'\n'
    else
      tracked=err untracked=err
    fi
    ignored=$(git -C "$path" ls-files --others --ignored --exclude-standard --directory 2>/dev/null | count) || ignored=err
    last=$(git -C "$path" log -1 --format=%cr 2>/dev/null) || last=err
  fi
  [ -n "$head" ] && cmp=$(compare "$head") || cmp=$(printf -- '-\t-')
  flags=${flags%,}
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$path" "$ref" "${head:0:12}" "${flags:--}" "$tracked" "$untracked" "$ignored" "$cmp" "$last"
done <<EOF
$records
EOF

echo
echo "## ignored entries (collapsed; ignored does not mean disposable)"
while IFS=$US read -r path _ ref _; do
  [ -d "$path" ] && [ "$ref" != "(bare)" ] || continue
  entries=$(git -C "$path" ls-files --others --ignored --exclude-standard --directory 2>/dev/null) || continue
  [ -n "$entries" ] || continue
  printf '%s\n' "$entries" | head -n 50 | while IFS= read -r entry; do
    if [ $sizes -eq 1 ]; then
      kb=$(du -sk -- "$path/$entry" 2>/dev/null | awk '{ print $1 }')
      printf '%s\t%s\t%sK\n' "$path" "$entry" "${kb:-?}"
    else
      printf '%s\t%s\n' "$path" "$entry"
    fi
  done
  n=$(printf '%s\n' "$entries" | count)
  [ "$n" -gt 50 ] && printf '%s\t... %s more\n' "$path" "$((n - 50))"
done <<EOF
$records
EOF

echo
echo "## uncommitted and untracked files (first 30 per worktree)"
printf '%s' "$details" | while IFS= read -r path; do
  [ -n "$path" ] || continue
  git -C "$path" status --porcelain=v1 --untracked-files=all 2>/dev/null | head -n 30 | P=$path awk '{ print ENVIRON["P"] "\t" $0 }'
done

echo
echo "## local branches"
printf 'branch\ttip\tupstream\ttrack\tworktree\tahead\tin_base\n'
git -C "$top" for-each-ref --format='%(refname:short)%1f%(objectname)%1f%(upstream:short)%1f%(upstream:track)%1f%(worktreepath)' refs/heads |
while IFS=$US read -r name sha upstream track wtpath; do
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$name" "${sha:0:12}" "${upstream:--}" "${track:-}" "${wtpath:--}" "$(compare "$sha")"
done
