local _, addonTable = ...

local LEM = addonTable.LEM or LibStub("LibEQOLEditMode-1.0")
local L = addonTable.L

local SecondaryResourceBarMixin = Mixin({}, addonTable.PowerBarMixin)

function SecondaryResourceBarMixin:OnLoad()
    addonTable.PowerBarMixin.OnLoad(self)

    -- Modules for the special cases requiring more work
    addonTable.TipOfTheSpear:OnLoad(self)
    addonTable.Whirlwind:OnLoad(self)

    -- Initialize Blizzard bar mode
    self:UseBlizzardBarMode()

end

function SecondaryResourceBarMixin:OnEvent(event, ...)
    addonTable.PowerBarMixin.OnEvent(self, event, ...)

    -- Modules for the special cases requiring more work
    addonTable.TipOfTheSpear:OnEvent(self, event, ...)
    addonTable.Whirlwind:OnEvent(self, event, ...)

    -- Update Blizzard bar mode on relevant events
    if event == "PLAYER_ENTERING_WORLD"
        or event == "UPDATE_SHAPESHIFT_FORM"
        or event == "PLAYER_SPECIALIZATION_CHANGED"
        or event == "PLAYER_REGEN_ENABLED"
        or event == "PLAYER_REGEN_DISABLED" then
        -- Use a slight delay for combat events to ensure Blizzard's frame setup completes first
        if event == "PLAYER_REGEN_DISABLED" then
            C_Timer.After(0, function()
                self:UseBlizzardBarMode(nil, true)
            end)
        else
            self:UseBlizzardBarMode()
        end
    end
end

function SecondaryResourceBarMixin:GetResource()
    local playerClass = select(2, UnitClass("player"))
    local secondaryResources = {
        ["DEATHKNIGHT"] = Enum.PowerType.Runes,
        ["DEMONHUNTER"] = {
            [581] = "SOUL_FRAGMENTS_VENGEANCE", -- Vengeance
            [1480] = "SOUL_FRAGMENTS", -- Devourer
        },
        ["DRUID"]       = {
            [0]                     = {
                [102] = Enum.PowerType.Mana, -- Balance
            },
            [DRUID_CAT_FORM]        = Enum.PowerType.ComboPoints,
            [DRUID_MOONKIN_FORM_1]  = Enum.PowerType.Mana,
            [DRUID_MOONKIN_FORM_2]  = Enum.PowerType.Mana,
        },
        ["EVOKER"]      = Enum.PowerType.Essence,
        ["HUNTER"]      = {
            [255] = "TIP_OF_THE_SPEAR", -- Survival
        },
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
            [263]  = "MAELSTROM_WEAPON", -- Enhancement
        },
        ["WARLOCK"]     = Enum.PowerType.SoulShards,
        ["WARRIOR"]     = {
            [72] = "WHIRLWIND",
        },
    }

    local spec = C_SpecializationInfo.GetSpecialization()
    local specID = C_SpecializationInfo.GetSpecializationInfo(spec)

    local resource = secondaryResources[playerClass]

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

function SecondaryResourceBarMixin:GetResourceValue(resource)
    if not resource then return nil, nil end
    local data = self:GetData()
    if not data then return nil, nil end

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

        return maxHealth, stagger
    end

    if resource == "SOUL_FRAGMENTS_VENGEANCE" then
        local current = C_Spell.GetSpellCastCount(228477) or 0 -- Soul Cleave
        local max = 6

        return max, current
    end

    if resource == "SOUL_FRAGMENTS" then
        local auraData = C_UnitAuras.GetPlayerAuraBySpellID(1225789) or C_UnitAuras.GetPlayerAuraBySpellID(1227702) -- Soul Fragments / Collapsing Star
        local current = auraData and auraData.applications or 0
        local max = C_SpellBook.IsSpellKnown(1247534) and 35 or 50 -- Soul Glutton

        -- For performance, only update the foreground when current is below 1, this happens when switching in/out of Void Metamorphosis
        if current <= 1 then
            self:ApplyForegroundSettings()
        end

        return max, current
    end

    if resource == Enum.PowerType.Runes then
        local current = 0
        local max = UnitPowerMax("player", resource)
        if max <= 0 then return nil, nil, nil, nil, nil end

        -- Cache rune cooldown data to avoid redundant GetRuneCooldown calls in UpdateFragmentedPowerDisplay
        if not self._runeCooldownCache then
            self._runeCooldownCache = {}
        end
        
        for i = 1, max do
            local start, duration, runeReady = GetRuneCooldown(i)
            self._runeCooldownCache[i] = { start = start, duration = duration, runeReady = runeReady }
            if runeReady then
                current = current + 1
            end
        end

        return max, current
    end

    if resource == Enum.PowerType.SoulShards then
        local current = UnitPower("player", resource, true)
        local max = UnitPowerMax("player", resource, true)
        if max <= 0 then return nil, nil end

        return max, current
    end

    if resource == "MAELSTROM_WEAPON" then
        local auraData = C_UnitAuras.GetPlayerAuraBySpellID(344179) -- Maelstrom Weapon
        local current = auraData and auraData.applications or 0
        local max = 10

        return max / 2, current
    end

    if resource == "TIP_OF_THE_SPEAR" then
        return addonTable.TipOfTheSpear:GetStacks()
    end

    if resource == "WHIRLWIND" then
        return addonTable.Whirlwind:GetStacks()
    end

    -- Regular secondary resource types
    local current = UnitPower("player", resource)
    local max = UnitPowerMax("player", resource)
    if max <= 0 then return nil, nil end

    return max, current
end

function SecondaryResourceBarMixin:GetTagValues(resource, max, current, precision)
    local pFormat = "%." .. (precision or 0) .. "f"

    local tagValues = addonTable.PowerBarMixin.GetTagValues(self, resource, max, current, precision)

    if resource == "STAGGER" then
        local staggerPercentStr = string.format(pFormat, self._lastStaggerPercent)
        tagValues["[percent]"] = function() return staggerPercentStr end
    end

    if resource == "SOUL_FRAGMENTS_VENGEANCE" then
        tagValues["[percent]"] = function() return '' end -- As the value is secret, cannot get percent for it
    end

    if resource == Enum.PowerType.SoulShards then
        local currentStr = string.format("%s", AbbreviateNumbers(current / 10))
        local percentStr = string.format(pFormat, UnitPowerPercent("player", resource, true, CurveConstants.ScaleTo100))
        local maxStr = string.format("%s", AbbreviateNumbers(max / 10))
        tagValues = {
            ["[current]"] = function() return currentStr end,
            ["[percent]"] = function() return percentStr end,
            ["[max]"] = function() return maxStr end,
        }
    end

    if resource == "MAELSTROM_WEAPON" then
        local percentStr = string.format(pFormat, (current / (max * 2)) * 100)
        local maxStr = string.format("%s", AbbreviateNumbers(max * 2))
        tagValues["[percent]"] = function() return percentStr end
        tagValues["[max]"] = function() return maxStr end
    end

    return tagValues
end

function SecondaryResourceBarMixin:GetPoint(layoutName, ignorePositionMode)
    local data = self:GetData(layoutName)

    if not ignorePositionMode then
        if data and data.positionMode == "Use Primary Resource Bar Position If Hidden" then
            local primaryResource = addonTable.barInstances and addonTable.barInstances["PrimaryResourceBar"]

            if primaryResource then
                primaryResource:ApplyVisibilitySettings(layoutName)
                if not primaryResource:IsShown() then
                    return primaryResource:GetPoint(layoutName, true)
                end
            end
        elseif data and data.positionMode == "Use Health Bar Position If Hidden" then
            local health = addonTable.barInstances and addonTable.barInstances["HealthBar"]

            if health then
                health:ApplyVisibilitySettings(layoutName)
                if not health:IsShown() then
                    return health:GetPoint(layoutName, true)
                end
            end
        end
    end

    return addonTable.PowerBarMixin.GetPoint(self, layoutName)
end

function SecondaryResourceBarMixin:ApplyVisibilitySettings(layoutName, inCombat)
    local data = self:GetData(layoutName)
    if not data then return end

    -- If using Blizzard bar, update its visibility and don't show our custom bar
    if data.useBlizzardBar and self:GetBlizzardResourceFrame() then
        self:UseBlizzardBarMode(layoutName, inCombat)
        return
    end

    -- Otherwise use default visibility behavior
    addonTable.PowerBarMixin.ApplyVisibilitySettings(self, layoutName, inCombat)
end

function SecondaryResourceBarMixin:OnShow()
    local data = self:GetData()

    if data and data.positionMode ~= nil and data.positionMode ~= "Self" then
        self:ApplyLayout()
    end
end

function SecondaryResourceBarMixin:OnHide()
    local data = self:GetData()

    if data and data.positionMode ~= nil and data.positionMode ~= "Self" then
        self:ApplyLayout()
    end
end

function SecondaryResourceBarMixin:GetBlizzardResourceFrame()
    local playerClass = select(2, UnitClass("player"))
    local blizzardResourceFrames = {
        ["DEATHKNIGHT"] = RuneFrame,
        ["DRUID"] = DruidComboPointBarFrame,
        ["EVOKER"] = EssencePlayerFrame,
        ["MAGE"] = MageArcaneChargesFrame,
        ["MONK"] = MonkHarmonyBarFrame,
        ["PALADIN"] = PaladinPowerBarFrame,
        ["ROGUE"] = RogueComboPointBarFrame,
        ["WARLOCK"] = WarlockPowerFrame,
    }

    return blizzardResourceFrames[playerClass]
end

-- Determine if bar should be visible based on visibility settings
function SecondaryResourceBarMixin:ShouldBeVisible(layoutName, inCombat)
    local data = self:GetData(layoutName)
    if not data then return false end

    -- Always visible in Edit Mode
    if LEM:IsInEditMode() then
        return true
    end

    local resource = self:GetResource()
    if not resource then
        return false
    end

    local playerClass = select(2, UnitClass("player"))
    local spec = C_SpecializationInfo.GetSpecialization()
    local specID = C_SpecializationInfo.GetSpecializationInfo(spec)
    local role = select(5, C_SpecializationInfo.GetSpecializationInfo(spec))
    local formID = GetShapeshiftFormID()

    -- Hide mana on role (not on arcane mage)
    if resource == Enum.PowerType.Mana and data.hideManaOnRole and data.hideManaOnRole[role] and specID ~= 62 then
        return false
    end

    -- Hide while mounted/vehicle
    local isDruidInFlightForm = playerClass == "DRUID" and (formID == DRUID_FLIGHT_FORM or formID == DRUID_TRAVEL_FORM or formID == DRUID_ACQUATIC_FORM)
    if data.hideWhileMountedOrVehicule and (IsMounted() or UnitInVehicle("player") or isDruidInFlightForm) then
        return false
    end

    -- Always hide in Pet Battles
    if C_PetBattles.IsInBattle() then
        return false
    end

    -- Check visibility mode
    if data.barVisible == "Always Visible" then
        return true
    elseif data.barVisible == "Hidden" then
        return false
    elseif data.barVisible == "In Combat" then
        inCombat = inCombat or InCombatLockdown()
        return inCombat
    elseif data.barVisible == "Has Target Selected" then
        return UnitExists("target")
    elseif data.barVisible == "Has Target Selected OR In Combat" then
        inCombat = inCombat or InCombatLockdown()
        return UnitExists("target") or inCombat
    end

    return true
end

function SecondaryResourceBarMixin:UseBlizzardBarMode(layoutName, inCombat)
    local data = self:GetData(layoutName)
    if not data then return end

    local blizzardFrame = self:GetBlizzardResourceFrame()
    if not blizzardFrame then
        -- No Blizzard bar for this class, show custom bar
        self.Frame:Show()
        self:ApplyVisibilitySettings(layoutName)
        return
    end

    if data.useBlizzardBar then
        local shouldBeVisible = self:ShouldBeVisible(layoutName, inCombat)

        -- Ensure frame is shown (Show is not protected, can be called during combat)
        -- This is needed because SetAlpha on a hidden frame has no effect
        blizzardFrame:Show()

        -- Use SetAlpha for visibility control to avoid triggering
        -- Blizzard's repositioning logic that can happen on Show()/Hide()
        if shouldBeVisible then
            blizzardFrame:SetAlpha(1)
        else
            blizzardFrame:SetAlpha(0)
        end

        -- Cannot modify frame positions during combat
        if InCombatLockdown() then return end

        -- Not in combat - we can safely position the frame

        -- Get the saved position
        local point, relativeFrame, relativePoint, x, y = self:GetPoint(layoutName, true)

        -- Apply scale if the Blizzard frame supports it
        local scale = data.scale or self.defaults.scale or 1
        if blizzardFrame.SetScale then
            blizzardFrame:SetScale(scale)
        end

        -- In Edit Mode, show our custom bar as a placeholder for positioning
        if LEM:IsInEditMode() then
            self.Frame:Show()
            -- Make it semi-transparent to indicate it's a placeholder
            self.Frame:SetAlpha(0.5)

            -- Match placeholder size to Blizzard bar size (visual only, doesn't change saved settings)
            local blizzardWidth, blizzardHeight = blizzardFrame:GetSize()
            if blizzardWidth and blizzardHeight and blizzardWidth > 0 and blizzardHeight > 0 then
                -- Apply scale to match the scaled Blizzard bar appearance
                self.Frame:SetSize(blizzardWidth * scale, blizzardHeight * scale)
            end

            -- Position the placeholder at the saved location
            self.Frame:ClearAllPoints()
            self.Frame:SetPoint(point, relativeFrame, relativePoint, x, y)

            -- Anchor Blizzard bar directly to the placeholder so they move together during drag
            blizzardFrame:ClearAllPoints()
            blizzardFrame:SetPoint("CENTER", self.Frame, "CENTER", 0, 0)
        else
            self.Frame:Hide()

            -- Position Blizzard bar at the saved location
            blizzardFrame:ClearAllPoints()
            blizzardFrame:SetPoint(point, relativeFrame, relativePoint, x, y)
        end

        -- Disable Edit Mode dragging for the Blizzard bar since it's managed by our addon
        if blizzardFrame.SetIgnoreParentScale then
            blizzardFrame:SetIgnoreParentScale(false)
        end
    else
        -- Restore Blizzard bar to default behavior
        -- Clear our positioning
        if blizzardFrame.ClearAllPoints then
            blizzardFrame:ClearAllPoints()
        end

        -- Reset to default position (under PlayerFrame)
        if blizzardFrame.SetPoint then
            blizzardFrame:SetPoint("TOP", PlayerFrame, "BOTTOM", 0, 16)
        end

        -- Reset scale
        if blizzardFrame.SetScale then
            blizzardFrame:SetScale(1)
        end

        -- Respect the hideBlizzardSecondaryResourceUi setting
        self:HideBlizzardSecondaryResource(layoutName)

        -- Show our custom bar
        self.Frame:Show()
        self.Frame:SetAlpha(1.0)  -- Restore full opacity
        self:ApplyVisibilitySettings(layoutName)
        self:ApplyLayout(layoutName)
    end
end

function SecondaryResourceBarMixin:ApplyLayout(layoutName, force)
    local data = self:GetData(layoutName)

    -- If using Blizzard bar, update its position instead
    if data and data.useBlizzardBar then
        self:UseBlizzardBarMode(layoutName)
        return
    end

    -- Otherwise use default layout behavior
    addonTable.PowerBarMixin.ApplyLayout(self, layoutName, force)
end

addonTable.SecondaryResourceBarMixin = SecondaryResourceBarMixin

addonTable.RegisteredBar = addonTable.RegisteredBar or {}
addonTable.RegisteredBar.SecondaryResourceBar = {
    mixin = addonTable.SecondaryResourceBarMixin,
    dbName = "SecondaryResourceBarDB",
    editModeName = L["SECONDARY_POWER_BAR_EDIT_MODE_NAME"],
    frameName = "SecondaryResourceBar",
    frameLevel = 2,
    defaultValues = {
        point = "CENTER",
        x = 0,
        y = -40,
        positionMode = "Self",
        hideBlizzardSecondaryResourceUi = false,
        useBlizzardBar = false,
        hideManaOnRole = {},
        showManaAsPercent = false,
        showTicks = true,
        tickColor = {r = 0, g = 0, b = 0, a = 1},
        tickThickness = 1,
        useResourceAtlas = false,
    },
    lemSettings = function(bar, defaults)
        local config = bar:GetConfig()
        local dbName = config.dbName

        return {
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
            },
            {
                parentId = L["CATEGORY_BAR_VISIBILITY"],
                order = 105,
                name = L["HIDE_BLIZZARD_UI"],
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
                tooltip = L["HIDE_BLIZZARD_UI_SECONDARY_POWER_BAR_TOOLTIP"],
                isEnabled = function(layoutName)
                    local data = SenseiClassResourceBarDB[dbName][layoutName]
                    return not (data and data.useBlizzardBar)
                end,
            },
            {
                parentId = L["CATEGORY_BAR_VISIBILITY"],
                order = 106,
                name = L["USE_BLIZZARD_BAR"],
                kind = LEM.SettingType.Checkbox,
                default = defaults.useBlizzardBar,
                get = function(layoutName)
                    local data = SenseiClassResourceBarDB[dbName][layoutName]
                    if data and data.useBlizzardBar ~= nil then
                        return data.useBlizzardBar
                    else
                        return defaults.useBlizzardBar
                    end
                end,
                set = function(layoutName, value)
                    SenseiClassResourceBarDB[dbName][layoutName] = SenseiClassResourceBarDB[dbName][layoutName] or CopyTable(defaults)
                    SenseiClassResourceBarDB[dbName][layoutName].useBlizzardBar = value
                    bar:UseBlizzardBarMode(layoutName)
                end,
                tooltip = L["USE_BLIZZARD_BAR_TOOLTIP"],
            },
            {
                parentId = L["CATEGORY_POSITION_AND_SIZE"],
                order = 201,
                name = L["POSITION"],
                kind = LEM.SettingType.Dropdown,
                default = defaults.positionMode,
                useOldStyle = true,
                values = addonTable.availablePositionModeOptions(config),
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
            {
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
            },
            {
                parentId = L["CATEGORY_TEXT_SETTINGS"],
                order = 506,
                kind = LEM.SettingType.Divider,
            },
            {
                parentId = L["CATEGORY_TEXT_SETTINGS"],
                order = 507,
                name = L["SHOW_RESOURCE_CHARGE_TIMER"],
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
                parentId = L["CATEGORY_TEXT_SETTINGS"],
                order = 508,
                name = L["CHARGE_TIMER_PRECISION"],
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
        }
    end
}
