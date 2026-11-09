# wsPACKS diagnosis: why Demo 52 is missing content (Nov 8, 2026)

Build checked: Demo 52, R2 `20261106-0332-76f5ee18` (godot-build `30a7645`), against Demo 51, R2 `20261104-d51-4d09e185`.

## Finding (short)

**Every pack is on R2 at the right size, but 81 generated meshes the wing scenes use were never put into the
packs.** The cause is the export, not the upload: the wing scenes committed after the Mac bake
(`198789cf`, Nov 5) carry `uid="…"` on references to `gen/*.res` meshes whose files carry no UID. On every
machine but the Mac those UIDs are unknown. Godot still loads the scene (it logs
`ext_resource, invalid UID … using text path instead`), but the web export's dependency walk resolves the
UID, finds nothing and drops the file. So the scene in the pack names `res://gen/w1/dyn_cinf_sign.res`, the
pack does not hold it, and at runtime that MeshInstance3D is empty. Not a re-upload, not an export-preset
filter, not the 1990s rename or a year filter.

## How it was established

1. **Pack list vs R2 (HEAD every URL).** The live page names build `20261106-0332-76f5ee18`; its `PACK_SIZES` /
   `SHARED_PACKS` list 12 wing packs and 5 shared packs, both kinds (34 files). Every one answers 200 with
   `Content-Length` equal to the size in `index.html`. Same for Demo 51 (32 files, no `chars_w2y26` then).
   `index.pck` 404 in both (expected: there is none). **Nothing failed to upload.**
2. **Inside the packs.** Read each pack's directory by HTTP range (`tools/qa/packcontents.py list`, written for
   this) and compared Demo 51 and 52 by source path. Demo 52's `w1` lacks 27 `gen/w1/dyn_*` meshes that Demo
   51's had (and the textures only they use: `tex/sg/ch_name_face.png`, `tex/sg/rs_face.png`, …); `w2` lacks 25.
3. **The shipped scene still wants them.** Extracted Demo 52's exported `wing1.scn` from `w1.mobile.pck`: it
   names all 56 `gen/w1/dyn_*` meshes, including the 27 the pack lacks.
4. **The missing set is exactly the UID-tagged set.** In `wing1.tscn` 27 `gen/w1/dyn_*` ext_resources carry a
   `uid=`; the 27 missing files are exactly those (set comparison: identical). No reference without a UID is
   missing in any wing. Before `198789cf` no `gen/` reference in any wing scene had a UID (`4d09e185`,
   `2e743364`, `2274d1e5`: 0; `198789cf`, `76f5ee18`: 28 in wing 1).
5. **The UIDs resolve nowhere.** `ResourceLoader.get_dependencies("res://wing1.tscn")` returns
   `uid://fgriepvbptmv::::res://gen/w1/dyn_cinf_sign.res`; `ResourceUID.has_id(uid://fgriepvbptmv)` is false;
   the file's own UID is `<invalid>` (generated binary meshes are saved without one).
6. **Reproduced in this box:** `godot --export-pack "Wing 1 Mobile"` on main ships 29 of the 56 `dyn_` meshes,
   the same 29 as Demo 52, with an `invalid UID … using text path instead` warning per dropped file.
7. **Export presets:** between Demo 51 and 52 `export_presets.cfg` only gained `models/ubc/*.gltf|bin|png`
   excludes (the UBC switch); nothing that touches `gen/` or `tex/sg/`.
8. **Live page console:** see "Console on the live page" below.
9. **Demo 51 comparison of the reference check:** the same scan over Demo 51's `w1` finds only four Dialogue
   Manager editor example files (never needed in the game, also absent in 51); Demo 52's finds those plus the
   27 meshes.

## The exact missing files (Demo 52 packs; scene reference present, file absent)

81 meshes in 9 of 12 wing packs (`w3` and `w6`, `w6y26` are complete; the shared packs are complete).
Store per mesh group from the builder that writes it (`tools/stores/**`).

| Pack | Missing `gen/<pack>/…` | What it is |
|---|---|---|
| **w1** (27) | `dyn_cinf_sign` | Cinema front sign (cinema/front.gd) |
| | `dyn_duf_sign` | Duncan Sports script sign (build_mall.gd) |
| | `dyn_faf_sign` | Foot Action sign (signs/fronts.gd) |
| | `dyn_knbf_sign`, `dyn_lflf_sign` | K&B logo signs; Lady Foot Locker sign (fronts.gd) |
| | `dyn_s6rf_sign` | Radio Shack letters (small/store2.gd) |
| | `dyn_smcf_sign`, `dyn_smgf_props`, `dyn_smmf_props` | Coach House sign; GNC and MasterCuts fronts (small/store.gd) |
| | `dyn_ssf_sign` | Sound Shop sign (media/sound_shop.gd) |
| | `dyn_w7jf_props`, `dyn_w7of_props` | Jean Nicole, Orange Julius fronts (wave7.gd) |
| | `dyn_w8c_paper`, `dyn_w8cf_sign`, `dyn_w8lf_sign`, `dyn_w8of_props`, `dyn_w8tf_props` | Cucos sign + papel picado, Claire's sign, the optical shop, Tee Tai (wave8.gd) |
| | `dyn_w9bf_props`, `dyn_w9rf_sign`, `dyn_w9sf_props` | the bank, Rave sign, Solarium (wave9.gd) |
| | `dyn_wlf_sign` | Woolworth sign (woolworth/store.gd) |
| | `dyn_gbf_props`, `dyn_kbf_props` | Gumballs and Kay-Bee fronts |
| | `dyn_a2f_props`, `dyn_ap_faceout` | apparel fronts and face-out walls (apparel/more.gd, kit.gd) |
| | `dyn_doorpic`, `dyn_standin` | the picture through the outside doors; the other wing's stand-in |
| **w2** (25) | `dyn_w7cf_sign` | **Champs Sports 3D letters** (wave7.gd; the flat sign is in `w7cf_props`, shipped) |
| | `dyn_bbf_props` | **Babbage's** front and neon letters (media/babbages.gd) |
| | `dyn_apf_props`, `dyn_apf_neon` | **579** front, its clothes, its neon (apparel/s579.gd, jw.gd) |
| | `dyn_w7sf_props`, `dyn_w7sf_sign` | **Sports Avenue** front and scoreboard sign (wave7.gd) |
| | `dyn_w7af_props`, `dyn_w7kf_sign`, `dyn_w7mf_props` | Afterthoughts, Great American Cookie sign, Merry-Go-Round (wave7.gd) |
| | `dyn_sdf_sign`, `dyn_flf_sign`, `dyn_payf_sign`, `dyn_aff_sign`, `dyn_bbmf_sign` | Shoe Dept., Foot Locker, Payless, Athlete's Foot, Blockbuster Music signs (fronts.gd) |
| | `dyn_s6bf_props`, `dyn_s6kf_sign`, `dyn_s6zf_sign` | B. Dalton front, Karmelkorn sign, Zales sign (store2.gd) |
| | `dyn_cfaf_sign` | Chick-fil-A sign (cfa/store.gd) |
| | `dyn_pcf_props` | Pocket Change front |
| | `dyn_w8sf_props`, `dyn_w9ff_props` | Saadi, Country Fair (wave8/9.gd) |
| | `dyn_rg_mannequin`, `dyn_a2f_props`, `dyn_ap_faceout`, `dyn_doorpic` | rougarou mannequin, apparel fronts, face-outs, door picture |
| **w4** (1) | `dyn_sr_out` | **Sears**: the lot and sky seen through its outside glass doors (sears/store.gd `outside_view`) |
| **w5** (1) | `dyn_dl_out` | Dillard's: the same for its outside doors |
| **w1y26** (7) | `dyn_H1a_lease`, `dyn_H2_lease`, `dyn_H4_lease`, `dyn_H2_sg26`, `dyn_H4_sg26`, `dyn_ap_small`, `dyn_doorpic` | 2026 lease cards, 2026 sign letters (Aéropostale, GNC, Rainbow), door picture |
| **w2y26** (14) | `dyn_C3_lease`, `dyn_C4_lease`, `dyn_H5_lease`, `dyn_H6_lease`, `dyn_H8_lease`, `dyn_C3_sg26`, `dyn_C4_sg26`, `dyn_H5_sg26`, `dyn_H8_sg26`, `dyn_H5_bbw_sg26`, `dyn_H5`, `dyn_cfaf_sign`, `dyn_cmf_dyn`, `dyn_doorpic` | 2026 lease cards and sign letters (AT&T, Auntie Anne's, Bath & Body Works, Boost, Cell Xpert, Dillard's, Foot Locker, Great American Cookies, JCPenney, Journeys, Lids, Pink), Chick-fil-A, Cinnamonster |
| **w3y26** (3) | `ex_entry`, `ex_props`, `ex_signs` | **2026 outside: the entrances (incl. doors), props, monument signs** (exterior/*.gd) |
| **w4y26** (1) | `dyn_sr_out` | Lynn's (2026 Sears box): the view through the outside doors |
| **w5y26** (2) | `dyn_dl_out`, `dyn_H8_sg26` | Dillard's outside view; its 2026 mall-side letters |

Textures that went with them (used only by those meshes, so also not shipped): `w1`: `tex/ap/faceouts.png`,
`tex/cin/cards.png`, `tex/cin/welcome.png`, `tex/gb/plaque.png`, `tex/sg/{ch,du,fa,rave}_name_face.png`,
`tex/sg/rs_face.png`, `tex/sg/wl_face.png`, `tex/sg/wlr_face.png`, `tex/w8/fret.png`, `tex/w8/papel.png`;
`w2`: `tex/ap/faceouts.png`, `tex/sg/bb_music_face.png`, `tex/sg/{cs,gac,pay,sd,zl}_name_face.png`,
`tex/sg/gac_check.png`, `tex/sg/gac_script_face.png`; `w1y26`, `w2y26`, `w5y26`: 36 `tex/sg/y26/*` sign faces,
`tex/sg/y26/lease_card.png`, `tex/cm/menu.png`, `tex/gac/rgb.png`; `w3y26`: `tex/ex/{aggregate,banner_2026,chainlink,lace_bracket,lace_frieze,mon_2026}.png`, `tex/wood_dark.png`.

(Store names are read from the builder code that writes each group; the file names are exact.)

## Steven's list, explained

| Seen on the live page | Cause |
|---|---|
| ~half the 1990s signage gone; Champs flat sign but no 3D letters | `w2` lacks `dyn_w7cf_sign` (letters) but has `w7cf_props` (flat badge); all `*_sign` groups that carry UIDs are gone |
| Babbage's sign missing | `w2` lacks `dyn_bbf_props` (its neon letters are in that group) |
| Sports Avenue and others | `dyn_w7sf_props`, `dyn_w7sf_sign` and the rest of the table |
| 579 has no clothes | `w2` lacks `dyn_apf_props` (s579.gd puts the front and the stock there). Not a year-filter problem |
| Sears: blank wall where the outside doors were | `w4`/`w4y26` lack `dyn_sr_out` (the view through the glass); the 2026 outside lacks `ex_entry` (its entrances) |
| Concepts' square displays noisy | **Not this bug**: the four solids in its shadow boxes got a spatter-fleck texture on Nov 1 (`wave9.gd` `solid_*`, `tex/w9/concepts_spatter.png`, triplanar). Store fix in stage 3 |

The 2026 year is hit as hard as the 1990s (lease cards, 2026 sign letters, the 2026 entrances), though only the
1990s was reported.

## Fix and what the director must do

- **No re-upload alone fixes it**: the packs on R2 are exactly what the export made. The export must be redone
  from scenes without the stale UIDs.
- Code fix (this branch): `tools/fix_stale_uids.gd` drops `uid=` attributes that do not resolve to their own
  path (101 in the 12 scenes: the 81 meshes, `gen/env_day.tres` ×10 (shipped anyway by an include filter) and
  the 10 `wing*_day.lmbake` light-data references, which only resolve where the lightmaps have been imported);
  `tools/export_web.sh` runs it before exporting; `tools/qa/packcontents.py` checks every reference in every
  pack is shipped and the contents match a checked-in list; `tools/publish_build.sh` refuses otherwise.
- **The director then:** re-export (no rebake: the scene change is the UID attribute only; `wing_hash.sh` does
  not hash the scene, so the stand-in stamps stay valid) and upload the 9 changed wing packs × 2 kinds
  (`w1 w2 w4 w5 w1y26 w2y26 w3y26 w4y26 w5y26`) as a new R2 build with the page. The shared packs and `w3`,
  `w6`, `w6y26` come out the same.

## Console on the live page
(added below once the headless run finished)

Headless Chromium (swiftshader, one browser), `https://stevenboudreaux.github.io/Houma-Mall-Rewind/?cam=0,14,0,0`,
Nov 8 19:54 UTC, 300 s after load (script: `node liveconsole.js`, a `page.waitForTimeout` probe; log kept with
this session, not in the repo):

- Requests: `index.js`, `index.wasm` (github.io) and `items`, `w1`, `chars`, `chars_w1`, then the prefetch of
  `w2`, `w1y26`, `w2y26` (`.desktop.pck`, R2 build `20261106-0332-76f5ee18`): **all HTTP 200, no failed request.**
- Console: 19 lines, engine start, `shared_packs: mounted /mall/items.pck`, `chars.pck`, `chars_w1.pck`, NPCs,
  attendants dressed. **No error and no warning about the missing meshes**: a release web build loads the
  scene through the path fallback and leaves the MeshInstance3D empty without a word. That is why Demo 52's web
  tests ("0 errors") passed: the check has to look inside the packs.
- Shot: `wsPACKS-live-d52-w1-console.jpg` (the probe's view after load; Demo 52's baked lightmaps).

## After the fix (stage 2, same day)
- `tools/fix_stale_uids.gd` removed 91 stale UIDs (the lightmap ones resolve once the lightmaps are imported).
- Full export with the patched `export_web.sh` (`.scratch/builds/packs`, Demo 52's baked lightmaps and stand-ins):
  `packcontents: 12 wing + 5 shared packs, every reference shipped`. Compared with Demo 52's packs only files were
  added: w1 +40, w2 +34, w1y26 +12, w2y26 +45, w3y26 +92, w4 +1, w5 +1, w4y26 +1, w5y26 +3; w3, w6, w6y26 and the
  shared packs unchanged. Sizes (MB): w1 94.36, w2 99.28, w1y26 51.58, w2y26 82.79, w3y26 34.07, w4 42.64,
  w5 43.54, w4y26 96.07, w5y26 38.74 (w2 is near GitHub's old 100 MiB file limit; R2 has none).
- `python3 tools/qa/packcontents.py check` on the downloaded Demo 52 build fails with exactly the files above.
- **One older gap the new check found:** the 2026 outside (`w3y26`) never shipped the pocket-item icons
  (`tex/items/*`, 82 files; also absent in Demo 51), so a carried item would show no icon there. Its two presets
  now include them (`tools/make_presets.py`).
- `.unwrap_cache` files (gitignored importer caches; 7 in the items pack of this box's export, none in Demo 52's)
  are left out of the comparison: whether they exist depends on the machine.

## Stage 3: the stores (before = live Demo 52; after = this branch's export with Demo 52's bake, same cameras)

Every store on Steven's list except Concepts was the delivery bug: no store file needed a change, the meshes
were built and in the scenes, only left out of the packs. Their "after" is the re-export.

| Store | Was | After | Evidence |
|---|---|---|---|
| Champs Sports | rods, no badge (lightmap ghost of the letters) | blue CHAMPS badge on its rods | `wsPACKS-champs-before/after.jpg` |
| Babbage's | bare white fascia | pink neon "Babbage's" | `wsPACKS-babbages-before/after.jpg` |
| 579 | empty pink walls and racks | outfits on the walls | `wsPACKS-579-before/after.jpg` (JW's neon and Foot Locker's sign back too) |
| Sports Avenue | blank blue fascia | SPORTS AVENUE marquee | `wsPACKS-sportsave-before/after.jpg` (Great American Cookie's lettering sharp again) |
| Sears / Lynn's | inside: the exit glass blank; 2026 outside: a crosswalk to a blank wall; the Sears hall's exit doors blank | the lot and sky through the glass; Lynn's 2026 entrance doors; the hall's doors show the lot | `wsPACKS-sears-before/after.jpg` (4 views), `wsPACKS-sears-hall-doors-before-after.jpg` |
| Concepts | speckled solids (Nov 1 spatter, in Demo 51 too) | flat satin colour (`wave9.gd`, own commit) | `wsPACKS-concepts-before-preview-unbaked.jpg` / `-after-preview-unbaked.jpg`; the export shot still shows the spatter until wing 2 is rebuilt |
| Others in the wing walk | the table above (Cinema, Duncan, Foot Action, K&B, Lady Foot Locker, Radio Shack, Coach House, GNC, MasterCuts, Sound Shop, Jean Nicole, Orange Julius, Cucos, Claire's, the optical shop, Tee Tai, the bank, Rave, Solarium, Woolworth, Gumballs, Kay-Bee, The Limited, Afterthoughts, Great American Cookie, Merry-Go-Round, Shoe Dept., Foot Locker, Payless, Athlete's Foot, Blockbuster Music, B. Dalton, Karmelkorn, Zales, Chick-fil-A, Pocket Change, Saadi, Country Fair; 2026: lease cards, 13 stores' letters, Cinnamonster, the outside's entrances and monuments; Dillard's outside doors) | all restored by the same re-export (contents check: every file Demo 52 lacked is in this export) | `wsPACKS-signs-before-after.jpg` (Sports Avenue, Babbage's + Country Fair, Concepts, wing 1 hall) |

Not walked shot by shot: every store front of both years. The pack check proves the files are there; the shots
above sample each kind (sign letters, neon, stock, outside views, the 2026 outside).

`publish_build.sh` dry run (`R2=0 DRY_RUN=1`): Demo 52's packs are refused at the contents check; this branch's
export passes every check.

## Tests on this branch (Nov 8)
The brief's list was "production/session-handoff-2026-11-04-noon-READ-FIRST.md"; no such file is on main, int-51,
int-52, integration or ws/r2-hosting, so the suites are the first eight of the int-52 handoff's table.
Native (headless, unbaked): bake_quality_test BAKE QUALITY OK; items_test OK (49); shop_interiors_test OK (179);
shop_test OK (204); dialogue_walk OK (67); corner_walk_test OK 1995 and 2026; wsS_thresholds_test OK 1995 and 2026;
int_d49_test OK. Web (this branch's full export, desktop packs, swiftshader, one browser at a time; Python
Playwright is not installed here, so the Node ports): shared_webtest.js all 12 maps SHARED WEB OK, 0 console errors;
char_webtest.js (wing 1) CHAR WEB OK desktop and phone; movetest.js (wing 1 hall) MOVED, 0 errors;
tests/unit/hosting/pack_base_test.js PACK BASE OK. New: packcontents_test.py all passed;
`packcontents.py check` passes on this export and fails on Demo 52.
