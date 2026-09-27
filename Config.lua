-- Config.lua — Gloom's Bars: the style editor (Config UI)
--
-- The product's front end (docs/HANDOFF.md ★ NORTH STAR): author button styles
-- through the UI, not baked-in recipes. Built in the GloomsAuras family design
-- language (docs/CLAUDE.md): flat SQUARED chrome, near-black navy plate, bright
-- purple #936BFF accents, deep-purple low-alpha fills, orange #FF7729 carets +
-- bottom glow, Khand uppercase headers + GeneralSans body, sliding toggles. The
-- toolkit mirrors GloomsAuras/Config.lua so the siblings feel identical.
--
-- Phase C (suite migration): the standalone window is GONE. This file now
-- registers the BARS tab of the Suite window (GloomsHub:RegisterTab, bottom of
-- this file) and consumes the shared LibGloomSkin-1.0 toolkit instead of its
-- old local copy. The section builders are unchanged. Opens with /gb.

local GB = _G.GloomsBars

local C = {}
GB.Config = C

-- --------------------------------------------------------------------------
-- Skin toolkit + tokens — CONSUMED from LibGloomSkin-1.0 (the shared lib
-- shipped by GloomsHub, our hard dependency, so it is always loaded first).
-- The local names mirror the old GB-local copies exactly, so the section
-- builders below read unchanged. FONT here = the Hub's font paths (pre-warmed
-- against the cold-pair blank-text quirk); the bar ENGINE keeps GB.FONT (GB's
-- own paths) — see Core.lua. Surface pinned in GloomsHub/docs/CONTRACTS.md §4.
-- --------------------------------------------------------------------------
-- --------------------------------------------------------------------------
-- ★ SHARED-TOOLKIT VERSION GATE — see GloomsHub/docs/CONTRACTS.md §6.
-- LibGloomSkin lives in GloomsHub and GROWS: each MINOR adds widgets this file
-- may call. WoW's "## Dependencies: GloomsHub" only checks that the Hub is
-- PRESENT, never that it is NEW ENOUGH — so a Hub a release or two behind would
-- let this file load and then die on the first nil widget, spraying Lua errors
-- at someone who has no idea what a MINOR is. Check first, and fail with ONE
-- actionable sentence instead.
-- ★ BUMP SKIN_NEEDS IN THE SAME COMMIT that first calls a newer widget.
-- --------------------------------------------------------------------------
local SKIN_MAJOR, SKIN_NEEDS = "LibGloomSkin-1.0", 16   -- 16: the two-window kit (Sansation, stretched controls, the windows); 15: solid panels + hairlines; 14: the GLASS KIT (gButton / gSwitch / gDrop / gDial / gColor …) + the glass Suite window — the third redesign

local Skin, skinMinor = LibStub(SKIN_MAJOR, true)
-- ★ The silhouette catalog and its art live in GloomsHub since 2026-08-25, and this
-- tab's shape picker is built straight off it — so an absent catalog means the same
-- fix as an old toolkit ("update the Hub") and belongs in the same one message.
-- Core.lua's engine-side fallback keeps the bars from erroring meanwhile; this is
-- only what TELLS the user, which is the half a silent degrade never does.
local hubShapes = _G.GloomsHub and _G.GloomsHub.SHAPES
if not Skin or (skinMinor or 0) < SKIN_NEEDS or not hubShapes then
  local found = Skin and ("v" .. tostring(skinMinor or 0)) or "none"
  -- The old tail promised the bars keep working normally. With no catalog that is no
  -- longer true — the buttons lose their shaped art — and the message must not lie.
  local tail = hubShapes and " Your action bars keep working normally."
    or " Your buttons will also lose their shaped art until you do."
  local warn = CreateFrame("Frame")
  warn:RegisterEvent("PLAYER_LOGIN")
  warn:SetScript("OnEvent", function(self)
    self:UnregisterAllEvents()
    print("|cffff7729Gloom's Bars:|r please update |cff936bffGloom's Hub|r. This version of "
      .. "Bars needs a newer Hub toolkit (needs v" .. SKIN_NEEDS .. ", found " .. found
      .. "), so the BARS tab is unavailable." .. tail)
  end)
  return   -- chunk-level return: the tab is never registered; the bar ENGINE is untouched
end
local UI = Skin.UI
local COLOR, FONT = Skin.COLOR, Skin.FONT
local TEXT, MUTE = COLOR.text, COLOR.mute       -- lib tokens (promoted from the old locals)
local CARET_TEX = UI.CARET                      -- the Hub's caret art (the one copy)
local CARET_DOWN = UI.CARET_DOWN                -- rotate right-pointing source to point down (open)

local setFont, newText, addEdges = UI.setFont, UI.newText, UI.addEdges
local skinPlate, hLine = UI.skinPlate, UI.hLine
-- Each swatch names the element it drives, for the picker's "in use" palette
-- tooltip. The tool prefix lives HERE rather than at 20 call sites — six of them
-- read only "Color" on screen, so the section is what tells them apart in that
-- list. An older Hub simply ignores the extra argument.
local makeScrollbar, attachTip = UI.makeScrollbar, UI.attachTip

-- Every (Hub font, size) pair this tab draws BEYOND the Hub's own warm list —
-- a cold (font file, size) pair renders BLANK on its first draw each session
-- (CONTRACTS §4). Queued now; warmed with the Hub's batch at PLAYER_ENTERING_WORLD.
UI.RegisterWarmPairs({
  { FONT.title, 17 }, { FONT.title, 18 },   -- name-dialog / Quick Keybind titles
  { FONT.head, 12 }, { FONT.head, 13 },     -- rail headers / POSITION-style subheads
  { FONT.body, 9.5 }, { FONT.body, 10 }, { FONT.body, 12.5 },   -- bispeed end labels / preview caption / footer enable label
  { FONT.label, 10 }, { FONT.label, 10.5 }, { FONT.label, 11 }, -- group titles / caption links / slider values
})

-- --------------------------------------------------------------------------
-- ★ THE BARS WINDOWS (2026-09-27) — the TWO-WINDOW design, from the owner's
-- Figma page "GloomSuite UI 3": the PREVIEW window ("gloomBars, preview
-- window") and the settings window's seven sections ("gloomBars, Icon Size &
-- Shape" … "Bar Visibility Layout & Presets"). The Hub (Windows.lua) owns the
-- windows, the headers, the pop-outs and Global Settings; the section builders
-- at the end of this file draw what is inside them, at the mocks' own
-- coordinates. (The glass design's "Editing Preset" row and the accordion
-- before it are gone.)
-- --------------------------------------------------------------------------
-- Padding-compensation for our masks (matches Skin.lua GROW_RATIO / the 240/256
-- edge-padding rule) + the state-ring inset fit; kept local so the preview uses
-- exactly the engine's geometry.
local GROW_RATIO = (256 / 240 - 1) / 2
-- The preview (the mock's "gloomBars, preview window", 240 × 420, 2026-09-27 —
-- its contents moved up 10 by the owner the same day, 20 under the wordmark as
-- in Auras): the construction's long side is 70 (the mock's square), centered
-- 218 under the window's top (the mock's 70px square at y 183–253), so a plate
-- growing either way stays between the state buttons and the caption (y 293).
local PREVIEW_CENTER_Y = -218
local PREVIEW_BASE = 70
local PREVIEW_CAPTION_Y = 293    -- the caption's top, under the window's top

local container   -- the shell-provided Bars tab frame (the whole window)
local previewFrame, previewIcon, previewMask, previewGlow, previewRing, previewCD
local previewBorder, previewBorderMask, previewCaption, previewCaptionHead, previewCaptionLinks
local previewCastFillFrame               -- looping cast/channel drain (Cast / Channel chips)
local previewPlateOn = false             -- plate mode live in the preview (set by RefreshPreview)
local previewOuter, previewInner          -- multi-part shaped glow (hand shapes; mirrors the bars)
local previewFlashFrame, previewFlash, previewFlashAnim   -- finish-flash preview
local previewPlates = {}                 -- pooled gradient-plate textures (created lazily)
local previewPlateFresh, previewRetryPending
local previewExtH, previewExtT, previewExtB = 0, 0, 0   -- live extension px (magnitude + top/bottom split)
local previewChips, previewState = {}, "idle"
-- Live pulse for the multi-part preview glow: mirrors the bars' pulse driver so the
-- Pulse-speed slider is visible on the pulsing chips (proc / flash). previewPulsePeak
-- = the trigger opacity to breathe about; the OnUpdate on previewFrame drives alpha.
local previewPulsing, previewPulsePeak, previewPulsePhase = false, 0.9, 0
local PREVIEW_PULSE_DEPTH = 0.5

-- The pages: id → { frame, items = { {ctrl, gate} }, refresh = fn }.
local P = { pages = {}, cur = "shape" }
C.P = P
local VIOLET, LILAC, LIME = COLOR.violet, COLOR.lilac, COLOR.lime
-- The page names the preview's "Styled in:" links name (their titles in the
-- Suite window's page list).
local PAGE_OF = {
  ["Icon Size & Shape"] = "shape", ["Decoration Layers"] = "deco", ["Text"] = "text",
  ["Glows & Animations"] = "glows", ["Casts & Channels"] = "casts",
  ["Cooldowns & Availability"] = "cooldowns", ["Bar Visibility, Layout & Presets"] = "layout",
}


-- --------------------------------------------------------------------------
-- Font picker — a dropdown whose label is drawn IN the current font; clicking
-- opens a scrollable flyout of every LibSharedMedia font (our bundled ones + all
-- other addons', incl. StoneTweaks), or just the bundled set if LSM is absent.
-- --------------------------------------------------------------------------
local function fontChoices()
  local lsm = GB.GetLSM and GB.GetLSM()
  if lsm and lsm.List then
    local shared, t = lsm:List("font"), {}   -- LSM hands back its own array; copy it
    for i = 1, #shared do t[i] = shared[i] end
    return t
  end
  local t = {}
  for n in pairs(GB.BUNDLED_FONTS or {}) do t[#t + 1] = n end
  table.sort(t)
  return t
end

-- Preview caption: the default explainer line, swapped by the Animations section for a
-- one-line description of the state being edited (what triggers it / what it means) —
-- contextual help right in the preview pane. Reset on every section toggle so it never
-- lingers into a section that has no "state" concept.
local PREVIEW_CAPTION_DEFAULT = "Sample of the visible skin. Your clickable hit area stays Edit Mode's size."
-- Section-name hyperlink: |Hgbsec:<title>|h in caret orange (#FF7729); the caption
-- frame's OnHyperlinkClick opens that accordion section. Display = the title in caps.
local function secLink(title)
  return ("|Hgbsec:%s|h|cffa881f8%s|r|h"):format(title, title)   -- lilac: the kit's link colour
end
-- The "Styled in:" bullet list under a state description (the owner: inline links were
-- hard to follow). Items: a title string, or { title, note } where the note (in the
-- muted body colour) marks which PART of the state that section covers.
-- The mock (stage 3) writes it inline: "Styled in: Glows | Animations | Cast & Channel".
local function linkList(items)
  local out = {}
  for _, it in ipairs(items) do
    local title, note = it, nil
    if type(it) == "table" then title, note = it[1], it[2] end
    out[#out + 1] = secLink(title) .. (note and (" (" .. note .. ")") or "")
  end
  return "Styled in: " .. table.concat(out, " | ")
end
local LL_GLOW = linkList({ "Glows & Animations" })
local LL_CDA = linkList({ "Cooldowns & Availability" })
local LL_CAST = linkList({ "Glows & Animations", { "Casts & Channels", "fill & bursts" } })
-- Each entry = { HEADING, body, links }: the state name (bold Semibold line), what
-- triggers it in-game (plain prose), then the clickable "Styled in:" bullet list.
local STATE_DESC = {
  idle      = { "Idle", "The button's resting/default look with nothing active.",
                linkList({ "Icon Size & Shape", "Decoration Layers", "Text" }) },
  proc      = { "Proc", "Triggered when an ability procs (a free or empowered cast becomes ready).", LL_GLOW },
  highlight = { "Highlight", "Indicates the current location (if any) on your action bars when hovering over an ability or talent in your spellbook or talent tree.", LL_GLOW },
  assist    = { "Assist", "Triggered by Blizzard's Combat Assistant/Assisted Highlight feature to indicate the suggested next rotation ability.", LL_GLOW },
  cast      = { "Cast", "Shows while activating an ability with a cast time.", LL_CAST },
  channel   = { "Channel", "Shows while activating a channeled ability.", LL_CAST },
  hover     = { "Hover", "Shows while hovering your pointer over an icon in your action bars.", LL_GLOW },
  selected  = { "Selected", "Displays when a button is toggled on (a stance, form or aura).", LL_GLOW },
  flash     = { "Flash", "Appears when auto-attack or auto-shot is active — typically needs the related auto-attack ability to be on the action bar. Not commonly seen.", LL_GLOW },
  cooldown  = { "Cooldown", "A swipe animation and finish flash to indicate that an ability is recharging or ready.",
                linkList({ "Cooldowns & Availability", { "Text", "countdown numbers" } }) },
  unusable  = { "Unusable", "Indicates an ability is unusable due to wrong talent, form/stance, weapon type, silenced, missing resource, etc.", LL_CDA },
  oom       = { "Out of Mana", "Indicates you have insufficient mana or other resource/power to cast.", LL_CDA },
  range     = { "Out of Range", "Shows when the target is too far for the ability to be cast. Tints the icon and recolors the keybind text (if shown).",
                linkList({ { "Cooldowns & Availability", "enable & style" } }) },
}
-- Set the caption trio: a STATE_DESC entry, or nil → the default explainer only.
local function setCaption(entry)
  if not (previewCaption and previewCaptionHead) then return end
  if type(entry) == "table" then
    previewCaptionHead:SetText(entry[1])
    previewCaption:SetText(entry[2])
    if previewCaptionLinks then previewCaptionLinks:SetText(entry[3] or "") end
  else
    previewCaptionHead:SetText("")
    previewCaption:SetText(PREVIEW_CAPTION_DEFAULT)
    if previewCaptionLinks then previewCaptionLinks:SetText("") end
  end
end

-- Open the PAGE with this title — the caption's "Styled in:" links.
function C:OpenSection(title)
  local id = PAGE_OF[title]
  if id and GloomsHub and GloomsHub.ShowPage then GloomsHub:ShowPage("bars", id) end
end

-- ---------------------------------------------------------------------------
-- Quick keybind launcher (phase L4) — opens Blizzard's quick-bind flow (their
-- BINDING logic untouched), reskinned to the family language on first open.
-- Shared by the Bar-layout section button and the footer button. Every styled
-- region is guarded: if a patch renames a piece it keeps its stock look.
local qkFromUs = false
local function flatifyBlizzButton(b)
  if not b or b.gbStyled then return end
  b.gbStyled = true
  for _, k in ipairs({ "Left", "Right", "Middle", "Center" }) do
    local tex = b[k]
    if tex and tex.SetAlpha then tex:SetAlpha(0) end
  end
  for _, get in ipairs({ "GetNormalTexture", "GetPushedTexture", "GetHighlightTexture", "GetDisabledTexture" }) do
    local tex = b[get] and b[get](b)
    if tex then tex:SetAlpha(0) end
  end
  local fill = b:CreateTexture(nil, "BACKGROUND")
  fill:SetAllPoints()
  fill:SetColorTexture(COLOR.heroic.r, COLOR.heroic.g, COLOR.heroic.b, 1)
  fill:SetAlpha(0.5)
  b:HookScript("OnEnter", function() fill:SetAlpha(0.8) end)
  b:HookScript("OnLeave", function() fill:SetAlpha(0.5) end)
  local fs = b.GetFontString and b:GetFontString()
  if fs then setFont(fs, FONT.bodyM, 12); fs:SetTextColor(1, 1, 1) end
end
local function styleQuickKeybind()
  local f = QuickKeybindFrame
  if not f or f.gbStyled then return end
  f.gbStyled = true
  if f.BG then f.BG:SetAlpha(0) end         -- their dialog border + fill
  skinPlate(f)
  addEdges(f, COLOR.rim, 1)
  if f.Header then
    f.Header:SetAlpha(0)                    -- their gold header art (text included)
    local title = f:CreateFontString(nil, "OVERLAY")
    setFont(title, FONT.title, 18)
    title:SetTextColor(COLOR.purple.r, COLOR.purple.g, COLOR.purple.b)
    title:SetPoint("TOP", 0, -14)
    title:SetText((f.Header.Text and f.Header.Text:GetText()) or "Quick Keybind Mode")
  end
  for _, key in ipairs({ "InstructionText", "CancelDescriptionText", "OutputText" }) do
    local fs = f[key]
    if fs and fs.SetFont then setFont(fs, FONT.body, 13) end   -- faces only; OutputText's colour is Blizzard's live status
  end
  flatifyBlizzButton(f.OkayButton)
  flatifyBlizzButton(f.CancelButton)
  flatifyBlizzButton(f.DefaultsButton)
  -- Character-specific checkbox: GloomsAuras's flatCheck look (20px box, 10%
  -- white fill, orange checkmark — same asset, copied to GB media), applied
  -- over Blizzard's CheckButton so its bindings mechanics stay theirs.
  local cb = f.UseCharacterBindingsButton
  if cb then
    for _, get in ipairs({ "GetNormalTexture", "GetPushedTexture", "GetHighlightTexture", "GetCheckedTexture", "GetDisabledCheckedTexture" }) do
      local tex = cb[get] and cb[get](cb)
      if tex then tex:SetAlpha(0) end
    end
    local box = cb:CreateTexture(nil, "ARTWORK")
    box:SetSize(20, 20); box:SetPoint("CENTER")
    box:SetColorTexture(1, 1, 1, 0.10)
    local mark = cb:CreateTexture(nil, "OVERLAY")
    mark:SetSize(20, 20); mark:SetPoint("CENTER")
    mark:SetTexture(GB.MEDIA .. "ui\\checkmark.png")
    mark:SetVertexColor(COLOR.orange.r, COLOR.orange.g, COLOR.orange.b, 1)
    local function sync() mark:SetShown(cb:GetChecked()) end
    cb:HookScript("OnClick", sync)
    cb:HookScript("OnShow", sync)
    sync()
    local cbText = cb.Text or cb.text
    if cbText and cbText.SetFont then setFont(cbText, FONT.body, 12) end
  end
end
local function openQuickKeybind()
  if InCombatLockdown() then GB.msg("quick keybind needs you out of combat."); return end
  if GB.Layout and GB.Layout.MoveModeOn and GB.Layout:MoveModeOn() then GB.Layout:SetMoveMode(false) end
  -- Close the Suite window (the editor is its Bars tab now) so the quick-bind
  -- flow has the screen. GloomsSuiteWindow is the shell's named frame.
  local suite = _G.GloomsSuiteWindow
  if suite and suite:IsShown() then suite:Hide() end
  local f = QuickKeybindFrame
  if not f then GB.msg("Quick keybind isn't available in this client."); return end
  if not f.gbHideHooked then
    f.gbHideHooked = true
    f:HookScript("OnHide", function()
      if not qkFromUs then return end
      qkFromUs = false
      -- Blizzard's OnHide reopens the SETTINGS panel (their flow assumes you
      -- came from it — the owner: "make that not happen"): close it again in the
      -- same frame, before it ever renders. Launches from Settings itself
      -- (qkFromUs false) keep Blizzard's return-trip behaviour.
      if SettingsPanel then
        if SettingsPanel.Close then pcall(SettingsPanel.Close, SettingsPanel, true)
        else HideUIPanel(SettingsPanel) end
      end
    end)
  end
  qkFromUs = true
  f:Show()
  styleQuickKeybind()
end

local function gradLayer()
  local st = GB.db and GB.db.styleData
  if not (st and st.layers) then return nil end
  for _, l in ipairs(st.layers) do if l.kind == "gradient" then return l end end
  return nil
end
local function ensureGradLayer()
  local st = GB.db and GB.db.styleData; if not st then return nil end
  st.layers = st.layers or {}
  local l = gradLayer()
  if not l then
    l = { kind = "gradient", zone = "extension", bleedPct = 0.5, color = { 1, 0.47, 0.16 }, fromAlpha = 1, toAlpha = 0 }
    st.layers[#st.layers + 1] = l
  end
  return l
end

-- The border decoration (a colored frame around ANY shape). Stored as its own
-- styleData field; the engine draws a shape-copy behind the icon, oversized by
-- `thickness`. Absent = no border.
local function borderData() local st = GB.db and GB.db.styleData; return st and st.border end
local function ensureBorder()
  local st = GB.db and GB.db.styleData; if not st then return nil end
  st.border = st.border or { enabled = true, color = { 0.58, 0.42, 1 }, thickness = 3, alpha = 1 }
  return st.border
end

-- The "plate" look for 2:1 portrait shapes: a square icon in one half, a solid-colour
-- plate in the other, the colour fading up over the icon. styleData.plate; absent = off.
local function plateData() local st = GB.db and GB.db.styleData; return st and st.plate end
local function ensurePlate()
  local st = GB.db and GB.db.styleData; if not st then return nil end
  st.plate = st.plate or { enabled = false, iconSide = "top", color = { 0.1, 0.1, 0.13 }, fadeStart = 0.5 }
  return st.plate
end
-- Plate only makes sense on a 2:1 portrait shape (the halves are then two squares).
local function plateShapeOK()
  local hk = GB.db and GB.db.handShape
  local info = hk and GB.HAND_SHAPES and GB.HAND_SHAPES[hk]
  return (info and info.orient == "portrait" and info.aspect == 2) or false
end

-- The keybind (HotKey) override. Present = the engine restyles/repositions the
-- keybind text (ApplyHotkeyOverride reads styleData.hotkey: zone/offset/size/
-- font/flags/color); absent = Blizzard's default (top-right). `font` is a GB.FONT
-- key. Default = the reference look (bold white centered in the extension).
local function hotkeyData() local st = GB.db and GB.db.styleData; return st and st.hotkey end
local function ensureHotkey()
  local st = GB.db and GB.db.styleData; if not st then return nil end
  st.hotkey = st.hotkey or { enabled = true, zone = "extension", offsetX = 0, offsetY = 0, size = 13, font = "GeneralSans SemiBold", flags = "OUTLINE", color = { 1, 1, 1 } }
  return st.hotkey
end
-- Custom-keybind ON = the table exists AND enabled ~= false. Toggling off keeps
-- the styling table (enabled=false) so the user's font/size/color/position all
-- persist and come back when re-enabled. Legacy tables (no `enabled`) read as on.
local function hotkeyOn() local h = hotkeyData(); return h ~= nil and h.enabled ~= false end

-- Charge/stack count override (styleData.count) — same pattern as the keybind.
-- Engine: Skin's ApplyCountOverride. Absent/off = Blizzard's default look.
local function countData() local st = GB.db and GB.db.styleData; return st and st.count end
local function ensureCount()
  local st = GB.db and GB.db.styleData; if not st then return nil end
  st.count = st.count or { enabled = true, zone = "corner", offsetX = 0, offsetY = 0, size = 14, font = "GeneralSans SemiBold", flags = "OUTLINE", color = { 1, 1, 1 } }
  return st.count
end
local function countOn() local c = countData(); return c ~= nil and c.enabled ~= false end

-- Cooldown countdown text (styleData.cdtext) — show/hide + restyle/reposition the
-- number Blizzard's Cooldown widget draws. ABSENT = untouched (the game's own
-- countdownForCooldowns CVar stays in charge). Engine: Skin.styleCooldownText.
local function cdtextData() local st = GB.db and GB.db.styleData; return st and st.cdtext end
local function ensureCdtext()
  local st = GB.db and GB.db.styleData; if not st then return nil end
  st.cdtext = st.cdtext or { enabled = true, size = 16, font = "GeneralSans SemiBold", flags = "OUTLINE", color = { 1, 1, 1 }, offsetX = 0, offsetY = 0 }
  return st.cdtext
end
local function cdtextOn() local c = cdtextData(); return c ~= nil and c.enabled ~= false end

-- Macro-name override (styleData.name) — same styling pattern as the count, but
-- THREE modes (default = Blizzard's stock label / custom = styled / hidden =
-- no label). Engine: Skin's ApplyNameOverride. Absent = default. Legacy tables
-- (no mode) read the old enabled flag: true = custom, false = default.
local function nameData() local st = GB.db and GB.db.styleData; return st and st.name end
local function ensureName()
  local st = GB.db and GB.db.styleData; if not st then return nil end
  st.name = st.name or { mode = "custom", zone = "bottom", offsetX = 0, offsetY = 0, size = 10, font = "GeneralSans Medium", flags = "OUTLINE", color = { 1, 1, 1 } }
  return st.name
end
local function nameMode()
  local c = nameData()
  if not c then return "default" end
  return c.mode or (c.enabled ~= false and "custom" or "default")
end

-- Plate — the 2:1-shape "plate" look: a SQUARE icon fills one half, a solid-colour plate
-- fills the other, and that colour fades up over the icon. Only meaningful on a 2:1
-- portrait shape (its halves are two squares); greyed with a hint on any other shape.

local function trig(key) return GB.db and GB.db.triggers and GB.db.triggers[key] end

-- Layer cycle cell: a compact button showing the trigger's current layers
-- ("Both"/"Inner"/"Outer"); click cycles Both → Inner → Outer. onChange() lets the
-- caller reflect it in the preview. Returns { btn, refresh, setEnabled }.
local LAYER_LABEL = { both = "Both", inner = "Inner", outer = "Outer" }
local LAYER_OPTS = { { value = "both", label = "Both" }, { value = "inner", label = "Inner" }, { value = "outer", label = "Outer" } }

local GLOW_ROWS = {
  { "proc", "Proc", "proc" }, { "highlight", "Highlight", "highlight" },
  { "cast", "Cast", "cast" }, { "channel", "Channel", "channel" },
  { "hover", "Hover", "hover" }, { "selected", "Selected", "selected" },
  { "flash", "Flash", "flash" }, { "assist", "Assist", "assist" },
}

local function sampleIconTexture()
  local b = _G["ActionButton1"]
  local ic = b and (b.icon or b.Icon)
  local tex = ic and ic.GetTexture and ic:GetTexture()
  return tex or "Interface\\Icons\\INV_Misc_QuestionMark"
end

local PREVIEW_STATES = {
  { "idle", "Idle" }, { "proc", "Proc" },
  { "highlight", "Highlight" }, { "assist", "Assist" },
  { "cast", "Cast" }, { "channel", "Channel" },
  { "hover", "Hover" }, { "selected", "Selected" },
  { "flash", "Flash" }, { "cooldown", "Cooldown" },
  { "unusable", "Unusable" }, { "oom", "Out of Mana" },
  { "range", "Out of Range" },
}
local RING_TINT = { hover = { 1, 0.82, 0.35 }, selected = { 0.45, 0.75, 1 }, flash = { 1, 0.25, 0.25 } }

-- Live extension % (mirror Skin.lua ExtensionPct: hexagon is a fixed shape → no
-- plate; signed key with a legacy below-only fallback). Drives the preview's
-- plate/mask/overlay geometry exactly like the bars.
local function previewExtendPct()
  if (GB.db and GB.db.shape) == "hexagon" then return 0 end
  local c = GB.db and GB.db.styleData and GB.db.styleData.construction
  if not c then return 0 end
  if c.extendPct ~= nil then return c.extendPct end
  return c.extendBottomPct or 0
end

-- Anchor an overlay (state ring / cooldown / proc glow) over the whole preview
-- construction (icon + extension), mirroring Skin.AnchorConstruction so overlays
-- follow the full pill and not just the icon. `ratio` = padding grow per axis,
-- `extra` = extra px overshoot.
local function anchorPreviewOverlay(tex, ratio, extra, ref)
  extra = extra or 0
  ref = ref or previewIcon   -- plate mode passes previewFrame for full-construction overlays
  local gx = ref:GetWidth() * ratio + extra
  local gy = (ref:GetHeight() + previewExtH) * ratio + extra
  tex:ClearAllPoints()
  tex:SetPoint("TOPLEFT", ref, "TOPLEFT", -gx, gy + previewExtT)
  tex:SetPoint("BOTTOMRIGHT", ref, "BOTTOMRIGHT", gx, -(gy + previewExtB))
end

-- Pooled gradient-plate texture (textures can't be freed, only reused/hidden).
-- A brand-new texture flags `previewPlateFresh` so RefreshPreview retries its
-- mask next frame (never-rendered textures reject AddMaskTexture — API-NOTES §2).
local function getPreviewPlate(idx)
  local p = previewPlates[idx]
  if not p then
    local tex = previewFrame:CreateTexture(nil, "ARTWORK", nil, 1)   -- sublevel 1 = above the icon
    tex:SetTexture("Interface\\Buttons\\WHITE8X8")
    p = { tex = tex }
    previewPlates[idx] = p
    previewPlateFresh = true
  end
  return p
end

function C:RefreshPreview()
  if not previewIcon then return end
  local hk = GB.db and GB.db.handShape
  local handInfo = hk and GB:HandShapeInfo(hk)
  local shp = GB:GetShape()
  local style = GB:GetStyle()
  -- Reflect the icon's aspect ratio, fit within a ~104px box (long side = base).
  local base = PREVIEW_BASE
  local pw, ph = base, base
  if hk then
    -- Hand shape: aspect comes from the silhouette; cap the LONG side to the box.
    if handInfo.orient == "portrait" then pw, ph = base / handInfo.aspect, base
    elseif handInfo.orient == "landscape" then pw, ph = base, base / handInfo.aspect end
  else
    local iw, ih = (GB.db and GB.db.iconW) or 1, (GB.db and GB.db.iconH) or 1
    if iw > 0 and ih > 0 then
      if iw >= ih then pw, ph = base, base * ih / iw else pw, ph = base * iw / ih, base end
    end
  end
  previewFrame:SetSize(pw, ph)

  -- Plate mode (Stage 4b): mirror the bars — the SQUARE icon fills one half of the
  -- 2:1 silhouette, the plate colour the other. The full 2:1 rect IS previewFrame,
  -- so shape anchors (mask/glows/border) point at `sref` (the frame in plate mode)
  -- while the icon shrinks to its half. Non-plate: icon spans the frame, sref ==
  -- previewIcon, so nothing changes for the other shapes.
  previewPlateOn = (plateShapeOK() and plateData() and plateData().enabled) and true or false
  local plateSide = (plateData() and plateData().iconSide) or "top"
  previewIcon:ClearAllPoints()
  if previewPlateOn then
    previewIcon:SetSize(pw, pw)
    local e = (plateSide == "bottom") and "BOTTOM" or "TOP"
    previewIcon:SetPoint(e, previewFrame, e, 0, 0)
  else
    previewIcon:SetAllPoints(previewFrame)
  end
  local sref = previewPlateOn and previewFrame or previewIcon   -- the SHAPE reference rect

  -- Per-axis hand-mask growth (mirrors Skin.hgAnchor): a hand silhouette fills a
  -- different fraction of its canvas per axis, so grow each edge to land `grow` px
  -- out (caps stay round). Anchored to sref's corners using pw/ph directly
  -- (no reliance on GetWidth mid-refresh). grow=0 → icon edge; grow=t → border.
  local function handAnchor(tex, grow)
    grow = grow or 0
    local m0 = 0.5 * math.min(pw, ph)
    local aspect = math.max(pw, ph) / math.max(1, math.min(pw, ph))
    local addL = grow * (aspect + 1) / aspect
    local mx = m0 + (pw <= ph and 2 * grow or addL)
    local my = m0 + (ph < pw and 2 * grow or addL)
    tex:ClearAllPoints()
    tex:SetPoint("TOPLEFT", sref, "TOPLEFT", -mx, my)
    tex:SetPoint("BOTTOMRIGHT", sref, "BOTTOMRIGHT", mx, -my)
  end

  -- Construction = icon + extension (a plate above/below). Mirror the engine:
  -- extendPct is signed (< 0 = above), the hexagon has none, and Continuous-OFF
  -- only bites with a plate on a straight-sided shape — force it ON with no
  -- extension or a circle (else the plate loses its mask → an unmasked square).
  -- Hand shapes take no plate extension (the silhouette IS the elongation).
  local extPct = hk and 0 or previewExtendPct()
  local ext = ph * math.abs(extPct)
  local above = extPct < 0
  local continuous = not (style.construction and style.construction.continuous == false)
  if hk or ext == 0 or (GB.db and GB.db.shape) == "circle" then continuous = true end
  local maskExt = continuous and ext or 0
  previewExtH = ext
  previewExtT, previewExtB = (above and ext or 0), (above and 0 or ext)   -- overlays span the real ext
  local mExtT, mExtB = (above and maskExt or 0), (above and 0 or maskExt)  -- masks span only when continuous

  -- Center the whole construction in the stage; the icon shifts so a plate
  -- growing either way keeps the construction visually centered (never rides
  -- into the state chips above or the caption below).
  previewFrame:ClearAllPoints()
  previewFrame:SetPoint("CENTER", previewFrame:GetParent(), "TOP", 0,
    PREVIEW_CENTER_Y + (above and -ext / 2 or ext / 2))

  previewIcon:SetTexture(sampleIconTexture())
  -- Icon mask spans the construction when continuous (one pill wrapping icon +
  -- plate), else just the icon (a rounded icon on a crisp square plate). Same
  -- aspect source the engine uses (maskPlan → the construction's aspect).
  -- A hand shape masks the icon to its own -base silhouette (per-axis grown);
  -- otherwise the SDF aspect mask, grown by GROW_RATIO, as the engine does.
  local maskSrc = hk and GB:HandAsset(hk, "base") or GB.Skin:AspectMask(pw, ph + maskExt)
  local growX = pw * GROW_RATIO
  local growY = (ph + maskExt) * GROW_RATIO
  if previewMask then previewIcon:RemoveMaskTexture(previewMask) end
  previewMask = previewFrame:CreateMaskTexture()
  previewMask:SetTexture(maskSrc or shp.mask, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
  if hk then
    handAnchor(previewMask, 0)
  else
    previewMask:ClearAllPoints()
    previewMask:SetPoint("TOPLEFT", previewIcon, "TOPLEFT", -growX, growY + mExtT)
    previewMask:SetPoint("BOTTOMRIGHT", previewIcon, "BOTTOMRIGHT", growX, -(growY + mExtB))
  end
  previewIcon:AddMaskTexture(previewMask)
  -- Same cover-fit crop as the engine so the preview matches the bars (part a).
  -- Plate mode: the icon is the pw×pw square half → square crop, like the bars.
  if previewPlateOn then
    previewIcon:SetTexCoord(GB.Skin:TexCoordFor(pw, pw))
  else
    previewIcon:SetTexCoord(GB.Skin:TexCoordFor(previewIcon:GetWidth(), previewIcon:GetHeight()))
  end

  -- Overlay art + span follow the construction shape/aspect, like the bars.
  previewGlow:SetTexture(GB.Skin:GlowArt() or shp.glow)   -- SDF-fallback proc bloom (non-hand shapes)
  previewRing:SetTexture(GB.Skin:AspectRing(pw, ph + maskExt) or shp.ring)
  anchorPreviewOverlay(previewRing, GB.Skin:StateWidthRatio())   -- spread tracks the Glow width control
  anchorPreviewOverlay(previewCD, 0, 0)                    -- swipe covers the whole pill
  -- Multi-part glow (hand shapes): mirror the bars' outer (under icon, grown by the
  -- border) / inner (over plate, +2px) art + per-axis anchor; SetPreviewState tints/shows.
  if hk then
    local bg = (style.border and style.border.enabled and (style.border.thickness or 0) > 0) and style.border.thickness or 0
    previewOuter:SetTexture(GB:HandAsset(hk, "outer")); handAnchor(previewOuter, bg)
    previewInner:SetTexture(GB:HandAsset(hk, "inner")); handAnchor(previewInner, 2)
  end
  -- Cooldown sweep traces the hand silhouette (its -swipe) on hand shapes, else the SDF
  -- swipe. Plate mode: the icon-half swipe (the CD chip tracks previewIcon = the square).
  local swipePart = previewPlateOn and ((plateSide == "bottom") and "swipe-b" or "swipe-t") or "swipe"
  if previewCD.SetSwipeTexture then previewCD:SetSwipeTexture((hk and GB:HandAsset(hk, swipePart)) or GB.Skin:AspectSwipe(pw, ph + maskExt) or shp.swipe) end

  -- Gradient plate layers — mirror Skin.ApplyDecor's directional renderer. Each
  -- layer is a shape-masked (continuous) or square (off) fade; when an extension
  -- lies on the solid edge, a flat SOLID zone is drawn through it first (the
  -- "plate" look), then the fade travels from that edge across the icon.
  previewPlateFresh = false
  local function plateMask(plate)
    if plate.mask then plate.tex:RemoveMaskTexture(plate.mask); plate.mask = nil end
    if not continuous then return end                     -- square plate (crisp junction)
    local m = previewFrame:CreateMaskTexture()
    m:SetTexture(maskSrc or shp.mask, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    if hk then
      handAnchor(m, 0)
    else
      m:ClearAllPoints()
      m:SetPoint("TOPLEFT", previewIcon, "TOPLEFT", -growX, growY + mExtT)
      m:SetPoint("BOTTOMRIGHT", previewIcon, "BOTTOMRIGHT", growX, -(growY + mExtB))
    end
    plate.tex:AddMaskTexture(m)
    plate.mask = m
  end
  local used = 0
  -- Plate mode draws its OWN fill + gradient and skips the decoration layers,
  -- exactly like the engine (ApplyDecor's plate blocks).
  if previewPlateOn then
    local pd = plateData()
    local pc = (pd and pd.color) or { 0.1, 0.1, 0.13 }
    local fadeStart = (pd and pd.fadeStart) or 0.5
    -- Fill: the solid square half OPPOSITE the icon, clipped by the silhouette mask.
    used = used + 1
    local fill = getPreviewPlate(used); plateMask(fill)
    local e = (plateSide == "bottom") and "TOP" or "BOTTOM"
    fill.tex:ClearAllPoints()
    fill.tex:SetPoint(e, previewFrame, e, 0, 0); fill.tex:SetSize(pw, pw)
    local fc = CreateColor(pc[1], pc[2], pc[3], 1)
    fill.tex:SetGradient("VERTICAL", fc, fc)   -- solid (clears any pooled gradient)
    fill.tex:Show()
    -- Gradient: opaque at the midline, fading across fadeStart of the icon half.
    used = used + 1
    local grad = getPreviewPlate(used); plateMask(grad)
    local fromC, toC = CreateColor(pc[1], pc[2], pc[3], 1), CreateColor(pc[1], pc[2], pc[3], 0)
    grad.tex:ClearAllPoints(); grad.tex:SetHeight(math.max(0.01, pw * fadeStart))
    if plateSide == "bottom" then   -- icon in the BOTTOM half → opaque at its TOP, fading DOWN
      grad.tex:SetPoint("TOPLEFT", previewIcon, "TOPLEFT", 0, 0); grad.tex:SetPoint("TOPRIGHT", previewIcon, "TOPRIGHT", 0, 0)
      grad.tex:SetGradient("VERTICAL", toC, fromC)
    else                            -- icon in the TOP half → opaque at its BOTTOM, fading UP
      grad.tex:SetPoint("BOTTOMLEFT", previewIcon, "BOTTOMLEFT", 0, 0); grad.tex:SetPoint("BOTTOMRIGHT", previewIcon, "BOTTOMRIGHT", 0, 0)
      grad.tex:SetGradient("VERTICAL", fromC, toC)
    end
    grad.tex:Show()
  end
  for _, layer in ipairs((not previewPlateOn and style.layers) or {}) do
    if layer.enabled ~= false and layer.kind == "gradient" then
      local c = layer.color or { 1, 1, 1 }
      local fromC = CreateColor(c[1], c[2], c[3], layer.fromAlpha or 1)
      local toC = CreateColor(c[1], c[2], c[3], layer.toAlpha or 0)
      local dir = layer.dir or "up"
      local reach = layer.bleedPct or 0.5                 -- fraction of the icon the fade spans
      if dir == "left" or dir == "right" then
        local solidRight = (dir == "left")                -- fades left ⇒ solid on the right
        local edge = solidRight and "RIGHT" or "LEFT"
        used = used + 1
        local fade = getPreviewPlate(used); plateMask(fade)
        fade.tex:ClearAllPoints()
        fade.tex:SetPoint("TOP" .. edge, previewIcon, "TOP" .. edge, 0, previewExtT)
        fade.tex:SetPoint("BOTTOM" .. edge, previewIcon, "BOTTOM" .. edge, 0, -previewExtB)
        fade.tex:SetWidth(math.max(0.01, pw * reach))
        if solidRight then fade.tex:SetGradient("HORIZONTAL", toC, fromC)
        else fade.tex:SetGradient("HORIZONTAL", fromC, toC) end
        fade.tex:Show()
      else
        local solidBottom = (dir == "up")
        local edge = solidBottom and "BOTTOM" or "TOP"
        local extAligned = ext > 0 and ((solidBottom and not above) or (not solidBottom and above))
        if extAligned then
          used = used + 1
          local solid = getPreviewPlate(used); plateMask(solid)
          local outward = solidBottom and -ext or ext
          solid.tex:ClearAllPoints()
          solid.tex:SetPoint(edge .. "LEFT", previewIcon, edge .. "LEFT", 0, outward)
          solid.tex:SetPoint(edge .. "RIGHT", previewIcon, edge .. "RIGHT", 0, outward)
          solid.tex:SetHeight(ext)
          solid.tex:SetGradient("VERTICAL", fromC, fromC)
          solid.tex:Show()
        end
        used = used + 1
        local fade = getPreviewPlate(used); plateMask(fade)
        fade.tex:ClearAllPoints()
        fade.tex:SetPoint(edge .. "LEFT", previewIcon, edge .. "LEFT", 0, 0)
        fade.tex:SetPoint(edge .. "RIGHT", previewIcon, edge .. "RIGHT", 0, 0)
        fade.tex:SetHeight(math.max(0.01, ph * reach))
        if solidBottom then fade.tex:SetGradient("VERTICAL", fromC, toC)
        else fade.tex:SetGradient("VERTICAL", toC, fromC) end
        fade.tex:Show()
      end
    end
  end
  for i = used + 1, #previewPlates do previewPlates[i].tex:Hide() end

  -- Border — a colored shape-copy behind the icon, oversized by `thickness` and
  -- (like the engine) framing the whole masked construction. Fresh mask per
  -- refresh (cheap; dodges the live-mask re-render quirk).
  local bd = style.border
  if bd and bd.enabled and (bd.thickness or 0) > 0 then
    local t, col = bd.thickness, bd.color or { 0, 0, 0 }
    local a = bd.alpha or 1
    previewBorder:ClearAllPoints()
    previewBorder:SetPoint("TOPLEFT", sref, "TOPLEFT", -t, t + mExtT)
    previewBorder:SetPoint("BOTTOMRIGHT", sref, "BOTTOMRIGHT", t, -(mExtB + t))
    if bd.color2 then
      local c2 = bd.color2
      local orient = (bd.gradDir == "left" or bd.gradDir == "right") and "HORIZONTAL" or "VERTICAL"
      local g1 = CreateColor(col[1], col[2], col[3], (col[4] or 1) * a)
      local g2 = CreateColor(c2[1], c2[2], c2[3], (c2[4] or 1) * a)
      if bd.gradDir == "down" or bd.gradDir == "left" then previewBorder:SetGradient(orient, g2, g1)
      else previewBorder:SetGradient(orient, g1, g2) end
    else
      previewBorder:SetVertexColor(col[1], col[2], col[3], (col[4] or 1) * a)
    end
    if previewBorderMask then previewBorder:RemoveMaskTexture(previewBorderMask) end
    previewBorderMask = previewFrame:CreateMaskTexture()
    previewBorderMask:SetTexture(maskSrc or shp.mask, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    if hk then
      handAnchor(previewBorderMask, t)
    else
      local gx, gy = (pw + 2 * t) * GROW_RATIO, (ph + maskExt + 2 * t) * GROW_RATIO
      previewBorderMask:ClearAllPoints()
      previewBorderMask:SetPoint("TOPLEFT", previewIcon, "TOPLEFT", -(t + gx), (t + gy) + mExtT)
      previewBorderMask:SetPoint("BOTTOMRIGHT", previewIcon, "BOTTOMRIGHT", (t + gx), -(mExtB + t + gy))
    end
    previewBorder:AddMaskTexture(previewBorderMask)
    previewBorder:Show()
  else
    previewBorder:Hide()
  end

  -- Cast/channel fill preview: the frame spans the shape rect exactly (a draining
  -- rectangle — the mask does the shaping, same rule as the bars' fill); fresh
  -- same-frame mask per refresh (the border's pattern). The chip's very first
  -- show gets a one-frame retry from SetPreviewState (never-rendered quirk §2).
  if previewCastFillFrame then
    local pfl = previewCastFillFrame
    pfl:ClearAllPoints()
    pfl:SetPoint("TOPLEFT", sref, "TOPLEFT", 0, 0)
    pfl:SetPoint("BOTTOMRIGHT", sref, "BOTTOMRIGHT", 0, 0)
    if pfl.mask then pfl.tex:RemoveMaskTexture(pfl.mask) end
    pfl.mask = pfl:CreateMaskTexture()
    pfl.mask:SetTexture(maskSrc or shp.mask, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    if hk then
      handAnchor(pfl.mask, 0)
    else
      pfl.mask:ClearAllPoints()
      pfl.mask:SetPoint("TOPLEFT", previewIcon, "TOPLEFT", -growX, growY + mExtT)
      pfl.mask:SetPoint("BOTTOMRIGHT", previewIcon, "BOTTOMRIGHT", growX, -(growY + mExtB))
    end
    pfl.tex:AddMaskTexture(pfl.mask)
  end

  -- Caption tucks just below the construction (below the plate when it extends
  -- downward) so it never sits under the plate: bold state heading, body under it
  -- (an empty heading has zero height, so the default caption sits at the top).
  -- (Stage 3: the caption keeps its fixed anchors from buildPreviewPane — the
  -- mock's y, 20px insets. Only when a downward plate would reach it does it
  -- drop under the construction.)
  if previewCaption and previewCaptionHead then
    local pane2 = previewFrame:GetParent()
    local under = -PREVIEW_CENTER_Y + (previewFrame:GetHeight() or 104) / 2 + previewExtB + 26
    local y = math.max(PREVIEW_CAPTION_Y, under)
    previewCaptionHead:ClearAllPoints()
    previewCaptionHead:SetPoint("TOPLEFT", pane2, "TOPLEFT", 20, -y)
    previewCaptionHead:SetPoint("TOPRIGHT", pane2, "TOPRIGHT", -20, -y)

  end

  -- A plate texture created THIS frame hasn't rendered, so its first
  -- AddMaskTexture silently failed (never-rendered quirk, API-NOTES §2) → retry
  -- once next frame, by when it has drawn and accepts the mask.
  if previewPlateFresh and not previewRetryPending then
    previewRetryPending = true
    C_Timer.After(0, function()
      previewRetryPending = nil
      if container and container:IsVisible() then C:RefreshPreview() end
    end)
  end
end

function C:PreviewZoom(v)
  if previewIcon then
    previewIcon:SetTexCoord(GB.Skin:TexCoordFor(previewIcon:GetWidth(), previewIcon:GetHeight()))
  end
end

-- Replay the shaped finish flash on the preview (so its colour/shape is visible
-- without waiting for a real cooldown to end). Uses the same art + sizing as the
-- engine's playFinishFlash. No-op when the flash is disabled.
-- Shared burst player: the expanding flash tinted `c` — the cooldown finish flash
-- and the cast/channel COMPLETE burst both use it, differing only by colour.
-- Mirrors the bars' playFinishFlash: hand shapes use the shape's own -outer glow
-- art on the hand-canvas anchor (the art's silhouette occupies the centre half of
-- its canvas → margins of half the short side land its edge ON the shape edge);
-- the legacy SDF path keeps the old bloom + uniform grow.
local function playPreviewBurst(c)
  if not (previewFlash and previewIcon) then return end
  local hk = GB.db and GB.db.handShape
  previewFlash:SetTexture(hk and GB:HandAsset(hk, "outer") or GB.Skin:GlowArt())
  previewFlash:SetVertexColor(c[1], c[2], c[3])
  if hk then
    -- Plate mode spans the full 2:1 construction (the bars trace constructRef).
    local ref = previewPlateOn and previewFrame or previewIcon
    local m0 = 0.5 * math.min(previewFrame:GetWidth(), previewFrame:GetHeight())
    previewFlashFrame:ClearAllPoints()
    previewFlashFrame:SetPoint("TOPLEFT", ref, "TOPLEFT", -m0, m0)
    previewFlashFrame:SetPoint("BOTTOMRIGHT", ref, "BOTTOMRIGHT", m0, -m0)
  else
    anchorPreviewOverlay(previewFlashFrame, (128 / 80 - 1) / 2)
  end
  previewFlashFrame:SetAlpha(1)
  previewFlashAnim:Stop(); previewFlashAnim:Play()
end
function C:PlayPreviewFlash()
  if not (GB.db and GB.db.finishFlash) then return end
  playPreviewBurst(GB.db.finishFlashColor or { 1, 0.9, 0.5 })
end
-- (No cast-complete burst in the preview: the real one is Blizzard's EndBurst
-- animation replayed inside their widget — not reproducible faithfully here.)

-- Multi-part preview glow: for a hand shape, every glow-trigger chip (proc /
-- highlight / assist / cast / channel / hover / selected / flash) shows the real
-- outer+inner glow tinted by that trigger's colour / opacity / layers
-- (art + anchor set in RefreshPreview). Respects `enabled` (off → blank chip).
local GLOW_STATES = { proc = true, highlight = true, assist = true, cast = true,
  channel = true, hover = true, selected = true, flash = true }
local PREVIEW_PULSING = { proc = true, flash = true, assist = true, highlight = true }   -- mirror the bars' PULSING
local function applyPreviewGlow(key)
  local t = (GB.db and GB.db.triggers and GB.db.triggers[key]) or {}
  if t.enabled == false then previewOuter:Hide(); previewInner:Hide(); previewPulsing = false; return end
  local c = t.color or { 1, 0.85, 0.35 }
  local a = math.max(0.35, t.opacity or 0.9)
  local layers = t.layers or "both"
  previewOuter:SetVertexColor(c[1], c[2], c[3]); previewOuter:SetAlpha(a)
  previewInner:SetVertexColor(c[1], c[2], c[3]); previewInner:SetAlpha(a)
  previewOuter:SetShown(layers ~= "inner")
  previewInner:SetShown(layers ~= "outer")
  previewPulsing, previewPulsePeak = PREVIEW_PULSING[key] or false, a   -- the OnUpdate breathes it
end

function C:SetPreviewState(st)
  previewState = st or "idle"
  local hk = GB.db and GB.db.handShape
  local glowState = GLOW_STATES[previewState]
  -- Hand shape (the norm): drive the multi-part glow chips; hide the SDF bloom/ring.
  if previewOuter and previewInner then
    if hk and glowState then applyPreviewGlow(previewState)
    else previewOuter:Hide(); previewInner:Hide(); previewPulsing = false end
  end
  -- SDF fallback (non-hand): the single soft bloom (proc) + ring (states).
  if previewGlow then
    previewGlow:SetShown((not hk) and previewState == "proc")
    if (not hk) and previewState == "proc" and previewIcon then
      local pt = (GB.db and GB.db.triggers and GB.db.triggers.proc) or {}
      local c = pt.color or { 1, 0.85, 0.35 }
      local sc = (GB.db and GB.db.glowScale) or (128 / 80)
      anchorPreviewOverlay(previewGlow, (sc - 1) / 2)
      previewGlow:SetVertexColor(c[1], c[2], c[3])
      previewGlow:SetAlpha(math.max(0.35, pt.opacity or 0.9))
    end
  end
  if previewCD then
    if previewState == "cooldown" then
      -- Reflect the sweep tint / opacity via the same engine path the bars use.
      if GB.Skin and GB.Skin.StyleCooldown then GB.Skin:StyleCooldown(previewCD) end
      previewCD:Show(); previewCD:SetCooldown(GetTime(), 12)
    else previewCD:Hide() end
  end
  -- Cast / Channel chips: run the looping fake drain (colour / alpha / direction
  -- from the same db fields the bars read — edits in Cast & channel show live).
  if previewCastFillFrame then
    if previewState == "cast" or previewState == "channel" then
      local f = previewCastFillFrame
      f.channel = (previewState == "channel")
      local col = (GB.db and GB.db.castFillColor) or { 1, 0.85, 0.4 }
      local a = (GB.db and GB.db.castFillAlpha) or 0.55
      f.tex:SetVertexColor(col[1], col[2], col[3], a)
      f.tex:Show(); f:Show()
      if not f.everShown then
        -- Very first show: the tex had never rendered, so RefreshPreview's mask
        -- attach silently failed (§2) — re-attach one frame later.
        f.everShown = true
        C_Timer.After(0, function()
          if container and container:IsVisible() then local st = previewState; C:RefreshPreview(); C:SetPreviewState(st) end
        end)
      end
    else
      previewCastFillFrame:Hide()
    end
  end
  -- Icon tint: the availability chips mirror the engine's computeIconTint (range =
  -- desaturate + wash; oom / unusable = the configured vertex tint — same db fields
  -- the bars read); cooldown keeps its desaturated look; everything else full colour.
  if previewIcon then
    local adb = GB.db or {}
    if previewState == "range" then
      local c = adb.rangeColor or { 1, 0.2, 0.2 }
      previewIcon:SetDesaturated(true); previewIcon:SetVertexColor(c[1], c[2], c[3])
    elseif previewState == "oom" then
      local c = adb.availOOM or { 0.5, 0.5, 1 }
      previewIcon:SetDesaturated(false); previewIcon:SetVertexColor(c[1], c[2], c[3])
    elseif previewState == "unusable" then
      local c = adb.availUnusable or { 0.4, 0.4, 0.4 }
      previewIcon:SetDesaturated(adb.availDesaturate and true or false)
      previewIcon:SetVertexColor(c[1], c[2], c[3])
    else
      -- Normal state → mirror the engine's base icon tint (same db fields the bars
      -- read). Cooldown still desaturates on top of either mode, as the bars do.
      local mode = adb.iconTintMode or "off"
      if mode ~= "off" then
        local c = adb.iconTintColor or { 1, 1, 1 }
        local s = adb.iconTintStrength; if s == nil then s = 1 end
        s = (s < 0 and 0) or (s > 1 and 1) or s
        local wash = (mode == "wash") and s or 0
        if previewState == "cooldown" then wash = 1 end   -- cooldown desaturates regardless
        if previewIcon.SetDesaturation then previewIcon:SetDesaturation(wash)
        else previewIcon:SetDesaturated(wash > 0) end
        previewIcon:SetVertexColor(1 + (c[1] - 1) * s, 1 + (c[2] - 1) * s, 1 + (c[3] - 1) * s)
      else
        previewIcon:SetDesaturated(previewState == "cooldown")
        previewIcon:SetVertexColor(1, 1, 1)
      end
    end
  end
  local isRing = RING_TINT[previewState] ~= nil
  if previewRing then
    previewRing:SetShown((not hk) and isRing)
    if (not hk) and isRing then
      local rt = GB.db and GB.db.triggers and GB.db.triggers[previewState]
      local c = (rt and rt.color) or RING_TINT[previewState]
      previewRing:SetVertexColor(c[1], c[2], c[3])
      previewRing:SetAlpha((rt and rt.opacity) or 1)
    end
  end
  -- Glow chips don't show animations; the Animations section re-adds them via
  -- SetPreviewAnim. Clear any preview animation by default so they don't linger.
  if GB.Anims and previewFrame then GB.Anims:PreviewReconcile(previewFrame, previewPlateOn and previewFrame or previewIcon, GB.db and GB.db.handShape, nil) end
  for s2, chip in pairs(previewChips) do chip:SetActive(s2 == previewState) end
  -- Caption tracks whatever state is previewed (top chips or a section). SetPreviewAnim
  -- runs after this and overrides with the animation trigger's own description.
  setCaption(STATE_DESC[previewState])
end

-- Preview the selected trigger's glow (its chip, or idle) PLUS its enabled animations
-- on the preview host — the live-feedback surface for the Animations section.
-- Every animation trigger has a matching state chip now (session 12).
function C:SetPreviewAnim(triggerKey)
  self:SetPreviewState(triggerKey or "idle")
  if GB.Anims and previewFrame and previewIcon then
    local trigger = GB.db and GB.db.triggers and GB.db.triggers[triggerKey]
    -- Plate mode: animations span the full 2:1 construction (the bars' ConstructRef).
    GB.Anims:PreviewReconcile(previewFrame, previewPlateOn and previewFrame or previewIcon, GB.db and GB.db.handShape, trigger)
  end
  setCaption(STATE_DESC[triggerKey])
end

-- Animations — the per-trigger animation system (GB.Anims). Pick a trigger, then
-- enable/configure each registered animation module (shine, and future march/sheen/…)
-- for it. Params are generated from each module's schema, so new modules get a UI for
-- free. The preview host runs the selected trigger's enabled animations live.
local ANIM_TRIGGERS = {
  { "proc", "Proc" }, { "highlight", "Highlight" }, { "cast", "Cast" }, { "channel", "Channel" },
  { "hover", "Hover" }, { "selected", "Selected" }, { "flash", "Flash" }, { "assist", "Assist" },
}
local animTrigger = "proc"   -- which trigger the section is currently editing

local function animData(id)   -- saved params for the selected trigger's animation `id` (nil until created)
  local t = GB.db and GB.db.triggers and GB.db.triggers[animTrigger]
  return t and t.anims and t.anims[id]
end
local function animEnsure(id)   -- create the saved table from the module defaults (enabled = false)
  local t = GB.db and GB.db.triggers and GB.db.triggers[animTrigger]
  if not t then return nil end
  t.anims = t.anims or {}
  if not t.anims[id] then
    local mod = GB.Anims and GB.Anims:Get(id)
    local d = { enabled = false }
    if mod then for k, v in pairs(mod.defaults) do d[k] = (type(v) == "table") and { v[1], v[2], v[3], v[4] } or v end end
    t.anims[id] = d
  end
  return t.anims[id]
end
local function animDefault(id, key) local m = GB.Anims and GB.Anims:Get(id); return m and m.defaults[key] end
local function animGet(id, key) local d = animData(id); if d and d[key] ~= nil then return d[key] end; return animDefault(id, key) end
local function animSet(id, key, v) local d = animEnsure(id); if d then d[key] = v end end
local function animFmt(p)
  if p.fmt == "int" then return function(v) return tostring(math.floor(v + 0.5)) end end
  if p.fmt == "secs" then return function(v) return string.format("%.1fs", v) end end
  return function(v) return string.format("%.1f", v) end
end

local function sortedNames(t)
  local o = {}
  for name in pairs(t or {}) do o[#o + 1] = name end
  table.sort(o)
  return o
end
local function editName() local prof = GB:ActiveProfile(); return (prof and prof.edit) or "?" end

-- The PROFILE api: the Suite window draws it as the footer profile row
-- (RegisterTab `profile`, LibGloomSkin MINOR 11) — the same mechanism every
-- tool uses (the owner, 2026-07-24), same dialogs, same delete gate.
local PROFILE_API = {
  noun   = "profile",
  names  = function() return sortedNames(GB.db and GB.db.profiles) end,
  active = function() return GB:ActiveProfileName() or "?" end,
  switch = function(v) GB:SetActiveProfile(v) end,
  users  = function(name)
    local o = {}
    for char, p in pairs((GB.db and GB.db.charProfiles) or {}) do if p == name then o[#o + 1] = char end end
    return o
  end,
  create = function(name)
    if not GB:CreateProfile(name) then return false, "A profile with that name already exists." end
    GB:SetActiveProfile(name); return true
  end,
  copy = function(name)
    if not GB:CopyProfile(GB:ActiveProfileName(), name) then return false, "A profile with that name already exists." end
    GB:SetActiveProfile(name); return true
  end,
  rename = function(name)
    if not GB:RenameProfile(GB:ActiveProfileName(), name) then return false, "A profile with that name already exists." end
    return true
  end,
  delete = function()
    local gone = GB:ActiveProfileName()
    local ok, landedOn = GB:DeleteProfile(gone)
    if not ok then return false, "Can't delete the last profile." end
    -- Say where this character went. The fallback is arbitrary (Core picks it
    -- with `next`), so silence here left you on some other profile with no clue
    -- which. The note line is cleared on success, so this goes to chat.
    GB.msg(("deleted profile |cffffffff%s|r — this character is now on |cffffffff%s|r.")
      :format(gone, tostring(landedOn)))
    return true
  end,
  onChange = function() C:Refresh() end,
  tips = {
    dropdown = "The active profile for this character. Each character remembers its own; the profile library is shared account-wide.",
    new      = "Creates a profile with the default look, and switches to it. To start from THIS look instead, use Copy.",
    copy     = "Duplicates this profile — presets, bar assignments and all — and switches to the copy.",
    rename   = "Renames this profile. Characters using it follow the new name.",
    delete   = "Deletes this profile (you'll be asked to confirm). Characters using it fall back to another profile. The last profile can't be deleted.",
  },
}

-- Bar layout (phase L1+L2) — Gloom's Bars owns bar geometry PER BAR, opt-in;
-- Edit Mode keeps any bar left off. Engine: Layout.lua (containers only —
-- never the secure buttons; out-of-combat with a combat queue). Settings live
-- per bar in the PROFILE (barLayout[barKey]), beside the preset assignments.
local function barLayoutData(barKey)
  local prof = GB:ActiveProfile(); local t = prof and prof.barLayout; return t and t[barKey]
end
local function ensureBarLayout(barKey)
  local prof = GB:ActiveProfile(); if not prof then return nil end
  prof.barLayout = prof.barLayout or {}
  prof.barLayout[barKey] = prof.barLayout[barKey] or
    { size = 45, gap = 4, rows = 1, horizontal = true, count = 12 }
  return prof.barLayout[barKey]
end
local function layoutOn() local prof = GB:ActiveProfile(); return (prof and prof.layoutEnabled) or false end

-- ===========================================================================
-- ★ THE TWO-WINDOW DESIGN (2026-09-27, the owner's Figma page "GloomSuite UI 3":
-- "gloomBars, preview window", "gloomBars, Icon Size & Shape" … "Bar
-- Visibility Layout & Presets", "gloomBars, popout panel").
-- The Hub (Windows.lua) owns the windows. This file draws the PREVIEW window's
-- content, the settings window's TAB ("Editing Preset: <name>" — click the name
-- for the list, right-click it for Rename · Duplicate · Delete; New and Delete
-- beside it) and the seven SECTIONS. Every number inside a section is the
-- mock's own coordinate inside it: a labelled control is 33 tall (the label,
-- 4, the 16-tall control), rows 43 apart, blocks 30 apart, two columns of 170
-- at 0 and 190, three of 107/106/107 at 0 / 127 / 253.
-- A control that cannot apply right now DIMS to 30% with its label — never
-- hides (the suite's rule).
-- ===========================================================================

local OFFON = { { false, "Off" }, { true, "On" } }
local DIRS = { { "up", "Up" }, { "down", "Down" }, { "left", "Left" }, { "right", "Right" } }
local C1, C2 = 0, 190
local T1, T2, T3 = 0, 127, 253

local function Label(parent, x, y, text, size, c)
  local l = UI.gLabel(parent, text, size or 12, c); l:SetPoint("TOPLEFT", x, -y)
  return l
end
local function Title(parent, x, y, text, size)
  local t = UI.gTitle(parent, text, size); t:SetPoint("TOPLEFT", x, -y)
  return t
end
-- values = { {stored, label} } or a function returning that
local function Drop(parent, x, y, w, label, values, get, set, opts)
  local lbl = label and Label(parent, x, y, label)
  local function list() return type(values) == "function" and values() or values end
  local d = UI.gDrop(parent, w,
    function()
      local cur = get()
      for _, v in ipairs(list()) do if v[1] == cur then return v[2] end end
      return (opts and opts.fallback) and opts.fallback(cur) or nil
    end,
    function()
      local out = {}
      for _, v in ipairs(list()) do out[#out + 1] = { value = v[1], label = v[2], disabled = v[3] } end
      return out
    end,
    get, set, opts)
  d:SetPoint("TOPLEFT", x, -(y + (label and 17 or 0)))
  d._label = lbl
  return d
end
local function Switch(parent, x, y, w, label, choices, get, set, opts)
  local lbl = label and Label(parent, x, y, label)
  opts = opts or {}; opts.w = opts.w or w
  local s = UI.gSwitch(parent, choices, get, set, opts)
  s:SetPoint("TOPLEFT", x, -(y + (label and 17 or 0)))
  s._label = lbl
  return s
end
local function Dial(parent, x, y, w, opts)
  opts.w = w
  local d = UI.gDial(parent, opts)
  d:SetPoint("TOPLEFT", x, -y)
  return d
end
local function Color(parent, x, y, w, label, opts)
  local lbl = label and Label(parent, x, y, label)
  -- `label` in these opts is the color's name in the picker's palette list
  -- ("Bars › Plate color"), not text to draw.
  opts.palette, opts.label = opts.label, nil
  opts.title = opts.title or label
  opts.w = w
  local c = UI.gColor(parent, opts)
  c:SetPoint("TOPLEFT", x, -(y + (label and 17 or 0)))
  c._label = lbl
  return c
end

-- A section and its controls. `gate` (optional) is an extra condition for being
-- usable; the section's refresh re-reads every control and re-applies the gates.
local function Section(id, parent, h)
  local f = CreateFrame("Frame", nil, parent)
  f:SetSize(360, h)
  local pg = { frame = f, items = {}, id = id }
  P.pages[id] = pg
  f:HookScript("OnShow", function() P.refreshSection(pg); if pg.onShow then pg.onShow() end end)
  return pg
end
local function add(pg, ctrl, gate)
  pg.items[#pg.items + 1] = { ctrl = ctrl, gate = gate }
  return ctrl
end
local function refreshPage(pg)
  for _, it in ipairs(pg.items) do
    local c = it.ctrl
    if c.refresh then c:refresh() end
    local ok = not it.gate or it.gate()
    if c.setEnabled then c:setEnabled(ok)
    elseif c.SetEnabled then c:SetEnabled(ok); c:SetAlpha(ok and 1 or UI.G_DIM) end
    if c._label then c._label:SetAlpha(ok and 1 or UI.G_DIM) end
  end
  if pg.after then pg.after() end
end
P.refreshSection = refreshPage

-- ---------------------------------------------------------------------------
-- SECTION · ICON SIZE & SHAPE (the mock's Frames 545-548, 415 tall)
-- The preset silhouettes as a grouped tile grid. The shaped-glow pivot (session
-- 8, docs/SHAPE-CATALOG.md) retired free width/height: the icon is ONE baked
-- silhouette so it can't warp, and Icon Scale scales every icon together.
-- ---------------------------------------------------------------------------
local function buildShapePage(parent)
  local pg = Section("shape", parent, 415); local f = pg.frame
  -- "Icon Scale": the icon within its button, per preset. The whole BUTTON's
  -- size is Icon Size, per bar, in Bar Visibility, Layout & Presets.
  local sizeDial = add(pg, Dial(f, C1, 0, 170, { label = "Icon Scale", min = 50, max = 200, step = 5, unit = "%",
    get = function() return math.floor(((GB.db and GB.db.sizeScale) or 1) * 100 + 0.5) end,
    set = function(v) v = v / 100; if GB.Skin then GB.Skin:SetSizeScale(v) else GB.db.sizeScale = v end; C:RefreshPreview() end }))
  attachTip(sizeDial.strip, "Icon scale", "Scales every icon together, as a percentage of its button. The clickable hit area stays Edit Mode's. (The whole button's size is Icon Size, per bar, in Bar Visibility, Layout & Presets.)")
  local zoomDial = add(pg, Dial(f, C2, 0, 170, { label = "Icon Zoom", min = 0, max = 30, unit = "%",
    get = function() return math.floor(((GB.db and GB.db.zoom) or 0) * 100 + 0.5) end,
    set = function(v) v = v / 100; if GB.Skin then GB.Skin:SetZoom(v) end; C:PreviewZoom(v) end }))
  attachTip(zoomDial.strip, "Icon zoom", "Crops into the icon art from every side, hiding Blizzard's baked-in border.")
  local fill = add(pg, Switch(f, C1, 43, 170, "Crop to Fill", OFFON,
    function() return not (GB.db and GB.db.iconFill == "stretch") end,
    function(v)
      if GB.Skin then GB.Skin:SetIconFill(v and "fill" or "stretch") else GB.db.iconFill = v and "fill" or "stretch" end
      C:RefreshPreview()
    end))
  attachTip(fill, "Crop to fill", "On: a non-square shape crops the icon art to fill it. Off: the art is stretched to the shape.")

  -- One tile (the mocks' Frame 376): 36 square, violet 20% with 4-unit corners
  -- (violet when chosen), the silhouette's own -base.png fit to its aspect in a
  -- 24 box. Eight to a row, 10 apart.
  local thumbs = {}
  local CELL, PITCH, PER_ROW = 36, 46, 8
  local function makeThumb(key)
    local info = GB.HAND_SHAPES[key] or GB.HAND_SHAPES.circle
    local b = CreateFrame("Button", nil, f)
    b:SetSize(CELL, CELL)
    local bg = UI.gRounded(b, { radius = 4, color = { 1, 1, 1, 1 } })
    bg:Place(0, 0, CELL, CELL)
    local box = 24
    local w, h = box, box
    if info.orient == "portrait" then w = box / info.aspect
    elseif info.orient == "landscape" then h = box / info.aspect end
    local tex = b:CreateTexture(nil, "ARTWORK")
    tex:SetSize(w, h); tex:SetPoint("CENTER"); tex:SetTexture(GB:HandAsset(key, "base"))
    local function paint(self)
      local a = self._sel and 1 or (self._hot and 0.4 or 0.2)
      for _, t in ipairs(bg.parts) do
        if t:GetTexture() then t:SetVertexColor(VIOLET.r, VIOLET.g, VIOLET.b, a) else t:SetColorTexture(VIOLET.r, VIOLET.g, VIOLET.b, a) end
      end
    end
    function b:SetSelected(on) self._sel = on and true or false; paint(self) end
    b:SetScript("OnEnter", function(self)
      self._hot = true; paint(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetText(info.label, 1, 1, 1); GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function(self) self._hot = false; paint(self); GameTooltip:Hide() end)
    b:SetScript("OnClick", function()
      if GB.Skin then GB.Skin:SetHandShape(key) else GB.db.handShape = key end
      refreshPage(pg); C:RefreshPreview()
    end)
    b:SetSelected(false)
    return b
  end
  -- "Icon Shape" + the group's name in lime (Sansation 12) at each group's top;
  -- the tiles 23 under it; the next group 20 after the last row.
  local y = 106
  for _, g in ipairs(GB.HAND_GROUPS) do
    Label(f, 0, y, ("Icon Shape |cff%s%s|r"):format(LIME.hex, g.title))
    local rows = 1
    for i, key in ipairs(g.keys) do
      local col, row = (i - 1) % PER_ROW, math.floor((i - 1) / PER_ROW)
      rows = math.max(rows, row + 1)
      local th = makeThumb(key); thumbs[key] = th
      th:SetPoint("TOPLEFT", col * PITCH, -(y + 23 + row * PITCH))
    end
    y = y + 23 + (rows - 1) * PITCH + CELL + 20
  end
  f:SetHeight(y - 20)
  pg.after = function()
    local active = GB.db and GB.db.handShape
    for key, th in pairs(thumbs) do th:SetSelected(key == active) end
  end
  return f
end

-- ---------------------------------------------------------------------------
-- SECTION · DECORATION LAYERS (the mock's Panel Content, 523 tall)
-- ---------------------------------------------------------------------------
local function buildDecoPage(parent)
  local pg = Section("deco", parent, 523); local f = pg.frame
  local function decor() if GB.Skin then GB.Skin:ReapplyDecor() end; C:RefreshPreview() end
  local function relook() refreshPage(pg) end

  -- PLATE CONSTRUCTION — the 2:1-shape look: a SQUARE icon fills one half, a
  -- solid-color plate the other, and that color fades up over the icon. Only
  -- meaningful on a 2:1 portrait shape; dimmed (with the note) on any other.
  local function plateOn() local p = plateData(); return p and p.enabled and true or false end
  local function live() return plateShapeOK() and plateOn() end
  local on = add(pg, Switch(f, C1, 0, 170, "Plate Construction", OFFON, plateOn, function(v)
    local p = ensurePlate(); if p then p.enabled = v and true or false end
    if GB.Skin then GB.Skin:RefreshPlate() end
    C:RefreshPreview(); relook()
  end), plateShapeOK)
  attachTip(on, "Plate construction", "Square icon in one half of a 2:1 shape, a solid plate with a color fade in the other.")
  -- Icon alignment: which half the square icon fills (the plate fills the other).
  add(pg, Switch(f, C2, 0, 170, "Icon Alignment", { { "top", "Top" }, { "bottom", "Bottom" } },
    function() return (plateData() and plateData().iconSide) or "top" end,
    function(v)
      local p = ensurePlate(); if p then p.iconSide = v end
      if GB.Skin then GB.Skin:RefreshPlate() end
      C:RefreshPreview()
    end), live)
  add(pg, Color(f, C1, 43, 170, "Plate Color", { label = "Bars › Plate color",
    get = function() local p = plateData(); return p and p.color end,
    set = function(c) local p = ensurePlate(); if p then p.color = c end; local l = gradLayer(); if l then l.color = c end; decor() end }), live)
  -- Fade start: how far the plate color bleeds up over the icon. Kept in sync with the
  -- gradient's fade (bleedPct) when a gradient layer exists.
  local fade = add(pg, Dial(f, C2, 43, 170, { label = "Fade Start", min = 0, max = 100, step = 5, unit = "%",
    get = function() local p = plateData(); return math.floor(((p and p.fadeStart) or 0.5) * 100 + 0.5) end,
    set = function(v)
      v = v / 100
      local p = ensurePlate(); if p then p.fadeStart = v end
      local l = gradLayer(); if l then l.bleedPct = v end
      decor()
    end }), live)
  attachTip(fade.strip, "Fade start", "How far up the icon the plate color bleeds before it fades out.")
  -- Dim on cooldown: the plate color darkens while the action's REAL (non-GCD)
  -- cooldown runs. Engine: Skin's dim proxy.
  add(pg, Switch(f, C1, 86, 170, "Dim on Cooldown", OFFON,
    function() local p = plateData(); return p and p.dimCD and true or false end,
    function(v)
      local p = ensurePlate(); if p then p.dimCD = v and true or false end
      if GB.Skin and GB.Skin.RefreshPlateDim then GB.Skin:RefreshPlateDim() end
    end), live)
  local note = UI.gLabel(f, "", 9); note:SetPoint("TOPLEFT", C2, -86); note:SetWidth(170); note:SetJustifyH("LEFT")
  note:SetWordWrap(true)
  note:SetText("Note: Plate Construction needs a 2:1 aspect ratio. Pick |cffffffffPill 2:1|r, |cffffffffTall Square 2:1|r, or a |cffffffffTall Rounded 2:1|r in Icon Size & Shape.")

  -- GRADIENT OVERLAY — the fill that runs across the icon and fades out.
  local function gradOn() local l = gradLayer(); return l and l.enabled ~= false end
  add(pg, Switch(f, C1, 149, 170, "Gradient Overlay", OFFON, function() return gradOn() and true or false end,
    function(v) local l = ensureGradLayer(); l.enabled = v; decor(); relook() end))
  add(pg, Color(f, C2, 149, 170, "Gradient Color", { label = "Bars › Gradient fill color",
    get = function() local l = gradLayer(); return l and l.color end,
    set = function(c) local l = ensureGradLayer(); l.color = c; if plateData() then plateData().color = c end; decor() end }), gradOn)
  local gstart = add(pg, Dial(f, C1, 192, 170, { label = "Gradient Start", min = 0, max = 100, step = 5, unit = "%",
    get = function() local l = gradLayer(); return math.floor(((l and l.bleedPct) or 0.5) * 100 + 0.5) end,
    set = function(v) v = v / 100; local l = ensureGradLayer(); l.bleedPct = v; if plateData() then plateData().fadeStart = v end; decor() end }), gradOn)
  attachTip(gstart.strip, "Gradient start", "How far across the icon the color reaches before it fades out; the direction sets the solid edge.")
  add(pg, Switch(f, C2, 192, 170, "Gradient Direction", DIRS,
    function() local l = gradLayer(); return (l and l.dir) or "up" end,
    function(d) local l = ensureGradLayer(); l.dir = d; decor() end), gradOn)

  -- ICON BORDER
  local function bOn() local b2 = borderData(); return b2 and b2.enabled and true or false end
  -- Off keeps the second color (twoTone = false), so On brings it back
  -- unchanged (the owner, 2026-09-21: wiping it "is bad").
  local function twoOn() local b2 = borderData(); return b2 and b2.color2 ~= nil and b2.twoTone ~= false end
  add(pg, Switch(f, C1, 255, 170, "Icon Border", OFFON, bOn,
    function(v) local b2 = ensureBorder(); b2.enabled = v; decor(); relook() end))
  add(pg, Dial(f, C2, 255, 170, { label = "Border Thickness", min = 1, max = 12, unit = "px",
    get = function() local b2 = borderData(); return (b2 and b2.thickness) or 3 end,
    set = function(v) local b2 = ensureBorder(); b2.thickness = v; decor() end }), bOn)
  add(pg, Dial(f, C1, 298, 170, { label = "Border Opacity", min = 0, max = 100, step = 5, unit = "%",
    get = function() local b2 = borderData(); return math.floor(((b2 and b2.alpha) or 1) * 100 + 0.5) end,
    set = function(v) local b2 = ensureBorder(); b2.alpha = v / 100; decor() end }), bOn)
  add(pg, Color(f, C2, 298, 170, "Border Color", { hasAlpha = true, label = "Bars › Border color",
    get = function() local b2 = borderData(); return b2 and b2.color end,
    set = function(c) local b2 = ensureBorder(); b2.color = c; decor() end }), bOn)
  local two = add(pg, Switch(f, C1, 341, 170, "Two-Color Border", OFFON, function() return twoOn() and true or false end,
    function(v)
      local b2 = ensureBorder()
      if v then b2.color2 = b2.color2 or { 1, 1, 1 }; b2.twoTone = nil else b2.twoTone = false end
      decor(); relook()
    end), bOn)
  attachTip(two, "Two-color border", "Makes the border a gradient between its color and the second color, along the gradient direction.")
  local function twoLive() return bOn() and twoOn() end
  add(pg, Color(f, C2, 341, 170, "Second Border Color", { hasAlpha = true, required = true, label = "Bars › Border color 2", title = "Second Border Color",
    get = function() local b2 = borderData(); return b2 and b2.color2 end,
    set = function(c) local b2 = ensureBorder(); b2.color2 = c; decor() end }), twoLive)
  add(pg, Switch(f, C1, 384, 170, "Gradient Direction", DIRS,
    function() local b2 = borderData(); return (b2 and b2.gradDir) or "up" end,
    function(d) local b2 = ensureBorder(); b2.gradDir = d; decor() end), twoLive)

  -- ICON TINT
  local function tintOn() return ((GB.db and GB.db.iconTintMode) or "off") ~= "off" end
  local mode = add(pg, Switch(f, C1, 447, 170, "Colorize Icon", { { "off", "Off" }, { "wash", "Wash" }, { "tint", "Tint" } },
    function() return (GB.db and GB.db.iconTintMode) or "off" end,
    function(m) if GB.Skin then GB.Skin:SetIconTintMode(m) end; relook(); C:SetPreviewState("idle") end))
  attachTip(mode, "Colorize icon", "Colors the normal state only, so out-of-range, out-of-mana and unusable still show through. Wash gives one clean color but makes icons harder to tell apart; Tint keeps the art and adds a cast (pale colors work best).")
  add(pg, Color(f, C2, 447, 170, "Tint Color", { label = "Bars › Icon tint",
    get = function() return GB.db and GB.db.iconTintColor end,
    set = function(c) if GB.Skin then GB.Skin:SetIconTintColor(c) end; C:SetPreviewState("idle") end }), tintOn)
  add(pg, Dial(f, C1, 490, 170, { label = "Tint Strength", min = 0, max = 100, step = 5, unit = "%",
    get = function() local v = GB.db and GB.db.iconTintStrength; return math.floor((v == nil and 1 or v) * 100 + 0.5) end,
    set = function(v) if GB.Skin then GB.Skin:SetIconTintStrength(v / 100) end; C:SetPreviewState("idle") end }), tintOn)

  pg.after = function() note:SetAlpha(plateShapeOK() and 0.4 or 1) end
  return f
end

-- ---------------------------------------------------------------------------
-- SECTION · TEXT (the mock's Panel Contents, 374 tall). ONE set of controls;
-- Bar Text Type (Keybind · Charge Count · Countdown · Name) decides which text
-- they edit.
-- ★ NAME is Off / On like the rest (the owner, 2026-09-25: drop "use Blizzard's"):
-- Off = no name text, On = the styling here. A preset still on Blizzard's own
-- name text ("default") reads On, and becomes Custom the moment it is edited.
-- ---------------------------------------------------------------------------
local function buildTextPage(parent)
  local pg = Section("text", parent, 374); local f = pg.frame
  local function reapply() if GB.Skin then GB.Skin:ReapplyDecor() end end
  local function reCD() if GB.Skin and GB.Skin.RefreshCooldownText then GB.Skin:RefreshCooldownText() end end
  local function ensureNameCustom()
    local c = ensureName()
    if c and nameMode() == "default" then c.mode = "custom"; c.enabled = nil end
    return c
  end
  local KINDS = {
    keybind = { title = "Keybind", data = hotkeyData, ensure = ensureHotkey, apply = reapply, on = hotkeyOn,
      setOn = function(v) local h = ensureHotkey(); if h then h.enabled = v and true or false end; reapply(); if GB.Skin then GB.Skin:RefreshHotkeyText() end end,
      zones = { { "center", "Center" }, { "extension", "Extension" } }, zoneDefault = "extension",
      sizeMin = 6, sizeMax = 28, sizeDefault = 13, shadowDefault = false },
    count = { title = "Charge Count", data = countData, ensure = ensureCount, apply = reapply, on = countOn,
      setOn = function(v) local c = ensureCount(); if c then c.enabled = v and true or false end; reapply() end,
      zones = { { "corner", "Corner" }, { "center", "Center" }, { "extension", "Plate" } }, zoneDefault = "corner",
      sizeMin = 6, sizeMax = 28, sizeDefault = 14, shadowDefault = false },
    cdtext = { title = "Countdown", data = cdtextData, ensure = ensureCdtext, apply = reCD, on = cdtextOn,
      setOn = function(v) local c = ensureCdtext(); if c then c.enabled = v and true or false end; reCD() end,
      sizeMin = 8, sizeMax = 30, sizeDefault = 16, shadowDefault = true },
    name = { title = "Name", data = nameData, ensure = ensureNameCustom, apply = reapply,
      on = function() return nameMode() ~= "hidden" end,
      setOn = function(v) local c = ensureName(); if c then c.mode = v and "custom" or "hidden"; c.enabled = nil end; reapply() end,
      zones = { { "bottom", "Bottom" }, { "center", "Center" }, { "extension", "Plate" } }, zoneDefault = "bottom",
      sizeMin = 6, sizeMax = 28, sizeDefault = 10, shadowDefault = true },
  }
  local tab = "keybind"
  local function K() return KINDS[tab] end
  local function data() return K().data() end
  local function ensure() return K().ensure() end
  local function apply() K().apply() end
  local function live() return K().on() and true or false end
  local function num(field, default) return function() local c = data(); return (c and c[field]) or (type(default) == "function" and default() or default) end end
  local function setNum(field) return function(v) local c = ensure(); if c then c[field] = v end; apply() end end

  local tabs = Switch(f, 0, 0, 360, "Bar Text Type", { { "keybind", "Keybind" }, { "count", "Charge Count" }, { "cdtext", "Countdown" }, { "name", "Name" } },
    function() return tab end, function(v) tab = v; refreshPage(pg) end)

  local head = add(pg, Switch(f, C1, 43, 170, "Custom Text", OFFON, live, function(v) K().setOn(v); refreshPage(pg) end))
  attachTip(head, "Custom text", "Keybind and Charge Count: On restyles Blizzard's text with the settings here. Countdown: shows or hides the cooldown numbers. Name: shows your styled macro name, or none.")
  add(pg, Drop(f, C2, 43, 170, "Font",
    function() local o = { { "", "Default" } }; for _, n in ipairs(fontChoices()) do o[#o + 1] = { n, n } end; return o end,
    function() local c = data(); return (c and c.font) or "" end,
    function(v) local c = ensure(); if c then c.font = (v ~= "") and v or nil end; apply() end,
    { fallback = function(cur) return (cur and cur ~= "") and cur or "Default" end }), live)
  add(pg, Color(f, C1, 86, 170, "Text Color", { label = "Bars › Text color",
    get = function() local c = data(); return c and c.color end,
    set = function(col) local c = ensure(); if c then c.color = col end; apply() end }), live)
  -- Text Anchor: each text has its own places; Countdown has none (it sits where
  -- the cooldown draws it), so the control dims there.
  local anchorLbl = Label(f, C2, 86, "Text Anchor")
  local anchors = {}
  for key, k in pairs(KINDS) do
    if k.zones then
      anchors[key] = Switch(f, C2, 103, 170, nil, k.zones,
        function() local c = k.data(); return (c and c.zone) or k.zoneDefault end,
        function(v) local c = k.ensure(); if c then c.zone = v end; k.apply() end)
    end
  end
  local cdAnchor = Switch(f, C2, 103, 170, nil, { { "cooldown", "With the Sweep" } }, function() return "cooldown" end, function() end)
  add(pg, Dial(f, C1, 129, 170, { label = "Font Size", min = 6, max = 30, unit = "px",
    get = function() local c = data(); return (c and c.size) or K().sizeDefault end,
    set = function(v) v = math.max(K().sizeMin, math.min(K().sizeMax, v)); local c = ensure(); if c then c.size = v end; apply() end }), live)

  -- The text's own offset, its outline, and Keybind's Mac symbols.
  add(pg, Dial(f, C1, 192, 170, { label = "Text Horizontal Offset", min = -40, max = 40, unit = "px", get = num("offsetX", 0), set = setNum("offsetX") }), live)
  add(pg, Switch(f, C2, 192, 170, "Text Outline", { { "", "None" }, { "OUTLINE", "Outline" }, { "THICKOUTLINE", "Thick" } },
    function() local c = data(); return (c and c.flags) or "OUTLINE" end,
    function(v) local c = ensure(); if c then c.flags = v end; apply() end), live)
  add(pg, Dial(f, C1, 235, 170, { label = "Text Vertical Offset", min = -40, max = 40, unit = "px", get = num("offsetY", 0), set = setNum("offsetY") }), live)
  local mac = add(pg, Switch(f, C2, 235, 170, "Mac Symbol Icons", OFFON,
    function() local st = GB.db and GB.db.styleData; return (st and st.keybindMods == "symbols") and true or false end,
    function(v)
      local st = GB.db and GB.db.styleData; if st then st.keybindMods = v and "symbols" or "default" end
      if GB.Skin then GB.Skin:RefreshHotkeyText() end
    end), function() return tab == "keybind" and live() end)
  attachTip(mac, "Mac symbol icons", "Keybind only: replaces the m-/s-/c-/a- prefixes with ⌘/⇧/⌃/⌥ (macOS binds).")

  -- TEXT SHADOW
  local function shadow() local c = data(); return c and c.shadow end
  local function shadowOn()
    local sh = shadow()
    if sh == nil then return K().shadowDefault end   -- legacy: mirror the engine's fallback
    return sh.enabled and true or false
  end
  local function ensureShadow()
    local c = ensure(); if not c then return nil end
    c.shadow = c.shadow or { enabled = K().shadowDefault, color = { 0, 0, 0, 1 }, x = 1, y = -1 }
    return c.shadow
  end
  local function shLive() return live() and shadowOn() end
  add(pg, Switch(f, C1, 298, 170, "Text Shadow", OFFON, function() return shadowOn() and true or false end,
    function(v) local sh = ensureShadow(); if sh then sh.enabled = v and true or false end; apply(); refreshPage(pg) end), live)
  add(pg, Dial(f, C2, 298, 170, { label = "Shadow Offset X", min = -8, max = 8, unit = "px",
    get = function() local sh = shadow(); return (sh and sh.x) or 1 end,
    set = function(v) local sh = ensureShadow(); if sh then sh.x = v end; apply() end }), shLive)
  add(pg, Color(f, C1, 341, 170, "Shadow Color", { hasAlpha = true, label = "Bars › Text shadow color",
    get = function() local sh = shadow(); return sh and sh.color end,
    set = function(col) local sh = ensureShadow(); if sh then sh.color = col end; apply() end }), shLive)
  add(pg, Dial(f, C2, 341, 170, { label = "Shadow Offset Y", min = -8, max = 8, unit = "px",
    get = function() local sh = shadow(); return (sh and sh.y) or -1 end,
    set = function(v) local sh = ensureShadow(); if sh then sh.y = v end; apply() end }), shLive)

  pg.after = function()
    tabs:refresh()
    for key, sw in pairs(anchors) do
      sw:SetShown(key == tab)
      sw:refresh(); sw:setEnabled(live())
    end
    cdAnchor:SetShown(tab == "cdtext"); cdAnchor:setEnabled(false)
    anchorLbl:SetAlpha((tab ~= "cdtext" and live()) and 1 or UI.G_DIM)
  end
  return f
end

-- ---------------------------------------------------------------------------
-- SECTION · GLOWS & ANIMATIONS (the mock's Panel Contents, 500 tall)
-- ---------------------------------------------------------------------------
local ANIM_ORDER = { "proc", "highlight", "cast", "channel", "hover", "selected", "flash", "assist" }
local function buildGlowsPage(parent)
  local pg = Section("glows", parent, 500); local f = pg.frame
  local function showPrev(prev) if prev then C:SetPreviewState(prev) end end

  -- CUSTOM GLOWS — Pulse Speed across the width, then a TABLE, one line per
  -- trigger, 24 apart: the name right-aligned to x 53, its switch (a checkbox),
  -- the color disc, the layer, the opacity.
  Title(f, 0, 0, "Custom Glows", 14)
  add(pg, Dial(f, 0, 26, 360, { label = "Pulse Speed", min = 0.3, max = 2, step = 0.1, unit = "x",
    get = function() return (GB.db and GB.db.glowPulseSpeed) or 1 end,
    -- The engine reads glowPulseSpeed live (Glows.lua glowSpeed()).
    set = function(v) if GB.db then GB.db.glowPulseSpeed = v end end }))
  for i, r in ipairs(GLOW_ROWS) do
    local key, label, prev = r[1], r[2], r[3]
    local y = 79 + (i - 1) * 24
    local function on() local t = trig(key); return t and t.enabled ~= false end
    local lab = UI.gLabel(f, label, 12); lab:SetPoint("TOPRIGHT", f, "TOPLEFT", 53, -(y + 1.5)); lab:SetJustifyH("RIGHT")
    local chk = UI.gCheck(f, nil, function() return on() and true or false end,
      function(v) if GB.Glows then GB.Glows:SetTriggerEnabled(key, v) end; refreshPage(pg); showPrev(prev) end)
    chk:SetPoint("TOPLEFT", 63, -y)
    add(pg, chk)
    local col = add(pg, Color(f, 89, y + 0.5, nil, nil, { required = true, dot = true, label = "Bars › Glow › " .. label, title = label .. " Glow Color",
      get = function() local t = trig(key); return t and t.color end,
      set = function(c) if GB.Glows then GB.Glows:SetTriggerColor(key, c) end; showPrev(prev) end }), on)
    col:ClearAllPoints(); col:SetPoint("TOPLEFT", 89, -(y + 0.5))
    add(pg, Drop(f, 114, y, 80, nil, { { "both", "Both" }, { "inner", "Inner" }, { "outer", "Outer" } },
      function() local t = trig(key); return (t and t.layers) or "both" end,
      function(v) if GB.Glows then GB.Glows:SetTriggerLayers(key, v) end; showPrev(prev) end), on)
    add(pg, Dial(f, 204, y, 156, { bare = true, label = label .. " opacity", min = 0, max = 100, step = 5, unit = "%",
      get = function() local t = trig(key); return math.floor(((t and t.opacity) or 1) * 100 + 0.5) end,
      set = function(v) if GB.Glows then GB.Glows:SetTriggerOpacity(key, v / 100) end; showPrev(prev) end }), on)
    pg.items[#pg.items + 1] = { ctrl = { refresh = function() end, setEnabled = function() end },
      gate = function() lab:SetAlpha(on() and 1 or UI.G_DIM); return true end }
  end

  -- CUSTOM ANIMATIONS — pick a state (the two-row switch), then the one
  -- animation it runs (or None) and that animation's own settings, built from
  -- the module's schema so a new module grows its controls here: two to a row
  -- under the type, a choice as a switch, a number as a dial. The preview runs
  -- the state's glow + animation.
  Title(f, 0, 293, "Custom Animations", 14)
  local states = {}
  for _, k in ipairs(ANIM_ORDER) do
    for _, tr in ipairs(ANIM_TRIGGERS) do if tr[1] == k then states[#states + 1] = { k, tr[2] } end end
  end
  local row1, row2 = {}, {}
  for i, s in ipairs(states) do if i <= 4 then row1[#row1 + 1] = s else row2[#row2 + 1] = s end end
  local function getS() return animTrigger end
  local function setS(v) animTrigger = v; refreshPage(pg); C:SetPreviewAnim(animTrigger) end
  local st1 = UI.gSwitch(f, row1, getS, setS, { w = 360 }); st1:SetPoint("TOPLEFT", 0, -329)
  local st2 = UI.gSwitch(f, row2, getS, setS, { w = 360 }); st2:SetPoint("TOPLEFT", 0, -345)
  local function apply() C:SetPreviewAnim(animTrigger); if GB.Anims then GB.Anims:Invalidate(animTrigger) end end
  local function currentSel()
    local t = GB.db and GB.db.triggers and GB.db.triggers[animTrigger]
    local found = "none"
    if t and t.anims and GB.Anims then
      GB.Anims:Each(function(mod) if t.anims[mod.id] and t.anims[mod.id].enabled then found = mod.id end end)
    end
    return found
  end
  local blocks = {}
  local function selectAnim(v)
    local t = GB.db and GB.db.triggers and GB.db.triggers[animTrigger]
    if not t then return end
    t.anims = t.anims or {}
    if GB.Anims then GB.Anims:Each(function(mod)
      if mod.id == v then local d = animEnsure(mod.id); if d then d.enabled = true end
      elseif t.anims[mod.id] then t.anims[mod.id].enabled = false end
    end) end
    refreshPage(pg); apply()
  end
  add(pg, Drop(f, C1, 381, 170, "Animation Type",
    function()
      local o = { { "none", "None" } }
      if GB.Anims then GB.Anims:Each(function(mod) o[#o + 1] = { mod.id, mod.label } end) end
      return o
    end, currentSel, selectAnim))
  -- With None, the color spot is there and dimmed.
  local noneColor = Color(f, C2, 381, 170, "Animation Effect Color", { get = function() return nil end, set = function() end })
  if GB.Anims then
    GB.Anims:Each(function(mod)
      local blk = CreateFrame("Frame", nil, f); blk:SetPoint("TOPLEFT", 0, 0); blk:SetSize(360, 10); blk:Hide()
      local ctrls, slot = {}, 0
      local hasColor = false
      local function place() local x = (slot % 2 == 0) and C1 or C2; local y = 424 + math.floor(slot / 2) * 43; slot = slot + 1; return x, y end
      for _, param in ipairs(mod.params) do
        local c
        if param.kind == "color" and not hasColor then
          hasColor = true
          c = Color(blk, C2, 381, 170, "Animation Effect Color", { label = "Bars › Animation › " .. param.label, title = param.label,
            get = function() return animGet(mod.id, param.key) end,
            set = function(v) animSet(mod.id, param.key, v); apply() end })
        elseif param.kind == "choice" then
          local ch = {}
          for _, o in ipairs(param.choices) do ch[#ch + 1] = { o[1], tostring(o[2]) } end
          local x, y = place()
          c = Switch(blk, x, y, 170, param.label, ch, function() return animGet(mod.id, param.key) end,
            function(v) animSet(mod.id, param.key, v); apply() end)
        elseif param.kind == "range" then
          local x, y = place()
          c = Dial(blk, x, y, 170, { label = param.label, min = param.min, max = param.max, step = param.step,
            get = function() return animGet(mod.id, param.key) end,
            set = function(v) animSet(mod.id, param.key, v); apply() end, fmt = animFmt(param) })
        elseif param.kind == "bispeed" then
          local x, y = place()
          local minRev = param.minRev or 0.8
          local negLabel, posLabel = param.neg or "CCW", param.pos or "CW"
          c = Dial(blk, x, y, 170, { label = param.label, min = -1, max = 1, step = 0.05,
            get = function() return animGet(mod.id, param.key) or 0 end,
            set = function(v) animSet(mod.id, param.key, v); apply() end,
            fmt = function(v)
              if math.abs(v) < 0.04 then return "still" end
              return string.format("%s %.1fs", v > 0 and posLabel or negLabel, minRev / math.abs(v))
            end })
          attachTip(c.strip, param.label, ("Left of the middle runs %s, right runs %s; further out is faster. The middle is still."):format(negLabel, posLabel))
        end
        if c then ctrls[#ctrls + 1] = c end
      end
      if not hasColor then
        local c = Color(blk, C2, 381, 170, "Animation Effect Color", { get = function() return nil end, set = function() end })
        c:setEnabled(false)
      end
      blocks[mod.id] = { frame = blk, ctrls = ctrls, h = 424 + math.ceil(slot / 2) * 43 - 10 }
    end)
  end
  pg.after = function()
    st1:refresh(); st2:refresh()
    local cur = currentSel()
    noneColor:SetShown(cur == "none"); noneColor:setEnabled(false)
    local h = 414
    for id, blk in pairs(blocks) do
      blk.frame:SetShown(id == cur)
      if id == cur then
        h = math.max(h, blk.h)
        for _, c in ipairs(blk.ctrls) do c:refresh(); c:setEnabled(true); if c._label then c._label:SetAlpha(1) end end
      end
    end
    if math.abs((f:GetHeight() or 0) - h) > 0.5 then f:SetHeight(h); if GloomsHub.RefreshWindows then GloomsHub:RefreshWindows("bars") end end
  end
  pg.onShow = function() C:SetPreviewAnim(animTrigger) end
  return f
end

-- ---------------------------------------------------------------------------
-- SECTION · CASTS & CHANNELS (the mock's Frame 562, 119 tall + Complete Color)
-- ---------------------------------------------------------------------------
local function buildCastsPage(parent)
  local pg = Section("casts", parent, 162); local f = pg.frame
  local function showCast() C:SetPreviewState("cast") end   -- fill edits animate on the Cast chip
  add(pg, Color(f, C1, 0, 170, "Cast Fill Color", { label = "Bars › Cast fill color", title = "Cast Fill Color",
    get = function() return GB.db and GB.db.castFillColor end,
    set = function(c) if GB.db then GB.db.castFillColor = c end; showCast() end }))
  add(pg, Dial(f, C2, 0, 170, { label = "Opacity", min = 0, max = 100, step = 5, unit = "%",
    get = function() return math.floor(((GB.db and GB.db.castFillAlpha) or 0.55) * 100 + 0.5) end,
    set = function(v) if GB.db then GB.db.castFillAlpha = v / 100 end; showCast() end }))
  add(pg, Switch(f, 0, 43, 360, "Cast Fill Direction", DIRS,
    function() return (GB.db and GB.db.castDrainDir) or "up" end,
    function(d) if GB.db then GB.db.castDrainDir = d end; showCast() end))
  add(pg, Color(f, C1, 86, 170, "Interrupted Cast Color", { label = "Bars › Cast interrupt color", title = "Cast Interrupt Color",
    get = function() return GB.db and GB.db.castInterruptColor end,
    set = function(c) if GB.db then GB.db.castInterruptColor = c end end }))
  local sp = add(pg, Dial(f, C2, 86, 170, { label = "Interrupt Animation Speed", min = 0.2, max = 2, step = 0.1, unit = "x",
    get = function() return (GB.db and GB.db.castInterruptSpeed) or 0.6 end,
    set = function(v) if GB.db then GB.db.castInterruptSpeed = v end end }))
  attachTip(sp.strip, "Interrupt burst speed", "Changes apply on your next cast. Below 1x slows the interrupt burst.")
  -- ★ Not in the mock (2026-09-27), kept so the setting is not lost: the flash
  -- when a cast completes. Under the rest, in the first column.
  add(pg, Color(f, C1, 129, 170, "Complete Color", { label = "Bars › Cast complete color", title = "Cast Complete Color",
    get = function() return GB.db and GB.db.castCompleteColor end,
    set = function(c) if GB.db then GB.db.castCompleteColor = c end end }))
  pg.onShow = function() C:SetPreviewState("cast") end
  return f
end

-- ---------------------------------------------------------------------------
-- SECTION · COOLDOWNS & AVAILABILITY (the mock's Frame 562, 205 tall)
-- ---------------------------------------------------------------------------
local function buildCooldownsPage(parent)
  local pg = Section("cooldowns", parent, 205); local f = pg.frame
  local function showCD() C:SetPreviewState("cooldown") end
  add(pg, Color(f, C1, 0, 170, "Cooldown Sweep Color", { label = "Bars › Sweep color",
    get = function() return GB.db and GB.db.swipeColor end,
    set = function(c) if GB.Skin then GB.Skin:SetSwipeColor(c) end; showCD() end }))
  add(pg, Dial(f, C2, 0, 170, { label = "Sweep Opacity", min = 0, max = 100, step = 5, unit = "%",
    get = function() return math.floor(((GB.db and GB.db.swipeAlpha) or 0.8) * 100 + 0.5) end,
    set = function(v) if GB.Skin then GB.Skin:SetSwipeAlpha(v / 100) end; showCD() end }))
  local fl = add(pg, Switch(f, C1, 43, 170, "Cast Finish Flash", OFFON,
    function() return (GB.db and GB.db.finishFlash) and true or false end,
    function(v) if GB.Skin then GB.Skin:SetFinishFlash(v) end; refreshPage(pg); C:PlayPreviewFlash() end))
  attachTip(fl, "Finish flash", "A shape-matched burst when a cooldown completes.")
  add(pg, Color(f, C2, 43, 170, "Finish Flash Color", { label = "Bars › Finish flash color",
    get = function() return GB.db and GB.db.finishFlashColor end,
    set = function(c) if GB.Skin then GB.Skin:SetFinishFlashColor(c) end; C:PlayPreviewFlash() end }),
    function() return GB.db and GB.db.finishFlash and true or false end)
  add(pg, Switch(f, C1, 86, 170, "Desaturate Unusable Spells", OFFON,
    function() return (GB.db and GB.db.availDesaturate) and true or false end,
    function(v) if GB.Skin then GB.Skin:SetAvailDesaturate(v) end end))
  add(pg, Color(f, C1, 129, 170, "Unusable Tint", { label = "Bars › Unusable tint",
    get = function() return GB.db and GB.db.availUnusable end,
    set = function(c) if GB.Skin then GB.Skin:SetAvailUnusable(c) end end }))
  add(pg, Color(f, C2, 129, 170, "Out of Mana Tint", { label = "Bars › Out-of-mana tint",
    get = function() return GB.db and GB.db.availOOM end,
    set = function(c) if GB.Skin then GB.Skin:SetAvailOOM(c) end end }))
  local rt = add(pg, Switch(f, C1, 172, 170, "Tint Out of Range", OFFON,
    function() return (GB.db and GB.db.rangeTint) and true or false end,
    function(v) if GB.Skin then GB.Skin:SetRangeTint(v) end; refreshPage(pg) end))
  attachTip(rt, "Tint out of range", "Tints the icon and recolors the keybind text while the target is out of range.")
  add(pg, Color(f, C2, 172, 170, "Out of Range Tint", { label = "Bars › Out-of-range color",
    get = function() return GB.db and GB.db.rangeColor end,
    set = function(c) if GB.Skin then GB.Skin:SetRangeColor(c) end end }),
    function() return GB.db and GB.db.rangeTint and true or false end)
  pg.onShow = function() C:SetPreviewState("cooldown") end
  return f
end

-- ---------------------------------------------------------------------------
-- SECTION · BAR VISIBILITY, LAYOUT & PRESETS (the mock's Frame 570, 427 tall)
-- Gloom's Bars owns bar geometry PER BAR, opt-in; Edit Mode keeps any bar left
-- off. Engine: Layout.lua (containers only — never the secure buttons;
-- out-of-combat with a combat queue). Settings live per bar in the PROFILE
-- (barLayout[barKey]), beside the preset assignments.
-- ---------------------------------------------------------------------------
local function buildLayoutPage(parent)
  local pg = Section("layout", parent, 427); local f = pg.frame

  -- EMPTY SLOTS (GLOBAL) — every bar; the per-bar Empty Icons below overrides it.
  local function emptyMode() return (GB.db and GB.db.emptySlots) or "normal" end
  local es = add(pg, Switch(f, C1, 0, 170, ("Empty Slots |cff%s(Global)|r"):format(LILAC.hex), { { "normal", "Normal" }, { "dim", "Dim" }, { "hide", "Hidden" } },
    emptyMode, function(v)
      if GB.Skin and GB.Skin.SetEmptySlots then GB.Skin:SetEmptySlots(v) elseif GB.db then GB.db.emptySlots = v end
      refreshPage(pg)
    end))
  attachTip(es, "Empty slots", "Every bar: slots with no action fade or vanish. They come back on their own while you drag a spell, so drop targets stay visible. A bar's own Empty Icons overrides this.")
  add(pg, Dial(f, C2, 0, 170, { label = ("Empty Slot Opacity |cff%s(Global)|r"):format(LILAC.hex), min = 5, max = 90, step = 5, unit = "%",
    get = function() return math.floor(((GB.db and GB.db.emptySlotAlpha) or 0.35) * 100 + 0.5) end,
    set = function(v)
      v = v / 100
      if GB.Skin and GB.Skin.SetEmptySlotAlpha then GB.Skin:SetEmptySlotAlpha(v) elseif GB.db then GB.db.emptySlotAlpha = v end
    end }), function() return emptyMode() == "dim" end)

  -- BAR LAYOUT — the bar being edited, a LIME switch of its own (the mock's
  -- "Editing Layout for Bar:"): 1 … 8 share what PET and STANCE leave.
  local selBar = GB.BARS[1].buttonPrefix
  local function data() return barLayoutData(selBar) end
  local function apply() if GB.Layout then GB.Layout:Reassert(selBar) end end
  local function barShort()
    for _, bar in ipairs(GB.BARS) do if bar.buttonPrefix == selBar then
      return bar.key:match("^bar(%d+)$") and ("Bar " .. bar.key:match("^bar(%d+)$")) or bar.label:gsub(" Bar$", "")
    end end
    return ""
  end
  Label(f, 0, 53, "Editing Layout for Bar:")
  local barChoices, widths, nums, fixed = {}, {}, 0, 0
  for _, bar in ipairs(GB.BARS) do
    local n = bar.key:match("^bar(%d+)$")
    barChoices[#barChoices + 1] = { bar.buttonPrefix, n or (bar.label:gsub(" Bar$", ""):upper()) }
    if n then nums = nums + 1 end
  end
  for _, ch in ipairs(barChoices) do
    if not tonumber(ch[2]) then
      local w = (ch[2] == "PET") and 50 or 69
      widths[#widths + 1] = w; fixed = fixed + w
    else widths[#widths + 1] = false end
  end
  local each = (nums > 0) and math.floor((360 - fixed) / nums) or 30
  local spare = 360 - fixed - each * nums
  for i, w in ipairs(widths) do
    if not w then widths[i] = each + ((spare > 0) and 1 or 0); spare = spare - 1 end
  end
  local barSw = UI.gSwitch(f, barChoices, function() return selBar end, function(v) selBar = v; refreshPage(pg) end,
    { widths = widths, h = 15, accent = LIME })
  barSw:SetPoint("TOPLEFT", 0, -70.5)
  for i, seg in ipairs(barSw.segs) do
    local bar = GB.BARS[i]
    seg:HookScript("OnEnter", function() if GB.Skin and GB.Skin.PingBar then GB.Skin:PingBar(bar.buttonPrefix, true) end end)
    seg:HookScript("OnLeave", function() if GB.Skin and GB.Skin.PingBar then GB.Skin:PingBar(bar.buttonPrefix, false) end end)
    attachTip(seg, bar.label, "Select this bar to edit its layout. Hovering pulses it on screen.")
  end

  local own = add(pg, Switch(f, C1, 106, 170, "Layout Control", OFFON, function() return layoutOn() and true or false end,
    function(v)
      local prof = GB:ActiveProfile(); if prof then prof.layoutEnabled = v and true or false end
      if GB.Layout then GB.Layout:ApplyAll() end
      if GB.Skin and GB.Skin.RefreshEmptySlots then GB.Skin:RefreshEmptySlots() end
      refreshPage(pg)
    end))
  attachTip(own, "Layout control", "On: this addon arranges ALL the bars, each with its settings here. Off: Edit Mode arranges everything, exactly as normal.")
  -- The per-bar labels name the bar: "Icon Size (Bar 1)" — the bar's name in lime.
  local perBar = {}
  local function perLabel(ctrl, name) perBar[#perBar + 1] = { ctrl._label or ctrl.label, name }; return ctrl end
  local function presetOptions()
    local prof = GB:ActiveProfile(); local o = {}
    for name in pairs((prof and prof.presets) or {}) do o[#o + 1] = { name, name } end
    table.sort(o, function(a2, b2) return a2[2] < b2[2] end)
    return o
  end
  local sp = add(pg, perLabel(Drop(f, C2, 106, 170, "Style Preset", presetOptions,
    function() local prof = GB:ActiveProfile(); return prof and prof.bars and prof.bars[selBar] end,
    function(v) GB:AssignBarPreset(selBar, v); refreshPage(pg) end), "Style Preset"))
  attachTip(sp, "Style preset", "Which whole-look preset the selected bar wears. The preset being edited renders live as you tweak it; any other preset shows its saved look.")
  local VIS = { { "default", "Default" }, { "show", "Always Visible" }, { "combat", "In Combat" }, { "nocombat", "Out of Combat" }, { "hide", "Hidden" } }
  local vis = add(pg, perLabel(Drop(f, C1, 149, 170, "Visibility Rule", VIS,
    function() local c = data(); return (c and c.vis) or "default" end,
    function(v) local c = ensureBarLayout(selBar); c.vis = (v ~= "default") and v or nil; apply(); refreshPage(pg) end), "Visibility Rule"), layoutOn)
  attachTip(vis, "Visibility", "Default follows Blizzard's rules (Edit Mode, mouseover, vehicles). Always Visible shows the bar even if Edit Mode has it disabled. In / Out of Combat show it only then. Hidden removes it. Game-driven hides always win.")
  -- EMPTY ICONS — this bar's OVERRIDE of the global Empty Slots: GLOBAL follows
  -- it, SHOW keeps this bar's empties visible, HIDE removes them (Skin.lua's
  -- emptyOverride). nil / true / false in the profile.
  local ei = add(pg, perLabel(Switch(f, C2, 149, 170, "Empty Icons", { { "global", "Global" }, { "show", "Show" }, { "hide", "Hide" } },
    function() local c = data(); local v = c and c.showEmpty; return (v == false and "hide") or (v == true and "show") or "global" end,
    function(v)
      local c = ensureBarLayout(selBar)
      if v == "hide" then c.showEmpty = false elseif v == "show" then c.showEmpty = true else c.showEmpty = nil end
      if GB.Skin and GB.Skin.RefreshEmptySlots then GB.Skin:RefreshEmptySlots() end
      apply()
    end), "Empty Icons"), layoutOn)
  attachTip(ei, "Empty icons", "This bar's override of Empty Slots (Global). Global: follow it. Show: keep this bar's empty slots visible. Hide: they disappear; their spot in the grid stays reserved, and they come back while you drag a spell.")

  local sz = add(pg, perLabel(Dial(f, C1, 192, 170, { label = "Icon Size", min = 24, max = 64, unit = "px",
    get = function() local c = data(); return (c and c.size) or 45 end,
    set = function(v) local c = ensureBarLayout(selBar); c.size = v; apply() end }), "Icon Size"), layoutOn)
  attachTip(sz.strip, "Icon size", "Scales the WHOLE button proportionally — icon, text, glows — like Edit Mode's size setting. How the icon sits within its button is Icon Scale, saved in the preset.")
  add(pg, perLabel(Dial(f, C2, 192, 170, { label = "Icon Gap", min = -32, max = 64, unit = "px",
    get = function() local c = data(); return (c and c.gap) or 4 end,
    set = function(v) local c = ensureBarLayout(selBar); c.gap = v; apply() end }), "Icon Gap"), layoutOn)
  add(pg, perLabel(Dial(f, C1, 235, 170, { label = "Total Icons", min = 1, max = 12,
    get = function() local c = data(); return (c and c.count) or 12 end,
    set = function(v) local c = ensureBarLayout(selBar); c.count = v; apply() end }), "Total Icons"), layoutOn)
  add(pg, perLabel(Dial(f, C2, 235, 170, { label = "Rows", min = 1, max = 6,
    get = function() local c = data(); return (c and c.rows) or 1 end,
    set = function(v) local c = ensureBarLayout(selBar); c.rows = v; apply(); refreshPage(pg) end }), "Rows"), layoutOn)
  add(pg, perLabel(Dial(f, C1, 278, 170, { label = "Gap Between Rows", min = -32, max = 64, unit = "px",
    get = function() local c = data(); return (c and (c.gapCross or c.gap)) or 4 end,
    set = function(v) local c = ensureBarLayout(selBar); c.gapCross = v; apply() end }), "Gap Between Rows"),
    function() local c = data(); return layoutOn() and ((c and c.rows or 1) > 1) end)
  add(pg, perLabel(Switch(f, C2, 278, 170, "Orientation", { { true, "Horizontal" }, { false, "Vertical" } },
    function() local c = data(); return not c or c.horizontal ~= false end,
    function(v) local c = ensureBarLayout(selBar); c.horizontal = v; apply() end), "Orientation"), layoutOn)

  -- The master switch, the preset highlight, and copying a layout (three columns).
  local en = add(pg, Switch(f, T1, 331, 107, "GloomBars Addon", OFFON,
    function() return (GB.Skin and GB.Skin.enabled) and true or false end,
    function(v) if not GB.Skin then return end; if v then GB.Skin:Enable() else GB.Skin:Disable() end end))
  attachTip(en, "Gloom's Bars", "The master switch: Off returns every bar to Blizzard's own look and layout.")
  local hl = add(pg, Switch(f, T2, 331, 106, "Preset Highlight", OFFON,
    function() return (GB.Skin and GB.Skin.SetPresetHighlight and GB.Skin:SetPresetHighlight()) and true or false end,
    function(v) if GB.Skin and GB.Skin.SetPresetHighlight then GB.Skin:SetPresetHighlight(v) end end))
  attachTip(hl, "Highlight bars using this preset", "Puts a translucent block behind every bar that wears the preset you're editing, so it's clear which bars your changes affect. Stays on with this window closed and through combat. Off again when you log in.")
  local cp = add(pg, Drop(f, T3, 331, 107, "Copy Styles From",
    function()
      local o = {}
      for _, bar in ipairs(GB.BARS) do if bar.buttonPrefix ~= selBar then o[#o + 1] = { bar.buttonPrefix, bar.label } end end
      return o
    end,
    function() return nil end,
    function(v)
      local src = barLayoutData(v); if not src then return end
      local dst = ensureBarLayout(selBar); if not dst then return end
      dst.size, dst.gap, dst.rows = src.size, src.gap, src.rows
      dst.gapCross, dst.horizontal = src.gapCross, src.horizontal
      apply(); refreshPage(pg)
    end), layoutOn)
  attachTip(cp, "Copy layout", "Copies the picked bar's arrangement — button size, gap, rows, row gap, orientation — onto the selected bar. Its position, visibility, button count and empty-slot settings stay as they are.")

  -- The buttons: MOVE BARS · QUICK KEYBIND · RESET POSITIONS (the owner's labels,
  -- 2026-09-25), stretched to the three columns. Move names the NEXT action
  -- (Move ↔ Lock).
  local mv = add(pg, UI.gButton(f, "Move Bars", { w = 107, h = 16, onClick = function()
    if GB.Layout then GB.Layout:SetMoveMode(not GB.Layout:MoveModeOn()) end
  end }), layoutOn)
  mv:SetPoint("TOPLEFT", T1, -394)
  attachTip(mv, "Move Bars", "Drag any bar's overlay to reposition it. Click an overlay to select it, then nudge with the arrow keys — hold Shift for 10px steps. ESC or this button exits. Out of combat only.")
  local qk = UI.gButton(f, "Quick Keybind", { w = 106, h = 16, onClick = openQuickKeybind })
  qk:SetPoint("TOPLEFT", T2, -394)
  attachTip(qk, "Quick Keybind", "Opens Blizzard's Quick Keybind mode: hover any action button and press a key to bind it, ESC when done. Out of combat only.")
  local rs = add(pg, UI.gButton(f, "Reset Positions", { w = 107, h = 16, onClick = function() if GB.Layout then GB.Layout:ResetPosition(selBar) end end }), layoutOn)
  rs:SetPoint("TOPLEFT", T3, -394)
  attachTip(rs, "Reset Positions", "Returns the selected bar to wherever Edit Mode places it.")

  pg.after = function()
    barSw:refresh()
    local short = barShort()
    for _, e in ipairs(perBar) do
      if e[1] then e[1]:SetText(("%s |cff%s(%s)|r"):format(e[2], LIME.hex, short)) end
    end
    local moving = (GB.Layout and GB.Layout.MoveModeOn and GB.Layout:MoveModeOn()) or false
    mv:SetLabel(moving and "Lock Bars" or "Move Bars"); mv:SetSelected(moving)
  end
  return f
end

-- ---------------------------------------------------------------------------
-- THE TAB (the mock's Frame 519): "Editing Preset:" in lime and the preset's
-- name (Sansation 10) at 20,8 — click the name for the list of presets; right-
-- click it for Rename · Duplicate · Delete. New and Delete at the right, 6
-- apart, ending 20 in. Every control in every section edits this preset, and it
-- saves as you edit. One tab per window (the settings window's and each
-- pop-out's), all kept in step.
-- ---------------------------------------------------------------------------
local presetTabs = {}
local function collision() GB.msg("a preset with that name already exists.") end
local function newPreset()
  UI.nameDialog("New preset", "", function(name)
    if not name or name == "" then return end
    if not GB:CreatePreset(name) then return collision() end
    C:Refresh()
  end)
end
local function duplicatePreset()
  UI.nameDialog("Duplicate preset", editName() .. " copy", function(name)
    if not name or name == "" then return end
    if not GB:CreatePreset(name) then return collision() end
    C:Refresh()
  end)
end
local function renamePreset()
  UI.nameDialog("Rename preset", editName(), function(name)
    if not name or name == "" then return end
    if not GB:RenamePreset(editName(), name) then return collision() end
    C:Refresh()
  end)
end
local function deletePreset()
  UI.confirm(("Delete the preset \"%s\"? Bars assigned to it fall back to another preset."):format(editName()), function()
    if not GB:DeletePreset(editName()) then GB.msg("can't delete the last preset.") end
    C:Refresh()
  end, "Delete", "Delete preset")
end
local function buildTab(tab)
  local t = {}
  local lead = UI.newText(tab, FONT.sa, 10, LIME, "LEFT"); lead:SetPoint("TOPLEFT", 20, -9)
  lead:SetText("Editing Preset: ")
  local nameBtn = CreateFrame("Button", nil, tab); nameBtn:SetHeight(14)
  nameBtn:SetPoint("LEFT", lead, "RIGHT", 0, 0)
  nameBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  local name = UI.newText(nameBtn, FONT.sa, 10, COLOR.paper, "LEFT"); name:SetPoint("LEFT", 0, 0); name:SetWordWrap(false)
  nameBtn:SetScript("OnEnter", function() name:SetTextColor(LILAC.r, LILAC.g, LILAC.b) end)
  nameBtn:SetScript("OnLeave", function() name:SetTextColor(1, 1, 1) end)
  nameBtn:SetScript("OnClick", function(self, button)
    if button == "RightButton" then
      UI.gList(self, {
        { value = "rename", label = "Rename" },
        { value = "dup", label = "Duplicate Preset" },
        { value = "delete", label = "Delete Preset", danger = true, divider = true },
      }, nil, function(v)
        if v == "rename" then renamePreset() elseif v == "dup" then duplicatePreset() else deletePreset() end
      end, { cursor = true, minW = 140 })
      return
    end
    local prof = GB:ActiveProfile(); local o = {}
    for _, n in ipairs(sortedNames(prof and prof.presets)) do o[#o + 1] = { value = n, label = n } end
    UI.gList(self, o, editName(), function(v) GB:SwitchPreset(v); C:Refresh() end, { minW = 160 })
  end)
  attachTip(nameBtn, "Preset being edited", "The look being edited — every control edits this preset, and it saves as you edit. Click for the list of presets; right-click to rename, duplicate or delete this one.")
  local del = UI.gButton(tab, "Delete", { danger = true, h = 16, pad = 10, onClick = deletePreset })
  del:SetPoint("TOPRIGHT", tab, "TOPRIGHT", -20, -6)
  attachTip(del, "Delete preset", "Deletes this preset (you'll be asked to confirm). The last preset can't be deleted.")
  local new = UI.gButton(tab, "New", { h = 16, pad = 10, onClick = newPreset })
  new:SetPoint("RIGHT", del, "LEFT", -6, 0)
  attachTip(new, "New preset", "Creates a preset starting as a copy of the current look, and makes it the one being edited.")
  function t:refresh()
    name:SetText(editName() or "")
    nameBtn:SetWidth(math.max(10, math.min(180, name:GetStringWidth())))
  end
  presetTabs[#presetTabs + 1] = t
  return t
end

-- ---------------------------------------------------------------------------
-- THE PREVIEW WINDOW (the mock's "gloomBars, preview window", 240 × 420): under
-- the wordmark (from y 52) the 13 state buttons (three to a row, then two; 15
-- tall, 19 apart, 4 between), the live construction centered 218 down, and the state's
-- name (Sansation Bold 12), description (10) and "Styled in:" links (each
-- opens its section).
-- ---------------------------------------------------------------------------
local PREVIEW_ROWS = { 3, 3, 3, 2, 2 }
local function buildPreviewPane(pane)
  previewChips = {}
  local i, y = 0, 52
  for _, n in ipairs(PREVIEW_ROWS) do
    local w = (200 - (n - 1) * 4) / n
    for col = 1, n do
      i = i + 1
      local st = PREVIEW_STATES[i]
      if not st then break end
      local chip = UI.gButton(pane, st[2], { w = w, size = 10, onClick = function() C:SetPreviewState(st[1]) end })
      chip:SetPoint("TOPLEFT", 20 + (col - 1) * (w + 4), -y)
      function chip:SetActive(on) self:SetSelected(on) end
      previewChips[st[1]] = chip
    end
    y = y + 19
  end

  -- Sample construction. The icon's long side is PREVIEW_BASE; the whole
  -- construction (icon + plate) is centered at PREVIEW_CENTER_Y and RefreshPreview
  -- re-anchors it as the extension grows, so nothing floats.
  local frame = CreateFrame("Frame", nil, pane); frame:SetSize(PREVIEW_BASE, PREVIEW_BASE)
  frame:SetPoint("CENTER", pane, "TOP", 0, PREVIEW_CENTER_Y)
  previewFrame = frame
  -- Live pulse for the pulsing chips (proc/flash): breathe the multi-part glow's
  -- alpha about its peak at the current Pulse-speed, mirroring Glows.lua's driver.
  frame:SetScript("OnUpdate", function(_, dt)
    if not previewPulsing then return end
    previewPulsePhase = previewPulsePhase + dt * math.max(0.1, (GB.db and GB.db.glowPulseSpeed) or 1)
    local a = previewPulsePeak * (PREVIEW_PULSE_DEPTH + (1 - PREVIEW_PULSE_DEPTH) * (0.5 + 0.5 * math.cos(previewPulsePhase * 5.7)))
    if previewOuter:IsShown() then previewOuter:SetAlpha(a) end
    if previewInner:IsShown() then previewInner:SetAlpha(a) end
  end)
  previewGlow = frame:CreateTexture(nil, "BACKGROUND"); previewGlow:SetPoint("TOPLEFT", -11, 11); previewGlow:SetPoint("BOTTOMRIGHT", 11, -11)
  previewGlow:SetBlendMode("ADD"); previewGlow:SetVertexColor(1, 0.77, 0.30); previewGlow:Hide()
  -- Multi-part shaped glow (hand shapes): outer bloom UNDER the icon, inner rim OVER
  -- the plate — mirrors the bars (Glows.lua).
  previewOuter = frame:CreateTexture(nil, "BACKGROUND", nil, -1); previewOuter:SetBlendMode("BLEND"); previewOuter:Hide()
  previewInner = frame:CreateTexture(nil, "OVERLAY"); previewInner:SetBlendMode("BLEND"); previewInner:Hide()
  previewIcon = frame:CreateTexture(nil, "ARTWORK"); previewIcon:SetAllPoints()
  previewCD = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate"); previewCD:SetAllPoints(previewIcon)
  previewCD:SetDrawEdge(false); previewCD:SetDrawBling(false); previewCD:Hide()
  -- No countdown number on the preview sweep: it ignores the Text→Countdown
  -- styling and its size/position would be wrong anyway (the owner).
  if previewCD.SetHideCountdownNumbers then previewCD:SetHideCountdownNumbers(true) end
  previewRing = frame:CreateTexture(nil, "OVERLAY"); previewRing:SetPoint("TOPLEFT", -3, 3); previewRing:SetPoint("BOTTOMRIGHT", 3, -3)
  previewRing:SetBlendMode("ADD"); previewRing:Hide()
  previewBorder = frame:CreateTexture(nil, "BACKGROUND", nil, -2)   -- behind the icon; peeks out as the border
  previewBorder:SetTexture("Interface\\Buttons\\WHITE8X8"); previewBorder:Hide()
  -- Finish-flash preview: an expanding shape-glow burst that fades out, mirroring
  -- the engine's setupFinishFlash.
  previewFlashFrame = CreateFrame("Frame", nil, frame)
  previewFlashFrame:SetFrameLevel(frame:GetFrameLevel() + 5); previewFlashFrame:SetAlpha(0)
  previewFlash = previewFlashFrame:CreateTexture(nil, "OVERLAY"); previewFlash:SetBlendMode("ADD")
  previewFlash:SetAllPoints(previewFlashFrame)
  previewFlashAnim = previewFlashFrame:CreateAnimationGroup()
  local fa = previewFlashAnim:CreateAnimation("Alpha")
  fa:SetFromAlpha(1); fa:SetToAlpha(0); fa:SetDuration(0.45); fa:SetSmoothing("OUT")
  local fsc = previewFlashAnim:CreateAnimation("Scale")
  fsc:SetScaleFrom(0.85, 0.85); fsc:SetScaleTo(1.5, 1.5); fsc:SetOrigin("CENTER", 0, 0)
  fsc:SetDuration(0.45); fsc:SetSmoothing("OUT")
  if previewFlashAnim.SetToFinalAlpha then previewFlashAnim:SetToFinalAlpha(true) end
  previewFlashAnim:SetScript("OnFinished", function() previewFlashFrame:SetAlpha(0) end)

  -- Cast/channel fill preview: a looping fake drain mirroring the bars' fill
  -- (cast fills up, channel drains; color / alpha / direction from the same db
  -- fields the engine reads).
  previewCastFillFrame = CreateFrame("Frame", nil, frame)
  previewCastFillFrame:SetFrameLevel(frame:GetFrameLevel() + 4)
  previewCastFillFrame.tex = previewCastFillFrame:CreateTexture(nil, "OVERLAY")
  previewCastFillFrame.tex:SetTexture("Interface\\Buttons\\WHITE8X8")   -- maskable (masks don't clip SetColorTexture)
  previewCastFillFrame:SetScript("OnUpdate", function(f)
    local p = (GetTime() % 2.4) / 2.4      -- a looping fake 2.4s cast
    local frac = f.channel and (1 - p) or p
    local tex, W, H = f.tex, f:GetWidth(), f:GetHeight()
    local dir = (GB.db and GB.db.castDrainDir) or "up"
    tex:ClearAllPoints()
    if dir == "up" then tex:SetPoint("BOTTOMLEFT", f); tex:SetPoint("BOTTOMRIGHT", f); tex:SetHeight(math.max(0.01, H * frac))
    elseif dir == "down" then tex:SetPoint("TOPLEFT", f); tex:SetPoint("TOPRIGHT", f); tex:SetHeight(math.max(0.01, H * frac))
    elseif dir == "left" then tex:SetPoint("TOPRIGHT", f); tex:SetPoint("BOTTOMRIGHT", f); tex:SetWidth(math.max(0.01, W * frac))
    else tex:SetPoint("TOPLEFT", f); tex:SetPoint("BOTTOMLEFT", f); tex:SetWidth(math.max(0.01, W * frac)) end
  end)
  previewCastFillFrame:Hide()

  -- The caption (the mock's: the state in Sansation Bold 12, its description in
  -- 10, a blank line, "Styled in:" with each section's name a lilac link).
  local head = newText(pane, FONT.saB, 12, COLOR.paper, "LEFT")
  head:SetJustifyH("LEFT"); head:SetText("")
  head:SetPoint("TOPLEFT", pane, "TOPLEFT", 20, -PREVIEW_CAPTION_Y); head:SetPoint("TOPRIGHT", pane, "TOPRIGHT", -20, -PREVIEW_CAPTION_Y)
  previewCaptionHead = head
  local cap = newText(pane, FONT.sa, 10, COLOR.paper, "LEFT")
  cap:SetJustifyH("LEFT"); cap:SetText(PREVIEW_CAPTION_DEFAULT)
  cap:SetPoint("TOPLEFT", head, "BOTTOMLEFT", 0, -1); cap:SetPoint("TOPRIGHT", head, "BOTTOMRIGHT", 0, -1)
  previewCaption = cap
  local capFrame = CreateFrame("Frame", nil, pane)
  capFrame:SetHyperlinksEnabled(true)
  capFrame:EnableMouse(true)
  capFrame:SetScript("OnHyperlinkClick", function(_, link)
    local title = link and link:match("^gbsec:(.+)$")
    if not title then return end
    local st = previewState
    C:OpenSection(title)
    C:SetPreviewState(st)   -- a section may take over the preview on show; restore the clicked state
  end)
  local links = newText(capFrame, FONT.sa, 10, COLOR.paper, "LEFT")
  links:SetJustifyH("LEFT"); links:SetSpacing(2); links:SetText("")
  links:SetPoint("TOPLEFT", cap, "BOTTOMLEFT", 0, -12); links:SetPoint("TOPRIGHT", cap, "BOTTOMRIGHT", 0, -12)
  previewCaptionLinks = links
  capFrame:SetAllPoints(links)

  C:RefreshPreview()
  C:SetPreviewState("idle")
end

-- ===========================================================================
-- Refreshing
-- ===========================================================================
function P.show(id)
  for _, pg in pairs(P.pages) do if pg.frame:IsVisible() then refreshPage(pg) end end
end

function C:Refresh()
  if not container then return end
  for _, t in ipairs(presetTabs) do t:refresh() end
  -- Re-point the preset-focus highlight at the newly-selected edit preset's bars
  -- (no-op if the highlight is off).
  if GB.Skin and GB.Skin.RefreshPresetHighlight then GB.Skin:RefreshPresetHighlight() end
  for _, pg in pairs(P.pages) do refreshPage(pg) end
  C:RefreshPreview()
  C:SetPreviewState(previewState)
end

-- C:Toggle() is GONE (Phase C, locked decision: hard dependency, no second
-- window path). /gb's config branch and the minimap button both route through
-- GloomsHub:ToggleWindow("bars") — the Hub owns open/close/switch semantics.

-- Mount the Bars windows (CONTRACTS §2, the two-window block).
GloomsHub:RegisterTab{
  id       = "bars",
  title    = "Bars",
  order    = 20,
  wordmark = "BARS",
  product  = "GloomBars",
  windows  = true,
  profile  = PROFILE_API,
  selector = { build = function(c) container = c; buildPreviewPane(c) end },
  tab      = { w = 360, build = buildTab },
  sections = {
    { id = "shape",     title = "Icon Size & Shape",                build = buildShapePage },
    { id = "deco",      title = "Decoration Layers",                build = buildDecoPage },
    { id = "text",      title = "Text",                             build = buildTextPage },
    { id = "glows",     title = "Glows & Animations",               build = buildGlowsPage },
    { id = "casts",     title = "Casts & Channels",                 build = buildCastsPage },
    { id = "cooldowns", title = "Cooldowns & Availability",         build = buildCooldownsPage },
    { id = "layout",    title = "Bar Visibility, Layout & Presets", build = buildLayoutPage },
  },
  onOpen   = function() C:Refresh() end,
  -- Exiting the addon RELOCKS the bars (the owner): however the Bars windows go
  -- away — Escape, a close disc, /gb, or another tool — move mode ends with
  -- them, so movers never outlive the editor.
  onClose  = function()
    if GB.Layout and GB.Layout:MoveModeOn() then GB.Layout:SetMoveMode(false) end
  end,
  refresh  = function() C:Refresh() end,
}
