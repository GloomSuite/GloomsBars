# Gloom Suite — unification plan (GloomsHub + tabbed shell)

> **Status:** PLAN ONLY — nothing built yet. Durable reference across sessions.
> **Goal (the owner's):** one unified, modular, **tabbed** interface fronting all the Gloom tools,
> *and* eliminate the scattered/duplicated plumbing between them. Each tool stays its own
> addon (separate release); a small shared base — **GloomsHub** — owns the one window, the
> shared toolkit, and the media plumbing.
>
> No "v1"/"later phase" framing — this is one sequence to completion (phased for safe QA,
> not because any part is optional).

## Decisions locked with the owner (do not reopen without him)
- **Shared base = `GloomsHub`.** Folder/asset path is permanent: `Interface\AddOns\GloomsHub\…`
  (the resolver depends on it — never rename after assets ship there). Product-facing window
  title: "Gloom Suite". Neutral slash: `/gloom`.
- **StoneTweaks is fully RETIRED — name and all.** Its useful half (font/graphic/texture
  registration + the resolver) is **absorbed into GloomsHub** as the **Media tab**. There is
  **no** standalone media addon. Its ElvUI half is dropped entirely.
- **VibeOverlay is renamed to `Gloom's Overlays`** (folder `GloomsOverlays`) and **reskinned
  into the Gloom design language in one go** when it is mounted (no interim native-looking
  state). The `Vibe`/`VibeOverlay` name is not preserved anywhere user-visible.
- **StoneCast** — already deleted by the owner. Ignore.
- **The family after this work:** `GloomsHub` (base) + `Gloom's Auras`, `Gloom's Bars`,
  `Gloom's Overlays` as tabbed tools, with the **Media** tab living in the Hub. `Gloom's
  Build Barn` is a future consumer — the shell's tab API must let it register a tab later
  with zero shell changes.

---

## 0. Ground truth (verified in code before this plan)

- **Four addons present** in `…/Interface/AddOns/`. GloomsAuras & GloomsBars are symlinks to
  `~/GloomsAuras` / `~/GloomsBars`; VibeOverlay (→ Gloom's Overlays) & StoneTweaks live
  directly in AddOns. `GloomsBuildBarn` is a fifth sibling sharing the same tokens (future).
- **The design language is genuinely duplicated.** `GloomsBars/Core.lua` and
  `GloomsAuras/Core.lua` define byte-for-byte identical `COLOR` and `FONT` tables (same
  `#936bff` purple, `#12131F` plate). GB's `Config.lua` says its toolkit was "ported from
  GloomsAuras/Config.lua — same primitives." So the widget toolkit (`setFont`, `newText`,
  `flatButton`, `makeToggle`, sliding switches, `makeScrollbar`, `makeSection`, …) exists in
  two hand-maintained copies today. Unifying it is real de-duplication.
- **Both GB and GA build fully standalone windows.** GB: `BuildPanel()` (`Config.lua` ~3256)
  creates `GloomsBarsConfig` on UIParent with its own title bar, logo, close, drag, footer,
  left rail, middle scroll+accordion, right preview; registers into `UISpecialFrames`;
  toggles via `C:Toggle()` (~3430). GA is structurally the same. **This window chrome is
  what gets replaced; the section builders are reused.**
- **The resolver contract is exact.** `StoneTweaks_ResolveAssetPath(name)` (`StoneTweaks.lua`
  ~142-155) searches `StoneTweaksDB.textures` then `.graphics`, returns
  `Interface\AddOns\StoneTweaks\{Textures|Graphics}\<file>`. **TWO consumers depend on it:**
  - **VibeOverlay** (`VibeOverlay.lua:155`) — `StoneTweaks_ResolveAssetPath and …` (guarded,
    so it no-ops safely if absent — but then graphics don't resolve).
  - **GloomsAuras** (`Config.lua` ~1125-1141, `CatStoneTweaks`) — does **NOT** use the
    resolver; reads `_G.StoneTweaksDB.graphics/.textures` **directly** and hardcodes
    `Interface\AddOns\StoneTweaks\…` paths inline. A **second, separate** ST dependency.
- **What ST registers:** `RegisterFont` → `lsm:Register("font", …)`; `RegisterTexture` →
  `lsm:Register("statusbar", …)` at `PLAYER_ENTERING_WORLD`; graphics are deliberately NOT
  in LSM (name→path only).
- **ElvUI cruft is confined & separable.** In `StoneTweaks.lua`: `StoneTweaks_FrameDefs`
  (`ElvUF_*`), frame-texture/backdrop hooks, glow suppression, the whole `[st:style:*]` tag
  engine (incl. a `loadstring` factory). In `StoneTweaks_UI.lua`: the **Frames** and **Names**
  tabs. The salvage set (Fonts/Textures/Graphics registration + resolver) has **zero** ElvUI
  refs and lifts cleanly.
- **ST asset inventory (must not be lost):** `Fonts/` 8 files incl. `DrukMedium.ttf` (a stray
  `BoordensStreet.otf` WoW can't load — ST already rejects `.otf`); `Textures/` 13; `Graphics/`
  45. `StoneTweaksDB` holds the name→file registrations the user actually named.
- **Gloom's Overlays core is clean** (0 ElvUI). Its UI is native `BackdropTemplate` (to be
  reskinned). Editor label at `VibeOverlay_Editor.lua:464` reads "StoneTweaks name…".
- **Release model** (`.pkgmeta`): BigWigs packager → GitHub Releases only (no CurseForge/
  Wago), WoWup installs/updates from repo URL, `externals` fetched at build & gitignored.
  Neither GB nor GA uses `## Dependencies` today.

---

## 1. Architecture (validated)

**Keep separate addons + one shared base. Do NOT merge into a mega-addon** — that would
couple GB's combat-taint surface with Overlays' cosmetic code, and force one release cadence
across mature, independently-shipped tools. Separate addons keep each one's release, WoWup
entry, and blast radius independent.

**GloomsHub is a real ADDON (not just a library)**, because three of its jobs are singleton +
stateful + shared at runtime: (1) the one window all tools mount into; (2) the one
SavedVariable that owns the migrated media registrations; (3) the one asset folder the
resolver points at. A per-addon embedded library can't own a singleton window/DB/folder.

**Hybrid:** GloomsHub is the addon that owns the window + media DB + assets + Media tab. The
*stateless* design toolkit (tokens + widget factory) is **also** exposed as an embedded
LibStub lib — working name **`LibGloomSkin-1.0`** — so any tool can build widgets even before
the Hub's frames exist, with a versioned API. GloomsHub is the canonical shipper of that lib.

---

## 2. GloomsHub

### 2.1 Responsibilities
1. **Media plumbing** (salvaged from ST, so it survives ST's retirement): own `GloomsHubDB`
   with `fonts`/`textures`/`graphics`; register fonts/statusbars into LSM at
   `PLAYER_ENTERING_WORLD`; own the migrated `Fonts/`/`Textures/`/`Graphics/` folders; expose
   `GloomsHub:ResolveAssetPath(name)` → `Interface\AddOns\GloomsHub\{Textures|Graphics}\<file>`.
2. **The tabbed window shell** — one window, tab registry, focus API, shared chrome.
3. **Shared design toolkit + tokens** — `GloomsHub.COLOR/.FONT/.UI` and `LibGloomSkin-1.0`.
4. **The Media tab** — the reskinned Fonts/Textures/Graphics manager (from ST's salvaged UI),
   reading `GloomsHubDB`.

### 2.2 Files
```
GloomsHub/
  GloomsHub.toc         ## Interface: 120007, ## SavedVariables: GloomsHubDB
  Core.lua              -- namespace, GloomsHubDB, tokens, login/PEW wiring, ST migration
  Media.lua             -- salvaged registration + ResolveAssetPath + Media-tab builder
  Skin.lua              -- design toolkit (also the body of LibGloomSkin-1.0)
  Shell.lua             -- tabbed window: RegisterTab / Open / FocusTab / chrome
  Libs/                 -- LibStub, CallbackHandler, LibSharedMedia-3.0, LibGloomSkin-1.0
  Fonts/  Textures/  Graphics/   -- migrated from StoneTweaks (§4.3)
```
Load order: LibStub → CallbackHandler → LibSharedMedia-3.0 → LibGloomSkin → Core → Skin →
Shell → Media.

### 2.3 Dependency wiring
GB/GA/Overlays get `## Dependencies: GloomsHub` (WoW loads a dependency first → `_G.GloomsHub`
and `LibStub("LibGloomSkin-1.0")` are guaranteed present). This replaces GB/GA's current soft
`GetLSM()`/`LibStub(…,true)` probes with a hard guarantee. All TOCs standardize on
`## Interface: 120007`.

### 2.4 Dependency vs independent-release (the big process risk, honestly)
A hard dependency means "install Gloom's Bars → nothing until GloomsHub is also installed."
**Recommended:** GloomsHub ships as its **own** GitHub-Release/WoWup entry; GB/GA/Overlays
hard-depend on it; **`LibGloomSkin-1.0` is embedded in all of them** via `.pkgmeta` externals
(LibStub-style, newest-wins) as belt-and-suspenders so widget-building never hard-fails
mid-transition. One-time cost to the owner: add the GloomsHub repo to WoWup once (same as he
already does per Gloom repo). *During development this is moot* — GloomsHub just needs to exist
as a folder in AddOns; the `.pkgmeta`/release work is the LAST phase (G), after everything
works locally.

### 2.5 Sizing "the bulk of the work"
GB `Config.lua` ≈ 3430 lines: the window *chrome* (`BuildPanel()` ~3256-3415, ~160 lines) is
**replaced**; the other ~3200 lines (section builders + toolkit) are **reused**, just
re-parented into the shell's container. GA is the same shape. Per tool the refactor is:
(a) delete standalone-window chrome, (b) use `LibGloomSkin`/`GloomsHub.UI` instead of the
local toolkit copy, (c) wrap existing section-building in `build(container)`. Mechanical but
large; done one tool at a time behind a working game (§5).

---

## 3. The tabbed shell

### 3.1 Registration API
```lua
GloomsHub:RegisterTab{
  id      = "bars",              -- stable key, used by slash focus
  title   = "BARS",             -- Khand uppercase on the tab
  order   = 20,                 -- sort weight (Media = 90; tools 10..80)
  icon    = "…\\GloomsBars\\Media\\ui\\logo.png",   -- optional
  build   = function(container) … end,   -- called ONCE, lazily, on first show
  refresh = function() … end,   -- optional, called each time the tab is focused
}
```
- `build` runs **lazily** on first show of that tab (never at login — keeps login cheap,
  avoids first-session blank-font issues). Receives a `container` sized to the content area;
  the tool parents everything to it.
- `refresh` maps to each tool's existing `C:Refresh()` so live state re-syncs on return.
- A tool whose addon isn't loaded simply doesn't register — the shell shows only present
  tools' tabs plus the always-present **Media** tab.

### 3.2 Shell chrome + tab strip
One `CreateFrame("Frame", "GloomsSuiteWindow", UIParent)` in the Gloom language (near-black
navy plate, `#936bff`/`#ff7729` accents, the warm orange bottom-glow gradient from GB
`Config.lua` ~3264-3270, Khand title). Registers into `UISpecialFrames` (Escape closes) —
replacing the tools' three separate entries. Tab strip of `flatButton`s (purple unselected /
orange active — the family convention). Clicking a tab hides the current container, shows the
target's (ST_UI's page show/hide pattern, generalized over the registry). **Each tool's
former window-local footer controls** (GB's master Enable toggle, Move Bars, Highlight, etc.)
move **into that tool's tab container**, not the shared footer. Shared footer stays generic
(close; maybe a global profile indicator — open Q §6).

### 3.3 Slash routing
Each tool keeps its slash; all route to the shell:
- `/gb` (config branch only) → `GloomsHub:Open("bars")`. Every `/gb` **diagnostic** subcommand
  (`debug`, `mask`, `shape`, …) stays exactly as-is.
- `/ga` → `GloomsHub:Open("auras")`.
- `/go` (or a chosen slash) → `GloomsHub:Open("overlays")`; keep `/vibe` as a legacy alias so
  muscle memory survives. Overlays' `list`/`debug`/`reload` subcommands stay.
- `/gloom` → open on last-used tab. `GloomsHub:Open(id)` = show window + `FocusTab(id)`.
- **Toggle semantics preserved:** slash while open *on that tab* closes; while open on a
  *different* tab, switches tabs.

### 3.4 Per-tool refactor shape
Replace `BuildPanel()`'s window creation with `GloomsHub:RegisterTab{ build =
function(container) … end }`, body = the tool's existing pane/section construction re-parented
from `panel` to `container`. Retire the tool's `C:Toggle()` in favor of shell focus. Replace
local toolkit locals with `LibGloomSkin`/`GloomsHub.UI`. GB's rail+scroll+preview three-pane
layout becomes the layout *inside* the Bars container — section builders unchanged.

---

## 4. Media tab + StoneTweaks retirement

### 4.1 Salvage set (verbatim behavior), ST → `GloomsHub/Media.lua`
`DB_DEFAULTS.fonts/textures/graphics`, `GetLSM()`, `RegisterFont`, `RegisterTexture`,
`RegisterAll` (login registration). Public API renamed under the Hub:
`StoneTweaks_AddFont/…/AddGraphic/…` → `GloomsHub.Media:AddFont(…)` etc. (same validation,
incl. `.otf` rejection and `.ttf/.blp/.tga/.png` gates). `StoneTweaks_ResolveAssetPath` →
`GloomsHub:ResolveAssetPath`, base path `Interface\AddOns\GloomsHub\…`. From `StoneTweaks_UI.lua`:
the Fonts/Textures/Graphics sub-pages (list rows, add/remove, preview swatches) → the **Media
tab**, reskinned from `BackdropTemplate` into the Gloom toolkit (recommend the `makeSection`
accordion pattern for family consistency).

### 4.2 Dropped (gone with ST)
`StoneTweaks_FrameDefs` + all `ElvUF_*` hooks/backdrops/glow suppression; the entire
`[st:style:*]` tag engine (Frames + Names tabs; the `loadstring` factory); ST's `/st` command.

### 4.3 SavedVariables migration — the "don't lose DrukMedium" requirement
Users have `StoneTweaksDB.fonts = {{name="DrukMedium", file="DrukMedium.ttf"}, …}` + textures +
45 graphics referenced *by name* (Overlays) and *by path* (GA). One-time, automatic,
**non-destructive**:
1. GloomsHub `PLAYER_LOGIN`: if `GloomsHubDB.fonts` is empty **and** `_G.StoneTweaksDB`
   exists, **COPY** (not move) `.fonts/.textures/.graphics` into `GloomsHubDB`; set
   `GloomsHubDB.migratedFromST = true` (runs once). Copy → ST's SV untouched, rollback = just
   re-enable ST.
2. The asset files must physically exist under GloomsHub for new paths to resolve, so the
   `Fonts/Textures/Graphics/` folders are **copied into `GloomsHub/`** and committed as bundled
   addon assets. DB entries are `{name,file}` and the resolver rebuilds the path from its own
   base → once files exist under `GloomsHub/` and the DB is copied, every name resolves.
   **DrukMedium survives** = `{name="DrukMedium",file="DrukMedium.ttf"}` + `GloomsHub/Fonts/
   DrukMedium.ttf`.
3. Ordering: ST must still be installed at first migration (so `_G.StoneTweaksDB` is readable)
   → **ST is deleted LAST** (Phase F), after the owner confirms migration. Migration reads
   `_G.StoneTweaksDB` opportunistically and skips cleanly if absent (fresh install = nothing
   to migrate).

### 4.4 Redirect the two live consumers (with shims)
- **Gloom's Overlays** (`VibeOverlay.lua:155`): GloomsHub installs a global shim
  `StoneTweaks_ResolveAssetPath = function(n) return GloomsHub:ResolveAssetPath(n) end` (only
  if the real ST one isn't loaded) → Overlays keeps working the moment the Hub is installed,
  ST present or not. Then the call site is updated to `GloomsHub:ResolveAssetPath` and the
  editor label (line 464) to "Media name". Shim kept as a safety net.
- **GloomsAuras** (`Config.lua` ~1125-1141): reads `_G.StoneTweaksDB` directly + hardcodes ST
  paths → redirect to a new `GloomsHub:ListMedia("graphics")` accessor returning `{tex=path,
  name=name}` rows (GA never rebuilds paths again). Relabel "StoneTweaks Graphics" →
  "Suite Graphics". Transitional fallback reads either DB. GA's `CatLSM` (statusbar textures
  via LSM) is unaffected — now registered by GloomsHub, transparently.

---

## 5. Phasing — every step leaves the game working

**A — Stand up GloomsHub, media only (game unaffected).** Build GloomsHub: media registration
+ resolver + the copy-migration from `StoneTweaksDB` + the compat global shim; copy in the
asset folders. Touch nothing else. ST + Hub both run; shim only installs if ST's real fn is
absent. *QA:* `/reload`; GA's texture picker still shows the media; `GloomsHubDB` now has
DrukMedium et al.; Overlays still render their graphics. Nothing removed.

**B — Empty shell + Media tab.** Add `Shell.lua` (window + RegisterTab/Open/FocusTab) and
register the **Media** tab (reskinned, reading `GloomsHubDB`). Add `/gloom`. Leave `/gb /ga
/vibe /st` on their existing windows. *QA:* `/gloom` opens a Gloom-styled window with a working
Media tab (add/remove a font → registers). Old windows still work.

**C — Migrate ONE tool as proof: Gloom's Bars.** GB `Config.lua` registers a **Bars** tab
(`build(container)` wrapping its rail/preview/accordion); `/gb` config branch → `GloomsHub:Open
("bars")`; swap local toolkit → `LibGloomSkin`; keep all diagnostics + section builders. *QA:*
`/gb` opens the shared window on Bars; every section, preview, master Enable, Move Bars,
Highlight work as before; `/gloom` shows Bars + Media. GA/Overlays/ST untouched. **Make-or-break
proof of the container-mount pattern.**

**D — Migrate Gloom's Auras.** Register **Auras** tab; route `/ga`. Flip GA's `CatStoneTweaks`
→ `GloomsHub:ListMedia(…)` (Phase A left both DBs valid) + relabel. *QA:* `/ga` on Auras;
texture/font/sound/graphic pickers all populated; tabs = Auras, Bars, Media.

**E — Migrate + RESKIN Gloom's Overlays.** Rename VibeOverlay → Gloom's Overlays
(`GloomsOverlays`); register **Overlays** tab; route the slash. Update the resolver call (line
155) → `GloomsHub:ResolveAssetPath` and the label (464). **Reskin the editor/manager from
`BackdropTemplate` into the Gloom toolkit in one go** (the largest net-new UI chunk). *QA:*
Overlays tab in full Gloom styling; overlays render, editor edits, resolver resolves.

**F — Retire StoneTweaks.** With all consumers migrated and `GloomsHubDB` proven populated:
remove/disable the ST folder. The Hub's compat shim keeps `StoneTweaks_ResolveAssetPath` alive
globally for anything stale. *QA:* ST disabled + `/reload`: fonts registered, textures in
pickers, overlays render, all tabs work. If anything's missing → re-enable ST (SV intact),
recheck Phase A migration. (Why ST dies last + non-destructively.)

**G — Packaging / release.** Author `GloomsHub/.pkgmeta` (BigWigs; embed LibStub/
CallbackHandler/LSM/LibGloomSkin). Add `## Dependencies: GloomsHub` to GB/GA/Overlays.
Embed `LibGloomSkin-1.0` in each via `externals`. Document the one-time "add GloomsHub repo to
WoWup" step. Cut a coordinated release set. *QA:* fresh WoWup install of GloomsHub + one tool
works; updates work.

---

## 6. Open questions still to decide (non-blocking)
1. **Overlays slash** — `/go`? keep `/vibe` as a legacy alias (recommended)?
2. **Shared footer** — generic (close only), or a global profile/enable indicator across tools?
3. **Compat shim lifetime** — keep `StoneTweaks_ResolveAssetPath` global forever (free
   insurance, recommended) or remove once Overlays is updated?
4. **`LibGloomSkin` versioned API surface** — finalize exactly which toolkit fns are public.
5. **GloomsBuildBarn** — note it in GloomsHub docs as a future tab consumer?
6. **Stray `BoordensStreet.otf`** — carry into `GloomsHub/Fonts` (harmless dead file) or drop
   during the copy? (Minor.)

## Critical files for implementation
- `GloomsBars/Config.lua` — standalone window (`BuildPanel()` ~3256, `C:Toggle()` ~3430) +
  toolkit to extract into `LibGloomSkin`; the Phase-C proof tool.
- `GloomsBars/Core.lua` — tokens (`COLOR`/`FONT`), `GB.BUNDLED_FONTS`/`GetLSM`/`RegisterMedia`
  (~460-493), `/gb` router (~1226) to reroute.
- `StoneTweaks/StoneTweaks.lua` — salvage set: `RegisterFont`/`RegisterTexture`/`RegisterAll`
  + `StoneTweaks_ResolveAssetPath` (~142-155); ElvUI code to drop.
- `VibeOverlay/VibeOverlay.lua` — resolver consumer (line 155), `/vibe` router (~329).
- `GloomsAuras/Config.lua` — `CatStoneTweaks`/`CatLSM` (~1111-1158), the second hardcoded
  `StoneTweaksDB` dependency; the reference design toolkit GB was ported from.
