"""Build the 2026 store list (same format as mall-data stores / eras) from the 1995 list
plus the site-visit findings. Output: eras_2026.json (store list), map_2026.md (table)."""
import json, copy

S95 = {s['id']: s for s in json.load(open('stores_1995_full.json'))}
VAC_BG, VAC_FG = "#8d8a80", "#d8d4c8"

# id -> change dict. Keys: name, sign, bg, fg, rect (x,y,w,h), face, face2, vacant, drop (list of absorbed ids),
# conf, note, src (clips). Unlisted ids are carried over unchanged.
CH = {}
def ch(id, **kw): CH[id] = kw
NEW = []  # new entries (re-cuts that need a new id)
def new(id, base, **kw): NEW.append((id, base, kw))

# --- anchors, exits ---
ch('s1', name="LYNN'S INTERIORS", sign="LYNN'S\nINTERIORS", bg="#ffffff", fg="#111111", conf="high",
   note="Furniture/appliances/mattresses in the whole Sears box; single level, 9 m column grid", src="4408-4413")
ch('s6', sign="JCPenney", bg="#cc0000", fg="#ffffff", conf="high", note="Modern red mixed-case logo on rosso marble (mall side) / white brick (exterior)", src="4457,4486")
ch('s2', bg="#c9a66b", fg="#ffffff", conf="high", note="White backlit serif on light-oak panel; cast-iron gallery outside", src="4438,4490")
ch('s43', name="EAST ENTRANCE", sign="EAST\nENTRANCE", conf="high", note="Peach fascia, gold deco fan, curved eyebrow canopy", src="4406")
# --- Sears hall (H1a/H1b) ---
ch('s40', vacant=True, conf="high", note="Closed cinema; cream panel + grey-green trim front, blind brick arches intact", src="4414,4485")
ch('s42', name="THE RED SEAL PIZZERIA & BAR", sign="THE RED SEAL", bg="#ffffff", fg="#c8202c", conf="high",
   note="White skip-trowel stucco, black brick pilasters, red awnings, garage doors; neon beer signs", src="4406,4407,4493")
ch('n8', vacant=True, conf="medium", note="Zig-zag black smoked-glass front (post-1995 re-face), wraps the court corner", src="4408")
ch('s29ab', vacant=True, conf="high", note="Walled; white faux-brick semicircular arch survives", src="4485")
ch('n9', rect=(130, 60, 13, 8), drop=['n10'], vacant=True, conf="medium",
   note="Rave + Lane Bryant merged into one large vacant (white metal-panel bulkhead, 15 m grille)", src="4484")
# --- H2 west side ---
ch('s19', name="SOLA CENTER FOR THE ARTS", sign="SOLA", bg="#111111", fg="#e14fa0", conf="high",
   note="Original Sound Shop black curved fascia, black round pillars, black tile threshold intact", src="4484")
ch('s18', name="PRIME TIME FITNESS", sign="PRIME TIME\nFITNESS", bg="#ffffff", fg="#111111", conf="high",
   note="Black script + 4 stars on white tile S-wave band; closed", src="4484")
ch('s17', name="INSPIRED 2 DANCE", sign="INSPIRED 2 DANCE", bg="#2a9d9f", fg="#ffffff", conf="low-med",
   note="Teal fascia with dancer decal; name inferred from banner seen through Hypervelocity", src="4484")
ch('s16', rect=(122, 80, 21, 9), drop=['s15'], vacant=True, conf="low",
   note="Jean Nicole + Kids Mart = royal-blue painted box with star lights, 12 m", src="4484")
ch('s13', name="THE BILLIARD ROOM", sign="THE BILLIARD ROOM", bg="#111111", fg="#d4af37", rect=(111, 89, 32, 16), drop=['s14'],
   conf="med-high", note="Pool hall + APL dart room; Woolworth north part + Footaction. Gold serif on black box", src="4484,4492,4434")
new('s10a', 's10', name="AÉROPOSTALE", sign="AÉROPOSTALE", bg="#111111", fg="#e3211c", rect=(123, 105, 20, 5), face="E",
    conf="low-med", note="Black riveted steel portal, red letters; ~9 m front on the west side of C2/H4 (directory: yellow zone)", src="4476-4483,4492")
ch('s10', name="RAINBOW", sign="Rainbow", bg="#ffffff", fg="#1f6fd1", rect=(123, 110, 20, 5), conf="low-med",
   note="Ex-American Eagle (brass 'A E' floor inlay). White beadboard, blue script, ~12 m", src="4492,4482")
new('s10b', 's10', name="GNC", sign="GNC", bg="#ffffff", fg="#111111", rect=(123, 115, 20, 3), face="E",
    conf="low-med", note="Steel 'GNC Live Well' box sign, frameless glass; south end of old Lerner", src="4477")
ch('s44', vacant=True, conf="low", note="2-bay vacant, tan wood-grain tile pilasters", src="4439")
ch('smuopv1vy0', name="GREAT AMERICAN COOKIES", sign="GREAT AMERICAN\nCOOKIES", bg="#ffffff", fg="#c8202c", conf="med-high",
   note="Same tenant; white wave wall, red/LED fascia", src="4438,4439")
ch('s8b', name="LIDS", sign="LIDS", bg="#1b2a5e", fg="#ffffff", conf="medium", note="Navy fascia, arched opening; faces Dillard's across C3", src="4438,4491")
ch('s8', name="DJS JEWELERS", sign="DJS JEWELERS", bg="#111111", fg="#d4af37", conf="medium", note="Black fascia, gold letters, olive-brown panels, travertine base", src="4438,4477")
# --- concourse north row (pink) ---
ch('n36', name="MAURICES", sign="maurices", bg="#ffffff", fg="#1a9c9c", conf="medium", note="Teal scalloped awnings over full glass", src="4439")
ch('n35', name="SPENCER'S", sign="SPENCER'S", bg="#5a2a1a", fg="#ffffff", conf="medium", note="Faux red brick, graffiti roll-door sign", src="4440")
ch('n34', bg="#9a9a9a", fg="#c8202c", conf="med-high", note="Same tenant; brushed-metal fascia, red letters", src="4440")
ch('n33b', vacant=True, conf="low", note="Slate-blue upper wall, rust-steel riveted frame", src="4440")
ch('n33', vacant=True, conf="low", note="Peach-travertine frame", src="4440")
ch('s45', name="JOURNEYS", sign="JOURNEYS", bg="#5b2d8e", fg="#b5e61d", conf="low-med", note="Purple/lime oval sign, slate floor", src="4440")
ch('s46', name="HI-5", sign="hi-5", bg="#c8c8c8", fg="#2e8b3a", vacant=False, conf="low", note="Candy; grey fascia, green letters, black sliding glass", src="4440")
ch('s47', name="AVANT-GARDE", sign="AVANT-GARDE", bg="#7a4a2a", fg="#ffffff", conf="low", note="Menswear; rust steel mesh frame", src="4440,4442")
ch('s48', name="AT&T", sign="AT&T", bg="#111111", fg="#ffffff", conf="low", note="Black fascia, white letters, globe", src="4442")
ch('s49', name="HOUSE OF FADEZ BARBERSHOP", sign="HOUSE OF FADEZ", bg="#1f4e9c", fg="#ffffff", conf="low", note="Blue-framed salon front; name from directory (pink zone), sign unreadable", src="4443")
ch('s50', name="LOLA LABELLE BRIDAL", sign="Lola LaBelle", bg="#111111", fg="#ffffff", conf="medium", note="Glossy black box frame, full glass, wraps the court corner", src="4459")
ch('s51', name="IMPRESSIVE PRINTS", sign="IMPRESSIVE PRINTS", bg="#6b5b4e", fg="#ffffff", conf="high", note="Steven: 'that was double… Shoe Department'. 2 bays, taupe band", src="4459")
# --- JCPenney court / H6 ---
ch('s7', vacant=True, conf="medium", note="Navy/charcoal painted square piers, grille", src="4461")
ch('s7b', vacant=True, conf="medium", note="as s7", src="4461")
ch('n39', name="CAKELICIOUS", sign="Cakelicious", bg="#f4a09a", fg="#f6d25a", rect=(79, 130, 7, 4), drop=['n39b'], conf="medium",
   note="Gold 'n Gifts + Babbage's merged. Salmon fascia, yellow script, white Tuscan columns", src="4459,4461")
ch('s56', vacant=True, conf="low", note="Not positively seen; H6 fronts vacant", src="4461")
ch('n42', name="FOOD COURT", sign="FEELIN'\nHUNGRY?", bg="#1f6fd1", fg="#ffffff", conf="medium",
   note="Country Fair re-cut into the food-court seating entry ('Feelin' Hungry?' blue wall under copper bulkhead)", src="4441,4461")
# --- concourse south row (blue) ---
ch('s52', name="GAMES, INC. (POCKET CHANGE)", sign="games, inc.", bg="#ffffff", fg="#2e8b3a", conf="high",
   note="Arcade, 8 × 40 m confirmed; directory lists it as Pocket Change", src="4443,4444,4445")
ch('s52b', vacant=True, conf="medium", note="Original aqua 8-in tile + glass-block pilaster front; ghost letters from a later AT&T", src="4442,4461")
ch('s64', name="WICKED WINGZ", sign="WICKED WINGZ", bg="#111111", fg="#f6d25a", conf="high", note="Food-court bay; black sign, yellow letters", src="4440,4441")
ch('n46', vacant=True, conf="low", note="Matte black box frame, roll grille, oak threshold", src="4461")
ch('s63', rect=(105, 130, 2, 20), vacant=True, conf="low", note="Second black box-frame vacant", src="4461")
new('s63b', 's63', name="TREASURE ISLAND PUTT PUTT GOLF", sign="TREASURE ISLAND\nPUTT PUTT", bg="#4aa3df", fg="#ffffff", rect=(107, 130, 3, 20), face="N",
    vacant=False, conf="low", note="Sky-blue box sign, cream stone portal, pirate mural window", src="4440,4461")
ch('s62', name="BATH & BODY WORKS", sign="BATH & BODY WORKS", bg="#1f4e9c", fg="#ffffff", rect=(110, 130, 4, 20), conf="low",
   note="Blue/white gingham surround; back door stencilled '3027'. Width uncertain", src="4440,4490")
ch('s61', name="RHEA LANA'S", sign="Rhea Lana's", bg="#4aa3df", fg="#ffffff", conf="high", note="Sky-blue box frame around white glass front", src="4439")
ch('s60', name="FIRE HAUS 3.0", sign="FIRE HAUS 3.0", bg="#111111", fg="#d4af37", conf="high",
   note="Closed. ORIGINAL Regis-era facade: gold serif on black, travertine pilasters with 3 black stripes", src="4439")
ch('s59', name="BOOST MOBILE", sign="boost", bg="#ffffff", fg="#f26522", conf="low-med", note="White panel fascia, orange logo; east of the restroom hall", src="4439")
ch('s58', name="CELL XPERT", sign="CELL XPERT", bg="#ffffff", fg="#1f6fd1", conf="low", note="Between elevator and Auntie Anne's", src="4439")
ch('n56', name="AUNTIE ANNE'S", sign="AUNTIE ANNE'S", bg="#1b2a5e", fg="#ffffff", conf="low-med", note="Navy fascia", src="4439")
ch('s57', name="CINNAMONSTER", sign="CINNAMONSTER", bg="#5c1a2a", fg="#f6d25a", rect=(134, 130, 4, 5), conf="high",
   note="KarmelKorn endcap; burgundy/cream checker tile counter, curved mahogany soffit, Community Coffee", src="4438,4464-4468")
new('s57v', 's57', vacant=True, rect=(130, 130, 4, 5), face="N", conf="low", note="Black stepped-deco front with accordion grille; west half of old KarmelKorn", src="4439")
ch('s57b', vacant=True, conf="medium", note="Clipped-corner glass store, Morguard FOR LEASE; coral French-door display box", src="4438,4464")
# --- H4 east side (green) ---
ch('s4', name="VICTORIA'S SECRET", sign="VICTORIA'S SECRET", bg="#f2c4cf", fg="#ffffff", conf="medium", note="Blush panels, nickel portal, backlit serif", src="4438,4474")
ch('s20', name="PINK", sign="PINK", bg="#f5efe6", fg="#e4007c", conf="medium", note="Cream classical panelled front, round medallions", src="4438,4469")
ch('s3', name="PROIMAGE SPORTS", sign="PROIMAGE SPORTS", bg="#f5efe6", fg="#111111", conf="medium", note="Black/blue/white dimensional letters 'EST. 1985'", src="4471,4472")
ch('s21d', name="SHOE DEPT. ENCORE", sign="SHOE DEPT.\nENCORE", bg="#ffffff", fg="#111111", rect=(149, 113, 21, 12), drop=['s21c', 's21b'],
   conf="medium", note="Radio Shack + GNC + The Avenue merged (ex-Forever 21). White ACM facade; exterior entrance with 3 stainless box canopies (post-1995)", src="4476-4481,4492")
ch('s21', vacant=True, conf="low-med", note="White panel vacant bay, Morguard FOR LEASE", src="4476")
ch('s33', name="ZALES", sign="ZALES", bg="#f5efe6", fg="#111111", rect=(149, 103, 4, 5), face="N", face2="W", conf="medium",
   note="Closed/gated. Cream tile, chocolate-brown wainscot, 2 lit all-caps signs on the C2 corner ('both in caps'). Frank's spot per Steven", src="4424,4435,4436,4437,4492")
ch('s34', vacant=True, conf="low", note="All-glass, blue chairs, stepped 'skyline' molding fascia", src="4430-4432")
ch('s35', vacant=True, conf="low-med", note="Steven: 'definitely the Tee Tai's' — scalloped 'cloud' relief top, black brick-pattern grille", src="4492")
ch('s36', vacant=True, conf="low", note="Marble-look porcelain piers on black bases, white glossy band (~12 m, may include s35)", src="4430-4432,4492")
ch('s38', vacant=True, conf="low", note="Mission/Spanish stepped-scroll parapet fascia", src="4430")
ch('s38b', name="T-MOBILE", sign="T-Mobile", bg="#ffffff", fg="#e20074", conf="medium",
   note="Exterior-entrance-only store (unit 1029), door on the porch; mall side is a blank white panel with magenta letters. Post-1995 cut", src="4426,4430,4492")
ch('s29', name="CLAIRE'S", sign="claire's", bg="#ffffff", fg="#7b2cbf", rect=(149, 91, 9, 6), drop=['s30'], conf="medium",
   note="Gordon's + Claire's merged; purple lowercase, silver crinkle band, glass wrapping both faces (the 'double end cap')", src="4484,4433,4492")
ch('s31', name="WAX UTOPIA", sign="WAX UTOPIA", bg="#111111", fg="#d4af37", rect=(158, 91, 5, 6), drop=['s32'], conf="low-med",
   note="Mitchell's + Laser Copies; black glass angled display, gold/teal logo; star-medallion pilasters", src="4433,4492")
ch('s32b', vacant=True, conf="low", note="Blank grey metal band, granite wainscot with diamond inlay, frameless glass; Morguard FOR LEASE", src="4428,4429")
# --- H2 east side (purple + Hypervelocity) ---
ch('s25', name="HYPERVELOCITY RACE TRACK", sign="HYPERVELOCITY\nRACE TRACK", bg="#c8102e", fg="#e8e8e8", rect=(149, 76, 21, 10), drop=['s24mc', 'n65'],
   conf="medium", note="Indoor karting (unit 1043) in the K&B box + Mastercuts/Father & Son frontage; white portal with semicircular notch = old K&B logo niche; original folded-plate exterior canopy", src="4484,4406,4493")
new('s25b', 's25', name="NEEK & CO.", sign="Neek & Co.", bg="#ffffff", fg="#1f6fd1", rect=(149, 86, 8, 5), face="W",
    vacant=False, conf="medium", note="Boutique; white crown-moulded fascia, marble pilasters, black spiral grille; south end of old K&B front, next to Claire's", src="4484 f005")
ch('s24', vacant=True, conf="low", note="Athletic-shoe livery: grey canted sign band, red soffit, navy tile threshold", src="4484")
ch('n62', vacant=True, conf="low", note="Steven: 'I believe that was Felger's'. Pediment relief, chain/scissor grille", src="4484")
ch('n63', vacant=True, conf="low", note="'Feelin' Hungry?' food-court leasing wall + narrow cream vacant", src="4484")
ch('s26', vacant=True, conf="low", note="Black smoked-mirror glass front", src="4484")
ch('s27', vacant=True, conf="low", note="Cream stucco with ziggurat relief / gable-outline trim over narrow grille", src="4484,4421")
ch('s28', vacant=True, conf="med-low", note="Steven: 'this is what Duncan Sports was' — charcoal-painted blank front, one flush door", src="4408")

# --------------------------------------------------------------------------- build
def apply(base, kw):
    s = copy.deepcopy(base)
    if 'rect' in kw: s['x'], s['y'], s['w'], s['h'] = kw['rect']
    if 'face' in kw: s['face'] = kw['face']
    if 'face2' in kw: s['face2'] = kw['face2']
    if kw.get('vacant'):
        s['name'] = ''; s['sign'] = ''; s['vacant'] = True; s['signBg'] = VAC_BG; s['signFg'] = VAC_FG; s['merch'] = []
    else:
        if 'vacant' in kw: s['vacant'] = False
        if 'name' in kw: s['name'] = kw['name']
        if 'sign' in kw: s['sign'] = kw['sign']
        elif 'name' in kw: s['sign'] = kw['name']
        if 'bg' in kw: s['signBg'] = kw['bg']
        if 'fg' in kw: s['signFg'] = kw['fg']
    return s

dropped = set()
for kw in CH.values(): dropped.update(kw.get('drop', []))
out, rows = [], []
order = [s['id'] for s in json.load(open('stores_1995_full.json'))]
for sid in order:
    if sid in dropped: continue
    base = S95[sid]; kw = CH.get(sid, {})
    s = apply(base, kw); out.append(s)
    rows.append((sid, base['name'], s['name'] or 'VACANT', kw))
    for nid, nb, nkw in NEW:
        if nb == sid:
            n = apply(S95[nb], nkw); n['id'] = nid; n.pop('unit', None); out.append(n)
            rows.append((nid + ' (new)', S95[nb]['name'] + ' (part)', n['name'] or 'VACANT', nkw))

json.dump(out, open('eras_2026.json', 'w'), indent=1)
with open('map_2026.md', 'w') as f:
    f.write('| id | 1995 | 2026 | rect (x y w h) | status | conf | notes | clips |\n|---|---|---|---|---|---|---|---|\n')
    for sid, n95, n26, kw in rows:
        s = next(x for x in out if x['id'] == sid.split()[0])
        status = 're-cut' if 'rect' in kw else 'same'
        if kw.get('drop'): status += ' (absorbs ' + ', '.join(S95[d]['name'] or d for d in kw['drop']) + ')'
        if sid.endswith('(new)'): status = 're-cut (new unit)'
        if not kw: status, conf, note, src = 'same', 'n/a', 'unchanged (anchor/exit/restroom/unseen)', ''
        else: conf, note, src = kw.get('conf', ''), kw.get('note', ''), kw.get('src', '')
        f.write(f"| {sid} | {n95 or '(blank)'} | {n26} | {s['x']} {s['y']} {s['w']} {s['h']} | {status} | {conf} | {note} | {src} |\n")
print(len(out), 'stores in 2026 list;', len(dropped), 'merged away;', len(NEW), 'new units')
print('vacant:', sum(1 for s in out if s.get('vacant')))
