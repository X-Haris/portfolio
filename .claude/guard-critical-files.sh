#!/usr/bin/env bash
# Guard the files that keep the site online (Claude Code PreToolUse hook).
#
#   CNAME      -> without it, abduloski.dev stops pointing at the site
#   .nojekyll  -> without it, GitHub Pages runs Jekyll and every page whose
#                 filename contains a space starts 404ing
#   robots.txt -> without it, the portrait photos become eligible for image search
#
# CLAUDE.md says not to touch these. This makes that mechanical rather than a note
# someone has to remember. Haris can still edit them by hand; this only stops Claude.
#
# Only fires for files inside THIS repo -- a robots.txt in some other project is
# none of our business.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOTW="$(cd "$ROOT" && pwd -W 2>/dev/null || printf '%s' "$ROOT")"

payload="$(cat)"

raw="$(printf '%s' "$payload" \
  | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' \
  | head -1 \
  | sed 's/.*"file_path"[[:space:]]*:[[:space:]]*"//; s/"$//')"

[ -n "$raw" ] || exit 0

norm() { printf '%s' "$1" | tr 'A-Z' 'a-z' | tr '\\' '/' | sed 's://*:/:g'; }

n_raw="$(norm "$raw")"

# Must live inside this repository, in either path style Windows/Git Bash may hand us.
inside=0
case "$n_raw" in
  "$(norm "$ROOTW")"/*) inside=1 ;;
  "$(norm "$ROOT")"/*)  inside=1 ;;
esac
[ "$inside" = "1" ] || exit 0

base="${raw##*/}"      # strip any forward-slash directories
base="${base##*\\}"   # strip any backslash directories (Windows)

case "$base" in
  CNAME|.nojekyll|robots.txt)
    reason="$base keeps the site online (custom domain, space-containing filenames, and portraits out of image search). CLAUDE.md says do not change it. Edit it by hand if this is deliberate."
    printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$reason"
    exit 0
    ;;
esac

exit 0
