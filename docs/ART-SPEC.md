# Gloom's Bars — Art Spec for hand-authored assets (Figma → PNG)

> For the owner to author the shape/glow PNGs by hand. Every asset for one silhouette shares ONE
> canvas per aspect, with the **icon reference rect centered and a 128px margin all around** for
> glow bloom. The engine anchors every asset the same way (icon rect → the on-screen icon), so as
> long as you draw inside these guides, exports drop straight in. See docs/SHAPE-CATALOG.md for the
> shape list, docs/EFFECTS-MATRIX.md for the glow architecture.

## Canvas dimensions
Icon reference rect short side = **256px**; margin = **128px per side**; canvas = icon rect + 256px each axis.

| Aspect | Icon reference rect (WxH) | **Canvas (WxH)** | Used by |
|---|---|---|---|
| 1:1 | 256 × 256 | **512 × 512** | all 1:1 shapes |
| 3:2 tall (portrait) | 256 × 384 | **512 × 640** | rounded-sq ×3, pill, square |
| 2:1 tall (portrait) | 256 × 512 | **512 × 768** | rounded-sq ×3, pill, square |
| 3:2 wide (landscape) | 384 × 256 | **640 × 512** | square only |
| 2:1 wide (landscape) | 512 × 256 | **768 × 512** | square only |

**In Figma:** make a frame at the Canvas size, drop a centered rectangle at the Icon reference rect
size as a guide (128px gap to every edge), draw the shape/glow against that guide, hide the guide,
export the frame as PNG.

## What to draw — 3 assets per silhouette
All are **greyscale/white on transparent** (RGBA PNG). **Do NOT bake color in** — the engine tints
each one at runtime (procs, hover, cast = the same asset, different tint). Luminance/alpha only.

**File names are `<key>-base` / `<key>-outer` / `<key>-inner`.** (This doc used to call the first one
`<shape>-mask` and the glows `-glow-outer`/`-glow-inner`; the shipped names are the ones above, and
`GB:HandAsset(key, part)` in Core.lua builds every path from them. Corrected 2026-07-25.)

1. **`<key>-base`** — the hard silhouette. Solid **white** shape filling the **icon reference rect**,
   transparent outside, anti-aliased edge. This defines the icon's exact shape (your corners/curvature
   live here). No blur. ★ **This is the single source of truth** — four more assets are derived from it,
   so if you re-export it, re-run all three generators below.
2. **`<key>-outer`** — the shape's silhouette with an **outer glow / blur blooming OUTWARD** into
   the margin, fading to fully transparent before the canvas edge. The interior fill can be dropped
   (the icon covers it) — what matters is the falloff *outside* the icon edge. Your call on blur radius
   / softness / spread.
3. **`<key>-inner`** — the shape filled with an **inner glow**: brightest at the inner edge,
   fading toward center so the middle stays transparent (interior never fully tints). Clipped to the
   silhouette. Your call on how far it reaches inward.

## What is DERIVED from `-base` — you do NOT draw these
**All three generators glob every `*-base.png` in `Media/art/hand/`, so a new shape is picked up
automatically — but they do not run themselves.** Each takes seconds (pure PIL).

| Command | Produces | Used by |
|---|---|---|
| `python3 tools/generate-hand-swipes.py` | `<key>-swipe.png` | the cooldown sweep |
| `python3 tools/generate-shine.py` | `<key>-rim.png` | Comet Chase + other animations |
| `python3 tools/generate-march.py` | `<key>-line.png` | Marching Lines |

★ **`-rim` and `-line` were added in sessions 10–11 and this doc never mentioned them until
2026-07-25.** A shape authored from the old spec looks correct for icons and glows but has **no
Marching Lines and no Comet Chase** — a per-shape failure that is easy to miss because every other
shape still works. Do not skip those two commands.

**So a finished shape is 6 files on disk** (`-base -outer -inner -rim -line -swipe`), plus 2 more for
2:1 portrait shapes (see the plate note in the procedure below).

Still engine-generated, nothing to author:
- **Border** — built from the base at runtime (the shape scaled up by the thickness slider), so it
  auto-fits every shape and stays user-adjustable. Its color is overridden to the glow color on glow.
- **State ring** — gone; hover/selected/cast reuse `-outer` + `-inner` with a different tint.

## ★★ ADDING A NEW SHAPE — the complete procedure (verified against the code 2026-07-25)
Nothing here is guesswork; each step names the file and the reason. **No data migration is needed** —
shapes are referenced by key, so existing profiles and presets keep whatever they had.

**1. Draw the three PNGs** at the canvas size for its aspect (table at the top of this file), obeying
the edge rule and the white-matte rule below. Name them `<key>-base/-outer/-inner.png` in
`Media/art/hand/`.

**2. Whiten the base's transparent pixels.** ⚠ **There is NO tool for this and it is the easiest step
to forget** — Figma exports a black matte, and a black-matted base **does not clip at all** (the icon
renders full/square). Every shipped base is `(255,255,255,0)` in its transparent regions. Fix a fresh
export with:
```
python3 -c "
from PIL import Image
p='Media/art/hand/<key>-base.png'
im=Image.open(p).convert('RGBA'); a=im.split()[3]
w=Image.new('RGBA', im.size, (255,255,255,0)); w.putalpha(a); w.save(p)
print('whitened', p)"
```
Only `-base` cares; the `-outer`/`-inner` glows are tinted textures where a black matte is fine.

**3. Run the three generators** from the repo root (table above). Do not run the big
`tools/generate-art.py` — that belongs to the older corner system, takes ~4 minutes, and is unrelated.

**4. Register it — `Core.lua`, two edits:**
- One row in **`HAND_DEF`** (~line 90): `{ "<key>", <aspect>, "<orient>", "<Label>" }` where aspect is
  `1`, `1.5` or `2` and orient is `"square"`, `"portrait"` or `"landscape"`. Order in this table is
  picker order.
- Add the key to the right group in **`GB.HAND_GROUPS`** (~line 123). **Miss this and the shape works
  but is invisible in the picker** — the grid renders from the groups, not from `HAND_DEF`.

**5. If it is NOT 1:1 — `Skin.lua`, one edit:** add it to **`FLYOUT_1X1`** (~line 287) mapping to its
1:1 sibling (`pill21 = "circle"`, `square21 = "square"`, …). Blizzard locks flyout popup members to
small squares, so without this a tall silhouette **overlaps its neighbours** in an open flyout.

**6. If it is 2:1 PORTRAIT — one more edit:** plate mode is granted automatically (eligibility is
computed from `orient == "portrait" and aspect == 2` in Skin.lua:331 and Config.lua:659 — there is no
list to update), **but the plate half-swipes are NOT automatic.** Add the key to **`PLATE_KEYS`** in
`tools/generate-hand-swipes.py` (~line 32) and re-run it, or the cooldown sweep on the icon half is
wrong in plate mode. That produces `<key>-swipe-t.png` / `<key>-swipe-b.png`.

**7. `/reload`.** New files need nothing more (the full-restart rule is retired suite-wide; only new
FONTS need a client restart).

**8. Update the two docs:** the table at the bottom of this file, and the counts in
`docs/SHAPE-CATALOG.md`. Both were written around a founding set of 21 and say so in several places.

## Edge rule (important)
Nothing may touch the canvas edge — the 128px margin exists so the outer glow fades to 0 with room to
spare (a shape/glow that hits the edge gets a hard clamped smear). Keep all pixels inside the margin.

## `-base` masks must be WHITE rgb (not black-matted)
The `-base` PNG is used as a MASK, and WoW's mask reads LUMINANCE — so the transparent regions must be
WHITE `(255,255,255,0)`, not the BLACK `(0,0,0,0)` that Figma exports by default. A black-matted base
**won't clip** (the icon renders full/square). On import we force rgb→255 on every `-base` (alpha
untouched), so you don't have to — but if you re-export a base, it'll be black-matted again and needs
re-whitening. (Only the `-base` cares; the `-outer`/`-inner` glows are tinted textures, black transparent
is fine there.) See docs/API-NOTES.md §2.

## Efficiency option *(historical — this was the plan before the founding 21 were authored; kept for the reasoning)*
21 silhouettes × 3 assets = 63 PNGs. Two ways to play it:
- **You make them all** — full control, Figma variants/components make the repetition fast.
- **You make 1–2 reference shapes** (mask + both glows) so I can measure your exact falloff/blur, then
  I replicate that look across all 21 in the generator to match. Least manual work, same look.
- **Hybrid** — you hand-make the shapes whose look you care most about; I generate the rest to match.

Recommend starting with **one** shape (your tall pill, say) end-to-end so we lock the look before
mass-producing — matches the Phase 3 "nail one silhouette first" plan.

## The founding 21 silhouettes — file naming (VALIDATED pipeline, 2026-07-20)
**All 21 below are AUTHORED AND SHIPPING** (the "Done" column records the original validation order and
is kept for history — it is not a to-do list). **This is the founding set, not a closed one:** adding a
22nd is a supported, routine operation — follow the procedure above and add a row here.
Each = 3 drawn files: `<key>-base.png`, `<key>-outer.png`, `<key>-inner.png`, plus the 3 derived
(`-rim`, `-line`, `-swipe`) and, for 2:1 portrait shapes, 2 plate half-swipes. Canvas from the table at top.

| Silhouette | Key | Canvas | Done |
|---|---|---|---|
| Circle | `circle` | 512×512 | |
| Square | `square` | 512×512 | ✓ |
| Rounded square — subtle / med / large | `roundsq1` / `roundsq2` / `roundsq3` | 512×512 | |
| Hexagon | `hexagon` | 512×512 | |
| Diamond | `diamond` | 512×512 | |
| Tombstone (flat bottom, round top) | `tombstone` | 512×512 | |
| Tombstone inverted | `tombstone-inv` | 512×512 | |
| Pill — 3:2 / 2:1 (portrait) | `pill32` / `pill21` | 512×640 / 512×768 | ✓ (32) |
| Square — 3:2 / 2:1 (portrait) | `square32` / `square21` | 512×640 / 512×768 | |
| Rounded sq 1 — 3:2 / 2:1 | `roundsq1-32` / `roundsq1-21` | 512×640 / 512×768 | |
| Rounded sq 2 — 3:2 / 2:1 | `roundsq2-32` / `roundsq2-21` | 512×640 / 512×768 | |
| Rounded sq 3 — 3:2 / 2:1 | `roundsq3-32` / `roundsq3-21` | 512×640 / 512×768 | |
| Square — 3:2 / 2:1 (landscape) | `square32w` / `square21w` | 640×512 / 768×512 | |

= the founding 21. Drop new art in `Media/art/hand/` directly; the generators and the engine both read
that folder. **To add a 22nd, use the procedure above** — the art is the only real work; the code side is
2 edits (4 if it is elongated and/or 2:1 portrait) and takes minutes.

