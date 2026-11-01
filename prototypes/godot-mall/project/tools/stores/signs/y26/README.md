# The 2026 store signs (Demo 43)

Every store sign Steven filmed on Oct 23 2026, rebuilt in 3D for the 2026 year, to the standard of
the 1995 traced signs (Radio Shack, Cucos, KarmelKorn): real letter cans with returns and trim
caps, the frame's colours, lit the way the frame shows them.

## Files
- `parts/<id>.json`: one sign (the spec below). Edit these.
- `src/`: squared-up reference pictures (`<id>_ref.png`), masks for traced shapes (`<id>_<part>_mask.png`),
  `src/fonts/` for any extra OFL font used (with its licence file).
- `<id>_<part>_logo.json`, `../../../tex/sg/y26/<id>_<part>_{face,glow}.png`: generated, don't edit.
- `signs_2026.json`: generated (all parts merged); the game reads it.
- `check/<id>.jpg`: reference | reference with the letters' outlines | letters alone, to look at.

## Commands (from `prototypes/godot-mall/project`)
```
python3 tools/stores/signs/make_signs_2026.py <id> [...]     # letters + textures from parts/<id>.json
python3 tools/stores/signs/check_sign_2026.py <id> [...]     # writes check/<id>.jpg
python3 tools/stores/signs/photo_trace.py quad --photo P --pts "x,y;x,y;x,y;x,y" --aspect W:H --width 1600 --margin 0.08 --out src/<id>_ref.png
```
`photo_trace.py` also has `front` (register a sharp oblique view onto a soft square-on one), `level`,
`mask`, `cut`, `zoom` (see its docstring and `claude/neon-sign-method.md` in the project notes).

## The spec: `parts/<id>.json`
```jsonc
{
  "id": "lynns",                       // file name; lower case, no spaces
  "store": "LYNN'S INTERIORS",         // EXACTLY the store's name in layout_2026.json
  "ref": "IMG_4408 f037 (square-on), f010 (letter detail)",   // the frames it was read from
  "ref_img": "lynns_ref.png",          // the squared-up reference in src/
  "w": 4.2, "h": 1.3,                  // the whole sign's real size, metres (estimated from the frame)
  "mount_y": 0.0,                      // optional: the sign's centre above the fascia band's centre, metres
  "scale": 1.0,                        // optional (ws/g): enlarge the whole spec; still capped by the band
  "drop": 0.0,                         // optional (ws/g): metres the sign may hang below the band
  "mount": "fascia",                   // or "glass": lettering on the storefront glass, centred 1.9 m + "glass_y" up
  "unseen": false,                     // true: no sign in the footage (only "fascia_color"/"backer" are built)
  "type": "flat",                      // default letter type for the parts (see below)
  "depth": 0.08,                       // default can depth (returns), metres
  "standoff": 0.03,                    // gap between the wall and the back of the cans, metres
  "fascia_color": "#f1efe8",           // optional: the wall/band the sign is on, if it differs from plain cream
  "backer": {                          // optional: a panel/box behind the letters
    "shape": "box",                    // box | oval | round
    "w": 3.0, "h": 0.8, "depth": 0.08, "dx": 0.0, "dy": 0.0,   // dy: centre, sign frame
    "color": "#111111", "side": "#111111", "frame": "#c0c0c0", "frame_w": 0.03,
    "lit": 0.0, "emit": "#ffffff", "rough": 0.4, "metal": 0.0
  },
  "raceway": {"w": 3.5, "h": 0.18, "depth": 0.1, "dy": 0.25, "color": "#d8d4cc"},   // optional
  "parts": [
    {
      "name": "script",                // short, lower case, no underscores
      "text": "Lynn's",                // what it says (for traced parts: the letters left to right, no spaces)
      // EITHER a font:
      "font": "GreatVibes-Regular.ttf", // a FONTS key in make_signs_2026.py or a file in src/fonts/
      "cap_h": 0.62,                   // capital height, metres
      "track": 0.0,                    // extra letter spacing, metres
      "stretch": 1.0,                  // horizontal scale (condensed/extended)
      "shear": 0.0,                    // slant: x += shear * y
      // OR a traced mask (white = letters) in src/:
      "trace": "lynns_script_mask.png", "width": 2.4, "smooth": 1.0,
      "dx": -0.3, "dy": 0.05,          // the part's bottom-centre in the sign frame, metres (y up)
      "dz": 0.0,                       // pushes the part forward (a layer over another part), metres
      "type": "flat",                  // channel | flat | halo | neon | vinyl  (see below)
      "depth": 0.06,                   // overrides the sign's
      "face": "#121212", "ret": "#121212", "trim": "#2a2a2a",   // colours; trim only for channel letters
      "lit": 0.0,                      // emission strength of the face (0 = unlit; channel letters ~1)
      "emit": "#ffffff",               // emission colour (default: the face colour)
      "glow": "#ffffff", "glow_pad": 0.25, "glow_e": 0.45,   // optional halo on the wall behind
      "rough": 0.3, "metal": 0.0, "ret_rough": 0.45, "ret_metal": 0.3,
      "ref_box": [412, 220, 1180, 470] // the part's letters' box in ref_img, pixels (for the check)
    }
  ],
  "notes": "what is certain, what is a guess"
}
```
Letter types:
- **channel**: closed-face channel letters, translucent acrylic face lit from inside, painted returns,
  a thin trim cap round the face. The usual mall sign. `lit` ~0.8–1.2; give a `glow` only if the
  frame shows light on the wall.
- **flat**: dimensional letters, not lit (cut acrylic, painted metal, PVC). Face and returns usually
  the same colour. `lit` 0.
- **halo**: reverse-lit: opaque face and returns, the light on the wall behind (`glow` required,
  `glow_e` ~0.8). Face often metal (`metal` 0.6–0.9, `rough` 0.25).
- **neon**: open-face letters with a lit tube; `lit` ~1.5.
- **vinyl**: printed/painted flat on a panel or glass (depth 3 mm). Use it for lettering on a lit
  cabinet face (`backer.lit` > 0) or on a painted band.

Colours: read them off the frame where the surface is evenly lit (avoid highlights and shadows),
then correct for the camera's warm cast in the mall (white walls read ~#f0ece4). Write hex.

Sizes: mall fascias here are a band about 1.4 m tall above a 3.2 m opening; a sign usually
fills 50–80 % of the store's width. Estimate from things of known size in the frame: door
opening 3.0–3.2 m tall, the 2×2 ft (61 cm) ceiling grid, 15 cm floor tiles, a person.
The builder scales a sign down if it doesn't fit its fascia, never up.
