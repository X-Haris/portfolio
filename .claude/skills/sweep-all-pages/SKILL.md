---
name: sweep-all-pages
description: Apply one described change to all nine portfolio HTML pages at once and report per-file what happened. For site-wide edits like a nav item, a design token, an analytics snippet, or a theme default.
disable-model-invocation: true
---

# Sweep a change across every page

This site duplicates its design system, nav, theme script and analytics snippet in
**every** HTML file. There is no shared stylesheet and no include. A "global" change
is therefore N separate edits, and the failure mode is silent: one page gets missed
and looks subtly wrong for months.

Roughly a quarter of this repo's history is exactly this job — commits `05c1165`
(GoatCounter to every page), `90d5e43` (light theme default) and `d5c55eb` (dark mode)
each touched 7 files with the same edit.

**This skill only runs when the user types `/sweep-all-pages`.** An 8-file rewrite
should never start because it was inferred.

## The pages

```bash
Portfolio.html        # homepage
Projects.html         # "all projects" index — unfinished, but keep it in sync
Project - Drone Dash.html
Project - Empire State Mechanical.html
Project - Fintrack.html
Project - PocketCloud.html
Project - Reps RPG.html
Project - Salah Companion.html
Project - Velvet Noise.html
```

`index.html` is a **redirect stub** — deliberately no analytics, no theme, no nav.
Exclude it from sweeps unless the change is specifically about the redirect.

## Steps

1. **Restate the change** in one sentence and confirm which pages it applies to.
   Some changes are genuinely homepage-only (the hero portrait easter egg) or
   project-page-only. Don't assume all nine.

2. **Check the current state per page first.** Never assume the pages start identical
   — they drift, which is the whole reason this skill exists:

   ```bash
   for f in Portfolio.html Projects.html "Project - "*.html; do
     printf "%-42s %s\n" "$f" "$(grep -c '<PATTERN>' "$f")"
   done
   ```

   Pages already carrying the change need skipping, not double-applying.

3. **Apply it.** For a mechanical substitution `sed -i` over the list is fine. For
   anything structural, edit each file individually — a regex that half-matches on one
   page is worse than nine careful edits.

   Mind the quoting: the filenames contain spaces, and the folder is
   `porfolio webpage` — spelled `porfolio`, not `portfolio`. Quote paths accordingly.

4. **Report a per-file table.** This is the point of the skill — the user must be able
   to see at a glance that nothing was skipped:

   ```
   Portfolio.html                          changed
   Projects.html                           changed
   Project - Drone Dash.html               changed
   ...
   Project - Velvet Noise.html             already had it, skipped
   ```

5. **Verify.** Re-run the step-2 check and confirm every page now agrees. Then run the
   consistency check against a page you touched:

   ```bash
   echo '{"tool_input":{"file_path":"'"$PWD"'/Portfolio.html"}}' \
     | bash .claude/check-page.sh; echo "exit=$?"
   ```

   The `PostToolUse` hook also runs this after each individual edit, so a drift
   warning during the sweep means that page ended up out of step — fix before moving on.

6. **Do not commit or push** unless asked. Pushing to `main` deploys the site.

## If the change touches a protected file

`CNAME`, `.nojekyll` and `robots.txt` are blocked by a `PreToolUse` hook — they keep
the domain working, the space-containing filenames served, and the portraits out of
image search. If a sweep genuinely needs one of them changed, say so and let the user
edit it by hand rather than working around the guard.
