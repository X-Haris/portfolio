---
name: new-project-page
description: Add a new "Project - <Name>.html" case-study page to the portfolio site, wired into the homepage slider and cross-linked from every other project page. Use when adding a project, case study, or work item to the site.
---

# Add a project case-study page

This site has **no shared template** — every page carries its own copy of the design
system, nav, theme script and analytics. Adding a project is therefore not one file:
it is one new file plus an edit to **every** other page that lists projects.

## Before starting

Ask for, or confirm, these three things:

1. **Name** — becomes `Project - <Name>.html`. Spaces are normal here; `.nojekyll`
   exists so GitHub Pages serves these filenames verbatim. Never rename to hyphens.
2. **Accent** — one of `t-cyan`, `t-blue`, `t-violet`, `t-amber`, `t-pink`, `t-aqua`,
   `t-mono`. Check which are already taken (below) and pick an unused one if possible.
3. **One-line description** and whether it is **live on Google Play** (drives the
   card copy and the CTA).

Current accents in the homepage `work-slider`, in order:

| Project | Accent |
|---|---|
| Velvet Noise | violet |
| PocketCloud | amber |
| Drone Dash | cyan |
| Reps RPG | pink |
| Salah Companion | aqua |
| Empire State Mechanical | blue |

`Project - Fintrack.html` exists but is deliberately **not** on the homepage. Don't
"fix" that unless asked.

## Steps

1. **Copy the closest existing page** as the base — pick the one whose structure
   matches best (an app case study vs. a client site read quite differently):

   ```bash
   cp "Project - Velvet Noise.html" "Project - <Name>.html"
   ```

   Copying preserves the GoatCounter snippet, the theme toggle, the `:root` tokens
   and the Google Fonts URL. Do **not** hand-write a page from scratch.

2. **Rewrite the content** — `<title>`, meta description, `project-hero`, the body
   sections, `stack-grid`, screenshots. Swap the accent class to the chosen one.

3. **Add the card to the homepage.** In `Portfolio.html`, inside `work-slider`, add a
   `<div class="lg is-interactive work-card t-<accent>">` following the shape of the
   cards already there (image/icon, `<h3>`, `<p class="desc">`, `<a class="work-cta">`).

4. **Cross-link from every other project page.** Each `Project - *.html` carries a
   `work-grid` near the bottom listing **all** the other projects. Add a card for the
   new page to every one of them — including `Project - Fintrack.html`, which links
   out even though nothing links back to it.

5. **Add it to `Projects.html`** if that page is being kept current. It is marked
   unfinished in `CLAUDE.md`, so check before assuming.

6. **Verify** before declaring done:

   ```bash
   # every internal link resolves
   grep -ho 'href="[^"]*\.html"' *.html | sed 's/href="//;s/"$//' | sort -u \
     | while read -r t; do [ -f "$t" ] || echo "BROKEN: $t"; done

   # the new page passes the consistency check
   echo '{"tool_input":{"file_path":"'"$PWD"'/Project - <Name>.html"}}' \
     | bash .claude/check-page.sh; echo "exit=$?"

   # nothing links to the new page? then step 3/4 was missed
   grep -l "Project - <Name>.html" *.html
   ```

   Exit `0` and silence from `check-page.sh` means the page is consistent with the
   rest of the site. The `PostToolUse` hook runs this automatically on every edit too.

7. **Do not commit or push** unless asked. Pushing to `main` deploys the site.
