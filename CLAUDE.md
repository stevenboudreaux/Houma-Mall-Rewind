# Houma Mall Rewind — Claude Code Game Studios setup

Working title **Houma Mall Rewind** (repo `stevenboudreaux/Houma-Mall-Rewind`; the game's
name avoids "Southland" because the real mall is still open). A walkable
recreation of Southland Mall in Houma, Louisiana, across the years people remember
(from its 1969 opening to roughly 2018, never stated as a hard range), with
moderated community photo boards for every store. The design record is
`design/game-brief.md`; the photo system is `design/photo-pipeline-brief.md`. The studio workflow comes from Claude Code Game
Studios (CCGS, MIT, see `.claude/CCGS-LICENSE`): coordinated subagents, skills,
hooks and rules, run at `modes.rigor: minimal`.

## Technology Stack

- **Engine**: none. Hand-built browser game: vanilla JavaScript, canvas raycaster
  with 3D, side and overhead views. No build step, no framework, no npm.
- **Hosting**: GitHub Pages, deployed by the Actions workflow `.github/workflows/pages.yml`
  (live: https://stevenboudreaux.github.io/Houma-Mall-Rewind/). It serves `main` plus the Godot
  mall build from the single-commit `godot-build` branch (`design/godot-build-hosting.md`).
  Anything pushed to `main` is live.
- **Backend**: Google Apps Script (`apps-script/Code.gs`), deployed by hand from
  Steven's Google account. Editing the file here does not redeploy it.
- **Version Control**: Git, trunk-based on `main`.
- **The old repo is gone.** Until Nov 3, 2026 the project lived at `stevenboudreaux/Southland-Mall-95`
  (site `stevenboudreaux.github.io/Southland-Mall-95/`). Every branch except the stale
  `claude/funny-feynman-x6im9s` was copied here with the same commit IDs, and Steven deletes the old
  repo himself. Session handoffs under `production/` still name the old repo and folder: they are the
  record, so leave them. Read their paths and URLs as this repo.
- **Targets**: phone (iPhone first) and desktop browsers. Touch and keyboard/gamepad.

## Where things are (as of Oct 4, 2026)

| Path | What it is |
|---|---|
| `index.html` | The whole game, ~2.7 MB in one file: `mall-engine` script (~1.2 MB, ~860 functions), character creator (`lk-engine` + `lk-weights`), `mall-data` JSON (~495 KB), inline images, CSS |
| `photos.json` | Published photo list, keyed by store-name slug |
| `photos/<store>/<id>.jpg` | Published photos |
| `pending.json`, `pending/` | Visitor submissions awaiting review (public but unlinked) |
| `review.html` | Moderation page (passphrase = `ADMIN_KEY` in the Apps Script) |
| `apps-script/Code.gs` | Receives visitor POSTs, writes pending files, emails Steven, approves/denies |

`index.html` is too large to read in one pass. Find code by function name with
Grep and read only the region you need. Key names: `render3`, `stepPlayer`,
`lookCand`/`lookUpdate`/`lookAway`/`lookOpen`, `lookTagEl`/`lookTagSync`,
`ORB_SVG`/`orbHTML`/`orbSet`/`badgeSync`/`BADGE_AT`, `hallPoster`, `posterNote`.

## Things that must not break

- **Publish** (owner, editor-unlocked browser) re-reads the live `photos.json`
  before writing, so approvals made in `review.html` are never overwritten. Keep it.
- **The editor's Publish rebuilds `index.html` from a template** (`buildDocument`):
  it keeps only the `RESET` string, `<style id="mall-css">`, the `lk-*` blocks, the
  data blocks and `<script id="mall-engine">`. Anything placed elsewhere in the file
  is silently dropped by the next editor Publish. All CSS goes in `mall-css`; all
  game code goes in `mall-engine`. (On Oct 4 this dropped every photo-board style.)
- **Publish refuses to run from an out-of-date tab**: it compares this page's
  `mall-engine`, `mall-css` and `lk-engine` with the live file first. Keep it, or an
  old open tab can roll back newer code.
- **Photos are keyed by store-name slug** and appear in every year map. Renaming a
  store changes its slug and orphans its photos.
- **Visitor flow**: POST → Apps Script → `pending/` + `pending.json` → email → `review.html` → Approve
  moves to `photos/` + `photos.json`; Deny deletes.
- **Reduced motion** turns off all marker and orb animation.
- **Secrets never go in the repo**: the GitHub token lives only in the owner's
  browser; `ADMIN_KEY` lives only in the deployed script.
- **The Godot mall ships in two wings** (`design/godot-wings.md`). Each wing shows the other across
  the seam as captured pictures. After any change to a wing, rebake it and run
  `tools/capture_standin.sh <wing>` before publishing. `tools/publish_build.sh` refuses a stale
  stand-in; never bypass it.
- **Visual changes are verified by looking**: open the game, check every affected
  view (3D, side, overhead; board open/closed; phone width), keep a screenshot.

## Period authenticity

Year maps exist today for 1993, 1995 and 1996; more years are added as photos
arrive (anywhere from 1969 to roughly 2018). Store names, signs, logos, products,
prices and decor must fit the year map they appear in. When unsure, ask the
`mall-historian`; for anything visual, the `period-art-director` reviews it.
Never invent a store that was not there; mark unknowns as unknown.

## Project Structure

@.claude/docs/directory-structure.md

There is no engine code root yet. Until the planned module split, all game code
is in `index.html`. Design docs go in `design/`, production notes in `production/`.

## Technical Preferences

`project.yaml` at the repo root is the primary config store (rigor, automation,
and later per-system overrides). Skills resolve it via `resolve_config`
(see `.claude/docs/config-resolution.md`).

## Coordination Rules

@.claude/docs/coordination-rules.md

## Collaboration Protocol

**User-driven collaboration, not autonomous execution.**
Every task follows: **Question -> Options -> Decision -> Draft -> Approval**

- Agents MUST ask "May I write this to [filepath]?" before using Write/Edit tools
- Agents MUST show drafts or summaries before requesting approval
- Multi-file changes require explicit approval for the full changeset
- No commits without user instruction (pushing to `main` publishes the site)

See `docs/COLLABORATIVE-DESIGN-PRINCIPLE.md` for full protocol and examples.

## Coding Standards

@.claude/docs/coding-standards.md

## Context Management

Read `.claude/docs/context-management.md` on demand. Two conventions matter:

- **`production/session-state/active.md` is the session checkpoint.** The file is
  the memory, not the conversation. Read it first after any compaction, crash, or `/clear`.
- **Helpers in `.claude/scripts/` emit observations, never verdicts.**

## Next steps for this setup

1. Done Oct 4: `/adopt` (minimal tier: only the game brief was missing; now written).
2. `/reverse-document`, one subsystem at a time. Done: photo boards and pipeline.
   Next: rendering, look/tags/orbs, editor and Publish, character creator, year maps.
3. Add `workflow_overrides.system_overrides` in `project.yaml` for the photo
   pipeline and renderer once those systems have names.
4. Baseline screenshots of every view before any refactor.
