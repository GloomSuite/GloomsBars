# Gloom's Bars — HANDOFF

> **Where Gloom's Bars stands, and what must not be relitigated.** Settled content only.
>
> Session records moved to [ARCHIVE.md](ARCHIVE.md) on 2026-07-26 — nothing was deleted. Open work
> for the whole suite lives in `~/GloomsHub/docs/BACKLOG.md`; unproven diagnosis in
> `~/GloomsHub/docs/FINDINGS.md`. **Do not restate suite-wide facts here** (release state, phase
> status, contracts) — point at the Hub. Every time that rule was broken, the copy went stale
> within a day.
>
> **Keep this file re-readable.** If it passes ~350 lines, move settled history to the archive.
> The handoff ritual (`~/GloomsHub/.claude/skills/handoff-ritual/`) maintains it.

**Last updated:** 2026-07-26 · **Shipped: `v1.1.2`** (verified against the published release, not
copied) · **No open bugs.**

---

## ★★ THE BAR-POSITION FIX — the durable engineering facts (`v1.1.2`, 2026-07-26)

The full investigation is in [ARCHIVE.md](ARCHIVE.md) (SESSION 18) and the suite record is in
`~/GloomsHub/docs/FINDINGS.md` §3. What must survive here:

- **★ A bar GB positions anchors its CONTAINERS to `UIParent`, not to the bar frame**, dividing the
  frame's scale out of the container scale. Blizzard may move or rescale the frame freely; the
  buttons no longer care. **Containers stay CHILDREN of the frame**, so show/hide, alpha and the
  vehicle/override visibility rules inherit exactly as before — only the anchor and scale changed.
  The frame is then sized and placed over its own grid so Edit Mode's selection box still lands on
  the buttons. Bars GB does not position keep the old path.
- **Hook the GLOBAL reposition pass, not per bar.** `UpdateBottomActionBarPositions` /
  `UpdateRightActionBarPositions` on `EditModeManagerFrame` re-anchor **every** bottom-anchored bar
  in one pass (bars 1/2/3 + Pet + Stance). Per-bar hooks meant one bar's visibility pass silently
  moved the others.
- **Repair in the SAME frame, not the next one.** Deferring to the next frame renders one frame at
  Blizzard's position — a visible flicker on every target change.
- **`MainActionBar:IsProtected()` → true.** GB may never re-anchor a bar frame in combat; "react
  faster" was never available at any hook position.
- **★ Do NOT write `isInDefaultPosition` to make Blizzard skip a bar.** It is written only from Edit
  Mode's own drag/nudge/magnetism, so there is no event-driven route and an addon can only set it
  directly — which taints the loop that re-anchors every *other* bottom bar, risking blocked actions
  in combat on bars GB never touched. **Rejected on evidence; do not "just try it".**
- **ACCEPTED, not a bug:** while Edit Mode is OPEN, Blizzard's grid pass re-anchors containers back
  onto the frame, so a default-position bar returns to Blizzard's spot until Edit Mode closes. GB
  stands down inside Edit Mode by design and restores on exit.
- **★ Nothing in `Skin.lua` / `Glows.lua` / `Anims.lua` references `.container` or the bar frame** —
  they hang off the BUTTON, which is why tints, glows and animations moved for free. Keep it that way.
- ★ **Method that cracked it: TRAP THE WRITE.** `hooksecurefunc` on `SetPoint` / `ClearAllPoints` /
  `SetScale`, deduplicated **by caller** (via `debugstack`), not by bar. Blizzard named itself in one
  reload. **Dedupe diagnostic output by CALLER and list affected objects beside it** — grouping by
  bar scrolled out of the owner's chat buffer.
- ★ **A PTR-only symptom is a hypothesis, not a finding.** This was filed as a 12.1 regression and
  reproduced on live 12.0.7 on any character whose bars sat at Edit Mode defaults. It had been
  shipped-and-broken for every new user. **Check "does this reproduce on live?" before trusting a
  PTR frame.**

---

## ▶▶ NO OPEN GB BUGS. All three session-14 bugs resolved (details in SESSION 15). Two were Blizzard behaviour:
1. **Hidden bars return → LEFT (mostly Blizzard).** the owner reproduced it with GB fully DISABLED on native
   Blizzard bars: pet detach / walking out of range flashes ALL hidden bars visible until back in range.
   Two layers: (a) Blizzard flashing them — UNFIXABLE, native does it; (b) GB slow to re-hide (the Layout
   watcher doesn't listen for UNIT_PET / PLAYER_CONTROL_*). The owner chose "leave it — good enough." Do NOT
   re-open as a GB defect. If ever revisited, the only fixable part is registering the pet-detach events on
   the Layout watcher (Layout.lua ~line 51) to narrow the lingering window. ([[hidden-bars-return-mostly-blizzard]])
2. **Pet autocast "white dot" → WON'T-FIX (Blizzard's RANGE_INDICATOR).** It appears on TARGET (the owner found
   it's targeting, not combat) — it's Blizzard's range dot working as intended, NOT an unbound-key leftover.
   The owner dropped it. The session-14 line-981 `hk:GetText()=="●"` hide still lingers (a harmless half-fix);
   optional one-line removal if tidying. Do NOT chase it. ([[pet-dot-is-range-indicator-wontfix]])
3. **Pet stance glow "stuck" → FIXED as not-a-bug + restyled.** Probe (`/gb petglow`, now removed) proved the
   pet's STANCE stays checked while it attacks — Kill Command fires a one-off attack ON TOP, it does NOT
   change the stance. Verified against native Blizzard bars (their glow is just a very subtle yellow interior
   one). GB now mirrors Blizzard faithfully (no attack-action special-casing) and defaults the "selected"
   trigger to a SOFT-BLUE INNER-ONLY glow (Core seed `layers="inner"`) so a persistently-lit stance reads
   quiet. Existing profiles set inner-only in the Glows section; the seed only affects fresh installs.
   Commit `9080b82`. ([[pet-stance-glow-mirrors-blizzard]])


## ▶ THE OWNER DECISIONS — ALL FOUR NOW CLOSED (a/b/c/d). Nothing is carried. Kept for the record:
- (a) "Default" mode label — KEEP "Default" (do NOT relabel to "Blizzard"). CLOSED.
- (b) Rewrite **CLAUDE.md** — its "pure skin v1 / settled decisions" block is STALE (layout built, profiles
  exist, pet/stance skinned+laid-out, no-"v1" rule, secure-geometry now in play, RefreshAll combat-gated).
  Offered across several sessions, not yet done.
- (c) **Release tag — CLOSED 2026-07-24 (suite Phase G): `v1.0.0` shipped.** It carried everything that
  had piled up unshipped since v0.2.0 (animations, plate, profiles, layout, 3-panel, minimap, pet/stance,
  preset-focus highlight, the two in-play bug fixes) **plus the Phase C tab migration**.
  ⚠ **The old published `v0.2.0` was tagged at a PRE-Phase-C commit** — two Lua files, no config UI, no
  `## Dependencies: GloomsHub`. It was three phases stale, not merely "unshipped work behind it".
  **Check what a tag POINTS AT, not just that it exists.** Suite-wide release state:
  `~/GloomsHub/docs/SUITE-STATE.md`.
- (d) **Modifier symbols (⌘⇧⌃⌥) don't take outline/shadow — ✅ CLOSED 2026-07-25: DROPPED, WON'T DO.**
  The owner's call, after reviewing the approach: *"leave the glyphs untouched… juice isn't worth the
  squeeze. I can deal with no stroke/dropshadow on the glyphs."* **Do not re-propose this**, and do not
  quietly "fix" it while touching keybind text. The glyphs stay as inline PNGs
  (`MOD_ICON`/`symbolizeHotkey`, [Skin.lua:826-865](../Skin.lua#L826-L865)), unstyled by design.
  **Why it was dropped, so nobody re-derives it:**
  - WoW cannot outline or shadow an inline `|T…|t` texture, and one FontString cannot mix fonts —
    so the styling can NEVER reach the glyphs on the current path. That much is settled fact.
  - The approved path (a second FontString in a glyph font) carried an **unstated hard prerequisite**:
    a bundled font actually containing U+2318/21E7/2303/2325. GB bundles Khand + GeneralSans, both Latin
    display faces that almost certainly lack all four — so it meant sourcing/subsetting a **new `.ttf`**,
    which is the suite's ONE genuine full-client-restart case, plus a licensing question.
  - It also meant duplicating the whole keybind surface on a parallel FontString: zone math
    (corner/center/extension/plate), `scaledFontSize`, the Midnight font-object shadow priming, the
    `UpdateHotkeys` re-assert, the pet `SetVertexColor` war, pristine stash/restore, and new
    pair-centering math. Large surface on the addon's most bug-prone text element.
  - **The cheaper alternative, if this is ever reopened** (it shouldn't be, absent a new reason): stay in
    the texture layer — bake outline variants (none/outline/thick) + a black silhouette in
    `tools/generate-modglyphs.py`, and emit two inline textures per modifier (silhouette offset, glyph on
    top) via the escape's x/y offset args. No new FontString, no new font, no restart. Its two costs:
    specifying offsets means giving an explicit height (losing `:0` auto-line-height — `scaledFontSize`
    has the number), and **shadow COLOUR would stay baked black**, since inline textures take no tint.
  ([[modifier-symbols-outline-deferred]])


## ✔ SETTLED (session 7): Blizzard's cooldown EDGE + finish BLING can't be shaped — don't re-attempt.
The cooldown SWEEP follows the shape via its swipe-texture alpha (works). But the rotating EDGE line and the
finish BLING (star) are drawn INTERNALLY by Blizzard's Cooldown widget to the SQUARE frame bounds — no
maskable handle, and `SetEdgeTexture`/`SetBlingTexture` colour args only MULTIPLY their baked gold/blue
textures (never a clean recolour). We also can't draw our own versions: both need the cooldown's REMAINING
TIME (the secret wall). So: edge + bling are SUPPRESSED, and our own shape-masked **finish flash** (fired on
the `OnCooldownDone` event, GCD-filtered by the game clock — never reading the secret duration) replaces the
bling. Decision with the owner: drop the edge, shape the flash. Do NOT re-add Blizzard's edge/bling.


## ✔ SETTLED: per-corner MIXING stays cut for the ICON, but mixed-corner ART is used for OVERLAYS.
Session 5 cut per-corner mixing for the ICON MASK (9-slice had a ~44px short-side floor; do NOT re-attempt
a mixed ICON mask). BUT the full-render mixed-corner PNGs (`corner-<TLTRBLBR>-r<N>`) still exist and are
now USED for OVERLAYS that span a continuous-OFF construction (rounded icon + SQUARE plate): the proc GLOW
and the cast FILL pick `corner-1100` (below-plate) / `corner-0011` (above-plate) so their plate end goes
square. These are soft/whole-image renders, not 9-sliced, so no floor problem. (SESSION 6, `mixedCornerBase`.)

> **This is the anti-relitigation record — if something is marked verified or settled here, do not
> re-derive it.** The handoff ritual maintains it; session narrative goes to [ARCHIVE.md](ARCHIVE.md),
> not here. Deep client facts live in [API-NOTES.md](API-NOTES.md) — read §1–§4 before touching
> mask/skin/glow code.


## How to work with the owner (the owner) — READ THIS
- **Non-developer.** He sets requirements + does in-game QA; Claude writes all code + research.
- **ONE instruction at a time** for testing; never batch QA steps.
- **Verify before claiming** — frame builds as hypotheses; never say it works until confirmed in-game.
- When something misbehaves, ask for the **BugSack error text FIRST** (WoW hides Lua errors).
- UI: **sliding switches** over checkboxes; **no native Blizzard UI** widgets; **pixel-perfect**
  to mocks. The owner's Figma numbers translate 1:1 into recipe values — ask for mockups; the
  figma-desktop MCP tools may allow reading values directly from his file.


## Project & environment
- WoW **Midnight 12.0.7** retail, Interface `120007`. Client at `/Applications/World of Warcraft/_retail_/`.
- Repo root = addon folder, symlinked to `…/Interface/AddOns/GloomsBars`. BugSack installed.
- GitHub: https://github.com/GloomSuite/GloomsBars (public). Releases: tag push →
  BigWigs packager workflow → GitHub Release → WoWUp installs/updates via repo URL.
  ★ **Release state is a SUITE fact and is deliberately NOT restated here** — the home of record is
  `~/GloomsHub/docs/SUITE-STATE.md`. Every past attempt to keep a version number in this file went
  stale within a day. Check the published release, or the Hub. `gh` CLI authorized on the owner's
  machine (the org admin account, scopes repo/workflow/read:org/delete_repo).
- Blizzard UI source for hook research: wow-ui-source `live` branch — clone matched the
  client exactly (commit "12.0.7 (68453)"). Re-clone when the client patches.
- Siblings (read-only reference): GloomsAuras at `~/GloomsAuras` (config
  toolkit `Config.lua`, API-NOTES pattern, design tokens), Build Barn at
  `~/Desktop/glooms-build-barn` (release recipe).
- The owner's client addon ecosystem (QA context): ArcUI (bars/CDM UI), EnhanceQoL (border
  hiding was ON during early probes — now off), StoneTweaks, VibeOverlay, Platynator
  (nameplates; ships the Lato font), BugSack. Dominos' hotkey styler was found styling
  keybind text — the owner REMOVED it. Late-phase QA: coexistence re-test with these enabled.


## The core idea (do NOT relitigate)
Pure appearance layer over Blizzard's own action buttons. Never replace secure buttons;
never read secret combat values; react to Blizzard's events and restyle Blizzard's
rendered output. Edit Mode owns geometry (the clickable areas). Full rationale: [SPEC.md](SPEC.md).

**Settled decisions (2026-07-18, with the owner — do not reopen):** pure skin v1 (no secure-frame
geometry); bars 1–8 (pet/stance/extra later); standalone (no Masque); slash `/gb` (+
`/gloomsbars`), SavedVariables `GloomsBarsDB`, namespace `GB` → `_G.GloomsBars`.

**Settled decisions (2026-07-19, session 5 — do not reopen):**
- **Per-corner MIXING is CUT.** Corners are all-or-nothing (Circle / Rounded / Square). Mixed
  rounded/sharp corners on a non-square icon can't render cleanly — do not re-attempt.
- **Hexagon is FIXED-ASPECT** (square only — one "Icon size", no width/height/lock/crop/extension).
- **Positioning/spacing (honeycomb layout) is the out-of-combat GEOMETRY FORK — a real FUTURE phase,
  NOT "never."** Clarified with the owner after I mis-framed it: (1) secure buttons can only be moved OUT
  of combat, and once moved they PERSIST (nothing reverts) — that's a NON-ISSUE, same as most addon
  config; don't keep flagging it. (2) The actual reason it's deferred/meaty is **taint** (moving
  Blizzard's secure buttons can cause "action blocked" errors). (3) v1 is still pure-skin; the fork is
  unbuilt and unscoped. The honeycomb can be built TODAY by hand in Edit Mode (two offset bars).
- **Border = a colored shape-backing** (a shape copy behind the icon, oversized by thickness), works
  for ALL shapes, reuses the masks. Lives in Decoration.

**Settled decisions (2026-07-19, session 6 — do not reopen):**
- **Continuous-OFF only applies with a PLATE on a straight-sided shape.** Circle + hexagon force
  Continuous ON (engine + greyed toggle); with no extension the engine forces it ON too (else the
  gradient plate loses its mask and draws as a square — the hexagon-gradient regression). A circle +
  an extension = a pill.
- **Proc-glow art = a WIDE soft bloom, GLOW_EXTENT 80 / GLOW_SCALE 128÷80.** Reprofiled twice this
  session (peak at the silhouette, wide Gaussian, inward rim-light). Bigger/softer than the old 96.
  The saved glow Size is reset ONCE via the `glowWideBloom` flag (art geometry changed).
- **Proc glow (and any alert-driven overlay) must gate on OUR action buttons only** — Midnight's
  Cooldown Viewer frames ALSO fire the spell-alert manager and their geometry is a SECRET combat value
  (arithmetic on it taints + throws). `Glows.isOurs` (a set from `GB:ForEachButton`) is the gate.
- **Standalone-consume LibSharedMedia** (no embed): `GB.GetLSM()` = `LibStub("LibSharedMedia-3.0",
  true)`; we register our bundled fonts into it. **Embedding it here is now settled as NOT-TO-DO
  (2026-07-24, suite Phase G):** GB hard-depends on GloomsHub, and the Hub embeds LSM via its own
  `.pkgmeta`, so the lib is guaranteed present by the dependency itself. A second embedded copy would be
  the exact drift the suite exists to prevent. Same reasoning that dropped "embed LibGloomSkin per tool".

**Settled decisions (2026-07-20, session 7 — do not reopen):**
- **Cooldown edge + finish bling can't be shaped → suppressed; shaped finish flash replaces the bling.**
  (See the ✔ SETTLED block at top.) Drop the edge entirely; the flash is OUR OWN burst on `OnCooldownDone`.
- **The cooldown SWEEP fills the icon; NO overshoot slider.** The old `sweepOvershoot` was really fixing
  Blizzard's UNDERSHOOT (Blizzard insets the cooldown). It's baked at +0.75px (kills the AA rim leak); the
  user slider was removed (`/gb sweep` dev command + db field stay). **Charge cooldowns are now styled too**
  (`btn.chargeCooldown` was edge-only → `SetDrawSwipe(true)` forces the shaped recharge sweep).
- **Availability + range tint = REACT to Blizzard's rendered output, never read the secret.** `UpdateUsable`
  sets the icon vertex (usable 1,1,1 / OOM 0.5,0.5,1 / unusable 0.4,0.4,0.4) → we read THAT (not
  `IsUsableAction`). `ActionButton_UpdateRangeIndicator(self, checksRange, inRange)` HANDS us `inRange` → we
  react (not `IsActionInRange`). Out-of-range = **desaturate then tint** (a clean wash, not a multiply) on the
  icon AND recolour Blizzard's red keybind to the same colour. `computeIconTint` layers them (range > oom >
  unusable > usable). "Unusable" is NARROW: not target/cooldown/range — only wrong form/stance, silence,
  missing secondary resource (untalented = Blizzard-desaturated separately).
- **State-highlight rings: bolder ADD art + a Glow-width (spread) slider.** `ring_alpha` rim now peaks at
  full (1.0) alpha (was ~0.65 → faint); `db.stateWidth` drives the ring's spread via `stateWidthRatio` (was
  the fixed `RING_FIT`). The owner chose the bolder-glow direction (not an opaque ring). The cast inner glow
  SHARES the ring art → its alpha is scaled to 0.65 to keep the QA'd cast look. "Too subtle" is RESOLVED.
- **Config accordion opens ALL-CLOSED** (no default-open section — easier to find the one you want).


## ★★ NORTH STAR (the owner, 2026-07-18): USER-AUTHORED styles via a style editor
The owner: "I wanted to build this via the UI myself — not a baked-in recipe. Define the
height and width of the icons (via the UI), overlay a gradient and position it, decide
where the keybind shows up, apply a shape to the overall construction… I want a TON of
flexibility — it's the entire point."
- A button style = **data** (shape, zoom, construction zones, decoration layers, text
  elements with position/font/size/color). The engine (Skin.lua decor pass) interprets
  data; `GB.STYLES` in code is scaffolding/starter-templates ONLY. Real styles live in
  SavedVariables, authored through the **style editor** (the Config UI — next major build).
- Reference look (matched in-game, the owner: "pretty cool"): `plate` — button extends ~40%
  below the icon, orange gradient fades in over the icon's bottom half, solid through the
  extension, keybind bold white centered in the extension, one continuous rounded shape.
- Icon sizing scope: the VISIBLE construction is freely sizable/aspectable (textures are
  not protected). The CLICKABLE hit area is the secure button — Edit-Mode-sized unless the
  spec's §B out-of-combat geometry fork is taken later. The UI must communicate this.


## CURRENT STATE — what's built and QA'd (base state 2026-07-18; SESSION 5 adds hexagon/border/construction)
> The bullets below are the session-1→4 skin foundation (all verified in-game). **SESSION 5 (above) adds:
> Hexagon shape, Border decoration, bidirectional + continuous construction, and REMOVES per-corner mixing.**
Files: `Core.lua` (namespace, tokens, `GB.SHAPES`, `GB.STYLES`, saved vars, `/gb` router,
probes), `Skin.lua` (skin + decoration engine), `Glows.lua` (proc glow engine),
`Media/masks|art/` (generated), `tools/generate-art.py` (SDF art generator).

- **Skin engine** (`/gb skin`, persisted): all 8 bars (96 buttons) — icon zoom crop
  (0.08), fresh per-button shape mask, slot art suppressed (`SlotBackground`/`SlotArt`
  Hide + `NormalTexture`/`PushedTexture` SetAlpha(0) — survives press), re-asserted via
  per-button `UpdateButtonArt` hook. ✅ QA'd incl. press cycles.
- **Shape registry** (`GB.SHAPES`: circle, roundrect, square; `/gb shape`, /reload to
  apply): every shape = mask/swipe/ring/glow PNGs from `tools/generate-art.py` (adding a
  shape = one signed-distance function). ✅ QA'd on all three shapes.
- **Cooldown sweeps**: circular 0.8-alpha swipe texture on `cooldown` + LoC widgets
  (charge cooldown untouched — edge-only), edge/bling off, re-anchored to the icon with
  overshoot (default 0.75px, `/gb sweep <px>`, persisted). ✅ QA'd.
- **State art**: hover/checked/flash replaced with `<shape>-ring` art (gold/blue/red
  tints). ✅ Hover QA'd. 📌 the owner: dimmer than default — styling controls required (backlog).
- **Proc glows — THE DIFFERENTIATOR, PROVEN**: `Glows.lua` hooks
  `ActionButtonSpellAlertManager:ShowAlert/HideAlert` + `AssistedCombatManager:
  SetAssistedHighlightFrameShown`; silences Blizzard frames via durable alpha-0; one
  shaped additive pulsing halo per button (gold procs / blue assist). ✅ QA'd: real
  in-combat proc traced the shape on round AND square. Assist-highlight replacement also
  observed working (LOW PRIORITY per the owner — do not iterate on it). ✅ "Hard to see" RESOLVED
  session 6: color/Brightness/Size/Pulse controls + a wide soft bloom (see SESSION 6).
- **Cast/channel overlay**: drain (`CastFill` mask swap), inner glow (art replacement via
  `PlaySpellCastAnim` hook, lime/gold, RING_FIT sizing), `EndBurst` end flash (mask
  swap). ✅ FULLY QA'd on round and square.
- **Decoration engine + construction zones** (`/gb style`, live, persisted): styles as
  data — extension zone below the icon, pooled WHITE8X8 gradient plates (solid+fade
  primitives), keybind override (position/font/size/color, re-asserted via `UpdateHotkeys`
  hook, text container raised). ✅ QA'd against the owner's Figma mock.
- **Text**: Count/Name/HotKey on bundled GeneralSans (sizes/flags/range-coloring kept).
  ✅ Verified via `/gb fontinfo`. ✅ Font picker DONE session 6 (LibSharedMedia dropdown); Count/Name
  per-style overrides still backlog.

**Dev slash commands** (scaffolding, not product): `/gb skin`, `/gb shape <name>`,
`/gb style <name>`, `/gb sweep <px>`, `/gb debug`, `/gb glowinfo`, `/gb fontinfo`,
`/gb mask`, `/gb maskinfo`, `/gb round`.


## Verification gates
| # | Claim | Status |
|---|-------|--------|
| 1 | 8 bars' button globals = Dragonflight-era names, 12 each | ✅ VERIFIED |
| 2 | Subregions `.icon/.HotKey/.Name/.Count/.cooldown` (+anatomy in API-NOTES §1) | ✅ VERIFIED |
| 3 | MaskTexture renders in Midnight (with the fresh-mask + edge-padding rules, API-NOTES §2) | ✅ VERIFIED |
| 4 | `IsActionInRange`/`IsUsableAction` readable in Midnight combat (custom range tint) | ✅ SIDESTEPPED (session 7) — we never CALL them; we react to `UpdateUsable`'s icon vertex + `UpdateRangeIndicator`'s `inRange` arg (Blizzard's rendered output). No secret read; usable/OOM/unusable/out-of-range tints all work in combat |
| 5 | Blizzard hook points (UpdateButtonArt, alert manager, cast anim, hotkeys…) | ✅ SOURCE-VERIFIED @ exact client build + confirmed in-game via the working hooks (API-NOTES §3) |
| 6 | Proc glows hookable without secret reads | ✅ VERIFIED IN COMBAT — the differentiator is proven |
| 7 | ALL states drive the multi-part shaped glow (proc/hover/selected/cast/channel/flash) per-shape | ✅ VERIFIED IN COMBAT (session 9) — every trigger reconciled by source priority; no secret reads |
| 8 | Cooldown sweep + cast fill/burst + finish flash trace the hand silhouette | ✅ VERIFIED (session 9) — hand `-swipe` generated from the base; fill/burst mask from `-base` |
| 9 | Per-trigger glow matrix (colour/opacity/layers/enable per state) + flash-square fix | ✅ VERIFIED IN-GAME (session 10) — GUI-configured; disabled trigger drops to next; no square on auto-attack |
| 10 | Per-trigger ANIMATION SYSTEM: Comet Chase rides the winning glow; masked rim-chase on any shape; per-state independent | ✅ VERIFIED IN-GAME (session 10) — GUI + preview; SetRotation under a fixed rim mask; one animation per state |
| 11 | Midnight duration-object proxy: GetActionCooldownDuration(ignoreGCD) → SetCooldownFromDurationObject → react to widget lifecycle = a combat-safe "real cooldown running" signal, no secret reads | ✅ VERIFIED IN-GAME (session 12) — drives plate dim-on-cooldown; GCDs never trigger it |


## Hard-won LEARNINGS (verified — do NOT rediscover; details in API-NOTES)
- **Masks**: fresh masks render; editing a live mask's texture never re-renders; runtime
  attach silently fails on never-rendered never-masked textures (→ replace art instead);
  3-mask-per-texture cap; masks don't clip `SetColorTexture` fills (use WHITE8X8);
  ALL mask/glow art needs transparent edge padding (edge-clamp bleed flattens+blurs);
  `CircleMaskScalable` is NOT usable at button size (scalable/9-slice flattening).
- **Re-assertion map**: `UpdateButtonArt` = only slot-art re-shower (hook it); press
  border re-show is C-side (SetAlpha(0), never Hide); icon texcoord never stomped;
  vertex color stomped by `UpdateUsable` (leave it — Blizzard's usability tint);
  `UpdateHotkeys` re-anchors keybind text (hook it); cooldown swipe textures never re-set.
- **Glow systems**: THREE mechanisms (spell alerts / assisted highlight / rotation
  helper) — all hooked centrally; per-button alert frames, never pooled; assist ants
  flipbook only animates in combat.
- Zoom-crop icons (~0.08) before masking (baked borders at shape tangents).
- Error inside a slash handler leaves typed text undigested in the chat box (check BugSack).
- From siblings: secret-values model (GloomsAuras API-NOTES), release pipeline (Build
  Barn), bundled-font pre-warm (GloomsAuras Core.lua).


## Config UI — deferred feedback (the owner, 2026-07-18, in-game QA of the editor)
The owner chose to defer these to keep wiring the sub-panels; revisit after breadth:
- ✅ **DONE (session 4): overlays now match the pill SHAPE + span the construction** (hover/checked/flash
  ring, cooldown sweep, cast fill/ring/interrupt).
- ✅ **DONE (session 7): the "size/width slider" + "state highlights too subtle"** — State Highlights got a
  **Glow width** slider AND the ring art was made bolder (full-alpha ADD rim). Both resolved.
- **Flyout buttons (pet/stance/etc.) keep a square Blizzard background border** at the
  default size — `Suppress()` misses the flyout background art. Identify + suppress it.
- **Color picker is the Blizzard default ColorPickerFrame** — clashes with the family
  look. Build a custom family-styled picker (swatch grid + sliders/wheel). **(NEXT #2.)**


## Smaller anytime-items
- Aspect-correct mask art for stretched constructions (corner distortion on tall shapes).
- Count/Name per-style overrides; more layer kinds (border, badge, top plate).
- Pet/stance/extra-action/vehicle bars; minimap button + icon art (`## IconTexture`).
- ★ **WoWup install test on a second machine (NOT the owner's — would clobber the dev symlink).** This is
  now the suite's ONE open Phase G QA item; the script lives in `~/GloomsHub/docs/ARCHIVE.md`. The symlink
  hazard is real and confirmed: all four AddOns entries point straight into the dev repos, so a WoWup
  install on this machine writes over live source unless the symlinks are moved aside first.
- Late-phase: coexistence QA with ArcUI/EQOL re-enabled.

