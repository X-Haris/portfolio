# `.claude/` — automated checks for this site

`settings.json` wires two hooks. They are **tracked in the repo**, so they fire for
anyone who clones it and runs Claude Code here. This file explains what they do, since
`CLAUDE.md` is excluded from git (`.git/info/exclude`) and isn't distributed.

## Why these exist

The site is nine hand-authored HTML pages with **no shared stylesheet and no include**.
The design tokens, nav, theme script and analytics snippet are duplicated in every
file. A site-wide change is N separate edits, and when one page gets missed nothing
errors — it just quietly looks wrong in production.

That already happened once: `Portfolio.html` asked for JetBrains Mono in its
matrix-rain easter egg while never loading the font, because the token and the Google
Fonts URL had drifted from the project pages. These checks exist to catch that class
of problem at edit time.

## The hooks

### `check-page.sh` — `PostToolUse` on `Edit|Write`

After any page is edited, re-checks **that page**:

1. the GoatCounter snippet is present (every live page must report analytics)
2. the theme toggle and `localStorage` theme script are present
3. every `href="*.html"` points at a file that exists — the filenames contain spaces,
   so typos are easy and silent
4. the `:root` design-token names match the other pages (majority wins)

Exits `2` on a problem, which surfaces the reason to Claude so it can fix it in the
same turn. It does **not** block the edit — `PostToolUse` runs after the write.
Skips `index.html` (a redirect stub with deliberately no analytics/theme/nav) and
anything that isn't a page in this repo.

### `guard-critical-files.sh` — `PreToolUse` on `Edit|Write`

Refuses Claude-side writes to three files, **only when they're inside this repo**:

| File | What breaks without it |
|---|---|
| `CNAME` | `abduloski.dev` stops resolving to the site |
| `.nojekyll` | Pages runs Jekyll, stops serving space-containing filenames — every project page 404s |
| `robots.txt` | the real portrait photos become eligible for image search |

You can still edit them by hand in an editor. This only stops Claude touching them by
accident. A `robots.txt` in some other project is unaffected.

## Testing them

Both are plain bash with **no `jq` dependency** (`jq` isn't installed on this machine).
Pipe either one a payload on stdin:

```bash
# should be silent, exit 0
echo '{"tool_input":{"file_path":"'"$PWD"'/Portfolio.html"}}' | bash .claude/check-page.sh

# should print a deny decision
echo '{"tool_input":{"file_path":"'"$PWD"'/CNAME"}}' | bash .claude/guard-critical-files.sh

# check every page at once
for f in Portfolio.html Projects.html "Project - "*.html; do
  echo '{"tool_input":{"file_path":"'"$PWD/$f"'"}}' | bash .claude/check-page.sh \
    && echo "ok   $f" || echo "FAIL $f"
done
```

## Turning them off

Review or disable them from the `/hooks` menu in Claude Code, or delete the relevant
block from `settings.json`. Note that `settings.local.json` is git-ignored globally
and is the right place for personal overrides.

## Skills

`skills/new-project-page` and `skills/sweep-all-pages` cover the two recurring jobs on
this site — adding a case study (one new file plus a link on every other project page)
and applying one change across all nine pages. `sweep-all-pages` is user-invocable only
(`/sweep-all-pages`); a nine-file rewrite shouldn't start on inference.
