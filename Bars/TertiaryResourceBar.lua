local _, addonTable = ...

local LEM = addonTable.LEM or LibStub("LibEQOLEditMode-1.0")

local TertiaryResourceBarMixin = Mixin({}, addonTable.PowerBarMixin)
local buildVersion = select(4, GetBuildInfo())

function TertiaryResourceBarMixin:GetResource()
    local playerClass = select(2, UnitClass("player"))
    local tertiaryResources = {
        ["DEATHKNIGHT"] = nil,
        ["DEMONHUNTER"] = nil,
        ["DRUID"]       = nil,
        ["EVOKER"]      = {
            [1473] = "EBON_MIGHT", -- Augmentation
        },
        ["HUNTER"]      = nil,
        ["MAGE"]        = nil,
        ["MONK"]        = nil,
        ["PALADIN"]     = nil,
        ["PRIEST"]      = nil,
        ["ROGUE"]       = nil,
        ["SHAMAN"]      = nil,
        ["WARLOCK"]     = nil,
        ["WARRIOR"]     = nil,
    }

    local spec = C_SpecializationInfo.GetSpecialization()
    local specID = C_SpecializationInfo.GetSpecializationInfo(spec)

    -- Druid: form-based
    if playerClass == "DRUID" then
        local formID = GetShapeshiftFormID()
        return tertiaryResources[playerClass] and tertiaryResources[playerClass][formID or 0]
    end

    if type(tertiaryResources[playerClass]) == "table" then
        return tertiaryResources[playerClass][specID]
    else 
        return tertiaryResources[playerClass]
    end
end

function TertiaryResourceBarMixin:GetResourceValue(resource)
    if not resource then return nil, nil end
    local data = self:GetData()
    if not data then return nil, nil end

    if resource == "EBON_MIGHT" then
        local auraData = C_UnitAuras.GetPlayerAuraBySpellID(395296) -- Ebon Might
        local current = auraData and (auraData.expirationTime - GetTime()) or 0
        local max = 20

        return max, current
    end

    local current = UnitPower("player", resource)
    local max = UnitPowerMax("player", resource)
    if max <= 0 then return nil, nil, nil, nil end

    return max, current
end

function TertiaryResourceBarMixin:GetTagValues(resource, max, current, precision)
    local tagValues = addonTable.PowerBarMixin:GetTagValues(resource, max, current, precision)

    if resource == "EBON_MIGHT" then
        tagValues["[current]"] = function() return string.format("%.1f", AbbreviateNumbers(current)) end
    end

    return tagValues
end

addonTable.TertiaryResourceBarMixin = TertiaryResourceBarMixin

addonTable.RegisteredBar = addonTable.RegisteredBar or {}
addonTable.RegisteredBar.TertiaryResourceBar = {
    mixin = addonTable.TertiaryResourceBarMixin,
    dbName = "tertiaryResourceBarDB",
    editModeName = "Ebon Might Bar",
    frameName = "TertiaryResourceBar",
    frameLevel = 1,
    defaultValues = {
        point = "CENTER",
        x = 0,
        y = -80,
        useResourceAtlas = false,
    },
    allowEditPredicate = function()
        local spec = C_SpecializationInfo.GetSpecialization()
        local specID = C_SpecializationInfo.GetSpecializationInfo(spec)
        return specID == 1473 -- Augmentation
    end,
    loadPredicate = function()
        local playerClass = select(2, UnitClass("player"))
        return playerClass == "EVOKER"
    end,
    lemSettings = function(bar, defaults)
        local dbName = bar:GetConfig().dbName

        return {
            {
                parentId = "Bar Style",
                order = 401,
                name = "Use Resource Texture And Color",
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