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
    self.Frame:RegisterUnitEvent("UNIT_AURA", "player") -- For auras that modify or define max power (i.e. Enhancement Shaman Maelstrom Weapon)

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

    elseif event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_TARGET_CHANGED" or event == "UNIT_ENTERED_VEHICLE" or event == "UNIT_EXITED_VEHICLE" or event == "PLAYER_MOUNT_DISPLAY_CHANGED" then

        self:ApplyVisibilitySettings(nil, event == "PLAYER_REGEN_DISABLED")
        self:UpdateDisplay()

    elseif event == "UNIT_MAXPOWER" and unit == "player" then
        self:UpdateTicksLayout()
    elseif event == "UNIT_AURA" and unit == "player" then
        local resource = self:GetResource()
        if resource == "MAELSTROM_WEAPON" then
            local auraData = C_UnitAuras.GetPlayerAuraBySpellID(344179)
            self._maelstromWeaponStacks = auraData and auraData.applications or 0
        end
        self:UpdateDisplay()
    end
end

addonTable.PowerBarMixin = PowerBarMixin