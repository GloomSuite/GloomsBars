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
local SKIN_MAJOR, SKIN_NEEDS = "LibGloomSkin-1.0", 12   -- 12: the KIT (button / pick / sectionHeader / dial / chip) + RegisterTab's `profile` footer — the redesign, stage 3

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
-- The Bars tab + one-open accordion
-- --------------------------------------------------------------------------
-- Phase C: this UI mounts as the BARS tab of the Suite window — the shell
-- hands BuildTab a `container` sized to the content area, and the tab keeps
-- its OWN footer row (the controls from the old window footer; CONTRACTS §2).
-- Three panes (the owner, session 14): profile + preset selection on the LEFT
-- (always visible — it decides what everything else edits), the control
-- accordion in the MIDDLE (widest — it absorbs any extra shell width), the
-- preview pane on the RIGHT.
-- ★ REDESIGN STAGE 3 (2026-09-21, Hub BACKLOG 16): the mocks' Bars tab. The
-- RAIL is 250 wide — the kit's PRESET block on a faint plate (120 tall) over
-- the dark PREVIEW pane (the state buttons, the construction, the caption) —
-- and the accordion fills the rest, headers at x=21 of the content pane. The
-- profile row moved to the Suite window's footer (RegisterTab `profile`).
local RAIL_W = 250               -- left rail: preset block + preview pane
local RAIL_TOP_H = 120           -- the preset block's plate
local PREVIEW_W = 0              -- (the preview lives in the rail now)
local FOOTER_H = 0               -- the tab has no footer of its own; the Layout section holds Move / Keybind / Reset / Highlight / Enable
local SECTION_HDR_H = 26         -- the kit header (16) + 10
local BODY_GAP_TOP, BODY_GAP_BOTTOM = 10, 28   -- the mocks: body 20 under the header (10 + the header's 10), next header 28 after
-- Padding-compensation for our masks (matches Skin.lua GROW_RATIO / the 240/256
-- edge-padding rule) + the state-ring inset fit; kept local so the preview uses
-- exactly the engine's geometry.
local GROW_RATIO = (256 / 240 - 1) / 2
-- The construction (icon + extension) is centered vertically at this pane-Y so a
-- plate growing above OR below stays put and never rides into the state chips or
-- the caption (max construction ≈ 104 + 0.9·104 ≈ 198px, so ±99 clears both).
local PREVIEW_CENTER_Y = -266    -- the mock: the 100px construction's centre, 266 under the preview pane's top

local container, bodyContainer, contentScroll   -- container: the shell-provided Bars tab frame; contentScroll: the middle accordion's scroll frame (for scroll-to-top on open)
local sections = {}
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
local function relayout()
  local prevBottom
  local total = 0
  for _, s in ipairs(sections) do
    s.header:ClearAllPoints()
    if prevBottom then
      local gap = prevBottom.isBody and -BODY_GAP_BOTTOM or 0
      s.header:SetPoint("TOPLEFT", prevBottom, "BOTTOMLEFT", 0, gap)
      s.header:SetPoint("TOPRIGHT", prevBottom, "BOTTOMRIGHT", 0, gap)
    else
      s.header:SetPoint("TOPLEFT", bodyContainer, "TOPLEFT", 0, 0)
      s.header:SetPoint("TOPRIGHT", bodyContainer, "TOPRIGHT", 0, 0)
    end
    s.header.button:SetOpen(s.open)
    total = total + SECTION_HDR_H
    if s.open then
      s.bodyFrame:ClearAllPoints()
      s.bodyFrame:SetPoint("TOPLEFT", s.header, "BOTTOMLEFT", 0, -BODY_GAP_TOP)
      s.bodyFrame:SetPoint("TOPRIGHT", s.header, "BOTTOMRIGHT", 0, -BODY_GAP_TOP)
      s.bodyFrame:Show()
      prevBottom = s.bodyFrame
      total = total + (s.bodyFrame:GetHeight() or 0) + BODY_GAP_TOP + BODY_GAP_BOTTOM
    else
      s.bodyFrame:Hide()
      prevBottom = s.header
    end
  end
  if bodyContainer then bodyContainer:SetHeight(math.max(total + 4, 10)) end
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
local LL_GLOW = linkList({ "Glows", "Animations" })
local LL_CDA = linkList({ "Cooldown & Availability" })
local LL_CAST = linkList({ "Glows", "Animations", { "Cast & Channel", "fill & bursts" } })
-- Each entry = { HEADING, body, links }: the state name (bold Semibold line), what
-- triggers it in-game (plain prose), then the clickable "Styled in:" bullet list.
local STATE_DESC = {
  idle      = { "Idle", "The button's resting/default look with nothing active.",
                linkList({ "Shape & Icon", "Plate Construction", "Decoration Layers", "Text" }) },
  proc      = { "Proc", "Triggered when an ability procs (a free or empowered cast becomes ready).", LL_GLOW },
  highlight = { "Highlight", "Indicates the current location (if any) on your action bars when hovering over an ability or talent in your spellbook or talent tree.", LL_GLOW },
  assist    = { "Assist", "Triggered by Blizzard's Combat Assistant/Assisted Highlight feature to indicate the suggested next rotation ability.", LL_GLOW },
  cast      = { "Cast", "Shows while activating an ability with a cast time.", LL_CAST },
  channel   = { "Channel", "Shows while activating a channeled ability.", LL_CAST },
  hover     = { "Hover", "Shows while hovering your pointer over an icon in your action bars.", LL_GLOW },
  selected  = { "Selected", "Displays when a button is toggled on (a stance, form or aura).", LL_GLOW },
  flash     = { "Flash", "Appears when auto-attack or auto-shot is active — typically needs the related auto-attack ability to be on the action bar. Not commonly seen.", LL_GLOW },
  cooldown  = { "Cooldown", "A swipe animation and finish flash to indicate that an ability is recharging or ready.",
                linkList({ "Cooldown & Availability", { "Text", "countdown numbers" } }) },
  unusable  = { "Unusable", "Indicates an ability is unusable due to wrong talent, form/stance, weapon type, silenced, missing resource, etc.", LL_CDA },
  oom       = { "Out of Mana", "Indicates you have insufficient mana or other resource/power to cast.", LL_CDA },
  range     = { "Out of Range", "Shows when the target is too far for the ability to be cast. Tints the icon and recolors the keybind text (if shown).",
                linkList({ { "Cooldown & Availability", "enable & style" } }) },
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

function C:ToggleSection(s)
  setCaption(nil)   -- Animations re-sets it in s.refresh
  local wasOpen = s.open
  for _, x in ipairs(sections) do x.open = false end
  local opening = not wasOpen
  if opening then s.open = true; if s.refresh then s.refresh() end end   -- reflect current state on open
  relayout()
  if not opening and contentScroll then contentScroll:SetVerticalScroll(0) end   -- nothing open → every header shows
  -- Surface as much of a freshly-opened section as possible: scroll its header
  -- NEAR the top of the pane, leaving just ONE collapsed header visible above it
  -- (the owner) so the opened content fills the view. Deferred a frame so the scroll
  -- range reflects the new bodyContainer height relayout() just set. Only sections
  -- ABOVE the opened one collapse above it — every one is closed now, so the
  -- opened header's offset = (its index - 1) collapsed headers tall.
  if opening and contentScroll then
    local idx
    for i, x in ipairs(sections) do if x == s then idx = i; break end end
    if idx then
      -- Leave one collapsed header visible above → target the header one slot up.
      local target = (idx - 2) * SECTION_HDR_H   -- idx-1 headers above; minus one to keep visible
      C_Timer.After(0, function()
        if not contentScroll then return end
        local range = contentScroll:GetVerticalScrollRange()
        contentScroll:SetVerticalScroll(math.max(0, math.min(range, target)))
      end)
    end
  end
end

-- Open (never close) the section with this title — the caption's section links.
function C:OpenSection(title)
  for _, s in ipairs(sections) do
    if s.title == title then
      if not s.open then self:ToggleSection(s) end
      return
    end
  end
end

-- A section = an accordion header (orange caret + purple Khand title) over a
-- body frame. `build(bodyFrame, section)` fills the body and sets its height.
local function makeSection(title, build)
  local s = { title = title, open = false }

  -- The kit's header (stage 3): a violet triangle + Play Bold 14 violet title at
  -- x=21 of the content pane (the mock's 271 − the rail's 250).
  local header = CreateFrame("Frame", nil, bodyContainer)
  header:SetHeight(SECTION_HDR_H)
  header.button = UI.sectionHeader(header, title, { onToggle = function() C:ToggleSection(s) end })
  header.button:SetPoint("TOPLEFT", 21, 0)

  local bodyFrame = CreateFrame("Frame", nil, bodyContainer)
  bodyFrame:SetHeight(10); bodyFrame.isBody = true

  s.header, s.bodyFrame = header, bodyFrame
  if build then build(bodyFrame, s) end
  sections[#sections + 1] = s
  return s
end

-- (flatEditBox comes from LibGloomSkin — see the toolkit block at the top.)

-- (The skinned text-entry dialog GB used to carry privately is LibGloomSkin's
-- UI.nameDialog as of MINOR 3 — GB's only callers were the rail's profile and
-- preset blocks, which are now the shared UI.profileBlock and open it themselves.)

-- (attachTip — the family-styled hover tooltip — comes from LibGloomSkin;
-- see the toolkit block at the top.)

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

-- Shape & icon — the 21 preset silhouettes as a grouped thumbnail grid, plus a
-- uniform size scale, icon zoom, and crop-to-fill. The shaped-glow pivot (session
-- 8, docs/SHAPE-CATALOG.md) retired free width/height + the SDF corner presets: the
-- icon is ONE baked silhouette so it can't warp, and Size scales every icon
-- together (aspect fixed by the shape). Picking a thumbnail calls Skin:SetHandShape
-- (persists + applies live); Size → Skin:SetSizeScale. Each thumbnail draws the
-- shape's own <key>-base.png (white on transparent), tinted grey / purple-selected.
local function buildShapeSection(bf, s)
  -- ★ STAGE 3 (2026-09-21): the Shape & Icon mock (`651:2528`), body-relative.
  local thumbs = {}   -- shape key → tile (for the selection refresh)

  -- Size in % · Icon Zoom · Crop to Fill on the first row
  local sizeDial = UI.dial(bf, { label = "Size in %", min = 50, max = 200, step = 5, unit = "%",
    get = function() return math.floor(((GB.db and GB.db.sizeScale) or 1) * 100 + 0.5) end,
    set = function(v) v = v / 100; if GB.Skin then GB.Skin:SetSizeScale(v) else GB.db.sizeScale = v end; C:RefreshPreview() end })
  sizeDial:SetPoint("TOPLEFT", 50, 0)
  attachTip(sizeDial.strip, "Size", "Scales every icon together, as a percentage of the Edit Mode button size. The clickable hit area stays Edit Mode's.")
  local zoomDial = UI.dial(bf, { label = "Icon Zoom", min = 0, max = 30, unit = "%",
    get = function() return math.floor(((GB.db and GB.db.zoom) or 0) * 100 + 0.5) end,
    set = function(v) v = v / 100; if GB.Skin then GB.Skin:SetZoom(v) end; C:PreviewZoom(v) end })
  zoomDial:SetPoint("TOPLEFT", 274, 0)
  attachTip(zoomDial.strip, "Icon zoom", "Crops into the icon art from every side, hiding Blizzard's baked-in border.")
  local fillLbl = UI.label(bf, "Crop to Fill"); fillLbl:SetPoint("TOPLEFT", 498, 0)
  local fillTog = UI.toggleBar(bf,
    function() return not (GB.db and GB.db.iconFill == "stretch") end,
    function(v)
      if GB.Skin then GB.Skin:SetIconFill(v and "fill" or "stretch") else GB.db.iconFill = v and "fill" or "stretch" end
      C:RefreshPreview()
    end)
  fillTog:SetPoint("TOPLEFT", 498, -18)
  attachTip(fillTog, "Crop to fill", "On: a non-square shape crops the icon art to fill it. Off: the art is stretched to the shape.")

  -- One tile: a 64px dim plate with the silhouette's own -base.png (white on
  -- transparent) fit to its aspect in a 48px box; violet plate when selected.
  local CELL, PITCH = 64, 74
  local function makeThumb(key)
    local info = GB.HAND_SHAPES[key] or GB.HAND_SHAPES.circle
    local b = CreateFrame("Button", nil, bf)
    b:SetSize(CELL, CELL)
    local bg = UI.roundFill(b, "BACKGROUND"); UI.tint(bg, COLOR.dim)
    local box = 48
    local w, h = box, box
    if info.orient == "portrait" then w = box / info.aspect
    elseif info.orient == "landscape" then h = box / info.aspect end
    local tex = b:CreateTexture(nil, "ARTWORK")
    tex:SetSize(w, h); tex:SetPoint("CENTER"); tex:SetTexture(GB:HandAsset(key, "base"))
    function b:SetSelected(on)
      self._sel = on and true or false
      if on then UI.tint(bg, COLOR.violet) else UI.tint(bg, COLOR.dim) end
    end
    b:SetScript("OnEnter", function(self)
      if not self._sel then UI.tint(bg, COLOR.dim, 0.7) end
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetText(info.label, 1, 1, 1); GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function(self)
      if not self._sel then UI.tint(bg, COLOR.dim) end
      GameTooltip:Hide()
    end)
    b:SetScript("OnClick", function()
      if GB.Skin then GB.Skin:SetHandShape(key) else GB.db.handShape = key end
      s.refresh(); C:RefreshPreview()
    end)
    b:SetSelected(false)
    return b
  end

  -- The groups at the mock's rows: title at y, tiles 20 under it, one row each
  -- (the catalog's groups fit one row; a longer group wraps at 13).
  local y = 65
  for _, g in ipairs(GB.HAND_GROUPS) do
    local t = UI.label(bf, g.title); t:SetPoint("TOPLEFT", 50, -y)
    local rows = 1
    for i, key in ipairs(g.keys) do
      local col, row = (i - 1) % 13, math.floor((i - 1) / 13)
      rows = math.max(rows, row + 1)
      local th = makeThumb(key); thumbs[key] = th
      th:SetPoint("TOPLEFT", 50 + col * PITCH, -(y + 20 + row * PITCH))
    end
    y = y + 20 + rows * PITCH + 16
  end
  bf:SetHeight(y - 16)

  s.refresh = function()
    local active = GB.db and GB.db.handShape
    for key, th in pairs(thumbs) do th:SetSelected(key == active) end
    sizeDial:refresh(); zoomDial:refresh(); fillTog:refresh()
    relayout()
  end
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
-- Kit cell shorthands (stage 3): a labelled 35px cell around a kit control.
local function toggleCell(parent, labelText, get, set) return UI.cell(parent, labelText, function(c) return UI.toggleBar(c, get, set) end) end
local function segCell(parent, labelText, options, get, set, opts) return UI.cell(parent, labelText, function(c) return UI.segments(c, options, get, set, opts) end) end
local function chipCell(parent, labelText, opts) return UI.cell(parent, labelText, function(c) return UI.chip(c, opts) end) end
local function pickCell(parent, labelText, w, getLabel, getOptions, getCurrent, onPick) return UI.cell(parent, labelText, function(c) return UI.pick(c, w, getLabel, getOptions, getCurrent, onPick) end) end
local function at(wd, x, y) wd:SetPoint("TOPLEFT", x, -y); return wd end

local function buildPlateSection(bf, s)
  -- ★ STAGE 3 (2026-09-21): the Plate Construction mock (`651:2755`), body-relative.
  local function on() local p = plateData(); return p and p.enabled and true or false end
  local w = {}
  w.on = at(toggleCell(bf, "Plate Construction", on, function(v)
    local p = ensurePlate(); if p then p.enabled = v and true or false end
    if GB.Skin then GB.Skin:RefreshPlate() end
    C:RefreshPreview(); s.refresh()
  end), 50, 0)
  attachTip(w.on.control, "Plate construction", "Square icon in one half of a 2:1 shape, a solid plate with a colour fade in the other.")
  -- Icon alignment: which half the square icon fills (the plate fills the other).
  w.side = at(segCell(bf, "Icon Alignment", { { value = "top", label = "Top" }, { value = "bottom", label = "Bottom" } },
    function() return (plateData() and plateData().iconSide) or "top" end,
    function(v)
      local p = ensurePlate(); if p then p.iconSide = v end
      if GB.Skin then GB.Skin:RefreshPlate() end
      C:RefreshPreview()
    end), 213, 0)
  w.color = at(chipCell(bf, "Plate Color", {
    get = function() local p = plateData(); return p and p.color end,
    set = function(c) local p = ensurePlate(); if p then p.color = c end; local l = gradLayer(); if l then l.color = c end; if GB.Skin then GB.Skin:ReapplyDecor() end; C:RefreshPreview() end,
    optional = true, label = "Bars › Plate color", title = "Plate Color" }), 399, 0)
  -- Fade start: how far the plate colour bleeds up over the icon. Kept in sync with the
  -- Decoration Layers gradient fade (bleedPct) when a gradient layer exists.
  w.fade = at(UI.dial(bf, { label = "Fade Start", min = 0, max = 100, step = 5, unit = "%",
    get = function() local p = plateData(); return math.floor(((p and p.fadeStart) or 0.5) * 100 + 0.5) end,
    set = function(v)
      v = v / 100
      local p = ensurePlate(); if p then p.fadeStart = v end
      local l = gradLayer(); if l then l.bleedPct = v end
      if GB.Skin then GB.Skin:ReapplyDecor() end; C:RefreshPreview()
    end }), 503, 0)
  attachTip(w.fade.strip, "Fade start", "How far up the icon the plate colour bleeds before it fades out.")
  -- Dim on cooldown: the plate colour darkens while the action's REAL (non-GCD)
  -- cooldown runs — the icon half already darkens under the sweep; this carries
  -- the "on cooldown" read across the plate half. Engine: Skin's dim proxy.
  w.dim = at(toggleCell(bf, "Dim on Cooldown",
    function() local p = plateData(); return p and p.dimCD and true or false end,
    function(v)
      local p = ensurePlate(); if p then p.dimCD = v and true or false end
      if GB.Skin and GB.Skin.RefreshPlateDim then GB.Skin:RefreshPlateDim() end
    end), 50, 55)
  local note = newText(bf, FONT.ui, 11, COLOR.ink, "LEFT")
  note:SetPoint("TOPLEFT", 213, -71); note:SetWidth(560); note:SetJustifyH("LEFT")
  note:SetText("Note: Plate Construction needs a 2:1 aspect ratio. Pick |cff000000Pill 2:1|r, |cff000000Tall Square 2:1|r, or a |cff000000Tall Rounded 2:1|r in Shape & Icon.")
  bf:SetHeight(100)
  s.refresh = function()
    local ok = plateShapeOK()
    w.on:refresh(); w.on:setEnabled(ok)
    local live = ok and on()
    for _, c in ipairs({ w.side, w.color, w.fade, w.dim }) do c:refresh(); c:setEnabled(live) end
    note:SetAlpha(ok and 0.5 or 1)
  end
end

-- Decoration — the gradient plate that fills the extension and fades up into the
-- icon. One layer for now (color + fade + on/off); multiple layers come later.
local DIR_OPTS = { { value = "up", label = "Up" }, { value = "down", label = "Down" }, { value = "left", label = "Left" }, { value = "right", label = "Right" } }

local function buildDecorSection(bf, s)
  -- ★ STAGE 3 (2026-09-21): the Decoration Layers mock (`651:3020`), body-relative.
  local w = {}
  local function decor() if GB.Skin then GB.Skin:ReapplyDecor() end; C:RefreshPreview() end

  -- ROW 0: the gradient fill
  w.grad = at(toggleCell(bf, "Gradient Fade",
    function() local l = gradLayer(); return l and l.enabled ~= false end,
    function(v) local l = ensureGradLayer(); l.enabled = v; decor(); s.refresh() end), 50, 0)
  w.gradColor = at(chipCell(bf, "Gradient", {
    get = function() local l = gradLayer(); return l and l.color end,
    set = function(c) local l = ensureGradLayer(); l.color = c; if plateData() then plateData().color = c end; decor() end,
    optional = true, label = "Bars › Gradient fill color", title = "Gradient Color" }), 196, 0)
  w.fade = at(UI.dial(bf, { label = "Fade Start", min = 0, max = 100, step = 5, unit = "%",
    get = function() local l = gradLayer(); return math.floor(((l and l.bleedPct) or 0.5) * 100 + 0.5) end,
    set = function(v) v = v / 100; local l = ensureGradLayer(); l.bleedPct = v; if plateData() then plateData().fadeStart = v end; decor() end }), 284, 0)
  attachTip(w.fade.strip, "Fade start", "How far across the icon the colour reaches before it fades out; Fade Direction sets the solid edge.")
  w.fadeDir = at(segCell(bf, "Fade Direction", DIR_OPTS,
    function() local l = gradLayer(); return (l and l.dir) or "up" end,
    function(d) local l = ensureGradLayer(); l.dir = d; decor() end, { padX = 8 }), 576, 0)   -- the mock's 185px four-way bar

  -- ROW 1: the border
  w.border = at(toggleCell(bf, "Icon Border",
    function() local b2 = borderData(); return b2 and b2.enabled end,
    function(v) local b2 = ensureBorder(); b2.enabled = v; decor(); s.refresh() end), 50, 65)
  w.borderColor = at(chipCell(bf, "Border Color", {
    get = function() local b2 = borderData(); return b2 and b2.color end,
    set = function(c) local b2 = ensureBorder(); b2.color = c; decor() end,
    hasAlpha = true, optional = true, label = "Bars › Border color", title = "Border Color" }), 196, 65)
  -- Off keeps the second colour (twoTone = false), so On brings it back
  -- unchanged (the owner, 2026-09-21: wiping it "is bad").
  local function twoOn() local b2 = borderData(); return b2 and b2.color2 ~= nil and b2.twoTone ~= false end
  w.two = at(toggleCell(bf, "Two-Tone Border", twoOn,
    function(v)
      local b2 = ensureBorder()
      if v then b2.color2 = b2.color2 or { 1, 1, 1 }; b2.twoTone = nil else b2.twoTone = false end
      decor(); s.refresh()
    end), 309, 65)
  attachTip(w.two.control, "Two-tone border", "Makes the border a gradient between its colour and the second colour, along the blend direction.")
  w.color2 = at(chipCell(bf, "Second Color", {
    get = function() local b2 = borderData(); return b2 and b2.color2 end,
    set = function(c) local b2 = ensureBorder(); b2.color2 = c; decor() end,
    hasAlpha = true, label = "Bars › Border color 2", title = "Second Border Color" }), 455, 65)
  w.blendDir = at(segCell(bf, "Blend Direction", DIR_OPTS,
    function() local b2 = borderData(); return (b2 and b2.gradDir) or "up" end,
    function(d) local b2 = ensureBorder(); b2.gradDir = d; decor() end, { padX = 8 }), 576, 65)

  -- ROW 2: thickness · opacity
  w.thick = at(UI.dial(bf, { label = "Thickness", min = 1, max = 12, unit = "px",
    get = function() local b2 = borderData(); return (b2 and b2.thickness) or 3 end,
    set = function(v) local b2 = ensureBorder(); b2.thickness = v; decor() end }), 50, 129)
  w.alpha = at(UI.dial(bf, { label = "Opacity %", min = 0, max = 100, step = 5, unit = "%",
    get = function() local b2 = borderData(); return math.floor(((b2 and b2.alpha) or 1) * 100 + 0.5) end,
    set = function(v) local b2 = ensureBorder(); b2.alpha = v / 100; decor() end }), 276, 129)

  -- ROW 3: the icon tint
  w.tintMode = at(segCell(bf, "Colorize Icon", { { value = "off", label = "Off" }, { value = "wash", label = "Wash" }, { value = "tint", label = "Tint" } },
    function() return (GB.db and GB.db.iconTintMode) or "off" end,
    function(m) if GB.Skin then GB.Skin:SetIconTintMode(m) end; s.refresh(); C:SetPreviewState("idle") end, { padX = 10 }), 50, 194)   -- idle so the tint is visible undimmed; the mock's 136px bar
  attachTip(w.tintMode.control, "Colorize icon", "Colours the normal state only, so out-of-range, out-of-mana and unusable still show through. Wash gives one clean colour but makes icons harder to tell apart; Tint keeps the art and adds a cast (pale colours work best).")
  w.tintColor = at(chipCell(bf, "Tint Color", {
    get = function() return GB.db and GB.db.iconTintColor end,
    set = function(c) if GB.Skin then GB.Skin:SetIconTintColor(c) end; C:SetPreviewState("idle") end,
    optional = true, label = "Bars › Icon tint", title = "Tint Color" }), 216, 194)
  w.tintStr = at(UI.dial(bf, { label = "Tint Strength", min = 0, max = 100, step = 5, unit = "%",
    get = function() local v = GB.db and GB.db.iconTintStrength; return math.floor((v == nil and 1 or v) * 100 + 0.5) end,
    set = function(v) if GB.Skin then GB.Skin:SetIconTintStrength(v / 100) end; C:SetPreviewState("idle") end }), 310, 194)

  bf:SetHeight(235)
  s.refresh = function()
    for _, c in pairs(w) do c:refresh() end
    local gradOn = (function() local l = gradLayer(); return l and l.enabled ~= false end)()
    w.gradColor:setEnabled(gradOn); w.fade:setEnabled(gradOn); w.fadeDir:setEnabled(gradOn)
    local bOn = (function() local b2 = borderData(); return b2 and b2.enabled and true or false end)()
    local two = bOn and twoOn()
    w.borderColor:setEnabled(bOn); w.two:setEnabled(bOn); w.thick:setEnabled(bOn); w.alpha:setEnabled(bOn)
    w.color2:setEnabled(two and true or false); w.blendDir:setEnabled(two and true or false)
    local tintOn = ((GB.db and GB.db.iconTintMode) or "off") ~= "off"
    w.tintColor:setEnabled(tintOn); w.tintStr:setEnabled(tintOn)
  end
end

-- ★ STAGE 3 (2026-09-21): the Text mock (`651:3493`), body-relative. One block
-- per text (Keybind · Charge Count · Countdown · Name) behind a four-way bar;
-- every block is the same layout with the kind's own first cell (the enable
-- toggle, or Name's DEFAULT | CUSTOM | HIDDEN), its own Zone choices (none
-- for Countdown) and Keybind's Mac Symbol Icons.
local function textBlock(bf, k)
  local f = CreateFrame("Frame", nil, bf)
  f:SetPoint("TOPLEFT", 0, -37); f:SetPoint("TOPRIGHT", 0, -37); f:SetHeight(230)
  f:Hide()
  local data, ensure, apply, on = k.data, k.ensure, k.apply, k.on
  local w = {}
  local function num(field, default) return function() local c = data(); return (c and c[field]) or default end end
  local function setNum(field) return function(v) local c = ensure(); if c then c[field] = v end; apply() end end

  w.head = at(k.head(f), 50, 0)
  w.color = at(chipCell(f, "Color", {
    get = function() local c = data(); return c and c.color end,
    set = function(col) local c = ensure(); if c then c.color = col end; apply() end,
    optional = true, label = "Bars › " .. k.title .. " color", title = k.title .. " Color" }), 196, 0)
  w.font = at(pickCell(f, "Font", 180,
    function() local c = data(); local n = c and c.font; return (n and n ~= "") and n or "Default" end,
    function() local o = { { label = "Default", value = "" } }; for _, n in ipairs(fontChoices()) do o[#o + 1] = { label = n, value = n } end; return o end,
    function() local c = data(); return (c and c.font) or "" end,
    function(v) local c = ensure(); if c then c.font = (v ~= "") and v or nil end; apply() end), 279, 0)
  w.ox = at(UI.dial(f, { label = "Horizontal Offset", min = -40, max = 40, unit = "px", centre = true, get = num("offsetX", 0), set = setNum("offsetX") }), 502, 0)
  if k.zones then
    w.zone = at(segCell(f, "Zone", k.zones, num("zone", k.zoneDefault), setNum("zone")), 50, 55)
    if k.zoneTip then attachTip(w.zone.control, "Zone", k.zoneTip) end
  end
  w.size = at(UI.dial(f, { label = "Font Size", min = k.sizeMin or 6, max = k.sizeMax or 28, unit = "px", get = num("size", k.sizeDefault), set = setNum("size") }), 261, 55)
  w.oy = at(UI.dial(f, { label = "Vertical Offset", min = -40, max = 40, unit = "px", centre = true, get = num("offsetY", 0), set = setNum("offsetY") }), 502, 55)

  -- outline + shadow
  w.outline = at(segCell(f, "Text Outline", { { value = "", label = "None" }, { value = "OUTLINE", label = "Outline" }, { value = "THICKOUTLINE", label = "Thick" } },
    function() local c = data(); return (c and c.flags) or "OUTLINE" end,
    function(v) local c = ensure(); if c then c.flags = v end; apply() end), 50, 139)
  local function shadow() local c = data(); return c and c.shadow end
  local function shadowOn()
    local sh = shadow()
    if sh == nil then return k.shadowDefault end   -- legacy: mirror the engine's fallback
    return sh.enabled and true or false
  end
  local function ensureShadow()
    local c = ensure(); if not c then return nil end
    c.shadow = c.shadow or { enabled = k.shadowDefault, color = { 0, 0, 0, 1 }, x = 1, y = -1 }
    return c.shadow
  end
  w.shadow = at(toggleCell(f, "Shadow", shadowOn, function(v) local sh = ensureShadow(); if sh then sh.enabled = v and true or false end; apply(); f.refresh() end), 306, 139)
  w.shx = at(UI.dial(f, { label = "Shadow Horizontal Offset", min = -8, max = 8, unit = "px", centre = true,
    get = function() local sh = shadow(); return (sh and sh.x) or 1 end,
    set = function(v) local sh = ensureShadow(); if sh then sh.x = v end; apply() end }), 452, 139)
  w.shColor = at(chipCell(f, "Shadow Color", {
    get = function() local sh = shadow(); return sh and sh.color end,
    set = function(col) local sh = ensureShadow(); if sh then sh.color = col end; apply() end,
    hasAlpha = true, optional = true, label = "Bars › " .. k.title .. " shadow color", title = "Shadow Color" }), 306, 194)
  w.shy = at(UI.dial(f, { label = "Shadow Vertical Offset", min = -8, max = 8, unit = "px", centre = true,
    get = function() local sh = shadow(); return (sh and sh.y) or -1 end,
    set = function(v) local sh = ensureShadow(); if sh then sh.y = v end; apply() end }), 452, 194)
  if k.extra then w.extra = at(k.extra(f), 50, 194) end

  f.refresh = function()
    local live = on()
    for name, c in pairs(w) do
      c:refresh()
      if name ~= "head" then c:setEnabled(live) end
    end
    local shOn = live and shadowOn()
    w.shColor:setEnabled(shOn); w.shx:setEnabled(shOn); w.shy:setEnabled(shOn)
  end
  return f
end

local function buildTextSection(bf, s)
  local function reapply() if GB.Skin then GB.Skin:ReapplyDecor() end end
  local function reCD() if GB.Skin and GB.Skin.RefreshCooldownText then GB.Skin:RefreshCooldownText() end end
  local blocks = {}
  local tab = "keybind"

  blocks.keybind = textBlock(bf, { title = "Keybind", data = hotkeyData, ensure = ensureHotkey, apply = reapply, on = hotkeyOn,
    head = function(f) return toggleCell(f, "Custom Keybind", hotkeyOn,
      function(v) local h = ensureHotkey(); if h then h.enabled = v and true or false end; reapply(); if GB.Skin then GB.Skin:RefreshHotkeyText() end; f.refresh() end) end,
    zones = { { value = "center", label = "Center" }, { value = "extension", label = "Extension" } }, zoneDefault = "extension",
    sizeDefault = 13, shadowDefault = false,
    extra = function(f)
      local c = toggleCell(f, "Mac Symbol Icons",
        function() local st = GB.db and GB.db.styleData; return st and st.keybindMods == "symbols" end,
        function(v)
          local st = GB.db and GB.db.styleData; if st then st.keybindMods = v and "symbols" or "default" end
          if GB.Skin then GB.Skin:RefreshHotkeyText() end
        end)
      attachTip(c.control, "Mac symbol icons", "Replaces the m-/s-/c-/a- prefixes with ⌘/⇧/⌃/⌥ (macOS binds).")
      return c
    end })
  blocks.count = textBlock(bf, { title = "Charge Count", data = countData, ensure = ensureCount, apply = reapply, on = countOn,
    head = function(f) return toggleCell(f, "Custom Charge Count", countOn,
      function(v) local c = ensureCount(); if c then c.enabled = v and true or false end; reapply(); f.refresh() end) end,
    zones = { { value = "corner", label = "Corner" }, { value = "center", label = "Center" }, { value = "extension", label = "Plate" } }, zoneDefault = "corner",
    zoneTip = "Corner = Blizzard's spot on the icon; Plate centres it in the plate half (2:1 plate shapes only).",
    sizeDefault = 14, shadowDefault = false })
  blocks.cdtext = textBlock(bf, { title = "Countdown", data = cdtextData, ensure = ensureCdtext, apply = reCD, on = cdtextOn,
    head = function(f) local c = toggleCell(f, "Countdown Numbers", cdtextOn,
      function(v) local c2 = ensureCdtext(); if c2 then c2.enabled = v and true or false end; reCD(); f.refresh() end)
      attachTip(c.control, "Countdown numbers", "The number Blizzard draws while a cooldown runs. Off = hidden. Styling applies from the next cooldown update.")
      return c end,
    sizeMin = 8, sizeMax = 30, sizeDefault = 16, shadowDefault = true })
  blocks.name = textBlock(bf, { title = "Name", data = nameData, ensure = ensureName, apply = reapply, on = function() return nameMode() == "custom" end,
    head = function(f) local c = segCell(f, "Macro Name", { { value = "default", label = "Default" }, { value = "custom", label = "Custom" }, { value = "hidden", label = "Hidden" } },
      nameMode, function(m) local c2 = ensureName(); c2.mode = m; c2.enabled = nil; reapply(); f.refresh() end)   -- mode supersedes the legacy flag
      attachTip(c.control, "Macro name", "Default = Blizzard's stock look; Hidden removes it; Custom applies the styling here and widens Blizzard's 36px clip box to the icon.")
      return c end,
    zones = { { value = "bottom", label = "Bottom" }, { value = "center", label = "Center" }, { value = "extension", label = "Plate" } }, zoneDefault = "bottom",
    sizeDefault = 10, shadowDefault = true })

  local tabs = UI.segments(bf, { { value = "keybind", label = "Keybind" }, { value = "count", label = "Charge Count" }, { value = "cdtext", label = "Countdown" }, { value = "name", label = "Name" } },
    function() return tab end, function(v) tab = v; s.refresh() end, { segW = 150 })
  tabs:SetPoint("TOPLEFT", 50, 0)

  bf:SetHeight(37 + 230)
  s.refresh = function()
    tabs:refresh()
    for key, f in pairs(blocks) do f:SetShown(key == tab) end
    blocks[tab].refresh()
  end
end

local function buildEmptySection(bf, s)
  -- ★ STAGE 3 (2026-09-21): the Empty Slots mock (`660:4995`): a three-way bar and the dim dial.
  local function mode() return (GB.db and GB.db.emptySlots) or "normal" end
  local seg = at(segCell(bf, "Empty Slots", { { value = "normal", label = "Normal" }, { value = "dim", label = "Dim" }, { value = "hide", label = "Hidden" } },
    mode, function(v)
      if GB.Skin and GB.Skin.SetEmptySlots then GB.Skin:SetEmptySlots(v) elseif GB.db then GB.db.emptySlots = v end
      s.refresh()
    end, { padX = 10 }), 50, 0)
  attachTip(seg.control, "Empty slots", "Slots with no action fade or vanish. They come back on their own while you drag a spell, so drop targets stay visible.")
  local dim = at(UI.dial(bf, { label = "Dim Opacity", min = 5, max = 90, step = 5, unit = "%",
    get = function() return math.floor(((GB.db and GB.db.emptySlotAlpha) or 0.35) * 100 + 0.5) end,
    set = function(v)
      v = v / 100
      if GB.Skin and GB.Skin.SetEmptySlotAlpha then GB.Skin:SetEmptySlotAlpha(v) elseif GB.db then GB.db.emptySlotAlpha = v end
    end }), 245, 0)
  bf:SetHeight(40)
  s.refresh = function()
    seg:refresh(); dim:refresh(); dim:setEnabled(mode() == "dim")
  end
end

local function buildCastSection(bf, s)
  -- ★ STAGE 3 (2026-09-21): the Cast & Channel mock (`657:4581`), body-relative.
  local w = {}
  local function showCast() C:SetPreviewState("cast") end   -- fill edits animate on the Cast chip
  w.fill = at(chipCell(bf, "Fill Color", {
    get = function() return GB.db and GB.db.castFillColor end,
    set = function(c) if GB.db then GB.db.castFillColor = c end; showCast() end,
    optional = true, label = "Bars › Cast fill color", title = "Cast Fill Color" }), 50, 0)
  w.alpha = at(UI.dial(bf, { label = "Opacity %", min = 0, max = 100, step = 5, unit = "%",
    get = function() return math.floor(((GB.db and GB.db.castFillAlpha) or 0.55) * 100 + 0.5) end,
    set = function(v) if GB.db then GB.db.castFillAlpha = v / 100 end; showCast() end }), 186, 0)
  w.dir = at(segCell(bf, "Cast Fill Direction", DIR_OPTS,
    function() return (GB.db and GB.db.castDrainDir) or "up" end,
    function(d) if GB.db then GB.db.castDrainDir = d end; showCast() end, { padX = 8 }), 424, 0)
  w.complete = at(chipCell(bf, "Complete Color", {
    get = function() return GB.db and GB.db.castCompleteColor end,
    set = function(c) if GB.db then GB.db.castCompleteColor = c end end,
    optional = true, label = "Bars › Cast complete color", title = "Cast Complete Color" }), 649, 0)
  w.interrupt = at(chipCell(bf, "Interrupt Color", {
    get = function() return GB.db and GB.db.castInterruptColor end,
    set = function(c) if GB.db then GB.db.castInterruptColor = c end end,
    optional = true, label = "Bars › Cast interrupt color", title = "Cast Interrupt Color" }), 50, 55)
  w.speed = at(UI.dial(bf, { label = "Interrupt Burst Animation Speed", min = 0.2, max = 2, step = 0.1, unit = "x",
    get = function() return (GB.db and GB.db.castInterruptSpeed) or 0.6 end,
    set = function(v) if GB.db then GB.db.castInterruptSpeed = v end end }), 186, 55)
  attachTip(w.speed.strip, "Interrupt burst speed", "Changes apply on your next cast. Below 1x slows the interrupt burst.")
  bf:SetHeight(90)
  s.refresh = function() for _, c in pairs(w) do c:refresh() end end
end

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
-- ★ STAGE 3 (2026-09-21): the Glows mock (`651:3928`) — Pulse Speed, then a
-- TABLE: a header row (Glow Status · Color · Layer · Opacity) and one row per
-- trigger, 26 apart: the name right-aligned, OFF | ON, a chip, the layer
-- picker, a bare dial.
local GX_LAB, GX_TOG, GX_SW, GX_LAY, GX_DIAL = 140, 152, 276, 315, 409
local function buildGlowsSection(bf, s)
  local rows = {}
  local function showPrev(prev) if prev then C:SetPreviewState(prev) end end

  local pulse = at(UI.dial(bf, { label = "Pulse Speed", min = 0.3, max = 2, step = 0.1, unit = "x",
    get = function() return (GB.db and GB.db.glowPulseSpeed) or 1 end,
    set = function(v) if GB.Glows then GB.Glows:SetPulseSpeed(v) end end }), 50, 0)
  rows[#rows + 1] = pulse

  local function head(x, txt, justify)
    local h = UI.label(bf, txt)
    if justify == "RIGHT" then h:SetPoint("TOPRIGHT", bf, "TOPLEFT", x, -53); h:SetJustifyH("RIGHT")
    else h:SetPoint("TOPLEFT", x, -53) end
  end
  head(GX_LAB, "Glow Status", "RIGHT"); head(GX_SW, "Color"); head(GX_LAY, "Layer"); head(GX_DIAL + 50, "Opacity")

  local y = 80
  for _, r in ipairs(GLOW_ROWS) do
    local key, label, prev = r[1], r[2], r[3]
    local lab = UI.label(bf, label); lab:SetPoint("TOPRIGHT", bf, "TOPLEFT", GX_LAB, -y - 2); lab:SetJustifyH("RIGHT")
    local tog = at(UI.toggleBar(bf,
      function() local t = trig(key); return t and t.enabled ~= false end,
      function(on) if GB.Glows then GB.Glows:SetTriggerEnabled(key, on) end; s.refresh(); showPrev(prev) end), GX_TOG, y)
    local chip = at(UI.chip(bf, {
      get = function() local t = trig(key); return t and t.color end,
      set = function(c) if GB.Glows then GB.Glows:SetTriggerColor(key, c) end; showPrev(prev) end,
      label = "Bars › Glow › " .. label, title = label .. " Glow Color" }), GX_SW, y)   -- a required colour: the bare swatch
    local lay = at(UI.pick(bf, 80,
      function() local t = trig(key); return LAYER_LABEL[(t and t.layers) or "both"] end,
      function() return LAYER_OPTS end,
      function() local t = trig(key); return (t and t.layers) or "both" end,
      function(v) if GB.Glows then GB.Glows:SetTriggerLayers(key, v) end; showPrev(prev) end), GX_LAY, y)
    local op = at(UI.dial(bf, { bare = true, min = 0, max = 100, step = 5, unit = "%",
      get = function() local t = trig(key); return math.floor(((t and t.opacity) or 1) * 100 + 0.5) end,
      set = function(v) if GB.Glows then GB.Glows:SetTriggerOpacity(key, v / 100) end; showPrev(prev) end }), GX_DIAL, y)
    rows[#rows + 1] = { refresh = function()
      tog:refresh(); chip:refresh(); lay:refresh(); op:refresh()
      local t = trig(key); local on = t and t.enabled ~= false
      lab:SetAlpha(on and 1 or 0.5); chip:setEnabled(on); lay:SetEnabled(on); op:setEnabled(on)
    end }
    y = y + 26
  end
  bf:SetHeight(y - 26 + 17)

  s.refresh = function()
    for _, rw in ipairs(rows) do rw:refresh() end
    C:SetPreviewState("proc")
  end
end

local function buildCooldownSection(bf, s)
  -- ★ STAGE 3 (2026-09-21): the Cooldown & Availability mock (`659:4804`) — a
  -- sweep row, a hairline at y=59, an availability row at y=79.
  local w = {}
  local function showCD() C:SetPreviewState("cooldown") end
  w.sweep = at(chipCell(bf, "Sweep Color", {
    get = function() return GB.db and GB.db.swipeColor end,
    set = function(c) if GB.Skin then GB.Skin:SetSwipeColor(c) end; showCD() end,
    optional = true, label = "Bars › Sweep color", title = "Sweep Color" }), 50, 0)
  w.sweepAlpha = at(UI.dial(bf, { label = "Sweep Opacity", min = 0, max = 100, step = 5, unit = "%",
    get = function() return math.floor(((GB.db and GB.db.swipeAlpha) or 0.8) * 100 + 0.5) end,
    set = function(v) if GB.Skin then GB.Skin:SetSwipeAlpha(v / 100) end; showCD() end }), 182, 0)
  w.flash = at(toggleCell(bf, "Finish Flash",
    function() return GB.db and GB.db.finishFlash end,
    function(v) if GB.Skin then GB.Skin:SetFinishFlash(v) end; s.refresh(); C:PlayPreviewFlash() end), 467, 0)
  attachTip(w.flash.control, "Finish flash", "A shape-matched burst when a cooldown completes.")
  w.flashColor = at(chipCell(bf, "Finish Flash Color", {
    get = function() return GB.db and GB.db.finishFlashColor end,
    set = function(c) if GB.Skin then GB.Skin:SetFinishFlashColor(c) end; C:PlayPreviewFlash() end,
    optional = true, label = "Bars › Finish flash color", title = "Finish Flash Color" }), 597, 0)
  local rule = bf:CreateTexture(nil, "ARTWORK"); rule:SetPoint("TOPLEFT", 50, -59); rule:SetSize(730, 1); UI.tint(rule, COLOR.paper)

  w.desat = at(toggleCell(bf, "Desaturate Unusable",
    function() return GB.db and GB.db.availDesaturate end,
    function(v) if GB.Skin then GB.Skin:SetAvailDesaturate(v) end end), 49, 79)
  w.unusable = at(chipCell(bf, "Unusable Tint", {
    get = function() return GB.db and GB.db.availUnusable end,
    set = function(c) if GB.Skin then GB.Skin:SetAvailUnusable(c) end end,
    optional = true, label = "Bars › Unusable tint", title = "Unusable Tint" }), 219, 79)
  w.oom = at(chipCell(bf, "Out of Mana Tint", {
    get = function() return GB.db and GB.db.availOOM end,
    set = function(c) if GB.Skin then GB.Skin:SetAvailOOM(c) end end,
    optional = true, label = "Bars › Out-of-mana tint", title = "Out of Mana Tint" }), 341, 79)
  w.range = at(toggleCell(bf, "Tint Out-of-Range",
    function() return GB.db and GB.db.rangeTint end,
    function(v) if GB.Skin then GB.Skin:SetRangeTint(v) end; s.refresh() end), 482, 79)
  attachTip(w.range.control, "Tint out-of-range", "Tints the icon and recolors the keybind text while the target is out of range.")
  w.rangeColor = at(chipCell(bf, "Out-of-Range Color", {
    get = function() return GB.db and GB.db.rangeColor end,
    set = function(c) if GB.Skin then GB.Skin:SetRangeColor(c) end end,
    optional = true, label = "Bars › Out-of-range color", title = "Out-of-Range Color" }), 633, 79)
  bf:SetHeight(120)
  s.refresh = function()
    for _, c in pairs(w) do c:refresh() end
    w.flashColor:setEnabled(GB.db and GB.db.finishFlash and true or false)
    w.rangeColor:setEnabled(GB.db and GB.db.rangeTint and true or false)
  end
end

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
  local base = 104
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
    local y = math.max(354, under)
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

-- One param control (from a module's schema). Returns { h, refresh, setEnabled, setShown }.
-- ★ STAGE 3 (2026-09-21): the Animations mock (`657:4328`), body-relative —
-- "Glow State" over a 2 × 4 grid of state buttons; then the module's
-- parameters by KIND: the colour chip beside the Animation picker (243, 92),
-- a choice (Style) under the picker (50, 147), and every range / speed as a
-- dial down the two right-hand columns (348 and 566, rows 92 and 147, then
-- 784). A bispeed is a centred dial from -1 to 1 reading "still" / "CW 1.2s";
-- its wider readout box takes the second row's LEFT slot (348, 147) so it
-- never runs toward the pane's edge (the owner, 2026-09-21).
local DIAL_SLOTS = { { 348, 92 }, { 566, 92 }, { 566, 147 }, { 784, 92 }, { 784, 147 } }
local function animParam(bf, id, param, onChange, x, y)
  local wd
  if param.kind == "color" then
    wd = chipCell(bf, param.label == "Colour" and "Color" or param.label, {
      get = function() return animGet(id, param.key) end,
      set = function(c) animSet(id, param.key, c); onChange() end,
      optional = true, label = "Bars › Animation › " .. param.label, title = param.label })
  elseif param.kind == "range" then
    local fmt = animFmt(param)
    wd = UI.dial(bf, { label = param.label, min = param.min, max = param.max, step = param.step,
      get = function() return animGet(id, param.key) end,
      set = function(v) animSet(id, param.key, v); onChange() end, fmt = fmt })
  elseif param.kind == "bispeed" then
    local minRev = param.minRev or 0.8
    local negLabel, posLabel = param.neg or "CCW", param.pos or "CW"
    wd = UI.dial(bf, { label = param.label, min = -1, max = 1, step = 0.05, centre = true,
      get = function() return animGet(id, param.key) or 0 end,
      set = function(v) animSet(id, param.key, v); onChange() end,
      fmt = function(v)
        if math.abs(v) < 0.04 then return "still" end
        return string.format("%s %.1fs", v > 0 and posLabel or negLabel, minRev / math.abs(v))
      end })
    attachTip(wd.strip, param.label, ("Left of centre runs %s, right runs %s; further out is faster. The centre is still."):format(negLabel, posLabel))
  elseif param.kind == "choice" then
    local opts = {}
    for _, ch in ipairs(param.choices) do opts[#opts + 1] = { value = ch[1], label = ch[2] } end
    wd = segCell(bf, param.label, opts, function() return animGet(id, param.key) end,
      function(v) animSet(id, param.key, v); onChange() end)
  else
    return nil
  end
  wd:SetPoint("TOPLEFT", x, -y)
  return wd
end

local function buildAnimsSection(bf, s)
  local blocks = {}
  local function apply() C:SetPreviewAnim(animTrigger); if GB.Anims then GB.Anims:Invalidate(animTrigger) end end

  local function currentSel()
    local t = GB.db and GB.db.triggers and GB.db.triggers[animTrigger]
    local found = "none"
    if t and t.anims and GB.Anims then
      GB.Anims:Each(function(mod) if t.anims[mod.id] and t.anims[mod.id].enabled then found = mod.id end end)
    end
    return found
  end
  local function options()
    local o = { { value = "none", label = "None" } }
    if GB.Anims then GB.Anims:Each(function(mod) o[#o + 1] = { value = mod.id, label = mod.label } end) end
    return o
  end
  local function labelFor(v) if v == "none" or not v then return "None" end local m = GB.Anims and GB.Anims:Get(v); return (m and m.label) or "None" end

  local st = UI.label(bf, "Glow State"); st:SetPoint("TOPLEFT", 50, 0)
  local chips = {}
  for i, tr in ipairs(ANIM_TRIGGERS) do
    local col, row = (i - 1) % 4, math.floor((i - 1) / 4)
    local b = UI.button(bf, tr[2], { kind = "action", w = 102 })   -- the mock: 102 wide, 112 apart, rows 27 apart, dark
    b:SetPoint("TOPLEFT", 50 + col * 112, -(18 + row * 27))
    chips[#chips + 1] = { b = b, k = tr[1] }
  end

  -- the module blocks: each module's params at the slots above
  if GB.Anims then
    GB.Anims:Each(function(mod)
      local prs, slot = {}, 1
      for _, param in ipairs(mod.params) do
        local x, y
        if param.kind == "color" then x, y = 243, 92
        elseif param.kind == "choice" then x, y = 50, 147
        elseif param.kind == "bispeed" then x, y = 348, 147
        else local sl = DIAL_SLOTS[slot] or DIAL_SLOTS[#DIAL_SLOTS]; x, y = sl[1], sl[2]; slot = slot + 1 end
        local pr = animParam(bf, mod.id, param, apply, x, y)
        if pr then prs[#prs + 1] = pr end
      end
      blocks[mod.id] = {
        setShown = function(on) for _, pr in ipairs(prs) do pr:SetShown(on) end end,
        refresh = function() for _, pr in ipairs(prs) do pr:refresh() end end,
      }
      blocks[mod.id].setShown(false)
    end)
  end

  local function selectAnim(v)
    local t = GB.db and GB.db.triggers and GB.db.triggers[animTrigger]
    if not t then return end
    t.anims = t.anims or {}
    if GB.Anims then GB.Anims:Each(function(mod)
      if mod.id == v then local d = animEnsure(mod.id); if d then d.enabled = true end
      elseif t.anims[mod.id] then t.anims[mod.id].enabled = false end
    end) end
    for id, blk in pairs(blocks) do blk.setShown(id == v) end
    if blocks[v] then blocks[v].refresh() end
    apply()
  end
  local dd = UI.cell(bf, "Animation", function(c)   -- the mock draws it as the white field picker
    return UI.pick(c, 163, function() return labelFor(currentSel()) end, options, currentSel, selectAnim, { kind = "field" })
  end)
  dd:SetPoint("TOPLEFT", 50, -92)
  bf:SetHeight(190)

  local function refreshForTrigger()
    dd:refresh()
    local cur = currentSel()
    for id, blk in pairs(blocks) do blk.setShown(id == cur) end
    if blocks[cur] then blocks[cur].refresh() end
    C:SetPreviewAnim(animTrigger)
  end
  local function selectTrigger(k) animTrigger = k; for _, c in ipairs(chips) do c.b:SetActive(c.k == k) end; refreshForTrigger() end
  for _, c in ipairs(chips) do c.b:SetScript("OnClick", function() selectTrigger(c.k) end) end

  s.refresh = function()
    for _, c in ipairs(chips) do c.b:SetActive(c.k == animTrigger) end
    refreshForTrigger()
  end
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

-- The rail's PRESET block (stage 3, the Shape mock): "Preset (Being Edited)"
-- on a faint 250 × 120 plate — a white 210px picker, then NEW · COPY / RENAME
-- · DELETE (amber) in two rows of 102. Same dialogs and delete gate as the
-- profile row: the kit's profileRow drives it, laid out 2 × 2 here.
local function buildRailPane(parent)
  local rail = CreateFrame("Frame", nil, parent)
  rail:SetPoint("TOPLEFT", 0, 0); rail:SetSize(RAIL_W, RAIL_TOP_H)
  local plate = rail:CreateTexture(nil, "BACKGROUND"); plate:SetAllPoints(); UI.tint(plate, COLOR.faint)

  local title = UI.label(rail, "Preset (Being Edited)"); title:SetPoint("TOPLEFT", 20, -18)
  local pick = UI.pick(rail, 210,
    editName,
    function()
      local prof = GB:ActiveProfile(); local o = {}
      for _, n in ipairs(sortedNames(prof and prof.presets)) do o[#o + 1] = { label = n, value = n } end
      return o
    end,
    editName,
    function(v) GB:SwitchPreset(v); C:Refresh() end,
    { kind = "field" })
  pick:SetPoint("TOPLEFT", 20, -34)
  attachTip(pick, "Preset being edited", "The look being edited — every control in the accordion edits this preset, and it saves automatically as you edit. Picking another preset swaps the whole look.")

  -- nameDialog ignores the callback's return; a refused name is said in chat.
  local function collision() GB.msg("a preset with that name already exists.") end
  local function newBtn(label, kind, x, y, onClick, tipT, tipB)
    local bt = UI.button(rail, label, { kind = kind, w = 102, onClick = onClick })
    bt:SetPoint("TOPLEFT", x, y); attachTip(bt, tipT, tipB); return bt
  end
  newBtn("New", "action", 20, -63, function()
    UI.nameDialog("New preset", "", function(name)
      if not name or name == "" then return end
      if not GB:CreatePreset(name) then return collision() end
      C:Refresh()
    end)
  end, "New preset", "Creates a preset starting as a copy of the current look, and makes it the one being edited.")
  newBtn("Copy", "action", 128, -63, function()
    UI.nameDialog("Copy preset", editName() .. " copy", function(name)
      if not name or name == "" then return end
      if not GB:CreatePreset(name) then return collision() end
      C:Refresh()
    end)
  end, "Copy preset", "A duplicate of the current look under a new name, which becomes the one being edited.")
  newBtn("Rename", "action", 20, -86, function()
    UI.nameDialog("Rename preset", editName(), function(name)
      if not name or name == "" then return end
      if not GB:RenamePreset(editName(), name) then return collision() end
      C:Refresh()
    end)
  end, "Rename preset", "Renames this preset. Bars assigned to it follow the new name.")
  newBtn("Delete", "warn", 128, -86, function()
    UI.confirm(("Delete the preset \"%s\"? Bars assigned to it fall back to another preset."):format(editName()), function()
      if not GB:DeletePreset(editName()) then GB.msg("can't delete the last preset.") end
      C:Refresh()
    end, "Delete", "Delete preset")
  end, "Delete preset", "Deletes this preset (you'll be asked to confirm). The last preset can't be deleted.")

  local railRefresh = function()
    pick:refresh()
    -- Re-point the preset-focus highlight at the newly-selected edit preset's bars
    -- (no-op if the highlight is off).
    if GB.Skin and GB.Skin.RefreshPresetHighlight then GB.Skin:RefreshPresetHighlight() end
  end
  C._railRefresh = railRefresh
end

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

local function buildLayoutSection(bf, s)
  -- ★ STAGE 3 (2026-09-21): the Bar Layout & Preset mock (`660:5304`), body-
  -- relative. The two controls the mocks give no home — the master ENABLE and
  -- the preset HIGHLIGHT — sit here too (the assistant's placement, flagged).
  local selBar = GB.BARS[1].buttonPrefix
  local chips = {}
  local w = {}
  local selectBar   -- fwd-declared

  local function data() return barLayoutData(selBar) end
  local function apply() if GB.Layout then GB.Layout:Reassert(selBar) end end

  -- ROW 0: Layout Control · Now Editing Bar: the ten chips · Gloom's Bars (enable)
  w.own = at(toggleCell(bf, "Layout Control", layoutOn,
    function(v)
      local prof = GB:ActiveProfile(); if prof then prof.layoutEnabled = v and true or false end
      if GB.Layout then GB.Layout:ApplyAll() end
      if GB.Skin and GB.Skin.RefreshEmptySlots then GB.Skin:RefreshEmptySlots() end
      s.refresh()
    end), 50, 0)
  attachTip(w.own.control, "Layout control", "On: this addon arranges ALL the bars, each with its settings below. Off: Edit Mode arranges everything, exactly as normal.")
  local nel = UI.label(bf, "Now Editing Bar:"); nel:SetPoint("TOPLEFT", 188, 0)
  local prev
  for _, bar in ipairs(GB.BARS) do
    local label = bar.key:match("^bar(%d+)$") and ("Bar " .. bar.key:match("^bar(%d+)$")) or bar.label:gsub(" Bar$", "")
    local chip = UI.button(bf, label, { kind = "action", padX = 6, onClick = function() selectBar(bar.buttonPrefix) end })   -- the mock's 47px "BAR 1", dark
    if prev then chip:SetPoint("LEFT", prev, "RIGHT", 6, 0) else chip:SetPoint("TOPLEFT", 188, -18) end
    chip:HookScript("OnEnter", function() if GB.Skin and GB.Skin.PingBar then GB.Skin:PingBar(bar.buttonPrefix, true) end end)
    chip:HookScript("OnLeave", function() if GB.Skin and GB.Skin.PingBar then GB.Skin:PingBar(bar.buttonPrefix, false) end end)
    attachTip(chip, bar.label, "Select this bar to edit its layout settings. Hovering pulses it on screen.")
    chips[#chips + 1] = { b = chip, k = bar.buttonPrefix }
    prev = chip
  end

  -- ROW 1: Style Preset · Visibility Rule · Empty Icons · Copy Layout From
  local VIS_OPTS = {
    { value = "default",  label = "Default" },
    { value = "show",     label = "Always Visible" },
    { value = "combat",   label = "In Combat" },
    { value = "nocombat", label = "Out of Combat" },
    { value = "hide",     label = "Hidden" },
  }
  local function visValue() local c = data(); return (c and c.vis) or "default" end
  local function visLabel()
    local v = visValue()
    for _, o in ipairs(VIS_OPTS) do if o.value == v then return o.label end end
    return "Default"
  end
  local function presetOptions()
    local prof = GB:ActiveProfile(); local o = {}
    for name in pairs((prof and prof.presets) or {}) do o[#o + 1] = { value = name, label = name } end
    table.sort(o, function(a2, b2) return a2.label < b2.label end)
    return o
  end
  local function barName() for _, bar in ipairs(GB.BARS) do if bar.buttonPrefix == selBar then return bar.label end end return "" end
  w.preset = at(pickCell(bf, "Style Preset", 170,
    function() local prof = GB:ActiveProfile(); return (prof and prof.bars and prof.bars[selBar]) or "?" end,
    presetOptions,
    function() local prof = GB:ActiveProfile(); return prof and prof.bars and prof.bars[selBar] end,
    function(v) GB:AssignBarPreset(selBar, v); s.refresh() end), 50, 55)
  attachTip(w.preset.control, "Style preset", "Which whole-look preset the selected bar wears. The preset being edited renders live as you tweak it; any other preset shows its saved look. Flyouts follow the bar they pop from.")
  w.vis = at(pickCell(bf, "Visibility Rule", 150, visLabel, function() return VIS_OPTS end, visValue,
    function(v)
      local c = ensureBarLayout(selBar)
      c.vis = (v ~= "default") and v or nil
      apply(); s.refresh()
    end), 250, 55)
  attachTip(w.vis.control, "Visibility", "Default follows Blizzard's rules (Edit Mode, mouseover, vehicles). Always Visible shows the bar even if Edit Mode has it disabled. In / Out of Combat show it only then. Hidden removes it. Game-driven hides always win.")
  w.empty = at(segCell(bf, "Empty Icons", { { value = true, label = "Show" }, { value = false, label = "Hide" } },
    function() local c = data(); return not (c and c.showEmpty == false) end,
    function(v)
      local c = ensureBarLayout(selBar)
      if v then c.showEmpty = nil else c.showEmpty = false end
      if GB.Skin and GB.Skin.RefreshEmptySlots then GB.Skin:RefreshEmptySlots() end
      apply()
    end, { padX = 10 }), 430, 55)   -- the mock's 98px bar
  attachTip(w.empty.control, "Empty icons", "Show: empty slots render normally — Blizzard's rules plus the Empty Slots section's treatment. Hide: buttons with no action disappear entirely; their spot in the grid stays reserved, and they reappear while you drag a spell.")
  w.copy = UI.cell(bf, "Copy Layout From", function(c)
    return UI.pick(c, 210, function() return "Pick a Bar" end,
      function()
        local o = {}
        for _, bar in ipairs(GB.BARS) do
          if bar.buttonPrefix ~= selBar then o[#o + 1] = { value = bar.buttonPrefix, label = bar.label } end
        end
        return o
      end,
      function() return nil end,
      function(v)
        local src = barLayoutData(v)
        if not src then return end
        local dst = ensureBarLayout(selBar)
        if not dst then return end
        dst.size, dst.gap, dst.rows = src.size, src.gap, src.rows
        dst.gapCross, dst.horizontal = src.gapCross, src.horizontal
        apply(); s.refresh()
      end, { kind = "field" })
  end)
  w.copy:SetPoint("TOPLEFT", 559, -55)
  attachTip(w.copy.control, "Copy layout", "Copies the picked bar's arrangement — button size, gap, rows, row gap, orientation — onto the selected bar. Its position, visibility, button count and empty-button settings stay as they are.")

  -- ROWS 2–3: the geometry
  w.size = at(UI.dial(bf, { label = "Icon Size", min = 24, max = 64, unit = "px",
    get = function() local c = data(); return (c and c.size) or 45 end,
    set = function(v) local c = ensureBarLayout(selBar); c.size = v; apply() end }), 50, 118)
  attachTip(w.size.strip, "Icon size", "Scales the WHOLE button proportionally — icon, text, glows — like Edit Mode's size setting. How the icon sits within its button is Shape & Icon's Size, saved in the preset.")
  w.gap = at(UI.dial(bf, { label = "Icon Gap", min = -32, max = 64, unit = "px", centre = true,
    get = function() local c = data(); return (c and c.gap) or 4 end,
    set = function(v) local c = ensureBarLayout(selBar); c.gap = v; apply() end }), 276, 118)
  w.count = at(UI.dial(bf, { label = "Total Icons", min = 1, max = 12,
    get = function() local c = data(); return (c and c.count) or 12 end,
    set = function(v) local c = ensureBarLayout(selBar); c.count = v; apply() end }), 502, 118)
  w.rows = at(UI.dial(bf, { label = "Rows", min = 1, max = 6,
    get = function() local c = data(); return (c and c.rows) or 1 end,
    set = function(v) local c = ensureBarLayout(selBar); c.rows = v; apply(); s.refresh() end }), 50, 173)
  w.rowGap = at(UI.dial(bf, { label = "Gap Between Rows", min = -32, max = 64, unit = "px", centre = true,
    get = function() local c = data(); return (c and (c.gapCross or c.gap)) or 4 end,
    set = function(v) local c = ensureBarLayout(selBar); c.gapCross = v; apply() end }), 276, 173)
  w.orient = at(segCell(bf, "Orientation", { { value = true, label = "Horizontal" }, { value = false, label = "Vertical" } },
    function() local c = data(); return not c or c.horizontal ~= false end,
    function(v) local c = ensureBarLayout(selBar); c.horizontal = v; apply() end, { padX = 9 }), 502, 173)   -- the mock's 156px bar

  -- the button row
  local mvBtn = UI.button(bf, "Move Bars", { kind = "action", w = 120, onClick = function()
    if GB.Layout then GB.Layout:SetMoveMode(not GB.Layout:MoveModeOn()) end
  end })
  mvBtn:SetPoint("TOPLEFT", 50, -257)
  attachTip(mvBtn, "Move Bars", "Drag any bar's overlay to reposition it. Click an overlay to select it, then nudge with the arrow keys — hold Shift for 10px steps. ESC or this button exits. Out of combat only.")
  local qkBtn = UI.button(bf, "Quick Keybind", { kind = "action", w = 120, onClick = openQuickKeybind })
  qkBtn:SetPoint("TOPLEFT", 180, -257)
  attachTip(qkBtn, "Quick Keybind", "Opens Blizzard's Quick Keybind mode: hover any action button and press a key to bind it, ESC when done. Out of combat only.")
  local rsBtn = UI.button(bf, "Reset Positions", { kind = "action", w = 120, onClick = function() if GB.Layout then GB.Layout:ResetPosition(selBar) end end })
  rsBtn:SetPoint("TOPLEFT", 310, -257)
  attachTip(rsBtn, "Reset Positions", "Returns the selected bar to wherever Edit Mode places it.")
  local hlBtn = UI.button(bf, "Highlight Preset's Bars", { kind = "action" })
  hlBtn:SetPoint("TOPLEFT", 440, -257)
  local function hlSync(on) hlBtn:SetActive(on) end
  hlBtn:SetScript("OnClick", function()
    if not (GB.Skin and GB.Skin.SetPresetHighlight) then return end
    hlSync(GB.Skin:SetPresetHighlight(not GB.Skin:SetPresetHighlight()))   -- toggle (query then flip)
  end)
  attachTip(hlBtn, "Highlight bars using current preset", "Puts a translucent block behind every bar that wears the preset you're currently editing, so it's clear which bars your changes affect. Stays on with this window closed and through combat. Resets off when you log in.")
  C._hlSync = hlSync
  -- The master switch (the owner's placement, 2026-09-21: the button row's end).
  w.enable = at(toggleCell(bf, "Gloom's Bars",
    function() return GB.Skin and GB.Skin.enabled end,
    function(v) if not GB.Skin then return end; if v then GB.Skin:Enable() else GB.Skin:Disable() end end), 660, 239)
  attachTip(w.enable.control, "Gloom's Bars", "The master switch: Off returns every bar to Blizzard's own look and layout.")
  C._enableToggle = w.enable.control
  local function mvSync()
    local moving = (GB.Layout and GB.Layout.MoveModeOn and GB.Layout:MoveModeOn()) or false
    mvBtn:SetActive(moving)
    mvBtn:SetLabel(moving and "Lock Bars" or "Move Bars")   -- the owner: the button names the NEXT action
  end
  C._mvFooterSync = mvSync

  selectBar = function(k)
    selBar = k
    for _, c in ipairs(chips) do c.b:SetActive(c.k == k) end
    s.refresh()
  end
  -- The mock suffixes the per-bar labels with the bar: "Icon Size (Bar 1)".
  local perBar = { { w.preset, "Style Preset" }, { w.vis, "Visibility Rule" }, { w.size, "Icon Size" }, { w.gap, "Icon Gap" },
                   { w.count, "Total Icons" }, { w.rows, "Rows" }, { w.rowGap, "Gap Between Rows" }, { w.orient, "Orientation" } }
  local function barShort() for _, bar in ipairs(GB.BARS) do if bar.buttonPrefix == selBar then
    return bar.key:match("^bar(%d+)$") and ("Bar " .. bar.key:match("^bar(%d+)$")) or bar.label:gsub(" Bar$", "") end end return "" end

  bf:SetHeight(280)
  s.refresh = function()
    for _, c in ipairs(chips) do c.b:SetActive(c.k == selBar) end
    local on = layoutOn()
    local short = barShort()
    for _, e in ipairs(perBar) do e[1].label:SetText(("%s (%s)"):format(e[2], short)) end
    for _, c in pairs(w) do c:refresh() end
    for _, name in ipairs({ "vis", "empty", "copy", "size", "gap", "count", "rows", "rowGap", "orient" }) do w[name]:setEnabled(on) end
    local c = data()
    w.rowGap:setEnabled(on and ((c and (c.rows or 1) or 1) > 1))
    mvSync(); mvBtn:SetEnabled(on); rsBtn:SetEnabled(on)
    if GB.Skin and GB.Skin.SetPresetHighlight then hlSync(GB.Skin:SetPresetHighlight()) end
  end
end

-- The PREVIEW pane (stage 3, the Shape mock): the rail's lower part, the one
-- dark surface (#1e1e1e) — "Preview" in white, the 13 state buttons two
-- across (102 wide, 21 apart), the construction, then the state's name, its
-- description and the "Styled in:" links in lilac.
local function buildPreviewPane(parent)
  local pane = CreateFrame("Frame", nil, parent)
  pane:SetPoint("TOPLEFT", 0, -RAIL_TOP_H)
  pane:SetPoint("BOTTOMLEFT", 0, 0)
  pane:SetWidth(RAIL_W)
  local plate = pane:CreateTexture(nil, "BACKGROUND"); plate:SetAllPoints(); plate:SetColorTexture(0x1e / 255, 0x1e / 255, 0x1e / 255, 1)

  local eb = newText(pane, FONT.uiB, 14, COLOR.paper, "LEFT"); eb:SetPoint("TOPLEFT", 20, -27); eb:SetText("Preview")

  -- state buttons (2 columns × 7 rows)
  previewChips = {}
  for i, st in ipairs(PREVIEW_STATES) do
    local col, row = (i - 1) % 2, math.floor((i - 1) / 2)
    local chip = UI.button(pane, st[2], { kind = "action", w = 102, onClick = function() C:SetPreviewState(st[1]) end })   -- dark, violet when current (the mock)
    chip:SetPoint("TOPLEFT", 20 + col * 106, -49 - row * 21)   -- 22 under the title's glyphs (the owner: more room)
    previewChips[st[1]] = chip
  end

  -- Sample construction. The icon is 104px; the whole construction (icon +
  -- plate) is centered at PREVIEW_CENTER_Y and RefreshPreview re-anchors it as
  -- the extension grows, so nothing floats. (Initial anchor is overwritten there.)
  local frame = CreateFrame("Frame", nil, pane); frame:SetSize(104, 104)
  frame:SetPoint("CENTER", pane, "TOP", 0, PREVIEW_CENTER_Y)
  previewFrame = frame
  -- Live pulse for the pulsing chips (proc/flash): breathe the multi-part glow's
  -- alpha about its peak at the current Pulse-speed, mirroring Glows.lua's driver, so
  -- the slider has a visible effect. Runs only while the window (this frame) is shown.
  frame:SetScript("OnUpdate", function(_, dt)
    if not previewPulsing then return end
    previewPulsePhase = previewPulsePhase + dt * math.max(0.1, (GB.db and GB.db.glowPulseSpeed) or 1)
    local a = previewPulsePeak * (PREVIEW_PULSE_DEPTH + (1 - PREVIEW_PULSE_DEPTH) * (0.5 + 0.5 * math.cos(previewPulsePhase * 5.7)))
    if previewOuter:IsShown() then previewOuter:SetAlpha(a) end
    if previewInner:IsShown() then previewInner:SetAlpha(a) end
  end)
  previewGlow = frame:CreateTexture(nil, "BACKGROUND"); previewGlow:SetPoint("TOPLEFT", -16, 16); previewGlow:SetPoint("BOTTOMRIGHT", 16, -16)
  previewGlow:SetBlendMode("ADD"); previewGlow:SetVertexColor(1, 0.77, 0.30); previewGlow:Hide()
  -- Multi-part shaped glow (hand shapes): outer bloom UNDER the icon, inner rim OVER
  -- the plate — mirrors the bars (Glows.lua) so the Proc/Hover/Selected/Flash chips
  -- show the real glow, honouring each trigger's colour / opacity / layers.
  previewOuter = frame:CreateTexture(nil, "BACKGROUND", nil, -1); previewOuter:SetBlendMode("BLEND"); previewOuter:Hide()
  previewInner = frame:CreateTexture(nil, "OVERLAY"); previewInner:SetBlendMode("BLEND"); previewInner:Hide()
  previewIcon = frame:CreateTexture(nil, "ARTWORK"); previewIcon:SetAllPoints()
  previewCD = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate"); previewCD:SetAllPoints(previewIcon)
  previewCD:SetDrawEdge(false); previewCD:SetDrawBling(false); previewCD:Hide()
  -- No countdown number on the preview sweep: it ignores the Text→Countdown
  -- styling and the enlarged preview makes its size/position wrong anyway (the owner).
  if previewCD.SetHideCountdownNumbers then previewCD:SetHideCountdownNumbers(true) end
  previewRing = frame:CreateTexture(nil, "OVERLAY"); previewRing:SetPoint("TOPLEFT", -4, 4); previewRing:SetPoint("BOTTOMRIGHT", 4, -4)
  previewRing:SetBlendMode("ADD"); previewRing:Hide()
  previewBorder = frame:CreateTexture(nil, "BACKGROUND", nil, -2)   -- behind the icon; peeks out as the border
  previewBorder:SetTexture("Interface\\Buttons\\WHITE8X8"); previewBorder:Hide()
  -- Finish-flash preview: an expanding shape-glow burst that fades out, mirroring
  -- the engine's setupFinishFlash so the flash colour/shape is visible without a
  -- real cooldown. Frame is anchored over the construction at play time (so the
  -- scale bursts from centre); the texture fills the frame.
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
  -- (CastFillOnUpdate geometry — cast fills up, channel drains; colour / alpha /
  -- direction from the same db fields the engine reads). Shown by the Cast /
  -- Channel chips; anchored + masked per-refresh in RefreshPreview.
  previewCastFillFrame = CreateFrame("Frame", nil, frame)
  previewCastFillFrame:SetFrameLevel(frame:GetFrameLevel() + 4)   -- above plates/glows, below the flash burst (+5)
  previewCastFillFrame.tex = previewCastFillFrame:CreateTexture(nil, "OVERLAY")
  previewCastFillFrame.tex:SetTexture("Interface\\Buttons\\WHITE8X8")   -- maskable (masks don't clip SetColorTexture)
  previewCastFillFrame:SetScript("OnUpdate", function(f)
    -- No completion burst at the wrap: the real one is Blizzard's own EndBurst
    -- animation (replayed inside their widget on the bars) and can't be cloned
    -- faithfully here — the owner: better none than a lookalike (session 12).
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

  -- Caption = a bold state-name heading (GeneralSans-Semibold) + the description
  -- body. The body lives on its own mouse-enabled frame with hyperlinks on:
  -- section names are |Hgbsec:*|h links (caret orange) that open that accordion
  -- section. RefreshPreview re-anchors both below the construction.
  -- The caption sits at the mock's fixed y (354 under the pane's top), inset 20
  -- each side — fixed anchors, so nothing about the construction's height can
  -- shift it (an over-constrained TOP + LEFT + RIGHT drifted it left).
  local head = newText(pane, FONT.uiB, 12, COLOR.paper, "LEFT")
  head:SetJustifyH("LEFT"); head:SetText("")
  head:SetPoint("TOPLEFT", pane, "TOPLEFT", 20, -354); head:SetPoint("TOPRIGHT", pane, "TOPRIGHT", -20, -354)
  previewCaptionHead = head
  local cap = newText(pane, FONT.ui, 11, COLOR.paper, "LEFT")
  cap:SetJustifyH("LEFT"); cap:SetText(PREVIEW_CAPTION_DEFAULT)
  cap:SetPoint("TOPLEFT", head, "BOTTOMLEFT", 0, -3); cap:SetPoint("TOPRIGHT", head, "BOTTOMRIGHT", 0, -3)
  previewCaption = cap
  -- The "Styled in:" bullet list — bold (Semibold), on its own mouse-enabled
  -- hyperlink frame; clicking an orange section name opens that section.
  local capFrame = CreateFrame("Frame", nil, pane)
  capFrame:SetHyperlinksEnabled(true)
  capFrame:EnableMouse(true)
  capFrame:SetScript("OnHyperlinkClick", function(_, link)
    local title = link and link:match("^gbsec:(.+)$")
    if not title then return end
    local st = previewState
    C:OpenSection(title)
    C:SetPreviewState(st)   -- some sections hijack the preview on open (Glows → proc); restore the clicked state
  end)
  local links = newText(capFrame, FONT.ui, 11, COLOR.paper, "LEFT")
  links:SetJustifyH("LEFT"); links:SetSpacing(2); links:SetText("")
  links:SetPoint("TOPLEFT", cap, "BOTTOMLEFT", 0, -12); links:SetPoint("TOPRIGHT", cap, "BOTTOMRIGHT", 0, -12)
  previewCaptionLinks = links
  capFrame:SetAllPoints(links)   -- the click surface tracks the list's rect
end

-- Phase C: the standalone window (GloomsBarsConfig — chrome, title bar, drag,
-- glow, edges, UISpecialFrames entry) is DELETED. The shell owns the window;
-- this builds the Bars tab's content INSIDE the shell-provided container.
local function BuildTab(c)
  container = c

  -- The rail: the preset block over the preview pane; the accordion fills the rest.
  buildRailPane(c)
  buildPreviewPane(c)

  -- Body: a scroll frame holding the accordion.
  local scroll = CreateFrame("ScrollFrame", nil, c)
  contentScroll = scroll   -- module ref: ToggleSection scrolls the opened section near the top
  scroll:SetPoint("TOPLEFT", RAIL_W, -20)   -- 20 above the first header (the owner, 2026-09-21)
  scroll:SetPoint("BOTTOMRIGHT", -24, FOOTER_H)
  scroll:EnableMouseWheel(true)
  scroll:SetScript("OnMouseWheel", function(self, delta)
    local range = self:GetVerticalScrollRange()
    self:SetVerticalScroll(math.max(0, math.min(range, self:GetVerticalScroll() - delta * 42)))
  end)
  bodyContainer = CreateFrame("Frame", nil, scroll)
  bodyContainer:SetSize(math.max(10, scroll:GetWidth()), 10)
  scroll:SetScrollChild(bodyContainer)
  scroll:SetScript("OnSizeChanged", function(self, w)
    if w and w > 0 then bodyContainer:SetWidth(w) end
  end)
  makeScrollbar(c, scroll, function(b)
    b:SetPoint("TOPRIGHT", -8, -2); b:SetPoint("BOTTOMRIGHT", -8, FOOTER_H + 2)
  end, { kit = true })

  -- Sections (mockup order). Profiles/presets live in the left rail now — the
  -- accordion holds the per-preset styling + bar controls.
  makeSection("Shape & Icon", buildShapeSection)
  makeSection("Plate Construction", buildPlateSection)
  makeSection("Decoration Layers", buildDecorSection)
  makeSection("Text", buildTextSection)
  makeSection("Glows", buildGlowsSection)
  makeSection("Animations", buildAnimsSection)
  makeSection("Cast & Channel", buildCastSection)
  makeSection("Cooldown & Availability", buildCooldownSection)
  makeSection("Empty Slots", buildEmptySection)
  makeSection("Bar Layout & Preset", buildLayoutSection)

  -- All sections start CLOSED (the owner 2026-07-20 — easier to find the one you want
  -- than scrolling past a large open panel).
  relayout()

  -- (Escape-close is the SHELL's job now — GloomsSuiteWindow sits in
  -- UISpecialFrames; the old GloomsBarsConfig entry is gone with the window.)

  -- Exiting the addon RELOCKS the bars (the owner): however the Bars UI goes away
  -- — the window's X, ESC, /gb, or another tab taking focus — move mode ends
  -- with it, so movers never outlive the editor. OnHide fires on EFFECTIVE
  -- visibility, so hiding the Suite window triggers it too, not just a tab
  -- switch hiding this container directly.
  c:HookScript("OnHide", function()
    if GB.Layout and GB.Layout:MoveModeOn() then GB.Layout:SetMoveMode(false) end
  end)
  C:RefreshPreview()
  C:SetPreviewState("idle")
end

function C:Refresh()
  if not container then return end
  if C._enableToggle then C._enableToggle:refresh() end
  if C._railRefresh then C._railRefresh() end
  for _, s in ipairs(sections) do if s.refresh then s.refresh() end end
  -- Keep the footer Move-bars button in step with the section button + auto-exits
  -- (combat/ESC route through SetMoveMode → C:Refresh); highlight follows too.
  if C._mvFooterSync then C._mvFooterSync() end
  if C._hlSync and GB.Skin and GB.Skin.SetPresetHighlight then C._hlSync(GB.Skin:SetPresetHighlight()) end
  C:RefreshPreview()
  C:SetPreviewState(previewState)
end

-- C:Toggle() is GONE (Phase C, locked decision: hard dependency, no second
-- window path). /gb's config branch and the minimap button both route through
-- GloomsHub:ToggleWindow("bars") — the shell owns open/close/switch semantics.

-- Mount the Bars tab (CONTRACTS §2). Registration is cheap and immediate;
-- BuildTab runs ONCE, lazily, the first time the tab is shown. `refresh`
-- fires on every focus so live state (footer toggles, rail, preview) re-syncs.
GloomsHub:RegisterTab{
  id       = "bars",
  title    = "BARS",
  order    = 20,
  wordmark = "BARS",
  profile  = PROFILE_API,
  build    = BuildTab,
  refresh  = function() C:Refresh() end,
}
