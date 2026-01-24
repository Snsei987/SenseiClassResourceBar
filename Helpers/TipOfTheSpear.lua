local _, addonTable = ...

local TipOfTheSpear = {}

-- Tracking variables
local tipStacks = 0
local tipExpiresAt = nil
local TIP_MAX_STACKS = 3
local TIP_DURATION = 10

-- Spell IDs
local KILL_COMMAND_ID = 259489

-- Abilities that consume Tip of the Spear stacks
local SPENDER_IDS = {
    [186270] = true,  -- Raptor Strike
    [1262293] = true, -- Raptor Swipe
    [1261193] = true, -- Boomstick
    [1253859] = true, -- Takedown
    [259495] = true,  -- Wildfire Bomb
    [193265] = true,  -- Hatchet Toss
    [1264949] = true, -- Chakram
    [1262343] = true, -- Ranged Raptor Swipe
    [265189] = true,  -- Ranged Raptor Strike
    [1251592] = true, -- Flamefang Pitch
}

function TipOfTheSpear:OnEvent(unit, spellID)
    if unit ~= "player" then return end
    
    -- Gain 2 stacks from Kill Command
    if spellID == KILL_COMMAND_ID then
        tipStacks = math.min(TIP_MAX_STACKS, tipStacks + 2)
        tipExpiresAt = GetTime() + TIP_DURATION
        return true -- Changed
    end
    
    -- Consume stack from spenders
    if SPENDER_IDS[spellID] then
        if tipStacks > 0 then
            tipStacks = tipStacks - 1
            if tipStacks == 0 then
                tipExpiresAt = nil
            end
            return true -- Changed
        end
    end
    
    return false -- No change
end

function TipOfTheSpear:GetStacks()
    -- Check if stacks have expired
    if tipExpiresAt and GetTime() >= tipExpiresAt then
        tipStacks = 0
        tipExpiresAt = nil
    end
    
    return tipStacks, TIP_MAX_STACKS
end

addonTable.TipOfTheSpear = TipOfTheSpear
