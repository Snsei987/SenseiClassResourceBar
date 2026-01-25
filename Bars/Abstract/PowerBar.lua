local _, addonTable = ...

local PowerBarMixin = Mixin({}, addonTable.BarMixin)

function PowerBarMixin:GetBarColor(resource)
    return addonTable:GetOverrideResourceColor(resource)
end

function PowerBarMixin:OnLoad()
    self.Frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    self.Frame:RegisterUnitEvent("PLAYER_SPECIALIZATION_CHANGED", "player")
    self.Frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    self.Frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    self.Frame:RegisterEvent("PLAYER_TARGET_CHANGED")
    self.Frame:RegisterUnitEvent("UNIT_ENTERED_VEHICLE", "player")
    self.Frame:RegisterUnitEvent("UNIT_EXITED_VEHICLE", "player")
    self.Frame:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
    self.Frame:RegisterUnitEvent("UNIT_MAXPOWER", "player")
    self.Frame:RegisterEvent("PET_BATTLE_OPENING_START")
    self.Frame:RegisterEvent("PET_BATTLE_CLOSE")

    local playerClass = select(2, UnitClass("player"))

    if playerClass == "DRUID" then
        self.Frame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
    end
end

function PowerBarMixin:OnEvent(event, ...)
    local unit = ...

    if event == "PLAYER_ENTERING_WORLD"
        or event == "UPDATE_SHAPESHIFT_FORM"
        or (event == "PLAYER_SPECIALIZATION_CHANGED" and unit == "player") then

        self:ApplyVisibilitySettings()
        self:ApplyLayout(nil, true)

    elseif event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_REGEN_DISABLED"
        or event == "PLAYER_TARGET_CHANGED"
        or event == "UNIT_ENTERED_VEHICLE" or event == "UNIT_EXITED_VEHICLE"
        or event == "PLAYER_MOUNT_DISPLAY_CHANGED"
        or event == "PET_BATTLE_OPENING_START" or event == "PET_BATTLE_CLOSE" then

        self:ApplyVisibilitySettings(nil, event == "PLAYER_REGEN_DISABLED")
        self:UpdateDisplay()

    elseif event == "UNIT_MAXPOWER" and unit == "player" then

        self:ApplyLayout(nil, true)

    end
end

function PowerBarMixin:GetTagValues(resource, max, current, precision)
    local pFormat = "%." .. (precision or 0) .. "f"

    return {
        ["[current]"] = function() return string.format("%s", AbbreviateNumbers(current)) end,
        ["[percent]"] = function()
            if issecretvalue(max) or issecretvalue(current) then
                return string.format(pFormat, UnitPowerPercent("player", resource, true, CurveConstants.ScaleTo100))
            else
                return string.format(pFormat, (current / max) * 100)
            end
        end,
        ["[max]"] = function() return string.format("%s", AbbreviateNumbers(max)) end,
    }
end

addonTable.PowerBarMixin = PowerBarMixin