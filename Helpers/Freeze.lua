local _, addonTable = ...

local Freeze = {}

-- Debufs are secrets now, so we will have to hook into the CDM to display the Freeze stacks.
Freeze.FREEZE_MAX_STACKS = 20

local _auraInstanceID = nil
local _cdmFrame       = nil
local _hooked         = false

local function HasAuraInstanceID(value)
    if value == nil then return false end
    if issecretvalue and issecretvalue(value) then return true end
    return type(value) == "number" and value ~= 0
end

function Freeze:OnLoad(powerBar)
    local playerClass = select(2, UnitClass("player"))
    if playerClass == "MAGE" then
        powerBar.Frame:RegisterUnitEvent("UNIT_AURA", "target")
    end
end

function Freeze:OnEvent(powerBar, event, ...)
    local playerClass = select(2, UnitClass("player"))
    if playerClass ~= "MAGE" then return end

    if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_SPECIALIZATION_CHANGED" then
        self:SetupCDMHooks(powerBar)
    elseif event == "PLAYER_TARGET_CHANGED" then
        _auraInstanceID = nil
        _cdmFrame = nil
    elseif event == "UNIT_AURA" and (...) == "target" then
        powerBar:UpdateDisplay()
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
                            powerBar:UpdateDisplay()
                        end
                    end)
                end
            end
        end
    end
end

function Freeze:GetStacks()
    local auraData = HasAuraInstanceID(_auraInstanceID)
        and C_UnitAuras.GetAuraDataByAuraInstanceID("target", _auraInstanceID)
    return self.FREEZE_MAX_STACKS, auraData and auraData.applications or 0
end

addonTable.Freeze = Freeze
