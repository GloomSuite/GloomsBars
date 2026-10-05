# Gloom's Bars — HANDOFF

> **Where Gloom's Bars stands, and what must not be relitigated.** Settled content only.
>
> Session records moved to [ARCHIVE.md](ARCHIVE.md) on 2026-07-26 — nothing was deleted. Open work
> for the whole suite lives in `~/GloomsHub/docs/BACKLOG.md`; unproven diagnosis in
> `~/GloomsHub/docs/FINDINGS.md`. **Do not restate suite-wide facts here** (release state, phase
> status, contracts) — point at the Hub. Every time that rule was broken, the copy went stale
> within a day.
>
> ## ▶▶▶ 2026-10-01 → 04 — SPACING, ICONS, PRESET CONTEXT, QUICK KEYBIND
> - **Layout spaces buttons by what's DRAWN** (`applyBar`): each slot is `pw × ph` from
>   `Skin:DrawnSize(btn)` (the hand shape's W/H in the button's own preset ctx; never less than the
>   button), so gap 0 = edge to edge for wide / tall shapes and Icon Size > 1. The container is centred
>   in its slot; the bounding box uses the slots. SetHandShape / SetSizeScale / RefreshPlate re-run
>   `Layout:ApplyAll`. ⚠ `local w, h = a and b and f()` truncated `h` once here — write the `if`.
> - **Custom icons survive EVERY re-set** (`Icons:HookButton`): a `hooksecurefunc(icon, "SetTexture")`
>   re-applies the override (a guard stops re-entry) — leaving stealth re-set the art by a path the
>   Update / UpdateButtonArt hooks never saw. Icon IDs: the file's last segment is the SPELL ID (the
>   number in Wowhead's URL), never the icon's file ID.
> - **Preset context on Blizzard's refresh hooks:** `ApplyCountOverride`, `ApplyHotkeyOverride` and
>   `StyleCastInnerGlow` are `withPresetCtx`-wrapped — called bare from the UpdateCount / UpdateHotkeys /
>   PlaySpellCastAnim hooks they read the WORKING COPY's settings (a bar on its own preset had its charge
>   count jump to the edit preset's spot; TESTED with an in-game anchor readout).
> - **Quick Keybind** wears the Suite window body (`UI.gRounded`, title at 20,-20, the kit's buttons /
>   checkbox) and closes BOTH Suite windows (`GloomsSuiteWindows` + the old `GloomsSuiteWindow`).
>
> ## ▶▶▶ 2026-09-27 — BARS IS NOW TWO WINDOWS (the end of `Config.lua`, "THE TWO-WINDOW DESIGN")
> Suite-wide: Hub BACKLOG 16 · CONTRACTS §2/§4 · FINDINGS §22. Bars detail only:
> - The **selector** is the PREVIEW window (`buildPreviewPane(content)`; `container` = it): chips from
>   y 52, the construction centered 218 down (`PREVIEW_CENTER_Y`), the caption at 293.
> - The **tab** ("Editing Preset: <name>", New, Delete): click the name = the preset list, right-click =
>   Rename · Duplicate · Delete. The old "Editing Preset" row is gone; `presetTabs` keeps every tab in step.
> - Seven **sections** (`Section(id, parent, h)` → `P.pages[id]`, refreshed on show). The Layout
>   section's bar picker is a LIME `gSwitch` with per-segment `widths` (1-8 share what PET/STANCE leave).
>   Glows' state picker is two 4-wide switches sharing one value. **Casts keeps "Complete Color"**
>   (not in the mock — BACKLOG 16 asks the owner). `SKIN_NEEDS = 16`.
> - `C:OpenSection(title)` → `GloomsHub:ShowPage("bars", id)` opens that section.
> - `Media/glass/` is deleted.
>
> ## ▶▶ 2026-09-25/26 — THE BARS TAB WAS REBUILT: the GLASS design (seven pages) — superseded
> Suite-wide status, decisions and what is un-mocked: Hub BACKLOG 16 · CONTRACTS §2/§4 · FINDINGS §22.
> Bars detail only:
> - All in `Config.lua` ("THE GLASS TAB" block): the accordion, the rail and `makeSection` are
>   GONE; the preview's logic (`C:RefreshPreview`, `SetPreviewState`, …) is unchanged except its
>   size (a 70px construction, `PREVIEW_BASE`) and home (the glass Preview panel, 30,314).
>   `C:OpenSection(title)` now opens a PAGE (the caption's "Styled in:" links name page titles).
>   `SKIN_NEEDS = 14`. The glass tiles: `Media/glass/<page>-a|b|c|d.png` (from the Hub's
>   `tools/gen-glass-art.py bg` — never hand-edited).
> - **Empty Icons is a real override** (`Skin.lua` `emptyOverride`): `barLayout.showEmpty` nil =
>   GLOBAL (follow Empty Slots — what nil always meant), true = SHOW (normal whatever the global
>   says, NEW), false = HIDE.
> - **Name text is OFF/ON**: OFF = `mode "hidden"`, ON = `"custom"`; a legacy `"default"` reads ON
>   and becomes custom when any Name control is edited (`ensureNameCustom`).
> - **Fixed:** the Pulse Speed dial called `GB.Glows:SetPulseSpeed`, removed in session 10 — it threw
>   on every move. It now writes `db.glowPulseSpeed`, which Glows.lua reads live.
> - The Text page is ONE set of controls; the KEYBIND · CHARGE COUNT · COUNTDOWN · NAME strip picks
>   what they edit. Each text keeps its own anchor choices (one switch per kind, one shown);
>   Countdown has none (a dimmed placeholder). Mac Symbol Icons dims off the Keybind tab.
>
> **Keep this file re-readable.** If it passes ~350 lines, move settled history to the archive.
> The handoff ritual (`~/GloomsHub/.claude/skills/handoff-ritual/`) maintains it.
>
> **2026-09-21 — the Bars tab is on the Hub's KIT (Hub BACKLOG 16, stage 3, owner-QA'd).**
> `Config.lua` was rebuilt from the ten Figma mocks at their own coordinates; the design decisions
> (button colours, bar tracks, chips, the dial, "dim not hide") are listed once, in the Hub's
> BACKLOG 16. **Do not restyle the tab on its own** — read the mock (`~/GloomsHub/tools/figma.py`)
> and the Hub's `Skin.lua` kit section first. GB-specific facts of the rebuild, below.

---

## ▶▶▶ 2026-09-30 (evening) — the spacebar as "_", and the two SLANT shapes
- **The spacebar shows as `_`** in keybind text (`spaceAsUnderscore` beside `symbolizeHotkey` in
  `Skin.lua`): only the KEY after the modifiers, only when it is the spacebar, with Custom keybind on —
  plain or with the Mac symbols. Owner-confirmed.
- **`slant-r` / `slant-l`** are the Hub's (Hub CONTRACTS §7). Here: `hgAnchor` passes the shape key to
  `GloomsHub:GrowAnchor` (a slant grows `growX` × more sideways), the BORDER's colour fill is widened by
  the same factor, and flyouts map both to `square` (`FLYOUT_1X1`). The even-border fix is untested in game.

## ▶▶▶ 2026-09-30 — the Hub's UNDO covers Bars
The `undo` block at the end of `Config.lua`'s RegisterTab: a snapshot is a deep copy of every
`GB.PRESET_FIELDS` key of `GB.db` (the working copy the windows edit); putting one back patches them
and calls `GB:RefreshAll()`. The token is profile + edit preset, so a preset or profile switch is
never an undo step. Nothing else in Bars changed.

## ▶▶▶ 2026-09-27 — the owner's first in-game round on the two-window Bars
Suite-wide facts are the Hub's (BACKLOG 16, CONTRACTS §2/§4). Here: the Text section's Font list
draws each name in its own face (`fontPathOf`); Casts & Channels' extra color is labelled **"Cast
Complete Color"** (the owner kept it); every section's positions follow the 10-point labels (control
15 under its label, rows 41 apart — CONTRACTS §4); colors offer "Use Class Color" (`Core.lua` stamps
them at login). `SKIN_NEEDS = 17`.

## ▶▶▶ 2026-09-21 — the Bars tab on the kit (redesign stage 3)

**Shape.** The RAIL (250) holds the kit PRESET block (a white field picker + NEW · COPY / RENAME ·
DELETE, 2 × 2 — the same `nameDialog` / `confirm` as the old `profileBlock`, with a refused name
said in chat) over the dark PREVIEW pane (`#1e1e1e`: the 13 state buttons two across, the
construction centred 266 under the pane's top, the caption at a fixed y=354 with 20px insets — or
under a downward plate if that reaches lower). The PROFILE api became `PROFILE_API`, handed to
`RegisterTab` (`profile`, `wordmark = "BARS"`) — the Suite window draws it in its footer. The
accordion starts 20 under the tab's top at x=21; kit headers with the mocks' names (Shape & Icon ·
Plate Construction · Decoration Layers · Text · Glows · Animations · Cast & Channel · Cooldown &
Availability · Empty Slots · Bar Layout & Preset); `C:OpenSection(title)` and `STATE_DESC`'s
"Styled in:" links (now inline, lilac, with pipes — the mock) use those exact names. Collapsing
the open section scrolls to the top.

**The tab has NO footer of its own now** (`FOOTER_H = 0`). What the old strip held moved into the
Layout section's bottom row: Move Bars · Quick Keybind · Reset Positions · **Highlight Preset's
Bars** (shortened so the row fits) · the **Gloom's Bars master switch** (the owner's choice from
three offered spots). `C._enableToggle / _hlSync / _mvFooterSync` still exist and `C:Refresh`
still syncs them.

**Per-section facts worth knowing:**
- Text: one `textBlock(bf, kind)` for all four texts; the kind supplies the head cell (Name's is
  the DEFAULT | CUSTOM | HIDDEN bar), its zones (Countdown has none) and Keybind's Mac Symbol Icons.
  The old `fontDropdown` / `openFontFlyout` (each font drawn in its own face) are DELETED — the kit
  `UI.pick` lists names in Play. He has not asked for the preview back.
- Glows: a table (Glow Status · Color · Layer · Opacity), one row per trigger 26 apart; the layer
  is a three-option `UI.pick`, the opacity a `bare` dial. Its colour chips are REQUIRED (bare swatch).
- Animations: the module's params are placed by KIND — colour chip beside the picker, `choice`
  (Style) under it, `range` dials down the two right columns, and a `bispeed` (Spin / March /
  Sweep) always at the second row's left slot because its "CCW 0.8s" readout widens the box.
- Decoration: Two-Tone Border OFF keeps `color2` and sets `twoTone = false` (Skin.lua reads
  `bd.color2 and bd.twoTone ~= false`) — switching it back on brings the same colour back. The
  owner: wiping it "is bad".
- Layout: the per-bar labels carry "(Bar N)"; the bar chips are dark `action` buttons with 6px
  padding (the mock's 47px "BAR 1"); Empty Icons SHOW | HIDE is 10px padding (98px).
- Segment padding is per mock: four-way direction bars 8, Colorize Icon 10, Orientation 9,
  everything else the kit's 20. Do not "normalise" them.

**Deleted as dead:** `stubBody`, the `colorSwatch` wrapper, `fontPath`, the font flyout, the
`flatButton / makeToggle / sliderRow / dirRow / flatEditBox` aliases. `Config.lua` is 2,270 lines
(was 3,150).

---

## ▶▶▶ 2026-09-05 — the button-COUNT path had §13's bug too

**Measured record: `~/GloomsHub/docs/FINDINGS.md` §13, the AMENDED block.** GB detail only here.

A bar set below its full count (the owner's bars 1 and 2 at 8 of 12) brought buttons 9-12 back
**mid-combat**. Same mechanism as the empty-slot collapse fixed on 08-24, in the path that was not
converted: `applyBar` still did `cont:SetShown(false)` for out-of-grid slots, `Reassert` bails with
`pending = true` in combat, and Blizzard's `UpdateShownButtons` re-shows every container up to ITS
count — which is still 12.

**Fix (`Layout.lua`):** out-of-grid containers get **alpha 0** *and* are **parked off-screen**;
in-grid containers get alpha restored to 1. Alpha survives the combat re-show (Blizzard only calls
`SetShown`); parking stops an invisible button eating clicks, which matters here because these sit
at stale coordinates rather than keeping a hole in the grid. The `SetShown` hide is unchanged — the
new treatment is belt-and-braces on top of it, not a replacement.

⚠ **Parking is only safe because both positioning branches re-anchor every in-grid container on
every pass** — that is what un-parks a slot when the count goes back up. Owner-verified 12 -> 8 -> 12
on 2026-09-05. If that ever stops being true, raising a bar's count strands buttons off-screen with
no visible clue, which is far worse than the bug this fixed.

⚠ **Reproducing it needs HOVERING the bars in combat.** Nothing shows without something making
Blizzard re-run `UpdateShownButtons` mid-fight. A bar that will not reproduce is usually missing the
trigger, not fixed.

---

## ▶▶▶ 2026-08-25 — the shapes and the animation modules LEFT this repo

**Measured record: `~/GloomsHub/docs/FINDINGS.md` §14. API: Hub CONTRACTS §7-§8.** GB detail only here.

Gloom's Auras now draws the suite's silhouettes too, so keeping a second copy of the catalog and 136
art files here would have guaranteed drift. **What moved to `~/GloomsHub`:**

- the 21-shape catalog → `Shapes.lua` · the art → `Media/art/shapes/` (was `Media/art/hand/`)
- all eight animation MODULES → `Effects.lua` · their 5 shared textures → `Media/art/effects/`

**What did NOT move, and why it matters:**

- **`Glows.lua` is untouched.** The multi-part shaped halo is entangled with the spell-alert and
  assisted-highlight hooks, and its outer glow has a SOLID CENTRE that only reads correctly because
  an opaque button icon covers it. GA gets its glow from the hollow rim-based modules instead. **Do
  not extract this "for consistency".**
- **`Anims.lua` kept every public method** — `Get`/`Each`/`Params`/`Enabled`/`Reconcile`/
  `Invalidate`/`PreviewReconcile` — and shrank 835 → 90 lines. It is wiring now: which trigger runs
  which animation, the per-trigger params in `GB.db`, the reconcile loop over buttons. **`Config.lua`
  and `Glows.lua` did not change at all**, which was checked by confirming nothing anywhere reaches
  into `Anims.modules` or `Anims.order`.
- **`hgAnchor` stayed local**, and now has a twin in the Hub (`GloomsHub:GrowAnchor`). Verified
  line-for-line identical by script. ⚠ **Change one, change both** — Hub backlog item 10.

**The engine must DEGRADE, never error** (CONTRACTS §6). `GB:HandAsset` returns a path for any
non-nil key even against an ancient Hub; `HAND_SHAPES` falls back to a one-entry circle catalog;
`Anims` resolves `GloomsHub.Effects` per call and runs nothing when absent. `Config.lua`'s login
gate now also fires when the catalog is missing — **and its message no longer says "your action bars
keep working normally", because without shape art they would not.**

**Owner-QA'd 2026-08-25** in two stages, each verified before the next started: all 21 picker
thumbnails plus procs and cooldown sweeps unchanged; then the animations, confirmed still tracing the
button's own silhouette rather than a circle.

⚠ **`tools/generate-{shine,march,hand-swipes,radar,sheen,sparkle}.py` now write into the sibling
Hub repo.** They still live here with GB's art pipeline. Verified they still see all 21 base masks.

---

## ▶▶▶ 2026-08-24 — the empty-slot collapse is an ALPHA treatment now

**Measured record: `~/GloomsHub/docs/FINDINGS.md` §13.** GB-specific detail only here.

The per-bar "hide empty buttons" (`c.showEmpty == false`) used to clear `show` in `Layout.lua` and
hide the button's **container**. That could never hold: Blizzard's `ActionBarMixin:UpdateShownButtons`
re-shows the container of every in-range slot regardless of whether it holds an action, and
`Layout:ApplyAll()` is a hard no-op in combat. Hovering a bar mid-fight brought empty buttons back
at the global dim alpha, and they stayed until `PLAYER_REGEN_ENABLED`.

**It is answered in `Skin.lua`'s `applyEmptyAlpha` now**, alongside the global Empty-slots mode —
one mechanism instead of two features fighting. A bar set to hide its empties outranks the global
Dim/Normal setting. Alpha is not geometry, is not combat-restricted, and rides the per-button Update
post-hook that already runs mid-fight, so it re-asserts itself.

- ⚠ **Do not reinstate `cont:SetShown(false)` for empties.** Comments at both ends say so.
- **`collapseEmpty` respects the master layout switch.** Layout off = Edit Mode owns the bars, so a
  stale `showEmpty` cannot strand buttons invisible with no visible way back.
- **Both setters refresh the alpha path directly** — `apply()` routes through `Layout:Reassert`,
  which gates on combat, so the refresh cannot ride along with it.
- `Layout.lua`'s `gridVisible` was deleted: it existed only to suspend the collapse during a drag,
  and `Skin` keeps its own flag off the same two events. Drag behaviour is unchanged.
- **This was the FOURTH instance of one pattern** (timewalking, Edit Mode, the 12.1
  `EDIT_MODE_LAYOUTS_UPDATED` change, this). The first three were each fixed by registering one more
  event. **That approach is exhausted** — in combat the geometry wall gags us whatever fires.


**Last updated:** 2026-09-20 · **No open bugs.**
Landed 2026-09-20 (from a Hub session): **the profile rework is fully owner-QA'd** — New (factory,
circles: he confirmed circles are right), Rename-unchanged (silent no-op), a name with outer spaces
(trimmed by the Hub's dialog), Delete (prints where the character landed) all clicked and correct.
**The profile block passes `users(name)`** (from `GB.db.charProfiles`) so the delete confirmation
names every other character on the profile — Hub CONTRACTS §4, the owner's ask after deleting a
test profile without knowing who else used it. **`hgAnchor` is a one-line delegation to
`GloomsHub:GrowAnchor`** (Skin.lua) — the two bodies were diffed identical first; six call sites
untouched; the owner looked and nothing moved. Release state is a SUITE fact — its home of record
is `~/GloomsHub/docs/SUITE-STATE.md`.
Previously (2026-08-15): the profile model rework — New now means the FACTORY look, and per-character
profiles are actually LOADED at login (they never were). See the block below.
Previously: per-bar preset context fix, `GB.Icons` per-action icon overrides, Quick Keybind gold square.
Release state is a SUITE fact — its home of record is `~/GloomsHub/docs/SUITE-STATE.md`.

---

## ★★ THE PROFILE MODEL — reworked 2026-08-15, after the owner said it was confusing

He asked what New / Copy / Rename actually did. Reading the code to answer him found a real bug and
three naming problems. **All of this is settled; do not relitigate it.**

### The bug — profiles were stored but never applied

`PLAYER_LOGIN` bound the character to its profile and **never called `LoadPreset`**. Because
`GloomsBarsDB` is account-wide and `GB.db`'s visual fields ARE the live working copy, every
character rendered whatever the last-played character left behind — and `PLAYER_LOGOUT` then wrote
that stale look into *this* character's edit preset. Full write-up and evidence:
`~/GloomsHub/docs/FINDINGS.md` §11. The login branch now ends with `GB:LoadPreset(...)`.

⚠ **Presets that were already overwritten stay overwritten.** A character may look wrong ONCE after
the fix and then be stable. Do not diagnose that as a regression.

### New vs Copy

- **`GB:CreateProfile`** now seeds from **`GB:DefaultPreset()`** — the factory look — not from a
  snapshot of the current one. GA and Overlays always split New/Copy this way; GB was the outlier.
- **`GB:CopyProfile`** is unchanged: a full `deepcopy` of the ACTIVE profile, presets and bar
  assignments included.
- ★ **`GB:DefaultPreset()` must supply ALL 39 `PRESET_FIELDS`.** `LoadPreset` skips `nil` fields, so
  a gap silently leaves the new profile wearing the OLD one's value. Three fields are not in
  `DB_DEFAULTS` and are supplied explicitly — `styleData`, `handShape`, `triggers`. **Do not "tidy"
  them into `DB_DEFAULTS`:** the defaults-fill loop runs BEFORE the migration, so seeding
  `handShape` there would pre-empt the legacy-shape derivation and change what upgraders get.
- **`buildTriggerDefaults(src)`** is the ONE definition of the 8 per-trigger glow records, used by
  both the session-10 migration (seeded from the live db) and `DefaultPreset` (seeded from
  `DB_DEFAULTS`). Keep it that way or the two will drift.

### First login

A character's first login still auto-creates `"Name - Realm"`, but the look it starts with is now
the factory one — **except for the VERY FIRST profile ever created**, which still snapshots the
working copy. That exception is load-bearing: on an upgrade from a pre-profiles GB, the working copy
IS the user's existing look, and seeding from defaults would wipe it. On a fresh install the two are
identical, so the branch only ever protects the upgrade path.

### The rail

PROFILE stays at the top in purple; **PRESET is pinned to the BOTTOM of the rail and drawn orange**
(`accent`, LibGloomSkin MINOR 7). The owner asked for this: two identical-looking blocks stacked in
one colour read as a single control. It is not token drift.
⚠ GB's convention is *purple = off, orange = on/selected*. The preset buttons are permanently orange
and therefore bend that rule deliberately.

### Small fixes in the same pass

- Rename to the name it already has is a **silent no-op**, not "a profile with that name already
  exists" (the dialog prefills the current name, so OK-without-typing hit this constantly). Same for
  presets.
- `DeleteProfile` returns `true, fallback`; Config prints which profile the character landed on.
  The fallback is `next(db.profiles)` — **arbitrary table order**, so saying it out loud matters.
- Name **trimming** now happens once in the Hub's shared `UI.nameDialog`, so GA and Overlays get it
  too.

### Still unverified

The New button itself, the rename no-op, trimming, and the delete message have not been clicked.
Suite BACKLOG item 5. **One open question for the owner:** he expected a new profile to look "like
the default UI"; it produces GB's default (circles), not Blizzard's squares. Circles were kept.

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

### Finding the ORIGINAL art to edit — the owner looks it up on Wowhead
A spellID appears nowhere in an icon's filename — the game maps spellID → fileDataID →
`interface/icons/<name>.blp`. Fetch: Eagle's icon is `inv_111_hunter_ability_featheredfrenzy`, which
no amount of searching for "fetch" or "eagle" will surface.

**His method: search the spell on Wowhead — the results list the icon name** — then take that
`<name>.tga` from his icon pack. **Do not build tooling for this.** A script that resolved a spellID
and copied the file in was written and then DELETED on 2026-07-26: *"I'm barely using it — it's
faster to just look up the spell on wowhead."* It was also fragile (page scraping) and handled
spells but not items. **A tool that is both unused and fragile is worse than no tool.**

⚠ **`/gb icon key` cannot do this, and do not re-try it.** `C_Texture.GetFilenameFromFileDataID`
exists but has **no name for Blizzard's packed assets** — it returns the literal string
`"FileData ID 538745"`. An earlier attempt printed that as though it were a filename. The command now
requires a real path and points at Wowhead instead. **Tested 2026-07-26.**

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

## ✅ CLOSED, NOT A GB BUG — the frame-level stack does NOT block Quick Keybind Mode

**Full record, evidence and `KILLED` list: `~/GloomsHub/docs/FINDINGS.md` §8.** Not restated here.
Closed 2026-07-26: non-reproducible on both clients, and the `/fstack` reading that named GB was a
misreading of what its arrow means. No code changed on account of it.

What belongs in THIS file is the stack it wrongly accused, which is deliberate and correct:

| Layer | Level | Set at |
|---|---|---|
| plate gradient | `+1` | `Skin.lua:1224` |
| decor | `+2` | `Skin.lua:1292` |
| glow / overlay | `+3` | `Skin.lua:790`, `:2715` |
| **`TextOverlayContainer`** | **`+4`** | **`Skin.lua:1378`** |
| cooldown-and-above | `+5` | `Skin.lua:1753` |

- ⚠ **Do NOT lower `TextOverlayContainer`** — hotkey and count text would fall behind the skin, which
  is the problem this stack exists to prevent (`Skin.lua:790` records the intent).
- ⚠ **Do NOT write `EnableMouse(false)` on it** — that was a guess built on the dead reading, and
  `Skin.lua` contains no `EnableMouse` call anywhere by design.

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
> ⚠ **2026-07-30: the PREMISE may have changed, `UNTESTED`.** 12.1 adds radial masking to textures
> and status bars — `SetRadialProgressBarPercent`, `SetRadialProgressBarStartOffset` / `EndOffset` /
> `Reverse` / `Feather`. This decision was made against the old API and was correct then. **Not
> reopened, and not a task** — recorded only so nobody re-derives the limitation from scratch, or
> assumes it still holds without checking. Owner's call whether it is ever worth revisiting.
> Source: <https://warcraft.wiki.gg/wiki/Patch_12.1.0/API_changes>
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


## Smaller anytime-items
- **`UNVERIFIED` (claim dated 2026-07-18, never re-checked):** flyout buttons (pet/stance/etc.) keep a
  square Blizzard background border at the default size — `Suppress()` was said to miss the flyout
  background art. Carried forward from a retired section rather than dropped. **Confirm it still
  happens before spending anything on it.**
- Aspect-correct mask art for stretched constructions (corner distortion on tall shapes).
- Count/Name per-style overrides; more layer kinds (border, badge, top plate).
- Pet/stance/extra-action/vehicle bars; minimap button + icon art (`## IconTexture`).
- ★ **WoWup install test on a second machine (NOT the owner's — would clobber the dev symlink).** This is
  now the suite's ONE open Phase G QA item; the script lives in `~/GloomsHub/docs/ARCHIVE.md`. The symlink
  hazard is real and confirmed: all four AddOns entries point straight into the dev repos, so a WoWup
  install on this machine writes over live source unless the symlinks are moved aside first.
- Late-phase: coexistence QA with ArcUI/EQOL re-enabled.

