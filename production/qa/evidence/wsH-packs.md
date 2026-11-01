# wsH: what is inside the desktop and mobile packs (Nov 1, 2026)

Live build on `godot-build` (Demo 46, exported Oct 29), read with `tools/qa/packformats.py`. Each family line: files and MB of the textures stored that way. Full per-file listing of the outside (w3) at the end.

```
83655532 w1.desktop.pck
83655532 w1.mobile.pck
20714840 w1y26.desktop.pck
20714840 w1y26.mobile.pck
80427500 w2.desktop.pck
80427500 w2.mobile.pck
51558108 w2y26.desktop.pck
51558108 w2y26.mobile.pck
12638232 w3.desktop.pck
12638232 w3.mobile.pck

w1.desktop.pck  (Godot 4.7.2 pack, 688 files, 83.6 MB; textures 55.0 MB)
  s3tc         51 files     27.9 MB
  lossless    152 files     20.9 MB
  bptc          1 files      6.3 MB
w1.mobile.pck  (Godot 4.7.2 pack, 688 files, 83.6 MB; textures 55.0 MB)
  etc2         51 files     27.9 MB
  lossless    152 files     20.9 MB
  astc          1 files      6.3 MB
w1y26.desktop.pck  (Godot 4.7.2 pack, 176 files, 20.7 MB; textures 12.6 MB)
  lossless     16 files      6.5 MB
  s3tc          8 files      4.0 MB
  bptc          1 files      2.1 MB
w1y26.mobile.pck  (Godot 4.7.2 pack, 176 files, 20.7 MB; textures 12.6 MB)
  lossless     16 files      6.5 MB
  etc2          8 files      4.0 MB
  astc          1 files      2.1 MB
w2.desktop.pck  (Godot 4.7.2 pack, 914 files, 80.3 MB; textures 47.3 MB)
  s3tc         51 files     28.0 MB
  lossless    143 files     11.0 MB
  bptc          1 files      5.2 MB
  lossy       130 files      3.0 MB
w2.mobile.pck  (Godot 4.7.2 pack, 914 files, 80.3 MB; textures 47.3 MB)
  etc2         51 files     28.0 MB
  lossless    143 files     11.0 MB
  astc          1 files      5.2 MB
  lossy       130 files      3.0 MB
w2y26.desktop.pck  (Godot 4.7.2 pack, 506 files, 51.5 MB; textures 23.1 MB)
  lossless     84 files     12.0 MB
  s3tc         16 files      5.7 MB
  bptc          1 files      3.1 MB
  lossy        80 files      2.3 MB
w2y26.mobile.pck  (Godot 4.7.2 pack, 506 files, 51.5 MB; textures 23.1 MB)
  lossless     84 files     12.0 MB
  etc2         16 files      5.7 MB
  astc          1 files      3.1 MB
  lossy        80 files      2.3 MB
w3.desktop.pck  (Godot 4.7.2 pack, 145 files, 12.6 MB; textures 8.2 MB)
  lossless     17 files      3.5 MB
  bptc          1 files      3.1 MB
  s3tc          5 files      1.6 MB
w3.mobile.pck  (Godot 4.7.2 pack, 145 files, 12.6 MB; textures 8.2 MB)
  lossless     17 files      3.5 MB
  astc          1 files      3.1 MB
  etc2          5 files      1.6 MB
```

## Same textures, other format: per wing, files only in one pack, and shared paths with identical bytes

```
w1: desktop-only 52, mobile-only 52 (same textures in the other format: True); shared paths 636, of which differ 52: ['import']
w2: desktop-only 52, mobile-only 52 (same textures in the other format: True); shared paths 862, of which differ 52: ['import']
w3: desktop-only 6, mobile-only 6 (same textures in the other format: True); shared paths 139, of which differ 6: ['import']
w1y26: desktop-only 9, mobile-only 9 (same textures in the other format: True); shared paths 167, of which differ 9: ['import']
w2y26: desktop-only 17, mobile-only 17 (same textures in the other format: True); shared paths 489, of which differ 17: ['import']
```

## w3 per file

```
w3.desktop.pck  (Godot 4.7.2 pack, 145 files, 12.6 MB; textures 8.2 MB)
  lossless     17 files      3.5 MB
  bptc          1 files      3.1 MB
  s3tc          5 files      1.6 MB
    bptc      ?            layered     0x0     mips=0    3145812  .godot/imported/wing3_day.exr-9e64380e743701b47d44d91bbd3bdbf9.bptc.ctexarray
    lossless  RGB8         webp-lossless  1024x1024  mips=0     673120  .godot/imported/concrete_panel.png-cad5a5677115b4111d6c7396e26433d1.ctex
    s3tc      DXT5         image     256x1024  mips=10    349636  .godot/imported/palm_frond.png-6af3cecc3a4c5be7d191af19b4583d0c.s3tc.ctex
    s3tc      DXT5         image     512x512   mips=9     349604  .godot/imported/leafy.png-b5b061fb91a2e1e3d3097365b9ec0694.s3tc.ctex
    s3tc      DXT5         image     512x512   mips=9     349604  .godot/imported/poinsettia.png-bff706a92009cc4aa76c72cd67e58149.s3tc.ctex
    s3tc      DXT1         image    1024x512   mips=10    349596  .godot/imported/int_side.png-611f0223e4c2be2e9664612fd4dc84da.s3tc.ctex
    lossless  RGB8         webp-lossless  1024x1024  mips=0     301676  .godot/imported/brick_cream.png-77d7660b532c3985d504b6b609fe8626.ctex
    lossless  RGB8         webp-lossless  1024x1024  mips=0     282912  .godot/imported/block_white.png-69ef7c100f7e161b29a0e9b42e917317.ctex
    lossless  RGB8         webp-lossless  1024x1024  mips=0     278094  .godot/imported/brick_brown.png-e19fde9da945d4228505c2e2a8c73bc2.ctex
    lossless  RGB8         webp-lossless  1024x1024  mips=0     277270  .godot/imported/brick_red.png-27c65cf2a53a6e314424e7c35b1d5785.ctex
    lossless  RGB8         webp-lossless  1024x1024  mips=0     277052  .godot/imported/brick_salmon.png-076b69acf6bc9ef57bed44ce154ba14d.ctex
    lossless  RGB8         webp-lossless  1024x1024  mips=0     275284  .godot/imported/brick_tan.png-25f7b7fa460ec80b466f97c2eabb463a.ctex
    lossless  RGB8         webp-lossless   512x512   mips=0     198568  .godot/imported/aggregate.png-2e2e730ab17b76cf0f39ee42bed00e35.ctex
    s3tc      DXT1         image     512x512   mips=9     174828  .godot/imported/wood_dark.png-97a9b72083820525157a0db40bf94df1.s3tc.ctex
    lossless  RGB8         webp-lossless   512x512   mips=0     165596  .godot/imported/mulch.png-1291b8ba0eaa7a191a65b4731f50c634.ctex
    lossless  RGB8         webp-lossless   512x512   mips=0     159672  .godot/imported/grass.png-a736be43aa22f66013b8e75907877704.ctex
    lossless  RGB8         webp-lossless   512x512   mips=0     144024  .godot/imported/asphalt.png-c989bf760b7586688f4018135915c948.ctex
    lossless  RGB8         webp-lossless   512x512   mips=0     117910  .godot/imported/stucco_tan.png-66c54ea388a2a20bb87d4dbd4a7cb366.ctex
    lossless  RGB8         webp-lossless   512x512   mips=0     115168  .godot/imported/stucco_cream.png-d14a3bc08458ef59238de3d189fe746e.ctex
    lossless  RGB8         webp-lossless   512x512   mips=0     114962  .godot/imported/stucco_peach.png-34574ba5e62e9b2afec81419df2870ae.ctex
    lossless  RGB8         webp-lossless  1024x1024  mips=0      56112  .godot/imported/video_marquees_blank.png-bfd67d58debfbf3caadd72326840f0fc.ctex
    lossless  RGB8         webp-lossless   512x128   mips=0      30414  .godot/imported/dept_blank.png-cffe360a67f80ae2626fa8307c55c77c.ctex
    lossless  RGBA8        webp-lossless   256x256   mips=0       2204  .godot/imported/chainlink.png-65cf2bcdc777acb2d31056160b74046c.ctex
w3.mobile.pck  (Godot 4.7.2 pack, 145 files, 12.6 MB; textures 8.2 MB)
  lossless     17 files      3.5 MB
  astc          1 files      3.1 MB
  etc2          5 files      1.6 MB
    astc      ?            layered     0x0     mips=0    3145812  .godot/imported/wing3_day.exr-9e64380e743701b47d44d91bbd3bdbf9.astc.ctexarray
    lossless  RGB8         webp-lossless  1024x1024  mips=0     673120  .godot/imported/concrete_panel.png-cad5a5677115b4111d6c7396e26433d1.ctex
    etc2      ETC2_RGBA8   image     256x1024  mips=10    349636  .godot/imported/palm_frond.png-6af3cecc3a4c5be7d191af19b4583d0c.etc2.ctex
    etc2      ETC2_RGBA8   image     512x512   mips=9     349604  .godot/imported/leafy.png-b5b061fb91a2e1e3d3097365b9ec0694.etc2.ctex
    etc2      ETC2_RGBA8   image     512x512   mips=9     349604  .godot/imported/poinsettia.png-bff706a92009cc4aa76c72cd67e58149.etc2.ctex
    etc2      ETC2_RGB8    image    1024x512   mips=10    349596  .godot/imported/int_side.png-611f0223e4c2be2e9664612fd4dc84da.etc2.ctex
    lossless  RGB8         webp-lossless  1024x1024  mips=0     301676  .godot/imported/brick_cream.png-77d7660b532c3985d504b6b609fe8626.ctex
    lossless  RGB8         webp-lossless  1024x1024  mips=0     282912  .godot/imported/block_white.png-69ef7c100f7e161b29a0e9b42e917317.ctex
    lossless  RGB8         webp-lossless  1024x1024  mips=0     278094  .godot/imported/brick_brown.png-e19fde9da945d4228505c2e2a8c73bc2.ctex
    lossless  RGB8         webp-lossless  1024x1024  mips=0     277270  .godot/imported/brick_red.png-27c65cf2a53a6e314424e7c35b1d5785.ctex
    lossless  RGB8         webp-lossless  1024x1024  mips=0     277052  .godot/imported/brick_salmon.png-076b69acf6bc9ef57bed44ce154ba14d.ctex
    lossless  RGB8         webp-lossless  1024x1024  mips=0     275284  .godot/imported/brick_tan.png-25f7b7fa460ec80b466f97c2eabb463a.ctex
    lossless  RGB8         webp-lossless   512x512   mips=0     198568  .godot/imported/aggregate.png-2e2e730ab17b76cf0f39ee42bed00e35.ctex
    etc2      ETC2_RGB8    image     512x512   mips=9     174828  .godot/imported/wood_dark.png-97a9b72083820525157a0db40bf94df1.etc2.ctex
    lossless  RGB8         webp-lossless   512x512   mips=0     165596  .godot/imported/mulch.png-1291b8ba0eaa7a191a65b4731f50c634.ctex
    lossless  RGB8         webp-lossless   512x512   mips=0     159672  .godot/imported/grass.png-a736be43aa22f66013b8e75907877704.ctex
    lossless  RGB8         webp-lossless   512x512   mips=0     144024  .godot/imported/asphalt.png-c989bf760b7586688f4018135915c948.ctex
    lossless  RGB8         webp-lossless   512x512   mips=0     117910  .godot/imported/stucco_tan.png-66c54ea388a2a20bb87d4dbd4a7cb366.ctex
    lossless  RGB8         webp-lossless   512x512   mips=0     115168  .godot/imported/stucco_cream.png-d14a3bc08458ef59238de3d189fe746e.ctex
    lossless  RGB8         webp-lossless   512x512   mips=0     114962  .godot/imported/stucco_peach.png-34574ba5e62e9b2afec81419df2870ae.ctex
    lossless  RGB8         webp-lossless  1024x1024  mips=0      56112  .godot/imported/video_marquees_blank.png-bfd67d58debfbf3caadd72326840f0fc.ctex
    lossless  RGB8         webp-lossless   512x128   mips=0      30414  .godot/imported/dept_blank.png-cffe360a67f80ae2626fa8307c55c77c.ctex
    lossless  RGBA8        webp-lossless   256x256   mips=0       2204  .godot/imported/chainlink.png-65cf2bcdc777acb2d31056160b74046c.ctex
```

## tools/qa/packtest.py on this branch's export (Nov 1, 2026)

```
phone_gpu picked mobile want mobile remembered None errors 0 OK
desktop_gpu picked desktop want desktop remembered None errors 0 OK
wrong_guess picked mobile want mobile remembered mobile errors 0 OK
ALL OK
```

## This branch's export: same split

```
w1.desktop.pck  (Godot 4.7.2 pack, 691 files, 83.6 MB; textures 55.0 MB)
  s3tc         51 files     27.9 MB
  lossless    152 files     20.9 MB
  bptc          1 files      6.3 MB
w1.mobile.pck  (Godot 4.7.2 pack, 691 files, 83.6 MB; textures 55.0 MB)
  etc2         51 files     27.9 MB
  lossless    152 files     20.9 MB
  astc          1 files      6.3 MB
w1y26.desktop.pck  (Godot 4.7.2 pack, 179 files, 20.7 MB; textures 12.6 MB)
  lossless     16 files      6.5 MB
  s3tc          8 files      4.0 MB
  bptc          1 files      2.1 MB
w1y26.mobile.pck  (Godot 4.7.2 pack, 179 files, 20.7 MB; textures 12.6 MB)
  lossless     16 files      6.5 MB
  etc2          8 files      4.0 MB
  astc          1 files      2.1 MB
w2.desktop.pck  (Godot 4.7.2 pack, 917 files, 80.4 MB; textures 47.3 MB)
  s3tc         51 files     28.0 MB
  lossless    143 files     11.0 MB
  bptc          1 files      5.2 MB
  lossy       130 files      3.0 MB
w2.mobile.pck  (Godot 4.7.2 pack, 917 files, 80.4 MB; textures 47.3 MB)
  etc2         51 files     28.0 MB
  lossless    143 files     11.0 MB
  astc          1 files      5.2 MB
  lossy       130 files      3.0 MB
w2y26.desktop.pck  (Godot 4.7.2 pack, 509 files, 51.5 MB; textures 23.1 MB)
  lossless     84 files     12.0 MB
  s3tc         16 files      5.7 MB
  bptc          1 files      3.1 MB
  lossy        80 files      2.3 MB
w2y26.mobile.pck  (Godot 4.7.2 pack, 509 files, 51.5 MB; textures 23.1 MB)
  lossless     84 files     12.0 MB
  etc2         16 files      5.7 MB
  astc          1 files      3.1 MB
  lossy        80 files      2.3 MB
w3.desktop.pck  (Godot 4.7.2 pack, 148 files, 12.6 MB; textures 8.2 MB)
  lossless     17 files      3.5 MB
  bptc          1 files      3.1 MB
  s3tc          5 files      1.6 MB
w3.mobile.pck  (Godot 4.7.2 pack, 148 files, 12.6 MB; textures 8.2 MB)
  lossless     17 files      3.5 MB
  astc          1 files      3.1 MB
  etc2          5 files      1.6 MB
```
