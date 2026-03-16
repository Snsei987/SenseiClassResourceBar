local _, addonTable = ...

local LEM = addonTable.LEM or LibStub("LibEQOLEditMode-1.0")
local L = addonTable.L

local TertiaryResourceBarMixin = Mixin({}, addonTable.PowerBarMixin)

-- Debuffs are secrets now, so we will have to hook into the CDM to display the Freezs stacks.
local _freezeAuraInstanceID = nil
local _freezeCDMFrame       = nil
local _freezeHooked         = false

local function HasAuraInstanceID(value)
    if value == nil then return false end
    if issecretvalue and issecretvalue(value) then return true end
    return type(value) == "number" and value ~= 0
end

local function SetupFreezeCDMHooks(bar)
    if _freezeHooked then return end
    _freezeHooked = true

    for _, viewer in ipairs({BuffIconCooldownViewer, BuffBarCooldownViewer}) do
        if viewer then
            for _, frame in ipairs({viewer:GetChildren()}) do
                if frame.SetAuraInstanceInfo then
                    hooksecurefunc(frame, "SetAuraInstanceInfo", function(f)
                        if f.auraDataUnit == "target" and HasAuraInstanceID(f.auraInstanceID) then
                            _freezeAuraInstanceID = f.auraInstanceID
                            _freezeCDMFrame = f
                            bar:UpdateDisplay()
                        end
                    end)
                end
                if frame.ClearAuraInstanceInfo then
                    hooksecurefunc(frame, "ClearAuraInstanceInfo", function(f)
                        if f == _freezeCDMFrame then
                            _freezeAuraInstanceID = nil
                            _freezeCDMFrame = nil
                            bar:UpdateDisplay()
                        end
                    end)
                end
            end
        end
    end
end

function TertiaryResourceBarMixin:OnLoad()
    addonTable.PowerBarMixin.OnLoad(self)

    local playerClass = select(2, UnitClass("player"))
    if playerClass == "MAGE" then
        self.Frame:RegisterUnitEvent("UNIT_AURA", "target")
    end
end

function TertiaryResourceBarMixin:OnEvent(event, ...)
    addonTable.PowerBarMixin.OnEvent(self, event, ...)

    if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_SPECIALIZATION_CHANGED" then
        SetupFreezeCDMHooks(self)
    elseif event == "PLAYER_TARGET_CHANGED" then
        _freezeAuraInstanceID = nil
        _freezeCDMFrame = nil
    elseif event == "UNIT_AURA" and (...) == "target" then
        self:UpdateDisplay()
    end
end

function TertiaryResourceBarMixin:GetResource()
    local playerClass = select(2, UnitClass("player"))
    self._resourceTable = self._resourceTable or {
        ["DEATHKNIGHT"] = nil,
        ["DEMONHUNTER"] = nil,
        ["DRUID"]       = nil,
        ["EVOKER"]      = {
            [1473] = "EBON_MIGHT", -- Augmentation
        },
        ["HUNTER"]      = nil,
        ["MAGE"]        = {
            [64] = "FREEZE", -- Frost
        },
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

    local resource = self._resourceTable[playerClass]

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

    if resource == "FREEZE" then
        local auraData = HasAuraInstanceID(_freezeAuraInstanceID)
            and C_UnitAuras.GetAuraDataByAuraInstanceID("target", _freezeAuraInstanceID)
        return 20, auraData and auraData.applications or 0
    end

    local current = UnitPower("player", resource)
    local max = UnitPowerMax("player", resource)
    if max <= 0 then return nil, nil, nil, nil end

    return max, current
end

function TertiaryResourceBarMixin:GetTagValues(resource, max, current, precision)
    local tagValues = addonTable.PowerBarMixin.GetTagValues(self, resource, max, current, precision)

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
    editModeName = L["TERNARY_POWER_BAR_EDIT_MODE_NAME"],
    frameName = "TertiaryResourceBar",
    frameLevel = 3,
    defaultValues = {
        point = "CENTER",
        x = 0,
        y = -80,
        useResourceAtlas = false,
        tickColor = {r = 0, g = 0, b = 0, a = 1},
        tickThickness = 1,
    },
    allowEditPredicate = function()
        local spec = C_SpecializationInfo.GetSpecialization()
        local specID = C_SpecializationInfo.GetSpecializationInfo(spec)
        return specID == 1473 -- Augmentation
            or specID == 64   -- Frost Mage
    end,
    loadPredicate = function()
        local playerClass = select(2, UnitClass("player"))
        return playerClass == "EVOKER" or playerClass == "MAGE"
    end,
    lemSettings = function(bar, defaults)
        local dbName = bar:GetConfig().dbName

        return {
            {
                parentId = L["CATEGORY_BAR_SETTINGS"],
                order = 304,
                kind = LEM.SettingType.Divider,
            },
            {
                parentId = L["CATEGORY_BAR_SETTINGS"],
                order = 305,
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
                parentId = L["CATEGORY_BAR_SETTINGS"],
                order = 306,
                name = L["TICK_THICKNESS"],
                kind = LEM.SettingType.Slider,
                default = defaults.tickThickness,
                minValue = 1,
                maxValue = 5,
                valueStep = 1,
                get = function(layoutName)
                    local data = SenseiClassResourceBarDB[dbName][layoutName]
                    return data and addonTable.rounded(data.tickThickness) or defaults.tickThickness
                end,
                set = function(layoutName, value)
                    SenseiClassResourceBarDB[dbName][layoutName] = SenseiClassResourceBarDB[dbName][layoutName] or CopyTable(defaults)
                    SenseiClassResourceBarDB[dbName][layoutName].tickThickness = addonTable.rounded(value)
                    bar:UpdateTicksLayout(layoutName)
                end,
                isEnabled = function(layoutName)
                    local data = SenseiClassResourceBarDB[dbName][layoutName]
                    return data.showTicks == true
                end,
            },
            {
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
            },
        }
    end
}
