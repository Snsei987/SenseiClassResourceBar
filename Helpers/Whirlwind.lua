local _, addonTable = ...

local Whirlwind = {}

local iwStacks    = 0
local iwExpiresAt = nil

local playerInCombat     = false
local hasRequiredTalent  = false
local noConsumeUntil     = 0
local seenCastGUID       = {}

Whirlwind.IW_MAX_STACKS = 4
local IW_DURATION   = 20

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

local function HasUnhingedTalent()
  return C_SpellBook and C_SpellBook.IsSpellKnown(UNHINGED_TALENT_ID) or false
end

local function IsSpellInTargetRange(spellID)
  if C_Spell and C_Spell.IsSpellInRange then
    local ok = C_Spell.IsSpellInRange(spellID, "target")
    if ok ~= nil then return ok end
    if type(CheckInteractDistance) == "function" then
      return CheckInteractDistance("target", 3) == true
    end
    return false
  end
  return true
end

function Whirlwind:OnLoad(powerBar)
    local playerClass = select(2, UnitClass("player"))

    if playerClass == "WARRIOR" then
        powerBar.Frame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
        powerBar.Frame:RegisterEvent("PLAYER_DEAD")
        powerBar.Frame:RegisterEvent("PLAYER_ALIVE")
        powerBar.Frame:RegisterEvent("PLAYER_TALENT_UPDATE")
        powerBar.Frame:RegisterEvent("ACTIVE_PLAYER_SPECIALIZATION_CHANGED")
        powerBar.Frame:RegisterEvent("TRAIT_CONFIG_UPDATED")
    end
end

function Whirlwind:OnEvent(powerBar, event, ...)
  if event == "PLAYER_TALENT_UPDATE" or event == "ACTIVE_PLAYER_SPECIALIZATION_CHANGED" or event == "TRAIT_CONFIG_UPDATED" then
    powerBar:ApplyVisibilitySettings()
    powerBar:UpdateDisplay()
    return
  end

  -- Handle Death and Resurrection Reset
    if event == "PLAYER_DEAD" or event == "PLAYER_ALIVE" then
        iwStacks = 0
        iwExpiresAt = nil
        seenCastGUID = {} -- Clear GUID cache to prevent memory bloat
        return
    end

    local unit, castGUID, spellID = ...
    if unit ~= "player" then return end
    if event ~= "UNIT_SPELLCAST_SUCCEEDED" then return end

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

    -- Generator -> award stacks
    if GENERATOR_IDS[spellID] then
        local hasTarget =
            UnitExists("target")
            and UnitCanAttack("player", "target")
            and not UnitIsDead("target")

        if hasTarget and not IsSpellInTargetRange(spellID) then return end

        -- small delay 
        C_Timer.After(0.15, function()
            if UnitAffectingCombat("player") then
                iwStacks = Whirlwind.IW_MAX_STACKS
                iwExpiresAt = GetTime() + IW_DURATION
            end
        end)
        return
    end

    -- Spender -> consume stack
    if SPENDER_IDS[spellID] then
        if (GetTime() < noConsumeUntil) and (spellID == 23881) then return end
            if (iwStacks or 0) <= 0 then return end
            iwStacks = math.max(0, (iwStacks or 0) - 1)
            if iwStacks == 0 then iwExpiresAt = nil end
        return
    end
end

function Whirlwind:GetStacks()
    if iwExpiresAt and GetTime() >= iwExpiresAt then
        iwStacks = 0
        iwExpiresAt = nil
    end

    return C_SpellBook.IsSpellKnown(REQUIRED_TALENT_ID) and self.IW_MAX_STACKS or nil, iwStacks
end

addonTable.Whirlwind = Whirlwind