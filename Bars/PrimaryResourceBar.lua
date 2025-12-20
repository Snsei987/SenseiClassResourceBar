local _, addonTable = ...

local LEM = addonTable.LEM or LibStub("LibEQOLEditMode-1.0")

local PrimaryResourceBarMixin = Mixin({}, addonTable.PowerBarMixin)
local buildVersion = select(4, GetBuildInfo())

function PrimaryResourceBarMixin:GetResource()
    local playerClass = select(2, UnitClass("player"))
    local primaryResources = {
        ["DEATHKNIGHT"] = Enum.PowerType.RunicPower,
        ["DEMONHUNTER"] = Enum.PowerType.Fury,
        ["DRUID"]       = {
            [0]   = Enum.PowerType.Mana, -- Human
            [DRUID_BEAR_FORM]       = Enum.PowerType.Rage,
            [DRUID_TREE_FORM]       = Enum.PowerType.Mana,
            [DRUID_CAT_FORM]        = Enum.PowerType.Energy,
            [DRUID_TRAVEL_FORM]     = Enum.PowerType.Mana,
            [DRUID_ACQUATIC_FORM]   = Enum.PowerType.Mana,
            [DRUID_FLIGHT_FORM]     = Enum.PowerType.Mana,
            [DRUID_MOONKIN_FORM_1]  = Enum.PowerType.LunarPower,
            [DRUID_MOONKIN_FORM_2]  = Enum.PowerType.LunarPower,
        },
        ["EVOKER"]      = Enum.PowerType.Mana,
        ["HUNTER"]      = Enum.PowerType.Focus,
        ["MAGE"]        = Enum.PowerType.Mana,
        ["MONK"]        = {
            [268] = Enum.PowerType.Energy, -- Brewmaster
            [269] = Enum.PowerType.Energy, -- Windwalker
            [270] = Enum.PowerType.Mana, -- Mistweaver
        },
        ["PALADIN"]     = Enum.PowerType.Mana,
        ["PRIEST"]      = {
            [256] = Enum.PowerType.Mana, -- Disciple
            [257] = Enum.PowerType.Mana, -- Holy,
            [258] = Enum.PowerType.Insanity, -- Shadow,
        },
        ["ROGUE"]       = Enum.PowerType.Energy,
        ["SHAMAN"]      = {
            [262] = Enum.PowerType.Maelstrom, -- Elemental
            [263] = "MAELSTROM_WEAPON", -- Enhancement
            [264] = Enum.PowerType.Mana, -- Restoration
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
        if not resource then return nil, nil, nil, nil, nil end

        -- Enhancement Shaman Maelstrom Weapon special case
        local data = self:GetData()
        if resource == "MAELSTROM_WEAPON" then
            local auraData = C_UnitAuras.GetPlayerAuraBySpellID(344179)
            local current = auraData and auraData.applications or 0
            local max = 10

            if data and (data.textFormat == "Percent" or data.textFormat == "Percent%") then
                return max, max, current, math.floor((current / max) * 100 + 0.5), "percent"
            else
                return max, max, current, current, "number"
            end
        end

        local current = UnitPower("player", resource)
        local max = UnitPowerMax("player", resource)
        if max <= 0 then return nil, nil, nil, nil, nil end

        if data and ((data.showManaAsPercent and resource == Enum.PowerType.Mana) or data.textFormat == "Percent" or data.textFormat == "Percent%") then
            -- UnitPowerPercent does not exist prior to Midnight
            if (buildVersion or 0) < 120000 then
                return max, max, current, math.floor((current / max) * 100 + 0.5), "percent"
            else
                return max, max, current, UnitPowerPercent("player", resource, false, CurveConstants.ScaleTo100), "percent"
            end
        else
            return max, max, current, current, "number"
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
        hideManaOnRole = {},
        showManaAsPercent = false,
        useResourceAtlas = false,
    },
    lemSettings = function(bar, defaults)
        local dbName = bar:GetConfig().dbName

        return {
            {
                parentId = "Bar Visibility",
                order = 103,
                name = "Hide Mana On Role",
                kind = LEM.SettingType.MultiDropdown,
                default = defaults.hideManaOnRole,
                values = addonTable.availableRoleOptions,
                hideSummary = true,
                useOldStyle = true,
                get = function(layoutName)
                    return (SenseiClassResourceBarDB[dbName][layoutName] and SenseiClassResourceBarDB[dbName][layoutName].hideManaOnRole) or defaults.hideManaOnRole
                end,
                set = function(layoutName, value)
                    SenseiClassResourceBarDB[dbName][layoutName] = SenseiClassResourceBarDB[dbName][layoutName] or CopyTable(defaults)
                    SenseiClassResourceBarDB[dbName][layoutName].hideManaOnRole = value
                end,
                tooltip = "Not effective on Arcane Mage",
            },
            {
                parentId = "Text Settings",
                order = 405,
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
                    SenseiClassResourceBarDB[dbName][layoutName] = SenseiClassResourceBarDB[dbName][layoutName] or CopyTable(defaults)
                    SenseiClassResourceBarDB[dbName][layoutName].showManaAsPercent = value
                    bar:UpdateDisplay(layoutName)
                end,
                isEnabled = function(layoutName)
                    local data = SenseiClassResourceBarDB[dbName][layoutName]
                    return data.showText
                end,
                tooltip = "Force the Percent format on Mana",
            },
            {
                parentId = "Bar Style",
                order = 606,
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
                    SenseiClassResourceBarDB[dbName][layoutName] = SenseiClassResourceBarDB[dbName][layoutName] or CopyTable(defaults)
                    SenseiClassResourceBarDB[dbName][layoutName].useResourceAtlas = value
                    bar:ApplyLayout(layoutName)
                end,
            },
        }
    end,
}