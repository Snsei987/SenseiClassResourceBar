local _, addonTable = ...

local LEM = addonTable.LEM or LibStub("LibEQOLEditMode-1.0")

local HealthBarMixin = Mixin({}, addonTable.BarMixin)

function HealthBarMixin:GetBarColor()
    local playerClass = select(2, UnitClass("player"))

    local data = self:GetData()

    local color = addonTable:GetOverrideHealthBarColor()

    if data and data.useClassColor == true then
        local r, g, b = GetClassColor(playerClass)
        return { r = r, g = g, b = b, a = color.a }
    else
        return color
    end
end

function HealthBarMixin:GetResource()
    return "HEALTH"
end

function HealthBarMixin:GetResourceValue()
    local current = UnitHealth("player")
    local max = UnitHealthMax("player")
    if max <= 0 then return nil, nil end

    return max, current
end

function HealthBarMixin:GetTagValues(_, max, current, precision)
    local pFormat = "%." .. (precision or 0) .. "f"

    return {
        ["[current]"] = function() return string.format("%s", AbbreviateNumbers(current)) end,
        ["[percent]"] = function() return string.format(pFormat, UnitHealthPercent("player", true, CurveConstants.ScaleTo100)) end,
        ["[max]"] = function() return string.format("%s", AbbreviateNumbers(max)) end,
    }
end

function HealthBarMixin:OnLoad()
    self.Frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    self.Frame:RegisterUnitEvent("PLAYER_SPECIALIZATION_CHANGED", "player")
    self.Frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    self.Frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    self.Frame:RegisterEvent("PLAYER_TARGET_CHANGED")
    self.Frame:RegisterUnitEvent("UNIT_ENTERED_VEHICLE", "player")
    self.Frame:RegisterUnitEvent("UNIT_EXITED_VEHICLE", "player")
    self.Frame:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
    self.Frame:RegisterEvent("PET_BATTLE_OPENING_START")
    self.Frame:RegisterEvent("PET_BATTLE_CLOSE")
end

function HealthBarMixin:OnEvent(event, ...)
    local unit = ...

    if event == "PLAYER_ENTERING_WORLD"
        or (event == "PLAYER_SPECIALIZATION_CHANGED" and unit == "player") then

        self:ApplyVisibilitySettings()
        self:ApplyLayout()
        self:UpdateDisplay()

    elseif event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_REGEN_DISABLED"
        or event == "PLAYER_TARGET_CHANGED"
        or event == "UNIT_ENTERED_VEHICLE" or event == "UNIT_EXITED_VEHICLE"
        or event == "PLAYER_MOUNT_DISPLAY_CHANGED"
        or event == "PET_BATTLE_OPENING_START" or event == "PET_BATTLE_CLOSE" then

            self:ApplyVisibilitySettings(nil, event == "PLAYER_REGEN_DISABLED")
            self:UpdateDisplay()

    end
end

addonTable.HealthBarMixin = HealthBarMixin

addonTable.RegisteredBar = addonTable.RegisteredBar or {}
addonTable.RegisteredBar.HealthBar = {
    mixin = addonTable.HealthBarMixin,
    dbName = "healthBarDB",
    editModeName = "Health Bar",
    frameName = "HealthBar",
    frameLevel = 0,
    defaultValues = {
        point = "CENTER",
        x = 0,
        y = 40,
        barVisible = "Hidden",
        hideHealthOnRole = {},
        hideBlizzardPlayerContainerUi = false,
        useClassColor = true,
    },
    lemSettings = function(bar, defaults)
        local dbName = bar:GetConfig().dbName

        return {
            {
                parentId = "Bar Visibility",
                order = 103,
                name = "Hide On Role",
                kind = LEM.SettingType.MultiDropdown,
                default = defaults.hideHealthOnRole,
                values = addonTable.availableRoleOptions,
                hideSummary = true,
                useOldStyle = true,
                get = function(layoutName)
                    return (SenseiClassResourceBarDB[dbName][layoutName] and SenseiClassResourceBarDB[dbName][layoutName].hideHealthOnRole) or defaults.hideHealthOnRole
                end,
                set = function(layoutName, value)
                    SenseiClassResourceBarDB[dbName][layoutName] = SenseiClassResourceBarDB[dbName][layoutName] or CopyTable(defaults)
                    SenseiClassResourceBarDB[dbName][layoutName].hideHealthOnRole = value
                end,
            },
            {
                parentId = "Bar Visibility",
                order = 105,
                name = "Hide Blizzard UI",
                kind = LEM.SettingType.Checkbox,
                default = defaults.hideBlizzardPlayerContainerUi,
                get = function(layoutName)
                    local data = SenseiClassResourceBarDB[dbName][layoutName]
                    if data and data.hideBlizzardPlayerContainerUi ~= nil then
                        return data.hideBlizzardPlayerContainerUi
                    else
                        return defaults.hideBlizzardPlayerContainerUi
                    end
                end,
                set = function(layoutName, value)
                    SenseiClassResourceBarDB[dbName][layoutName] = SenseiClassResourceBarDB[dbName][layoutName] or CopyTable(defaults)
                    SenseiClassResourceBarDB[dbName][layoutName].hideBlizzardPlayerContainerUi = value
                    bar:HideBlizzardPlayerContainer(layoutName)
                end,
                tooltip = "Hides the default Blizzard Player Frame UI",
            },
            {
                parentId = "Bar Style",
                order = 401,
                name = "Use Class Color",
                kind = LEM.SettingType.Checkbox,
                default = defaults.useClassColor,
                get = function(layoutName)
                    local data = SenseiClassResourceBarDB[dbName][layoutName]
                    if data and data.useClassColor ~= nil then
                        return data.useClassColor
                    else
                        return defaults.useClassColor
                    end
                end,
                set = function(layoutName, value)
                    SenseiClassResourceBarDB[dbName][layoutName] = SenseiClassResourceBarDB[dbName][layoutName] or CopyTable(defaults)
                    SenseiClassResourceBarDB[dbName][layoutName].useClassColor = value
                    bar:ApplyLayout(layoutName)
                end,
            },
        }
    end,
}