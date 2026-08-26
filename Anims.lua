-- Anims.lua — Gloom's Bars per-trigger ANIMATION WIRING (GB.Anims).
--
-- ★ THE MODULES THEMSELVES MOVED TO GLOOMSHUB (2026-08-25) — they are
-- GloomsHub.Effects now, so Gloom's Auras can render the same eight animations on
-- its aura displays. They were always host-agnostic (Start/Stop keyed by host
-- frame, "a button, OR the Config preview frame"), which is what made the move a
-- rewiring of paths rather than a rewrite.
--
-- What stays HERE is everything that is genuinely GB's: which button "trigger"
-- (proc/cast/channel/hover/selected/flash/assist) runs which animation, the
-- per-trigger saved params in GB.db, and the reconcile loop over GB's buttons.
-- GB.Anims keeps its exact old surface — Get / Each / Params / Enabled /
-- Reconcile / Invalidate / PreviewReconcile — so Config.lua and Glows.lua did not
-- change at all.
--
-- Adding an animation = register a new module in GloomsHub/Effects.lua; the data
-- model and the Config UI still pick it up generically from its schema.

local GB = _G.GloomsBars

local Anims = {}
GB.Anims = Anims

-- ⚠ Resolved per call, never cached at load: this is ENGINE code and must degrade,
-- not error, against a Hub too old to carry the engine (CONTRACTS §6). With no
-- Effects table every accessor below returns empty and `Reconcile` simply runs
-- nothing — bars keep working, they just stop animating. Config.lua's version gate
-- is what actually tells the user to update the Hub.
local function E() return _G.GloomsHub and _G.GloomsHub.Effects end

function Anims:Get(id) local e = E(); return e and e:Get(id) or nil end
function Anims:Each(fn) local e = E(); if e then e:Each(fn) end end

-- A trigger's saved params for animation `id`, merged over the module defaults so
-- the engine + UI always see a full set. nil if the module is unknown.
function Anims:Params(trigger, id)
  local e = E(); if not e then return nil end
  return e:MergeParams(id, trigger and trigger.anims and trigger.anims[id])
end
function Anims:Enabled(trigger, id)
  local saved = trigger and trigger.anims and trigger.anims[id]
  return saved and saved.enabled and true or false
end

-- The module ids, in registration order. Replaces the old local `self.order`, which
-- lived here when the modules did.
local function eachID(fn)
  local e = E(); if not e then return end
  for _, id in ipairs(e.order) do fn(id, e.modules[id]) end
end

-- Reconcile a BUTTON's animations to its winning glow trigger (called from
-- Glows:Refresh with the winning trigger key + record, or nil). Skips when the winner
-- is unchanged (Refresh fires often); Anims:Invalidate forces a re-run after edits.
local activeState = {}   -- [btn] = { key = <triggerKey>, [animId] = true }
function Anims:Reconcile(btn, triggerKey, trigger)
  local st = activeState[btn]
  if not st then st = {}; activeState[btn] = st end
  if st.key == triggerKey then return end
  st.key = triggerKey
  -- In plate mode the animation spans the full 2:1 plate (ConstructRef), not the half icon.
  local icon = (GB.Skin and GB.Skin.ConstructRef and GB.Skin:ConstructRef(btn)) or btn.icon or btn.Icon
  local key = (GB.Skin and GB.Skin.ShapeKeyFor and GB.Skin:ShapeKeyFor(btn)) or (GB.db and GB.db.handShape)
  eachID(function(id, mod)
    local want = triggerKey and trigger and self:Enabled(trigger, id) and icon and key
    if want then mod:Start(btn, icon, key, self:Params(trigger, id)); st[id] = true
    elseif st[id] then mod:Stop(btn); st[id] = nil end
  end)
end

-- After a Config edit to `triggerKey`'s params, drop the cached winner on bars showing
-- it so the next Refresh re-reconciles with the new values (live bars, no combat wait).
function Anims:Invalidate(triggerKey)
  for _, st in pairs(activeState) do
    if st.key == triggerKey then st.key = nil end
  end
  if GB.Glows and GB.Glows.RefreshTrigger then GB.Glows:RefreshTrigger(triggerKey) end
end

-- Config PREVIEW: run the selected trigger's enabled animations on the preview host
-- (previewFrame/previewIcon), stop the rest. Same modules as the bars — host-keyed.
function Anims:PreviewReconcile(host, icon, key, trigger)
  eachID(function(id, mod)
    if trigger and icon and key and self:Enabled(trigger, id) then
      mod:Start(host, icon, key, self:Params(trigger, id))
    else
      mod:Stop(host)
    end
  end)
end
