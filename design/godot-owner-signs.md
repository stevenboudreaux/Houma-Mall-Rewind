# Owner-editable signs (Godot mall)

**Asked for (Steven, Oct 6, 2026):** in owner mode, change the names written on the arcade cabinets in Pocket Change, and the words on Kay-Bee Toys' hanging department boards.

## What it does
- **Signs covered:**
  - the title of every upright video cabinet in Pocket Change (69 since Demo 9, ids `pc.video.01` to `pc.video.69`, numbered in build order), of the four basketball games (`pc.hoops.1`–`4`) and of the three claw machines (`pc.crane.1`–`3`);
  - on a video cabinet, renaming it changes every place its title is printed, together: the marquee, the lower-front panel under the coin door, the control panel's front lip (between the two INSERT TOKEN labels) and the small line on the bezel above the screen (Steven, Oct 6: "change the bottom text to match the top sign"). Tapping any of those faces in Edit signs picks the cabinet;
  - the eight Kay-Bee department boards (`kb.dept.1` to `kb.dept.8`; both faces of a board change together).
- **Who is the owner:** any browser where the mall editor has been unlocked (localStorage `southland-editor` = `1`, set by the main game's secret code), or any visit with `?owner=1` added to the play URL. Being the owner only shows the buttons; publishing still needs a GitHub token with write access.
- **Editing:**
  - The owner sees **Edit signs** and **Publish signs** in the menu's **OWNER** tab, TOOLS (since Nov 4,
    design/godot-owner-mode.md; they were at the top left). Turning Edit signs on closes the menu.
  - With Edit signs on, tap or click a sign within about 16 m. A text box opens: type the new words, or leave it empty to restore the original.
  - The change shows at once. It is kept in this browser (localStorage `southland-signs-draft`) until it is published.
- **Publishing:**
  - **Publish signs** merges the drafts into `prototypes/godot-mall/play/signs.json` on `main`, using the GitHub contents API.
  - It uses the token the main game's editor Publish keeps in this browser (`southland-gh`). If no token is saved, it asks for one and does not keep it.
  - Everyone sees the change about a minute later, once GitHub Pages updates. No rebuild, export or rebake is needed.

## How it is built
- **Build time:**
  - `tools/build_mall.gd` `sign_add()` records each sign's faces in world space in `gen/signs.json`.
  - The callers are `pocket_change/video.gd` `_sign()`, `pocket_change/hoops.gd`, `pocket_change/crane.gd` and `kay_bee/store.gd` `dept()`.
  - A video cabinet's sign is registered at the end of `video.gd` `build()`, with four faces: the marquee first (from `_marquee` or `_housing`; `signs.gd` treats `faces[0]` as the marquee), then the lower front, the panel lip (from `_panel`) and the bezel strip above the picture (from `_bezel`).
  - A face may carry overrides (a 4th element in `sign_add`'s face list, copied into the face record): `tex` (its own word-free art), `band` (where the painted title sits, as fractions of the face from its top edge), `span` (the width the new words may use), `look` (font, fill, outline, `osz` outline size) and `lit`.
- **Run time:**
  - `scripts/signs.gd` (node `Signs` in `main.tscn`) loads the list and the published `play/signs.json`, plus the owner's draft.
  - For each changed sign it lays a word-free copy of the art just in front of the painted sign: `tex/pc/video_marquees_blank.png` (from `paint_video.py` `paint_marquees_blank()`) or `tex/kb/dept_blank.png` (from `paint_store.py` `dept_blank()`). It then draws the words with a Label3D in that marquee's title colours.
  - A video cabinet's other three faces use `tex/pc/video_fronts_blank.png`, `video_panels_blank.png` and `video_bezels_blank.png`, from `paint_video.py` `paint_titles_blank()`. Each is the original atlas with only the title's box repainted, so nothing else changes. The same function writes `tools/stores/pocket_change/video_titles.json` (each style's title band, span and look per face), which `video.gd` reads at build time. On those faces the new words sit in the old title's band, capitals as tall as the painted ones, in the painted title's colours.
  - Those three faces are painted rather than backlit, so their copies are shaded (`lit`) and take their light from the lightmap's probes. The painted face beside them has baked light. A renamed lower front can therefore look a little brighter or flatter than before, most where the bake is darkest (seen on THUNDER DOJO's flames in the night lighting).
  - Signs that are not changed show the original painted art, untouched.
- **Publish code:** `window.mallSigns` in `web/shell.html`.
- **Test:** `tools/qa/signstest.py` (it loads as the owner with a draft, then runs the tap-and-type flow).
- **Evidence (Oct 6):** `production/qa/evidence/2026-10-06-titles-*.jpg` (renamed cabinets of styles 0, 1, 3, 6 and 7, unrenamed ones, close-ups of before and after, and a tap on a lower front opening the editor).

## Not covered yet
- The other machines' names: skee-ball, racers, pinball, the ride and air hockey.
