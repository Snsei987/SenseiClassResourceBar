local addonName = ...
local Core = {}

-- =========================
-- CONFIG (hardcoded)
-- =========================
local IW_MAX_STACKS = 4
local IW_DURATION   = 20

-- Bars appearance 
local BAR_W, BAR_H  = 80, 18
local BAR_SPACING   = 6
local OFFSET_X, OFFSET_Y = 0, -100

-- Required behaviors
local SHOW_ONLY_IN_COMBAT = true
local HIDE_WHEN_NO_STACKS = true

-- Talents
local REQUIRED_TALENT_ID = 12950   -- Improved Whirlwind talent . WITHOUT tracker is not working
local UNHINGED_TALENT_ID = 386628  -- Unhinged  - if enabled -> BT will not consume stacks during Bladestorm

-- Generators
local GENERATOR_IDS = {
  [190411] = true, -- Whirlwind
  [6343]   = true, -- Thunder Clap
  [435222] = true, -- Thunder Blast
}

-- Spenders consume
local SPENDER_IDS = {
  [23881]  = true, -- Bloodthirst
  [85288]  = true, -- Raging Blow
  [280735] = true, -- Execute
  [202168] = true, -- Impending Victory
  [184367] = true, -- Rampage
  [335096] = true, -- Bloodbath
  [335097] = true, -- Crushing Blow
  [5308]   = true, -- Execute (base)
}

-- =========================
-- STATE
-- =========================
local iwStacks    = 0
local iwExpiresAt = nil

local playerInCombat     = false
local hasRequiredTalent  = false
local noConsumeUntil     = 0
local seenCastGUID       = {}

-- module flags
local enabled = true

-- =========================
-- UTILS
-- =========================
local function IsFuryWarrior()
  local _, class = UnitClass("player")
  if class ~= "WARRIOR" then return false end
  local specIndex = GetSpecialization()
  if not specIndex then return false end
  local specID = GetSpecializationInfo(specIndex)
  return specID == 72
end

local function HasUnhingedTalent()
  return IsPlayerSpell and IsPlayerSpell(UNHINGED_TALENT_ID) or false
end

local function UpdateTalentState()
  hasRequiredTalent = (IsPlayerSpell and IsPlayerSpell(REQUIRED_TALENT_ID)) or false
end


local function IsSpellInTargetRange(spellID)
  if C_Spell and C_Spell.IsSpellInRange then
    local ok = C_Spell.IsSpellInRange(spellID, "target")
    if ok == true then return true end
    if ok == false then return false end
    if type(CheckInteractDistance) == "function" then
      return CheckInteractDistance("target", 3) == true
    end
    return false
  end
  return true 
end


-- =========================
-- BARS (minimal Ui render)
-- =========================
local barFrame
local bars = {}

local function CreateBars()
  if barFrame then return end

  barFrame = CreateFrame("Frame", "IWT_CoreBarsFrame", UIParent)
  barFrame:SetPoint("CENTER", UIParent, "CENTER", OFFSET_X, OFFSET_Y)
  barFrame:SetSize((BAR_W * IW_MAX_STACKS) + (BAR_SPACING * (IW_MAX_STACKS - 1)), BAR_H)
  barFrame:EnableMouse(false)
  barFrame:Hide()

  for i = 1, IW_MAX_STACKS do
    local bar = CreateFrame("StatusBar", nil, barFrame)
    bar:SetSize(BAR_W, BAR_H)
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(1)
    bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")

    if i == 1 then
      bar:SetPoint("LEFT", barFrame, "LEFT", 0, 0)
    else
      bar:SetPoint("LEFT", bars[i-1], "RIGHT", BAR_SPACING, 0)
    end

    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(true)
    bg:SetColorTexture(0, 0, 0, 0.7)
    bar.bg = bg

    bars[i] = bar
  end
end

local function SetBarsVisual(stacks)
  stacks = math.min(stacks or 0, IW_MAX_STACKS)
  for i = 1, IW_MAX_STACKS do
    local bar = bars[i]
    if bar then
      local active = (i <= stacks)
      local tex = bar:GetStatusBarTexture()
      if tex then
        if active then
          tex:SetVertexColor(0.2, 0.8, 0.2, 1)
        else
          tex:SetVertexColor(0, 0, 0, 1)
        end
      end
      bar:Show()
    end
  end
end

local function UpdateBars()
  if not barFrame then return end

  if not enabled then
    barFrame:Hide()
    return
  end

  if not IsFuryWarrior() or not hasRequiredTalent then
    barFrame:Hide()
    return
  end

  local stacks = math.min(iwStacks or 0, IW_MAX_STACKS)

  if SHOW_ONLY_IN_COMBAT and (not playerInCombat) and stacks <= 0 then
    barFrame:Hide()
    return
  end

  if HIDE_WHEN_NO_STACKS and stacks <= 0 then
    barFrame:Hide()
    return
  end

  barFrame:Show()
  SetBarsVisual(stacks)
end

-- =========================
-- CORE LOGIC (exportable)
-- =========================
function Core.GetStacks()
  return iwStacks or 0, iwExpiresAt
end

function Core.Reset()
  iwStacks = 0
  iwExpiresAt = nil
  UpdateBars()
end

local function GainIWStacks()
  iwStacks = IW_MAX_STACKS
  iwExpiresAt = GetTime() + IW_DURATION
  UpdateBars()
end

local function ConsumeIWStacks()
  if (iwStacks or 0) <= 0 then return end
  iwStacks = math.max(0, (iwStacks or 0) - 1)
  if iwStacks == 0 then iwExpiresAt = nil end
  UpdateBars()
end

-- THIS is Optional:  other addon can move the bars without any UI
function Core.SetAnchor(point, relFrame, relPoint, x, y)
  if not barFrame then return end
  barFrame:ClearAllPoints()
  barFrame:SetPoint(point or "CENTER", relFrame or UIParent, relPoint or "CENTER", x or 0, y or 0)
end

function Core.SetEnabled(on)
  enabled = (on ~= false)
  UpdateBars()
end

-- =========================
-- EVENTS
-- =========================
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
eventFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
eventFrame:RegisterEvent("ACTIVE_PLAYER_SPECIALIZATION_CHANGED")
eventFrame:RegisterEvent("TRAIT_CONFIG_UPDATED")

-- timer expiry (minimal)
eventFrame:SetScript("OnUpdate", function(_, elapsed)
  if (iwStacks or 0) > 0 and iwExpiresAt then
    if GetTime() >= iwExpiresAt then
      iwStacks = 0
      iwExpiresAt = nil
      UpdateBars()
    end
  end
end)

eventFrame:SetScript("OnEvent", function(_, event, ...)
  if event == "PLAYER_LOGIN" then
    CreateBars()
    UpdateTalentState()
    UpdateBars()

    -- THIS IS Optional /iwwt commant for quick test (NO UI)
    SLASH_IWTCORE1 = "/iwwt"
    SlashCmdList["IWTCORE"] = function(msg)
      msg = (msg or ""):lower()
      if msg == "on" then Core.SetEnabled(true); print("IWT Core: enabled") return end
      if msg == "off" then Core.SetEnabled(false); print("IWT Core: disabled") return end
      if msg == "reset" then Core.Reset(); print("IWT Core: reset") return end
      print("IWT Core: /iwtcore on | off | reset")
    end

  elseif event == "PLAYER_REGEN_DISABLED" then
    playerInCombat = true
    UpdateBars()

  elseif event == "PLAYER_REGEN_ENABLED" then
    playerInCombat = false
    UpdateBars()

  elseif event == "PLAYER_TALENT_UPDATE"
      or event == "ACTIVE_PLAYER_SPECIALIZATION_CHANGED"
      or event == "TRAIT_CONFIG_UPDATED" then
    UpdateTalentState()
    UpdateBars()

  elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
    local unit, castGUID, spellID = ...
    if unit ~= "player" then return end
    if not IsFuryWarrior() or not hasRequiredTalent then return end

    if castGUID and seenCastGUID[castGUID] then return end
    if castGUID then seenCastGUID[castGUID] = true end

    -- Unhinged “no-consume window” Very important
    if HasUnhingedTalent() and (
         spellID == 50622
      or spellID == 46924
      or spellID == 227847
      or spellID == 184362
      or spellID == 446035
    ) then
      noConsumeUntil = GetTime() + 2
    end

    -- Generator -> award stacks )
    if GENERATOR_IDS[spellID] then
      local hasTarget =
        UnitExists("target")
        and UnitCanAttack("player", "target")
        and not UnitIsDead("target")

      if hasTarget and not IsSpellInTargetRange(spellID) then
        return
      end

      -- small delay 
      C_Timer.After(0.15, function()
        if UnitAffectingCombat("player") then
          GainIWStacks()
        end
      end)
      return
    end

    -- Spender -> consume stack
    if SPENDER_IDS[spellID] then
      if (GetTime() < noConsumeUntil) and (spellID == 23881) then
        return
      end
      ConsumeIWStacks()
      return
    end
  end
end)


_G.IWT_Core = Core
