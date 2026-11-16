# PHONE-MEMORY, stage 1: where a phone's memory goes (Mon Nov 16, 2026)

> **DRAFT (in progress):** sections a, d and e are written; b, c and the tests are being measured. Placeholders in
> capitals (PACK_TABLE, B_SECTION …) are filled when the runs finish.

Branch `ws/phone-memory` from `ws/seamless-upfront` (`74cef19e`). Stage 1 of the brief: measure, change no
behaviour. The one code change is a memory readout behind `?qa=1` (section c). Not baked, not published, nothing
uploaded.

**Nothing here was run on an iPhone.** Sources: the mobile packs of the last R2 build (`20261114-1715-5ba126d8`,
the int-55 preview Steven's iPhone crashed on; this branch changes no texture), Godot 4.7.2's own source for what
the web renderer does with each format, a native Linux run with a real GL renderer (Mesa llvmpipe) for the engine's
own memory counters, and headless Chromium (swiftshader) for the wasm heap and the page's memory.

## Summary

1. **The mobile lightmaps are 8 times their size in memory on the web.** They ship as ASTC 4x4 **HDR**. Godot's web
   renderer never treats ASTC HDR as supported (it looks for the GL extension name
   `GL_KHR_texture_compression_astc_hdr`, which WebGL never lists: in WebGL, HDR is a "profile" of
   `WEBGL_compressed_texture_astc`). So each lightmap is decompressed on the CPU (astcenc, in the wasm heap) to
   half-float RGBA, 8 bytes a pixel, and uploaded uncompressed. Wing 1 1990s: 12.6 MB on disk, **100.7 MB** in GPU
   memory, plus 12.6 + 100.7 MB of CPU copies in the wasm heap while it is decompressed. A second mall wing adds the
   same again. Computers do not pay this (BC6H is used compressed). This is new: no earlier note mentions it.
2. **Most textures are lossless WebP, uncompressed in memory:** 702 RGB8 files over all mobile packs, 236 MB on
   disk, about 3 GB if every one were loaded. Measured in the engine: see section b.
3. **The page keeps every streamed pack twice.** `web/shell.html` keeps the fetched pack's bytes in
   `window.__mallPre[url]` (a promise that holds the whole ArrayBuffer for the rest of the visit) and
   `engine.copyToFS` copies them into the engine's file system (`FS.writeFile`, a second copy). While the download
   is assembled there is a third (the chunks and the joined array). For wing 2 that is 2 x 94.5 MB held, 3 x briefly.
4. **The wasm heap only grows.** The engine's heap starts at 32 MB and grows in steps of up to 20 % (or 96 MB) to at
   most 2 GB. On iOS growing it can mean finding one new block of the new size and copying the old one, with both
   held for a moment; a heap is never given back.
5. Whether the crash is memory at all is not proven. Section d lists what else happens on the phone 4 s in, and how
   to tell from the readout and from Safari's Web Inspector.

(numbers for b filled in below)

## a. Textures and lightmaps per mobile pack (R2 build `20261114-1715-5ba126d8`)

`tools/qa/packmemory.py <packs> --files` (new) lists every texture with format, size, mips, bytes on disk and bytes
in GPU memory on the web. The full per-file list for every pack is
`production/qa/evidence/wsPHONE-MEMORY-textures.md`. GPU bytes follow Godot 4.7.2's
`drivers/gles3/storage/texture_storage.cpp`: WebP / PNG are decoded and uploaded uncompressed (RGB8 counted as 4
bytes a pixel, as Apple GPUs store it), ETC2 and ASTC LDR stay compressed, ASTC HDR is decompressed to RGBAH (8
bytes a pixel), mip chains counted whole.

"If all loaded" is an upper bound: it counts every texture inside the pack, and a pack carries files a wing only loads
on demand (the directory's 4096 x 4580 close-up panels, 100 MB each in memory, only when the directory is opened; the
items' 2048 pictures only when the item is made). What a wing really loads is measured in section b.

PACK_TABLE

Kinds: *albedo* = surface pictures (walls, floors, fronts, signs, stock); *normal* = normal maps (mostly the Lynn's
2026 and Blender items' 2048 normal maps); *lightmap* = the baked light (one layered texture per wing); *stand-in* =
the pictures of the other wing across the seam and of the room wings' openings; *ui* = item icons, the directory
panels, the dialogue add-on's pictures, fonts; *cast* = the cast's heads and bodies and shopper skins; *items 3D* =
the Blender items' albedo and ORM maps. *Probes*: no reflection-probe or light-probe texture ships in a pack. The
LightmapGI's light probes are a few kilobytes inside the `.lmbake`; the reflection probes (room wings) render into
the engine's probe atlas at run time (in "video memory", section b).

FORMAT_TABLE

Mips: of 2,023 lossless textures, 64 have mipmaps (the cast's heads and bodies, the directory panels). The rest have
none, so mips are not where the memory goes.

### Two wings, upper bounds (every texture of the packs counted once by source path)
A texture both packs carry is loaded once: the second pack is mounted with `replace_files = false` and the same
`res://` path finds the one already in the engine's cache.

UNION_TABLE

### Lightmaps

LM_TABLE

## b. Where one wing's memory goes, then two

B_SECTION

## c. The readout (`?qa=1`)

C_SECTION

## d. Is it memory?

D_SECTION

## e. What iPhone and iPad Safari support, and what Godot's web export does with it

E_SECTION

## Tests

TESTS_SECTION
