-- Icons.lua — per-action icon overrides (GB.Icons)
--
-- Swap the icon art on OUR action buttons ONLY, without touching the rest of the
-- game. A custom icon pack dropped into Interface/ICONS is GLOBAL: the same .tga
-- feeds bags, the spellbook, tooltips and the Cooldown Manager, so re-framing an
-- icon to survive a wide button's crop re-frames it everywhere. This is the
-- GB-only alternative — art registered here is seen by nothing but the bars, so
-- it can be padded to exactly the margin the bar's aspect needs.
--
-- ★ KEYED BY spellID / itemID, NOT by art filename. GetActionTexture returns a
-- fileDataID in modern retail, not "INV_Mace_104", so keying by art name would
-- need a ~32k fileDataID↔name table shipped in the addon. GetActionInfo gives us
-- the spellID directly, and it is the same number the owner's tooltips already
-- show — so the key is readable straight off the screen.
--
-- ⚠ WoW exposes NO filesystem API, so we CANNOT test whether an override file
-- exists. That is exactly why this is an explicit opt-in table and not a folder
-- scan: an entry means "I made this file". A missing file draws a blank icon —
-- that is the one failure mode to expect, and it is not an error you will see in
-- BugSack. Same hazard class as the Hub's Media tab registering a dead font path
-- (which is why GB.SetFontSafe exists).

local GB = _G.GloomsBars

local Icons = {}
GB.Icons = Icons

-- Personal icon art lives OUTSIDE Media/ and is gitignored. Media/ holds GB's own
-- design assets and IS tracked; the owner's art must never be (see .gitignore).
local ICON_DIR = "Interface\\AddOns\\GloomsBars\\IconsHD\\"

-- Global, not per-preset: a spellID means the same thing in every preset, and the
-- art you drew for Aimed Shot should not vanish when you switch looks. Created
-- lazily rather than seeded in Core's defaults so it stays out of the preset
-- copy/migration machinery entirely.
local function store()
  if not GB.db then return nil end
  GB.db.iconOverrides = GB.db.iconOverrides or {}
  return GB.db.iconOverrides
end

-- "spell:264735" / "item:6948", or nil for an empty/unmappable slot.
-- pcall'd: GetActionInfo is not a secret combat value (it is what YOU put on the
-- bar, not a cooldown or charge count), but this runs on every button refresh
-- including across the combat edge, and a cosmetic swap must never be the thing
-- that throws. 12.1 taught us what a silent read failure costs.
local function keyForSlot(slot)
  if not slot then return nil end
  local ok, kind, id = pcall(GetActionInfo, slot)
  if not (ok and kind and id) then return nil end
  if kind == "spell" then return "spell:" .. id end
  if kind == "item" then return "item:" .. id end
  if kind == "macro" then
    -- A macro's icon follows whatever spell it currently casts, so key on that.
    local ok2, sid = pcall(GetMacroSpell, id)
    if ok2 and sid then return "spell:" .. sid end
  end
  return nil
end

function Icons:KeyFor(btn)
  return btn and keyForSlot(btn.action) or nil
end

-- TWO sources, explicit override first. The generated manifest
-- (IconsManifest.lua, from tools/build-icon-manifest.sh) is what SCALES — drop
-- files named by spellID into IconsHD/, run the script, /reload. `/gb icon` stays
-- for one-offs and for files you'd rather name something arbitrary, and it wins
-- so a quick experiment can always beat what the scanner found.
function Icons:PathFor(btn)
  local key = self:KeyFor(btn)
  if not key then return nil end
  local t = store()
  local file = (t and t[key]) or (GB.ICON_MANIFEST and GB.ICON_MANIFEST[key])
  return file and (ICON_DIR .. file) or nil
end

-- Called from Skin.lua's per-button Update / UpdateButtonArt hooks (Blizzard has
-- just re-set the icon) and once from ApplyButton. ★ With no override we do NOT
-- touch the icon at all — Blizzard's art stands exactly as it was.
function Icons:Apply(btn)
  local icon = btn and (btn.icon or btn.Icon)
  if not icon then return end
  local path = self:PathFor(btn)
  if path then icon:SetTexture(path) end
end

-- Re-run every button. CLEARING an override needs the original art put back, and
-- Blizzard will not re-set it until the slot next changes — so restore it here
-- rather than making the owner swap the button out and back.
function Icons:RefreshAll()
  if not GB.ForEachButton then return end
  GB:ForEachButton(function(btn)
    local icon = btn.icon or btn.Icon
    if not icon then return end
    local path = Icons:PathFor(btn)
    if path then
      icon:SetTexture(path)
    elseif btn.action then
      local ok, tex = pcall(GetActionTexture, btn.action)
      if ok and tex then icon:SetTexture(tex) end
    end
  end)
end

-- You cannot hover a button and type a slash command at the same time, so
-- `/gb icon <file>` acts on the last button the pointer ENTERED, not the one
-- under the cursor when you hit Enter.
function Icons:HookButton(btn)
  if not btn or btn.gbIconHooked then return end
  btn.gbIconHooked = true
  btn:HookScript("OnEnter", function(b) Icons.lastHovered = b end)
end

--------------------------------------------------------------------------------
-- /gb icon …
--------------------------------------------------------------------------------

local function usage()
  GB.msg("icon overrides — GB action bars only:")
  print("  |cff936bff/gb icon <file.tga>|r          override the LAST BUTTON YOU HOVERED")
  print("  |cff936bff/gb icon <spellID> <file>|r    override that spell explicitly")
  print("  |cff936bff/gb icon clear|r               clear the last hovered button")
  print("  |cff936bff/gb icon clear <spellID>|r     clear that spell")
  print("  |cff936bff/gb icon list|r                list every override")
  print("  files live in |cff936bffIconsHD\\|r inside the GloomsBars folder.")
  print("  |cff808080for MANY icons: name them class_spec_name_<spellID>.tga (the ID is|r")
  print("  |cff808080the LAST segment), drop them in IconsHD\\, double-click|r")
  print("  |cff808080\"Rebuild Icons.command\", then /reload.|r")
end

local function describe(key)
  local kind, id = key:match("^(%a+):(%d+)$")
  id = tonumber(id)
  if not id then return key end
  if kind == "spell" then
    local info = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(id)
    return (info and info.name or "spell") .. " (" .. id .. ")"
  end
  local iname = C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(id)
  return (iname or "item") .. " (" .. id .. ")"
end

function Icons:Command(rest)
  rest = (rest or ""):match("^%s*(.-)%s*$")
  local t = store()
  if not t then GB.msg("saved variables aren't ready yet."); return end

  local head = (rest:match("^(%S+)") or ""):lower()

  if rest == "" or head == "help" then usage(); return end

  if head == "list" then
    local n, m = 0, 0
    for key, file in pairs(t) do
      n = n + 1
      print(("  |cff936bff%s|r → %s  |cff808080(override)|r"):format(describe(key), file))
    end
    for key, file in pairs(GB.ICON_MANIFEST or {}) do
      if not t[key] then
        m = m + 1
        print(("  |cff936bff%s|r → %s  |cff808080(manifest)|r"):format(describe(key), file))
      end
    end
    if n + m == 0 then GB.msg("no icon overrides set.")
    else GB.msg(("%d override(s), %d from the manifest."):format(n, m)) end
    return
  end

  if head == "clear" then
    local id = rest:match("^%S+%s+(%d+)$")
    local key = id and ("spell:" .. id) or (self.lastHovered and self:KeyFor(self.lastHovered))
    if not key then GB.msg("hover an action button first, or give a spellID."); return end
    if not t[key] then GB.msg("no override on " .. describe(key) .. "."); return end
    t[key] = nil
    self:RefreshAll()
    -- Clearing removes only the EXPLICIT override. If the manifest also lists this
    -- spell, the icon does not go back to Blizzard's — say so rather than let it
    -- look like the clear silently failed.
    local mf = GB.ICON_MANIFEST and GB.ICON_MANIFEST[key]
    if mf then
      GB.msg("cleared the override on " .. describe(key) .. " — the manifest entry (" .. mf .. ") applies now.")
      print("  to remove it entirely: delete the file from IconsHD\\ and re-run tools/build-icon-manifest.sh")
    else
      GB.msg("cleared " .. describe(key) .. ".")
    end
    return
  end

  -- <spellID> <file>
  local id, file = rest:match("^(%d+)%s+(%S+)$")
  if not id then
    -- <file> → the last hovered button
    file = rest:match("^(%S+)$")
    if not file then usage(); return end
    if not self.lastHovered then GB.msg("hover an action button first, then run this again."); return end
    local key = self:KeyFor(self.lastHovered)
    if not key then GB.msg("that button is empty, or its action can't be keyed."); return end
    t[key] = file
    self:RefreshAll()
    GB.msg(("%s → %s"):format(describe(key), file))
    return
  end

  t["spell:" .. id] = file
  self:RefreshAll()
  GB.msg(("%s → %s"):format(describe("spell:" .. id), file))
end
