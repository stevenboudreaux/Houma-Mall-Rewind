# Framed newspaper ads on the bare walls (Godot mall, since Demo 25, Oct 14 2026)

**Asked for (Steven, Oct 14):** Courier ads he found for the mall's stores, "posted like posters
around the mall and put in a frame, but the frame is dynamic and wraps around the dimensions of
the actual file", sprinkled on the bare walls, "especially the Sears wing", and on the side of
Franks.

## What's built (`tools/stores/posters/posters.gd`, `tex/ads/*.png`)
- Nine ads, each at most 1024 px on its long side: Gumballs' ribbon cutting (Courier
  "Advertising News"), Dippin' Dots ("Now open in Southland Mall"), TGMC OutReach's community
  calendar, Radiofone pagers, Vision Plaza, Gryder's Shoes (Rockport), Concepts (Eastpak),
  Scatterbar's Buffet, Saadi's haberdashery.
- Each poster: a black anodised frame built to the ad's own aspect (the print's longer side is
  1.15 m), a white mat 6 cm wide, the print on matte paper, centre 1.55 m up. The frame rails are
  4.5 cm wide and 3.2 cm proud of the wall.
- The print and the mat carry a little emission (0.55 / 0.4 at night, 0.35 / 0.25 by day), because
  dynamic meshes get no lightmap and would read black at night; it looks like downlight on paper.
- Placement, as fractions along a plain wall of the layout (`PLACES`): the Sears hall west's
  north wall (Gryder's, TGMC, Saadi's), its south wall east of the court (Vision Plaza, Concepts),
  the Sears hall east's south wall (Radiofone, Scatterbar's), and Franks' side wall on the east
  hall under the neon (Dippin' Dots, Gumballs).
- Dynamic geometry in the wing's `dyn_posters.res`: no rebake. A wall missing from the layout is
  skipped with a warning.

## The owner's own pictures (Nov 4 2026)
In owner mode, Edit pictures (menu, OWNER) puts the owner's own picture on any of these ads (id
`ad.<name>`), with a new frame wrapped round the picture's aspect, and on poster / ad panels elsewhere;
Publish pictures writes `play/posters/` and `play/posters.json`. design/godot-owner-mode.md "Pictures".

## Period and tenancy notes
- Scatterbar's (1832 West Park) and Radiofone (Houma office) were not mall tenants; Steven sent
  them with the rest. Pull them from `PLACES` if he says so.
- The ads span 1987–1996; the mall's year maps run 1993–1996. Dates printed in the ads are left
  as they are (they are the real clippings).
- The Dec 24, 1987 Courier page he also sent (Palin's Tire, Betty White Jewelers, South Coast
  Gas, South Louisiana Bank) carries no mall-store ad and was not used.
