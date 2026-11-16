# PHONE-MEMORY: every texture in every mobile pack (R2 build 20261114-1715-5ba126d8)

Made by `python3 tools/qa/packmemory.py <packs> --files` (Nov 16 2026). GPU bytes: what Godot 4.7.2's web renderer uploads (see `wsPHONE-MEMORY-findings.md` section a). Sorted by GPU bytes within each pack.

### w1.mobile.pck: 90.9 MB pack; textures 325 files, 63.5 MB on disk, 653.6 MB in GPU memory

| Kind | Files | MB on disk | MB in GPU memory (web) |
|---|---|---|---|
| albedo | 179 | 27.1 | 263.9 |
| ui | 100 | 3.2 | 263.8 |
| lightmap | 1 | 12.6 | 100.7 |
| stand-in | 6 | 8.2 | 12.8 |
| cast | 39 | 12.5 | 12.5 |

| Stored as | Files | MB on disk | MB in GPU memory (web) |
|---|---|---|---|
| webp-lossless RGB8 | 158 | 25.7 | 506.3 |
| vram ASTC_4x4_HDR | 1 | 12.6 | 100.7 |
| webp-lossless RGBA8 | 113 | 1.1 | 22.5 |
| vram ETC2_RGB8 | 31 | 17.0 | 17.0 |
| vram ETC2_RGBA8 | 22 | 7.1 | 7.1 |

| Source | Kind | Stored | Format | Size | Mips | Layers | Bytes on disk | Bytes in GPU |
|---|---|---|---|---|---|---|---|---|
| wing1_day.exr | lightmap | image | ASTC_4x4_HDR | 2048x2048 | 0 | 3 | 12582996 | 100663296 |
| tex/dir/hi/panel_1995.png | ui | webp-lossless | RGB8 | 4096x4580 | 12 | 1 | 752008 | 100049940 |
| tex/dir/hi/panel_2026.png | ui | webp-lossless | RGB8 | 4096x4580 | 12 | 1 | 937534 | 100049940 |
| tex/wl/dept_band.png | albedo | webp-lossless | RGB8 | 2048x3072 | 0 | 1 | 2115818 | 25165824 |
| tex/dir/panel_1995.png | ui | webp-lossless | RGB8 | 2048x2290 | 11 | 1 | 342466 | 25011220 |
| tex/dir/panel_2026.png | ui | webp-lossless | RGB8 | 2048x2290 | 11 | 1 | 408600 | 25011220 |
| items/radioshack/tex/cordless_phone.png | albedo | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 19136 | 16777216 |
| items/radioshack/tex/rc_car_box.png | albedo | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 79420 | 16777216 |
| tex/standin/from_w2_day.png | stand-in | image | ETC2_RGB8 | 4096x2048 | 12 | 1 | 5592476 | 5592405 |
| tex/standin/from_w4_day.png | stand-in | webp-lossless | RGB8 | 3072x435 | 0 | 1 | 806648 | 5345280 |
| items/radioshack/tex/battery_card.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 16636 | 4194304 |
| tex/a2/cards.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 348472 | 4194304 |
| tex/sm/cards.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 366350 | 4194304 |
| items/radioshack/tex/cb_radio.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 16362 | 4194304 |
| addons/dialogue_manager/assets/logo.svg | ui | webp-lossless | RGBA8 | 1024x1024 | 0 | 1 | 49440 | 4194304 |
| items/radioshack/tex/microcassette.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 10798 | 4194304 |
| items/radioshack/tex/pager.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 12052 | 4194304 |
| tex/ap/racks.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 412360 | 4194304 |
| items/radioshack/tex/scanner.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 20124 | 4194304 |
| tex/gb/tees.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 558938 | 4194304 |
| tex/pc/video_marquees_blank.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 56112 | 4194304 |
| items/radioshack/tex/walkie_talkies.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 12382 | 4194304 |
| tex/ads/tgmc.png | albedo | webp-lossless | RGB8 | 950x1024 | 0 | 1 | 1010140 | 3891200 |
| tex/ads/dippin_dots.png | albedo | webp-lossless | RGB8 | 871x1024 | 0 | 1 | 902178 | 3567616 |
| tex/cin/posters.png | albedo | webp-lossless | RGB8 | 1024x768 | 0 | 1 | 50844 | 3145728 |
| tex/md/ss_headers.png | albedo | webp-lossless | RGB8 | 512x1536 | 0 | 1 | 241292 | 3145728 |
| tex/ads/concepts.png | albedo | webp-lossless | RGB8 | 850x706 | 0 | 1 | 576862 | 2400400 |
| tex/ads/gryders.png | albedo | webp-lossless | RGB8 | 546x1024 | 0 | 1 | 546098 | 2236416 |
| tex/gb/bins.png | albedo | webp-lossless | RGB8 | 1024x512 | 0 | 1 | 256622 | 2097152 |
| tex/kb/dept_signs.png | albedo | webp-lossless | RGB8 | 512x1024 | 0 | 1 | 229006 | 2097152 |
| tex/ap/faceouts.png | albedo | webp-lossless | RGBA8 | 1024x512 | 0 | 1 | 5410 | 2097152 |
| tex/kb/merch_action.png | albedo | webp-lossless | RGB8 | 512x1024 | 0 | 1 | 260048 | 2097152 |
| tex/kb/merch_dolls.png | albedo | webp-lossless | RGB8 | 512x1024 | 0 | 1 | 278168 | 2097152 |
| tex/kb/merch_games.png | albedo | webp-lossless | RGB8 | 512x1024 | 0 | 1 | 299750 | 2097152 |
| tex/kb/merch_preschool.png | albedo | webp-lossless | RGB8 | 512x1024 | 0 | 1 | 298802 | 2097152 |
| tex/kb/merch_sports.png | albedo | webp-lossless | RGB8 | 512x1024 | 0 | 1 | 275038 | 2097152 |
| tex/kb/merch_vehicles.png | albedo | webp-lossless | RGB8 | 512x1024 | 0 | 1 | 305058 | 2097152 |
| tex/kb/merch_video.png | albedo | webp-lossless | RGB8 | 512x1024 | 0 | 1 | 317516 | 2097152 |
| tex/w9/rave_dresses.png | albedo | webp-lossless | RGB8 | 1024x512 | 0 | 1 | 211898 | 2097152 |
| tex/sm/rs_signs.png | albedo | webp-lossless | RGB8 | 1024x512 | 0 | 1 | 20050 | 2097152 |
| tex/md/ss_posters.png | albedo | webp-lossless | RGB8 | 1024x512 | 0 | 1 | 153786 | 2097152 |
| tex/md/stock_boxes.png | albedo | webp-lossless | RGB8 | 512x1024 | 0 | 1 | 274410 | 2097152 |
| tex/md/stock_candles.png | albedo | webp-lossless | RGB8 | 512x1024 | 0 | 1 | 303906 | 2097152 |
| tex/md/stock_candy.png | albedo | webp-lossless | RGB8 | 512x1024 | 0 | 1 | 329920 | 2097152 |
| tex/md/stock_cd.png | albedo | webp-lossless | RGB8 | 512x1024 | 0 | 1 | 220456 | 2097152 |
| tex/md/stock_gcards.png | albedo | webp-lossless | RGB8 | 512x1024 | 0 | 1 | 331274 | 2097152 |
| tex/md/stock_gifts.png | albedo | webp-lossless | RGB8 | 512x1024 | 0 | 1 | 287830 | 2097152 |
| tex/md/stock_hba.png | albedo | webp-lossless | RGB8 | 512x1024 | 0 | 1 | 334088 | 2097152 |
| tex/md/stock_linens.png | albedo | webp-lossless | RGB8 | 512x1024 | 0 | 1 | 291266 | 2097152 |
| tex/md/stock_party.png | albedo | webp-lossless | RGB8 | 512x1024 | 0 | 1 | 313704 | 2097152 |
| tex/md/stock_rsbatt.png | albedo | webp-lossless | RGB8 | 512x1024 | 0 | 1 | 305454 | 2097152 |
| tex/md/stock_rsboxes.png | albedo | webp-lossless | RGB8 | 512x1024 | 0 | 1 | 228362 | 2097152 |
| tex/md/stock_rsparts.png | albedo | webp-lossless | RGB8 | 512x1024 | 0 | 1 | 332562 | 2097152 |
| tex/md/stock_rsphones.png | albedo | webp-lossless | RGB8 | 512x1024 | 0 | 1 | 285686 | 2097152 |
| tex/md/stock_tape.png | albedo | webp-lossless | RGB8 | 512x1024 | 0 | 1 | 255662 | 2097152 |
| tex/md/tickets.png | albedo | webp-lossless | RGB8 | 1024x512 | 0 | 1 | 221670 | 2097152 |
| tex/w8/tux.png | albedo | webp-lossless | RGB8 | 1024x512 | 0 | 1 | 297886 | 2097152 |
| tex/int_atlas.png | albedo | image | ETC2_RGB8 | 2048x1536 | 11 | 1 | 2097228 | 2097151 |
| tex/ads/radiofone.png | albedo | webp-lossless | RGB8 | 534x855 | 0 | 1 | 180650 | 1826280 |
| tex/ads/saadis.png | albedo | webp-lossless | RGB8 | 617x727 | 0 | 1 | 408418 | 1794236 |
| tex/ads/vision_plaza.png | albedo | webp-lossless | RGB8 | 602x743 | 0 | 1 | 410612 | 1789144 |
| tex/standin/door_w1_day.png | stand-in | image | ETC2_RGB8 | 1152x2304 | 11 | 1 | 1769620 | 1769468 |
| tex/gb/jackets.png | albedo | webp-lossless | RGB8 | 1024x420 | 0 | 1 | 283748 | 1720320 |
| tex/md/bb_counter.png | albedo | webp-lossless | RGB8 | 1024x400 | 0 | 1 | 183128 | 1638400 |
| tex/kb/counter.png | albedo | webp-lossless | RGB8 | 1024x400 | 0 | 1 | 194114 | 1638400 |
| tex/md/ss_counter.png | albedo | webp-lossless | RGB8 | 1024x400 | 0 | 1 | 188894 | 1638400 |
| tex/gb/bl_posters.png | albedo | webp-lossless | RGB8 | 1024x384 | 0 | 1 | 60068 | 1572864 |
| tex/wl/counter.png | albedo | webp-lossless | RGB8 | 1024x384 | 0 | 1 | 121916 | 1572864 |
| tex/sg/felgers_8bit.png | albedo | webp-lossless | RGB8 | 880x416 | 0 | 1 | 2416 | 1464320 |
| tex/ads/gumballs.png | albedo | webp-lossless | RGB8 | 667x519 | 0 | 1 | 325004 | 1384692 |
| tex/ads/scatterbars.png | albedo | webp-lossless | RGB8 | 633x544 | 0 | 1 | 348364 | 1377408 |
| tex/kb/tile_wall.png | albedo | webp-lossless | RGB8 | 1280x256 | 0 | 1 | 144902 | 1310720 |
| tex/sg/rave_name_face.png | albedo | webp-lossless | RGB8 | 1024x260 | 0 | 1 | 55788 | 1064960 |
| tex/gb/boxes.png | albedo | webp-lossless | RGB8 | 512x512 | 0 | 1 | 135000 | 1048576 |
| tex/cin/brick.png | albedo | webp-lossless | RGB8 | 512x512 | 0 | 1 | 119306 | 1048576 |
| tex/kb/cards.png | albedo | webp-lossless | RGB8 | 512x512 | 0 | 1 | 102640 | 1048576 |
| tex/gb/cards.png | albedo | webp-lossless | RGB8 | 512x512 | 0 | 1 | 122956 | 1048576 |
| tex/kb/carpet.png | albedo | webp-lossless | RGB8 | 512x512 | 0 | 1 | 192890 | 1048576 |
| tex/md/carpet_grey.png | albedo | webp-lossless | RGB8 | 512x512 | 0 | 1 | 185418 | 1048576 |
| tex/a2/carpet_grey.png | albedo | webp-lossless | RGB8 | 512x512 | 0 | 1 | 185846 | 1048576 |
| tex/a2/carpet_mauve.png | albedo | webp-lossless | RGB8 | 512x512 | 0 | 1 | 190534 | 1048576 |
| tex/a2/carpet_teal.png | albedo | webp-lossless | RGB8 | 512x512 | 0 | 1 | 180088 | 1048576 |
| tex/sg/fa_star_glow.png | albedo | webp-lossless | RGBA8 | 512x512 | 0 | 1 | 55732 | 1048576 |
| tex/wl/food_photos.png | albedo | webp-lossless | RGB8 | 1024x256 | 0 | 1 | 134882 | 1048576 |
| tex/w8/frames.png | albedo | webp-lossless | RGB8 | 512x512 | 0 | 1 | 97740 | 1048576 |
| tex/wl/garments.png | albedo | webp-lossless | RGB8 | 1024x256 | 0 | 1 | 79338 | 1048576 |
| tex/w9/gate.png | albedo | webp-lossless | RGBA8 | 512x512 | 0 | 1 | 474 | 1048576 |
| tex/w8/jewel_cards.png | albedo | webp-lossless | RGB8 | 512x512 | 0 | 1 | 124184 | 1048576 |
| tex/sg/kb_brick.png | albedo | webp-lossless | RGB8 | 512x512 | 0 | 1 | 149188 | 1048576 |
| tex/w8/marble.png | albedo | webp-lossless | RGB8 | 512x512 | 0 | 1 | 30678 | 1048576 |
| tex/kb/plush.png | albedo | webp-lossless | RGB8 | 512x512 | 0 | 1 | 165360 | 1048576 |
| tex/gb/plush.png | albedo | webp-lossless | RGB8 | 1024x256 | 0 | 1 | 136932 | 1048576 |
| tex/w8/portraits.png | albedo | webp-lossless | RGB8 | 1024x256 | 0 | 1 | 64982 | 1048576 |
| tex/w9/posters.png | albedo | webp-lossless | RGB8 | 1024x256 | 0 | 1 | 127278 | 1048576 |
| addons/dialogue_manager/assets/resource.svg | ui | webp-lossless | RGBA8 | 512x512 | 0 | 1 | 13392 | 1048576 |
| tex/wl/signs.png | albedo | webp-lossless | RGB8 | 512x512 | 0 | 1 | 102422 | 1048576 |
| tex/md/ss_cards.png | albedo | webp-lossless | RGB8 | 512x512 | 0 | 1 | 102024 | 1048576 |
| tex/md/ss_stucco.png | albedo | webp-lossless | RGB8 | 512x512 | 0 | 1 | 147640 | 1048576 |
| tex/md/ss_tile_black.png | albedo | webp-lossless | RGB8 | 512x512 | 0 | 1 | 119174 | 1048576 |
| tex/w8/tt_menu.png | albedo | webp-lossless | RGB8 | 1024x256 | 0 | 1 | 24462 | 1048576 |
| tex/w8/tux_shirts.png | albedo | webp-lossless | RGB8 | 512x512 | 0 | 1 | 103210 | 1048576 |
| tex/sg/rs_face.png | albedo | webp-lossless | RGB8 | 1024x211 | 0 | 1 | 47760 | 864256 |
| tex/sg/cla_name_glow.png | albedo | webp-lossless | RGBA8 | 512x394 | 0 | 1 | 60756 | 806912 |
| tex/gb/incense.png | albedo | webp-lossless | RGB8 | 1024x192 | 0 | 1 | 94324 | 786432 |
| npc/skins/Ch01_0.png | cast | image | ETC2_RGBA8 | 768x768 | 9 | 1 | 786532 | 786430 |
| npc/skins/Ch06_0.png | cast | image | ETC2_RGBA8 | 768x768 | 9 | 1 | 786532 | 786430 |
| npc/skins/Ch12_0.png | cast | image | ETC2_RGBA8 | 768x768 | 9 | 1 | 786532 | 786430 |
| npc/skins/Ch28_0.png | cast | image | ETC2_RGBA8 | 768x768 | 9 | 1 | 786532 | 786430 |
| tex/wl/lunch_front.png | albedo | webp-lossless | RGB8 | 480x400 | 0 | 1 | 137340 | 768000 |
| tex/wl/price_strip.png | albedo | webp-lossless | RGB8 | 1600x120 | 0 | 1 | 8990 | 768000 |
| tex/sg/fa_name_face.png | albedo | webp-lossless | RGB8 | 1024x152 | 0 | 1 | 35768 | 622592 |
| tex/sg/wlr_face.png | albedo | webp-lossless | RGB8 | 1024x134 | 0 | 1 | 32848 | 548864 |
| tex/w8/bar.png | albedo | webp-lossless | RGB8 | 512x256 | 0 | 1 | 68636 | 524288 |
| tex/md/bin_tops.png | albedo | webp-lossless | RGB8 | 512x256 | 0 | 1 | 54534 | 524288 |
| tex/kb/carton.png | albedo | webp-lossless | RGB8 | 512x256 | 0 | 1 | 46740 | 524288 |
| tex/ap/folded.png | albedo | webp-lossless | RGB8 | 512x256 | 0 | 1 | 53992 | 524288 |
| tex/w8/hats.png | albedo | webp-lossless | RGBA8 | 1024x128 | 0 | 1 | 2830 | 524288 |
| tex/sm/jewels.png | albedo | webp-lossless | RGB8 | 512x256 | 0 | 1 | 60232 | 524288 |
| tex/gb/knick.png | albedo | webp-lossless | RGB8 | 512x256 | 0 | 1 | 69632 | 524288 |
| tex/w8/mitchell_sign.png | albedo | webp-lossless | RGB8 | 512x256 | 0 | 1 | 9350 | 524288 |
| tex/gb/oval.png | albedo | webp-lossless | RGB8 | 512x256 | 0 | 1 | 16128 | 524288 |
| tex/w8/papel.png | albedo | webp-lossless | RGBA8 | 1024x128 | 0 | 1 | 1682 | 524288 |
| tex/w8/planks.png | albedo | webp-lossless | RGB8 | 256x512 | 0 | 1 | 87488 | 524288 |
| tex/sm/rs_cards.png | albedo | webp-lossless | RGB8 | 512x256 | 0 | 1 | 8164 | 524288 |
| tex/gb/showcase.png | albedo | webp-lossless | RGB8 | 512x256 | 0 | 1 | 66070 | 524288 |
| tex/gb/snacks.png | albedo | webp-lossless | RGB8 | 256x512 | 0 | 1 | 9598 | 524288 |
| tex/sm/terrazzo.png | albedo | webp-lossless | RGB8 | 1024x128 | 0 | 1 | 44496 | 524288 |
| tex/sg/du_name_face.png | albedo | webp-lossless | RGB8 | 1024x106 | 0 | 1 | 30168 | 434176 |
| tex/sg/wl_face.png | albedo | webp-lossless | RGB8 | 1024x101 | 0 | 1 | 26350 | 413696 |
| tex/sg/rave_name_glow.png | albedo | webp-lossless | RGBA8 | 512x193 | 0 | 1 | 45150 | 395264 |
| tex/items/it_die.png | ui | webp-lossless | RGB8 | 384x256 | 0 | 1 | 10654 | 393216 |
| tex/items/it_pog_card.png | ui | webp-lossless | RGB8 | 256x384 | 0 | 1 | 2214 | 393216 |
| tex/gb/sale.png | albedo | webp-lossless | RGB8 | 256x384 | 0 | 1 | 7808 | 393216 |
| tex/cin/welcome.png | albedo | webp-lossless | RGB8 | 256x384 | 0 | 1 | 11746 | 393216 |
| npc/skins/Ch02_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch08_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch13_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch17_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch21_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch22_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch23_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch26_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch27_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch36_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch37_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch38_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch41_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch42_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Remy_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| tex/palm_frond.png | albedo | image | ETC2_RGBA8 | 256x1024 | 10 | 1 | 349636 | 349527 |
| tex/int_side.png | albedo | image | ETC2_RGB8 | 1024x512 | 10 | 1 | 349596 | 349525 |
| tex/leafy.png | albedo | image | ETC2_RGBA8 | 512x512 | 9 | 1 | 349604 | 349525 |
| tex/poinsettia.png | albedo | image | ETC2_RGBA8 | 512x512 | 9 | 1 | 349604 | 349525 |
| tex/gb/plaque.png | albedo | webp-lossless | RGB8 | 512x160 | 0 | 1 | 28502 | 327680 |
| tex/sg/rs_glow.png | albedo | webp-lossless | RGBA8 | 512x156 | 0 | 1 | 24320 | 319488 |
| tex/sg/ch_name_face.png | albedo | webp-lossless | RGB8 | 1024x68 | 0 | 1 | 19102 | 278528 |
| tex/dir/back.png | ui | webp-lossless | RGB8 | 256x256 | 0 | 1 | 26040 | 262144 |
| items/radioshack/icons/battery_card.png | albedo | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 12204 | 262144 |
| tex/cin/cards.png | albedo | webp-lossless | RGB8 | 512x128 | 0 | 1 | 9842 | 262144 |
| tex/cin/carpet.png | albedo | webp-lossless | RGB8 | 256x256 | 0 | 1 | 428 | 262144 |
| items/radioshack/icons/cb_radio.png | albedo | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 9542 | 262144 |
| tex/w8/clay.png | albedo | webp-lossless | RGB8 | 256x256 | 0 | 1 | 22776 | 262144 |
| items/radioshack/icons/cordless_phone.png | albedo | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 12268 | 262144 |
| tex/kb/dept_blank.png | albedo | webp-lossless | RGB8 | 512x128 | 0 | 1 | 30414 | 262144 |
| tex/wl/floor.png | albedo | webp-lossless | RGB8 | 256x256 | 0 | 1 | 11658 | 262144 |
| tex/gb/floor.png | albedo | webp-lossless | RGB8 | 256x256 | 0 | 1 | 26386 | 262144 |
| tex/gb/gumballs.png | albedo | webp-lossless | RGB8 | 256x256 | 0 | 1 | 6688 | 262144 |
| items/radioshack/icons/microcassette.png | albedo | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 13718 | 262144 |
| items/radioshack/icons/pager.png | albedo | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 10640 | 262144 |
| tex/items/pc_claw_bruiser.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 17348 | 262144 |
| tex/items/pc_claw_comet.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 24656 | 262144 |
| tex/items/pc_claw_crawfish.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 10722 | 262144 |
| tex/items/pc_claw_gator.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 8960 | 262144 |
| tex/items/pc_claw_nutria.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 8880 | 262144 |
| tex/items/pc_claw_pelican.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 15710 | 262144 |
| tex/items/pc_claw_pogEye.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 16462 | 262144 |
| tex/items/pc_claw_pogGator.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 21136 | 262144 |
| tex/items/pc_claw_pogSkull.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 18510 | 262144 |
| tex/items/pc_claw_rougarou.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 18412 | 262144 |
| tex/items/pc_claw_slammer.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 30160 | 262144 |
| tex/gb/plasma.png | albedo | webp-lossless | RGB8 | 256x256 | 0 | 1 | 9170 | 262144 |
| items/radioshack/icons/rc_car_box.png | albedo | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 25644 | 262144 |
| tex/w8/ribbed.png | albedo | webp-lossless | RGB8 | 256x256 | 0 | 1 | 36208 | 262144 |
| tex/w8/saltillo.png | albedo | webp-lossless | RGB8 | 256x256 | 0 | 1 | 10700 | 262144 |
| items/radioshack/icons/scanner.png | albedo | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 7096 | 262144 |
| tex/sm/slat_green.png | albedo | webp-lossless | RGB8 | 256x256 | 0 | 1 | 21832 | 262144 |
| tex/wl/slats.png | albedo | webp-lossless | RGB8 | 256x256 | 0 | 1 | 29838 | 262144 |
| tex/sm/stone.png | albedo | webp-lossless | RGB8 | 256x256 | 0 | 1 | 6640 | 262144 |
| tex/wl/tile_stripe.png | albedo | webp-lossless | RGB8 | 256x256 | 0 | 1 | 308 | 262144 |
| tex/w8/trays.png | albedo | webp-lossless | RGB8 | 512x128 | 0 | 1 | 33726 | 262144 |
| tex/w8/tt_counter.png | albedo | webp-lossless | RGB8 | 512x128 | 0 | 1 | 28824 | 262144 |
| tex/md/vinyl.png | albedo | webp-lossless | RGB8 | 256x256 | 0 | 1 | 22506 | 262144 |
| items/radioshack/icons/walkie_talkies.png | albedo | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 7474 | 262144 |
| tex/ap/wood.png | albedo | webp-lossless | RGB8 | 256x256 | 0 | 1 | 39350 | 262144 |
| tex/sg/fa_name_glow.png | albedo | webp-lossless | RGBA8 | 512x122 | 0 | 1 | 36320 | 249856 |
| tex/sg/wlr_glow.png | albedo | webp-lossless | RGBA8 | 512x122 | 0 | 1 | 25340 | 249856 |
| tex/sm/rs_screen.png | albedo | webp-lossless | RGB8 | 256x192 | 0 | 1 | 202 | 196608 |
| npc/skins/Ch02_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch08_2.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch13_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch17_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch21_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch22_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch23_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch26_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch27_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch37_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch38_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch41_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch42_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Remy_3.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Remy_5.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| tex/sg/wl_glow.png | albedo | webp-lossless | RGBA8 | 512x87 | 0 | 1 | 26892 | 178176 |
| tex/plaster.png | albedo | image | ETC2_RGB8 | 512x512 | 9 | 1 | 174828 | 174762 |
| tex/stone.png | albedo | image | ETC2_RGB8 | 512x512 | 9 | 1 | 174828 | 174762 |
| tex/wood_dark.png | albedo | image | ETC2_RGB8 | 512x512 | 9 | 1 | 174828 | 174762 |
| tex/sg/du_name_glow.png | albedo | webp-lossless | RGBA8 | 512x84 | 0 | 1 | 27564 | 172032 |
| tex/sg/ch_name_glow.png | albedo | webp-lossless | RGBA8 | 512x78 | 0 | 1 | 26532 | 159744 |
| tex/kb/pegboard.png | albedo | webp-lossless | RGB8 | 192x192 | 0 | 1 | 12844 | 147456 |
| tex/kb/ceiling.png | albedo | webp-lossless | RGB8 | 128x256 | 0 | 1 | 14550 | 131072 |
| tex/w8/fret.png | albedo | webp-lossless | RGBA8 | 512x64 | 0 | 1 | 156 | 131072 |
| tex/wl/lanes.png | albedo | webp-lossless | RGB8 | 512x64 | 0 | 1 | 3408 | 131072 |
| tex/w8/sale.png | albedo | webp-lossless | RGB8 | 256x128 | 0 | 1 | 1048 | 131072 |
| tex/md/screens.png | albedo | webp-lossless | RGB8 | 256x128 | 0 | 1 | 850 | 131072 |
| tex/kb/screens.png | albedo | webp-lossless | RGB8 | 256x128 | 0 | 1 | 676 | 131072 |
| tex/kb/troffer.png | albedo | webp-lossless | RGB8 | 128x256 | 0 | 1 | 326 | 131072 |
| npc/skins/Ch06_1.png | cast | image | ETC2_RGB8 | 384x384 | 8 | 1 | 98380 | 98303 |
| npc/skins/Ch08_1.png | cast | image | ETC2_RGB8 | 384x384 | 8 | 1 | 98380 | 98303 |
| npc/skins/Remy_1.png | cast | image | ETC2_RGB8 | 384x384 | 8 | 1 | 98380 | 98303 |
| npc/skins/Remy_2.png | cast | image | ETC2_RGB8 | 384x384 | 8 | 1 | 98380 | 98303 |
| npc/skins/Remy_4.png | cast | image | ETC2_RGB8 | 384x384 | 8 | 1 | 98380 | 98303 |
| tex/buff_tile.png | albedo | image | ETC2_RGB8 | 384x384 | 8 | 1 | 98380 | 98303 |
| tex/grey_tile.png | albedo | image | ETC2_RGB8 | 384x384 | 8 | 1 | 98380 | 98303 |
| addons/dialogue_manager/assets/update.svg | ui | webp-lossless | RGBA8 | 300x80 | 0 | 1 | 5340 | 96000 |
| tex/items/candy_neck.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7674 | 65536 |
| tex/w7/diamonds.png | albedo | webp-lossless | RGB8 | 256x64 | 0 | 1 | 6988 | 65536 |
| tex/items/dice.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 9836 | 65536 |
| tex/items/folse_stick.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 1630 | 65536 |
| tex/items/gi_arcade.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8266 | 65536 |
| tex/items/gi_blind_bag.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7194 | 65536 |
| tex/items/gi_bubbles.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 3996 | 65536 |
| tex/items/gi_cable.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5340 | 65536 |
| tex/items/gi_console.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 6826 | 65536 |
| tex/items/gi_earbuds.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4728 | 65536 |
| tex/items/gi_emoji_key.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7826 | 65536 |
| tex/items/gi_fidget.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5842 | 65536 |
| tex/items/gi_giftcard.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 3986 | 65536 |
| tex/items/gi_handheld.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8894 | 65536 |
| tex/items/gi_headphones.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8400 | 65536 |
| tex/items/gi_jumbo.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 9108 | 65536 |
| tex/items/gi_led_wand.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 3140 | 65536 |
| tex/items/gi_ledstrip.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8872 | 65536 |
| tex/items/gi_light_ring.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4662 | 65536 |
| tex/items/gi_phone_stand.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5930 | 65536 |
| tex/items/gi_play_ball.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8812 | 65536 |
| tex/items/gi_popper_board.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 12764 | 65536 |
| tex/items/gi_popper_key.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 10584 | 65536 |
| tex/items/gi_projector.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 9032 | 65536 |
| tex/items/gi_slime.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4566 | 65536 |
| tex/items/gi_speaker.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8356 | 65536 |
| tex/items/gi_squish_big.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8714 | 65536 |
| tex/items/gi_squishy.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 6306 | 65536 |
| tex/kb/louver.png | albedo | webp-lossless | RGB8 | 128x128 | 0 | 1 | 136 | 65536 |
| tex/items/pc_alien.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7690 | 65536 |
| tex/items/pc_army_men.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8094 | 65536 |
| tex/items/pc_ball.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8816 | 65536 |
| tex/items/pc_big_bear.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 9518 | 65536 |
| tex/items/pc_big_dice.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5086 | 65536 |
| tex/items/pc_bounce_ball.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 6942 | 65536 |
| tex/items/pc_candy_cig.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4658 | 65536 |
| tex/items/pc_candy_ring.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 6156 | 65536 |
| tex/items/pc_candy_roll.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7588 | 65536 |
| tex/items/pc_cassette.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 10530 | 65536 |
| tex/items/pc_chew.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7948 | 65536 |
| tex/items/pc_eraser.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4264 | 65536 |
| tex/items/pc_glow_bracelet.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 6834 | 65536 |
| tex/items/pc_harmonica.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4880 | 65536 |
| tex/items/pc_jelly_bracelet.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7044 | 65536 |
| tex/items/pc_jelly_trap.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4798 | 65536 |
| tex/items/pc_lcd_game.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 9072 | 65536 |
| tex/items/pc_lollipop.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 2738 | 65536 |
| tex/items/pc_mood_ring.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4768 | 65536 |
| tex/items/pc_paddle_ball.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5216 | 65536 |
| tex/items/pc_pencil.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 3574 | 65536 |
| tex/items/pc_powder_straw.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 3608 | 65536 |
| tex/items/pc_rc_car.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 11782 | 65536 |
| tex/items/pc_rubber_snake.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 6154 | 65536 |
| tex/items/pc_slammer.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 920 | 65536 |
| tex/items/pc_sour_candy.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4724 | 65536 |
| tex/items/pc_spider_ring.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 3560 | 65536 |
| tex/items/pc_stickers.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7440 | 65536 |
| tex/items/pc_sticky_hand.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5404 | 65536 |
| tex/items/pc_sunglasses.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 6408 | 65536 |
| tex/items/pc_taffy.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5558 | 65536 |
| tex/items/pc_toy_car.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7670 | 65536 |
| tex/items/pc_vpet.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7950 | 65536 |
| tex/items/pc_walkie.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7800 | 65536 |
| tex/items/pc_water_pistol.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5392 | 65536 |
| tex/items/pogs.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 10278 | 65536 |
| tex/sm/rs_valance.png | albedo | webp-lossless | RGB8 | 256x64 | 0 | 1 | 622 | 65536 |
| tex/items/slap.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5130 | 65536 |
| tex/gb/slat_black.png | albedo | webp-lossless | RGB8 | 128x128 | 0 | 1 | 7340 | 65536 |
| tex/gb/slat_white.png | albedo | webp-lossless | RGB8 | 128x128 | 0 | 1 | 7330 | 65536 |
| tex/items/spring.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 16232 | 65536 |
| tex/wl/vinyl_booth.png | albedo | webp-lossless | RGB8 | 128x128 | 0 | 1 | 2188 | 65536 |
| tex/standin/from_w4_night.png | stand-in | webp-lossless | RGB8 | 256x36 | 0 | 1 | 9700 | 36864 |
| tex/items/it_rainbow.png | ui | webp-lossless | RGB8 | 32x256 | 0 | 1 | 196 | 32768 |
| tex/items/it_slap.png | ui | webp-lossless | RGB8 | 256x32 | 0 | 1 | 620 | 32768 |
| tex/gb/lava.png | albedo | webp-lossless | RGB8 | 64x128 | 0 | 1 | 1584 | 32768 |
| tex/kb/shelf_edge.png | albedo | webp-lossless | RGB8 | 512x16 | 0 | 1 | 286 | 32768 |
| tex/standin/door_w1_night.png | stand-in | image | ETC2_RGB8 | 128x256 | 8 | 1 | 21916 | 21845 |
| tex/standin/from_w2_night.png | stand-in | image | ETC2_RGB8 | 256x128 | 8 | 1 | 21916 | 21845 |
| tex/items/it_candy.png | ui | webp-lossless | RGB8 | 256x16 | 0 | 1 | 172 | 16384 |
| tex/items/it_halo.png | ui | webp-lossless | RGBA8 | 64x64 | 0 | 1 | 820 | 16384 |
| tex/kb/wire.png | albedo | webp-lossless | RGBA8 | 64x64 | 0 | 1 | 152 | 16384 |
| addons/dialogue_manager/assets/cue.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 174 | 1024 |
| addons/dialogue_manager/nodes/actionable/dialogue_actionable_2d.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 318 | 1024 |
| addons/dialogue_manager/nodes/actionable/dialogue_actionable_3d.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 272 | 1024 |
| addons/dialogue_manager/nodes/dialogue_label/dialogue_label.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 350 | 1024 |
| addons/dialogue_manager/nodes/marker/dialogue_marker_2d.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 282 | 1024 |
| addons/dialogue_manager/nodes/marker/dialogue_marker_3d.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 262 | 1024 |
| addons/dialogue_manager/nodes/responses_menu/dialogue_responses_menu.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 224 | 1024 |
| addons/dialogue_manager/nodes/context/dialogue_state_context.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 320 | 1024 |
| addons/dialogue_manager/assets/icon.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 322 | 1024 |
| addons/dialogue_manager/assets/region.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 158 | 1024 |

### w2.mobile.pck: 94.5 MB pack; textures 438 files, 60.1 MB on disk, 702.3 MB in GPU memory

| Kind | Files | MB on disk | MB in GPU memory (web) |
|---|---|---|---|
| albedo | 292 | 24.9 | 316.1 |
| ui | 100 | 3.2 | 263.8 |
| lightmap | 1 | 12.6 | 100.7 |
| cast | 39 | 12.5 | 12.5 |
| stand-in | 6 | 7.0 | 9.3 |

| Stored as | Files | MB on disk | MB in GPU memory (web) |
|---|---|---|---|
| webp-lossless RGB8 | 146 | 19.9 | 435.5 |
| webp-lossy RGB8 | 115 | 2.7 | 109.2 |
| vram ASTC_4x4_HDR | 1 | 12.6 | 100.7 |
| webp-lossless RGBA8 | 108 | 1.2 | 24.4 |
| vram ETC2_RGB8 | 31 | 16.3 | 16.3 |
| webp-lossy RGBA8 | 15 | 0.3 | 9.1 |
| vram ETC2_RGBA8 | 22 | 7.1 | 7.1 |

| Source | Kind | Stored | Format | Size | Mips | Layers | Bytes on disk | Bytes in GPU |
|---|---|---|---|---|---|---|---|---|
| wing2_day.exr | lightmap | image | ASTC_4x4_HDR | 2048x2048 | 0 | 3 | 12582996 | 100663296 |
| tex/dir/hi/panel_1995.png | ui | webp-lossless | RGB8 | 4096x4580 | 12 | 1 | 752008 | 100049940 |
| tex/dir/hi/panel_2026.png | ui | webp-lossless | RGB8 | 4096x4580 | 12 | 1 | 937534 | 100049940 |
| tex/dir/panel_1995.png | ui | webp-lossless | RGB8 | 2048x2290 | 11 | 1 | 342466 | 25011220 |
| tex/dir/panel_2026.png | ui | webp-lossless | RGB8 | 2048x2290 | 11 | 1 | 408600 | 25011220 |
| tex/cd7/awning.png | albedo | webp-lossless | RGB8 | 3313x974 | 0 | 1 | 43052 | 12907448 |
| tex/standin/from_w1_day.png | stand-in | image | ETC2_RGB8 | 4096x2048 | 12 | 1 | 5592476 | 5592405 |
| tex/cd7/wall_yellow.png | albedo | webp-lossless | RGB8 | 1160x1160 | 0 | 1 | 218470 | 5382400 |
| tex/gac/pics.png | albedo | webp-lossless | RGB8 | 2048x552 | 0 | 1 | 1340396 | 4521984 |
| tex/y95/beetle.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 12444 | 4194304 |
| tex/a2/cards.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 348472 | 4194304 |
| tex/pc/cyclone_field.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 220992 | 4194304 |
| addons/dialogue_manager/assets/logo.svg | ui | webp-lossless | RGBA8 | 1024x1024 | 0 | 1 | 49440 | 4194304 |
| tex/ap/racks.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 412360 | 4194304 |
| tex/pc/redeem_cards.png | albedo | webp-lossy | RGBA8 | 1024x1024 | 0 | 1 | 118804 | 4194304 |
| tex/pc/redeem_small.png | albedo | webp-lossy | RGB8 | 1024x1024 | 0 | 1 | 291800 | 4194304 |
| tex/pay/shelves.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 1405690 | 4194304 |
| tex/pc/store_carpet.png | albedo | webp-lossy | RGB8 | 1024x1024 | 0 | 1 | 14700 | 4194304 |
| tex/pc/video_marquees.png | albedo | webp-lossy | RGB8 | 1024x1024 | 0 | 1 | 131096 | 4194304 |
| tex/pc/video_marquees_blank.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 56112 | 4194304 |
| tex/pc/video_panels.png | albedo | webp-lossy | RGB8 | 1024x1024 | 0 | 1 | 96882 | 4194304 |
| tex/pc/video_sides.png | albedo | webp-lossy | RGB8 | 1024x1024 | 0 | 1 | 123216 | 4194304 |
| tex/gac/wall95_b.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 557390 | 4194304 |
| tex/cd7/counter_front.png | albedo | webp-lossless | RGB8 | 1000x1000 | 0 | 1 | 1492 | 4000000 |
| tex/sg/tgmc_8bit.png | albedo | webp-lossless | RGB8 | 1680x576 | 0 | 1 | 6554 | 3870720 |
| tex/cd7/ceiling.png | albedo | webp-lossless | RGB8 | 960x960 | 0 | 1 | 550110 | 3686400 |
| tex/cd7/menu.png | albedo | webp-lossless | RGB8 | 1280x720 | 0 | 1 | 35408 | 3686400 |
| tex/md/bb_headers.png | albedo | webp-lossless | RGB8 | 512x1536 | 0 | 1 | 284644 | 3145728 |
| tex/w8/gcg_sign.png | albedo | webp-lossless | RGB8 | 1536x512 | 0 | 1 | 23220 | 3145728 |
| tex/pc/video_screens.png | albedo | webp-lossy | RGB8 | 1024x768 | 0 | 1 | 94786 | 3145728 |
| tex/cd7/troffer.png | albedo | webp-lossless | RGB8 | 600x1200 | 0 | 1 | 274 | 2880000 |
| tex/pc/ride_side.png | albedo | webp-lossy | RGB8 | 1024x692 | 0 | 1 | 61412 | 2834432 |
| tex/standin/from_w5_day.png | stand-in | webp-lossless | RGB8 | 1536x435 | 0 | 1 | 408404 | 2672640 |
| tex/pc/crane_header_0.png | albedo | webp-lossy | RGB8 | 1024x640 | 0 | 1 | 96384 | 2621440 |
| tex/pc/crane_header_1.png | albedo | webp-lossy | RGB8 | 1024x640 | 0 | 1 | 84586 | 2621440 |
| tex/pc/crane_header_2.png | albedo | webp-lossy | RGB8 | 1024x640 | 0 | 1 | 105356 | 2621440 |
| tex/pc/cyclone_decal.png | albedo | webp-lossless | RGBA8 | 1024x640 | 0 | 1 | 31788 | 2621440 |
| tex/pc/skee_marquee.png | albedo | webp-lossy | RGB8 | 1024x640 | 0 | 1 | 35892 | 2621440 |
| tex/cd7/floor.png | albedo | webp-lossless | RGB8 | 800x800 | 0 | 1 | 9018 | 2560000 |
| tex/cd7/oak_slats.png | albedo | webp-lossless | RGB8 | 800x800 | 0 | 1 | 2152 | 2560000 |
| tex/cd7/tile_navy.png | albedo | webp-lossless | RGB8 | 800x800 | 0 | 1 | 1736 | 2560000 |
| tex/pc/airhockey_field.png | albedo | webp-lossy | RGB8 | 1024x512 | 0 | 1 | 68180 | 2097152 |
| tex/pay/bags.png | albedo | webp-lossless | RGB8 | 1024x512 | 0 | 1 | 675112 | 2097152 |
| tex/pc/crane_cab_0.png | albedo | webp-lossy | RGB8 | 1024x512 | 0 | 1 | 39924 | 2097152 |
| tex/pc/crane_cab_1.png | albedo | webp-lossy | RGB8 | 1024x512 | 0 | 1 | 39578 | 2097152 |
| tex/pc/crane_cab_2.png | albedo | webp-lossy | RGB8 | 1024x512 | 0 | 1 | 38222 | 2097152 |
| tex/pc/driver_pfield0.png | albedo | webp-lossy | RGB8 | 512x1024 | 0 | 1 | 64070 | 2097152 |
| tex/pc/driver_pfield1.png | albedo | webp-lossy | RGB8 | 512x1024 | 0 | 1 | 46054 | 2097152 |
| tex/pc/driver_pfield2.png | albedo | webp-lossy | RGB8 | 512x1024 | 0 | 1 | 74676 | 2097152 |
| tex/pc/driver_rpanel0.png | albedo | webp-lossy | RGB8 | 1024x512 | 0 | 1 | 20282 | 2097152 |
| tex/pc/driver_rpanel1.png | albedo | webp-lossy | RGB8 | 1024x512 | 0 | 1 | 19744 | 2097152 |
| tex/ap/faceouts.png | albedo | webp-lossless | RGBA8 | 1024x512 | 0 | 1 | 5410 | 2097152 |
| tex/y95/gz_ads.png | albedo | webp-lossless | RGB8 | 1024x512 | 0 | 1 | 13182 | 2097152 |
| tex/pc/hoops_side.png | albedo | webp-lossy | RGB8 | 1024x512 | 0 | 1 | 25850 | 2097152 |
| tex/sp/jerseys.png | albedo | webp-lossless | RGBA8 | 1024x512 | 0 | 1 | 38784 | 2097152 |
| tex/cfa/menu.png | albedo | webp-lossless | RGB8 | 2048x256 | 0 | 1 | 41958 | 2097152 |
| tex/pc/pusher_front.png | albedo | webp-lossless | RGB8 | 1024x512 | 0 | 1 | 59558 | 2097152 |
| tex/pc/pusher_side.png | albedo | webp-lossless | RGB8 | 512x1024 | 0 | 1 | 32574 | 2097152 |
| tex/pc/redeem_tok.png | albedo | webp-lossy | RGB8 | 512x1024 | 0 | 1 | 40390 | 2097152 |
| tex/pc/redeem_wood.png | albedo | webp-lossy | RGB8 | 512x1024 | 0 | 1 | 9538 | 2097152 |
| tex/ap/signs.png | albedo | webp-lossless | RGB8 | 512x1024 | 0 | 1 | 20366 | 2097152 |
| tex/pc/skee_side.png | albedo | webp-lossy | RGB8 | 1024x512 | 0 | 1 | 26370 | 2097152 |
| tex/md/stock_acc.png | albedo | webp-lossless | RGB8 | 512x1024 | 0 | 1 | 338914 | 2097152 |
| tex/md/stock_books.png | albedo | webp-lossless | RGB8 | 512x1024 | 0 | 1 | 234688 | 2097152 |
| tex/md/stock_candles.png | albedo | webp-lossless | RGB8 | 512x1024 | 0 | 1 | 303906 | 2097152 |
| tex/md/stock_candy.png | albedo | webp-lossless | RGB8 | 512x1024 | 0 | 1 | 329920 | 2097152 |
| tex/md/stock_cd.png | albedo | webp-lossless | RGB8 | 512x1024 | 0 | 1 | 220456 | 2097152 |
| tex/md/stock_games.png | albedo | webp-lossless | RGB8 | 512x1024 | 0 | 1 | 246384 | 2097152 |
| tex/md/stock_gifts.png | albedo | webp-lossless | RGB8 | 512x1024 | 0 | 1 | 287830 | 2097152 |
| tex/md/stock_hba.png | albedo | webp-lossless | RGB8 | 512x1024 | 0 | 1 | 334088 | 2097152 |
| tex/md/stock_pc.png | albedo | webp-lossless | RGB8 | 512x1024 | 0 | 1 | 198060 | 2097152 |
| tex/md/stock_tape.png | albedo | webp-lossless | RGB8 | 512x1024 | 0 | 1 | 255662 | 2097152 |
| tex/w9/uniforms.png | albedo | webp-lossless | RGB8 | 1024x512 | 0 | 1 | 232232 | 2097152 |
| tex/pc/video_bezels.png | albedo | webp-lossy | RGB8 | 1024x512 | 0 | 1 | 29720 | 2097152 |
| tex/pc/video_fronts.png | albedo | webp-lossy | RGB8 | 1024x512 | 0 | 1 | 58366 | 2097152 |
| tex/pay/wood.png | albedo | webp-lossless | RGB8 | 1024x512 | 0 | 1 | 752714 | 2097152 |
| tex/int_atlas.png | albedo | image | ETC2_RGB8 | 2048x1536 | 11 | 1 | 2097228 | 2097151 |
| tex/sg/bb_music_face.png | albedo | webp-lossless | RGB8 | 1024x482 | 0 | 1 | 99288 | 1974272 |
| tex/pc/pusher_back.png | albedo | webp-lossless | RGB8 | 1024x448 | 0 | 1 | 377452 | 1835008 |
| tex/md/bb_counter.png | albedo | webp-lossless | RGB8 | 1024x400 | 0 | 1 | 183128 | 1638400 |
| tex/pc/skee_board.png | albedo | webp-lossy | RGB8 | 512x768 | 0 | 1 | 20762 | 1572864 |
| tex/pc/cyclone_front.png | albedo | webp-lossless | RGB8 | 768x482 | 0 | 1 | 42876 | 1480704 |
| tex/pc/hoops_marquee.png | albedo | webp-lossy | RGB8 | 1024x352 | 0 | 1 | 47184 | 1441792 |
| tex/cd7/butcher.png | albedo | webp-lossless | RGB8 | 600x600 | 0 | 1 | 1318 | 1440000 |
| tex/sg/cs_name_face.png | albedo | webp-lossless | RGB8 | 1024x333 | 0 | 1 | 67822 | 1363968 |
| tex/w9/plaque.png | albedo | webp-lossless | RGBA8 | 512x640 | 0 | 1 | 53720 | 1310720 |
| tex/cfa/prints.png | albedo | webp-lossless | RGB8 | 1024x320 | 0 | 1 | 8924 | 1310720 |
| tex/md/release.png | albedo | webp-lossless | RGB8 | 512x640 | 0 | 1 | 136764 | 1310720 |
| tex/pc/cyclone_console.png | albedo | webp-lossless | RGB8 | 1024x288 | 0 | 1 | 27972 | 1179648 |
| tex/pc/cyclone_deck.png | albedo | webp-lossless | RGB8 | 512x528 | 0 | 1 | 27410 | 1081344 |
| tex/md/bb_cards.png | albedo | webp-lossless | RGB8 | 512x512 | 0 | 1 | 97256 | 1048576 |
| tex/md/carpet_grey.png | albedo | webp-lossless | RGB8 | 512x512 | 0 | 1 | 185418 | 1048576 |
| tex/a2/carpet_grey.png | albedo | webp-lossless | RGB8 | 512x512 | 0 | 1 | 185846 | 1048576 |
| tex/a2/carpet_mauve.png | albedo | webp-lossless | RGB8 | 512x512 | 0 | 1 | 190534 | 1048576 |
| tex/a2/carpet_teal.png | albedo | webp-lossless | RGB8 | 512x512 | 0 | 1 | 180088 | 1048576 |
| tex/w8/chains.png | albedo | webp-lossless | RGB8 | 1024x256 | 0 | 1 | 111170 | 1048576 |
| tex/w9/concepts_bags.png | albedo | webp-lossless | RGB8 | 1024x256 | 0 | 1 | 58794 | 1048576 |
| tex/w9/concepts_floor.png | albedo | webp-lossless | RGB8 | 512x512 | 0 | 1 | 78836 | 1048576 |
| tex/w9/concepts_siding.png | albedo | webp-lossless | RGB8 | 512x512 | 0 | 1 | 109078 | 1048576 |
| tex/gac/cookies.png | albedo | webp-lossless | RGB8 | 1024x256 | 0 | 1 | 408480 | 1048576 |
| tex/w9/country.png | albedo | webp-lossless | RGB8 | 1024x256 | 0 | 1 | 108098 | 1048576 |
| tex/pc/crane_glass.png | albedo | webp-lossy | RGBA8 | 512x512 | 0 | 1 | 38622 | 1048576 |
| tex/sg/fl_wood.png | albedo | webp-lossless | RGB8 | 512x512 | 0 | 1 | 167874 | 1048576 |
| tex/pc/hoops_led.png | albedo | webp-lossy | RGB8 | 512x512 | 0 | 1 | 27912 | 1048576 |
| tex/pay/pegs.png | albedo | webp-lossless | RGB8 | 512x512 | 0 | 1 | 311884 | 1048576 |
| tex/ap/posters.png | albedo | webp-lossless | RGB8 | 512x512 | 0 | 1 | 143662 | 1048576 |
| tex/pc/pusher_band.png | albedo | webp-lossless | RGB8 | 1024x256 | 0 | 1 | 23012 | 1048576 |
| tex/pc/pusher_coins.png | albedo | webp-lossless | RGB8 | 512x512 | 0 | 1 | 218482 | 1048576 |
| tex/pc/pusher_marquee.png | albedo | webp-lossless | RGB8 | 1024x256 | 0 | 1 | 98474 | 1048576 |
| tex/cfa/quarry.png | albedo | webp-lossless | RGB8 | 512x512 | 0 | 1 | 357458 | 1048576 |
| tex/w9/quilt.png | albedo | webp-lossless | RGB8 | 512x512 | 0 | 1 | 162734 | 1048576 |
| tex/pc/redeem_desk.png | albedo | webp-lossy | RGB8 | 512x512 | 0 | 1 | 15280 | 1048576 |
| tex/pc/redeem_glass.png | albedo | webp-lossy | RGBA8 | 512x512 | 0 | 1 | 28250 | 1048576 |
| tex/pc/redeem_header.png | albedo | webp-lossy | RGB8 | 1024x256 | 0 | 1 | 27318 | 1048576 |
| tex/pc/redeem_toys.png | albedo | webp-lossy | RGB8 | 512x512 | 0 | 1 | 22660 | 1048576 |
| addons/dialogue_manager/assets/resource.svg | ui | webp-lossless | RGBA8 | 512x512 | 0 | 1 | 13392 | 1048576 |
| tex/pc/ride_console.png | albedo | webp-lossy | RGB8 | 1024x256 | 0 | 1 | 28982 | 1048576 |
| tex/pc/ride_dash.png | albedo | webp-lossy | RGB8 | 512x512 | 0 | 1 | 11300 | 1048576 |
| tex/pc/ride_decals.png | albedo | webp-lossy | RGB8 | 512x512 | 0 | 1 | 40818 | 1048576 |
| tex/pc/ride_marquee.png | albedo | webp-lossy | RGB8 | 1024x256 | 0 | 1 | 38200 | 1048576 |
| tex/pc/ride_title.png | albedo | webp-lossy | RGBA8 | 1024x256 | 0 | 1 | 49122 | 1048576 |
| tex/sg/sd_marble.png | albedo | webp-lossless | RGB8 | 512x512 | 0 | 1 | 134512 | 1048576 |
| tex/pc/skee_lane.png | albedo | webp-lossy | RGB8 | 256x1024 | 0 | 1 | 9344 | 1048576 |
| tex/pc/skee_led.png | albedo | webp-lossy | RGB8 | 512x512 | 0 | 1 | 22406 | 1048576 |
| tex/cd7/steel.png | albedo | webp-lossless | RGB8 | 512x512 | 0 | 1 | 1046 | 1048576 |
| tex/pc/store_tile.png | albedo | webp-lossy | RGB8 | 512x512 | 0 | 1 | 5842 | 1048576 |
| tex/w7/sunset.png | albedo | webp-lossless | RGB8 | 1024x256 | 0 | 1 | 125248 | 1048576 |
| tex/ap/tile_cs.png | albedo | webp-lossless | RGB8 | 512x512 | 0 | 1 | 101854 | 1048576 |
| tex/cfa/wallpaper.png | albedo | webp-lossless | RGB8 | 512x512 | 0 | 1 | 351874 | 1048576 |
| tex/sg/zl_stone.png | albedo | webp-lossless | RGB8 | 512x512 | 0 | 1 | 179866 | 1048576 |
| tex/sg/zl_name_face.png | albedo | webp-lossless | RGB8 | 1024x251 | 0 | 1 | 54482 | 1028096 |
| tex/pc/hoops_front.png | albedo | webp-lossy | RGB8 | 512x452 | 0 | 1 | 15484 | 925696 |
| tex/pc/driver_rmarq0.png | albedo | webp-lossy | RGB8 | 1024x224 | 0 | 1 | 38952 | 917504 |
| tex/pc/driver_rmarq1.png | albedo | webp-lossy | RGB8 | 1024x224 | 0 | 1 | 37868 | 917504 |
| tex/standin/door_w2_day.png | stand-in | image | ETC2_RGB8 | 1152x1152 | 10 | 1 | 884868 | 884733 |
| tex/pc/cyclone_side.png | albedo | webp-lossless | RGB8 | 512x420 | 0 | 1 | 48912 | 860160 |
| tex/pc/driver_ptrans0.png | albedo | webp-lossy | RGB8 | 512x416 | 0 | 1 | 33798 | 851968 |
| tex/pc/driver_ptrans1.png | albedo | webp-lossy | RGB8 | 512x416 | 0 | 1 | 24548 | 851968 |
| tex/pc/driver_ptrans2.png | albedo | webp-lossy | RGB8 | 512x416 | 0 | 1 | 41110 | 851968 |
| tex/pc/airhockey_side.png | albedo | webp-lossy | RGB8 | 1024x200 | 0 | 1 | 9666 | 819200 |
| tex/gac/cake_top.png | albedo | webp-lossless | RGB8 | 512x384 | 0 | 1 | 279952 | 786432 |
| tex/w9/concepts_sign_serif.png | albedo | webp-lossless | RGB8 | 1024x192 | 0 | 1 | 8074 | 786432 |
| tex/pc/ride_screen.png | albedo | webp-lossy | RGB8 | 512x384 | 0 | 1 | 27374 | 786432 |
| tex/w8/saadi_sub.png | albedo | webp-lossless | RGB8 | 1024x192 | 0 | 1 | 4416 | 786432 |
| npc/skins/Ch01_0.png | cast | image | ETC2_RGBA8 | 768x768 | 9 | 1 | 786532 | 786430 |
| npc/skins/Ch06_0.png | cast | image | ETC2_RGBA8 | 768x768 | 9 | 1 | 786532 | 786430 |
| npc/skins/Ch12_0.png | cast | image | ETC2_RGBA8 | 768x768 | 9 | 1 | 786532 | 786430 |
| npc/skins/Ch28_0.png | cast | image | ETC2_RGBA8 | 768x768 | 9 | 1 | 786532 | 786430 |
| tex/pc/skee_front.png | albedo | webp-lossy | RGB8 | 512x352 | 0 | 1 | 14420 | 720896 |
| tex/pc/hoops_board.png | albedo | webp-lossy | RGB8 | 512x342 | 0 | 1 | 8174 | 700416 |
| tex/pc/hoops_ramp.png | albedo | webp-lossy | RGB8 | 256x640 | 0 | 1 | 6492 | 655360 |
| tex/sg/bb_music_glow.png | albedo | webp-lossless | RGBA8 | 512x286 | 0 | 1 | 55498 | 585728 |
| tex/sg/gac_script_face.png | albedo | webp-lossless | RGB8 | 1024x131 | 0 | 1 | 36762 | 536576 |
| tex/sg/sd_name_face.png | albedo | webp-lossless | RGB8 | 1024x129 | 0 | 1 | 30584 | 528384 |
| tex/pc/airhockey_led.png | albedo | webp-lossy | RGB8 | 512x256 | 0 | 1 | 11960 | 524288 |
| tex/md/bin_tops.png | albedo | webp-lossless | RGB8 | 512x256 | 0 | 1 | 54534 | 524288 |
| tex/w9/brick.png | albedo | webp-lossless | RGB8 | 512x256 | 0 | 1 | 56242 | 524288 |
| tex/pc/crane_panel.png | albedo | webp-lossy | RGB8 | 512x256 | 0 | 1 | 12882 | 524288 |
| tex/pc/driver_pside0.png | albedo | webp-lossy | RGB8 | 512x256 | 0 | 1 | 13754 | 524288 |
| tex/pc/driver_pside1.png | albedo | webp-lossy | RGB8 | 512x256 | 0 | 1 | 16026 | 524288 |
| tex/pc/driver_pside2.png | albedo | webp-lossy | RGB8 | 512x256 | 0 | 1 | 15064 | 524288 |
| tex/pc/driver_rside0.png | albedo | webp-lossy | RGB8 | 256x512 | 0 | 1 | 13234 | 524288 |
| tex/pc/driver_rside1.png | albedo | webp-lossy | RGB8 | 256x512 | 0 | 1 | 14920 | 524288 |
| tex/ap/folded.png | albedo | webp-lossless | RGB8 | 512x256 | 0 | 1 | 53992 | 524288 |
| tex/gac/fountain.png | albedo | webp-lossless | RGB8 | 512x256 | 0 | 1 | 154398 | 524288 |
| tex/pay/headers.png | albedo | webp-lossless | RGB8 | 1024x128 | 0 | 1 | 3958 | 524288 |
| tex/pc/hoops_ball.png | albedo | webp-lossy | RGB8 | 512x256 | 0 | 1 | 16872 | 524288 |
| tex/sm/jewels.png | albedo | webp-lossless | RGB8 | 512x256 | 0 | 1 | 60232 | 524288 |
| tex/pay/mat.png | albedo | webp-lossless | RGBA8 | 512x256 | 0 | 1 | 2462 | 524288 |
| tex/sp/racks.png | albedo | webp-lossless | RGB8 | 512x256 | 0 | 1 | 1646 | 524288 |
| tex/pc/ride_rear.png | albedo | webp-lossy | RGB8 | 256x512 | 0 | 1 | 2698 | 524288 |
| tex/pc/store_ceiling.png | albedo | webp-lossy | RGB8 | 256x512 | 0 | 1 | 13910 | 524288 |
| tex/pc/store_glassblock.png | albedo | webp-lossy | RGB8 | 256x512 | 0 | 1 | 14404 | 524288 |
| tex/w8/ties.png | albedo | webp-lossless | RGB8 | 512x256 | 0 | 1 | 70472 | 524288 |
| tex/sg/gac_name_face.png | albedo | webp-lossless | RGB8 | 1024x114 | 0 | 1 | 28130 | 466944 |
| tex/sg/cs_name_glow.png | albedo | webp-lossless | RGBA8 | 512x192 | 0 | 1 | 36980 | 393216 |
| tex/pc/driver_rscr0.png | albedo | webp-lossy | RGB8 | 512x192 | 0 | 1 | 17906 | 393216 |
| tex/pc/driver_rscr1.png | albedo | webp-lossy | RGB8 | 512x192 | 0 | 1 | 17968 | 393216 |
| tex/items/it_die.png | ui | webp-lossless | RGB8 | 384x256 | 0 | 1 | 10654 | 393216 |
| tex/items/it_pog_card.png | ui | webp-lossless | RGB8 | 256x384 | 0 | 1 | 2214 | 393216 |
| npc/skins/Ch02_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch08_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch13_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch17_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch21_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch22_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch23_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch26_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch27_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch36_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch37_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch38_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch41_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch42_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Remy_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| tex/pc/hoops_door.png | albedo | webp-lossy | RGB8 | 256x376 | 0 | 1 | 8306 | 385024 |
| tex/pc/hoops_panel.png | albedo | webp-lossy | RGB8 | 512x186 | 0 | 1 | 12192 | 380928 |
| tex/pc/airhockey_end.png | albedo | webp-lossy | RGB8 | 512x182 | 0 | 1 | 7106 | 372736 |
| tex/sg/zl_name_glow.png | albedo | webp-lossless | RGBA8 | 512x177 | 0 | 1 | 48368 | 362496 |
| tex/sg/pay_name_face.png | albedo | webp-lossless | RGB8 | 1024x88 | 0 | 1 | 23858 | 360448 |
| tex/pc/video_door.png | albedo | webp-lossy | RGB8 | 256x352 | 0 | 1 | 7796 | 360448 |
| tex/palm_frond.png | albedo | image | ETC2_RGBA8 | 256x1024 | 10 | 1 | 349636 | 349527 |
| tex/int_side.png | albedo | image | ETC2_RGB8 | 1024x512 | 10 | 1 | 349596 | 349525 |
| tex/leafy.png | albedo | image | ETC2_RGBA8 | 512x512 | 9 | 1 | 349604 | 349525 |
| tex/poinsettia.png | albedo | image | ETC2_RGBA8 | 512x512 | 9 | 1 | 349604 | 349525 |
| tex/pc/airhockey_unit.png | albedo | webp-lossy | RGB8 | 448x168 | 0 | 1 | 2210 | 301056 |
| tex/pc/driver_coin.png | albedo | webp-lossy | RGB8 | 256x288 | 0 | 1 | 8966 | 294912 |
| tex/pc/airhockey_leg.png | albedo | webp-lossy | RGB8 | 256x256 | 0 | 1 | 2864 | 262144 |
| tex/dir/back.png | ui | webp-lossless | RGB8 | 256x256 | 0 | 1 | 26040 | 262144 |
| tex/a2/capsule.png | albedo | webp-lossless | RGB8 | 512x128 | 0 | 1 | 23332 | 262144 |
| tex/y95/caramel.png | albedo | webp-lossless | RGB8 | 256x256 | 0 | 1 | 59928 | 262144 |
| tex/pay/carpet.png | albedo | webp-lossless | RGB8 | 256x256 | 0 | 1 | 123358 | 262144 |
| tex/sm/cedar.png | albedo | webp-lossless | RGB8 | 256x256 | 0 | 1 | 41444 | 262144 |
| tex/a2/checker.png | albedo | webp-lossless | RGB8 | 256x256 | 0 | 1 | 17778 | 262144 |
| tex/y95/cheese.png | albedo | webp-lossless | RGB8 | 256x256 | 0 | 1 | 61308 | 262144 |
| tex/pc/crane_fur.png | albedo | webp-lossy | RGB8 | 256x256 | 0 | 1 | 15070 | 262144 |
| tex/pc/cyclone_dome.png | albedo | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 17744 | 262144 |
| tex/pc/cyclone_yellow.png | albedo | webp-lossless | RGB8 | 256x256 | 0 | 1 | 5744 | 262144 |
| tex/kb/dept_blank.png | albedo | webp-lossless | RGB8 | 512x128 | 0 | 1 | 30414 | 262144 |
| tex/pc/driver_apron.png | albedo | webp-lossy | RGB8 | 512x128 | 0 | 1 | 7704 | 262144 |
| tex/pc/driver_glass.png | albedo | webp-lossy | RGBA8 | 256x256 | 0 | 1 | 6150 | 262144 |
| tex/pc/driver_lam.png | albedo | webp-lossy | RGB8 | 256x256 | 0 | 1 | 1526 | 262144 |
| tex/pc/driver_pbox0.png | albedo | webp-lossy | RGB8 | 512x128 | 0 | 1 | 3460 | 262144 |
| tex/pc/driver_pbox1.png | albedo | webp-lossy | RGB8 | 512x128 | 0 | 1 | 3652 | 262144 |
| tex/pc/driver_pbox2.png | albedo | webp-lossy | RGB8 | 512x128 | 0 | 1 | 3542 | 262144 |
| tex/pc/driver_pdmd0.png | albedo | webp-lossy | RGB8 | 512x128 | 0 | 1 | 8314 | 262144 |
| tex/pc/driver_pdmd1.png | albedo | webp-lossy | RGB8 | 512x128 | 0 | 1 | 7174 | 262144 |
| tex/pc/driver_pdmd2.png | albedo | webp-lossy | RGB8 | 512x128 | 0 | 1 | 9020 | 262144 |
| tex/pc/driver_vinyl.png | albedo | webp-lossy | RGB8 | 256x256 | 0 | 1 | 10644 | 262144 |
| tex/wl/floor.png | albedo | webp-lossless | RGB8 | 256x256 | 0 | 1 | 11658 | 262144 |
| tex/gb/floor.png | albedo | webp-lossless | RGB8 | 256x256 | 0 | 1 | 26386 | 262144 |
| tex/sg/gac_check.png | albedo | webp-lossless | RGB8 | 256x256 | 0 | 1 | 134 | 262144 |
| tex/a2/gz_tile.png | albedo | webp-lossless | RGB8 | 256x256 | 0 | 1 | 3730 | 262144 |
| tex/pc/hoops_lam.png | albedo | webp-lossy | RGB8 | 256x256 | 0 | 1 | 720 | 262144 |
| tex/pc/hoops_mesh.png | albedo | webp-lossy | RGBA8 | 256x256 | 0 | 1 | 3358 | 262144 |
| tex/pc/hoops_net.png | albedo | webp-lossy | RGBA8 | 256x256 | 0 | 1 | 5438 | 262144 |
| tex/pc/hoops_paint.png | albedo | webp-lossy | RGB8 | 256x256 | 0 | 1 | 1852 | 262144 |
| tex/cfa/labels.png | albedo | webp-lossless | RGB8 | 512x128 | 0 | 1 | 2840 | 262144 |
| tex/w7/mosaic.png | albedo | webp-lossless | RGB8 | 256x256 | 0 | 1 | 664 | 262144 |
| tex/items/pc_claw_bruiser.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 17348 | 262144 |
| tex/items/pc_claw_comet.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 24656 | 262144 |
| tex/items/pc_claw_crawfish.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 10722 | 262144 |
| tex/items/pc_claw_gator.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 8960 | 262144 |
| tex/items/pc_claw_nutria.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 8880 | 262144 |
| tex/items/pc_claw_pelican.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 15710 | 262144 |
| tex/items/pc_claw_pogEye.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 16462 | 262144 |
| tex/items/pc_claw_pogGator.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 21136 | 262144 |
| tex/items/pc_claw_pogSkull.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 18510 | 262144 |
| tex/items/pc_claw_rougarou.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 18412 | 262144 |
| tex/items/pc_claw_slammer.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 30160 | 262144 |
| tex/y95/plain.png | albedo | webp-lossless | RGB8 | 256x256 | 0 | 1 | 54632 | 262144 |
| tex/sm/popcorn.png | albedo | webp-lossless | RGB8 | 256x256 | 0 | 1 | 44652 | 262144 |
| tex/pc/pusher_glass.png | albedo | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 9436 | 262144 |
| tex/pc/pusher_inner.png | albedo | webp-lossless | RGB8 | 256x256 | 0 | 1 | 27098 | 262144 |
| tex/pc/pusher_ramp.png | albedo | webp-lossless | RGB8 | 128x512 | 0 | 1 | 18872 | 262144 |
| tex/y95/red.png | albedo | webp-lossless | RGB8 | 256x256 | 0 | 1 | 60188 | 262144 |
| tex/pc/redeem_band.png | albedo | webp-lossy | RGB8 | 512x128 | 0 | 1 | 5078 | 262144 |
| tex/pc/redeem_fur.png | albedo | webp-lossy | RGB8 | 256x256 | 0 | 1 | 12436 | 262144 |
| tex/pc/redeem_scuff.png | albedo | webp-lossy | RGB8 | 256x256 | 0 | 1 | 3386 | 262144 |
| tex/pc/redeem_slat.png | albedo | webp-lossy | RGB8 | 256x256 | 0 | 1 | 1468 | 262144 |
| tex/pc/ride_carpet.png | albedo | webp-lossy | RGB8 | 256x256 | 0 | 1 | 21386 | 262144 |
| tex/pc/ride_paint.png | albedo | webp-lossy | RGB8 | 256x256 | 0 | 1 | 1318 | 262144 |
| tex/pc/ride_vinyl.png | albedo | webp-lossy | RGB8 | 256x256 | 0 | 1 | 1658 | 262144 |
| tex/pc/skee_metal.png | albedo | webp-lossy | RGB8 | 256x256 | 0 | 1 | 6714 | 262144 |
| tex/pc/skee_rail.png | albedo | webp-lossy | RGB8 | 64x1024 | 0 | 1 | 3512 | 262144 |
| tex/pc/skee_sidetext.png | albedo | webp-lossy | RGBA8 | 512x128 | 0 | 1 | 25010 | 262144 |
| tex/md/slatwall.png | albedo | webp-lossless | RGB8 | 256x256 | 0 | 1 | 15532 | 262144 |
| tex/sm/stone.png | albedo | webp-lossless | RGB8 | 256x256 | 0 | 1 | 6640 | 262144 |
| tex/pc/store_wall.png | albedo | webp-lossy | RGB8 | 256x256 | 0 | 1 | 1744 | 262144 |
| tex/w7/travertine.png | albedo | webp-lossless | RGB8 | 256x256 | 0 | 1 | 4900 | 262144 |
| tex/pc/video_glass.png | albedo | webp-lossy | RGBA8 | 256x256 | 0 | 1 | 5832 | 262144 |
| tex/pc/video_lam.png | albedo | webp-lossy | RGB8 | 256x256 | 0 | 1 | 848 | 262144 |
| tex/cfa/vinyl.png | albedo | webp-lossless | RGB8 | 256x256 | 0 | 1 | 10368 | 262144 |
| tex/md/vinyl.png | albedo | webp-lossless | RGB8 | 256x256 | 0 | 1 | 22506 | 262144 |
| tex/ap/wood.png | albedo | webp-lossless | RGB8 | 256x256 | 0 | 1 | 39350 | 262144 |
| tex/sg/gac_script_glow.png | albedo | webp-lossless | RGBA8 | 512x123 | 0 | 1 | 26140 | 251904 |
| tex/sg/fl_glow.png | albedo | webp-lossless | RGBA8 | 512x113 | 0 | 1 | 27180 | 231424 |
| tex/sg/sd_name_glow.png | albedo | webp-lossless | RGBA8 | 512x102 | 0 | 1 | 32500 | 208896 |
| tex/sg/gac_name_glow.png | albedo | webp-lossless | RGBA8 | 512x100 | 0 | 1 | 32972 | 204800 |
| npc/skins/Ch02_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch08_2.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch13_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch17_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch21_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch22_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch23_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch26_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch27_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch37_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch38_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch41_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch42_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Remy_3.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Remy_5.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| tex/sg/zl_sub_glow.png | albedo | webp-lossless | RGBA8 | 512x92 | 0 | 1 | 24194 | 188416 |
| tex/pc/airhockey_door.png | albedo | webp-lossy | RGB8 | 192x240 | 0 | 1 | 6070 | 184320 |
| tex/pc/cyclone_bonus.png | albedo | webp-lossless | RGB8 | 256x176 | 0 | 1 | 3024 | 180224 |
| tex/brown_stone.png | albedo | image | ETC2_RGB8 | 512x512 | 9 | 1 | 174828 | 174762 |
| tex/plaster.png | albedo | image | ETC2_RGB8 | 512x512 | 9 | 1 | 174828 | 174762 |
| tex/stone.png | albedo | image | ETC2_RGB8 | 512x512 | 9 | 1 | 174828 | 174762 |
| tex/wood_dark.png | albedo | image | ETC2_RGB8 | 512x512 | 9 | 1 | 174828 | 174762 |
| tex/wood_diag.png | albedo | image | ETC2_RGB8 | 512x512 | 9 | 1 | 174828 | 174762 |
| tex/pc/driver_rbase0.png | albedo | webp-lossy | RGB8 | 256x160 | 0 | 1 | 5072 | 163840 |
| tex/pc/driver_rbase1.png | albedo | webp-lossy | RGB8 | 256x160 | 0 | 1 | 5608 | 163840 |
| tex/sg/pay_name_glow.png | albedo | webp-lossless | RGBA8 | 512x73 | 0 | 1 | 24166 | 149504 |
| tex/pc/airhockey_rail.png | albedo | webp-lossy | RGB8 | 1024x36 | 0 | 1 | 4420 | 147456 |
| tex/pc/airhockey_fieldglow.png | albedo | webp-lossy | RGB8 | 256x128 | 0 | 1 | 1432 | 131072 |
| tex/pc/airhockey_lamp.png | albedo | webp-lossy | RGB8 | 256x128 | 0 | 1 | 3478 | 131072 |
| tex/kb/ceiling.png | albedo | webp-lossless | RGB8 | 128x256 | 0 | 1 | 14550 | 131072 |
| tex/pc/crane_face.png | albedo | webp-lossy | RGBA8 | 256x128 | 0 | 1 | 2908 | 131072 |
| tex/pc/cyclone_led.png | albedo | webp-lossless | RGB8 | 256x128 | 0 | 1 | 3596 | 131072 |
| tex/pc/cyclone_tower.png | albedo | webp-lossless | RGB8 | 256x128 | 0 | 1 | 4044 | 131072 |
| tex/pc/driver_ins.png | albedo | webp-lossy | RGBA8 | 256x128 | 0 | 1 | 5250 | 131072 |
| tex/a2/gz_ceiling.png | albedo | webp-lossless | RGB8 | 128x256 | 0 | 1 | 11948 | 131072 |
| tex/sp/pennant.png | albedo | webp-lossless | RGBA8 | 256x128 | 0 | 1 | 1414 | 131072 |
| tex/pc/pusher_edge.png | albedo | webp-lossless | RGB8 | 512x64 | 0 | 1 | 47954 | 131072 |
| tex/md/screens.png | albedo | webp-lossless | RGB8 | 256x128 | 0 | 1 | 850 | 131072 |
| tex/kb/troffer.png | albedo | webp-lossless | RGB8 | 128x256 | 0 | 1 | 326 | 131072 |
| tex/pc/ride_skirt.png | albedo | webp-lossy | RGB8 | 256x96 | 0 | 1 | 598 | 98304 |
| tex/pc/video_kick.png | albedo | webp-lossy | RGB8 | 384x64 | 0 | 1 | 3136 | 98304 |
| npc/skins/Ch06_1.png | cast | image | ETC2_RGB8 | 384x384 | 8 | 1 | 98380 | 98303 |
| npc/skins/Ch08_1.png | cast | image | ETC2_RGB8 | 384x384 | 8 | 1 | 98380 | 98303 |
| npc/skins/Remy_1.png | cast | image | ETC2_RGB8 | 384x384 | 8 | 1 | 98380 | 98303 |
| npc/skins/Remy_2.png | cast | image | ETC2_RGB8 | 384x384 | 8 | 1 | 98380 | 98303 |
| npc/skins/Remy_4.png | cast | image | ETC2_RGB8 | 384x384 | 8 | 1 | 98380 | 98303 |
| addons/dialogue_manager/assets/update.svg | ui | webp-lossless | RGBA8 | 300x80 | 0 | 1 | 5340 | 96000 |
| tex/pc/airhockey_acrylic.png | albedo | webp-lossy | RGBA8 | 512x40 | 0 | 1 | 5428 | 81920 |
| tex/pc/cyclone_coin.png | albedo | webp-lossless | RGB8 | 128x160 | 0 | 1 | 6036 | 81920 |
| tex/standin/from_w5_night.png | stand-in | webp-lossless | RGB8 | 256x73 | 0 | 1 | 20618 | 74752 |
| tex/items/candy_neck.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7674 | 65536 |
| tex/pc/cyclone_button.png | albedo | webp-lossless | RGB8 | 128x128 | 0 | 1 | 3784 | 65536 |
| tex/items/dice.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 9836 | 65536 |
| tex/pc/driver_diamond.png | albedo | webp-lossy | RGB8 | 128x128 | 0 | 1 | 4858 | 65536 |
| tex/pc/driver_grille.png | albedo | webp-lossy | RGB8 | 128x128 | 0 | 1 | 3064 | 65536 |
| tex/pc/driver_steel.png | albedo | webp-lossy | RGB8 | 128x128 | 0 | 1 | 2432 | 65536 |
| tex/items/folse_stick.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 1630 | 65536 |
| tex/items/gi_arcade.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8266 | 65536 |
| tex/items/gi_blind_bag.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7194 | 65536 |
| tex/items/gi_bubbles.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 3996 | 65536 |
| tex/items/gi_cable.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5340 | 65536 |
| tex/items/gi_console.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 6826 | 65536 |
| tex/items/gi_earbuds.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4728 | 65536 |
| tex/items/gi_emoji_key.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7826 | 65536 |
| tex/items/gi_fidget.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5842 | 65536 |
| tex/items/gi_giftcard.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 3986 | 65536 |
| tex/items/gi_handheld.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8894 | 65536 |
| tex/items/gi_headphones.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8400 | 65536 |
| tex/items/gi_jumbo.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 9108 | 65536 |
| tex/items/gi_led_wand.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 3140 | 65536 |
| tex/items/gi_ledstrip.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8872 | 65536 |
| tex/items/gi_light_ring.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4662 | 65536 |
| tex/items/gi_phone_stand.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5930 | 65536 |
| tex/items/gi_play_ball.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8812 | 65536 |
| tex/items/gi_popper_board.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 12764 | 65536 |
| tex/items/gi_popper_key.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 10584 | 65536 |
| tex/items/gi_projector.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 9032 | 65536 |
| tex/items/gi_slime.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4566 | 65536 |
| tex/items/gi_speaker.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8356 | 65536 |
| tex/items/gi_squish_big.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8714 | 65536 |
| tex/items/gi_squishy.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 6306 | 65536 |
| tex/w9/gingham.png | albedo | webp-lossless | RGB8 | 128x128 | 0 | 1 | 160 | 65536 |
| tex/pc/hoops_plate.png | albedo | webp-lossy | RGB8 | 256x64 | 0 | 1 | 3192 | 65536 |
| tex/pc/hoops_ticket.png | albedo | webp-lossy | RGBA8 | 64x256 | 0 | 1 | 4674 | 65536 |
| tex/items/pc_alien.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7690 | 65536 |
| tex/items/pc_army_men.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8094 | 65536 |
| tex/items/pc_ball.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8816 | 65536 |
| tex/items/pc_big_bear.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 9518 | 65536 |
| tex/items/pc_big_dice.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5086 | 65536 |
| tex/items/pc_bounce_ball.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 6942 | 65536 |
| tex/items/pc_candy_cig.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4658 | 65536 |
| tex/items/pc_candy_ring.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 6156 | 65536 |
| tex/items/pc_candy_roll.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7588 | 65536 |
| tex/items/pc_cassette.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 10530 | 65536 |
| tex/items/pc_chew.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7948 | 65536 |
| tex/items/pc_eraser.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4264 | 65536 |
| tex/items/pc_glow_bracelet.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 6834 | 65536 |
| tex/items/pc_harmonica.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4880 | 65536 |
| tex/items/pc_jelly_bracelet.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7044 | 65536 |
| tex/items/pc_jelly_trap.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4798 | 65536 |
| tex/items/pc_lcd_game.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 9072 | 65536 |
| tex/items/pc_lollipop.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 2738 | 65536 |
| tex/items/pc_mood_ring.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4768 | 65536 |
| tex/items/pc_paddle_ball.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5216 | 65536 |
| tex/items/pc_pencil.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 3574 | 65536 |
| tex/items/pc_powder_straw.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 3608 | 65536 |
| tex/items/pc_rc_car.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 11782 | 65536 |
| tex/items/pc_rubber_snake.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 6154 | 65536 |
| tex/items/pc_slammer.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 920 | 65536 |
| tex/items/pc_sour_candy.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4724 | 65536 |
| tex/items/pc_spider_ring.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 3560 | 65536 |
| tex/items/pc_stickers.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7440 | 65536 |
| tex/items/pc_sticky_hand.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5404 | 65536 |
| tex/items/pc_sunglasses.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 6408 | 65536 |
| tex/items/pc_taffy.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5558 | 65536 |
| tex/items/pc_toy_car.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7670 | 65536 |
| tex/items/pc_vpet.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7950 | 65536 |
| tex/items/pc_walkie.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7800 | 65536 |
| tex/items/pc_water_pistol.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5392 | 65536 |
| tex/items/pogs.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 10278 | 65536 |
| tex/pc/pusher_mech.png | albedo | webp-lossless | RGB8 | 128x128 | 0 | 1 | 11582 | 65536 |
| tex/pc/pusher_perf.png | albedo | webp-lossless | RGB8 | 128x128 | 0 | 1 | 7908 | 65536 |
| tex/pc/ride_felt.png | albedo | webp-lossy | RGB8 | 128x128 | 0 | 1 | 2066 | 65536 |
| tex/pc/ride_tread.png | albedo | webp-lossy | RGB8 | 128x128 | 0 | 1 | 4356 | 65536 |
| tex/pc/skee_mesh.png | albedo | webp-lossy | RGBA8 | 128x128 | 0 | 1 | 682 | 65536 |
| tex/pc/skee_num.png | albedo | webp-lossy | RGB8 | 256x64 | 0 | 1 | 2100 | 65536 |
| tex/items/slap.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5130 | 65536 |
| tex/gb/slat_black.png | albedo | webp-lossless | RGB8 | 128x128 | 0 | 1 | 7340 | 65536 |
| tex/gb/slat_white.png | albedo | webp-lossless | RGB8 | 128x128 | 0 | 1 | 7330 | 65536 |
| tex/items/spring.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 16232 | 65536 |
| tex/pc/video_speaker.png | albedo | webp-lossy | RGB8 | 256x64 | 0 | 1 | 1290 | 65536 |
| tex/wl/vinyl_booth.png | albedo | webp-lossless | RGB8 | 128x128 | 0 | 1 | 2188 | 65536 |
| tex/standin/door_w2_night.png | stand-in | image | ETC2_RGB8 | 256x256 | 8 | 1 | 43756 | 43690 |
| tex/pc/cyclone_slot.png | albedo | webp-lossless | RGB8 | 128x64 | 0 | 1 | 1196 | 32768 |
| tex/pc/cyclone_ticket.png | albedo | webp-lossless | RGBA8 | 64x128 | 0 | 1 | 852 | 32768 |
| tex/items/it_rainbow.png | ui | webp-lossless | RGB8 | 32x256 | 0 | 1 | 196 | 32768 |
| tex/items/it_slap.png | ui | webp-lossless | RGB8 | 256x32 | 0 | 1 | 620 | 32768 |
| tex/pc/pusher_coin.png | albedo | webp-lossless | RGB8 | 128x64 | 0 | 1 | 6568 | 32768 |
| tex/f26/ref.png | albedo | webp-lossless | RGB8 | 128x64 | 0 | 1 | 120 | 32768 |
| tex/pc/skee_ball.png | albedo | webp-lossy | RGB8 | 128x64 | 0 | 1 | 1516 | 32768 |
| tex/pc/skee_ticket.png | albedo | webp-lossy | RGB8 | 32x256 | 0 | 1 | 2338 | 32768 |
| tex/pc/video_entry.png | albedo | webp-lossy | RGB8 | 64x128 | 0 | 1 | 1838 | 32768 |
| tex/pc/video_entry_e.png | albedo | webp-lossy | RGB8 | 64x128 | 0 | 1 | 718 | 32768 |
| tex/pc/video_tmold.png | albedo | webp-lossy | RGB8 | 32x256 | 0 | 1 | 728 | 32768 |
| tex/standin/from_w1_night.png | stand-in | image | ETC2_RGB8 | 256x128 | 8 | 1 | 21916 | 21845 |
| tex/pc/driver_tmold.png | albedo | webp-lossy | RGB8 | 64x64 | 0 | 1 | 388 | 16384 |
| tex/items/it_candy.png | ui | webp-lossless | RGB8 | 256x16 | 0 | 1 | 172 | 16384 |
| tex/items/it_halo.png | ui | webp-lossless | RGBA8 | 64x64 | 0 | 1 | 820 | 16384 |
| addons/dialogue_manager/assets/cue.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 174 | 1024 |
| addons/dialogue_manager/nodes/actionable/dialogue_actionable_2d.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 318 | 1024 |
| addons/dialogue_manager/nodes/actionable/dialogue_actionable_3d.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 272 | 1024 |
| addons/dialogue_manager/nodes/dialogue_label/dialogue_label.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 350 | 1024 |
| addons/dialogue_manager/nodes/marker/dialogue_marker_2d.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 282 | 1024 |
| addons/dialogue_manager/nodes/marker/dialogue_marker_3d.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 262 | 1024 |
| addons/dialogue_manager/nodes/responses_menu/dialogue_responses_menu.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 224 | 1024 |
| addons/dialogue_manager/nodes/context/dialogue_state_context.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 320 | 1024 |
| addons/dialogue_manager/assets/icon.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 322 | 1024 |
| addons/dialogue_manager/assets/region.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 158 | 1024 |
| tex/pc/video_scan.png | albedo | webp-lossy | RGBA8 | 4x4 | 0 | 1 | 144 | 64 |

### w4.mobile.pck: 38.9 MB pack; textures 171 files, 30.6 MB on disk, 383.6 MB in GPU memory

| Kind | Files | MB on disk | MB in GPU memory (web) |
|---|---|---|---|
| ui | 100 | 3.2 | 263.8 |
| albedo | 32 | 2.4 | 72.8 |
| lightmap | 1 | 3.1 | 25.2 |
| stand-in | 4 | 11.2 | 11.2 |
| cast | 34 | 10.6 | 10.6 |

| Stored as | Files | MB on disk | MB in GPU memory (web) |
|---|---|---|---|
| webp-lossless RGB8 | 26 | 3.0 | 320.2 |
| vram ASTC_4x4_HDR | 1 | 3.1 | 25.2 |
| vram ETC2_RGB8 | 27 | 17.8 | 17.8 |
| webp-lossless RGBA8 | 98 | 0.8 | 14.6 |
| vram ETC2_RGBA8 | 19 | 5.8 | 5.8 |

| Source | Kind | Stored | Format | Size | Mips | Layers | Bytes on disk | Bytes in GPU |
|---|---|---|---|---|---|---|---|---|
| tex/dir/hi/panel_1995.png | ui | webp-lossless | RGB8 | 4096x4580 | 12 | 1 | 752008 | 100049940 |
| tex/dir/hi/panel_2026.png | ui | webp-lossless | RGB8 | 4096x4580 | 12 | 1 | 937534 | 100049940 |
| wing4_day.exr | lightmap | image | ASTC_4x4_HDR | 1024x1024 | 0 | 3 | 3145812 | 25165824 |
| tex/dir/panel_1995.png | ui | webp-lossless | RGB8 | 2048x2290 | 11 | 1 | 342466 | 25011220 |
| tex/dir/panel_2026.png | ui | webp-lossless | RGB8 | 2048x2290 | 11 | 1 | 408600 | 25011220 |
| items/radioshack/tex/cordless_phone.png | albedo | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 19136 | 16777216 |
| items/radioshack/tex/rc_car_box.png | albedo | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 79420 | 16777216 |
| tex/standin/from_w1_day.png | stand-in | image | ETC2_RGB8 | 4096x2048 | 12 | 1 | 5592476 | 5592405 |
| tex/standin/from_w2_day.png | stand-in | image | ETC2_RGB8 | 4096x2048 | 12 | 1 | 5592476 | 5592405 |
| items/radioshack/tex/battery_card.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 16636 | 4194304 |
| items/radioshack/tex/cb_radio.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 16362 | 4194304 |
| addons/dialogue_manager/assets/logo.svg | ui | webp-lossless | RGBA8 | 1024x1024 | 0 | 1 | 49440 | 4194304 |
| items/radioshack/tex/microcassette.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 10798 | 4194304 |
| items/radioshack/tex/pager.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 12052 | 4194304 |
| items/radioshack/tex/scanner.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 20124 | 4194304 |
| tex/pc/video_marquees_blank.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 56112 | 4194304 |
| items/radioshack/tex/walkie_talkies.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 12382 | 4194304 |
| tex/cd7/troffer.png | albedo | webp-lossless | RGB8 | 600x1200 | 0 | 1 | 274 | 2880000 |
| tex/sr/carpet95.png | albedo | webp-lossless | RGB8 | 512x512 | 0 | 1 | 155320 | 1048576 |
| addons/dialogue_manager/assets/resource.svg | ui | webp-lossless | RGBA8 | 512x512 | 0 | 1 | 13392 | 1048576 |
| tex/sr/vct95.png | albedo | webp-lossless | RGB8 | 512x512 | 0 | 1 | 19532 | 1048576 |
| npc/skins/Ch01_0.png | cast | image | ETC2_RGBA8 | 768x768 | 9 | 1 | 786532 | 786430 |
| npc/skins/Ch12_0.png | cast | image | ETC2_RGBA8 | 768x768 | 9 | 1 | 786532 | 786430 |
| npc/skins/Ch28_0.png | cast | image | ETC2_RGBA8 | 768x768 | 9 | 1 | 786532 | 786430 |
| tex/sr/panel.png | albedo | webp-lossless | RGB8 | 256x512 | 0 | 1 | 38480 | 524288 |
| tex/items/it_die.png | ui | webp-lossless | RGB8 | 384x256 | 0 | 1 | 10654 | 393216 |
| tex/items/it_pog_card.png | ui | webp-lossless | RGB8 | 256x384 | 0 | 1 | 2214 | 393216 |
| npc/skins/Ch02_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch08_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch13_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch21_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch22_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch23_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch26_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch27_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch37_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch38_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch41_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch42_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Remy_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| tex/palm_frond.png | albedo | image | ETC2_RGBA8 | 256x1024 | 10 | 1 | 349636 | 349527 |
| tex/int_side.png | albedo | image | ETC2_RGB8 | 1024x512 | 10 | 1 | 349596 | 349525 |
| tex/poinsettia.png | albedo | image | ETC2_RGBA8 | 512x512 | 9 | 1 | 349604 | 349525 |
| tex/dir/back.png | ui | webp-lossless | RGB8 | 256x256 | 0 | 1 | 26040 | 262144 |
| items/radioshack/icons/battery_card.png | albedo | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 12204 | 262144 |
| items/radioshack/icons/cb_radio.png | albedo | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 9542 | 262144 |
| items/radioshack/icons/cordless_phone.png | albedo | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 12268 | 262144 |
| tex/kb/dept_blank.png | albedo | webp-lossless | RGB8 | 512x128 | 0 | 1 | 30414 | 262144 |
| items/radioshack/icons/microcassette.png | albedo | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 13718 | 262144 |
| items/radioshack/icons/pager.png | albedo | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 10640 | 262144 |
| tex/items/pc_claw_bruiser.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 17348 | 262144 |
| tex/items/pc_claw_comet.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 24656 | 262144 |
| tex/items/pc_claw_crawfish.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 10722 | 262144 |
| tex/items/pc_claw_gator.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 8960 | 262144 |
| tex/items/pc_claw_nutria.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 8880 | 262144 |
| tex/items/pc_claw_pelican.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 15710 | 262144 |
| tex/items/pc_claw_pogEye.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 16462 | 262144 |
| tex/items/pc_claw_pogGator.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 21136 | 262144 |
| tex/items/pc_claw_pogSkull.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 18510 | 262144 |
| tex/items/pc_claw_rougarou.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 18412 | 262144 |
| tex/items/pc_claw_slammer.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 30160 | 262144 |
| items/radioshack/icons/rc_car_box.png | albedo | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 25644 | 262144 |
| items/radioshack/icons/scanner.png | albedo | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 7096 | 262144 |
| items/radioshack/icons/walkie_talkies.png | albedo | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 7474 | 262144 |
| npc/skins/Ch02_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch08_2.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch13_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch21_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch22_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch23_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch26_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch27_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch37_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch38_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch41_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch42_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Remy_3.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Remy_5.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| tex/plaster.png | albedo | image | ETC2_RGB8 | 512x512 | 9 | 1 | 174828 | 174762 |
| tex/stone.png | albedo | image | ETC2_RGB8 | 512x512 | 9 | 1 | 174828 | 174762 |
| tex/wood_dark.png | albedo | image | ETC2_RGB8 | 512x512 | 9 | 1 | 174828 | 174762 |
| tex/kb/ceiling.png | albedo | webp-lossless | RGB8 | 128x256 | 0 | 1 | 14550 | 131072 |
| tex/kb/troffer.png | albedo | webp-lossless | RGB8 | 128x256 | 0 | 1 | 326 | 131072 |
| npc/skins/Ch08_1.png | cast | image | ETC2_RGB8 | 384x384 | 8 | 1 | 98380 | 98303 |
| npc/skins/Remy_1.png | cast | image | ETC2_RGB8 | 384x384 | 8 | 1 | 98380 | 98303 |
| npc/skins/Remy_2.png | cast | image | ETC2_RGB8 | 384x384 | 8 | 1 | 98380 | 98303 |
| npc/skins/Remy_4.png | cast | image | ETC2_RGB8 | 384x384 | 8 | 1 | 98380 | 98303 |
| tex/buff_tile.png | albedo | image | ETC2_RGB8 | 384x384 | 8 | 1 | 98380 | 98303 |
| tex/grey_tile.png | albedo | image | ETC2_RGB8 | 384x384 | 8 | 1 | 98380 | 98303 |
| addons/dialogue_manager/assets/update.svg | ui | webp-lossless | RGBA8 | 300x80 | 0 | 1 | 5340 | 96000 |
| tex/items/candy_neck.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7674 | 65536 |
| tex/items/dice.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 9836 | 65536 |
| tex/items/folse_stick.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 1630 | 65536 |
| tex/items/gi_arcade.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8266 | 65536 |
| tex/items/gi_blind_bag.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7194 | 65536 |
| tex/items/gi_bubbles.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 3996 | 65536 |
| tex/items/gi_cable.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5340 | 65536 |
| tex/items/gi_console.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 6826 | 65536 |
| tex/items/gi_earbuds.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4728 | 65536 |
| tex/items/gi_emoji_key.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7826 | 65536 |
| tex/items/gi_fidget.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5842 | 65536 |
| tex/items/gi_giftcard.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 3986 | 65536 |
| tex/items/gi_handheld.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8894 | 65536 |
| tex/items/gi_headphones.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8400 | 65536 |
| tex/items/gi_jumbo.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 9108 | 65536 |
| tex/items/gi_led_wand.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 3140 | 65536 |
| tex/items/gi_ledstrip.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8872 | 65536 |
| tex/items/gi_light_ring.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4662 | 65536 |
| tex/items/gi_phone_stand.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5930 | 65536 |
| tex/items/gi_play_ball.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8812 | 65536 |
| tex/items/gi_popper_board.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 12764 | 65536 |
| tex/items/gi_popper_key.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 10584 | 65536 |
| tex/items/gi_projector.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 9032 | 65536 |
| tex/items/gi_slime.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4566 | 65536 |
| tex/items/gi_speaker.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8356 | 65536 |
| tex/items/gi_squish_big.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8714 | 65536 |
| tex/items/gi_squishy.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 6306 | 65536 |
| tex/items/pc_alien.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7690 | 65536 |
| tex/items/pc_army_men.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8094 | 65536 |
| tex/items/pc_ball.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8816 | 65536 |
| tex/items/pc_big_bear.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 9518 | 65536 |
| tex/items/pc_big_dice.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5086 | 65536 |
| tex/items/pc_bounce_ball.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 6942 | 65536 |
| tex/items/pc_candy_cig.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4658 | 65536 |
| tex/items/pc_candy_ring.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 6156 | 65536 |
| tex/items/pc_candy_roll.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7588 | 65536 |
| tex/items/pc_cassette.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 10530 | 65536 |
| tex/items/pc_chew.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7948 | 65536 |
| tex/items/pc_eraser.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4264 | 65536 |
| tex/items/pc_glow_bracelet.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 6834 | 65536 |
| tex/items/pc_harmonica.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4880 | 65536 |
| tex/items/pc_jelly_bracelet.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7044 | 65536 |
| tex/items/pc_jelly_trap.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4798 | 65536 |
| tex/items/pc_lcd_game.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 9072 | 65536 |
| tex/items/pc_lollipop.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 2738 | 65536 |
| tex/items/pc_mood_ring.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4768 | 65536 |
| tex/items/pc_paddle_ball.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5216 | 65536 |
| tex/items/pc_pencil.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 3574 | 65536 |
| tex/items/pc_powder_straw.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 3608 | 65536 |
| tex/items/pc_rc_car.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 11782 | 65536 |
| tex/items/pc_rubber_snake.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 6154 | 65536 |
| tex/items/pc_slammer.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 920 | 65536 |
| tex/items/pc_sour_candy.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4724 | 65536 |
| tex/items/pc_spider_ring.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 3560 | 65536 |
| tex/items/pc_stickers.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7440 | 65536 |
| tex/items/pc_sticky_hand.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5404 | 65536 |
| tex/items/pc_sunglasses.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 6408 | 65536 |
| tex/items/pc_taffy.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5558 | 65536 |
| tex/items/pc_toy_car.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7670 | 65536 |
| tex/items/pc_vpet.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7950 | 65536 |
| tex/items/pc_walkie.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7800 | 65536 |
| tex/items/pc_water_pistol.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5392 | 65536 |
| tex/items/pogs.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 10278 | 65536 |
| tex/items/slap.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5130 | 65536 |
| tex/items/spring.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 16232 | 65536 |
| tex/items/it_rainbow.png | ui | webp-lossless | RGB8 | 32x256 | 0 | 1 | 196 | 32768 |
| tex/items/it_slap.png | ui | webp-lossless | RGB8 | 256x32 | 0 | 1 | 620 | 32768 |
| tex/standin/from_w1_night.png | stand-in | image | ETC2_RGB8 | 256x128 | 8 | 1 | 21916 | 21845 |
| tex/standin/from_w2_night.png | stand-in | image | ETC2_RGB8 | 256x128 | 8 | 1 | 21916 | 21845 |
| tex/items/it_candy.png | ui | webp-lossless | RGB8 | 256x16 | 0 | 1 | 172 | 16384 |
| tex/items/it_halo.png | ui | webp-lossless | RGBA8 | 64x64 | 0 | 1 | 820 | 16384 |
| addons/dialogue_manager/assets/cue.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 174 | 1024 |
| addons/dialogue_manager/nodes/actionable/dialogue_actionable_2d.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 318 | 1024 |
| addons/dialogue_manager/nodes/actionable/dialogue_actionable_3d.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 272 | 1024 |
| addons/dialogue_manager/nodes/dialogue_label/dialogue_label.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 350 | 1024 |
| addons/dialogue_manager/nodes/marker/dialogue_marker_2d.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 282 | 1024 |
| addons/dialogue_manager/nodes/marker/dialogue_marker_3d.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 262 | 1024 |
| addons/dialogue_manager/nodes/responses_menu/dialogue_responses_menu.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 224 | 1024 |
| addons/dialogue_manager/nodes/context/dialogue_state_context.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 320 | 1024 |
| addons/dialogue_manager/assets/icon.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 322 | 1024 |
| addons/dialogue_manager/assets/region.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 158 | 1024 |

### w5.mobile.pck: 39.8 MB pack; textures 172 files, 30.3 MB on disk, 380.2 MB in GPU memory

| Kind | Files | MB on disk | MB in GPU memory (web) |
|---|---|---|---|
| ui | 100 | 3.2 | 263.8 |
| albedo | 33 | 3.2 | 77.8 |
| lightmap | 1 | 2.1 | 16.8 |
| stand-in | 4 | 11.2 | 11.2 |
| cast | 34 | 10.6 | 10.6 |

| Stored as | Files | MB on disk | MB in GPU memory (web) |
|---|---|---|---|
| webp-lossless RGB8 | 28 | 3.8 | 325.2 |
| vram ETC2_RGB8 | 26 | 17.8 | 17.8 |
| vram ASTC_4x4_HDR | 1 | 2.1 | 16.8 |
| webp-lossless RGBA8 | 98 | 0.8 | 14.6 |
| vram ETC2_RGBA8 | 19 | 5.8 | 5.8 |

| Source | Kind | Stored | Format | Size | Mips | Layers | Bytes on disk | Bytes in GPU |
|---|---|---|---|---|---|---|---|---|
| tex/dir/hi/panel_1995.png | ui | webp-lossless | RGB8 | 4096x4580 | 12 | 1 | 752008 | 100049940 |
| tex/dir/hi/panel_2026.png | ui | webp-lossless | RGB8 | 4096x4580 | 12 | 1 | 937534 | 100049940 |
| tex/dir/panel_1995.png | ui | webp-lossless | RGB8 | 2048x2290 | 11 | 1 | 342466 | 25011220 |
| tex/dir/panel_2026.png | ui | webp-lossless | RGB8 | 2048x2290 | 11 | 1 | 408600 | 25011220 |
| items/radioshack/tex/cordless_phone.png | albedo | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 19136 | 16777216 |
| items/radioshack/tex/rc_car_box.png | albedo | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 79420 | 16777216 |
| wing5_day.exr | lightmap | image | ASTC_4x4_HDR | 1024x1024 | 0 | 2 | 2097220 | 16777216 |
| tex/standin/from_w1_day.png | stand-in | image | ETC2_RGB8 | 4096x2048 | 12 | 1 | 5592476 | 5592405 |
| tex/standin/from_w2_day.png | stand-in | image | ETC2_RGB8 | 4096x2048 | 12 | 1 | 5592476 | 5592405 |
| items/radioshack/tex/battery_card.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 16636 | 4194304 |
| items/radioshack/tex/cb_radio.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 16362 | 4194304 |
| addons/dialogue_manager/assets/logo.svg | ui | webp-lossless | RGBA8 | 1024x1024 | 0 | 1 | 49440 | 4194304 |
| items/radioshack/tex/microcassette.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 10798 | 4194304 |
| items/radioshack/tex/pager.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 12052 | 4194304 |
| items/radioshack/tex/scanner.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 20124 | 4194304 |
| tex/dl/trav.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 620362 | 4194304 |
| tex/pc/video_marquees_blank.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 56112 | 4194304 |
| items/radioshack/tex/walkie_talkies.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 12382 | 4194304 |
| tex/cd7/troffer.png | albedo | webp-lossless | RGB8 | 600x1200 | 0 | 1 | 274 | 2880000 |
| tex/dl/carpet.png | albedo | webp-lossless | RGB8 | 512x512 | 0 | 1 | 135300 | 1048576 |
| tex/dl/carpet95.png | albedo | webp-lossless | RGB8 | 512x512 | 0 | 1 | 139660 | 1048576 |
| addons/dialogue_manager/assets/resource.svg | ui | webp-lossless | RGBA8 | 512x512 | 0 | 1 | 13392 | 1048576 |
| tex/dl/vest.png | albedo | webp-lossless | RGB8 | 512x512 | 0 | 1 | 118282 | 1048576 |
| npc/skins/Ch01_0.png | cast | image | ETC2_RGBA8 | 768x768 | 9 | 1 | 786532 | 786430 |
| npc/skins/Ch12_0.png | cast | image | ETC2_RGBA8 | 768x768 | 9 | 1 | 786532 | 786430 |
| npc/skins/Ch28_0.png | cast | image | ETC2_RGBA8 | 768x768 | 9 | 1 | 786532 | 786430 |
| tex/items/it_die.png | ui | webp-lossless | RGB8 | 384x256 | 0 | 1 | 10654 | 393216 |
| tex/items/it_pog_card.png | ui | webp-lossless | RGB8 | 256x384 | 0 | 1 | 2214 | 393216 |
| npc/skins/Ch02_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch08_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch13_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch21_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch22_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch23_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch26_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch27_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch37_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch38_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch41_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch42_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Remy_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| tex/palm_frond.png | albedo | image | ETC2_RGBA8 | 256x1024 | 10 | 1 | 349636 | 349527 |
| tex/int_side.png | albedo | image | ETC2_RGB8 | 1024x512 | 10 | 1 | 349596 | 349525 |
| tex/poinsettia.png | albedo | image | ETC2_RGBA8 | 512x512 | 9 | 1 | 349604 | 349525 |
| tex/dir/back.png | ui | webp-lossless | RGB8 | 256x256 | 0 | 1 | 26040 | 262144 |
| items/radioshack/icons/battery_card.png | albedo | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 12204 | 262144 |
| items/radioshack/icons/cb_radio.png | albedo | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 9542 | 262144 |
| items/radioshack/icons/cordless_phone.png | albedo | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 12268 | 262144 |
| tex/kb/dept_blank.png | albedo | webp-lossless | RGB8 | 512x128 | 0 | 1 | 30414 | 262144 |
| tex/dl/granite.png | albedo | webp-lossless | RGB8 | 256x256 | 0 | 1 | 41528 | 262144 |
| items/radioshack/icons/microcassette.png | albedo | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 13718 | 262144 |
| items/radioshack/icons/pager.png | albedo | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 10640 | 262144 |
| tex/items/pc_claw_bruiser.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 17348 | 262144 |
| tex/items/pc_claw_comet.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 24656 | 262144 |
| tex/items/pc_claw_crawfish.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 10722 | 262144 |
| tex/items/pc_claw_gator.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 8960 | 262144 |
| tex/items/pc_claw_nutria.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 8880 | 262144 |
| tex/items/pc_claw_pelican.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 15710 | 262144 |
| tex/items/pc_claw_pogEye.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 16462 | 262144 |
| tex/items/pc_claw_pogGator.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 21136 | 262144 |
| tex/items/pc_claw_pogSkull.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 18510 | 262144 |
| tex/items/pc_claw_rougarou.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 18412 | 262144 |
| tex/items/pc_claw_slammer.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 30160 | 262144 |
| items/radioshack/icons/rc_car_box.png | albedo | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 25644 | 262144 |
| items/radioshack/icons/scanner.png | albedo | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 7096 | 262144 |
| items/radioshack/icons/walkie_talkies.png | albedo | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 7474 | 262144 |
| npc/skins/Ch02_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch08_2.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch13_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch21_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch22_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch23_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch26_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch27_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch37_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch38_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch41_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch42_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Remy_3.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Remy_5.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| tex/brown_stone.png | albedo | image | ETC2_RGB8 | 512x512 | 9 | 1 | 174828 | 174762 |
| tex/plaster.png | albedo | image | ETC2_RGB8 | 512x512 | 9 | 1 | 174828 | 174762 |
| tex/stone.png | albedo | image | ETC2_RGB8 | 512x512 | 9 | 1 | 174828 | 174762 |
| tex/wood_dark.png | albedo | image | ETC2_RGB8 | 512x512 | 9 | 1 | 174828 | 174762 |
| tex/kb/ceiling.png | albedo | webp-lossless | RGB8 | 128x256 | 0 | 1 | 14550 | 131072 |
| tex/kb/troffer.png | albedo | webp-lossless | RGB8 | 128x256 | 0 | 1 | 326 | 131072 |
| npc/skins/Ch08_1.png | cast | image | ETC2_RGB8 | 384x384 | 8 | 1 | 98380 | 98303 |
| npc/skins/Remy_1.png | cast | image | ETC2_RGB8 | 384x384 | 8 | 1 | 98380 | 98303 |
| npc/skins/Remy_2.png | cast | image | ETC2_RGB8 | 384x384 | 8 | 1 | 98380 | 98303 |
| npc/skins/Remy_4.png | cast | image | ETC2_RGB8 | 384x384 | 8 | 1 | 98380 | 98303 |
| addons/dialogue_manager/assets/update.svg | ui | webp-lossless | RGBA8 | 300x80 | 0 | 1 | 5340 | 96000 |
| tex/items/candy_neck.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7674 | 65536 |
| tex/items/dice.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 9836 | 65536 |
| tex/items/folse_stick.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 1630 | 65536 |
| tex/items/gi_arcade.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8266 | 65536 |
| tex/items/gi_blind_bag.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7194 | 65536 |
| tex/items/gi_bubbles.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 3996 | 65536 |
| tex/items/gi_cable.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5340 | 65536 |
| tex/items/gi_console.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 6826 | 65536 |
| tex/items/gi_earbuds.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4728 | 65536 |
| tex/items/gi_emoji_key.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7826 | 65536 |
| tex/items/gi_fidget.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5842 | 65536 |
| tex/items/gi_giftcard.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 3986 | 65536 |
| tex/items/gi_handheld.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8894 | 65536 |
| tex/items/gi_headphones.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8400 | 65536 |
| tex/items/gi_jumbo.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 9108 | 65536 |
| tex/items/gi_led_wand.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 3140 | 65536 |
| tex/items/gi_ledstrip.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8872 | 65536 |
| tex/items/gi_light_ring.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4662 | 65536 |
| tex/items/gi_phone_stand.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5930 | 65536 |
| tex/items/gi_play_ball.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8812 | 65536 |
| tex/items/gi_popper_board.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 12764 | 65536 |
| tex/items/gi_popper_key.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 10584 | 65536 |
| tex/items/gi_projector.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 9032 | 65536 |
| tex/items/gi_slime.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4566 | 65536 |
| tex/items/gi_speaker.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8356 | 65536 |
| tex/items/gi_squish_big.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8714 | 65536 |
| tex/items/gi_squishy.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 6306 | 65536 |
| tex/items/pc_alien.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7690 | 65536 |
| tex/items/pc_army_men.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8094 | 65536 |
| tex/items/pc_ball.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8816 | 65536 |
| tex/items/pc_big_bear.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 9518 | 65536 |
| tex/items/pc_big_dice.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5086 | 65536 |
| tex/items/pc_bounce_ball.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 6942 | 65536 |
| tex/items/pc_candy_cig.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4658 | 65536 |
| tex/items/pc_candy_ring.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 6156 | 65536 |
| tex/items/pc_candy_roll.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7588 | 65536 |
| tex/items/pc_cassette.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 10530 | 65536 |
| tex/items/pc_chew.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7948 | 65536 |
| tex/items/pc_eraser.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4264 | 65536 |
| tex/items/pc_glow_bracelet.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 6834 | 65536 |
| tex/items/pc_harmonica.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4880 | 65536 |
| tex/items/pc_jelly_bracelet.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7044 | 65536 |
| tex/items/pc_jelly_trap.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4798 | 65536 |
| tex/items/pc_lcd_game.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 9072 | 65536 |
| tex/items/pc_lollipop.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 2738 | 65536 |
| tex/items/pc_mood_ring.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4768 | 65536 |
| tex/items/pc_paddle_ball.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5216 | 65536 |
| tex/items/pc_pencil.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 3574 | 65536 |
| tex/items/pc_powder_straw.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 3608 | 65536 |
| tex/items/pc_rc_car.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 11782 | 65536 |
| tex/items/pc_rubber_snake.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 6154 | 65536 |
| tex/items/pc_slammer.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 920 | 65536 |
| tex/items/pc_sour_candy.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4724 | 65536 |
| tex/items/pc_spider_ring.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 3560 | 65536 |
| tex/items/pc_stickers.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7440 | 65536 |
| tex/items/pc_sticky_hand.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5404 | 65536 |
| tex/items/pc_sunglasses.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 6408 | 65536 |
| tex/items/pc_taffy.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5558 | 65536 |
| tex/items/pc_toy_car.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7670 | 65536 |
| tex/items/pc_vpet.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7950 | 65536 |
| tex/items/pc_walkie.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7800 | 65536 |
| tex/items/pc_water_pistol.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5392 | 65536 |
| tex/items/pogs.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 10278 | 65536 |
| tex/items/slap.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5130 | 65536 |
| tex/items/spring.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 16232 | 65536 |
| tex/items/it_rainbow.png | ui | webp-lossless | RGB8 | 32x256 | 0 | 1 | 196 | 32768 |
| tex/items/it_slap.png | ui | webp-lossless | RGB8 | 256x32 | 0 | 1 | 620 | 32768 |
| tex/standin/from_w1_night.png | stand-in | image | ETC2_RGB8 | 256x128 | 8 | 1 | 21916 | 21845 |
| tex/standin/from_w2_night.png | stand-in | image | ETC2_RGB8 | 256x128 | 8 | 1 | 21916 | 21845 |
| tex/items/it_candy.png | ui | webp-lossless | RGB8 | 256x16 | 0 | 1 | 172 | 16384 |
| tex/items/it_halo.png | ui | webp-lossless | RGBA8 | 64x64 | 0 | 1 | 820 | 16384 |
| addons/dialogue_manager/assets/cue.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 174 | 1024 |
| addons/dialogue_manager/nodes/actionable/dialogue_actionable_2d.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 318 | 1024 |
| addons/dialogue_manager/nodes/actionable/dialogue_actionable_3d.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 272 | 1024 |
| addons/dialogue_manager/nodes/dialogue_label/dialogue_label.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 350 | 1024 |
| addons/dialogue_manager/nodes/marker/dialogue_marker_2d.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 282 | 1024 |
| addons/dialogue_manager/nodes/marker/dialogue_marker_3d.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 262 | 1024 |
| addons/dialogue_manager/nodes/responses_menu/dialogue_responses_menu.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 224 | 1024 |
| addons/dialogue_manager/nodes/context/dialogue_state_context.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 320 | 1024 |
| addons/dialogue_manager/assets/icon.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 322 | 1024 |
| addons/dialogue_manager/assets/region.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 158 | 1024 |

### w6.mobile.pck: 20.6 MB pack; textures 154 files, 14.5 MB on disk, 340.3 MB in GPU memory

| Kind | Files | MB on disk | MB in GPU memory (web) |
|---|---|---|---|
| ui | 100 | 3.2 | 263.8 |
| albedo | 20 | 0.7 | 65.9 |
| cast | 34 | 10.6 | 10.6 |

| Stored as | Files | MB on disk | MB in GPU memory (web) |
|---|---|---|---|
| webp-lossless RGB8 | 21 | 2.8 | 314.7 |
| webp-lossless RGBA8 | 98 | 0.8 | 14.6 |
| vram ETC2_RGB8 | 18 | 5.9 | 5.9 |
| vram ETC2_RGBA8 | 17 | 5.1 | 5.1 |

| Source | Kind | Stored | Format | Size | Mips | Layers | Bytes on disk | Bytes in GPU |
|---|---|---|---|---|---|---|---|---|
| tex/dir/hi/panel_1995.png | ui | webp-lossless | RGB8 | 4096x4580 | 12 | 1 | 752008 | 100049940 |
| tex/dir/hi/panel_2026.png | ui | webp-lossless | RGB8 | 4096x4580 | 12 | 1 | 937534 | 100049940 |
| tex/dir/panel_1995.png | ui | webp-lossless | RGB8 | 2048x2290 | 11 | 1 | 342466 | 25011220 |
| tex/dir/panel_2026.png | ui | webp-lossless | RGB8 | 2048x2290 | 11 | 1 | 408600 | 25011220 |
| items/radioshack/tex/cordless_phone.png | albedo | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 19136 | 16777216 |
| items/radioshack/tex/rc_car_box.png | albedo | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 79420 | 16777216 |
| items/radioshack/tex/battery_card.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 16636 | 4194304 |
| items/radioshack/tex/cb_radio.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 16362 | 4194304 |
| addons/dialogue_manager/assets/logo.svg | ui | webp-lossless | RGBA8 | 1024x1024 | 0 | 1 | 49440 | 4194304 |
| items/radioshack/tex/microcassette.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 10798 | 4194304 |
| items/radioshack/tex/pager.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 12052 | 4194304 |
| items/radioshack/tex/scanner.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 20124 | 4194304 |
| tex/pc/video_marquees_blank.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 56112 | 4194304 |
| items/radioshack/tex/walkie_talkies.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 12382 | 4194304 |
| addons/dialogue_manager/assets/resource.svg | ui | webp-lossless | RGBA8 | 512x512 | 0 | 1 | 13392 | 1048576 |
| npc/skins/Ch01_0.png | cast | image | ETC2_RGBA8 | 768x768 | 9 | 1 | 786532 | 786430 |
| npc/skins/Ch12_0.png | cast | image | ETC2_RGBA8 | 768x768 | 9 | 1 | 786532 | 786430 |
| npc/skins/Ch28_0.png | cast | image | ETC2_RGBA8 | 768x768 | 9 | 1 | 786532 | 786430 |
| tex/items/it_die.png | ui | webp-lossless | RGB8 | 384x256 | 0 | 1 | 10654 | 393216 |
| tex/items/it_pog_card.png | ui | webp-lossless | RGB8 | 256x384 | 0 | 1 | 2214 | 393216 |
| npc/skins/Ch02_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch08_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch13_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch21_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch22_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch23_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch26_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch27_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch37_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch38_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch41_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch42_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Remy_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| tex/int_side.png | albedo | image | ETC2_RGB8 | 1024x512 | 10 | 1 | 349596 | 349525 |
| tex/dir/back.png | ui | webp-lossless | RGB8 | 256x256 | 0 | 1 | 26040 | 262144 |
| items/radioshack/icons/battery_card.png | albedo | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 12204 | 262144 |
| tex/cin/carpet.png | albedo | webp-lossless | RGB8 | 256x256 | 0 | 1 | 428 | 262144 |
| items/radioshack/icons/cb_radio.png | albedo | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 9542 | 262144 |
| items/radioshack/icons/cordless_phone.png | albedo | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 12268 | 262144 |
| tex/kb/dept_blank.png | albedo | webp-lossless | RGB8 | 512x128 | 0 | 1 | 30414 | 262144 |
| items/radioshack/icons/microcassette.png | albedo | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 13718 | 262144 |
| items/radioshack/icons/pager.png | albedo | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 10640 | 262144 |
| tex/items/pc_claw_bruiser.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 17348 | 262144 |
| tex/items/pc_claw_comet.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 24656 | 262144 |
| tex/items/pc_claw_crawfish.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 10722 | 262144 |
| tex/items/pc_claw_gator.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 8960 | 262144 |
| tex/items/pc_claw_nutria.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 8880 | 262144 |
| tex/items/pc_claw_pelican.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 15710 | 262144 |
| tex/items/pc_claw_pogEye.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 16462 | 262144 |
| tex/items/pc_claw_pogGator.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 21136 | 262144 |
| tex/items/pc_claw_pogSkull.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 18510 | 262144 |
| tex/items/pc_claw_rougarou.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 18412 | 262144 |
| tex/items/pc_claw_slammer.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 30160 | 262144 |
| items/radioshack/icons/rc_car_box.png | albedo | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 25644 | 262144 |
| items/radioshack/icons/scanner.png | albedo | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 7096 | 262144 |
| items/radioshack/icons/walkie_talkies.png | albedo | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 7474 | 262144 |
| npc/skins/Ch02_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch08_2.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch13_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch21_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch22_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch23_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch26_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch27_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch37_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch38_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch41_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch42_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Remy_3.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Remy_5.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch08_1.png | cast | image | ETC2_RGB8 | 384x384 | 8 | 1 | 98380 | 98303 |
| npc/skins/Remy_1.png | cast | image | ETC2_RGB8 | 384x384 | 8 | 1 | 98380 | 98303 |
| npc/skins/Remy_2.png | cast | image | ETC2_RGB8 | 384x384 | 8 | 1 | 98380 | 98303 |
| npc/skins/Remy_4.png | cast | image | ETC2_RGB8 | 384x384 | 8 | 1 | 98380 | 98303 |
| addons/dialogue_manager/assets/update.svg | ui | webp-lossless | RGBA8 | 300x80 | 0 | 1 | 5340 | 96000 |
| tex/items/candy_neck.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7674 | 65536 |
| tex/items/dice.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 9836 | 65536 |
| tex/items/folse_stick.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 1630 | 65536 |
| tex/items/gi_arcade.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8266 | 65536 |
| tex/items/gi_blind_bag.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7194 | 65536 |
| tex/items/gi_bubbles.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 3996 | 65536 |
| tex/items/gi_cable.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5340 | 65536 |
| tex/items/gi_console.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 6826 | 65536 |
| tex/items/gi_earbuds.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4728 | 65536 |
| tex/items/gi_emoji_key.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7826 | 65536 |
| tex/items/gi_fidget.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5842 | 65536 |
| tex/items/gi_giftcard.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 3986 | 65536 |
| tex/items/gi_handheld.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8894 | 65536 |
| tex/items/gi_headphones.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8400 | 65536 |
| tex/items/gi_jumbo.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 9108 | 65536 |
| tex/items/gi_led_wand.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 3140 | 65536 |
| tex/items/gi_ledstrip.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8872 | 65536 |
| tex/items/gi_light_ring.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4662 | 65536 |
| tex/items/gi_phone_stand.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5930 | 65536 |
| tex/items/gi_play_ball.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8812 | 65536 |
| tex/items/gi_popper_board.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 12764 | 65536 |
| tex/items/gi_popper_key.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 10584 | 65536 |
| tex/items/gi_projector.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 9032 | 65536 |
| tex/items/gi_slime.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4566 | 65536 |
| tex/items/gi_speaker.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8356 | 65536 |
| tex/items/gi_squish_big.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8714 | 65536 |
| tex/items/gi_squishy.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 6306 | 65536 |
| tex/items/pc_alien.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7690 | 65536 |
| tex/items/pc_army_men.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8094 | 65536 |
| tex/items/pc_ball.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8816 | 65536 |
| tex/items/pc_big_bear.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 9518 | 65536 |
| tex/items/pc_big_dice.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5086 | 65536 |
| tex/items/pc_bounce_ball.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 6942 | 65536 |
| tex/items/pc_candy_cig.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4658 | 65536 |
| tex/items/pc_candy_ring.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 6156 | 65536 |
| tex/items/pc_candy_roll.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7588 | 65536 |
| tex/items/pc_cassette.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 10530 | 65536 |
| tex/items/pc_chew.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7948 | 65536 |
| tex/items/pc_eraser.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4264 | 65536 |
| tex/items/pc_glow_bracelet.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 6834 | 65536 |
| tex/items/pc_harmonica.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4880 | 65536 |
| tex/items/pc_jelly_bracelet.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7044 | 65536 |
| tex/items/pc_jelly_trap.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4798 | 65536 |
| tex/items/pc_lcd_game.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 9072 | 65536 |
| tex/items/pc_lollipop.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 2738 | 65536 |
| tex/items/pc_mood_ring.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4768 | 65536 |
| tex/items/pc_paddle_ball.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5216 | 65536 |
| tex/items/pc_pencil.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 3574 | 65536 |
| tex/items/pc_powder_straw.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 3608 | 65536 |
| tex/items/pc_rc_car.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 11782 | 65536 |
| tex/items/pc_rubber_snake.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 6154 | 65536 |
| tex/items/pc_slammer.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 920 | 65536 |
| tex/items/pc_sour_candy.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4724 | 65536 |
| tex/items/pc_spider_ring.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 3560 | 65536 |
| tex/items/pc_stickers.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7440 | 65536 |
| tex/items/pc_sticky_hand.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5404 | 65536 |
| tex/items/pc_sunglasses.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 6408 | 65536 |
| tex/items/pc_taffy.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5558 | 65536 |
| tex/items/pc_toy_car.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7670 | 65536 |
| tex/items/pc_vpet.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7950 | 65536 |
| tex/items/pc_walkie.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7800 | 65536 |
| tex/items/pc_water_pistol.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5392 | 65536 |
| tex/items/pogs.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 10278 | 65536 |
| tex/items/slap.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5130 | 65536 |
| tex/items/spring.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 16232 | 65536 |
| tex/items/it_rainbow.png | ui | webp-lossless | RGB8 | 32x256 | 0 | 1 | 196 | 32768 |
| tex/items/it_slap.png | ui | webp-lossless | RGB8 | 256x32 | 0 | 1 | 620 | 32768 |
| tex/items/it_candy.png | ui | webp-lossless | RGB8 | 256x16 | 0 | 1 | 172 | 16384 |
| tex/items/it_halo.png | ui | webp-lossless | RGBA8 | 64x64 | 0 | 1 | 820 | 16384 |
| addons/dialogue_manager/assets/cue.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 174 | 1024 |
| addons/dialogue_manager/nodes/actionable/dialogue_actionable_2d.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 318 | 1024 |
| addons/dialogue_manager/nodes/actionable/dialogue_actionable_3d.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 272 | 1024 |
| addons/dialogue_manager/nodes/dialogue_label/dialogue_label.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 350 | 1024 |
| addons/dialogue_manager/nodes/marker/dialogue_marker_2d.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 282 | 1024 |
| addons/dialogue_manager/nodes/marker/dialogue_marker_3d.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 262 | 1024 |
| addons/dialogue_manager/nodes/responses_menu/dialogue_responses_menu.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 224 | 1024 |
| addons/dialogue_manager/nodes/context/dialogue_state_context.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 320 | 1024 |
| addons/dialogue_manager/assets/icon.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 322 | 1024 |
| addons/dialogue_manager/assets/region.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 158 | 1024 |

### w1y26.mobile.pck: 48.2 MB pack; textures 172 files, 35.2 MB on disk, 410.8 MB in GPU memory

| Kind | Files | MB on disk | MB in GPU memory (web) |
|---|---|---|---|
| ui | 100 | 3.2 | 263.8 |
| lightmap | 1 | 8.4 | 67.1 |
| stand-in | 5 | 5.5 | 40.8 |
| albedo | 32 | 7.5 | 28.5 |
| cast | 34 | 10.6 | 10.6 |

| Stored as | Files | MB on disk | MB in GPU memory (web) |
|---|---|---|---|
| webp-lossless RGB8 | 35 | 9.5 | 313.7 |
| vram ASTC_4x4_HDR | 1 | 8.4 | 67.1 |
| webp-lossless RGBA8 | 93 | 0.9 | 13.6 |
| vram ETC2_RGB8 | 23 | 10.2 | 10.2 |
| vram ETC2_RGBA8 | 20 | 6.2 | 6.2 |

| Source | Kind | Stored | Format | Size | Mips | Layers | Bytes on disk | Bytes in GPU |
|---|---|---|---|---|---|---|---|---|
| tex/dir/hi/panel_1995.png | ui | webp-lossless | RGB8 | 4096x4580 | 12 | 1 | 752008 | 100049940 |
| tex/dir/hi/panel_2026.png | ui | webp-lossless | RGB8 | 4096x4580 | 12 | 1 | 937534 | 100049940 |
| wing1_2026_day.exr | lightmap | image | ASTC_4x4_HDR | 2048x2048 | 0 | 2 | 8388676 | 67108864 |
| tex/standin/y26_from_w2_day.png | stand-in | webp-lossless | RGB8 | 4096x2048 | 0 | 1 | 2954690 | 33554432 |
| tex/dir/panel_1995.png | ui | webp-lossless | RGB8 | 2048x2290 | 11 | 1 | 342466 | 25011220 |
| tex/dir/panel_2026.png | ui | webp-lossless | RGB8 | 2048x2290 | 11 | 1 | 408600 | 25011220 |
| tex/standin/y26_from_w4_day.png | stand-in | webp-lossless | RGB8 | 3072x435 | 0 | 1 | 767044 | 5345280 |
| addons/dialogue_manager/assets/logo.svg | ui | webp-lossless | RGBA8 | 1024x1024 | 0 | 1 | 49440 | 4194304 |
| tex/ap/racks.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 412360 | 4194304 |
| tex/pc/video_marquees_blank.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 56112 | 4194304 |
| tex/f26/accessories.png | albedo | webp-lossless | RGB8 | 768x768 | 0 | 1 | 814052 | 2359296 |
| tex/f26/posters.png | albedo | webp-lossless | RGB8 | 1024x512 | 0 | 1 | 688284 | 2097152 |
| tex/int_atlas.png | albedo | image | ETC2_RGB8 | 2048x1536 | 11 | 1 | 2097228 | 2097151 |
| tex/standin/y26_door_w1_day.png | stand-in | image | ETC2_RGB8 | 1152x2304 | 11 | 1 | 1769620 | 1769468 |
| tex/sg/y26/lease_card.png | albedo | webp-lossless | RGB8 | 448x800 | 0 | 1 | 5752 | 1433600 |
| tex/sg/y26/claires_name_face.png | albedo | webp-lossless | RGB8 | 1024x317 | 0 | 1 | 70116 | 1298432 |
| addons/dialogue_manager/assets/resource.svg | ui | webp-lossless | RGBA8 | 512x512 | 0 | 1 | 13392 | 1048576 |
| tex/f26/tees.png | albedo | webp-lossless | RGB8 | 1024x256 | 0 | 1 | 351108 | 1048576 |
| tex/sg/y26/rainbow_name_face.png | albedo | webp-lossless | RGB8 | 1024x255 | 0 | 1 | 56880 | 1044480 |
| tex/sg/y26/gnc_name_face.png | albedo | webp-lossless | RGB8 | 1024x242 | 0 | 1 | 49472 | 991232 |
| tex/sg/y26/gnc_tag_face.png | albedo | webp-lossless | RGB8 | 1024x240 | 0 | 1 | 54418 | 983040 |
| tex/f26/jewelry.png | albedo | webp-lossless | RGB8 | 768x320 | 0 | 1 | 277122 | 983040 |
| npc/skins/Ch01_0.png | cast | image | ETC2_RGBA8 | 768x768 | 9 | 1 | 786532 | 786430 |
| npc/skins/Ch12_0.png | cast | image | ETC2_RGBA8 | 768x768 | 9 | 1 | 786532 | 786430 |
| npc/skins/Ch28_0.png | cast | image | ETC2_RGBA8 | 768x768 | 9 | 1 | 786532 | 786430 |
| tex/sg/y26/aero_name_face.png | albedo | webp-lossless | RGB8 | 1024x182 | 0 | 1 | 41740 | 745472 |
| tex/f26/banners.png | albedo | webp-lossless | RGB8 | 512x256 | 0 | 1 | 175356 | 524288 |
| tex/sg/y26/shoedept_encore_glow.png | albedo | webp-lossless | RGBA8 | 512x200 | 0 | 1 | 58510 | 409600 |
| tex/items/it_die.png | ui | webp-lossless | RGB8 | 384x256 | 0 | 1 | 10654 | 393216 |
| tex/items/it_pog_card.png | ui | webp-lossless | RGB8 | 256x384 | 0 | 1 | 2214 | 393216 |
| npc/skins/Ch02_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch08_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch13_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch21_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch22_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch23_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch26_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch27_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch37_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch38_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch41_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch42_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Remy_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| tex/palm_frond.png | albedo | image | ETC2_RGBA8 | 256x1024 | 10 | 1 | 349636 | 349527 |
| tex/int_side.png | albedo | image | ETC2_RGB8 | 1024x512 | 10 | 1 | 349596 | 349525 |
| tex/leafy.png | albedo | image | ETC2_RGBA8 | 512x512 | 9 | 1 | 349604 | 349525 |
| tex/poinsettia.png | albedo | image | ETC2_RGBA8 | 512x512 | 9 | 1 | 349604 | 349525 |
| tex/sg/y26/shoedept_shoe_glow.png | albedo | webp-lossless | RGBA8 | 512x160 | 0 | 1 | 45354 | 327680 |
| tex/sg/y26/zales_name_glow.png | albedo | webp-lossless | RGBA8 | 512x150 | 0 | 1 | 43304 | 307200 |
| tex/dir/back.png | ui | webp-lossless | RGB8 | 256x256 | 0 | 1 | 26040 | 262144 |
| tex/f26/beadboard.png | albedo | webp-lossless | RGB8 | 256x256 | 0 | 1 | 75950 | 262144 |
| tex/f26/crumple.png | albedo | webp-lossless | RGB8 | 256x256 | 0 | 1 | 30372 | 262144 |
| tex/kb/dept_blank.png | albedo | webp-lossless | RGB8 | 512x128 | 0 | 1 | 30414 | 262144 |
| tex/items/pc_claw_bruiser.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 17348 | 262144 |
| tex/items/pc_claw_comet.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 24656 | 262144 |
| tex/items/pc_claw_crawfish.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 10722 | 262144 |
| tex/items/pc_claw_gator.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 8960 | 262144 |
| tex/items/pc_claw_nutria.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 8880 | 262144 |
| tex/items/pc_claw_pelican.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 15710 | 262144 |
| tex/items/pc_claw_pogEye.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 16462 | 262144 |
| tex/items/pc_claw_pogGator.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 21136 | 262144 |
| tex/items/pc_claw_pogSkull.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 18510 | 262144 |
| tex/items/pc_claw_rougarou.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 18412 | 262144 |
| tex/items/pc_claw_slammer.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 30160 | 262144 |
| tex/f26/travertine.png | albedo | webp-lossless | RGB8 | 256x256 | 0 | 1 | 66114 | 262144 |
| npc/skins/Ch02_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch08_2.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch13_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch21_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch22_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch23_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch26_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch27_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch37_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch38_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch41_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch42_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Remy_3.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Remy_5.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| tex/plaster.png | albedo | image | ETC2_RGB8 | 512x512 | 9 | 1 | 174828 | 174762 |
| tex/stone.png | albedo | image | ETC2_RGB8 | 512x512 | 9 | 1 | 174828 | 174762 |
| tex/wood_dark.png | albedo | image | ETC2_RGB8 | 512x512 | 9 | 1 | 174828 | 174762 |
| tex/kb/ceiling.png | albedo | webp-lossless | RGB8 | 128x256 | 0 | 1 | 14550 | 131072 |
| tex/sg/y26/gnc_rule_face.png | albedo | webp-lossless | RGB8 | 1024x32 | 0 | 1 | 6924 | 131072 |
| tex/kb/troffer.png | albedo | webp-lossless | RGB8 | 128x256 | 0 | 1 | 326 | 131072 |
| tex/standin/y26_from_w2_night.png | stand-in | webp-lossless | RGB8 | 256x128 | 0 | 1 | 35766 | 131072 |
| npc/skins/Ch08_1.png | cast | image | ETC2_RGB8 | 384x384 | 8 | 1 | 98380 | 98303 |
| npc/skins/Remy_1.png | cast | image | ETC2_RGB8 | 384x384 | 8 | 1 | 98380 | 98303 |
| npc/skins/Remy_2.png | cast | image | ETC2_RGB8 | 384x384 | 8 | 1 | 98380 | 98303 |
| npc/skins/Remy_4.png | cast | image | ETC2_RGB8 | 384x384 | 8 | 1 | 98380 | 98303 |
| addons/dialogue_manager/assets/update.svg | ui | webp-lossless | RGBA8 | 300x80 | 0 | 1 | 5340 | 96000 |
| tex/items/candy_neck.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7674 | 65536 |
| tex/items/dice.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 9836 | 65536 |
| tex/f26/felt.png | albedo | webp-lossless | RGB8 | 128x128 | 0 | 1 | 16758 | 65536 |
| tex/items/folse_stick.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 1630 | 65536 |
| tex/items/gi_arcade.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8266 | 65536 |
| tex/items/gi_blind_bag.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7194 | 65536 |
| tex/items/gi_bubbles.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 3996 | 65536 |
| tex/items/gi_cable.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5340 | 65536 |
| tex/items/gi_console.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 6826 | 65536 |
| tex/items/gi_earbuds.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4728 | 65536 |
| tex/items/gi_emoji_key.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7826 | 65536 |
| tex/items/gi_fidget.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5842 | 65536 |
| tex/items/gi_giftcard.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 3986 | 65536 |
| tex/items/gi_handheld.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8894 | 65536 |
| tex/items/gi_headphones.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8400 | 65536 |
| tex/items/gi_jumbo.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 9108 | 65536 |
| tex/items/gi_led_wand.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 3140 | 65536 |
| tex/items/gi_ledstrip.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8872 | 65536 |
| tex/items/gi_light_ring.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4662 | 65536 |
| tex/items/gi_phone_stand.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5930 | 65536 |
| tex/items/gi_play_ball.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8812 | 65536 |
| tex/items/gi_popper_board.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 12764 | 65536 |
| tex/items/gi_popper_key.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 10584 | 65536 |
| tex/items/gi_projector.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 9032 | 65536 |
| tex/items/gi_slime.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4566 | 65536 |
| tex/items/gi_speaker.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8356 | 65536 |
| tex/items/gi_squish_big.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8714 | 65536 |
| tex/items/gi_squishy.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 6306 | 65536 |
| tex/items/pc_alien.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7690 | 65536 |
| tex/items/pc_army_men.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8094 | 65536 |
| tex/items/pc_ball.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8816 | 65536 |
| tex/items/pc_big_bear.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 9518 | 65536 |
| tex/items/pc_big_dice.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5086 | 65536 |
| tex/items/pc_bounce_ball.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 6942 | 65536 |
| tex/items/pc_candy_cig.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4658 | 65536 |
| tex/items/pc_candy_ring.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 6156 | 65536 |
| tex/items/pc_candy_roll.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7588 | 65536 |
| tex/items/pc_cassette.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 10530 | 65536 |
| tex/items/pc_chew.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7948 | 65536 |
| tex/items/pc_eraser.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4264 | 65536 |
| tex/items/pc_glow_bracelet.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 6834 | 65536 |
| tex/items/pc_harmonica.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4880 | 65536 |
| tex/items/pc_jelly_bracelet.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7044 | 65536 |
| tex/items/pc_jelly_trap.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4798 | 65536 |
| tex/items/pc_lcd_game.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 9072 | 65536 |
| tex/items/pc_lollipop.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 2738 | 65536 |
| tex/items/pc_mood_ring.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4768 | 65536 |
| tex/items/pc_paddle_ball.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5216 | 65536 |
| tex/items/pc_pencil.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 3574 | 65536 |
| tex/items/pc_powder_straw.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 3608 | 65536 |
| tex/items/pc_rc_car.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 11782 | 65536 |
| tex/items/pc_rubber_snake.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 6154 | 65536 |
| tex/items/pc_slammer.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 920 | 65536 |
| tex/items/pc_sour_candy.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4724 | 65536 |
| tex/items/pc_spider_ring.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 3560 | 65536 |
| tex/items/pc_stickers.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7440 | 65536 |
| tex/items/pc_sticky_hand.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5404 | 65536 |
| tex/items/pc_sunglasses.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 6408 | 65536 |
| tex/items/pc_taffy.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5558 | 65536 |
| tex/items/pc_toy_car.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7670 | 65536 |
| tex/items/pc_vpet.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7950 | 65536 |
| tex/items/pc_walkie.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7800 | 65536 |
| tex/items/pc_water_pistol.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5392 | 65536 |
| tex/items/pogs.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 10278 | 65536 |
| tex/items/slap.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5130 | 65536 |
| tex/items/spring.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 16232 | 65536 |
| tex/standin/y26_from_w4_night.png | stand-in | webp-lossless | RGB8 | 256x36 | 0 | 1 | 10708 | 36864 |
| tex/items/it_rainbow.png | ui | webp-lossless | RGB8 | 32x256 | 0 | 1 | 196 | 32768 |
| tex/items/it_slap.png | ui | webp-lossless | RGB8 | 256x32 | 0 | 1 | 620 | 32768 |
| tex/items/it_candy.png | ui | webp-lossless | RGB8 | 256x16 | 0 | 1 | 172 | 16384 |
| tex/items/it_halo.png | ui | webp-lossless | RGBA8 | 64x64 | 0 | 1 | 820 | 16384 |
| addons/dialogue_manager/assets/cue.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 174 | 1024 |
| addons/dialogue_manager/nodes/actionable/dialogue_actionable_2d.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 318 | 1024 |
| addons/dialogue_manager/nodes/actionable/dialogue_actionable_3d.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 272 | 1024 |
| addons/dialogue_manager/nodes/dialogue_label/dialogue_label.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 350 | 1024 |
| addons/dialogue_manager/nodes/marker/dialogue_marker_2d.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 282 | 1024 |
| addons/dialogue_manager/nodes/marker/dialogue_marker_3d.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 262 | 1024 |
| addons/dialogue_manager/nodes/responses_menu/dialogue_responses_menu.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 224 | 1024 |
| addons/dialogue_manager/nodes/context/dialogue_state_context.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 320 | 1024 |
| addons/dialogue_manager/assets/icon.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 322 | 1024 |
| addons/dialogue_manager/assets/region.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 158 | 1024 |

### w2y26.mobile.pck: 79.2 MB pack; textures 287 files, 53.5 MB on disk, 642.7 MB in GPU memory

| Kind | Files | MB on disk | MB in GPU memory (web) |
|---|---|---|---|
| albedo | 147 | 27.5 | 263.9 |
| ui | 100 | 3.2 | 263.8 |
| lightmap | 1 | 8.4 | 67.1 |
| stand-in | 5 | 3.8 | 37.3 |
| cast | 34 | 10.6 | 10.6 |

| Stored as | Files | MB on disk | MB in GPU memory (web) |
|---|---|---|---|
| webp-lossless RGB8 | 136 | 27.4 | 541.6 |
| vram ASTC_4x4_HDR | 1 | 8.4 | 67.1 |
| webp-lossless RGBA8 | 102 | 1.2 | 17.6 |
| vram ETC2_RGB8 | 28 | 10.3 | 10.3 |
| vram ETC2_RGBA8 | 20 | 6.2 | 6.2 |

| Source | Kind | Stored | Format | Size | Mips | Layers | Bytes on disk | Bytes in GPU |
|---|---|---|---|---|---|---|---|---|
| tex/dir/hi/panel_1995.png | ui | webp-lossless | RGB8 | 4096x4580 | 12 | 1 | 752008 | 100049940 |
| tex/dir/hi/panel_2026.png | ui | webp-lossless | RGB8 | 4096x4580 | 12 | 1 | 937534 | 100049940 |
| wing2_2026_day.exr | lightmap | image | ASTC_4x4_HDR | 2048x2048 | 0 | 2 | 8388676 | 67108864 |
| tex/standin/y26_from_w1_day.png | stand-in | webp-lossless | RGB8 | 4096x2048 | 0 | 1 | 2417322 | 33554432 |
| tex/dir/panel_1995.png | ui | webp-lossless | RGB8 | 2048x2290 | 11 | 1 | 342466 | 25011220 |
| tex/dir/panel_2026.png | ui | webp-lossless | RGB8 | 2048x2290 | 11 | 1 | 408600 | 25011220 |
| tex/cd7/awning.png | albedo | webp-lossless | RGB8 | 3313x974 | 0 | 1 | 43052 | 12907448 |
| tex/sg/y26/gac_i_face.png | albedo | webp-lossless | RGB8 | 1024x2608 | 0 | 1 | 442712 | 10682368 |
| tex/sg/y26/cellxpert_screen_face.png | albedo | webp-lossless | RGB8 | 1024x2605 | 0 | 1 | 446946 | 10670080 |
| tex/sg/y26/cellxpert_icon_face.png | albedo | webp-lossless | RGB8 | 1024x2042 | 0 | 1 | 349278 | 8364032 |
| tex/sg/y26/cellxpert_x_face.png | albedo | webp-lossless | RGB8 | 1024x1613 | 0 | 1 | 283380 | 6606848 |
| tex/sg/y26/gac_e_face.png | albedo | webp-lossless | RGB8 | 1024x1348 | 0 | 1 | 230946 | 5521408 |
| tex/cd7/wall_yellow.png | albedo | webp-lossless | RGB8 | 1160x1160 | 0 | 1 | 218470 | 5382400 |
| tex/sg/y26/gac_c_face.png | albedo | webp-lossless | RGB8 | 1024x1252 | 0 | 1 | 220198 | 5128192 |
| tex/sg/y26/gac_s_face.png | albedo | webp-lossless | RGB8 | 1024x1234 | 0 | 1 | 218074 | 5054464 |
| tex/sg/y26/gac_k_face.png | albedo | webp-lossless | RGB8 | 1024x1139 | 0 | 1 | 196900 | 4665344 |
| tex/spencers/tee_rail.png | albedo | webp-lossless | RGB8 | 1024x1110 | 0 | 1 | 1532242 | 4546560 |
| tex/sg/y26/gac_o1_face.png | albedo | webp-lossless | RGB8 | 1024x1059 | 0 | 1 | 187058 | 4337664 |
| tex/sg/y26/gac_o2_face.png | albedo | webp-lossless | RGB8 | 1024x1059 | 0 | 1 | 187058 | 4337664 |
| tex/sg/y26/att_globe_face.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 191750 | 4194304 |
| tex/spencers/corrugated.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 1437234 | 4194304 |
| addons/dialogue_manager/assets/logo.svg | ui | webp-lossless | RGBA8 | 1024x1024 | 0 | 1 | 49440 | 4194304 |
| tex/ap/racks.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 412360 | 4194304 |
| tex/spencers/tee_grid.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 1399014 | 4194304 |
| tex/pc/video_marquees_blank.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 56112 | 4194304 |
| tex/gi/ww_field.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 196460 | 4194304 |
| tex/sg/y26/auntie_pretzel_face.png | albedo | webp-lossless | RGB8 | 1024x1012 | 0 | 1 | 192142 | 4145152 |
| tex/cd7/counter_front.png | albedo | webp-lossless | RGB8 | 1000x1000 | 0 | 1 | 1492 | 4000000 |
| tex/sg/y26/boost_mark_face.png | albedo | webp-lossless | RGB8 | 1024x904 | 0 | 1 | 161102 | 3702784 |
| tex/cd7/ceiling.png | albedo | webp-lossless | RGB8 | 960x960 | 0 | 1 | 550110 | 3686400 |
| tex/cd7/menu.png | albedo | webp-lossless | RGB8 | 1280x720 | 0 | 1 | 35408 | 3686400 |
| tex/sg/y26/cellxpert_cell_face.png | albedo | webp-lossless | RGB8 | 1024x811 | 0 | 1 | 158272 | 3321856 |
| tex/sg/y26/lids_name_face.png | albedo | webp-lossless | RGB8 | 1024x776 | 0 | 1 | 153162 | 3178496 |
| tex/gac/menu.png | albedo | webp-lossless | RGB8 | 1536x512 | 0 | 1 | 4888 | 3145728 |
| tex/cd7/troffer.png | albedo | webp-lossless | RGB8 | 600x1200 | 0 | 1 | 274 | 2880000 |
| tex/sg/y26/cellxpert_pert_face.png | albedo | webp-lossless | RGB8 | 1024x679 | 0 | 1 | 130862 | 2781184 |
| tex/ww/counter_tile.png | albedo | webp-lossless | RGB8 | 960x720 | 0 | 1 | 918704 | 2764800 |
| tex/standin/y26_from_w5_day.png | stand-in | webp-lossless | RGB8 | 1536x435 | 0 | 1 | 407148 | 2672640 |
| tex/f26/caps.png | albedo | webp-lossless | RGB8 | 1024x640 | 0 | 1 | 870180 | 2621440 |
| tex/gi/ww_decal.png | albedo | webp-lossless | RGB8 | 1024x640 | 0 | 1 | 40542 | 2621440 |
| tex/cd7/floor.png | albedo | webp-lossless | RGB8 | 800x800 | 0 | 1 | 9018 | 2560000 |
| tex/cd7/oak_slats.png | albedo | webp-lossless | RGB8 | 800x800 | 0 | 1 | 2152 | 2560000 |
| tex/cd7/tile_navy.png | albedo | webp-lossless | RGB8 | 800x800 | 0 | 1 | 1736 | 2560000 |
| tex/sg/y26/journeys_name_face.png | albedo | webp-lossless | RGB8 | 1024x582 | 0 | 1 | 121384 | 2383872 |
| tex/aa/front.png | albedo | webp-lossless | RGB8 | 1024x580 | 0 | 1 | 582778 | 2375680 |
| tex/gi/m_alley.png | albedo | webp-lossless | RGB8 | 1024x512 | 0 | 1 | 16082 | 2097152 |
| tex/gi/m_claw.png | albedo | webp-lossless | RGB8 | 1024x512 | 0 | 1 | 38158 | 2097152 |
| tex/gi/m_counter.png | albedo | webp-lossless | RGB8 | 1024x512 | 0 | 1 | 19942 | 2097152 |
| tex/gi/m_deal.png | albedo | webp-lossless | RGB8 | 1024x512 | 0 | 1 | 16438 | 2097152 |
| tex/gi/m_dice.png | albedo | webp-lossless | RGB8 | 1024x512 | 0 | 1 | 10436 | 2097152 |
| tex/gi/m_dome.png | albedo | webp-lossless | RGB8 | 1024x512 | 0 | 1 | 57068 | 2097152 |
| tex/gi/m_gunbig.png | albedo | webp-lossless | RGB8 | 1024x512 | 0 | 1 | 14950 | 2097152 |
| tex/gi/m_hockey.png | albedo | webp-lossless | RGB8 | 1024x512 | 0 | 1 | 7584 | 2097152 |
| tex/gi/m_hoop.png | albedo | webp-lossless | RGB8 | 1024x512 | 0 | 1 | 16670 | 2097152 |
| tex/gi/m_merch.png | albedo | webp-lossless | RGB8 | 1024x512 | 0 | 1 | 62620 | 2097152 |
| tex/gi/m_ptower.png | albedo | webp-lossless | RGB8 | 1024x512 | 0 | 1 | 9476 | 2097152 |
| tex/gi/m_pusher.png | albedo | webp-lossless | RGB8 | 1024x512 | 0 | 1 | 64668 | 2097152 |
| tex/gi/m_racer.png | albedo | webp-lossless | RGB8 | 1024x512 | 0 | 1 | 4188 | 2097152 |
| tex/gi/m_room.png | albedo | webp-lossless | RGB8 | 1024x512 | 0 | 1 | 35080 | 2097152 |
| tex/gi/m_upright.png | albedo | webp-lossless | RGB8 | 1024x512 | 0 | 1 | 32678 | 2097152 |
| tex/gi/m_wheel.png | albedo | webp-lossless | RGB8 | 1024x512 | 0 | 1 | 19558 | 2097152 |
| tex/f26/posters.png | albedo | webp-lossless | RGB8 | 1024x512 | 0 | 1 | 688284 | 2097152 |
| tex/int_atlas.png | albedo | image | ETC2_RGB8 | 2048x1536 | 11 | 1 | 2097228 | 2097151 |
| tex/f26/bottles.png | albedo | webp-lossless | RGB8 | 768x640 | 0 | 1 | 647644 | 1966080 |
| tex/cm/posters.png | albedo | webp-lossless | RGB8 | 1200x400 | 0 | 1 | 659306 | 1920000 |
| tex/ww/guard.png | albedo | webp-lossless | RGB8 | 2048x220 | 0 | 1 | 32776 | 1802240 |
| tex/aa/screens.png | albedo | webp-lossless | RGB8 | 1536x288 | 0 | 1 | 447750 | 1769472 |
| tex/ww/menu.png | albedo | webp-lossless | RGB8 | 2000x220 | 0 | 1 | 610820 | 1760000 |
| tex/gi/ww_front.png | albedo | webp-lossless | RGB8 | 768x482 | 0 | 1 | 46218 | 1480704 |
| tex/cd7/butcher.png | albedo | webp-lossless | RGB8 | 600x600 | 0 | 1 | 1318 | 1440000 |
| tex/sg/y26/lease_card.png | albedo | webp-lossless | RGB8 | 448x800 | 0 | 1 | 5752 | 1433600 |
| tex/aa/geo.png | albedo | webp-lossless | RGB8 | 1024x340 | 0 | 1 | 398142 | 1392640 |
| tex/sg/y26/att_name_face.png | albedo | webp-lossless | RGB8 | 1024x334 | 0 | 1 | 70000 | 1368064 |
| tex/f26/menus.png | albedo | webp-lossless | RGB8 | 1024x320 | 0 | 1 | 405610 | 1310720 |
| tex/cfa/prints.png | albedo | webp-lossless | RGB8 | 1024x320 | 0 | 1 | 8924 | 1310720 |
| tex/sg/y26/vs_s_glow.png | albedo | webp-lossless | RGBA8 | 512x604 | 0 | 1 | 77504 | 1236992 |
| tex/sg/y26/boost_boost_face.png | albedo | webp-lossless | RGB8 | 1024x296 | 0 | 1 | 62810 | 1212416 |
| tex/gi/ww_console.png | albedo | webp-lossless | RGB8 | 1024x288 | 0 | 1 | 58602 | 1179648 |
| tex/sg/y26/pink_face_face.png | albedo | webp-lossless | RGB8 | 1024x277 | 0 | 1 | 58206 | 1134592 |
| tex/gi/ww_deck.png | albedo | webp-lossless | RGB8 | 512x528 | 0 | 1 | 35588 | 1081344 |
| tex/sg/y26/boost_mobile_face.png | albedo | webp-lossless | RGB8 | 1024x262 | 0 | 1 | 58800 | 1073152 |
| tex/spencers/concrete.png | albedo | webp-lossless | RGB8 | 512x512 | 0 | 1 | 388480 | 1048576 |
| tex/gac/cookies.png | albedo | webp-lossless | RGB8 | 1024x256 | 0 | 1 | 408480 | 1048576 |
| tex/ww/floor.png | albedo | webp-lossless | RGB8 | 512x512 | 0 | 1 | 391512 | 1048576 |
| addons/dialogue_manager/assets/resource.svg | ui | webp-lossless | RGBA8 | 512x512 | 0 | 1 | 13392 | 1048576 |
| tex/aa/rolltop.png | albedo | webp-lossless | RGB8 | 1024x256 | 0 | 1 | 313114 | 1048576 |
| tex/cd7/steel.png | albedo | webp-lossless | RGB8 | 512x512 | 0 | 1 | 1046 | 1048576 |
| tex/aa/subway.png | albedo | webp-lossless | RGB8 | 512x512 | 0 | 1 | 276324 | 1048576 |
| tex/gac/wave.png | albedo | webp-lossless | RGB8 | 512x512 | 0 | 1 | 254910 | 1048576 |
| tex/sg/y26/jcp_name_face.png | albedo | webp-lossless | RGB8 | 1024x241 | 0 | 1 | 53848 | 987136 |
| tex/f26/cakes.png | albedo | webp-lossless | RGB8 | 768x320 | 0 | 1 | 325284 | 983040 |
| tex/sg/y26/auntie_auntie_face.png | albedo | webp-lossless | RGB8 | 1024x239 | 0 | 1 | 52020 | 978944 |
| tex/sg/y26/vs_v_glow.png | albedo | webp-lossless | RGBA8 | 512x469 | 0 | 1 | 48806 | 960512 |
| tex/sg/y26/auntie_annes_face.png | albedo | webp-lossless | RGB8 | 1024x230 | 0 | 1 | 51548 | 942080 |
| tex/standin/y26_door_w2_day.png | stand-in | image | ETC2_RGB8 | 1152x1152 | 10 | 1 | 884868 | 884733 |
| tex/gi/ww_side.png | albedo | webp-lossless | RGB8 | 512x420 | 0 | 1 | 47084 | 860160 |
| tex/cm/menu.png | albedo | webp-lossless | RGB8 | 400x520 | 0 | 1 | 257028 | 832000 |
| tex/sg/y26/dillards_name_face.png | albedo | webp-lossless | RGB8 | 1024x199 | 0 | 1 | 43352 | 815104 |
| tex/gac/cake_top.png | albedo | webp-lossless | RGB8 | 512x384 | 0 | 1 | 279952 | 786432 |
| npc/skins/Ch01_0.png | cast | image | ETC2_RGBA8 | 768x768 | 9 | 1 | 786532 | 786430 |
| npc/skins/Ch12_0.png | cast | image | ETC2_RGBA8 | 768x768 | 9 | 1 | 786532 | 786430 |
| npc/skins/Ch28_0.png | cast | image | ETC2_RGBA8 | 768x768 | 9 | 1 | 786532 | 786430 |
| tex/gac/dip.png | albedo | webp-lossless | RGB8 | 512x360 | 0 | 1 | 1342 | 737280 |
| tex/f26/brick.png | albedo | webp-lossless | RGB8 | 512x341 | 0 | 1 | 241540 | 698368 |
| tex/cm/mahogany.png | albedo | webp-lossless | RGB8 | 512x340 | 0 | 1 | 222972 | 696320 |
| tex/sg/y26/journeys_name_glow.png | albedo | webp-lossless | RGBA8 | 512x312 | 0 | 1 | 79900 | 638976 |
| tex/sg/y26/footlocker_name_face.png | albedo | webp-lossless | RGB8 | 1024x128 | 0 | 1 | 31190 | 524288 |
| tex/aa/oak.png | albedo | webp-lossless | RGB8 | 512x256 | 0 | 1 | 177984 | 524288 |
| tex/f26/planks.png | albedo | webp-lossless | RGB8 | 512x256 | 0 | 1 | 207118 | 524288 |
| tex/gac/slush.png | albedo | webp-lossless | RGB8 | 512x256 | 0 | 1 | 2408 | 524288 |
| tex/ww/aframe.png | albedo | webp-lossless | RGB8 | 300x420 | 0 | 1 | 170276 | 504000 |
| tex/sg/y26/bbw_name_face.png | albedo | webp-lossless | RGB8 | 1024x118 | 0 | 1 | 35130 | 483328 |
| tex/f26/shutter.png | albedo | webp-lossless | RGB8 | 512x224 | 0 | 1 | 180836 | 458752 |
| tex/items/it_die.png | ui | webp-lossless | RGB8 | 384x256 | 0 | 1 | 10654 | 393216 |
| tex/items/it_pog_card.png | ui | webp-lossless | RGB8 | 256x384 | 0 | 1 | 2214 | 393216 |
| npc/skins/Ch02_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch08_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch13_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch21_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch22_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch23_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch26_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch27_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch37_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch38_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch41_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch42_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Remy_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| tex/gi/plank.png | albedo | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| tex/palm_frond.png | albedo | image | ETC2_RGBA8 | 256x1024 | 10 | 1 | 349636 | 349527 |
| tex/int_side.png | albedo | image | ETC2_RGB8 | 1024x512 | 10 | 1 | 349596 | 349525 |
| tex/leafy.png | albedo | image | ETC2_RGBA8 | 512x512 | 9 | 1 | 349604 | 349525 |
| tex/poinsettia.png | albedo | image | ETC2_RGBA8 | 512x512 | 9 | 1 | 349604 | 349525 |
| tex/spencers/folded.png | albedo | webp-lossless | RGB8 | 512x170 | 0 | 1 | 117664 | 348160 |
| tex/sg/y26/pink_face_glow.png | albedo | webp-lossless | RGBA8 | 512x169 | 0 | 1 | 48098 | 346112 |
| tex/sg/y26/auntie_auntie_glow.png | albedo | webp-lossless | RGBA8 | 512x160 | 0 | 1 | 38156 | 327680 |
| tex/gac/rgb.png | albedo | webp-lossless | RGB8 | 512x160 | 0 | 1 | 27150 | 327680 |
| tex/sg/y26/auntie_annes_glow.png | albedo | webp-lossless | RGBA8 | 512x156 | 0 | 1 | 37282 | 319488 |
| tex/sg/y26/gac_great_face.png | albedo | webp-lossless | RGB8 | 1024x77 | 0 | 1 | 20304 | 315392 |
| tex/sg/y26/jcp_name_glow.png | albedo | webp-lossless | RGBA8 | 512x140 | 0 | 1 | 38234 | 286720 |
| tex/sg/y26/vs_ecret_glow.png | albedo | webp-lossless | RGBA8 | 512x134 | 0 | 1 | 38202 | 274432 |
| tex/dir/back.png | ui | webp-lossless | RGB8 | 256x256 | 0 | 1 | 26040 | 262144 |
| tex/f26/concrete.png | albedo | webp-lossless | RGB8 | 256x256 | 0 | 1 | 48376 | 262144 |
| tex/kb/dept_blank.png | albedo | webp-lossless | RGB8 | 512x128 | 0 | 1 | 30414 | 262144 |
| tex/f26/gingham.png | albedo | webp-lossless | RGB8 | 256x256 | 0 | 1 | 85612 | 262144 |
| tex/cm/gold.png | albedo | webp-lossless | RGB8 | 256x256 | 0 | 1 | 44206 | 262144 |
| tex/cfa/labels.png | albedo | webp-lossless | RGB8 | 512x128 | 0 | 1 | 2840 | 262144 |
| tex/items/pc_claw_bruiser.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 17348 | 262144 |
| tex/items/pc_claw_comet.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 24656 | 262144 |
| tex/items/pc_claw_crawfish.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 10722 | 262144 |
| tex/items/pc_claw_gator.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 8960 | 262144 |
| tex/items/pc_claw_nutria.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 8880 | 262144 |
| tex/items/pc_claw_pelican.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 15710 | 262144 |
| tex/items/pc_claw_pogEye.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 16462 | 262144 |
| tex/items/pc_claw_pogGator.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 21136 | 262144 |
| tex/items/pc_claw_pogSkull.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 18510 | 262144 |
| tex/items/pc_claw_rougarou.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 18412 | 262144 |
| tex/items/pc_claw_slammer.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 30160 | 262144 |
| tex/spencers/strip.png | albedo | webp-lossless | RGB8 | 1024x64 | 0 | 1 | 1774 | 262144 |
| tex/f26/travertine.png | albedo | webp-lossless | RGB8 | 256x256 | 0 | 1 | 66114 | 262144 |
| tex/ww/wall.png | albedo | webp-lossless | RGB8 | 256x256 | 0 | 1 | 83088 | 262144 |
| tex/cm/white_tile.png | albedo | webp-lossless | RGB8 | 256x256 | 0 | 1 | 95572 | 262144 |
| tex/gi/ww_dome.png | albedo | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 17594 | 262144 |
| tex/gi/ww_yellow.png | albedo | webp-lossless | RGB8 | 256x256 | 0 | 1 | 5996 | 262144 |
| tex/aa/sign_rolling.png | albedo | webp-lossless | RGB8 | 512x96 | 0 | 1 | 1720 | 196608 |
| npc/skins/Ch02_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch08_2.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch13_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch21_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch22_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch23_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch26_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch27_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch37_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch38_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch41_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch42_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Remy_3.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Remy_5.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| tex/sg/y26/vs_ictorias_glow.png | albedo | webp-lossless | RGBA8 | 512x95 | 0 | 1 | 33392 | 194560 |
| tex/gi/ww_bonus.png | albedo | webp-lossless | RGB8 | 256x176 | 0 | 1 | 2876 | 180224 |
| tex/sg/y26/bbw_name_glow.png | albedo | webp-lossless | RGBA8 | 512x86 | 0 | 1 | 33550 | 176128 |
| tex/brown_stone.png | albedo | image | ETC2_RGB8 | 512x512 | 9 | 1 | 174828 | 174762 |
| tex/plaster.png | albedo | image | ETC2_RGB8 | 512x512 | 9 | 1 | 174828 | 174762 |
| tex/stone.png | albedo | image | ETC2_RGB8 | 512x512 | 9 | 1 | 174828 | 174762 |
| tex/gi/tile.png | albedo | image | ETC2_RGB8 | 512x512 | 9 | 1 | 174828 | 174762 |
| tex/wood_dark.png | albedo | image | ETC2_RGB8 | 512x512 | 9 | 1 | 174828 | 174762 |
| tex/wood_diag.png | albedo | image | ETC2_RGB8 | 512x512 | 9 | 1 | 174828 | 174762 |
| tex/kb/ceiling.png | albedo | webp-lossless | RGB8 | 128x256 | 0 | 1 | 14550 | 131072 |
| tex/cm/checker.png | albedo | webp-lossless | RGB8 | 256x128 | 0 | 1 | 49524 | 131072 |
| tex/md/screens.png | albedo | webp-lossless | RGB8 | 256x128 | 0 | 1 | 850 | 131072 |
| tex/kb/troffer.png | albedo | webp-lossless | RGB8 | 128x256 | 0 | 1 | 326 | 131072 |
| tex/gi/ww_led.png | albedo | webp-lossless | RGB8 | 256x128 | 0 | 1 | 3130 | 131072 |
| tex/gi/ww_tower.png | albedo | webp-lossless | RGB8 | 256x128 | 0 | 1 | 4026 | 131072 |
| tex/standin/y26_from_w1_night.png | stand-in | webp-lossless | RGB8 | 256x128 | 0 | 1 | 30876 | 131072 |
| npc/skins/Ch08_1.png | cast | image | ETC2_RGB8 | 384x384 | 8 | 1 | 98380 | 98303 |
| npc/skins/Remy_1.png | cast | image | ETC2_RGB8 | 384x384 | 8 | 1 | 98380 | 98303 |
| npc/skins/Remy_2.png | cast | image | ETC2_RGB8 | 384x384 | 8 | 1 | 98380 | 98303 |
| npc/skins/Remy_4.png | cast | image | ETC2_RGB8 | 384x384 | 8 | 1 | 98380 | 98303 |
| addons/dialogue_manager/assets/update.svg | ui | webp-lossless | RGBA8 | 300x80 | 0 | 1 | 5340 | 96000 |
| tex/gi/ww_coin.png | albedo | webp-lossless | RGB8 | 128x160 | 0 | 1 | 5766 | 81920 |
| tex/standin/y26_from_w5_night.png | stand-in | webp-lossless | RGB8 | 256x73 | 0 | 1 | 20890 | 74752 |
| tex/items/candy_neck.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7674 | 65536 |
| tex/items/dice.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 9836 | 65536 |
| tex/items/folse_stick.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 1630 | 65536 |
| tex/items/gi_arcade.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8266 | 65536 |
| tex/items/gi_blind_bag.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7194 | 65536 |
| tex/items/gi_bubbles.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 3996 | 65536 |
| tex/items/gi_cable.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5340 | 65536 |
| tex/items/gi_console.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 6826 | 65536 |
| tex/items/gi_earbuds.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4728 | 65536 |
| tex/items/gi_emoji_key.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7826 | 65536 |
| tex/items/gi_fidget.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5842 | 65536 |
| tex/items/gi_giftcard.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 3986 | 65536 |
| tex/items/gi_handheld.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8894 | 65536 |
| tex/items/gi_headphones.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8400 | 65536 |
| tex/items/gi_jumbo.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 9108 | 65536 |
| tex/items/gi_led_wand.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 3140 | 65536 |
| tex/items/gi_ledstrip.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8872 | 65536 |
| tex/items/gi_light_ring.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4662 | 65536 |
| tex/items/gi_phone_stand.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5930 | 65536 |
| tex/items/gi_play_ball.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8812 | 65536 |
| tex/items/gi_popper_board.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 12764 | 65536 |
| tex/items/gi_popper_key.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 10584 | 65536 |
| tex/items/gi_projector.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 9032 | 65536 |
| tex/items/gi_slime.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4566 | 65536 |
| tex/items/gi_speaker.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8356 | 65536 |
| tex/items/gi_squish_big.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8714 | 65536 |
| tex/items/gi_squishy.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 6306 | 65536 |
| tex/items/pc_alien.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7690 | 65536 |
| tex/items/pc_army_men.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8094 | 65536 |
| tex/items/pc_ball.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8816 | 65536 |
| tex/items/pc_big_bear.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 9518 | 65536 |
| tex/items/pc_big_dice.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5086 | 65536 |
| tex/items/pc_bounce_ball.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 6942 | 65536 |
| tex/items/pc_candy_cig.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4658 | 65536 |
| tex/items/pc_candy_ring.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 6156 | 65536 |
| tex/items/pc_candy_roll.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7588 | 65536 |
| tex/items/pc_cassette.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 10530 | 65536 |
| tex/items/pc_chew.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7948 | 65536 |
| tex/items/pc_eraser.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4264 | 65536 |
| tex/items/pc_glow_bracelet.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 6834 | 65536 |
| tex/items/pc_harmonica.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4880 | 65536 |
| tex/items/pc_jelly_bracelet.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7044 | 65536 |
| tex/items/pc_jelly_trap.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4798 | 65536 |
| tex/items/pc_lcd_game.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 9072 | 65536 |
| tex/items/pc_lollipop.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 2738 | 65536 |
| tex/items/pc_mood_ring.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4768 | 65536 |
| tex/items/pc_paddle_ball.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5216 | 65536 |
| tex/items/pc_pencil.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 3574 | 65536 |
| tex/items/pc_powder_straw.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 3608 | 65536 |
| tex/items/pc_rc_car.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 11782 | 65536 |
| tex/items/pc_rubber_snake.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 6154 | 65536 |
| tex/items/pc_slammer.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 920 | 65536 |
| tex/items/pc_sour_candy.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4724 | 65536 |
| tex/items/pc_spider_ring.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 3560 | 65536 |
| tex/items/pc_stickers.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7440 | 65536 |
| tex/items/pc_sticky_hand.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5404 | 65536 |
| tex/items/pc_sunglasses.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 6408 | 65536 |
| tex/items/pc_taffy.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5558 | 65536 |
| tex/items/pc_toy_car.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7670 | 65536 |
| tex/items/pc_vpet.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7950 | 65536 |
| tex/items/pc_walkie.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7800 | 65536 |
| tex/items/pc_water_pistol.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5392 | 65536 |
| tex/items/pogs.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 10278 | 65536 |
| tex/items/slap.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5130 | 65536 |
| tex/gi/slatwall.png | albedo | webp-lossless | RGB8 | 64x256 | 0 | 1 | 154 | 65536 |
| tex/items/spring.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 16232 | 65536 |
| tex/gi/ww_button.png | albedo | webp-lossless | RGB8 | 128x128 | 0 | 1 | 3758 | 65536 |
| tex/gi/panel.png | albedo | image | ETC2_RGB8 | 256x256 | 8 | 1 | 43756 | 43690 |
| tex/items/it_rainbow.png | ui | webp-lossless | RGB8 | 32x256 | 0 | 1 | 196 | 32768 |
| tex/items/it_slap.png | ui | webp-lossless | RGB8 | 256x32 | 0 | 1 | 620 | 32768 |
| tex/f26/ref.png | albedo | webp-lossless | RGB8 | 128x64 | 0 | 1 | 120 | 32768 |
| tex/gi/ww_slot.png | albedo | webp-lossless | RGB8 | 128x64 | 0 | 1 | 1134 | 32768 |
| tex/gi/ww_ticket.png | albedo | webp-lossless | RGBA8 | 64x128 | 0 | 1 | 822 | 32768 |
| tex/items/it_candy.png | ui | webp-lossless | RGB8 | 256x16 | 0 | 1 | 172 | 16384 |
| tex/items/it_halo.png | ui | webp-lossless | RGBA8 | 64x64 | 0 | 1 | 820 | 16384 |
| addons/dialogue_manager/assets/cue.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 174 | 1024 |
| addons/dialogue_manager/nodes/actionable/dialogue_actionable_2d.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 318 | 1024 |
| addons/dialogue_manager/nodes/actionable/dialogue_actionable_3d.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 272 | 1024 |
| addons/dialogue_manager/nodes/dialogue_label/dialogue_label.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 350 | 1024 |
| addons/dialogue_manager/nodes/marker/dialogue_marker_2d.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 282 | 1024 |
| addons/dialogue_manager/nodes/marker/dialogue_marker_3d.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 262 | 1024 |
| addons/dialogue_manager/nodes/responses_menu/dialogue_responses_menu.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 224 | 1024 |
| addons/dialogue_manager/nodes/context/dialogue_state_context.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 320 | 1024 |
| addons/dialogue_manager/assets/icon.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 322 | 1024 |
| addons/dialogue_manager/assets/region.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 158 | 1024 |

### w4y26.mobile.pck: 92.3 MB pack; textures 232 files, 75.9 MB on disk, 997.5 MB in GPU memory

| Kind | Files | MB on disk | MB in GPU memory (web) |
|---|---|---|---|
| albedo | 73 | 36.2 | 446.0 |
| ui | 100 | 3.2 | 263.8 |
| normal | 20 | 17.3 | 184.5 |
| stand-in | 4 | 5.4 | 67.4 |
| lightmap | 1 | 3.1 | 25.2 |
| cast | 34 | 10.6 | 10.6 |

| Stored as | Files | MB on disk | MB in GPU memory (web) |
|---|---|---|---|
| webp-lossless RGB8 | 93 | 59.7 | 945.5 |
| vram ASTC_4x4_HDR | 1 | 3.1 | 25.2 |
| webp-lossless RGBA8 | 98 | 0.8 | 14.6 |
| vram ETC2_RGB8 | 21 | 6.4 | 6.4 |
| vram ETC2_RGBA8 | 19 | 5.8 | 5.8 |

| Source | Kind | Stored | Format | Size | Mips | Layers | Bytes on disk | Bytes in GPU |
|---|---|---|---|---|---|---|---|---|
| tex/dir/hi/panel_1995.png | ui | webp-lossless | RGB8 | 4096x4580 | 12 | 1 | 752008 | 100049940 |
| tex/dir/hi/panel_2026.png | ui | webp-lossless | RGB8 | 4096x4580 | 12 | 1 | 937534 | 100049940 |
| tex/standin/y26_from_w1_day.png | stand-in | webp-lossless | RGB8 | 4096x2048 | 0 | 1 | 2417322 | 33554432 |
| tex/standin/y26_from_w2_day.png | stand-in | webp-lossless | RGB8 | 4096x2048 | 0 | 1 | 2954690 | 33554432 |
| wing4_2026_day.exr | lightmap | image | ASTC_4x4_HDR | 1024x1024 | 0 | 3 | 3145812 | 25165824 |
| tex/dir/panel_1995.png | ui | webp-lossless | RGB8 | 2048x2290 | 11 | 1 | 342466 | 25011220 |
| tex/dir/panel_2026.png | ui | webp-lossless | RGB8 | 2048x2290 | 11 | 1 | 408600 | 25011220 |
| models/lynns/bl_ly_bed_espresso/bl_ly_bed_espresso_albedo.png | albedo | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 2555242 | 16777216 |
| models/lynns/bl_ly_bed_espresso/bl_ly_bed_espresso_normal.png | normal | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 1369862 | 16777216 |
| models/lynns/bl_ly_bed_espresso/bl_ly_bed_espresso_orm.png | albedo | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 640374 | 16777216 |
| models/lynns/bl_ly_bed_glam/bl_ly_bed_glam_albedo.png | albedo | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 2458102 | 16777216 |
| models/lynns/bl_ly_bed_glam/bl_ly_bed_glam_normal.png | normal | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 1744898 | 16777216 |
| models/lynns/bl_ly_bed_glam/bl_ly_bed_glam_orm.png | albedo | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 571906 | 16777216 |
| models/lynns/bl_ly_bed_oak/bl_ly_bed_oak_albedo.png | albedo | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 2171440 | 16777216 |
| models/lynns/bl_ly_bed_oak/bl_ly_bed_oak_normal.png | normal | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 1295480 | 16777216 |
| models/lynns/bl_ly_bed_oak/bl_ly_bed_oak_orm.png | albedo | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 592260 | 16777216 |
| models/lynns/bl_ly_bed_sage/bl_ly_bed_sage_albedo.png | albedo | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 2336722 | 16777216 |
| models/lynns/bl_ly_bed_sage/bl_ly_bed_sage_normal.png | normal | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 1368916 | 16777216 |
| models/lynns/bl_ly_bed_sage/bl_ly_bed_sage_orm.png | albedo | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 640104 | 16777216 |
| models/lynns/bl_ly_sofa_cream/bl_ly_sofa_cream_albedo.png | albedo | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 2774222 | 16777216 |
| models/lynns/bl_ly_sofa_cream/bl_ly_sofa_cream_normal.png | normal | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 3574848 | 16777216 |
| models/lynns/bl_ly_sofa_cream/bl_ly_sofa_cream_orm.png | albedo | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 720970 | 16777216 |
| models/lynns/bl_ly_sofa_leather/bl_ly_sofa_leather_albedo.png | albedo | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 1712694 | 16777216 |
| models/lynns/bl_ly_sofa_leather/bl_ly_sofa_leather_normal.png | normal | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 2092732 | 16777216 |
| models/lynns/bl_ly_sofa_leather/bl_ly_sofa_leather_orm.png | albedo | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 1054876 | 16777216 |
| models/lynns/bl_ly_sofa_sage/bl_ly_sofa_sage_albedo.png | albedo | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 2077670 | 16777216 |
| models/lynns/bl_ly_sofa_sage/bl_ly_sofa_sage_normal.png | normal | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 1952268 | 16777216 |
| models/lynns/bl_ly_sofa_sage/bl_ly_sofa_sage_orm.png | albedo | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 702496 | 16777216 |
| models/lynns/bl_ly_sofa_taupe/bl_ly_sofa_taupe_albedo.png | albedo | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 2300390 | 16777216 |
| models/lynns/bl_ly_sofa_taupe/bl_ly_sofa_taupe_normal.png | normal | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 2020868 | 16777216 |
| models/lynns/bl_ly_sofa_taupe/bl_ly_sofa_taupe_orm.png | albedo | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 730338 | 16777216 |
| items/radioshack/tex/cordless_phone.png | albedo | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 19136 | 16777216 |
| items/radioshack/tex/rc_car_box.png | albedo | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 79420 | 16777216 |
| items/radioshack/tex/battery_card.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 16636 | 4194304 |
| models/lynns/bl_ly_chest_espresso/bl_ly_chest_espresso_albedo.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 820266 | 4194304 |
| models/lynns/bl_ly_chest_espresso/bl_ly_chest_espresso_normal.png | normal | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 145430 | 4194304 |
| models/lynns/bl_ly_chest_espresso/bl_ly_chest_espresso_orm.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 147502 | 4194304 |
| models/lynns/bl_ly_chest_glam/bl_ly_chest_glam_albedo.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 162288 | 4194304 |
| models/lynns/bl_ly_chest_glam/bl_ly_chest_glam_normal.png | normal | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 113900 | 4194304 |
| models/lynns/bl_ly_chest_glam/bl_ly_chest_glam_orm.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 143312 | 4194304 |
| models/lynns/bl_ly_chest_oak/bl_ly_chest_oak_albedo.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 873524 | 4194304 |
| models/lynns/bl_ly_chest_oak/bl_ly_chest_oak_normal.png | normal | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 110596 | 4194304 |
| models/lynns/bl_ly_chest_oak/bl_ly_chest_oak_orm.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 151502 | 4194304 |
| models/lynns/bl_ly_chest_sage/bl_ly_chest_sage_albedo.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 600670 | 4194304 |
| models/lynns/bl_ly_chest_sage/bl_ly_chest_sage_normal.png | normal | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 165856 | 4194304 |
| models/lynns/bl_ly_chest_sage/bl_ly_chest_sage_orm.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 153254 | 4194304 |
| models/lynns/bl_ly_dresser_espresso/bl_ly_dresser_espresso_albedo.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 737052 | 4194304 |
| models/lynns/bl_ly_dresser_espresso/bl_ly_dresser_espresso_normal.png | normal | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 173810 | 4194304 |
| models/lynns/bl_ly_dresser_espresso/bl_ly_dresser_espresso_orm.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 181678 | 4194304 |
| models/lynns/bl_ly_dresser_glam/bl_ly_dresser_glam_albedo.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 325502 | 4194304 |
| models/lynns/bl_ly_dresser_glam/bl_ly_dresser_glam_normal.png | normal | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 224690 | 4194304 |
| models/lynns/bl_ly_dresser_glam/bl_ly_dresser_glam_orm.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 273664 | 4194304 |
| models/lynns/bl_ly_dresser_oak/bl_ly_dresser_oak_albedo.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 852994 | 4194304 |
| models/lynns/bl_ly_dresser_oak/bl_ly_dresser_oak_normal.png | normal | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 173128 | 4194304 |
| models/lynns/bl_ly_dresser_oak/bl_ly_dresser_oak_orm.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 245646 | 4194304 |
| models/lynns/bl_ly_dresser_sage/bl_ly_dresser_sage_albedo.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 593150 | 4194304 |
| models/lynns/bl_ly_dresser_sage/bl_ly_dresser_sage_normal.png | normal | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 211494 | 4194304 |
| models/lynns/bl_ly_dresser_sage/bl_ly_dresser_sage_orm.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 215486 | 4194304 |
| models/lynns/bl_ly_night_espresso/bl_ly_night_espresso_albedo.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 746744 | 4194304 |
| models/lynns/bl_ly_night_espresso/bl_ly_night_espresso_normal.png | normal | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 138766 | 4194304 |
| models/lynns/bl_ly_night_espresso/bl_ly_night_espresso_orm.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 144638 | 4194304 |
| models/lynns/bl_ly_night_glam/bl_ly_night_glam_albedo.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 191792 | 4194304 |
| models/lynns/bl_ly_night_glam/bl_ly_night_glam_normal.png | normal | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 137208 | 4194304 |
| models/lynns/bl_ly_night_glam/bl_ly_night_glam_orm.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 163176 | 4194304 |
| models/lynns/bl_ly_night_oak/bl_ly_night_oak_albedo.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 816352 | 4194304 |
| models/lynns/bl_ly_night_oak/bl_ly_night_oak_normal.png | normal | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 121434 | 4194304 |
| models/lynns/bl_ly_night_oak/bl_ly_night_oak_orm.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 156222 | 4194304 |
| models/lynns/bl_ly_night_sage/bl_ly_night_sage_albedo.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 514928 | 4194304 |
| models/lynns/bl_ly_night_sage/bl_ly_night_sage_normal.png | normal | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 139906 | 4194304 |
| models/lynns/bl_ly_night_sage/bl_ly_night_sage_orm.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 138316 | 4194304 |
| items/radioshack/tex/cb_radio.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 16362 | 4194304 |
| tex/sr/concrete.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 542336 | 4194304 |
| addons/dialogue_manager/assets/logo.svg | ui | webp-lossless | RGBA8 | 1024x1024 | 0 | 1 | 49440 | 4194304 |
| items/radioshack/tex/microcassette.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 10798 | 4194304 |
| items/radioshack/tex/pager.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 12052 | 4194304 |
| items/radioshack/tex/scanner.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 20124 | 4194304 |
| tex/pc/video_marquees_blank.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 56112 | 4194304 |
| items/radioshack/tex/walkie_talkies.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 12382 | 4194304 |
| tex/cd7/troffer.png | albedo | webp-lossless | RGB8 | 600x1200 | 0 | 1 | 274 | 2880000 |
| tex/sr/carpet_taupe.png | albedo | webp-lossless | RGB8 | 512x512 | 0 | 1 | 162742 | 1048576 |
| tex/sr/marble_vinyl.png | albedo | webp-lossless | RGB8 | 512x512 | 0 | 1 | 112314 | 1048576 |
| addons/dialogue_manager/assets/resource.svg | ui | webp-lossless | RGBA8 | 512x512 | 0 | 1 | 13392 | 1048576 |
| npc/skins/Ch01_0.png | cast | image | ETC2_RGBA8 | 768x768 | 9 | 1 | 786532 | 786430 |
| npc/skins/Ch12_0.png | cast | image | ETC2_RGBA8 | 768x768 | 9 | 1 | 786532 | 786430 |
| npc/skins/Ch28_0.png | cast | image | ETC2_RGBA8 | 768x768 | 9 | 1 | 786532 | 786430 |
| tex/sr/panel.png | albedo | webp-lossless | RGB8 | 256x512 | 0 | 1 | 38480 | 524288 |
| tex/items/it_die.png | ui | webp-lossless | RGB8 | 384x256 | 0 | 1 | 10654 | 393216 |
| tex/items/it_pog_card.png | ui | webp-lossless | RGB8 | 256x384 | 0 | 1 | 2214 | 393216 |
| npc/skins/Ch02_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch08_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch13_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch21_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch22_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch23_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch26_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch27_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch37_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch38_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch41_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch42_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Remy_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| tex/palm_frond.png | albedo | image | ETC2_RGBA8 | 256x1024 | 10 | 1 | 349636 | 349527 |
| tex/int_side.png | albedo | image | ETC2_RGB8 | 1024x512 | 10 | 1 | 349596 | 349525 |
| tex/poinsettia.png | albedo | image | ETC2_RGBA8 | 512x512 | 9 | 1 | 349604 | 349525 |
| tex/dir/back.png | ui | webp-lossless | RGB8 | 256x256 | 0 | 1 | 26040 | 262144 |
| items/radioshack/icons/battery_card.png | albedo | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 12204 | 262144 |
| items/radioshack/icons/cb_radio.png | albedo | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 9542 | 262144 |
| items/radioshack/icons/cordless_phone.png | albedo | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 12268 | 262144 |
| tex/kb/dept_blank.png | albedo | webp-lossless | RGB8 | 512x128 | 0 | 1 | 30414 | 262144 |
| items/radioshack/icons/microcassette.png | albedo | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 13718 | 262144 |
| items/radioshack/icons/pager.png | albedo | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 10640 | 262144 |
| tex/items/pc_claw_bruiser.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 17348 | 262144 |
| tex/items/pc_claw_comet.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 24656 | 262144 |
| tex/items/pc_claw_crawfish.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 10722 | 262144 |
| tex/items/pc_claw_gator.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 8960 | 262144 |
| tex/items/pc_claw_nutria.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 8880 | 262144 |
| tex/items/pc_claw_pelican.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 15710 | 262144 |
| tex/items/pc_claw_pogEye.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 16462 | 262144 |
| tex/items/pc_claw_pogGator.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 21136 | 262144 |
| tex/items/pc_claw_pogSkull.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 18510 | 262144 |
| tex/items/pc_claw_rougarou.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 18412 | 262144 |
| tex/items/pc_claw_slammer.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 30160 | 262144 |
| items/radioshack/icons/rc_car_box.png | albedo | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 25644 | 262144 |
| items/radioshack/icons/scanner.png | albedo | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 7096 | 262144 |
| items/radioshack/icons/walkie_talkies.png | albedo | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 7474 | 262144 |
| npc/skins/Ch02_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch08_2.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch13_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch21_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch22_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch23_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch26_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch27_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch37_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch38_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch41_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch42_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Remy_3.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Remy_5.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| tex/plaster.png | albedo | image | ETC2_RGB8 | 512x512 | 9 | 1 | 174828 | 174762 |
| tex/stone.png | albedo | image | ETC2_RGB8 | 512x512 | 9 | 1 | 174828 | 174762 |
| tex/wood_dark.png | albedo | image | ETC2_RGB8 | 512x512 | 9 | 1 | 174828 | 174762 |
| tex/kb/ceiling.png | albedo | webp-lossless | RGB8 | 128x256 | 0 | 1 | 14550 | 131072 |
| tex/kb/troffer.png | albedo | webp-lossless | RGB8 | 128x256 | 0 | 1 | 326 | 131072 |
| tex/standin/y26_from_w1_night.png | stand-in | webp-lossless | RGB8 | 256x128 | 0 | 1 | 30876 | 131072 |
| tex/standin/y26_from_w2_night.png | stand-in | webp-lossless | RGB8 | 256x128 | 0 | 1 | 35766 | 131072 |
| npc/skins/Ch08_1.png | cast | image | ETC2_RGB8 | 384x384 | 8 | 1 | 98380 | 98303 |
| npc/skins/Remy_1.png | cast | image | ETC2_RGB8 | 384x384 | 8 | 1 | 98380 | 98303 |
| npc/skins/Remy_2.png | cast | image | ETC2_RGB8 | 384x384 | 8 | 1 | 98380 | 98303 |
| npc/skins/Remy_4.png | cast | image | ETC2_RGB8 | 384x384 | 8 | 1 | 98380 | 98303 |
| addons/dialogue_manager/assets/update.svg | ui | webp-lossless | RGBA8 | 300x80 | 0 | 1 | 5340 | 96000 |
| tex/items/candy_neck.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7674 | 65536 |
| tex/items/dice.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 9836 | 65536 |
| tex/items/folse_stick.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 1630 | 65536 |
| tex/items/gi_arcade.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8266 | 65536 |
| tex/items/gi_blind_bag.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7194 | 65536 |
| tex/items/gi_bubbles.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 3996 | 65536 |
| tex/items/gi_cable.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5340 | 65536 |
| tex/items/gi_console.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 6826 | 65536 |
| tex/items/gi_earbuds.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4728 | 65536 |
| tex/items/gi_emoji_key.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7826 | 65536 |
| tex/items/gi_fidget.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5842 | 65536 |
| tex/items/gi_giftcard.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 3986 | 65536 |
| tex/items/gi_handheld.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8894 | 65536 |
| tex/items/gi_headphones.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8400 | 65536 |
| tex/items/gi_jumbo.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 9108 | 65536 |
| tex/items/gi_led_wand.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 3140 | 65536 |
| tex/items/gi_ledstrip.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8872 | 65536 |
| tex/items/gi_light_ring.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4662 | 65536 |
| tex/items/gi_phone_stand.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5930 | 65536 |
| tex/items/gi_play_ball.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8812 | 65536 |
| tex/items/gi_popper_board.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 12764 | 65536 |
| tex/items/gi_popper_key.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 10584 | 65536 |
| tex/items/gi_projector.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 9032 | 65536 |
| tex/items/gi_slime.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4566 | 65536 |
| tex/items/gi_speaker.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8356 | 65536 |
| tex/items/gi_squish_big.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8714 | 65536 |
| tex/items/gi_squishy.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 6306 | 65536 |
| models/lynns/pack/ly_palette.png | albedo | webp-lossless | RGB8 | 128x128 | 0 | 1 | 394 | 65536 |
| models/lynns/pack/ly_palette_orm.png | albedo | webp-lossless | RGB8 | 128x128 | 0 | 1 | 202 | 65536 |
| tex/items/pc_alien.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7690 | 65536 |
| tex/items/pc_army_men.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8094 | 65536 |
| tex/items/pc_ball.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8816 | 65536 |
| tex/items/pc_big_bear.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 9518 | 65536 |
| tex/items/pc_big_dice.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5086 | 65536 |
| tex/items/pc_bounce_ball.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 6942 | 65536 |
| tex/items/pc_candy_cig.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4658 | 65536 |
| tex/items/pc_candy_ring.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 6156 | 65536 |
| tex/items/pc_candy_roll.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7588 | 65536 |
| tex/items/pc_cassette.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 10530 | 65536 |
| tex/items/pc_chew.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7948 | 65536 |
| tex/items/pc_eraser.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4264 | 65536 |
| tex/items/pc_glow_bracelet.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 6834 | 65536 |
| tex/items/pc_harmonica.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4880 | 65536 |
| tex/items/pc_jelly_bracelet.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7044 | 65536 |
| tex/items/pc_jelly_trap.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4798 | 65536 |
| tex/items/pc_lcd_game.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 9072 | 65536 |
| tex/items/pc_lollipop.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 2738 | 65536 |
| tex/items/pc_mood_ring.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4768 | 65536 |
| tex/items/pc_paddle_ball.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5216 | 65536 |
| tex/items/pc_pencil.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 3574 | 65536 |
| tex/items/pc_powder_straw.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 3608 | 65536 |
| tex/items/pc_rc_car.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 11782 | 65536 |
| tex/items/pc_rubber_snake.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 6154 | 65536 |
| tex/items/pc_slammer.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 920 | 65536 |
| tex/items/pc_sour_candy.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4724 | 65536 |
| tex/items/pc_spider_ring.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 3560 | 65536 |
| tex/items/pc_stickers.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7440 | 65536 |
| tex/items/pc_sticky_hand.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5404 | 65536 |
| tex/items/pc_sunglasses.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 6408 | 65536 |
| tex/items/pc_taffy.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5558 | 65536 |
| tex/items/pc_toy_car.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7670 | 65536 |
| tex/items/pc_vpet.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7950 | 65536 |
| tex/items/pc_walkie.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7800 | 65536 |
| tex/items/pc_water_pistol.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5392 | 65536 |
| tex/items/pogs.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 10278 | 65536 |
| tex/items/slap.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5130 | 65536 |
| tex/items/spring.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 16232 | 65536 |
| tex/items/it_rainbow.png | ui | webp-lossless | RGB8 | 32x256 | 0 | 1 | 196 | 32768 |
| tex/items/it_slap.png | ui | webp-lossless | RGB8 | 256x32 | 0 | 1 | 620 | 32768 |
| tex/items/it_candy.png | ui | webp-lossless | RGB8 | 256x16 | 0 | 1 | 172 | 16384 |
| tex/items/it_halo.png | ui | webp-lossless | RGBA8 | 64x64 | 0 | 1 | 820 | 16384 |
| addons/dialogue_manager/assets/cue.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 174 | 1024 |
| addons/dialogue_manager/nodes/actionable/dialogue_actionable_2d.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 318 | 1024 |
| addons/dialogue_manager/nodes/actionable/dialogue_actionable_3d.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 272 | 1024 |
| addons/dialogue_manager/nodes/dialogue_label/dialogue_label.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 350 | 1024 |
| addons/dialogue_manager/nodes/marker/dialogue_marker_2d.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 282 | 1024 |
| addons/dialogue_manager/nodes/marker/dialogue_marker_3d.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 262 | 1024 |
| addons/dialogue_manager/nodes/responses_menu/dialogue_responses_menu.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 224 | 1024 |
| addons/dialogue_manager/nodes/context/dialogue_state_context.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 320 | 1024 |
| addons/dialogue_manager/assets/icon.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 322 | 1024 |
| addons/dialogue_manager/assets/region.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 158 | 1024 |

### w5y26.mobile.pck: 35.0 MB pack; textures 173 files, 25.1 MB on disk, 440.3 MB in GPU memory

| Kind | Files | MB on disk | MB in GPU memory (web) |
|---|---|---|---|
| ui | 100 | 3.2 | 263.8 |
| albedo | 34 | 3.8 | 81.7 |
| stand-in | 4 | 5.4 | 67.4 |
| lightmap | 1 | 2.1 | 16.8 |
| cast | 34 | 10.6 | 10.6 |

| Stored as | Files | MB on disk | MB in GPU memory (web) |
|---|---|---|---|
| webp-lossless RGB8 | 33 | 9.9 | 396.5 |
| vram ASTC_4x4_HDR | 1 | 2.1 | 16.8 |
| webp-lossless RGBA8 | 98 | 0.8 | 14.6 |
| vram ETC2_RGB8 | 22 | 6.6 | 6.6 |
| vram ETC2_RGBA8 | 19 | 5.8 | 5.8 |

| Source | Kind | Stored | Format | Size | Mips | Layers | Bytes on disk | Bytes in GPU |
|---|---|---|---|---|---|---|---|---|
| tex/dir/hi/panel_1995.png | ui | webp-lossless | RGB8 | 4096x4580 | 12 | 1 | 752008 | 100049940 |
| tex/dir/hi/panel_2026.png | ui | webp-lossless | RGB8 | 4096x4580 | 12 | 1 | 937534 | 100049940 |
| tex/standin/y26_from_w1_day.png | stand-in | webp-lossless | RGB8 | 4096x2048 | 0 | 1 | 2417322 | 33554432 |
| tex/standin/y26_from_w2_day.png | stand-in | webp-lossless | RGB8 | 4096x2048 | 0 | 1 | 2954690 | 33554432 |
| tex/dir/panel_1995.png | ui | webp-lossless | RGB8 | 2048x2290 | 11 | 1 | 342466 | 25011220 |
| tex/dir/panel_2026.png | ui | webp-lossless | RGB8 | 2048x2290 | 11 | 1 | 408600 | 25011220 |
| items/radioshack/tex/cordless_phone.png | albedo | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 19136 | 16777216 |
| items/radioshack/tex/rc_car_box.png | albedo | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 79420 | 16777216 |
| wing5_2026_day.exr | lightmap | image | ASTC_4x4_HDR | 1024x1024 | 0 | 2 | 2097220 | 16777216 |
| items/radioshack/tex/battery_card.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 16636 | 4194304 |
| items/radioshack/tex/cb_radio.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 16362 | 4194304 |
| tex/dl/cherry.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 703496 | 4194304 |
| addons/dialogue_manager/assets/logo.svg | ui | webp-lossless | RGBA8 | 1024x1024 | 0 | 1 | 49440 | 4194304 |
| items/radioshack/tex/microcassette.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 10798 | 4194304 |
| items/radioshack/tex/pager.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 12052 | 4194304 |
| items/radioshack/tex/scanner.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 20124 | 4194304 |
| tex/dl/trav.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 620362 | 4194304 |
| tex/pc/video_marquees_blank.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 56112 | 4194304 |
| items/radioshack/tex/walkie_talkies.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 12382 | 4194304 |
| tex/cd7/troffer.png | albedo | webp-lossless | RGB8 | 600x1200 | 0 | 1 | 274 | 2880000 |
| tex/dl/carpet.png | albedo | webp-lossless | RGB8 | 512x512 | 0 | 1 | 135300 | 1048576 |
| addons/dialogue_manager/assets/resource.svg | ui | webp-lossless | RGBA8 | 512x512 | 0 | 1 | 13392 | 1048576 |
| tex/dl/vest.png | albedo | webp-lossless | RGB8 | 512x512 | 0 | 1 | 118282 | 1048576 |
| tex/sg/y26/dillards_name_face.png | albedo | webp-lossless | RGB8 | 1024x199 | 0 | 1 | 43352 | 815104 |
| npc/skins/Ch01_0.png | cast | image | ETC2_RGBA8 | 768x768 | 9 | 1 | 786532 | 786430 |
| npc/skins/Ch12_0.png | cast | image | ETC2_RGBA8 | 768x768 | 9 | 1 | 786532 | 786430 |
| npc/skins/Ch28_0.png | cast | image | ETC2_RGBA8 | 768x768 | 9 | 1 | 786532 | 786430 |
| tex/items/it_die.png | ui | webp-lossless | RGB8 | 384x256 | 0 | 1 | 10654 | 393216 |
| tex/items/it_pog_card.png | ui | webp-lossless | RGB8 | 256x384 | 0 | 1 | 2214 | 393216 |
| npc/skins/Ch02_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch08_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch13_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch21_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch22_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch23_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch26_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch27_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch37_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch38_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch41_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch42_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Remy_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| tex/palm_frond.png | albedo | image | ETC2_RGBA8 | 256x1024 | 10 | 1 | 349636 | 349527 |
| tex/int_side.png | albedo | image | ETC2_RGB8 | 1024x512 | 10 | 1 | 349596 | 349525 |
| tex/poinsettia.png | albedo | image | ETC2_RGBA8 | 512x512 | 9 | 1 | 349604 | 349525 |
| tex/dir/back.png | ui | webp-lossless | RGB8 | 256x256 | 0 | 1 | 26040 | 262144 |
| items/radioshack/icons/battery_card.png | albedo | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 12204 | 262144 |
| items/radioshack/icons/cb_radio.png | albedo | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 9542 | 262144 |
| items/radioshack/icons/cordless_phone.png | albedo | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 12268 | 262144 |
| tex/kb/dept_blank.png | albedo | webp-lossless | RGB8 | 512x128 | 0 | 1 | 30414 | 262144 |
| tex/dl/granite.png | albedo | webp-lossless | RGB8 | 256x256 | 0 | 1 | 41528 | 262144 |
| items/radioshack/icons/microcassette.png | albedo | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 13718 | 262144 |
| items/radioshack/icons/pager.png | albedo | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 10640 | 262144 |
| tex/items/pc_claw_bruiser.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 17348 | 262144 |
| tex/items/pc_claw_comet.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 24656 | 262144 |
| tex/items/pc_claw_crawfish.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 10722 | 262144 |
| tex/items/pc_claw_gator.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 8960 | 262144 |
| tex/items/pc_claw_nutria.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 8880 | 262144 |
| tex/items/pc_claw_pelican.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 15710 | 262144 |
| tex/items/pc_claw_pogEye.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 16462 | 262144 |
| tex/items/pc_claw_pogGator.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 21136 | 262144 |
| tex/items/pc_claw_pogSkull.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 18510 | 262144 |
| tex/items/pc_claw_rougarou.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 18412 | 262144 |
| tex/items/pc_claw_slammer.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 30160 | 262144 |
| items/radioshack/icons/rc_car_box.png | albedo | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 25644 | 262144 |
| items/radioshack/icons/scanner.png | albedo | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 7096 | 262144 |
| items/radioshack/icons/walkie_talkies.png | albedo | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 7474 | 262144 |
| npc/skins/Ch02_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch08_2.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch13_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch21_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch22_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch23_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch26_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch27_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch37_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch38_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch41_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch42_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Remy_3.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Remy_5.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| tex/plaster.png | albedo | image | ETC2_RGB8 | 512x512 | 9 | 1 | 174828 | 174762 |
| tex/stone.png | albedo | image | ETC2_RGB8 | 512x512 | 9 | 1 | 174828 | 174762 |
| tex/wood_dark.png | albedo | image | ETC2_RGB8 | 512x512 | 9 | 1 | 174828 | 174762 |
| tex/wood_diag.png | albedo | image | ETC2_RGB8 | 512x512 | 9 | 1 | 174828 | 174762 |
| tex/kb/ceiling.png | albedo | webp-lossless | RGB8 | 128x256 | 0 | 1 | 14550 | 131072 |
| tex/kb/troffer.png | albedo | webp-lossless | RGB8 | 128x256 | 0 | 1 | 326 | 131072 |
| tex/standin/y26_from_w1_night.png | stand-in | webp-lossless | RGB8 | 256x128 | 0 | 1 | 30876 | 131072 |
| tex/standin/y26_from_w2_night.png | stand-in | webp-lossless | RGB8 | 256x128 | 0 | 1 | 35766 | 131072 |
| npc/skins/Ch08_1.png | cast | image | ETC2_RGB8 | 384x384 | 8 | 1 | 98380 | 98303 |
| npc/skins/Remy_1.png | cast | image | ETC2_RGB8 | 384x384 | 8 | 1 | 98380 | 98303 |
| npc/skins/Remy_2.png | cast | image | ETC2_RGB8 | 384x384 | 8 | 1 | 98380 | 98303 |
| npc/skins/Remy_4.png | cast | image | ETC2_RGB8 | 384x384 | 8 | 1 | 98380 | 98303 |
| addons/dialogue_manager/assets/update.svg | ui | webp-lossless | RGBA8 | 300x80 | 0 | 1 | 5340 | 96000 |
| tex/items/candy_neck.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7674 | 65536 |
| tex/items/dice.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 9836 | 65536 |
| tex/items/folse_stick.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 1630 | 65536 |
| tex/items/gi_arcade.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8266 | 65536 |
| tex/items/gi_blind_bag.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7194 | 65536 |
| tex/items/gi_bubbles.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 3996 | 65536 |
| tex/items/gi_cable.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5340 | 65536 |
| tex/items/gi_console.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 6826 | 65536 |
| tex/items/gi_earbuds.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4728 | 65536 |
| tex/items/gi_emoji_key.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7826 | 65536 |
| tex/items/gi_fidget.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5842 | 65536 |
| tex/items/gi_giftcard.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 3986 | 65536 |
| tex/items/gi_handheld.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8894 | 65536 |
| tex/items/gi_headphones.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8400 | 65536 |
| tex/items/gi_jumbo.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 9108 | 65536 |
| tex/items/gi_led_wand.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 3140 | 65536 |
| tex/items/gi_ledstrip.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8872 | 65536 |
| tex/items/gi_light_ring.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4662 | 65536 |
| tex/items/gi_phone_stand.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5930 | 65536 |
| tex/items/gi_play_ball.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8812 | 65536 |
| tex/items/gi_popper_board.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 12764 | 65536 |
| tex/items/gi_popper_key.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 10584 | 65536 |
| tex/items/gi_projector.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 9032 | 65536 |
| tex/items/gi_slime.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4566 | 65536 |
| tex/items/gi_speaker.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8356 | 65536 |
| tex/items/gi_squish_big.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8714 | 65536 |
| tex/items/gi_squishy.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 6306 | 65536 |
| tex/items/pc_alien.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7690 | 65536 |
| tex/items/pc_army_men.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8094 | 65536 |
| tex/items/pc_ball.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8816 | 65536 |
| tex/items/pc_big_bear.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 9518 | 65536 |
| tex/items/pc_big_dice.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5086 | 65536 |
| tex/items/pc_bounce_ball.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 6942 | 65536 |
| tex/items/pc_candy_cig.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4658 | 65536 |
| tex/items/pc_candy_ring.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 6156 | 65536 |
| tex/items/pc_candy_roll.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7588 | 65536 |
| tex/items/pc_cassette.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 10530 | 65536 |
| tex/items/pc_chew.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7948 | 65536 |
| tex/items/pc_eraser.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4264 | 65536 |
| tex/items/pc_glow_bracelet.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 6834 | 65536 |
| tex/items/pc_harmonica.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4880 | 65536 |
| tex/items/pc_jelly_bracelet.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7044 | 65536 |
| tex/items/pc_jelly_trap.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4798 | 65536 |
| tex/items/pc_lcd_game.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 9072 | 65536 |
| tex/items/pc_lollipop.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 2738 | 65536 |
| tex/items/pc_mood_ring.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4768 | 65536 |
| tex/items/pc_paddle_ball.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5216 | 65536 |
| tex/items/pc_pencil.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 3574 | 65536 |
| tex/items/pc_powder_straw.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 3608 | 65536 |
| tex/items/pc_rc_car.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 11782 | 65536 |
| tex/items/pc_rubber_snake.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 6154 | 65536 |
| tex/items/pc_slammer.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 920 | 65536 |
| tex/items/pc_sour_candy.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4724 | 65536 |
| tex/items/pc_spider_ring.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 3560 | 65536 |
| tex/items/pc_stickers.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7440 | 65536 |
| tex/items/pc_sticky_hand.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5404 | 65536 |
| tex/items/pc_sunglasses.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 6408 | 65536 |
| tex/items/pc_taffy.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5558 | 65536 |
| tex/items/pc_toy_car.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7670 | 65536 |
| tex/items/pc_vpet.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7950 | 65536 |
| tex/items/pc_walkie.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7800 | 65536 |
| tex/items/pc_water_pistol.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5392 | 65536 |
| tex/items/pogs.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 10278 | 65536 |
| tex/items/slap.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5130 | 65536 |
| tex/items/spring.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 16232 | 65536 |
| tex/items/it_rainbow.png | ui | webp-lossless | RGB8 | 32x256 | 0 | 1 | 196 | 32768 |
| tex/items/it_slap.png | ui | webp-lossless | RGB8 | 256x32 | 0 | 1 | 620 | 32768 |
| tex/items/it_candy.png | ui | webp-lossless | RGB8 | 256x16 | 0 | 1 | 172 | 16384 |
| tex/items/it_halo.png | ui | webp-lossless | RGBA8 | 64x64 | 0 | 1 | 820 | 16384 |
| addons/dialogue_manager/assets/cue.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 174 | 1024 |
| addons/dialogue_manager/nodes/actionable/dialogue_actionable_2d.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 318 | 1024 |
| addons/dialogue_manager/nodes/actionable/dialogue_actionable_3d.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 272 | 1024 |
| addons/dialogue_manager/nodes/dialogue_label/dialogue_label.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 350 | 1024 |
| addons/dialogue_manager/nodes/marker/dialogue_marker_2d.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 282 | 1024 |
| addons/dialogue_manager/nodes/marker/dialogue_marker_3d.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 262 | 1024 |
| addons/dialogue_manager/nodes/responses_menu/dialogue_responses_menu.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 224 | 1024 |
| addons/dialogue_manager/nodes/context/dialogue_state_context.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 320 | 1024 |
| addons/dialogue_manager/assets/icon.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 322 | 1024 |
| addons/dialogue_manager/assets/region.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 158 | 1024 |

### w6y26.mobile.pck: 20.8 MB pack; textures 154 files, 14.5 MB on disk, 340.3 MB in GPU memory

| Kind | Files | MB on disk | MB in GPU memory (web) |
|---|---|---|---|
| ui | 100 | 3.2 | 263.8 |
| albedo | 20 | 0.7 | 65.9 |
| cast | 34 | 10.6 | 10.6 |

| Stored as | Files | MB on disk | MB in GPU memory (web) |
|---|---|---|---|
| webp-lossless RGB8 | 21 | 2.8 | 314.7 |
| webp-lossless RGBA8 | 98 | 0.8 | 14.6 |
| vram ETC2_RGB8 | 18 | 5.9 | 5.9 |
| vram ETC2_RGBA8 | 17 | 5.1 | 5.1 |

| Source | Kind | Stored | Format | Size | Mips | Layers | Bytes on disk | Bytes in GPU |
|---|---|---|---|---|---|---|---|---|
| tex/dir/hi/panel_1995.png | ui | webp-lossless | RGB8 | 4096x4580 | 12 | 1 | 752008 | 100049940 |
| tex/dir/hi/panel_2026.png | ui | webp-lossless | RGB8 | 4096x4580 | 12 | 1 | 937534 | 100049940 |
| tex/dir/panel_1995.png | ui | webp-lossless | RGB8 | 2048x2290 | 11 | 1 | 342466 | 25011220 |
| tex/dir/panel_2026.png | ui | webp-lossless | RGB8 | 2048x2290 | 11 | 1 | 408600 | 25011220 |
| items/radioshack/tex/cordless_phone.png | albedo | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 19136 | 16777216 |
| items/radioshack/tex/rc_car_box.png | albedo | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 79420 | 16777216 |
| items/radioshack/tex/battery_card.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 16636 | 4194304 |
| items/radioshack/tex/cb_radio.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 16362 | 4194304 |
| addons/dialogue_manager/assets/logo.svg | ui | webp-lossless | RGBA8 | 1024x1024 | 0 | 1 | 49440 | 4194304 |
| items/radioshack/tex/microcassette.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 10798 | 4194304 |
| items/radioshack/tex/pager.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 12052 | 4194304 |
| items/radioshack/tex/scanner.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 20124 | 4194304 |
| tex/pc/video_marquees_blank.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 56112 | 4194304 |
| items/radioshack/tex/walkie_talkies.png | albedo | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 12382 | 4194304 |
| addons/dialogue_manager/assets/resource.svg | ui | webp-lossless | RGBA8 | 512x512 | 0 | 1 | 13392 | 1048576 |
| npc/skins/Ch01_0.png | cast | image | ETC2_RGBA8 | 768x768 | 9 | 1 | 786532 | 786430 |
| npc/skins/Ch12_0.png | cast | image | ETC2_RGBA8 | 768x768 | 9 | 1 | 786532 | 786430 |
| npc/skins/Ch28_0.png | cast | image | ETC2_RGBA8 | 768x768 | 9 | 1 | 786532 | 786430 |
| tex/items/it_die.png | ui | webp-lossless | RGB8 | 384x256 | 0 | 1 | 10654 | 393216 |
| tex/items/it_pog_card.png | ui | webp-lossless | RGB8 | 256x384 | 0 | 1 | 2214 | 393216 |
| npc/skins/Ch02_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch08_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch13_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch21_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch22_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch23_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch26_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch27_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch37_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch38_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch41_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Ch42_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| npc/skins/Remy_0.png | cast | image | ETC2_RGB8 | 768x768 | 9 | 1 | 393292 | 393215 |
| tex/int_side.png | albedo | image | ETC2_RGB8 | 1024x512 | 10 | 1 | 349596 | 349525 |
| tex/dir/back.png | ui | webp-lossless | RGB8 | 256x256 | 0 | 1 | 26040 | 262144 |
| items/radioshack/icons/battery_card.png | albedo | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 12204 | 262144 |
| tex/cin/carpet.png | albedo | webp-lossless | RGB8 | 256x256 | 0 | 1 | 428 | 262144 |
| items/radioshack/icons/cb_radio.png | albedo | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 9542 | 262144 |
| items/radioshack/icons/cordless_phone.png | albedo | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 12268 | 262144 |
| tex/kb/dept_blank.png | albedo | webp-lossless | RGB8 | 512x128 | 0 | 1 | 30414 | 262144 |
| items/radioshack/icons/microcassette.png | albedo | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 13718 | 262144 |
| items/radioshack/icons/pager.png | albedo | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 10640 | 262144 |
| tex/items/pc_claw_bruiser.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 17348 | 262144 |
| tex/items/pc_claw_comet.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 24656 | 262144 |
| tex/items/pc_claw_crawfish.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 10722 | 262144 |
| tex/items/pc_claw_gator.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 8960 | 262144 |
| tex/items/pc_claw_nutria.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 8880 | 262144 |
| tex/items/pc_claw_pelican.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 15710 | 262144 |
| tex/items/pc_claw_pogEye.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 16462 | 262144 |
| tex/items/pc_claw_pogGator.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 21136 | 262144 |
| tex/items/pc_claw_pogSkull.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 18510 | 262144 |
| tex/items/pc_claw_rougarou.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 18412 | 262144 |
| tex/items/pc_claw_slammer.png | ui | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 30160 | 262144 |
| items/radioshack/icons/rc_car_box.png | albedo | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 25644 | 262144 |
| items/radioshack/icons/scanner.png | albedo | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 7096 | 262144 |
| items/radioshack/icons/walkie_talkies.png | albedo | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 7474 | 262144 |
| npc/skins/Ch02_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch08_2.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch13_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch21_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch22_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch23_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch26_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch27_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch37_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch38_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch41_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch42_1.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Remy_3.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Remy_5.png | cast | image | ETC2_RGBA8 | 384x384 | 8 | 1 | 196708 | 196606 |
| npc/skins/Ch08_1.png | cast | image | ETC2_RGB8 | 384x384 | 8 | 1 | 98380 | 98303 |
| npc/skins/Remy_1.png | cast | image | ETC2_RGB8 | 384x384 | 8 | 1 | 98380 | 98303 |
| npc/skins/Remy_2.png | cast | image | ETC2_RGB8 | 384x384 | 8 | 1 | 98380 | 98303 |
| npc/skins/Remy_4.png | cast | image | ETC2_RGB8 | 384x384 | 8 | 1 | 98380 | 98303 |
| addons/dialogue_manager/assets/update.svg | ui | webp-lossless | RGBA8 | 300x80 | 0 | 1 | 5340 | 96000 |
| tex/items/candy_neck.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7674 | 65536 |
| tex/items/dice.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 9836 | 65536 |
| tex/items/folse_stick.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 1630 | 65536 |
| tex/items/gi_arcade.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8266 | 65536 |
| tex/items/gi_blind_bag.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7194 | 65536 |
| tex/items/gi_bubbles.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 3996 | 65536 |
| tex/items/gi_cable.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5340 | 65536 |
| tex/items/gi_console.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 6826 | 65536 |
| tex/items/gi_earbuds.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4728 | 65536 |
| tex/items/gi_emoji_key.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7826 | 65536 |
| tex/items/gi_fidget.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5842 | 65536 |
| tex/items/gi_giftcard.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 3986 | 65536 |
| tex/items/gi_handheld.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8894 | 65536 |
| tex/items/gi_headphones.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8400 | 65536 |
| tex/items/gi_jumbo.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 9108 | 65536 |
| tex/items/gi_led_wand.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 3140 | 65536 |
| tex/items/gi_ledstrip.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8872 | 65536 |
| tex/items/gi_light_ring.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4662 | 65536 |
| tex/items/gi_phone_stand.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5930 | 65536 |
| tex/items/gi_play_ball.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8812 | 65536 |
| tex/items/gi_popper_board.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 12764 | 65536 |
| tex/items/gi_popper_key.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 10584 | 65536 |
| tex/items/gi_projector.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 9032 | 65536 |
| tex/items/gi_slime.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4566 | 65536 |
| tex/items/gi_speaker.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8356 | 65536 |
| tex/items/gi_squish_big.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8714 | 65536 |
| tex/items/gi_squishy.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 6306 | 65536 |
| tex/items/pc_alien.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7690 | 65536 |
| tex/items/pc_army_men.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8094 | 65536 |
| tex/items/pc_ball.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 8816 | 65536 |
| tex/items/pc_big_bear.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 9518 | 65536 |
| tex/items/pc_big_dice.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5086 | 65536 |
| tex/items/pc_bounce_ball.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 6942 | 65536 |
| tex/items/pc_candy_cig.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4658 | 65536 |
| tex/items/pc_candy_ring.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 6156 | 65536 |
| tex/items/pc_candy_roll.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7588 | 65536 |
| tex/items/pc_cassette.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 10530 | 65536 |
| tex/items/pc_chew.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7948 | 65536 |
| tex/items/pc_eraser.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4264 | 65536 |
| tex/items/pc_glow_bracelet.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 6834 | 65536 |
| tex/items/pc_harmonica.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4880 | 65536 |
| tex/items/pc_jelly_bracelet.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7044 | 65536 |
| tex/items/pc_jelly_trap.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4798 | 65536 |
| tex/items/pc_lcd_game.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 9072 | 65536 |
| tex/items/pc_lollipop.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 2738 | 65536 |
| tex/items/pc_mood_ring.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4768 | 65536 |
| tex/items/pc_paddle_ball.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5216 | 65536 |
| tex/items/pc_pencil.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 3574 | 65536 |
| tex/items/pc_powder_straw.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 3608 | 65536 |
| tex/items/pc_rc_car.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 11782 | 65536 |
| tex/items/pc_rubber_snake.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 6154 | 65536 |
| tex/items/pc_slammer.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 920 | 65536 |
| tex/items/pc_sour_candy.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 4724 | 65536 |
| tex/items/pc_spider_ring.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 3560 | 65536 |
| tex/items/pc_stickers.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7440 | 65536 |
| tex/items/pc_sticky_hand.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5404 | 65536 |
| tex/items/pc_sunglasses.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 6408 | 65536 |
| tex/items/pc_taffy.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5558 | 65536 |
| tex/items/pc_toy_car.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7670 | 65536 |
| tex/items/pc_vpet.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7950 | 65536 |
| tex/items/pc_walkie.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 7800 | 65536 |
| tex/items/pc_water_pistol.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5392 | 65536 |
| tex/items/pogs.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 10278 | 65536 |
| tex/items/slap.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 5130 | 65536 |
| tex/items/spring.png | ui | webp-lossless | RGBA8 | 128x128 | 0 | 1 | 16232 | 65536 |
| tex/items/it_rainbow.png | ui | webp-lossless | RGB8 | 32x256 | 0 | 1 | 196 | 32768 |
| tex/items/it_slap.png | ui | webp-lossless | RGB8 | 256x32 | 0 | 1 | 620 | 32768 |
| tex/items/it_candy.png | ui | webp-lossless | RGB8 | 256x16 | 0 | 1 | 172 | 16384 |
| tex/items/it_halo.png | ui | webp-lossless | RGBA8 | 64x64 | 0 | 1 | 820 | 16384 |
| addons/dialogue_manager/assets/cue.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 174 | 1024 |
| addons/dialogue_manager/nodes/actionable/dialogue_actionable_2d.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 318 | 1024 |
| addons/dialogue_manager/nodes/actionable/dialogue_actionable_3d.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 272 | 1024 |
| addons/dialogue_manager/nodes/dialogue_label/dialogue_label.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 350 | 1024 |
| addons/dialogue_manager/nodes/marker/dialogue_marker_2d.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 282 | 1024 |
| addons/dialogue_manager/nodes/marker/dialogue_marker_3d.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 262 | 1024 |
| addons/dialogue_manager/nodes/responses_menu/dialogue_responses_menu.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 224 | 1024 |
| addons/dialogue_manager/nodes/context/dialogue_state_context.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 320 | 1024 |
| addons/dialogue_manager/assets/icon.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 322 | 1024 |
| addons/dialogue_manager/assets/region.svg | ui | webp-lossless | RGBA8 | 16x16 | 0 | 1 | 158 | 1024 |

### common.mobile.pck: 59.6 MB pack; textures 24 files, 47.2 MB on disk, 218.1 MB in GPU memory

| Kind | Files | MB on disk | MB in GPU memory (web) |
|---|---|---|---|
| cast | 14 | 35.5 | 162.2 |
| cast normal | 10 | 11.7 | 55.9 |

| Stored as | Files | MB on disk | MB in GPU memory (web) |
|---|---|---|---|
| webp-lossless RGB8 | 20 | 43.0 | 195.7 |
| webp-lossless RGBA8 | 4 | 4.2 | 22.4 |

| Source | Kind | Stored | Format | Size | Mips | Layers | Bytes on disk | Bytes in GPU |
|---|---|---|---|---|---|---|---|---|
| cast/auntie_annes_2026_auntie_annes_2026_head.png | cast | webp-lossless | RGB8 | 2048x2048 | 11 | 1 | 4926100 | 22369620 |
| cast/cucos_owner_1995_cucos_owner_1995_head.png | cast | webp-lossless | RGB8 | 2048x2048 | 11 | 1 | 4561682 | 22369620 |
| cast/gac_1995_gac_1995_head.png | cast | webp-lossless | RGB8 | 2048x2048 | 11 | 1 | 6757656 | 22369620 |
| cast/radioshack_1995_radioshack_1995_head.png | cast | webp-lossless | RGB8 | 2048x2048 | 11 | 1 | 4434968 | 22369620 |
| cast/spencers_2026_spencers_2026_head.png | cast | webp-lossless | RGB8 | 2048x2048 | 11 | 1 | 5700198 | 22369620 |
| cast/auntie_annes_2026_auntie_annes_2026_body.png | cast | webp-lossless | RGB8 | 1024x1024 | 10 | 1 | 789582 | 5592404 |
| cast/auntie_annes_2026_m019_body_normal.png | cast normal | webp-lossless | RGB8 | 1024x1024 | 10 | 1 | 1045082 | 5592404 |
| cast/auntie_annes_2026_m019_head_normal.png | cast normal | webp-lossless | RGB8 | 1024x1024 | 10 | 1 | 1035612 | 5592404 |
| cast/cucos_owner_1995_cucos_owner_1995_body.png | cast | webp-lossless | RGB8 | 1024x1024 | 10 | 1 | 1381500 | 5592404 |
| cast/cucos_owner_1995_cucos_owner_1995_opacity.png | cast | webp-lossless | RGBA8 | 1024x1024 | 10 | 1 | 636292 | 5592404 |
| cast/cucos_owner_1995_m013_body_normal.png | cast normal | webp-lossless | RGB8 | 1024x1024 | 10 | 1 | 1513806 | 5592404 |
| cast/cucos_owner_1995_m013_head_normal.png | cast normal | webp-lossless | RGB8 | 1024x1024 | 10 | 1 | 1051384 | 5592404 |
| cast/gac_1995_f022_body_normal.png | cast normal | webp-lossless | RGB8 | 1024x1024 | 10 | 1 | 1101584 | 5592404 |
| cast/gac_1995_f022_head_normal.png | cast normal | webp-lossless | RGB8 | 1024x1024 | 10 | 1 | 1471912 | 5592404 |
| cast/gac_1995_gac_1995_body.png | cast | webp-lossless | RGB8 | 1024x1024 | 10 | 1 | 1087864 | 5592404 |
| cast/gac_1995_gac_1995_opacity.png | cast | webp-lossless | RGBA8 | 1024x1024 | 10 | 1 | 1173468 | 5592404 |
| cast/radioshack_1995_m014_body_normal.png | cast normal | webp-lossless | RGB8 | 1024x1024 | 10 | 1 | 1058266 | 5592404 |
| cast/radioshack_1995_m014_head_normal.png | cast normal | webp-lossless | RGB8 | 1024x1024 | 10 | 1 | 1032010 | 5592404 |
| cast/radioshack_1995_radioshack_1995_body.png | cast | webp-lossless | RGB8 | 1024x1024 | 10 | 1 | 936728 | 5592404 |
| cast/radioshack_1995_radioshack_1995_opacity.png | cast | webp-lossless | RGBA8 | 1024x1024 | 10 | 1 | 1278874 | 5592404 |
| cast/spencers_2026_f014_body_normal.png | cast normal | webp-lossless | RGB8 | 1024x1024 | 10 | 1 | 1069256 | 5592404 |
| cast/spencers_2026_f014_head_normal.png | cast normal | webp-lossless | RGB8 | 1024x1024 | 10 | 1 | 1332242 | 5592404 |
| cast/spencers_2026_spencers_2026_body.png | cast | webp-lossless | RGB8 | 1024x1024 | 10 | 1 | 688434 | 5592404 |
| cast/spencers_2026_spencers_2026_opacity.png | cast | webp-lossless | RGBA8 | 1024x1024 | 10 | 1 | 1114082 | 5592404 |

### items.mobile.pck: 83.9 MB pack; textures 301 files, 74.8 MB on disk, 1315.0 MB in GPU memory

| Kind | Files | MB on disk | MB in GPU memory (web) |
|---|---|---|---|
| items 3D | 206 | 49.8 | 881.1 |
| normal | 61 | 24.9 | 428.9 |
| ui | 34 | 0.0 | 5.1 |

| Stored as | Files | MB on disk | MB in GPU memory (web) |
|---|---|---|---|
| webp-lossless RGB8 | 222 | 71.5 | 1245.0 |
| webp-lossy RGB8 | 3 | 1.9 | 50.3 |
| webp-lossless RGBA8 | 76 | 1.4 | 19.7 |

| Source | Kind | Stored | Format | Size | Mips | Layers | Bytes on disk | Bytes in GPU |
|---|---|---|---|---|---|---|---|---|
| models/bl_bd_adventure_book/bl_bd_adventure_book_albedo.png | items 3D | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 767414 | 16777216 |
| models/bl_bd_adventure_book/bl_bd_adventure_book_normal.png | normal | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 388376 | 16777216 |
| models/bl_bd_adventure_book/bl_bd_adventure_book_orm.png | items 3D | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 229200 | 16777216 |
| models/bl_bd_chills_book/bl_bd_chills_book_albedo.png | items 3D | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 660232 | 16777216 |
| models/bl_bd_chills_book/bl_bd_chills_book_normal.png | normal | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 280922 | 16777216 |
| models/bl_bd_chills_book/bl_bd_chills_book_orm.png | items 3D | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 186762 | 16777216 |
| models/bl_bd_dark_room_book/bl_bd_dark_room_book_albedo.png | items 3D | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 592632 | 16777216 |
| models/bl_bd_dark_room_book/bl_bd_dark_room_book_normal.png | normal | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 446810 | 16777216 |
| models/bl_bd_dark_room_book/bl_bd_dark_room_book_orm.png | items 3D | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 243914 | 16777216 |
| models/bl_bd_mars_book/bl_bd_mars_book_albedo.png | items 3D | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 613548 | 16777216 |
| models/bl_bd_mars_book/bl_bd_mars_book_normal.png | normal | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 329688 | 16777216 |
| models/bl_bd_mars_book/bl_bd_mars_book_orm.png | items 3D | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 169380 | 16777216 |
| models/bl_bd_moby_dick/bl_bd_moby_dick_albedo.png | items 3D | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 1217344 | 16777216 |
| models/bl_bd_moby_dick/bl_bd_moby_dick_normal.png | normal | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 2751974 | 16777216 |
| models/bl_bd_moby_dick/bl_bd_moby_dick_orm.png | items 3D | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 961950 | 16777216 |
| models/bl_cd7_crinkle_fries/bl_cd7_crinkle_fries_albedo.png | items 3D | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 1617146 | 16777216 |
| models/bl_cd7_crinkle_fries/bl_cd7_crinkle_fries_normal.png | normal | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 631354 | 16777216 |
| models/bl_cd7_crinkle_fries/bl_cd7_crinkle_fries_orm.png | items 3D | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 664580 | 16777216 |
| models/bl_cd7_lemonade/bl_cd7_lemonade_albedo.png | items 3D | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 929792 | 16777216 |
| models/bl_cd7_lemonade/bl_cd7_lemonade_normal.png | normal | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 710354 | 16777216 |
| models/bl_cd7_lemonade/bl_cd7_lemonade_orm.png | items 3D | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 474870 | 16777216 |
| models/bl_cu_bb_bottles_a/bl_cu_bb_bottles_a_albedo.png | items 3D | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 899928 | 16777216 |
| models/bl_cu_bb_bottles_a/bl_cu_bb_bottles_a_normal.png | normal | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 190998 | 16777216 |
| models/bl_cu_bb_bottles_a/bl_cu_bb_bottles_a_orm.png | items 3D | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 883052 | 16777216 |
| models/bl_cu_bb_bottles_b/bl_cu_bb_bottles_b_albedo.png | items 3D | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 887668 | 16777216 |
| models/bl_cu_bb_bottles_b/bl_cu_bb_bottles_b_normal.png | normal | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 177272 | 16777216 |
| models/bl_cu_bb_bottles_b/bl_cu_bb_bottles_b_orm.png | items 3D | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 886902 | 16777216 |
| models/bl_cu_bb_service/bl_cu_bb_service_albedo.png | items 3D | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 687312 | 16777216 |
| models/bl_cu_bb_service/bl_cu_bb_service_normal.png | normal | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 1017948 | 16777216 |
| models/bl_cu_bb_service/bl_cu_bb_service_orm.png | items 3D | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 1082092 | 16777216 |
| models/bl_cu_coupon/bl_cu_coupon_albedo.png | items 3D | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 151800 | 16777216 |
| models/bl_cu_coupon/bl_cu_coupon_normal.png | normal | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 194240 | 16777216 |
| models/bl_cu_coupon/bl_cu_coupon_orm.png | items 3D | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 46150 | 16777216 |
| models/bl_ls_lion/bl_ls_lion_albedo.png | items 3D | webp-lossy | RGB8 | 2048x2048 | 0 | 1 | 692632 | 16777216 |
| models/bl_ls_lion/bl_ls_lion_normal.png | normal | webp-lossy | RGB8 | 2048x2048 | 0 | 1 | 501316 | 16777216 |
| models/bl_ls_lion/bl_ls_lion_orm.png | items 3D | webp-lossy | RGB8 | 2048x2048 | 0 | 1 | 692696 | 16777216 |
| models/bl_pc_boombox/bl_pc_boombox_albedo.png | items 3D | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 635610 | 16777216 |
| models/bl_pc_boombox/bl_pc_boombox_normal.png | normal | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 502262 | 16777216 |
| models/bl_pc_boombox/bl_pc_boombox_orm.png | items 3D | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 631008 | 16777216 |
| models/bl_rs_rcbox/bl_rs_rcbox_albedo.png | items 3D | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 309056 | 16777216 |
| models/bl_rs_rcbox/bl_rs_rcbox_normal.png | normal | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 66442 | 16777216 |
| models/bl_rs_rcbox/bl_rs_rcbox_orm.png | items 3D | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 11002 | 16777216 |
| models/bl_wl_fries/bl_wl_fries_albedo.png | items 3D | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 2010172 | 16777216 |
| models/bl_wl_fries/bl_wl_fries_normal.png | normal | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 654004 | 16777216 |
| models/bl_wl_fries/bl_wl_fries_orm.png | items 3D | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 776734 | 16777216 |
| models/bl_wl_hamburger/bl_wl_hamburger_albedo.png | items 3D | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 1936872 | 16777216 |
| models/bl_wl_hamburger/bl_wl_hamburger_normal.png | normal | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 1777554 | 16777216 |
| models/bl_wl_hamburger/bl_wl_hamburger_orm.png | items 3D | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 840306 | 16777216 |
| models/bl_wl_hot_dog/bl_wl_hot_dog_albedo.png | items 3D | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 2315334 | 16777216 |
| models/bl_wl_hot_dog/bl_wl_hot_dog_normal.png | normal | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 1089156 | 16777216 |
| models/bl_wl_hot_dog/bl_wl_hot_dog_orm.png | items 3D | webp-lossless | RGB8 | 2048x2048 | 0 | 1 | 1042906 | 16777216 |
| models/bl_aa_nugget_cup/bl_aa_nugget_cup_albedo.png | items 3D | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 444416 | 4194304 |
| models/bl_aa_nugget_cup_case/bl_aa_nugget_cup_case_albedo.png | items 3D | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 513888 | 4194304 |
| models/bl_aa_nugget_cup_case/bl_aa_nugget_cup_case_normal.png | normal | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 500272 | 4194304 |
| models/bl_aa_nugget_cup_case/bl_aa_nugget_cup_case_orm.png | items 3D | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 286358 | 4194304 |
| models/bl_aa_nugget_cup/bl_aa_nugget_cup_normal.png | normal | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 500630 | 4194304 |
| models/bl_aa_nugget_cup/bl_aa_nugget_cup_orm.png | items 3D | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 226224 | 4194304 |
| models/bl_aa_warmer/bl_aa_warmer_albedo.png | items 3D | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 529522 | 4194304 |
| models/bl_aa_warmer/bl_aa_warmer_normal.png | normal | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 274382 | 4194304 |
| models/bl_aa_warmer/bl_aa_warmer_orm.png | items 3D | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 484286 | 4194304 |
| models/bl_bd_paperback/bl_bd_paperback_albedo.png | items 3D | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 436352 | 4194304 |
| models/bl_bd_paperback/bl_bd_paperback_normal.png | normal | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 94646 | 4194304 |
| models/bl_bd_paperback/bl_bd_paperback_orm.png | items 3D | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 43584 | 4194304 |
| models/bl_cd7_case/bl_cd7_case_albedo.png | items 3D | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 160880 | 4194304 |
| models/bl_cd7_case/bl_cd7_case_normal.png | normal | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 112372 | 4194304 |
| models/bl_cd7_case/bl_cd7_case_orm.png | items 3D | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 46542 | 4194304 |
| models/bl_cd7_corndog/bl_cd7_corndog_albedo.png | items 3D | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 912812 | 4194304 |
| models/bl_cd7_corndog/bl_cd7_corndog_normal.png | normal | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 720444 | 4194304 |
| models/bl_cd7_corndog/bl_cd7_corndog_orm.png | items 3D | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 272692 | 4194304 |
| models/bl_cu_bb_glasses/bl_cu_bb_glasses_albedo.png | items 3D | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 9240 | 4194304 |
| models/bl_cu_bb_glasses/bl_cu_bb_glasses_normal.png | normal | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 45574 | 4194304 |
| models/bl_cu_bb_glasses/bl_cu_bb_glasses_orm.png | items 3D | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 70906 | 4194304 |
| models/bl_cu_bb_stemrack/bl_cu_bb_stemrack_albedo.png | items 3D | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 176032 | 4194304 |
| models/bl_cu_bb_stemrack/bl_cu_bb_stemrack_normal.png | normal | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 103764 | 4194304 |
| models/bl_cu_bb_stemrack/bl_cu_bb_stemrack_orm.png | items 3D | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 196354 | 4194304 |
| models/bl_cu_bb_taps/bl_cu_bb_taps_albedo.png | items 3D | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 340334 | 4194304 |
| models/bl_cu_bb_taps/bl_cu_bb_taps_normal.png | normal | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 262040 | 4194304 |
| models/bl_cu_bb_taps/bl_cu_bb_taps_orm.png | items 3D | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 458806 | 4194304 |
| models/bl_cu_beer/bl_cu_beer_albedo.png | items 3D | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 222296 | 4194304 |
| models/bl_cu_beer/bl_cu_beer_normal.png | normal | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 246858 | 4194304 |
| models/bl_cu_beer/bl_cu_beer_orm.png | items 3D | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 156556 | 4194304 |
| models/bl_cu_doubloon/bl_cu_doubloon_albedo.png | items 3D | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 210046 | 4194304 |
| models/bl_cu_doubloon/bl_cu_doubloon_normal.png | normal | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 173624 | 4194304 |
| models/bl_cu_doubloon/bl_cu_doubloon_orm.png | items 3D | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 149316 | 4194304 |
| models/bl_cu_margarita/bl_cu_margarita_albedo.png | items 3D | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 435696 | 4194304 |
| models/bl_cu_margarita/bl_cu_margarita_normal.png | normal | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 781946 | 4194304 |
| models/bl_cu_margarita/bl_cu_margarita_orm.png | items 3D | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 261694 | 4194304 |
| models/bl_cu_top_shelf_margarita/bl_cu_top_shelf_margarita_albedo.png | items 3D | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 377360 | 4194304 |
| models/bl_cu_top_shelf_margarita/bl_cu_top_shelf_margarita_normal.png | normal | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 416150 | 4194304 |
| models/bl_cu_top_shelf_margarita/bl_cu_top_shelf_margarita_orm.png | items 3D | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 246638 | 4194304 |
| models/bl_ex_dumpster/bl_ex_dumpster_albedo.png | items 3D | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 720542 | 4194304 |
| models/bl_ex_dumpster/bl_ex_dumpster_normal.png | normal | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 426324 | 4194304 |
| models/bl_ex_dumpster/bl_ex_dumpster_orm.png | items 3D | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 447942 | 4194304 |
| models/bl_gac_choc_chip_cookie/bl_gac_choc_chip_cookie_albedo.png | items 3D | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 302292 | 4194304 |
| models/bl_gac_choc_chip_cookie/bl_gac_choc_chip_cookie_normal.png | normal | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 524590 | 4194304 |
| models/bl_gac_choc_chip_cookie/bl_gac_choc_chip_cookie_orm.png | items 3D | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 225594 | 4194304 |
| models/bl_gac_cookies/bl_gac_cookies_albedo.png | items 3D | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 853924 | 4194304 |
| models/bl_gac_cookies/bl_gac_cookies_normal.png | normal | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 1088430 | 4194304 |
| models/bl_gac_cookies/bl_gac_cookies_orm.png | items 3D | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 440788 | 4194304 |
| models/bl_gac_sugarcookie/bl_gac_sugarcookie_albedo.png | items 3D | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 293042 | 4194304 |
| models/bl_gac_sugarcookie/bl_gac_sugarcookie_normal.png | normal | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 235762 | 4194304 |
| models/bl_gac_sugarcookie/bl_gac_sugarcookie_orm.png | items 3D | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 192272 | 4194304 |
| models/bl_kk_caramelcorn/bl_kk_caramelcorn_albedo.png | items 3D | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 627750 | 4194304 |
| models/bl_kk_caramelcorn/bl_kk_caramelcorn_normal.png | normal | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 644740 | 4194304 |
| models/bl_kk_caramelcorn/bl_kk_caramelcorn_orm.png | items 3D | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 348030 | 4194304 |
| models/bl_mall_trashcan/bl_mall_trashcan_albedo.png | items 3D | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 284350 | 4194304 |
| models/bl_mall_trashcan/bl_mall_trashcan_normal.png | normal | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 251744 | 4194304 |
| models/bl_mall_trashcan/bl_mall_trashcan_orm.png | items 3D | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 305126 | 4194304 |
| models/bl_oj_cup/bl_oj_cup_albedo.png | items 3D | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 204474 | 4194304 |
| models/bl_oj_cup/bl_oj_cup_normal.png | normal | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 98408 | 4194304 |
| models/bl_oj_cup/bl_oj_cup_orm.png | items 3D | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 50382 | 4194304 |
| models/bl_pc_fingertrap/bl_pc_fingertrap_albedo.png | items 3D | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 658852 | 4194304 |
| models/bl_pc_fingertrap/bl_pc_fingertrap_normal.png | normal | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 904900 | 4194304 |
| models/bl_pc_fingertrap/bl_pc_fingertrap_orm.png | items 3D | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 227594 | 4194304 |
| models/bl_pc_skateboard/bl_pc_skateboard_albedo.png | items 3D | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 227740 | 4194304 |
| models/bl_pc_skateboard/bl_pc_skateboard_normal.png | normal | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 529724 | 4194304 |
| models/bl_pc_skateboard/bl_pc_skateboard_orm.png | items 3D | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 229120 | 4194304 |
| models/bl_rs_battcard/bl_rs_battcard_albedo.png | items 3D | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 20950 | 4194304 |
| models/bl_rs_battcard/bl_rs_battcard_normal.png | normal | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 32392 | 4194304 |
| models/bl_rs_battcard/bl_rs_battcard_orm.png | items 3D | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 3042 | 4194304 |
| models/bl_rs_cordless/bl_rs_cordless_albedo.png | items 3D | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 347612 | 4194304 |
| models/bl_rs_cordless/bl_rs_cordless_normal.png | normal | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 180472 | 4194304 |
| models/bl_rs_cordless/bl_rs_cordless_orm.png | items 3D | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 265350 | 4194304 |
| models/bl_rs_pager/bl_rs_pager_albedo.png | items 3D | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 78152 | 4194304 |
| models/bl_rs_pager/bl_rs_pager_normal.png | normal | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 188126 | 4194304 |
| models/bl_rs_pager/bl_rs_pager_orm.png | items 3D | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 171274 | 4194304 |
| models/bl_rs_scanner/bl_rs_scanner_albedo.png | items 3D | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 138808 | 4194304 |
| models/bl_rs_scanner/bl_rs_scanner_normal.png | normal | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 244052 | 4194304 |
| models/bl_rs_scanner/bl_rs_scanner_orm.png | items 3D | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 258776 | 4194304 |
| models/bl_rs_walkie/bl_rs_walkie_albedo.png | items 3D | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 126632 | 4194304 |
| models/bl_rs_walkie/bl_rs_walkie_normal.png | normal | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 161982 | 4194304 |
| models/bl_rs_walkie/bl_rs_walkie_orm.png | items 3D | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 202858 | 4194304 |
| models/bl_sr_folse_stick/bl_sr_folse_stick_albedo.png | items 3D | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 21320 | 4194304 |
| models/bl_sr_folse_stick/bl_sr_folse_stick_normal.png | normal | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 28582 | 4194304 |
| models/bl_sr_folse_stick/bl_sr_folse_stick_orm.png | items 3D | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 5380 | 4194304 |
| models/bl_tt_lomein/bl_tt_lomein_albedo.png | items 3D | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 628572 | 4194304 |
| models/bl_tt_lomein/bl_tt_lomein_normal.png | normal | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 750334 | 4194304 |
| models/bl_tt_lomein/bl_tt_lomein_orm.png | items 3D | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 413102 | 4194304 |
| models/bl_wl_coffee/bl_wl_coffee_albedo.png | items 3D | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 591092 | 4194304 |
| models/bl_wl_coffee/bl_wl_coffee_normal.png | normal | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 35338 | 4194304 |
| models/bl_wl_coffee/bl_wl_coffee_orm.png | items 3D | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 268696 | 4194304 |
| models/bl_wl_rootbeer_float/bl_wl_rootbeer_float_albedo.png | items 3D | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 490224 | 4194304 |
| models/bl_wl_rootbeer_float/bl_wl_rootbeer_float_normal.png | normal | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 438114 | 4194304 |
| models/bl_wl_rootbeer_float/bl_wl_rootbeer_float_orm.png | items 3D | webp-lossless | RGB8 | 1024x1024 | 0 | 1 | 331788 | 4194304 |
| models/bl_dir_finial/bl_dir_finial_albedo.png | items 3D | webp-lossless | RGB8 | 512x512 | 0 | 1 | 105316 | 1048576 |
| models/bl_dir_finial/bl_dir_finial_normal.png | normal | webp-lossless | RGB8 | 512x512 | 0 | 1 | 73654 | 1048576 |
| models/bl_dir_finial/bl_dir_finial_orm.png | items 3D | webp-lossless | RGB8 | 512x512 | 0 | 1 | 136044 | 1048576 |
| models/bl_gb_lavalamp/bl_gb_lavalamp_albedo.png | items 3D | webp-lossless | RGB8 | 512x512 | 0 | 1 | 18610 | 1048576 |
| models/bl_gb_lavalamp/bl_gb_lavalamp_normal.png | normal | webp-lossless | RGB8 | 512x512 | 0 | 1 | 1448 | 1048576 |
| models/bl_gb_lavalamp/bl_gb_lavalamp_orm.png | items 3D | webp-lossless | RGB8 | 512x512 | 0 | 1 | 52894 | 1048576 |
| models/bl_gi_capybara/bl_gi_capybara_albedo.png | items 3D | webp-lossless | RGB8 | 512x512 | 0 | 1 | 209812 | 1048576 |
| models/bl_gi_capybara/bl_gi_capybara_normal.png | normal | webp-lossless | RGB8 | 512x512 | 0 | 1 | 331152 | 1048576 |
| models/bl_gi_capybara/bl_gi_capybara_orm.png | items 3D | webp-lossless | RGB8 | 512x512 | 0 | 1 | 108902 | 1048576 |
| models/bl_gi_doughball/bl_gi_doughball_albedo.png | items 3D | webp-lossless | RGB8 | 512x512 | 0 | 1 | 71012 | 1048576 |
| models/bl_gi_doughball/bl_gi_doughball_normal.png | normal | webp-lossless | RGB8 | 512x512 | 0 | 1 | 77396 | 1048576 |
| models/bl_gi_doughball/bl_gi_doughball_orm.png | items 3D | webp-lossless | RGB8 | 512x512 | 0 | 1 | 6510 | 1048576 |
| models/bl_gi_squish/bl_gi_squish_albedo.png | items 3D | webp-lossless | RGB8 | 512x512 | 0 | 1 | 143244 | 1048576 |
| models/bl_gi_squish/bl_gi_squish_normal.png | normal | webp-lossless | RGB8 | 512x512 | 0 | 1 | 215656 | 1048576 |
| models/bl_gi_squish/bl_gi_squish_orm.png | items 3D | webp-lossless | RGB8 | 512x512 | 0 | 1 | 62040 | 1048576 |
| models/bl_pc_blaster/bl_pc_blaster_albedo.png | items 3D | webp-lossless | RGB8 | 512x512 | 0 | 1 | 111698 | 1048576 |
| models/bl_pc_blaster/bl_pc_blaster_normal.png | normal | webp-lossless | RGB8 | 512x512 | 0 | 1 | 86518 | 1048576 |
| models/bl_pc_blaster/bl_pc_blaster_orm.png | items 3D | webp-lossless | RGB8 | 512x512 | 0 | 1 | 91884 | 1048576 |
| models/bl_pc_koosh/bl_pc_koosh_albedo.png | items 3D | webp-lossless | RGB8 | 512x512 | 0 | 1 | 269012 | 1048576 |
| models/bl_pc_koosh/bl_pc_koosh_normal.png | normal | webp-lossless | RGB8 | 512x512 | 0 | 1 | 1228 | 1048576 |
| models/bl_pc_koosh/bl_pc_koosh_orm.png | items 3D | webp-lossless | RGB8 | 512x512 | 0 | 1 | 116186 | 1048576 |
| models/bl_pc_plasma/bl_pc_plasma_albedo.png | items 3D | webp-lossless | RGB8 | 512x512 | 0 | 1 | 18856 | 1048576 |
| models/bl_pc_plasma/bl_pc_plasma_normal.png | normal | webp-lossless | RGB8 | 512x512 | 0 | 1 | 5982 | 1048576 |
| models/bl_pc_plasma/bl_pc_plasma_orm.png | items 3D | webp-lossless | RGB8 | 512x512 | 0 | 1 | 45688 | 1048576 |
| models/bl_pc_plush_bear/bl_pc_plush_bear_albedo.png | items 3D | webp-lossless | RGB8 | 512x512 | 0 | 1 | 214128 | 1048576 |
| models/bl_pc_plush_bear/bl_pc_plush_bear_normal.png | normal | webp-lossless | RGB8 | 512x512 | 0 | 1 | 402964 | 1048576 |
| models/bl_pc_plush_bear/bl_pc_plush_bear_orm.png | items 3D | webp-lossless | RGB8 | 512x512 | 0 | 1 | 113230 | 1048576 |
| models/bl_pc_plush_bunny/bl_pc_plush_bunny_albedo.png | items 3D | webp-lossless | RGB8 | 512x512 | 0 | 1 | 217448 | 1048576 |
| models/bl_pc_plush_bunny/bl_pc_plush_bunny_normal.png | normal | webp-lossless | RGB8 | 512x512 | 0 | 1 | 404288 | 1048576 |
| models/bl_pc_plush_bunny/bl_pc_plush_bunny_orm.png | items 3D | webp-lossless | RGB8 | 512x512 | 0 | 1 | 122196 | 1048576 |
| models/bl_pc_plush_dog/bl_pc_plush_dog_albedo.png | items 3D | webp-lossless | RGB8 | 512x512 | 0 | 1 | 218518 | 1048576 |
| models/bl_pc_plush_dog/bl_pc_plush_dog_normal.png | normal | webp-lossless | RGB8 | 512x512 | 0 | 1 | 404058 | 1048576 |
| models/bl_pc_plush_dog/bl_pc_plush_dog_orm.png | items 3D | webp-lossless | RGB8 | 512x512 | 0 | 1 | 119080 | 1048576 |
| models/bl_pc_troll/bl_pc_troll_albedo.png | items 3D | webp-lossless | RGB8 | 512x512 | 0 | 1 | 152508 | 1048576 |
| models/bl_pc_troll/bl_pc_troll_normal.png | normal | webp-lossless | RGB8 | 512x512 | 0 | 1 | 156674 | 1048576 |
| models/bl_pc_troll/bl_pc_troll_orm.png | items 3D | webp-lossless | RGB8 | 512x512 | 0 | 1 | 101110 | 1048576 |
| models/bl_pc_yoyo/bl_pc_yoyo_albedo.png | items 3D | webp-lossless | RGB8 | 512x512 | 0 | 1 | 76472 | 1048576 |
| models/bl_pc_yoyo/bl_pc_yoyo_normal.png | normal | webp-lossless | RGB8 | 512x512 | 0 | 1 | 30822 | 1048576 |
| models/bl_pc_yoyo/bl_pc_yoyo_orm.png | items 3D | webp-lossless | RGB8 | 512x512 | 0 | 1 | 65306 | 1048576 |
| models/bl_standin_rs_cell_phone/standin_rs_cell_phone_front.png | items 3D | webp-lossless | RGB8 | 256x791 | 0 | 1 | 1546 | 809984 |
| models/bl_standin_rs_corded_phone/standin_rs_corded_phone_front.png | items 3D | webp-lossless | RGB8 | 256x563 | 0 | 1 | 1284 | 576512 |
| prizes/ball.png | ui | webp-lossless | RGB8 | 512x256 | 0 | 1 | 15580 | 524288 |
| models/bl_standin_rs_9v_battery/standin_rs_9v_battery_front.png | items 3D | webp-lossless | RGB8 | 256x438 | 0 | 1 | 2716 | 448512 |
| models/bl_standin_rs_c_batteries/standin_rs_c_batteries_front.png | items 3D | webp-lossless | RGB8 | 256x398 | 0 | 1 | 2574 | 407552 |
| prizes/die.png | ui | webp-lossless | RGB8 | 384x256 | 0 | 1 | 10654 | 393216 |
| prizes/pog_card.png | ui | webp-lossless | RGB8 | 256x384 | 0 | 1 | 2214 | 393216 |
| models/bl_standin_rs_ic_card/standin_rs_ic_card_front.png | items 3D | webp-lossless | RGB8 | 256x384 | 0 | 1 | 2176 | 393216 |
| models/bl_standin_rs_plug_adapter/standin_rs_plug_adapter_front.png | items 3D | webp-lossless | RGB8 | 256x384 | 0 | 1 | 2516 | 393216 |
| models/bl_standin_rs_ac_adapter/standin_rs_ac_adapter_front.png | items 3D | webp-lossless | RGB8 | 256x332 | 0 | 1 | 2000 | 339968 |
| models/bl_aa_nugget_cup/bl_aa_nugget_cup_icon.png | items 3D | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 31802 | 262144 |
| models/bl_bd_adventure_book/bl_bd_adventure_book_icon.png | items 3D | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 46606 | 262144 |
| models/bl_bd_chills_book/bl_bd_chills_book_icon.png | items 3D | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 48844 | 262144 |
| models/bl_bd_dark_room_book/bl_bd_dark_room_book_icon.png | items 3D | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 40890 | 262144 |
| models/bl_bd_mars_book/bl_bd_mars_book_icon.png | items 3D | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 44626 | 262144 |
| models/bl_bd_moby_dick/bl_bd_moby_dick_icon.png | items 3D | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 43326 | 262144 |
| models/bl_bd_paperback/bl_bd_paperback_icon.png | items 3D | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 38348 | 262144 |
| models/bl_cd7_corndog/bl_cd7_corndog_icon.png | items 3D | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 21532 | 262144 |
| models/bl_cd7_crinkle_fries/bl_cd7_crinkle_fries_icon.png | items 3D | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 34782 | 262144 |
| models/bl_cd7_lemonade/bl_cd7_lemonade_icon.png | items 3D | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 24042 | 262144 |
| models/bl_cu_beer/bl_cu_beer_icon.png | items 3D | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 31652 | 262144 |
| models/bl_cu_coupon/bl_cu_coupon_icon.png | items 3D | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 33422 | 262144 |
| models/bl_cu_doubloon/bl_cu_doubloon_icon.png | items 3D | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 38890 | 262144 |
| models/bl_cu_margarita/bl_cu_margarita_icon.png | items 3D | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 27030 | 262144 |
| models/bl_cu_top_shelf_margarita/bl_cu_top_shelf_margarita_icon.png | items 3D | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 34510 | 262144 |
| models/bl_gac_choc_chip_cookie/bl_gac_choc_chip_cookie_icon.png | items 3D | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 23834 | 262144 |
| models/bl_gac_sugarcookie/bl_gac_sugarcookie_icon.png | items 3D | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 21702 | 262144 |
| models/bl_gb_lavalamp/bl_gb_lavalamp_icon.png | items 3D | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 23616 | 262144 |
| models/bl_gi_capybara/bl_gi_capybara_icon.png | items 3D | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 21822 | 262144 |
| models/bl_gi_doughball/bl_gi_doughball_icon.png | items 3D | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 22320 | 262144 |
| models/bl_gi_squish/bl_gi_squish_icon.png | items 3D | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 22304 | 262144 |
| models/bl_kk_caramelcorn/bl_kk_caramelcorn_icon.png | items 3D | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 36206 | 262144 |
| models/bl_oj_cup/bl_oj_cup_icon.png | items 3D | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 23842 | 262144 |
| models/bl_pc_blaster/bl_pc_blaster_icon.png | items 3D | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 23222 | 262144 |
| models/bl_pc_boombox/bl_pc_boombox_icon.png | items 3D | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 27612 | 262144 |
| models/bl_pc_fingertrap/bl_pc_fingertrap_icon.png | items 3D | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 22560 | 262144 |
| models/bl_pc_koosh/bl_pc_koosh_icon.png | items 3D | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 46120 | 262144 |
| models/bl_pc_plasma/bl_pc_plasma_icon.png | items 3D | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 34898 | 262144 |
| models/bl_pc_plush_bear/bl_pc_plush_bear_icon.png | items 3D | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 26112 | 262144 |
| models/bl_pc_plush_bunny/bl_pc_plush_bunny_icon.png | items 3D | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 22626 | 262144 |
| models/bl_pc_plush_dog/bl_pc_plush_dog_icon.png | items 3D | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 24484 | 262144 |
| models/bl_pc_skateboard/bl_pc_skateboard_icon.png | items 3D | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 18142 | 262144 |
| models/bl_pc_troll/bl_pc_troll_icon.png | items 3D | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 27972 | 262144 |
| models/bl_pc_yoyo/bl_pc_yoyo_icon.png | items 3D | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 25536 | 262144 |
| models/bl_rs_battcard/bl_rs_battcard_icon.png | items 3D | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 31276 | 262144 |
| models/bl_rs_cordless/bl_rs_cordless_icon.png | items 3D | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 22358 | 262144 |
| models/bl_rs_pager/bl_rs_pager_icon.png | items 3D | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 35420 | 262144 |
| models/bl_rs_rcbox/bl_rs_rcbox_icon.png | items 3D | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 51300 | 262144 |
| models/bl_rs_scanner/bl_rs_scanner_icon.png | items 3D | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 18920 | 262144 |
| models/bl_rs_walkie/bl_rs_walkie_icon.png | items 3D | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 13836 | 262144 |
| models/bl_sr_folse_stick/bl_sr_folse_stick_icon.png | items 3D | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 9582 | 262144 |
| models/bl_tt_lomein/bl_tt_lomein_icon.png | items 3D | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 27102 | 262144 |
| models/bl_wl_coffee/bl_wl_coffee_icon.png | items 3D | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 24480 | 262144 |
| models/bl_wl_fries/bl_wl_fries_icon.png | items 3D | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 23326 | 262144 |
| models/bl_wl_hamburger/bl_wl_hamburger_icon.png | items 3D | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 24990 | 262144 |
| models/bl_wl_hot_dog/bl_wl_hot_dog_icon.png | items 3D | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 23184 | 262144 |
| models/bl_wl_rootbeer_float/bl_wl_rootbeer_float_icon.png | items 3D | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 21626 | 262144 |
| models/bl_standin_aa_cinnamon_pretzel/standin_aa_cinnamon_pretzel_icon.png | items 3D | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 2102 | 262144 |
| models/bl_standin_aa_lemonade/standin_aa_lemonade_icon.png | items 3D | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 1204 | 262144 |
| models/bl_standin_aa_original_pretzel/standin_aa_original_pretzel_icon.png | items 3D | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 2102 | 262144 |
| models/bl_standin_aa_pretzel_bites/standin_aa_pretzel_bites_icon.png | items 3D | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 1574 | 262144 |
| models/bl_standin_gac_brownie/standin_gac_brownie_icon.png | items 3D | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 1060 | 262144 |
| models/bl_standin_gac_cake_slice/standin_gac_cake_slice_icon.png | items 3D | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 1378 | 262144 |
| models/bl_standin_gac_choc_chip_cookie/standin_gac_choc_chip_cookie_icon.png | items 3D | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 1816 | 262144 |
| models/bl_standin_gac_fountain_drink/standin_gac_fountain_drink_icon.png | items 3D | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 1204 | 262144 |
| models/bl_standin_pay_boots/standin_pay_boots_icon.png | items 3D | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 1282 | 262144 |
| models/bl_standin_pay_pumps/standin_pay_pumps_icon.png | items 3D | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 1322 | 262144 |
| models/bl_standin_pay_sandals/standin_pay_sandals_icon.png | items 3D | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 1400 | 262144 |
| models/bl_standin_pay_shoe_polish/standin_pay_shoe_polish_icon.png | items 3D | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 1506 | 262144 |
| models/bl_standin_pay_sneakers/standin_pay_sneakers_icon.png | items 3D | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 1366 | 262144 |
| models/bl_standin_pay_socks/standin_pay_socks_icon.png | items 3D | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 1144 | 262144 |
| models/bl_standin_rs_9v_battery/standin_rs_9v_battery_icon.png | items 3D | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 4796 | 262144 |
| models/bl_standin_rs_ac_adapter/standin_rs_ac_adapter_icon.png | items 3D | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 3934 | 262144 |
| models/bl_standin_rs_answering_machine/standin_rs_answering_machine_icon.png | items 3D | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 4094 | 262144 |
| models/bl_standin_rs_c_batteries/standin_rs_c_batteries_icon.png | items 3D | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 5506 | 262144 |
| models/bl_standin_rs_cell_phone/standin_rs_cell_phone_icon.png | items 3D | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 2740 | 262144 |
| models/bl_standin_rs_clock_radio/standin_rs_clock_radio_icon.png | items 3D | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 5884 | 262144 |
| models/bl_standin_rs_corded_phone/standin_rs_corded_phone_icon.png | items 3D | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 3016 | 262144 |
| models/bl_standin_rs_ic_card/standin_rs_ic_card_icon.png | items 3D | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 4898 | 262144 |
| models/bl_standin_rs_plug_adapter/standin_rs_plug_adapter_icon.png | items 3D | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 4988 | 262144 |
| models/bl_standin_rs_speaker_wire/standin_rs_speaker_wire_icon.png | items 3D | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 2420 | 262144 |
| models/bl_standin_sp_mug/standin_sp_mug_icon.png | items 3D | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 2654 | 262144 |
| models/bl_standin_sp_plush/standin_sp_plush_icon.png | items 3D | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 1650 | 262144 |
| models/bl_standin_sp_stickers/standin_sp_stickers_icon.png | items 3D | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 2576 | 262144 |
| models/bl_standin_sp_tee/standin_sp_tee_icon.png | items 3D | webp-lossless | RGBA8 | 256x256 | 0 | 1 | 2966 | 262144 |
| prizes/candy_box.png | ui | webp-lossless | RGB8 | 192x288 | 0 | 1 | 132 | 221184 |
| prizes/tag.png | ui | webp-lossless | RGB8 | 256x204 | 0 | 1 | 144 | 208896 |
| prizes/box_arcade.png | ui | webp-lossless | RGB8 | 192x256 | 0 | 1 | 592 | 196608 |
| prizes/box_cassette.png | ui | webp-lossless | RGB8 | 192x256 | 0 | 1 | 996 | 196608 |
| prizes/box_console.png | ui | webp-lossless | RGB8 | 192x256 | 0 | 1 | 504 | 196608 |
| prizes/box_earbuds.png | ui | webp-lossless | RGB8 | 192x256 | 0 | 1 | 702 | 196608 |
| prizes/box_handheld.png | ui | webp-lossless | RGB8 | 192x256 | 0 | 1 | 654 | 196608 |
| prizes/box_headphones.png | ui | webp-lossless | RGB8 | 192x256 | 0 | 1 | 1006 | 196608 |
| prizes/box_lcd.png | ui | webp-lossless | RGB8 | 192x256 | 0 | 1 | 774 | 196608 |
| prizes/box_ledstrip.png | ui | webp-lossless | RGB8 | 192x256 | 0 | 1 | 978 | 196608 |
| prizes/box_phonestand.png | ui | webp-lossless | RGB8 | 192x256 | 0 | 1 | 476 | 196608 |
| prizes/box_projector.png | ui | webp-lossless | RGB8 | 192x256 | 0 | 1 | 1122 | 196608 |
| prizes/box_rc.png | ui | webp-lossless | RGB8 | 192x256 | 0 | 1 | 1182 | 196608 |
| prizes/box_speaker.png | ui | webp-lossless | RGB8 | 192x256 | 0 | 1 | 688 | 196608 |
| prizes/box_walkie.png | ui | webp-lossless | RGB8 | 192x256 | 0 | 1 | 734 | 196608 |
| models/bl_standin_rs_answering_machine/standin_rs_answering_machine_front.png | items 3D | webp-lossless | RGB8 | 256x191 | 0 | 1 | 1284 | 195584 |
| prizes/gtag.png | ui | webp-lossless | RGB8 | 256x160 | 0 | 1 | 146 | 163840 |
| models/bl_standin_rs_clock_radio/standin_rs_clock_radio_front.png | items 3D | webp-lossless | RGB8 | 256x128 | 0 | 1 | 2266 | 131072 |
| prizes/blister.png | ui | webp-lossless | RGB8 | 128x192 | 0 | 1 | 1624 | 98304 |
| prizes/stickers.png | ui | webp-lossless | RGB8 | 128x192 | 0 | 1 | 1136 | 98304 |
| prizes/foil.png | ui | webp-lossless | RGB8 | 128x128 | 0 | 1 | 2550 | 65536 |
| prizes/chew.png | ui | webp-lossless | RGB8 | 128x64 | 0 | 1 | 176 | 32768 |
| prizes/rainbow.png | ui | webp-lossless | RGB8 | 32x256 | 0 | 1 | 196 | 32768 |
| prizes/slap0.png | ui | webp-lossless | RGB8 | 256x32 | 0 | 1 | 178 | 32768 |
| prizes/slap1.png | ui | webp-lossless | RGB8 | 256x32 | 0 | 1 | 620 | 32768 |
| prizes/slap2.png | ui | webp-lossless | RGB8 | 256x32 | 0 | 1 | 466 | 32768 |
| prizes/slap3.png | ui | webp-lossless | RGB8 | 256x32 | 0 | 1 | 152 | 32768 |
| prizes/swirl.png | ui | webp-lossless | RGB8 | 128x64 | 0 | 1 | 198 | 32768 |
| prizes/weave.png | ui | webp-lossless | RGB8 | 64x128 | 0 | 1 | 216 | 32768 |
| prizes/wrapper.png | ui | webp-lossless | RGB8 | 128x64 | 0 | 1 | 150 | 32768 |
| prizes/emoji.png | ui | webp-lossless | RGBA8 | 64x64 | 0 | 1 | 406 | 16384 |
| prizes/stripes.png | ui | webp-lossless | RGB8 | 32x128 | 0 | 1 | 112 | 16384 |
| prizes/vpet_screen.png | ui | webp-lossless | RGB8 | 64x56 | 0 | 1 | 174 | 14336 |

