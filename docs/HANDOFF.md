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

**Last updated:** 2026-07-26 (late) · **Shipped: `v1.2.0`** · **No open bugs.**
Release state is a SUITE fact — its home of record is `~/GloomsHub/docs/SUITE-STATE.md`.

---

## ★★ PER-BAR PRESET CONTEXT — the rule that has now broken twice

**Any code that loops over buttons and reads a preset value MUST supply the per-button context.**
Not doing so is silent: everything renders from `GB.db`, the working copy, so *every* bar shows the
preset currently being edited and nothing errors.

How resolution works: `pv(field)` returns `presetCtx[field]` if set, else `GB.db[field]`. `presetCtx`
is set from a **button** — `presetFor(btn)` — and returns nil when the bar wears the preset being
edited (that bar *should* follow the working copy). Two ways to supply it:

- `withPresetCtx(fn)` — the decorator. Works only for helpers whose **first argument is the button**.
- `Skin:EnterButtonCtx(btn)` / `Skin:LeaveButtonCtx(prevP, prevS)` — for everything else.

⚠ **`applyTexCoord(icon)` takes the ICON, not the button.** It can therefore NEVER be wrapped, and
depends entirely on its caller's enclosing context. Same trap applies to every other sub-object
helper — `ExtensionHeight(icon)`, `maskPlan(icon)`, `applySwipe(cd)`, `applyBorderColor(tex)`.

**Fixed 2026-07-26, owner-QA'd** — `SetZoom` and `SetIconFill` now enter the ctx around
`applyTexCoord`, and `refreshIconGeometry` joined the `withPresetCtx` list (it is reached by
`RefreshAll` → `SetSizeScale`, which is what a **preset switch** runs — that is why the wrong crop
survived a `/reload`). Symptom was the Icon Zoom slider moving every bar on screen.

**The audit, worth repeating after any new live setter:** list every `GB:ForEachButton` loop in
`Skin.lua` and confirm each supplies context. At the time of the fix: ten loops, eight already
correct (six via `withPresetCtx`, two setting `presetCtx` by hand), two wrong.

★ `Skin.lua:1408`'s comment records the **earlier** round of this same bug, where icon *size* went to
the working copy for bars on a non-edit preset. Saved data was never involved either time — presets
kept their own distinct values throughout, which is how you tell resolution from corruption.

---

## ★ Per-action icon overrides — `GB.Icons` (2026-07-26, owner-QA'd)

Swap icon art on GB's action buttons **only**. A custom pack in `Interface/ICONS` is global — the
same `.tga` feeds bags, spellbook, tooltips and the Cooldown Manager — so padding an icon to survive
a wide button's crop changes it everywhere. Art registered here is seen by nothing else, so it can be
padded to exactly the margin the bar's aspect needs.

**Keyed by spellID / itemID, never by art filename.** `GetActionTexture` returns a fileDataID in
modern retail, so keying by name would need a ~32k mapping table in the addon. `GetActionInfo` gives
the spellID directly; macros key on the spell the macro currently casts.

| Piece | What it is |
|---|---|
| `Icons.lua` | the engine + `/gb icon` command |
| `IconsManifest.lua` | **GENERATED** index, tracked, **committed EMPTY on purpose** |
| `tools/build-icon-manifest.sh` | scans `IconsHD/`, rewrites the manifest |
| `Rebuild Icons.command` | Finder double-click wrapper for the above |
| `tools/install-icon-watcher.sh` | OPTIONAL LaunchAgent, **not installed** |
| `tools/find-icon.sh` | spellID → which icon art the game uses |
| `Find Icon.command` | Finder double-click wrapper for the above |
| `IconsHD/` | the art — **gitignored, and the only copy in existence** |

Two sources, **explicit `/gb icon` override beats the manifest**, so a quick experiment always wins.
Naming: the ID is the **last** `_`/`-` segment (`hunter_mm_aimedshot_19434.tga`); everything before
it is for the owner's sorting. `i` prefix on the final segment means an item.

**★ WoW exposes NO filesystem API** — an addon cannot list a folder or test whether a file exists.
That is the whole reason the manifest exists, and it is why a wrong filename yields a **blank icon**
rather than an error. Never "improve" this by trying paths speculatively.

⚠ **`IconsManifest.lua` is COMMITTED EMPTY and will always show as a local modification.** That is
deliberate, not drift. It is *tracked* so the file always exists — a TOC entry pointing at a missing
file risks the addon being flagged corrupt — but a *populated* manifest names art nobody else has, so
shipping one would give every other installer **blank icons on those exact spells**. **Never commit a
populated manifest.** The owner's real one regenerates any time from `Rebuild Icons.command`.

### Finding the ORIGINAL art to edit
A spellID appears nowhere in an icon's filename — the game maps spellID → fileDataID →
`interface/icons/<name>.blp`. Fetch: Eagle's icon is `inv_111_hunter_ability_featheredfrenzy`, which
no amount of searching for "fetch" or "eagle" will surface. `Find Icon.command` resolves it and
copies the original into `IconsHD/` pre-named for the manifest.

⚠ **It scrapes Wowhead** — fragile by nature. It reports and stops rather than guessing whenever the
page yields anything other than exactly one icon. **Spells only**: item pages key their icon
differently and are NOT handled, so an item (e.g. a healthstone) still needs finding by hand.

⚠ **`/gb icon key` cannot do this, and do not re-try it.** `C_Texture.GetFilenameFromFileDataID`
exists but has **no name for Blizzard's packed assets** — it returns the literal string
`"FileData ID 538745"`. An earlier attempt printed that as though it were a filename. The command now
requires a real path and says plainly when the client has no name. **Tested 2026-07-26.**

Applied from three places in `Skin.lua` — once in `ApplyButton`, and re-applied inside the existing
`Update` and `UpdateButtonArt` hooks, because Blizzard re-sets the icon on every page flip and slot
change. With no override GB does not touch the icon at all.

---

## ★ Quick Keybind's gold square — adopted at last (2026-07-26, owner-QA'd)

`QuickKeybindHighlightTexture` was the ONE button-state texture the skin never adopted — its
siblings (`HighlightTexture`, `CheckedTexture`, `Flash`) are all retextured and anchored — so it drew
Blizzard's square art at Blizzard's size, proud of every shaped icon, on both clients.

Handled the way GB already handles the other three: **hand shape suppresses it** and a shaped glow
carries the state; **SDF fallback keeps Blizzard's art** but anchors it to the icon.

- The glow is a built-in `keybind` trigger in `Glows.lua`, **top priority** in `winningTrigger` (while
  the mode is open you need to see what is bindable, not what is proccing), **non-pulsing**, and
  **inner-only at 0.6 opacity** — it lights every button at once and holds, so the first attempt at
  full opacity on both layers read as a wall of gold. Same reasoning as the `selected` seed.
- Deliberately **not** in the Glows/Anims config lists: it is a mode indicator, not a combat state.
- ⚠ **Suppression must NOT go in `Skin.lua`'s one-time state-art block.** Blizzard creates that
  texture only when the mode first opens, so the nil-guard there is never true — it fails silently
  and looks handled. It is done in `Glows:SetKeybindMode`, a frame after the mode opens.
- Known edge, matching existing behaviour: **glows off + hand shape → no keybind indicator at all**,
  exactly as hover/selected/flash already behave.

---

## ✅ CLOSED, NOT A GB BUG — the frame-level stack does NOT block Quick Keybind Mode (2026-07-26)

**Full record and evidence: `~/GloomsHub/docs/FINDINGS.md` §8. Don't restate it here.** What belongs
in this file is the GB-side reasoning. **No code change was made, and none is needed.**

`Skin.lua:1378` raises `TextOverlayContainer` to `btn:GetFrameLevel() + 4`. That is **deliberate,
correct, and now proven harmless** — it is the top of a stack the skin depends on:

| Layer | Level | Set at |
|---|---|---|
| plate gradient | `+1` | `Skin.lua:1224` |
| decor | `+2` | `Skin.lua:1292` |
| glow / overlay | `+3` | `Skin.lua:790`, `:2715` |
| **`TextOverlayContainer`** | **`+4`** | **`Skin.lua:1378`** |
| cooldown-and-above | `+5` | `Skin.lua:1753` |

The comment at `Skin.lua:790` records the intent — *"above icon, below text (TextOverlayContainer =
+4)"*. **Do not "fix" this by lowering the container**; hotkey and count text would fall behind the
skin, which is the problem this stack exists to prevent.

### What was claimed, and why it was wrong
An earlier session claimed the container is **mouse-enabled** and outranks the button for mouse
focus, so Quick Keybind Mode never receives the hover — "proven with `/fstack`". **Both halves are
dead** (owner-tested on live, 2026-07-26):

- **The stack is present on LIVE and binding works fine.** Same container at 56 over the same button
  at 52, gold highlight showing, bind assigns normally. So the raise cannot be what blocks it.
- **`/fstack`'s `-->` arrow is not mouse focus** — it is the topmost frame under the cursor,
  mouse-enabled or not. On a button's edge it marks GB's own decor frame (`Skin.lua:1290`), and
  **`Skin.lua` contains no `EnableMouse` call at all** — that frame cannot hold focus. We therefore
  have no evidence `TextOverlayContainer` is even mouse-enabled.

**Do not write `EnableMouse(false)` on the container.** It was only ever a guess resting on the
reading above, and the symptom it targeted is gone from both clients.

**Do not "fix" the stack by lowering the container** either — that part of the old note still
stands, and for the original reason: hotkey and count text would fall behind the skin.

The symptom itself was real on the PTR and is now **non-reproducible there too**. Prime suspect is
the competing UI suite on that client (FINDINGS §4), which has already manufactured one convincing
false 12.1 bug — though its action-bars module was already disabled at the time, so the cause is
genuinely unknown. **Nothing to do in this repo unless it comes back with new evidence.**

---

## Colour swatches carry a LABEL (2026-07-26)

`Config.lua` wraps `UI.colorSwatch` in a local that prefixes **`"Bars › "`**, so each of the 20 call
sites passes only its own short name (`"Border color"`, `"Glow › " .. label`). Those names are what
the Hub's colour picker lists as *where a colour is in use*. **Six of GB's swatches read only
"Color" on screen** — the section prefix is what tells them apart in that list, so keep new labels
section-qualified.

★ **GB needs no colour ENUMERATOR, unlike GA and Overlays.** Its colours are **one per PROFILE**
(`GB.db.styleData`, `GB.db.triggers`, `GB.db.*`), not one per bar — so a plain getter already
describes them completely. Verified 2026-07-26; an earlier claim that these were per-bar was wrong.

`SKIN_NEEDS` stays **5**: passing the extra label argument is ignored by an older Hub.
**Contract in `~/GloomsHub/docs/CONTRACTS.md` §4.**

---

## ★ FONT WRITES ARE GUARDED — `GB.SetFontSafe` (2026-07-26)

**`SetFont` RAISES on a missing font asset; it does not return false.** Every `if not
fs:SetFont(…)` guard in the suite was written on the opposite assumption, so the fallback never ran
and the raise escaped into the caller. Use **`GB.SetFontSafe(fs, path, size, flags)`** (`Core.lua`)
for every font write in this repo — it `pcall`s, falls back to the bundled `GB.FONT.label`, and
returns whether the requested face applied.

**Why the bar engine specifically.** Hotkey / count / name faces resolve from a user-chosen **LSM
name**, and LSM will hand back a path whose file is gone: `Fetch(…, true)`'s silent-nil rescue only
fires when the lookup MISSES, and a name registered for a missing file *hits*. The Hub's own Media
tab can create exactly that — it cannot verify files, because WoW exposes no filesystem API. Applied
at the four engine writes in `Skin.lua` (hotkey / count / name / the size-normalising write), at
`PreloadFonts`, and at the two `Config.lua` guards. Owner-QA'd 2026-07-26: a dead LSM font selected
for keybind text falls back visibly instead of raising, and combat is unaffected.

⚠ **`Config.lua` now declares `SKIN_NEEDS = 5`** — it branches on `UI.setFont`'s return value, which
only exists from LibGloomSkin MINOR 5. Against an older Hub that return is `nil`, so
`if not setFont(…)` would take the fallback branch every single time. See the Hub's CONTRACTS §4/§6.

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

## Session-14 bugs and the four owner decisions — ALL CLOSED, moved to the archive

Resolved 2026-07-24/25, archived 2026-07-26. Full text in [ARCHIVE.md](ARCHIVE.md) — including why
the modifier-symbol outline was DROPPED, which is the one a session might re-propose.

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

