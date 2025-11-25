local _, addonTable = ...

local LEM = addonTable.LEM or LibStub("LibEditMode")

local PrimaryResourceBarMixin = Mixin({}, addonTable.PowerBarMixin)
local buildVersion = select(4, GetBuildInfo())

function PrimaryResourceBarMixin:GetResourceNumberColor()
    -- Check if class/spec specific text color is enabled
    local data = self:GetData()
    if data and data.enableClassSpecificTextColor then
        -- Check if Elemental Shaman for dynamic text color
        local playerClass = select(2, UnitClass("player"))
        if playerClass == "SHAMAN" then
            local spec = C_SpecializationInfo.GetSpecialization()
            local specID = C_SpecializationInfo.GetSpecializationInfo(spec)
            if specID == 262 then -- Elemental Shaman
                local opacity = data.outOfCombatOpacity or 0.5
                return addonTable:GetElementalShamanTextColor(opacity)
            end
        end
    end

    return addonTable:GetOverrideTextColor(addonTable.RegistereredBar.PrimaryResourceBar.frameName,
        addonTable.TextId.ResourceNumber) or { r = 1, b = 1, g = 1 }
end

function PrimaryResourceBarMixin:GetResourceChargeTimerColor()
    return addonTable:GetOverrideTextColor(addonTable.RegistereredBar.PrimaryResourceBar.frameName,
        addonTable.TextId.ResourceChargeTimer) or { r = 1, b = 1, g = 1 }
end

function PrimaryResourceBarMixin:GetBarColor(resource)
    -- Check if class/spec specific bar color is enabled
    local data = self:GetData()
    if data and data.enableClassSpecificBarColor then
        -- Check if Elemental Shaman for dynamic bar color
        local playerClass = select(2, UnitClass("player"))
        if playerClass == "SHAMAN" then
            local spec = C_SpecializationInfo.GetSpecialization()
            local specID = C_SpecializationInfo.GetSpecializationInfo(spec)
            if specID == 262 then -- Elemental Shaman
                local opacity = data.outOfCombatOpacity or 0.5
                return addonTable:GetElementalShamanBarColor(opacity)
            end
        end
    end

    -- Default behavior
    return addonTable:GetOverrideResourceColor(resource)
end

function PrimaryResourceBarMixin:OnLoad()
    -- Call parent OnLoad
    if addonTable.PowerBarMixin.OnLoad then
        addonTable.PowerBarMixin.OnLoad(self)
    end

    -- Register additional events for Elemental Shaman dynamic text color
    local playerClass = select(2, UnitClass("player"))
    if playerClass == "SHAMAN" then
        self.Frame:RegisterEvent("SPELL_UPDATE_USABLE")
        self.Frame:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player")
    end
end

function PrimaryResourceBarMixin:OnEvent(event, ...)
    -- Call parent OnEvent first
    if addonTable.PowerBarMixin.OnEvent then
        addonTable.PowerBarMixin.OnEvent(self, event, ...)
    end

    -- Handle additional events for Elemental Shaman
    local playerClass = select(2, UnitClass("player"))
    if playerClass == "SHAMAN" then
        local spec = C_SpecializationInfo.GetSpecialization()
        local specID = C_SpecializationInfo.GetSpecializationInfo(spec)
        if specID == 262 then -- Elemental Shaman
            if event == "SPELL_UPDATE_USABLE" or event == "UNIT_POWER_FREQUENT" then
                -- Update text color
                self:ApplyFontSettings()

                -- Update bar color if enabled
                local data = self:GetData()
                if data and data.enableClassSpecificBarColor then
                    self:ApplyForegroundSettings()
                end
            end
        end
    end
end

function PrimaryResourceBarMixin:GetResource()
    local playerClass = select(2, UnitClass("player"))
    local primaryResources = {
        ["DEATHKNIGHT"] = Enum.PowerType.RunicPower,
        ["DEMONHUNTER"] = Enum.PowerType.Fury,
        ["DRUID"]       = {
            [0]                    = Enum.PowerType.Mana, -- Human
            [DRUID_BEAR_FORM]      = Enum.PowerType.Rage,
            [DRUID_TREE_FORM]      = Enum.PowerType.Mana,
            [DRUID_CAT_FORM]       = Enum.PowerType.Energy,
            [DRUID_TRAVEL_FORM]    = Enum.PowerType.Mana,
            [DRUID_ACQUATIC_FORM]  = Enum.PowerType.Mana,
            [DRUID_FLIGHT_FORM]    = Enum.PowerType.Mana,
            [DRUID_MOONKIN_FORM_1] = Enum.PowerType.LunarPower,
            [DRUID_MOONKIN_FORM_2] = Enum.PowerType.LunarPower,
        },
        ["EVOKER"]      = Enum.PowerType.Mana,
        ["HUNTER"]      = Enum.PowerType.Focus,
        ["MAGE"]        = Enum.PowerType.Mana,
        ["MONK"]        = {
            [268] = Enum.PowerType.Energy, -- Brewmaster
            [269] = Enum.PowerType.Energy, -- Windwalker
            [270] = Enum.PowerType.Mana,   -- Mistweaver
        },
        ["PALADIN"]     = Enum.PowerType.Mana,
        ["PRIEST"]      = {
            [256] = Enum.PowerType.Mana,     -- Disciple
            [257] = Enum.PowerType.Mana,     -- Holy,
            [258] = Enum.PowerType.Insanity, -- Shadow,
        },
        ["ROGUE"]       = Enum.PowerType.Energy,
        ["SHAMAN"]      = {
            [262] = Enum.PowerType.Maelstrom, -- Elemental
            [263] = nil,                      -- Enhancement
            [264] = Enum.PowerType.Mana,      -- Restoration
        },
        ["WARLOCK"]     = Enum.PowerType.Mana,
        ["WARRIOR"]     = Enum.PowerType.Rage,
    }

    local spec = C_SpecializationInfo.GetSpecialization()
    local specID = C_SpecializationInfo.GetSpecializationInfo(spec)

    -- Druid: form-based
    if playerClass == "DRUID" then
        local formID = GetShapeshiftFormID()
        return primaryResources[playerClass] and primaryResources[playerClass][formID or 0]
    end

    if type(primaryResources[playerClass]) == "table" then
        return primaryResources[playerClass][specID]
    else
        return primaryResources[playerClass]
    end
end

function PrimaryResourceBarMixin:GetResourceValue(resource)
    if not resource then return nil, nil, nil, nil end

    local data = self:GetData()
    local current = UnitPower("player", resource)
    local max = UnitPowerMax("player", resource)
    if max <= 0 then return nil, nil, nil, nil end

    if data and data.showManaAsPercent and resource == Enum.PowerType.Mana then
        -- UnitPowerPercent does not exist prior to Midnight
        if (buildVersion or 0) < 120000 then
            return max, current, math.floor((current / max) * 100 + 0.5), "percent"
        else
            return max, current, UnitPowerPercent("player", resource, false, true), "percent"
        end
    else
        return max, current, current, "number"
    end
end

addonTable.PrimaryResourceBarMixin = PrimaryResourceBarMixin

addonTable.RegistereredBar = addonTable.RegistereredBar or {}
addonTable.RegistereredBar.PrimaryResourceBar = {
    mixin = addonTable.PrimaryResourceBarMixin,
    dbName = "PrimaryResourceBarDB",
    editModeName = "Primary Resource Bar",
    frameName = "PrimaryResourceBar",
    frameLevel = 3,
    defaultValues = {
        point = "CENTER",
        x = 0,
        y = 0,
        showManaAsPercent = false,
        useResourceAtlas = false,
        enableClassSpecificTextColor = true,
        enableClassSpecificBarColor = false,
        outOfCombatOpacity = 0.5,
    },
    lemSettings = function(bar, defaults)
        local dbName = bar:GetConfig().dbName

        -- Get current spec name for display
        local specName = "Elemental Shaman"
        local playerClass = select(2, UnitClass("player"))
        if playerClass == "SHAMAN" then
            local spec = C_SpecializationInfo.GetSpecialization()
            if spec then
                local _, name = C_SpecializationInfo.GetSpecializationInfo(spec)
                if name then
                    specName = name .. " " .. UnitClass("player")
                end
            end
        end

        return {
            {
                order = 41,
                name = "Show Mana As Percent",
                kind = LEM.SettingType.Checkbox,
                default = defaults.showManaAsPercent,
                get = function(layoutName)
                    local data = SenseiClassResourceBarDB[dbName][layoutName]
                    if data and data.showManaAsPercent ~= nil then
                        return data.showManaAsPercent
                    else
                        return defaults.showManaAsPercent
                    end
                end,
                set = function(layoutName, value)
                    SenseiClassResourceBarDB[dbName][layoutName] = SenseiClassResourceBarDB[dbName][layoutName] or
                        CopyTable(defaults)
                    SenseiClassResourceBarDB[dbName][layoutName].showManaAsPercent = value
                    bar:UpdateDisplay(layoutName)
                end,
            },
            {
                order = 63,
                name = "Use Resource Foreground And Color",
                kind = LEM.SettingType.Checkbox,
                default = defaults.useResourceAtlas,
                get = function(layoutName)
                    local data = SenseiClassResourceBarDB[dbName][layoutName]
                    if data and data.useResourceAtlas ~= nil then
                        return data.useResourceAtlas
                    else
                        return defaults.useResourceAtlas
                    end
                end,
                set = function(layoutName, value)
                    SenseiClassResourceBarDB[dbName][layoutName] = SenseiClassResourceBarDB[dbName][layoutName] or
                        CopyTable(defaults)
                    SenseiClassResourceBarDB[dbName][layoutName].useResourceAtlas = value
                    bar:ApplyLayout(layoutName)
                end,
            },
            {
                order = 64,
                name = "Enable " .. specName .. " Specific Text Color",
                kind = LEM.SettingType.Checkbox,
                default = defaults.enableClassSpecificTextColor,
                get = function(layoutName)
                    local data = SenseiClassResourceBarDB[dbName][layoutName]
                    if data and data.enableClassSpecificTextColor ~= nil then
                        return data.enableClassSpecificTextColor
                    else
                        return defaults.enableClassSpecificTextColor
                    end
                end,
                set = function(layoutName, value)
                    SenseiClassResourceBarDB[dbName][layoutName] = SenseiClassResourceBarDB[dbName][layoutName] or
                        CopyTable(defaults)
                    SenseiClassResourceBarDB[dbName][layoutName].enableClassSpecificTextColor = value
                    bar:ApplyFontSettings(layoutName)
                end,
            },
            {
                order = 65,
                name = "Enable " .. specName .. " Specific Bar Color",
                kind = LEM.SettingType.Checkbox,
                default = defaults.enableClassSpecificBarColor,
                get = function(layoutName)
                    local data = SenseiClassResourceBarDB[dbName][layoutName]
                    if data and data.enableClassSpecificBarColor ~= nil then
                        return data.enableClassSpecificBarColor
                    else
                        return defaults.enableClassSpecificBarColor
                    end
                end,
                set = function(layoutName, value)
                    SenseiClassResourceBarDB[dbName][layoutName] = SenseiClassResourceBarDB[dbName][layoutName] or
                        CopyTable(defaults)
                    SenseiClassResourceBarDB[dbName][layoutName].enableClassSpecificBarColor = value
                    bar:ApplyLayout(layoutName)
                end,
            },
            {
                order = 66,
                name = "OOC Opacity",
                kind = LEM.SettingType.Slider,
                default = defaults.outOfCombatOpacity,
                minValue = 0,
                maxValue = 1,
                valueStep = 0.01,
                formatter = function(value)
                    return string.format("%d%%", value * 100)
                end,
                get = function(layoutName)
                    local data = SenseiClassResourceBarDB[dbName][layoutName]
                    if data and data.outOfCombatOpacity ~= nil then
                        return data.outOfCombatOpacity
                    else
                        return defaults.outOfCombatOpacity
                    end
                end,
                set = function(layoutName, value)
                    SenseiClassResourceBarDB[dbName][layoutName] = SenseiClassResourceBarDB[dbName][layoutName] or
                        CopyTable(defaults)
                    SenseiClassResourceBarDB[dbName][layoutName].outOfCombatOpacity = value
                    bar:ApplyFontSettings(layoutName)
                    bar:ApplyForegroundSettings(layoutName)
                end,
            },
        }
    end,
}
