local _, addonTable = ...

local LEM = addonTable.LEM or LibStub("LibEQOLEditMode-1.0")

local SecondaryResourceBarMixin = Mixin({}, addonTable.PowerBarMixin)
local buildVersion = select(4, GetBuildInfo())

function SecondaryResourceBarMixin:GetResource()
    local playerClass = select(2, UnitClass("player"))
    local secondaryResources = {
        ["DEATHKNIGHT"] = Enum.PowerType.Runes,
        ["DEMONHUNTER"] = {
            [1480] = "SOUL_FRAGMENTS", -- Devourer
        },
        ["DRUID"]       = {
            [DRUID_CAT_FORM]        = Enum.PowerType.ComboPoints,
            [DRUID_MOONKIN_FORM_1]  = Enum.PowerType.Mana,
            [DRUID_MOONKIN_FORM_2]  = Enum.PowerType.Mana,
        },
        ["EVOKER"]      = Enum.PowerType.Essence,
        ["HUNTER"]      = nil,
        ["MAGE"]        = {
            [62]   = Enum.PowerType.ArcaneCharges, -- Arcane
        },
        ["MONK"]        = {
            [268]  = "STAGGER", -- Brewmaster
            [269]  = Enum.PowerType.Chi, -- Windwalker
        },
        ["PALADIN"]     = Enum.PowerType.HolyPower,
        ["PRIEST"]      = {
            [258]  = Enum.PowerType.Mana, -- Shadow
        },
        ["ROGUE"]       = Enum.PowerType.ComboPoints,
        ["SHAMAN"]      = {
            [262]  = Enum.PowerType.Mana, -- Elemental
            [263] =  Enum.PowerType.Mana, -- Enhancement
        },
        ["WARLOCK"]     = Enum.PowerType.SoulShards,
        ["WARRIOR"]     = nil,
    }

    local spec = C_SpecializationInfo.GetSpecialization()
    local specID = C_SpecializationInfo.GetSpecializationInfo(spec)

    -- Druid: form-based
    if playerClass == "DRUID" then
        local formID = GetShapeshiftFormID()
        return secondaryResources[playerClass] and secondaryResources[playerClass][formID or 0]
    end

    if type(secondaryResources[playerClass]) == "table" then
        return secondaryResources[playerClass][specID]
    else
        return secondaryResources[playerClass]
    end
end

local abbrevDataWarlockSoulShards = {
  breakpointData = {
    {
      breakpoint = 0,
      abbreviation = "",
      significandDivisor = 1,
      fractionDivisor = 10,
      abbreviationIsGlobal = false,
    },
  },
}

function SecondaryResourceBarMixin:GetResourceValue(resource)
    if not resource then return nil, nil, nil, nil, nil end
    local data = self:GetData()
    if not data then return nil, nil, nil, nil, nil end

    if resource == "STAGGER" then
        local stagger = UnitStagger("player") or 0
        local maxHealth = UnitHealthMax("player") or 1

        self._lastStaggerPercent = self._lastStaggerPercent or ((stagger / maxHealth) * 100)
        local staggerPercent = (stagger / maxHealth) * 100
        if (staggerPercent >= 30 and self._lastStaggerPercent < 30)
            or (staggerPercent < 30 and self._lastStaggerPercent >= 30)
            or (staggerPercent >= 60 and self._lastStaggerPercent < 60)
            or (staggerPercent < 60 and self._lastStaggerPercent >= 60) then
            self:ApplyForegroundSettings()
        end
        self._lastStaggerPercent = staggerPercent

        if data.textFormat == "Percent" or data.textFormat == "Percent%" then
            return maxHealth, maxHealth, stagger, staggerPercent, "percent"
        else
            return maxHealth, maxHealth, stagger, stagger, "number"
        end
    end

    if resource == "SOUL_FRAGMENTS" then
        local auraData = C_UnitAuras.GetPlayerAuraBySpellID(1225789) or C_UnitAuras.GetPlayerAuraBySpellID(1227702) -- Soul Fragments / Collapsing Star
        local current = auraData and auraData.applications or 0
        local max = C_SpellBook.IsSpellKnown(1247534) and 35 or 50 -- Soul Glutton

        -- For performance, only update the foreground when current is below 1, this happens when switching in/out of Void Metamorphosis
        if current <= 1 then
            self:ApplyForegroundSettings()
        end

        if data.textFormat == "Percent" or data.textFormat == "Percent%" then
            return max, max, current, math.floor((current / max) * 100 + 0.5), "percent"
        else
            return max, max, current, current, "number"
        end
    end

    if resource == Enum.PowerType.Runes then
        local current = 0
        local max = UnitPowerMax("player", resource)
        if max <= 0 then return nil, nil, nil, nil, nil end

        for i = 1, max do
            local runeReady = select(3, GetRuneCooldown(i))
            if runeReady then
                current = current + 1
            end
        end

        if data.textFormat == "Percent" or data.textFormat == "Percent%" then
            return max, max, current, math.floor((current / max) * 100 + 0.5), "percent"
        else
            return max, max, current, current, "number"
        end
    end

    if resource == Enum.PowerType.SoulShards then
        local current = UnitPower("player", resource, true)
        local max = UnitPowerMax("player", resource, true)
        if max <= 0 then return nil, nil, nil, nil, nil end

        if data.textFormat == "Percent" or data.textFormat == "Percent%" then
            return max, max, current, math.floor((current / max) * 100 + 0.5), "percent"
        else
            return max, max / 10, current, current / 10, "number"
        end
    end

    -- Regular secondary resource types
    local current = UnitPower("player", resource)
    local max = UnitPowerMax("player", resource)
    if max <= 0 then return nil, nil, nil, nil, nil end

    if (data.showManaAsPercent and resource == Enum.PowerType.Mana) or data.textFormat == "Percent" or data.textFormat == "Percent%" then
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

function SecondaryResourceBarMixin:GetPoint(layoutName)
    local data = self:GetData(layoutName)

    if data and data.positionMode == "Use Primary Resource Bar Position If Hidden" then
        local primaryResource = addonTable.barInstances and addonTable.barInstances["PrimaryResourceBar"]

        if primaryResource then
            -- This works because visibility settings are applied before layout, so the secondary can know whether the primary is shown or not
            if not primaryResource:IsShown() then
                return primaryResource:GetPoint(layoutName)
            end
        end
    end

    return addonTable.PowerBarMixin.GetPoint(self, layoutName)
end

function SecondaryResourceBarMixin:OnShow()
    local data = self:GetData()

    if data and data.positionMode == "Use Primary Resource Bar Position If Hidden" then
        self:ApplyLayout()
    end
end

function SecondaryResourceBarMixin:OnHide()
    local data = self:GetData()

    if data and data.positionMode == "Use Primary Resource Bar Position If Hidden" then
        self:ApplyLayout()
    end
end

addonTable.SecondaryResourceBarMixin = SecondaryResourceBarMixin

addonTable.RegisteredBar = addonTable.RegisteredBar or {}
addonTable.RegisteredBar.SecondaryResourceBar = {
    mixin = addonTable.SecondaryResourceBarMixin,
    dbName = "SecondaryResourceBarDB",
    editModeName = "Secondary Resource Bar",
    frameName = "SecondaryResourceBar",
    frameLevel = 2,
    defaultValues = {
        point = "CENTER",
        x = 0,
        y = -40,
        positionMode = "Self",
        hideBlizzardSecondaryResourceUi = false,
        hideManaOnRole = {},
        showManaAsPercent = false,
        showTicks = true,
        tickColor = {r = 0, g = 0, b = 0, a = 1},
        tickThickness = 1,
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
            },
            {
                parentId = "Bar Visibility",
                order = 105,
                name = "Hide Blizzard UI",
                kind = LEM.SettingType.Checkbox,
                default = defaults.hideBlizzardSecondaryResourceUi,
                get = function(layoutName)
                    local data = SenseiClassResourceBarDB[dbName][layoutName]
                    if data and data.hideBlizzardSecondaryResourceUi ~= nil then
                        return data.hideBlizzardSecondaryResourceUi
                    else
                        return defaults.hideBlizzardSecondaryResourceUi
                    end
                end,
                set = function(layoutName, value)
                    SenseiClassResourceBarDB[dbName][layoutName] = SenseiClassResourceBarDB[dbName][layoutName] or CopyTable(defaults)
                    SenseiClassResourceBarDB[dbName][layoutName].hideBlizzardSecondaryResourceUi = value
                    bar:HideBlizzardSecondaryResource(layoutName)
                end,
                tooltip = "Hides the default Blizzard secondary resource UI (e.g. Rune Frame for Death Knights)",
            },
            {
                parentId = "Position & Size",
                order = 201,
                name = "Position",
                kind = LEM.SettingType.Dropdown,
                default = defaults.positionMode,
                useOldStyle = true,
                values = addonTable.availablePositionModeOptions,
                get = function(layoutName)
                    return (SenseiClassResourceBarDB[dbName][layoutName] and SenseiClassResourceBarDB[dbName][layoutName].positionMode) or defaults.positionMode
                end,
                set = function(layoutName, value)
                    SenseiClassResourceBarDB[dbName][layoutName] = SenseiClassResourceBarDB[dbName][layoutName] or CopyTable(defaults)
                    SenseiClassResourceBarDB[dbName][layoutName].positionMode = value
                    bar:ApplyLayout(layoutName)
                end,
            },
            {
                name = "b",
                parentId = "Bar Settings",
                order = 304,
                kind = LEM.SettingType.Divider,
            },
            {
                parentId = "Bar Settings",
                order = 305,
                name = "Show Ticks When Available",
                kind = LEM.SettingType.CheckboxColor,
                default = defaults.showTicks,
                colorDefault = defaults.tickColor,
                get = function(layoutName)
                    local data = SenseiClassResourceBarDB[dbName][layoutName]
                    if data and data.showTicks ~= nil then
                        return data.showTicks
                    else
                        return defaults.showTicks
                    end
                end,
                colorGet = function(layoutName)
                    local data = SenseiClassResourceBarDB[dbName][layoutName]
                    return data and data.tickColor or defaults.tickColor
                end,
                set = function(layoutName, value)
                    SenseiClassResourceBarDB[dbName][layoutName] = SenseiClassResourceBarDB[dbName][layoutName] or CopyTable(defaults)
                    SenseiClassResourceBarDB[dbName][layoutName].showTicks = value
                    bar:UpdateTicksLayout(layoutName)
                end,
                colorSet = function(layoutName, value)
                    SenseiClassResourceBarDB[dbName][layoutName] = SenseiClassResourceBarDB[dbName][layoutName] or CopyTable(defaults)
                    SenseiClassResourceBarDB[dbName][layoutName].tickColor = value
                    bar:UpdateTicksLayout(layoutName)
                end,
            },
            {
                parentId = "Bar Settings",
                order = 306,
                name = "Tick Thickness",
                kind = LEM.SettingType.Slider,
                default = defaults.tickThickness,
                minValue = 1,
                maxValue = 5,
                valueStep = 1,
                get = function(layoutName)
                    local data = SenseiClassResourceBarDB[dbName][layoutName]
                    return data and data.tickThickness or defaults.tickThickness
                end,
                set = function(layoutName, value)
                    SenseiClassResourceBarDB[dbName][layoutName] = SenseiClassResourceBarDB[dbName][layoutName] or CopyTable(defaults)
                    SenseiClassResourceBarDB[dbName][layoutName].tickThickness = value
                    bar:UpdateTicksLayout(layoutName)
                end,
                isEnabled = function(layoutName)
                    local data = SenseiClassResourceBarDB[dbName][layoutName]
                    return data.showTicks
                end,
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
                name = "c",
                parentId = "Text Settings",
                order = 406,
                kind = LEM.SettingType.Divider,
            },
            {
                parentId = "Text Settings",
                order = 407,
                name = "Show Resource Charge Timer (e.g. Runes)",
                kind = LEM.SettingType.CheckboxColor,
                default = defaults.showFragmentedPowerBarText,
                colorDefault = defaults.fragmentedPowerBarTextColor,
                get = function(layoutName)
                    local data = SenseiClassResourceBarDB[dbName][layoutName]
                    if data and data.showFragmentedPowerBarText ~= nil then
                        return data.showFragmentedPowerBarText
                    else
                        return defaults.showFragmentedPowerBarText
                    end
                end,
                colorGet = function(layoutName)
                    local data = SenseiClassResourceBarDB[dbName][layoutName]
                    return data and data.fragmentedPowerBarTextColor or defaults.fragmentedPowerBarTextColor
                end,
                set = function(layoutName, value)
                    SenseiClassResourceBarDB[dbName][layoutName] = SenseiClassResourceBarDB[dbName][layoutName] or CopyTable(defaults)
                    SenseiClassResourceBarDB[dbName][layoutName].showFragmentedPowerBarText = value
                    bar:ApplyTextVisibilitySettings(layoutName)
                end,
                colorSet = function(layoutName, value)
                    SenseiClassResourceBarDB[dbName][layoutName] = SenseiClassResourceBarDB[dbName][layoutName] or CopyTable(defaults)
                    SenseiClassResourceBarDB[dbName][layoutName].fragmentedPowerBarTextColor = value
                    bar:ApplyFontSettings(layoutName)
                end,
            },
            {
                parentId = "Text Settings",
                order = 408,
                name = "Charge Timer Precision",
                kind = LEM.SettingType.Dropdown,
                default = defaults.fragmentedPowerBarTextPrecision,
                useOldStyle = true,
                values = addonTable.availableTextPrecisions,
                get = function(layoutName)
                    return (SenseiClassResourceBarDB[dbName][layoutName] and SenseiClassResourceBarDB[dbName][layoutName].fragmentedPowerBarTextPrecision) or defaults.fragmentedPowerBarTextPrecision
                end,
                set = function(layoutName, value)
                    SenseiClassResourceBarDB[dbName][layoutName] = SenseiClassResourceBarDB[dbName][layoutName] or CopyTable(defaults)
                    SenseiClassResourceBarDB[dbName][layoutName].fragmentedPowerBarTextPrecision = value
                    bar:UpdateDisplay(layoutName)
                end,
                isEnabled = function(layoutName)
                    local data = SenseiClassResourceBarDB[dbName][layoutName]
                    return data.showFragmentedPowerBarText
                end,
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
    end
}
