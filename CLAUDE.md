# Gloom's Bars — project guide

> **▶ NEW SESSION: read [docs/HANDOFF.md](docs/HANDOFF.md) FIRST.** It has current build
> state, settled decisions (do not relitigate), verification gates, how the owner works, and
> the next steps. Then this file (conventions), [docs/API-NOTES.md](docs/API-NOTES.md)
> (verified client facts — button anatomy, mask rules), [docs/SPEC.md](docs/SPEC.md)
> (the original design brief — note its "pure skin vs skin+geometry" fork is now *decided*:
> we own geometry, see below), and `docs/wow-addon-dev/` (vendored addon-dev skill).
> The frozen references [docs/SHAPE-CATALOG.md](docs/SHAPE-CATALOG.md),
> [docs/EFFECTS-MATRIX.md](docs/EFFECTS-MATRIX.md), [docs/ART-SPEC.md](docs/ART-SPEC.md) still apply.

> **▶ PART OF THE GLOOM SUITE.** Gloom's Bars is being unified with Gloom's Auras + Gloom's
> Overlays under a shared base addon, **GloomsHub** (`~/GloomsHub`). All cross-cutting suite
> facts — the plan, current phase status, and shared runtime contracts — live THERE and are the
> single source of truth; this repo does not keep its own copy. Before any *suite* work (mounting
> GB's config into the shared tabbed window, the shared toolkit/tokens, media/resolver), read
> `~/GloomsHub/docs/HANDOFF.md` FIRST — it is the active-phase cold-start briefing, and **Phase C
> (next) migrates THIS repo's config into the Suite window** — then SUITE-STATE.md / SUITE-PLAN.md /
> CONTRACTS.md. Normal GB-only work (skin, glows, layout, bugs) proceeds here as usual.
> **Gloom's Build Barn is NOT in the suite.**

Bespoke WoW addon: an **appearance + geometry layer** for Blizzard's built-in action bars —
rounded / non-square icons, restyled text, **shape-matched proc glows + cooldown sweeps**
(the differentiator), a per-trigger animation system, and **opt-in per-bar layout** (size,
gaps, rows, orientation, count, visibility, position). Target: **Midnight 12.0.7**
(Interface `120007`), retail only. Third sibling to GloomsAuras + GloomsBuildBarn
(author "Gloom", guild Hand of Devastation).

## The one principle that matters
**Never replace Blizzard's secure buttons — only restyle them and re-arrange their
unprotected containers.** Style Blizzard's *rendered output* and *react to Blizzard's
events*; never *compute* combat state from secret data. This addon owns look, and — where
a bar is opted in — owns geometry by moving/scaling the **plain unprotected button
containers** Blizzard lays the secure buttons inside (never the secure buttons themselves).
Everything hard about full bar replacements (custom secure buttons, casting machinery,
secure state drivers) is still avoided by staying a layer over Blizzard's own buttons.

### Hard walls (still absolute)
- **Move / resize / show / hide of secure buttons — or anything that re-lays them —
  OUT OF COMBAT ONLY.** In combat every geometry apply degrades to a queued flag, flushed
  on `PLAYER_REGEN_ENABLED` (the Layout engine's pattern; the Skin engine's `reassert`
  frame does the same for hit-rects). We move/scale the *containers* (unprotected), never
  the secure buttons — but that still counts, so it stays gated.
- **Never read secret combat values in Lua** (cooldown remaining, charges, and treat
  range/usability as suspect). React to Blizzard's *rendered output* and *events* instead.
  The one sanctioned indirect route in use: a hidden proxy `Cooldown` widget fed
  `C_ActionBar.GetActionCooldownDuration(..., ignoreGCD=true)` and read only via its
  rendered lifecycle (`IsShown`/`OnCooldownDone`) — no secret value ever reaches Lua
  (drives plate dim-on-cooldown; see HANDOFF SESSION 12 PART B).
- **Keybind changes — OUT OF COMBAT ONLY.**
- **Combat-edge visibility flips** go through `RegisterStateDriver(bar, "visibility",
  "[combat] show; hide")` — the only sanctioned way to flip a bar across the combat edge.
  Nothing insecure may touch a bar once combat starts (this even includes
  `SetPropagateKeyboardInput` — it's combat-restricted).
- **`GB:RefreshAll` is COMBAT-GATED and must stay that way.** It is the widest simultaneous
  secure-button pass (a profile/preset switch re-applies skin+glows+layout across every
  button); ungated in combat it taints buttons and freezes cooldowns. It defers its visual
  re-apply to `PLAYER_REGEN_ENABLED` in combat; only the Config-UI refresh runs immediately.
  See [[refreshall-combat-gate]]. (Individual Skin setters — SetAlpha, a texture write — are
  combat-safe alone; it's the full simultaneous re-apply overlapping Blizzard's secure
  update that taints.)

## Settled decisions (do not reopen without the owner)
> **Framing rule (the owner's, absolute): there is NO "v1", no "later phase", no "pure skin"
> era.** This is one continuous build. Bar layout is committed roadmap work that is now
> BUILT. "Deferred" means "not now, still on the roadmap" — never "maybe never." Do not
> reintroduce version/phase language anywhere the owner can see it, or in these docs.

- **We own geometry (opt-in, per bar).** The old SPEC "pure skin vs skin+geometry" fork is
  decided: Edit Mode owns any bar *not* flipped to us; a bar opted in (Config → Bar layout)
  is arranged by GB via its containers. Master switch is all-or-nothing across bars; per-bar
  tables are settings. (HANDOFF SESSION 13 PART D.)
- **All ten bars are in scope and built:** action bars 1–8 **plus the Pet bar and Stance
  bar**, both fully skinned AND layout-managed (they're real `EditModeActionBarTemplate`
  bars built by the shared `ActionBarMixin` with `.container`/`.bar` — verify the shared
  builder, not per-icon code). Extra-action / vehicle-leave and the buff/debuff frame are
  out of scope (different templates, no procs/sweeps). (HANDOFF SESSION 14 PART D.)
- **Profiles → whole-look presets → per-bar assignment** is the settled architecture (see
  Conventions below). Per-character *active* profile; the preset library is shared
  account-wide.
- **Standalone skinning** — no Masque integration.
- **Slash `/gb`** (long-form alias `/gloomsbars`) — but for **DIAGNOSTICS ONLY**. Every
  *user* control lives in the Config GUI; the owner tests there and dislikes slash/CLI for real
  features. Dev slash probes are KEPT until the build settles. `/ga` = GloomsAuras,
  `/glooms` = Build Barn. See [[gui-not-slash-commands]].

## Conventions
- **Namespace** `GB` → `_G.GloomsBars`; **SavedVariables** `GloomsBarsDB`. Plain frames,
  plain SavedVariables, no Ace3.
- **Libraries** are embedded under `Libs/` (LibStub, CallbackHandler-1.0, LibDataBroker-1.1,
  LibDBIcon-1.0 — for the minimap launcher) and pulled by the packager via `.pkgmeta`
  externals; `Libs/` is git-ignored and present only in the working copy. They load FIRST
  (see the TOC).
- **Data model — `GloomsBarsDB`:**
  - `db.profiles[name] = { presets = { [presetName] = <PRESET_FIELDS deepcopy> },
    bars = { [buttonPrefix] = presetName }, edit = presetName }`. A **preset is the whole
    look** (the fields in `GB.PRESET_FIELDS`, ~36 of them); `bars` assigns one preset per
    action bar; `edit` is the preset the Config is currently editing.
  - `db.charProfiles["Char-Realm"] = active profile name` — active profile is per-character;
    the profile library is account-wide. First login auto-creates a **"Name - Realm"**
    profile (the GloomsAuras convention the owner cites).
  - **`GB.db`'s visual fields ARE the live working copy** — the engine renders them, the
    Config mutates them. Loading a preset writes it over the working copy + `RefreshAll`;
    saving snapshots the working copy into a preset. **The bar wearing the profile's `edit`
    preset renders the working copy live (editing stays live); bars on OTHER presets render
    snapshots** — the per-button ctx resolution (`presetCtx` + `pv()` in Skin.lua, exported
    to Glows/Anims). Bar *layout* geometry lives in `profile.barLayout[barKey]`, per bar per
    profile — NOT in a look preset (layout is geometry, not look). See
    [[profiles-presets-per-bar]].
- **In-game UI follows the GloomsAuras design language** — same tokens (bright purple
  `#936bff` on near-black navy; Khand titles + GeneralSans body, both in `GB.COLOR`/`GB.FONT`
  in `Core.lua`, fonts bundled in `Media/fonts/`), sliding switches not checkboxes, no native
  Blizzard UI textures/widgets, pixel-perfect to mocks. Buttons name the **next action**
  ("Move Bars" ↔ "Lock Bars"). Every flat button is PURPLE off/unselected, ORANGE
  on/selected. Title-case button/chip/option labels; sentence case for field labels,
  headers, hints, tooltips. Reuse GloomsAuras's Config toolkit patterns
  (`~/GloomsAuras/Config.lua`). The owner has **Figma mockups for GloomsAuras**
  as the styling basis (Figma desktop MCP tools may be available; else ask for screenshots).
- **No engine jargon in anything the owner sees** — UI text, chat, or these docs. "Ownership,"
  "ctx," "reconcile" mean nothing to him; name controls by their visible effect.

## Files
- `GloomsBars.toc` — manifest (Interface 120007, `## IconTexture` → minimap art). Declares
  load order: `Libs/*` first, then `Core → Skin → Glows → Anims → Layout → Config →
  MinimapButton`.
- `Core.lua` — namespace, design tokens (`GB.COLOR`/`GB.FONT`), `GB.SHAPES` (shape registry)
  + `GB.STYLES` (decoration-style recipes), saved-var load + legacy-shape migration,
  **the profiles/presets data model** (`GB.PRESET_FIELDS`, `Snapshot`/`SavePreset`/
  `LoadPreset`, profile CRUD, `SetActiveProfile`, `RefreshAll` — the combat-gated composite
  refresh), `GB.BARS` (all 10 bars) / `GB.BUTTONS_PER_BAR` / `GB:ForEachButton` (honours a
  bar's own `count`), `InitMinimapButton`, and the `/gb` diagnostic router.
- `Skin.lua` — GB.Skin: the skin engine (zoom/mask/art-suppression, cooldown sweeps, state
  art, cast/channel shaping, usability/OOM/range tints, empty-slot dim/hide, text styling for
  keybind/count/countdown/name incl. the Midnight font-object shadow, hit-rect extension for
  non-square shapes, re-assert hooks) + the decoration/construction engine (gradient plate,
  border, bidirectional + continuous extension). Owns the **per-button preset ctx** (`pv()`
  read funnel) exported to Glows/Anims, and the preset-focus highlight.
- `Glows.lua` — GB.Glows: shape-matched glow engine. Per-trigger model (`db.triggers`); every
  button state (proc/assist/highlight/cast/channel/hover/selected/flash) drives the
  multi-part glow, reconciled by the winning trigger. Calls `GB.Anims:Reconcile`.
- `Anims.lua` — GB.Anims: per-trigger ANIMATION SYSTEM — a plug-in registry, one module per
  animation (Comet Chase, Marching Lines, …). Modules render on bars AND the Config preview
  (host-keyed). New animation = one new module.
- `Layout.lua` — GB.Layout: the opt-in per-bar layout engine. Re-anchors + re-scales the
  **unprotected button containers** (never the secure buttons) into GB's grid: size, gaps
  (main + cross axis, negative allowed), rows/cols, orientation, count (hides surplus
  containers), visibility (incl. combat/out-of-combat via `RegisterStateDriver`), and
  position (drag movers + arrow-key nudge). **All geometry OUT OF COMBAT ONLY**, queued +
  flushed on `PLAYER_REGEN_ENABLED`. Also hosts the Quick-keybind launcher reskin.
- `MinimapButton.lua` — the minimap launcher (LibDBIcon/LibDataBroker, with a self-contained
  fallback if libs are absent) + title-bar logo wiring. Left-click opens Config. Data in
  `db.minimap` (account-wide). **New file → needs a full client RESTART to load, not a
  /reload.**
- `Config.lua` — the style editor. `/gb` opens it. **Three-panel window:** a left RAIL
  (profile + preset selection, always visible) · a middle scrollable one-open ACCORDION
  (all the controls) · a right PREVIEW pane, over a footer (Enable toggle, Quick keybind,
  Move Bars, preset-focus highlight). Toolkit + all wired sections + the working-copy model.
- `Media/masks/`, `Media/art/` — generated shape + animation art. `tools/generate-art.py`
  regenerates the SDF masks/rings/swipes (edge-padding rule in API-NOTES §2). **Full regen
  is slow (~4 min); regen ONE shape** with `python3 tools/generate-art.py <name>`; the
  aspect-correct pill masks (`pill-<t|w>-a<ratio>-r<N>`) regen alone (fast) with `python3
  tools/generate-art.py pills`. The other `tools/generate-*.py` scripts each bake one
  animation's texture (march, shine, sheen, sparkle, radar, hand-swipes, modifier glyphs).
  `Media/ui/` — Config chrome (`caret.png`, `checkmark.png`, `logo.png`, `minimap.png`) +
  modifier-key glyphs (`cmd/ctrl/opt/shift.png`).
- **Two shape systems — know which is which:**
  - **The live icon-shape system is the hand-authored catalog** (`db.handShape` →
    `GB.HAND_SHAPES` / `GB.HAND_ORDER`, art under `Media/art/hand/<key>-base|-outer|-inner.png`).
    It's the ~21-preset set the Config picker exposes, grouped 1:1 / Portrait / Landscape.
    **Session-8 pivot (settled): free width/height was RETIRED** — the icon is one preset +
    a uniform `sizeScale`, and the engine derives W/H from the preset's baked
    `aspect × orient × naturalSize × sizeScale`, so a silhouette can never stretch. This is
    why there are no discrete height/width controls; aspect ratios are baked into the
    presets (`pill32`/`pill21`, `square32`/`square21`, the `roundsq*-32/-21` families, etc.).
  - **The older `corner-*` registry** (`db.shape` → `GB.SHAPES`, keys
    `corner-<TL><TR><BL><BR>-r<N>`, plus `circle`/`hexagon`; masks/rings/glows under
    `Media/art` + `Media/masks`) was a *per-corner rounding* design that predates and was
    superseded by the catalog. It is NOT the user-facing shape picker (there is no corner
    picker) and it is NOT *the* shape system — but it is NOT dead either: it supplies
    fallback ring/glow/mask textures (`GB:GetShape()` in Skin.lua when no hand shape is
    active) and a couple of geometry special-cases (circle → continuous sweep, hexagon
    extension). Migration maps legacy `roundrect → corner-1111-r2`, `square → corner-0000-r0`.
  - **Only 4 corner patterns exist on disk / are registered** (per-corner MIXING was cut
    2026-07-19): `1111` (all-round / roundrect), `0000` (square), and `0011` / `1100` — the
    **plate half-shapes** (rounded icon end, sharp plate end) that `Skin.lua`'s
    `mixedCornerBase()` builds at runtime for the plate glow + cast-fill. The migration
    actively COLLAPSES any saved mixed value to `corner-1111`. The other 12 mixed patterns
    (`corner-0001`, `corner-0110`, …) were **deleted as dead assets (~2 MB)** — do NOT
    re-add them. The set is kept in lockstep across three places: the art
    (`tools/generate-art.py` `CORNER_PATTERNS`), the registry (`Core.lua`'s registration
    loop), and this note. Regen ONE shape with `python3 tools/generate-art.py <name>`
    (full regen is slow, ~4 min); pill masks regen fast via `python3 tools/generate-art.py
    pills`.

## Debugging protocol (hard-won — do not relearn these)
- **When a rendered value is wrong or keeps reverting (colour / font / anchor / alpha),
  TRAP THE ACTUAL WRITE** — `hooksecurefunc(region, "SetFont" / "SetVertexColor" /
  "SetTextColor", …)` + `debugstack` — to name the exact caller (file:line + addon) in ONE
  reload. Do NOT infer, and do NOT grep-and-accuse other addons: sessions have been burned
  blaming innocent addons before a write-trap named the real culprit immediately.
  See [[fontstring-setvertexcolor-trap]].
- **`SetVertexColor` tints FontStrings too** (not just textures), and its 4th arg is alpha —
  it silently overrides `SetTextColor`/`SetAlpha`. Blizzard's range indicator recolors the
  hotkey via `SetVertexColor` on a continuous OnUpdate timer; re-assert in a
  `hooksecurefunc(..., "SetVertexColor", …)` post-hook.
- **Probe-first for suspected GB bugs.** Confirm the *culprit* before writing a fix — several
  "GB bugs" turned out to be Blizzard working as intended (proven by a temporary probe +
  testing with GB disabled + reading Blizzard's source). A fix that fights the game is worse
  than no fix. When the owner says he tested/disabled a suspect, BELIEVE him and stop re-accusing.
- **Blizzard's real 12.0.7 source is ON DISK** at `/Applications/World of Warcraft/_retail_/
  BlizzardInterfaceCode/Interface/AddOns/…` (e.g. `Blizzard_ActionBar/…/PetActionBar.lua`,
  `ActionButton.lua`) — READ IT for pet/action-bar behaviour instead of guessing.

## Testing workflow
The repo root **is** the addon folder, symlinked into the client at
`/Applications/World of Warcraft/_retail_/Interface/AddOns/GloomsBars`. QA is done by the owner
(non-developer): give **ONE copy-paste instruction at a time**, verify before claiming, and
when something misbehaves ask for the **BugSack error text first**. New files or new media
assets require a **full client restart** (a /reload only re-reads existing files). See
[[how-owner-works]] and [[dont-swirl-stabilize-early]].

## Git / releases
GitHub Releases via BigWigs packager (`.github/workflows/release.yml`), fired by pushing a
version tag (e.g. `v0.3.0`). WoWUp installs/auto-updates from the repo URL. No
CurseForge/Wago. `## Version: @project-version@` in the TOC is filled by the packager.
Last shipped tag: **v0.2.0** — a large body of work since then is unshipped, so a tag is
warranted whenever the owner wants to cut one.
