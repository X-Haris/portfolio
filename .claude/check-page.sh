#!/usr/bin/env bash
# Portfolio page consistency check (Claude Code PostToolUse hook).
#
# The site is 9 hand-authored HTML pages that each carry their own copy of the
# design tokens, nav, theme script and analytics snippet. Nothing else checks that
# those copies still agree. This does, on every edit.
#
# Exit 2 makes Claude Code show stderr to the model, which can then fix it in the
# same turn. It does NOT block the edit (PostToolUse runs after the write).

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

payload="$(cat)"

# First "file_path" in the payload is the edited file.
raw="$(printf '%s' "$payload" \
  | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' \
  | head -1 \
  | sed 's/.*"file_path"[[:space:]]*:[[:space:]]*"//; s/"$//')"

[ -n "$raw" ] || exit 0

# Take the filename off the end. Handles both "\\" and "/" separators, and both
# single and JSON-escaped double backslashes, without touching the rest.
base="${raw##*/}"      # strip any forward-slash directories
base="${base##*\\}"   # strip any backslash directories (Windows)

# Only care about this repo's live pages.
case "$base" in
  *.html) ;;
  *) exit 0 ;;
esac
[ -f "$ROOT/$base" ] || exit 0
# index.html is a redirect stub: deliberately no analytics, no theme, no nav.
[ "$base" = "index.html" ] && exit 0

cd "$ROOT" || exit 0

tokens_of() {
  awk '/:root \{/{f=1} f{print} f&&/^  \}/{exit}' "$1" \
    | grep -o '^[[:space:]]*--[a-z0-9-]*' | tr -d ' '
}

problems=()

# 1. Analytics — CLAUDE.md: every live page must report to GoatCounter.
if ! grep -q 'gc.zgo.at' "$base"; then
  problems+=("missing the GoatCounter snippet (every live page needs it, before </body>)")
fi

# 2. Theme toggle + persistence.
if ! grep -q 'themeToggle' "$base" || ! grep -q "localStorage.getItem('theme')" "$base"; then
  problems+=("missing the theme toggle / localStorage theme script")
fi

# 3. Internal links resolve. Filenames contain spaces, so typos are easy and silent.
while IFS= read -r target; do
  [ -z "$target" ] && continue
  [ -f "$target" ] || problems+=("links to \"$target\" which does not exist")
done < <(grep -o 'href="[^"]*\.html"' "$base" | sed 's/href="//; s/"$//' | sort -u)

# 4. Design tokens agree with the rest of the site (majority wins).
mine="$(tokens_of "$base" | md5sum | cut -d' ' -f1)"
ref="$(for f in Portfolio.html Projects.html Project\ -\ *.html; do
         [ "$f" = "$base" ] && continue
         [ -f "$f" ] && tokens_of "$f" | md5sum | cut -d' ' -f1
       done | sort | uniq -c | sort -rn | head -1 | awk '{print $2}')"

if [ -n "$ref" ] && [ "$mine" != "$ref" ]; then
  diffs="$(diff <(tokens_of "$base") \
                <(for f in Portfolio.html Projects.html Project\ -\ *.html; do
                    [ "$f" = "$base" ] && continue
                    if [ -f "$f" ] && [ "$(tokens_of "$f" | md5sum | cut -d' ' -f1)" = "$ref" ]; then
                      tokens_of "$f"; break
                    fi
                  done) | grep '^[<>]' | tr '\n' ' ')"
  problems+=(":root design tokens differ from the other pages -> $diffs")
fi

if [ ${#problems[@]} -gt 0 ]; then
  {
    echo "Page consistency check failed for \"$base\":"
    for p in "${problems[@]}"; do echo "  - $p"; done
    echo "This site duplicates its design system across every page, so fix it here"
    echo "and check whether the other pages need the same change."
  } >&2
  exit 2
fi

exit 0
