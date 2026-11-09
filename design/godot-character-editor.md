# The character editor (Godot mall, workstreams B2 and CHAR-EDITOR, Nov 2-4 2026): SUPERSEDED

**Superseded Nov 8 2026 by CHAR-STRIP** (branch `ws/char-strip`; Steven's decisions of Nov 8). Nothing this
note used to describe is in the game any more, and none of its claims hold:

- no character editor (player or owner), no presets (`data/characters/`), no shape sliders, no colours,
  no wardrobe, no baking of dressed bodies at runtime, no owner NPC editor (K);
- no `AvatarChar` / `CharBody` / `CharPreset` / `CharPack`, no UBC or MakeHuman B1 bodies (`models/ubc/`,
  `models/characters/` deleted), no "later" character packs fetched after the mall runs;
- no `mall-avatar-preset-1` record (read once for the name, then deleted).

What replaced it: `design/godot-avatar.md` (the cast, `Cast.body(id)` as the one loader, the menu's Character
row, the save record `mall-player-2`, the counting test) and `design/godot-characters-research.md` on
`ws/char-research` (why: two systems, two save keys, four places deciding the body). The cast's people are
built by CHAR-BUILD (`tools/blender/cast/`, `cast/<id>.glb`).

The old text is in git history: `git show ae0aa05~1:design/godot-character-editor.md`.
