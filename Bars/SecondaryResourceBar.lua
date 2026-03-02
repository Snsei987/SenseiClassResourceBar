local _, addonTable = ...

local LEM = addonTable.LEM or LibStub("LibEQOLEditMode-1.0")
local L = addonTable.L

local SecondaryResourceBarMixin = Mixin({}, addonTable.PowerBarMixin)

function SecondaryResourceBarMixin:OnLoad()
    addonTable.PowerBarMixin.OnLoad(self)

    -- Modules for the special cases requiring more work
    addonTable.TipOfTheSpear:OnLoad(self)
    addonTable.Whirlwind:OnLoad(self)
end

function SecondaryResourceBarMixin:OnEvent(event, ...)
    addonTable.PowerBarMixin.OnEvent(self, event, ...)

    -- Modules for the special cases requiring more work
    addonTable.TipOfTheSpear:OnEvent(self, event, ...)
    addonTable.Whirlwind:OnEvent(self, event, ...)
end

function SecondaryResourceBarMixin:GetResource()
    local playerClass = select(2, UnitClass("player"))
    self._resourceTable = self._resourceTable or {
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
            [72] = "WHIRLWIND", -- Fury
        },
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

function SecondaryResourceBarMixin:GetResourceValue(resource)
    if not resource then return nil, nil end
    local data = self:GetData()
    if not data then return nil, nil end

    if resource == "STAGGER" then
        local stagger = UnitStagger("player") or 0
        local maxHealth = UnitHealthMax("player") or 1

        -- Sometimes the stagger is secret (even though Blizzard said it's not), so just skip the computation if secret
        if issecretvalue(stagger) then
            return maxHealth, stagger
        end

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
        local spec = C_SpecializationInfo.GetSpecialization()
        local specID = C_SpecializationInfo.GetSpecializationInfo(spec)

        -- If true, current and max will be something like 14 for 1.4 shard, instead of 1
        local preciseResourceCount = specID == 267

        local current = UnitPower("player", resource, preciseResourceCount)
        local max = UnitPowerMax("player", resource, preciseResourceCount)
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
        local spec = C_SpecializationInfo.GetSpecialization()
        local specID = C_SpecializationInfo.GetSpecializationInfo(spec)

        if specID == 267 then
            current = current / 10
            max = max / 10
        end

        local currentStr = string.format("%s", AbbreviateNumbers(current))
        local maxStr = string.format("%s", AbbreviateNumbers(max))
        tagValues["[current]"] = function() return currentStr end
        tagValues["[max]"] = function() return maxStr end
    end

    if resource == "MAELSTROM_WEAPON" then
        local percentStr = string.format(pFormat, (current / (max * 2)) * 100)
        local maxStr = string.format("%s", AbbreviateNumbers(max * 2))
        tagValues["[percent]"] = function() return percentStr end
        tagValues["[max]"] = function() return maxStr end
    end

    return tagValues
end

function SecondaryResourceBarMixin:ApplyVisibilitySettings(layoutName, inCombat)
    local data = self:GetData(layoutName)
    if not data then return end

    -- If using Blizzard bar, delegate to UseBlizzardBarMode which handles
    -- both compatible and incompatible specs (falling back to custom bar)
    if data.useBlizzardBar then
        self:UseBlizzardBarMode(layoutName, inCombat)
        return
    end

    self:HideBlizzardSecondaryResource(layoutName, data)

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

function SecondaryResourceBarMixin:HideBlizzardSecondaryResource(layoutName, data)
    data = data or self:GetData(layoutName)
    if not data then return end

    -- Blizzard Frames are protected in combat
    if data.hideBlizzardSecondaryResourceUi == nil or InCombatLockdown() then return end

    local playerClass = select(2, UnitClass("player"))

    for class, frameData in pairs(addonTable.blizzardResourceFrames) do
        local f = frameData.frame
        if f and playerClass == class then
            if data.hideBlizzardSecondaryResourceUi == true then
                if LEM:IsInEditMode() then
                    if class ~= "DRUID" or (class == "DRUID" and GetShapeshiftFormID() == DRUID_CAT_FORM) then
                        f:Show()
                    end
                else
                    f:Hide()
                end
            elseif class ~= "DRUID" or (class == "DRUID" and GetShapeshiftFormID() == DRUID_CAT_FORM) then
                f:Show()
            end
        end
    end
end

-- Returns the Blizzard frame for the class (regardless of spec compatibility)
function SecondaryResourceBarMixin:GetBlizzardFrameForClass()
    local playerClass = select(2, UnitClass("player"))
    local frameData = addonTable.blizzardResourceFrames[playerClass]
    return frameData and frameData.frame
end

-- Returns the Blizzard frame only if it matches the current spec's resource
function SecondaryResourceBarMixin:GetBlizzardResourceFrame()
    local playerClass = select(2, UnitClass("player"))
    local frameData = addonTable.blizzardResourceFrames[playerClass]
    if not frameData then
        return nil
    end

    -- Check if the current spec's resource matches what the Blizzard bar displays
    -- If not, return nil to fall back to the custom bar
    local currentResource = self:GetResource()
    if currentResource ~= frameData.resource then
        return nil
    end

    return frameData.frame
end

-- Returns the screen-space offset between the frame's center and the
-- average center of its visible children, plus the ratio of visual content
-- size to frame size. For frames like RogueComboPointBarFrame where the content
-- extends beyond the frame bounds (e.g. 7 combo points in a 5-CP-wide frame),
-- this lets us position and size the placeholder accurately.
-- Returns: offsetX, offsetY, widthRatio, heightRatio
function SecondaryResourceBarMixin:GetBlizzardFrameContentOffset(blizzardFrame)
    local frameCX, frameCY = blizzardFrame:GetCenter()
    if not frameCX or not frameCY then return 0, 0, 1, 1 end

    local children = {blizzardFrame:GetChildren()}
    if #children == 0 then return 0, 0, 1, 1 end

    local sumCX, sumCY, count = 0, 0, 0
    local minLeft, maxRight = math.huge, -math.huge
    local minBottom, maxTop = math.huge, -math.huge

    for _, child in ipairs(children) do
        if child:IsShown() then
            local cx, cy = child:GetCenter()
            local left, right = child:GetLeft(), child:GetRight()
            local bottom, top = child:GetBottom(), child:GetTop()
            if cx and cy and left and right and bottom and top then
                sumCX = sumCX + cx
                sumCY = sumCY + cy
                count = count + 1
                minLeft = math.min(minLeft, left)
                maxRight = math.max(maxRight, right)
                minBottom = math.min(minBottom, bottom)
                maxTop = math.max(maxTop, top)
            end
        end
    end

    if count == 0 then return 0, 0, 1, 1 end

    local offsetX = (sumCX / count) - frameCX
    local offsetY = (sumCY / count) - frameCY

    -- Only return offset if significant (avoids floating point noise on centered frames)
    if math.abs(offsetX) < 0.5 then offsetX = 0 end
    if math.abs(offsetY) < 0.5 then offsetY = 0 end

    -- Compute ratio of visual content size to frame size
    local frameLeft, frameRight = blizzardFrame:GetLeft(), blizzardFrame:GetRight()
    local frameBottom, frameTop = blizzardFrame:GetBottom(), blizzardFrame:GetTop()
    local widthRatio, heightRatio = 1, 1

    if frameLeft and frameRight and frameBottom and frameTop then
        local frameScreenW = frameRight - frameLeft
        local frameScreenH = frameTop - frameBottom
        if frameScreenW > 0 then
            local visualScreenW = maxRight - minLeft
            local r = visualScreenW / frameScreenW
            if math.abs(r - 1) > 0.05 then widthRatio = r end
        end
        if frameScreenH > 0 then
            local visualScreenH = maxTop - minBottom
            local r = visualScreenH / frameScreenH
            if math.abs(r - 1) > 0.05 then heightRatio = r end
        end
    end

    return offsetX, offsetY, widthRatio, heightRatio
end

-- Determine if bar should be visible based on visibility settings.
-- Uses the parent's ApplyVisibilitySettings to decide, then reads the result
-- from self.Frame:IsShown(). This avoids duplicating the parent's visibility logic.
function SecondaryResourceBarMixin:ShouldBeVisible(layoutName, inCombat)
    if LEM:IsInEditMode() then
        return true
    end

    addonTable.PowerBarMixin.ApplyVisibilitySettings(self, layoutName, inCombat)
    local visible = self.Frame:IsShown()
    self.Frame:Hide()
    return visible
end

function SecondaryResourceBarMixin:UseBlizzardBarMode(layoutName, inCombat)
    local data = self:GetData(layoutName)
    if not data then return end

    local blizzardFrame = self:GetBlizzardResourceFrame()
    if not blizzardFrame then
        -- No compatible Blizzard bar for current spec, fall back to custom bar
        -- Hide the class's Blizzard bar if it exists (e.g., Chi bar for Brewmaster)
        local classBlizzardFrame = self:GetBlizzardFrameForClass()
        if classBlizzardFrame and data.useBlizzardBar and not InCombatLockdown() then
            classBlizzardFrame:Hide()
        end
        -- Use the custom bar as if useBlizzardBar wasn't enabled
        self.Frame:Show()
        self.Frame:SetAlpha(1.0)
        addonTable.PowerBarMixin.ApplyLayout(self, layoutName)
        addonTable.PowerBarMixin.ApplyVisibilitySettings(self, layoutName, inCombat)
        self:UpdateDisplay(true)
        return
    end

    if data.useBlizzardBar then
        -- One-time setup: intercept SetPoint and ClearAllPoints so that Blizzard's
        -- layout system and other addons cannot move the frame while active.
        -- Intercepts are installed once and never removed; behavior is controlled
        -- by _useBlizzardBarActive (block/passthrough) and _allowBlizzardFramePositioning.
        if not self._blizzardFrameIntercepted then
            self._blizzardFrameIntercepted = true

            local originalSetPoint = blizzardFrame.SetPoint
            local originalClearAllPoints = blizzardFrame.ClearAllPoints
            blizzardFrame.SetPoint = function(frame, ...)
                if not self._useBlizzardBarActive or self._allowBlizzardFramePositioning then
                    originalSetPoint(frame, ...)
                end
            end
            blizzardFrame.ClearAllPoints = function(frame, ...)
                if not self._useBlizzardBarActive or self._allowBlizzardFramePositioning then
                    originalClearAllPoints(frame, ...)
                end
            end

            -- Reparent to UIParent so the frame renders independently of
            -- PlayerFrame (which addons like ElvUI may hide or reparent)
            self._originalParent = blizzardFrame:GetParent()

            -- OnShow hook: re-apply positioning when the frame is re-shown
            -- (e.g. after Toggle User Interface with Alt+Z)
            blizzardFrame:HookScript("OnShow", function()
                if self._useBlizzardBarActive then
                    self:UseBlizzardBarMode()
                end
            end)
        end

        self._useBlizzardBarActive = true
        blizzardFrame:SetParent(UIParent)

        local shouldBeVisible = self:ShouldBeVisible(layoutName, inCombat)

        -- Show the Blizzard frame and use SetAlpha for visibility control
        blizzardFrame:Show()
        blizzardFrame:SetAlpha(shouldBeVisible and 1 or 0)

        -- Get the saved position
        local point, relativeFrame, relativePoint, x, y = self:GetPoint(layoutName, true)

        -- Apply scale
        local scale = data.scale or self.defaults.scale or 1
        blizzardFrame:SetScale(scale)

        -- Compute content offset and size ratio for frames where visual content
        -- isn't centered or extends beyond the frame (e.g. Rogue combo points with talents)
        local contentOffsetX, contentOffsetY, widthRatio, heightRatio = self:GetBlizzardFrameContentOffset(blizzardFrame)

        -- Position the Blizzard frame using the original methods via our flag
        self._allowBlizzardFramePositioning = true

        -- Size placeholder to match Blizzard bar's visual content
        local blizzardWidth, blizzardHeight = blizzardFrame:GetSize()
        if blizzardWidth and blizzardHeight and blizzardWidth > 0 and blizzardHeight > 0 then
            self.Frame:SetSize(blizzardWidth * scale * widthRatio, blizzardHeight * scale * heightRatio)
        end

        -- Position placeholder at the saved location using the user's anchor point
        self.Frame:ClearAllPoints()
        self.Frame:SetPoint(point, relativeFrame, relativePoint, x, y)

        -- Anchor Blizzard bar CENTER-to-CENTER with the placeholder, compensating
        -- for content offset so the visual content aligns with the placeholder.
        -- Using the placeholder as an anchor in both modes ensures Edit Mode and
        -- normal mode always produce the same position regardless of anchor point.
        blizzardFrame:ClearAllPoints()
        blizzardFrame:SetPoint("CENTER", self.Frame, "CENTER", -contentOffsetX, -contentOffsetY)

        if LEM:IsInEditMode() then
            -- In Edit Mode, show the placeholder for drag-and-drop positioning
            self.Frame:Show()
            self.Frame:SetAlpha(0.5)
            self.TextFrame:Hide()
        else
            -- In normal mode, hide the placeholder (it still serves as a position anchor)
            self.Frame:Hide()
        end

        self._allowBlizzardFramePositioning = false

        if blizzardFrame.SetIgnoreParentScale then
            blizzardFrame:SetIgnoreParentScale(false)
        end
    else
        -- Restore Blizzard bar to default behavior
        self._useBlizzardBarActive = false

        if self._blizzardFrameIntercepted and self._originalParent then
            blizzardFrame:SetParent(self._originalParent)
        end

        blizzardFrame:ClearAllPoints()
        blizzardFrame:SetPoint("TOP", PlayerFrame, "BOTTOM", 0, 16)
        blizzardFrame:SetScale(1)

        self:HideBlizzardSecondaryResource(layoutName)

        -- Show our custom bar
        self.Frame:Show()
        self.Frame:SetAlpha(1.0)
        self:ApplyVisibilitySettings(layoutName)
        self:ApplyLayout(layoutName)
    end
end

function SecondaryResourceBarMixin:ApplyLayout(layoutName, force)
    local data = self:GetData(layoutName)

    -- If using Blizzard bar, delegate to UseBlizzardBarMode which handles
    -- both compatible and incompatible specs (falling back to custom bar)
    if data and data.useBlizzardBar then
        self:UseBlizzardBarMode(layoutName)
        return
    end

    addonTable.PowerBarMixin.ApplyLayout(self, layoutName, force)
end

addonTable.SecondaryResourceBarMixin = SecondaryResourceBarMixin

addonTable.RegisteredBar = addonTable.RegisteredBar or {}
addonTable.RegisteredBar.SecondaryResourceBar = {
    mixin = addonTable.SecondaryResourceBarMixin,
    dbName = "SecondaryResourceBarDB",
    editModeName = L["SECONDARY_POWER_BAR_EDIT_MODE_NAME"],
    frameName = "SecondaryResourceBar",
    frameLevel = 6,
    defaultValues = {
        point = "CENTER",
        x = 0,
        y = -40,
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
            {
                parentId = L["CATEGORY_TEXT_SETTINGS"],
                order = 605,
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
                    return data.showText == true
                end,
                tooltip = L["SHOW_MANA_AS_PERCENT_TOOLTIP"],
            },
            {
                parentId = L["CATEGORY_TEXT_SETTINGS"],
                order = 606,
                kind = LEM.SettingType.Divider,
            },
            {
                parentId = L["CATEGORY_TEXT_SETTINGS"],
                order = 607,
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
                order = 608,
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
                    return data.showFragmentedPowerBarText == true
                end,
            },
        }
    end
}
