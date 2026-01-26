local _, addonTable = ...

local LEM = addonTable.LEM or LibStub("LibEQOLEditMode-1.0")
local L = addonTable.L

local PrimaryResourceBarMixin = Mixin({}, addonTable.PowerBarMixin)

function PrimaryResourceBarMixin:GetResource()
    local playerClass = select(2, UnitClass("player"))
    local primaryResources = {
        ["DEATHKNIGHT"] = Enum.PowerType.RunicPower,
        ["DEMONHUNTER"] = Enum.PowerType.Fury,
        ["DRUID"]       = {
            [0]                     = {
                [102] = Enum.PowerType.LunarPower, -- Balance
                [103] = Enum.PowerType.Mana, -- Feral
                [104] = Enum.PowerType.Mana, -- Guardian
                [105] = Enum.PowerType.Mana, -- Restoration
            },
            [DRUID_BEAR_FORM]       = Enum.PowerType.Rage,
            [DRUID_TREE_FORM]       = Enum.PowerType.Mana,
            [36]                    = Enum.PowerType.Mana, -- Tome of the Wilds: Treant Form
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
            [263] = Enum.PowerType.Mana, -- Enhancement
            [264] = Enum.PowerType.Mana, -- Restoration
        },
        ["WARLOCK"]     = Enum.PowerType.Mana,
        ["WARRIOR"]     = Enum.PowerType.Rage,
    }

    local spec = C_SpecializationInfo.GetSpecialization()
    local specID = C_SpecializationInfo.GetSpecializationInfo(spec)

    local resource = primaryResources[playerClass]

    -- Druid: form-based
    if playerClass == "DRUID" then
        local formID = GetShapeshiftFormID()
        resource = resource and resource[formID or 0]
    end

    if type(resource) == "table" then
        return resource[specID]
    else 
        return resource
    end
end

function PrimaryResourceBarMixin:GetResourceValue(resource)
    if not resource then return nil, nil end

    local data = self:GetData()
    if not data then return nil, nil end

    local current = UnitPower("player", resource)
    local max = UnitPowerMax("player", resource)
    if max <= 0 then return nil end

    return max, current
end

addonTable.PrimaryResourceBarMixin = PrimaryResourceBarMixin

addonTable.RegisteredBar = addonTable.RegisteredBar or {}
addonTable.RegisteredBar.PrimaryResourceBar = {
    mixin = addonTable.PrimaryResourceBarMixin,
    dbName = "PrimaryResourceBarDB",
    editModeName = L["PRIMARY_POWER_BAR_EDIT_MODE_NAME"],
    frameName = "PrimaryResourceBar",
    frameLevel = 3,
    defaultValues = {
        point = "CENTER",
        x = 0,
        y = 0,
        hideManaOnRole = {},
        showManaAsPercent = false,
        showTicks = true,
        tickColor = {r = 0, g = 0, b = 0, a = 1},
        tickThickness = 1,
        customTicks = {
            { enabled = false, resource = L["MANA"], value = 25, mode = L["TICK_MODE_PERCENTAGE"] },
            { enabled = false, resource = L["MANA"], value = 50, mode = L["TICK_MODE_PERCENTAGE"] },
            { enabled = false, resource = L["MANA"], value = 75, mode = L["TICK_MODE_PERCENTAGE"] },
            { enabled = false, resource = L["MANA"], value = 100, mode = L["TICK_MODE_FIXED"] },
        },
        useResourceAtlas = false,
    },
    lemSettings = function(bar, defaults)
        local dbName = bar:GetConfig().dbName
        
        -- Resource type options for ticks
        local resourceOptions = {
            { text = L["MANA"] },
            { text = L["RAGE"] },
            { text = L["FOCUS"] },
            { text = L["ENERGY"] },
            { text = L["RUNIC_POWER"] },
            { text = L["LUNAR_POWER"] },
            { text = L["MAELSTORM"] },
            { text = L["INSANITY"] },
            { text = L["FURY"] },
        }

        local settings = {
            {
                parentId = L["CATEGORY_BAR_VISIBILITY"],
                order = 103,
                name = L["HIDE_MANA_ON_ROLE"],
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
                tooltip = L["HIDE_MANA_ON_ROLE_PRIMARY_BAR_TOOLTIP"],
            },
            {
                order = 305,
                name = L["CATEGORY_TICK_SETTINGS"],
                kind = LEM.SettingType.Collapsible,
                id = L["CATEGORY_TICK_SETTINGS"],
                defaultCollapsed = true,
            },
            {
                parentId = L["CATEGORY_TICK_SETTINGS"],
                order = 306,
                name = L["SHOW_TICKS_WHEN_AVAILABLE"],
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
                parentId = L["CATEGORY_TICK_SETTINGS"],
                order = 307,
                name = L["TICK_THICKNESS"],
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
        }
        
        -- Pre-generate settings for up to 4 custom ticks
        for i = 1, 4 do
            local tickIndex = i  -- Capture the value for closures
            local baseOrder = 310 + (tickIndex * 10)
            
            -- Divider
            table.insert(settings, {
                parentId = L["CATEGORY_TICK_SETTINGS"],
                order = baseOrder,
                kind = LEM.SettingType.Divider,
            })
            
            -- Enable checkbox
            table.insert(settings, {
                parentId = L["CATEGORY_TICK_SETTINGS"],
                order = baseOrder + 1,
                name = L["CUSTOM_TICK"] .. " " .. tickIndex,
                kind = LEM.SettingType.Checkbox,
                get = function(layoutName)
                    local data = SenseiClassResourceBarDB[dbName][layoutName]
                    return (data.customTicks and data.customTicks[tickIndex] and data.customTicks[tickIndex].enabled == true) or false
                end,
                set = function(layoutName, value)
                    SenseiClassResourceBarDB[dbName][layoutName] = SenseiClassResourceBarDB[dbName][layoutName] or CopyTable(defaults)
                    local data = SenseiClassResourceBarDB[dbName][layoutName]
                    -- Initialize customTicks if it doesn't exist
                    data.customTicks = data.customTicks or CopyTable(defaults.customTicks)
                    if data.customTicks and data.customTicks[tickIndex] then
                        data.customTicks[tickIndex].enabled = value
                        bar:UpdateTicksLayout(layoutName)
                    end
                end,
            })
            
            -- Resource type dropdown
            table.insert(settings, {
                parentId = L["CATEGORY_TICK_SETTINGS"],
                order = baseOrder + 2,
                name = L["TICK_RESOURCE_TYPE"],
                kind = LEM.SettingType.Dropdown,
                values = resourceOptions,
                useOldStyle = true,
                isEnabled = function(layoutName)
                    local data = SenseiClassResourceBarDB[dbName][layoutName]
                    return data and data.customTicks and data.customTicks[tickIndex] and data.customTicks[tickIndex].enabled or false
                end,
                get = function(layoutName)
                    local data = SenseiClassResourceBarDB[dbName][layoutName]
                    return (data and data.customTicks and data.customTicks[tickIndex] and data.customTicks[tickIndex].resource) or L["MANA"]
                end,
                set = function(layoutName, value)
                    SenseiClassResourceBarDB[dbName][layoutName] = SenseiClassResourceBarDB[dbName][layoutName] or CopyTable(defaults)
                    local data = SenseiClassResourceBarDB[dbName][layoutName]
                    -- Initialize customTicks if it doesn't exist
                    data.customTicks = data.customTicks or CopyTable(defaults.customTicks)
                    if data.customTicks and data.customTicks[tickIndex] then
                        data.customTicks[tickIndex].resource = value
                        bar:UpdateTicksLayout(layoutName)
                    end
                end,
            })
            
            -- Mode dropdown (Percentage vs Fixed)
            table.insert(settings, {
                parentId = L["CATEGORY_TICK_SETTINGS"],
                order = baseOrder + 3,
                name = L["TICK_MODE"],
                kind = LEM.SettingType.Dropdown,
                values = {
                    { text = L["TICK_MODE_PERCENTAGE"] },
                    { text = L["TICK_MODE_FIXED"] },
                },
                useOldStyle = true,
                isEnabled = function(layoutName)
                    local data = SenseiClassResourceBarDB[dbName][layoutName]
                    return data and data.customTicks and data.customTicks[tickIndex] and data.customTicks[tickIndex].enabled or false
                end,
                get = function(layoutName)
                    local data = SenseiClassResourceBarDB[dbName][layoutName]
                    return (data and data.customTicks and data.customTicks[tickIndex] and data.customTicks[tickIndex].mode) or L["TICK_MODE_PERCENTAGE"]
                end,
                set = function(layoutName, value)
                    SenseiClassResourceBarDB[dbName][layoutName] = SenseiClassResourceBarDB[dbName][layoutName] or CopyTable(defaults)
                    local data = SenseiClassResourceBarDB[dbName][layoutName]
                    -- Initialize customTicks if it doesn't exist
                    data.customTicks = data.customTicks or CopyTable(defaults.customTicks)
                    if data.customTicks and data.customTicks[tickIndex] then
                        data.customTicks[tickIndex].mode = value
                        bar:UpdateTicksLayout(layoutName)
                    end
                end,
            })
            
            -- Value input
            table.insert(settings, {
                parentId = L["CATEGORY_TICK_SETTINGS"],
                order = baseOrder + 4,
                name = L["TICK_VALUE"],
                kind = LEM.SettingType.Input,
                numeric = true,
                isEnabled = function(layoutName)
                    local data = SenseiClassResourceBarDB[dbName][layoutName]
                    return data and data.customTicks and data.customTicks[tickIndex] and data.customTicks[tickIndex].enabled or false
                end,
                get = function(layoutName)
                    local data = SenseiClassResourceBarDB[dbName][layoutName]
                    return data.customTicks and data.customTicks[tickIndex] and data.customTicks[tickIndex].value or 50
                end,
                set = function(layoutName, value)
                    SenseiClassResourceBarDB[dbName][layoutName] = SenseiClassResourceBarDB[dbName][layoutName] or CopyTable(defaults)
                    local data = SenseiClassResourceBarDB[dbName][layoutName]
                    -- Initialize customTicks if it doesn't exist
                    data.customTicks = data.customTicks or CopyTable(defaults.customTicks)
                    if data.customTicks and data.customTicks[tickIndex] then
                        data.customTicks[tickIndex].value = value
                        bar:UpdateTicksLayout(layoutName)
                    end
                end,
                tooltip = L["TICK_VALUE"],
            })
        end
        
        -- Add remaining settings
        table.insert(settings, {
            parentId = L["CATEGORY_BAR_STYLE"],
            order = 401,
            name = L["USE_RESOURCE_TEXTURE_AND_COLOR"],
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
        })
        
        table.insert(settings, {
            parentId = L["CATEGORY_TEXT_SETTINGS"],
            order = 505,
            name = L["SHOW_MANA_AS_PERCENT"],
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
            tooltip = L["SHOW_MANA_AS_PERCENT_TOOLTIP"],
        })
        
        return settings
    end,
}