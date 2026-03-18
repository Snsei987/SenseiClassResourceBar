local _, addonTable = ...

local Freeze = {}

-- Debufs are secrets now, so we will have to hook into the CDM to display the Freeze stacks.
Freeze.FREEZE_MAX_STACKS = 20

local FREEZE_SPELL_ID = 1246769

local _auraInstanceID    = nil
local _cdmFrame          = nil
local _hooked            = false
local _lastKnownStacks   = 0

local function HasAuraInstanceID(value)
    if value == nil then return false end
    if issecretvalue and issecretvalue(value) then return true end
    return type(value) == "number" and value ~= 0
end

function Freeze:OnLoad(powerBar)
    local playerClass = select(2, UnitClass("player"))
    if playerClass == "MAGE" then
        self:SetupCDMHooks(powerBar)
    end
end

function Freeze:OnEvent(powerBar, event, ...)
    local playerClass = select(2, UnitClass("player"))
    if playerClass ~= "MAGE" then return end

    if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_SPECIALIZATION_CHANGED" then
        self:SetupCDMHooks(powerBar)
    end
end

function Freeze:SetupCDMHooks(powerBar)
    if _hooked then return end
    _hooked = true

    for _, viewer in ipairs({BuffIconCooldownViewer, BuffBarCooldownViewer}) do
        if viewer then
            for _, frame in ipairs({viewer:GetChildren()}) do
                if frame.SetAuraInstanceInfo then
                    hooksecurefunc(frame, "SetAuraInstanceInfo", function(f)
                        -- Re-validate at call time: CDM may have reassigned this frame to a different spell
                        local cdID = f.cooldownID
                        local info = cdID and C_CooldownViewer and C_CooldownViewer.GetCooldownViewerCooldownInfo(cdID)
                        if not (info and info.spellID == FREEZE_SPELL_ID) then return end

                        if f.auraDataUnit == "target" and HasAuraInstanceID(f.auraInstanceID) then
                            _auraInstanceID = f.auraInstanceID
                            _cdmFrame = f
                            powerBar:UpdateDisplay()
                        end
                    end)
                end
                if frame.ClearAuraInstanceInfo then
                    hooksecurefunc(frame, "ClearAuraInstanceInfo", function(f)
                        if f == _cdmFrame then
                            _auraInstanceID = nil
                            _cdmFrame = nil
                            _lastKnownStacks = 0
                            powerBar:UpdateDisplay()
                        end
                    end)
                end
            end
        end
    end
end

function Freeze:GetStacks()
    if not HasAuraInstanceID(_auraInstanceID) then
        return self.FREEZE_MAX_STACKS, 0
    end
    local auraData = C_UnitAuras.GetAuraDataByAuraInstanceID("target", _auraInstanceID)
    if auraData then
        _lastKnownStacks = auraData.applications or 0
        return self.FREEZE_MAX_STACKS, _lastKnownStacks
    end
    -- Return last known stacks to avoid a brief flash to 0.
    return self.FREEZE_MAX_STACKS, _lastKnownStacks
end

addonTable.Freeze = Freeze
