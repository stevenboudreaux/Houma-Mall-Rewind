# Playable arcade cabinets (Godot mall, Pocket Change)

**Asked for (Steven, Oct 6, 2026):**
- He wants Pocket Change cabinets that play ROMs: open-source games he made himself.
- "I want a sprinkling of 3 Atari, 3 NES, 3 Genesis, 3 SNES, 12 total."

> **ARCADE-NES, Nov 4 2026 (Steven; branch `ws/owner-tools`, design/godot-owner-mode.md):** all twelve
> playable cabinets are **NES** now (same cabinets, NES-red stickers). The setup page accepts only `.nes`,
> `.fds`, `.unf`, play uses the `nes` core, and writing `roms.json` drops entries for other systems (none
> existed on Nov 4). The Atari / Genesis / Super NES lists below are the Oct 6 state. Arcade mode is in
> the menu's OWNER tab.

## What it does
- **The cabinets:** twelve upright video cabinets with joysticks are playable. They are spread round the arcade, three for each system:
  - Atari 2600: `pc.video.33`, `pc.video.11`, `pc.video.22`.
  - NES: `pc.video.37`, `pc.video.46`, `pc.video.54`.
  - Genesis: `pc.video.03`, `pc.video.17`, `pc.video.29`.
  - Super NES: `pc.video.62`, `pc.video.52`, `pc.video.67`.
  - (Re-picked for Demo 9, when the right-hand line moved back and the cabinet numbering changed. Cabinet ids follow build order, so a layout change can renumber them: check `play/roms.json` and `play/signs.json` before publishing one.)
  - Each wears a small white "PLAYABLE" sticker under its marquee, outlined in its system's colour. The list is `ARCADE` in `scripts/signs.gd`.
- **Playing:** anyone who stands at one of these cabinets, facing it, gets a **PLAY** button, but only once it has a game. The button opens `play/emu.html` in a full-window frame over the mall.
  - The game runs in EmulatorJS (GPL-3.0, loaded from cdn.emulatorjs.org), which has on-screen controls on phones.
  - **Back to the mall** closes the frame.
- **Putting a game on a cabinet (owner only):**
  1. In owner mode, tap **Arcade**. Every playable cabinet shows its system and what is on it.
  2. Tap one. Its setup page accepts only that system's files:
     - Atari 2600: `.a26`, `.bin`;
     - NES: `.nes`, `.fds`, `.unf`;
     - Genesis: `.md`, `.gen`, `.smd`, `.bin`;
     - Super NES: `.sfc`, `.smc`.
  3. The file goes to `play/roms/`, and `play/roms.json` is updated (merged with the live copy). Both use the GitHub token the mall editor keeps in the browser.
  4. **Take it off** removes the cabinet's entry.
  - The game is playable for everyone in about a minute, once Pages updates.
- **ROMs:** only the owner's own files belong in `play/roms/`. Nothing else is shipped.

## Files
- `scripts/signs.gd`: the ARCADE list, stickers, Play button, Arcade mode.
- `web/shell.html`: `window.mallRoms`, the frame.
- `play/emu.html`: player and setup page.
- `play/roms.json`: which ROM each cabinet has.
