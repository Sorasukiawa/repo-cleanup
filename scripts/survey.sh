#!/usr/bin/env bash
# Read-only inventory for the repo-cleanup skill: worktrees, local branches, ignored entries, and
# project-owned outputs outside the repository.
# It never fetches, prunes, locks, or writes: GIT_OPTIONAL_LOCKS=0 keeps `git status` from refreshing the index.
# Usage: survey.sh [--repo <path>] [--base <target-ref>] [--sizes]
#   --base   target to compare against (ancestry and commits ahead); never guessed
#   --sizes  add `du -sk` sizes, largest ignored entries first (slower on large trees)
# REPO_CLEANUP_DERIVED_DATA overrides the Xcode DerivedData root (default ~/Library/Developer/Xcode/DerivedData).
set -u
export GIT_OPTIONAL_LOCKS=0 LC_ALL=C

repo=. base= sizes=0
while [ $# -gt 0 ]; do
  case $1 in
    --repo) repo=${2:?--repo needs a path}; shift 2 ;;
    --base) base=${2:?--base needs a ref}; shift 2 ;;
    --sizes) sizes=1; shift ;;
    -h|--help) sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
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
if [ $sizes -eq 1 ]; then
  echo "## ignored entries (collapsed, largest first; ignored does not mean disposable)"
else
  echo "## ignored entries (collapsed; ignored does not mean disposable)"
fi
while IFS=$US read -r path _ ref _; do
  [ -d "$path" ] && [ "$ref" != "(bare)" ] || continue
  entries=$(git -C "$path" ls-files --others --ignored --exclude-standard --directory 2>/dev/null) || continue
  [ -n "$entries" ] || continue
  if [ $sizes -eq 1 ]; then
    printf '%s\n' "$entries" | head -n 200 | while IFS= read -r entry; do
      kb=$(du -sk -- "$path/$entry" 2>/dev/null | awk '{ print $1 }')
      printf '%s\t%s\t%sK\n' "$path" "$entry" "${kb:-0}"
    done | sort -t "$(printf '\t')" -k3,3nr | head -n 50
  else
    printf '%s\n' "$entries" | head -n 50 | P=$path awk '{ print ENVIRON["P"] "\t" $0 }'
  fi
  n=$(printf '%s\n' "$entries" | count)
  [ "$n" -gt 50 ] && printf '%s\t... %s more\n' "$path" "$((n - 50))"
done <<EOF
$records
EOF

# Project-owned outputs outside the repository: Cargo target dirs, Xcode DerivedData for this
# project's workspaces, and output paths named in tracked docs or scripts.
inside_repo() {
  local wt
  while IFS=$US read -r wt _; do
    [ -n "$wt" ] || continue
    case $1 in "$wt"|"$wt"/*) return 0 ;; esac
  done <<EOF
$records
EOF
  return 1
}
expand_path() { # $1 raw token, $2 base dir for relative paths; prints absolute paths that exist
  local raw=$1 prefix
  raw=${raw#\"}; raw=${raw%\"}; raw=${raw#\'}; raw=${raw%\'}
  case $raw in "~/"*) raw=$HOME/${raw#\~/} ;; esac
  raw=${raw//\$\{HOME\}/$HOME}; raw=${raw//\$HOME/$HOME}
  raw=${raw//\$\{TMPDIR\}/${TMPDIR:-/tmp}}; raw=${raw//\$TMPDIR/${TMPDIR:-/tmp}}
  case $raw in /*) ;; *) raw=$2/$raw ;; esac
  case $raw in
    *'$'*|*'<'*|*'{'*|*'*'*) # a per-task placeholder: list what exists under the fixed prefix
      prefix=${raw%%[\$<\{*]*}
      [ ${#prefix} -gt 5 ] || return 0
      for p in "$prefix"*; do [ -e "$p" ] && physical "$p"; done | head -n 300 ;;
    *) [ -e "$raw" ] && physical "$raw" ;;
  esac
}
physical() { # resolves .. and symlinked parents so inside/outside checks compare real paths
  if [ -d "$1" ]; then (cd "$1" && pwd -P); else printf '%s/%s\n' "$(cd "$(dirname "$1")" && pwd -P)" "${1##*/}"; fi
}
outputs=
add_output() { inside_repo "$1" || outputs="$outputs$1$US$2"$'\n'; }

if [ -n "${CARGO_TARGET_DIR:-}" ]; then
  found=$(expand_path "$CARGO_TARGET_DIR" "$top")
  while IFS= read -r p; do [ -n "$p" ] && add_output "$p" "env CARGO_TARGET_DIR"; done <<EOF
$found
EOF
fi
while IFS= read -r cfg; do
  [ -n "$cfg" ] || continue
  dir=$(sed -n 's/^[[:space:]]*target-dir[[:space:]]*=[[:space:]]*//p' "$cfg" | head -n 1)
  [ -n "$dir" ] || continue
  found=$(expand_path "$dir" "$(dirname "$(dirname "$cfg")")")
  while IFS= read -r p; do [ -n "$p" ] && add_output "$p" "${cfg#$top/}"; done <<EOF
$found
EOF
done <<EOF
$(find "$top" -maxdepth 4 \( -name node_modules -o -name .git -o -name target \) -prune -o -path '*/.cargo/config*' -type f -print 2>/dev/null)
EOF
mentions=$(git -C "$top" grep -nE -- '(CARGO_TARGET_DIR=|--target-dir[ =]|-derivedDataPath[ =])' 2>/dev/null | head -n 200)
while IFS= read -r line; do
  [ -n "$line" ] || continue
  where=${line%%:*}:$(printf '%s' "${line#*:}" | cut -d: -f1)
  token=$(printf '%s' "$line" | sed -nE 's/.*(CARGO_TARGET_DIR=|--target-dir[ =]|-derivedDataPath[ =])["'\'']?([^ "'\''`;)|&]+).*/\2/p')
  [ -n "$token" ] || continue
  found=$(expand_path "$token" "$top")
  while IFS= read -r p; do [ -n "$p" ] && add_output "$p" "mentioned in $where"; done <<EOF
$found
EOF
done <<EOF
$mentions
EOF
dd_root=${REPO_CLEANUP_DERIVED_DATA:-$HOME/Library/Developer/Xcode/DerivedData}
if [ -d "$dd_root" ]; then
  # DerivedData folders are named after the project, workspace, or Swift package folder.
  names=$(while IFS=$US read -r wt _; do
      [ -d "$wt" ] || continue
      find "$wt" -maxdepth 3 \( -name node_modules -o -name .git -o -name .build \) -prune -o \( -name '*.xcodeproj' -o -name '*.xcworkspace' \) -print 2>/dev/null |
        sed 's|.*/||; s|\.xcodeproj$||; s|\.xcworkspace$||'
      [ -f "$wt/Package.swift" ] && printf '%s\n' "${wt##*/}"
    done <<EOF | grep -v '^project$' | sort -u
$records
EOF
)
  for dd in "$dd_root"/*/; do
    dd=${dd%/}
    ws=
    if [ -f "$dd/info.plist" ]; then
      ws=$(plutil -extract WorkspacePath raw -o - "$dd/info.plist" 2>/dev/null) ||
        ws=$(awk '/<key>WorkspacePath<\/key>/ { getline; gsub(/.*<string>|<\/string>.*/, ""); print; exit }' "$dd/info.plist")
    fi
    if [ -n "$ws" ]; then
      case $ws in "$top"/*) ;; *) inside_repo "$ws" || continue ;; esac
      [ -e "$ws" ] && note="Xcode DerivedData for $ws" || note="Xcode DerivedData; workspace no longer exists: $ws"
      add_output "$dd" "$note"
    else
      base=${dd##*/}
      while IFS= read -r n; do
        [ -n "$n" ] && case $base in "$n"-*) add_output "$dd" "Xcode DerivedData; name match only (no info.plist)" ;; esac
      done <<EOF
$names
EOF
    fi
  done
fi

echo
echo "## project outputs outside the repository (candidates; confirm ownership and use before removing)"
printf 'path\tsource\tsize\n'
printf '%s' "$outputs" | awk -F "$US" '!seen[$1]++' | while IFS=$US read -r p src; do
  [ -n "$p" ] || continue
  if [ $sizes -eq 1 ]; then
    kb=$(du -sk -- "$p" 2>/dev/null | awk '{ print $1 }')
    printf '%s\t%s\t%sK\n' "$p" "$src" "${kb:-0}"
  else
    printf '%s\t%s\t-\n' "$p" "$src"
  fi
done

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
