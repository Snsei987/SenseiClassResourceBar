local addonName, addonTable = ...

if not SenseiClassResourceBarDB then
    SenseiClassResourceBarDB = {}
end

------------------------------------------------------------
-- LIBEDITMODE INTEGRATION
------------------------------------------------------------
local LEM = LibStub("LibEditMode")

------------------------------------------------------------
-- COMMON DEFAULTS & DROPDOWN OPTIONS
------------------------------------------------------------
local commonDefaults = {
    point = "CENTER",
    x = 0,
    y = 0,
    barVisible = "Always Visible",
    scale = 1,
    width = 200,
    height = 15,
    widthMode = "Manual",
    smoothProgress = true,
    showText = true,
    showFragmentedPowerBarText = false,
    font = "Fonts\\FRIZQT__.TTF",
    fontSize = 12,
    fontOutline = "OUTLINE",
    textAlign = "CENTER",
    maskAndBorderStyle = "Thin",
    backgroundStyle = "Semi-transparent",
    foregroundStyle = "Fade Left",
}

-- Available bar visibility options
local availableBarVisibilityOptions = {
    { text = "Always Visible", isRadio = true },
    { text = "In Combat", isRadio = true },
    { text = "Has Target Selected", isRadio = true },
    { text = "Has Target Selected OR In Combat", isRadio = true },
    { text = "Hidden", isRadio = true },
}

local availableWidthModes = {
    { text = "Manual", isRadio = true },
    { text = "Sync With Essential Cooldowns", isRadio = true },
    { text = "Sync With Utility Cooldowns", isRadio = true },
}

-- Available font styles
local fontStyles = {
    { text = "Fonts\\FRIZQT__.TTF", isRadio = true },
    { text = "Fonts\\ARIALN.TTF", isRadio = true },
    { text = "Fonts\\MORPHEUS.TTF", isRadio = true },
    { text = "Fonts\\SKURRI.TTF", isRadio = true },
}

-- Available outline styles
local outlineStyles = {
    { text = "NONE", isRadio = true },
    { text = "OUTLINE", isRadio = true },
    { text = "THICKOUTLINE", isRadio = true },
}

-- Available text alignement styles
local availableTextAlignmentStyles = {
    { text = "LEFT", isRadio = true },
    { text = "CENTER", isRadio = true },
    { text = "RIGHT", isRadio = true },
}

-- Available mask and border styles
local maskAndBorderStyles = {
    ["Thin"] = {
        mask = "Interface\\AddOns\\SenseiClassResourceBar\\Textures\\BarBorders\\thin-mask.png",
        border = "Interface\\AddOns\\SenseiClassResourceBar\\Textures\\BarBorders\\thin.png",
    },
    ["Bold"] = {
        mask = "Interface\\AddOns\\SenseiClassResourceBar\\Textures\\BarBorders\\bold-mask.png",
        border = "Interface\\AddOns\\SenseiClassResourceBar\\Textures\\BarBorders\\bold.png",
    },
    ["Slight"] = {
        mask = "Interface\\AddOns\\SenseiClassResourceBar\\Textures\\BarBorders\\slight-mask.png",
        border = "Interface\\AddOns\\SenseiClassResourceBar\\Textures\\BarBorders\\slight.png",
    },
    ["Blizzard Classic"] = {
        mask = "Interface\\AddOns\\SenseiClassResourceBar\\Textures\\BarBorders\\blizzard-classic-mask.png",
        border = "Interface\\AddOns\\SenseiClassResourceBar\\Textures\\BarBorders\\blizzard-classic.png",
    },
    -- Add more styles here as needed
    -- ["style-name"] = {
    --     mask = "path/to/mask.png",
    --     border = "path/to/border.png",
    -- },
}

local availableMaskAndBorderStyles = {}
for styleName, _ in pairs(maskAndBorderStyles) do
    table.insert(availableMaskAndBorderStyles, { text = styleName, isRadio = true })
end

-- Available background styles
local backgroundStyles = {
    ["Semi-transparent"] = { type = "color", r = 0, g = 0, b = 0, a = 0.5 },
    ["Solid Light Grey"] = { type = "texture", value = "Interface\\AddOns\\SenseiClassResourceBar\\Textures\\BarBackgrounds\\bevelled.png" },
    ["Solid Dark Grey"] = { type = "texture", value = "Interface\\AddOns\\SenseiClassResourceBar\\Textures\\BarBackgrounds\\bevelled-grey.png" },
}

local availableBackgroundStyles = {}
for name, _ in pairs(backgroundStyles) do
    table.insert(availableBackgroundStyles, { text = name, isRadio = true })
end

-- Available foreground styles
local foregroundStyles = {
    ["Fade Left"] = "Interface\\AddOns\\SenseiClassResourceBar\\Textures\\BarForegrounds\\fade-left.png",
    ["Fade Top"] = "Interface\\AddOns\\SenseiClassResourceBar\\Textures\\BarForegrounds\\fade-top.png",
    ["Fade Bottom"] = "Interface\\AddOns\\SenseiClassResourceBar\\Textures\\BarForegrounds\\fade-bottom.png",
    ["Solid"] = "Interface\\AddOns\\SenseiClassResourceBar\\Textures\\BarForegrounds\\solid.png",
}

local availableForegroundStyles = {}
for name, _ in pairs(foregroundStyles) do
    table.insert(availableForegroundStyles, { text = name, isRadio = true })
end

-- Power types that should show discrete ticks
local tickedPowerTypes = {
    [Enum.PowerType.ArcaneCharges] = true,
    [Enum.PowerType.Chi] = true,
    [Enum.PowerType.ComboPoints] = true,
    [Enum.PowerType.Essence] = true,
    [Enum.PowerType.HolyPower] = true,
    [Enum.PowerType.Runes] = true,
    [Enum.PowerType.SoulShards] = true,
}

-- Power types that are fragmented (multiple independent segments)
local fragmentedPowerTypes = {
    --[Enum.PowerType.Essence] = true,
    [Enum.PowerType.Runes] = true,
}

------------------------------------------------------------
-- BAR CONFIGURATION
------------------------------------------------------------
local barConfigs = {}

-- PRIMARY RESOURCE BAR
barConfigs.primary = {
    dbName = "PrimaryResourceBarDB",
    name = "Primary Resource Bar",
    defaultValues = {
        point = "CENTER",
        x = 0,
        y = 0,
        showManaAsPercent = false,
    },
    getResource = function()
        local playerClass = select(2, UnitClass("player"))
        local classResources = {
            ["DEATHKNIGHT"] = Enum.PowerType.RunicPower,
            ["DEMONHUNTER"] = Enum.PowerType.Fury,
            ["DRUID"]       = Enum.PowerType.Mana,
            ["EVOKER"]      = Enum.PowerType.Mana,
            ["HUNTER"]      = Enum.PowerType.Focus,
            ["MAGE"]        = Enum.PowerType.Mana,
            ["MONK"]        = Enum.PowerType.Energy,
            ["PALADIN"]     = Enum.PowerType.Mana,
            ["PRIEST"]      = Enum.PowerType.Mana,
            ["ROGUE"]       = Enum.PowerType.Energy,
            ["SHAMAN"]      = Enum.PowerType.Mana,
            ["WARLOCK"]     = Enum.PowerType.Mana,
            ["WARRIOR"]     = Enum.PowerType.Rage,
        }

        -- Druid: form-based
        if playerClass == "DRUID" then
            local form = GetShapeshiftFormID()
            if form == 5 then
                return Enum.PowerType.Rage
            elseif form == 1 then
                return Enum.PowerType.Energy
            elseif form == 31 then
                return Enum.PowerType.LunarPower
            else
                return Enum.PowerType.Mana
            end
        end

        return classResources[playerClass]
    end,
    getValue = function(resource, config, data)
        if not resource then return nil, nil, nil, nil end

        local current = UnitPower("player", resource)
        local max = UnitPowerMax("player", resource)
        if max <= 0 then return nil, nil, nil, nil end

        if data.showManaAsPercent and resource == Enum.PowerType.Mana then
            return max, current, UnitPowerPercent("player", resource, false, true), "percent"
        else
            return max, current, current, "number"
        end
    end,
    lemSettings = function(dbName, defaults, frame)
        return {
            {
                order = 41,
                name = "Show Mana As Percent",
                kind = LEM.SettingType.Checkbox,
                default = defaults.showManaAsPercent,
                get = function(layoutName)
                    local data = SenseiClassResourceBarDB[dbName][layoutName]
                    return data and data.showManaAsPercent or false
                end,
                set = function(layoutName, value)
                    SenseiClassResourceBarDB[dbName][layoutName] = SenseiClassResourceBarDB[dbName][layoutName] or CopyTable(defaults)
                    SenseiClassResourceBarDB[dbName][layoutName].showManaAsPercent = value
                    frame:UpdateDisplay(layoutName)
                end,
            },
        }
    end,
}

-- SECONDARY RESOURCE BAR
barConfigs.secondary = {
    dbName = "SecondaryResourceBarDB",
    name = "Secondary Resource Bar",
    defaultValues = {
        point = "CENTER",
        x = 0,
        y = -40,
        showTicks = true,
        tickWidth = 1,
    },
    getResource = function()
        local _, class = UnitClass("player")
        local secondaryResources = {
            ["DEATHKNIGHT"] = Enum.PowerType.Runes,
            ["DEMONHUNTER"] = nil,
            ["DRUID"]       = nil, -- Through code
            ["EVOKER"]      = Enum.PowerType.Essence,
            ["HUNTER"]      = nil,
            ["MAGE"]        = {
                [62] = Enum.PowerType.ArcaneCharges, -- Arcane
            },
            ["MONK"]        = {
                [268] = "STAGGER", -- Brewmaster
                [269] = Enum.PowerType.Chi, -- Windwalker
            },
            ["PALADIN"]     = Enum.PowerType.HolyPower,
            ["PRIEST"]      = {
                [258] = Enum.PowerType.Insanity, -- Shadow
            },
            ["ROGUE"]       = Enum.PowerType.ComboPoints,
            ["SHAMAN"]      = {
                [262] = Enum.PowerType.Maelstrom, -- Elemental
            },
            ["WARLOCK"]     = Enum.PowerType.SoulShards,
            ["WARRIOR"]     = nil,
        }

        local specID = GetSpecialization()

        -- Druid: form-based
        if class == "DRUID" then
            local form = GetShapeshiftFormID()
            if form == 1 then -- Cat form
                return Enum.PowerType.ComboPoints
            else
                return nil
            end
        end

        return type(secondaryResources[class]) == "table" and secondaryResources[class][specID] or secondaryResources[class]
    end,
    getValue = function(resource, config, data)
        if not resource then return nil, nil, nil, nil end

        -- Handle Brewmaster Stagger separately
        if resource == "STAGGER" then
            local stagger = UnitStagger("player") or 0
            local maxHealth = UnitHealthMax("player") or 1
            return maxHealth, stagger, stagger, "number"
        end

        -- Handle Death Knight Runes with independent reload times
        if resource == Enum.PowerType.Runes then
            local readyCount = 0
            local totalRunes = UnitPowerMax("player", resource)
            if totalRunes <= 0 then return nil, nil, nil, nil end
            
            for i = 1, totalRunes do
                local runeReady = select(3, GetRuneCooldown(i))
                if runeReady then
                    readyCount = readyCount + 1
                end
            end
            
            return totalRunes, readyCount, readyCount, "number"
        end

        if resource == Enum.PowerType.SoulShards then
            local currentDisplay = UnitPower("player", resource)
            local current = UnitPower("player", resource, true)
            local max = UnitPowerMax("player", resource, true)
            if max <= 0 then return nil, nil, nil, nil end

            return max, current, currentDisplay, "number"
        end

        -- Regular secondary resource types
        local current = UnitPower("player", resource)
        local max = UnitPowerMax("player", resource)
        if max <= 0 then return nil, nil, nil, nil end

        return max, current, current, "number"
    end,
    lemSettings = function(dbName, defaults, frame)
        return {
            {
                order = 41,
                name = "Show Resource Charge Timer (e.g. Runes)",
                kind = LEM.SettingType.Checkbox,
                default = defaults.showFragmentedPowerBarText,
                get = function(layoutName)
                    local data = SenseiClassResourceBarDB[dbName][layoutName]
                    return data and data.showFragmentedPowerBarText ~= false
                end,
                set = function(layoutName, value)
                    SenseiClassResourceBarDB[dbName][layoutName] = SenseiClassResourceBarDB[dbName][layoutName] or CopyTable(defaults)
                    SenseiClassResourceBarDB[dbName][layoutName].showFragmentedPowerBarText = value
                    frame:ApplyTextVisibilitySettings(layoutName)
                end,
            },
            {
                order = 42,
                name = "Show Ticks When Available",
                kind = LEM.SettingType.Checkbox,
                default = defaults.showTicks,
                get = function(layoutName)
                    local data = SenseiClassResourceBarDB[dbName][layoutName]
                    if data and data.showTicks ~= nil then
                        return data.showTicks
                    else
                        return defaults.showTicks
                    end
                end,
                set = function(layoutName, value)
                    SenseiClassResourceBarDB[dbName][layoutName] = SenseiClassResourceBarDB[dbName][layoutName] or CopyTable(defaults)
                    SenseiClassResourceBarDB[dbName][layoutName].showTicks = value
                    frame:UpdateTicks(layoutName)
                end,
            },
            {
                order = 43,
                name = "Tick Width",
                kind = LEM.SettingType.Slider,
                default = defaults.tickWidth,
                minValue = 1,
                maxValue = 5,
                valueStep = 1,
                get = function(layoutName)
                    local data = SenseiClassResourceBarDB[dbName][layoutName]
                    return data and data.tickWidth or defaults.tickWidth
                end,
                set = function(layoutName, value)
                    SenseiClassResourceBarDB[dbName][layoutName] = SenseiClassResourceBarDB[dbName][layoutName] or CopyTable(defaults)
                    SenseiClassResourceBarDB[dbName][layoutName].tickWidth = value
                    frame:UpdateTicks(layoutName)
                end,
            },
        }
    end,
}

------------------------------------------------------------
-- BAR FACTORY
------------------------------------------------------------
local function CreateBarInstance(config, parent)
    -- Initialize database
    if not SenseiClassResourceBarDB[config.dbName] then
        SenseiClassResourceBarDB[config.dbName] = {}
    end

    -- Create frame
    local frame = CreateFrame("Frame", config.name, parent or UIParent)
    frame.config = config
    frame.barName = config.name

    -- BACKGROUND
    frame.background = frame:CreateTexture(nil, "BACKGROUND")
    frame.background:SetAllPoints()
    frame.background:SetColorTexture(0, 0, 0, 0.5)

    -- STATUS BAR
    frame.statusBar = CreateFrame("StatusBar", nil, frame)
    frame.statusBar:SetAllPoints()
    frame.statusBar:SetStatusBarTexture("Interface\\AddOns\\SenseiClassResourceBar\\Textures\\BarForegrounds\\fade-left.png")
    frame.statusBar:SetFrameLevel(1)

    -- MASK
    frame.mask = frame.statusBar:CreateMaskTexture()
    frame.mask:SetAllPoints()
    frame.mask:SetTexture("Interface\\AddOns\\SenseiClassResourceBar\\Textures\\BarBorders\\thin-mask.png")

    frame.statusBar:GetStatusBarTexture():AddMaskTexture(frame.mask)
    frame.background:AddMaskTexture(frame.mask)

    -- BORDER
    frame.border = frame:CreateTexture(nil, "OVERLAY")
    frame.border:SetAllPoints()
    frame.border:SetTexture("Interface\\AddOns\\SenseiClassResourceBar\\Textures\\BarBorders\\thin.png")
    frame.border:SetBlendMode("BLEND")
    frame.border:SetVertexColor(0, 0, 0)

    -- TEXT FRAME
    frame.textFrame = CreateFrame("Frame", nil, frame)
    frame.textFrame:SetAllPoints(frame)
    frame.textFrame:SetFrameLevel(frame.statusBar:GetFrameLevel() + 2)

    frame.textValue = frame.textFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.textValue:SetPoint("CENTER", frame.textFrame, "CENTER", 0, 0)
    frame.textValue:SetJustifyH("CENTER")
    frame.textValue:SetText("0")

    -- STATE
    frame.smoothEnabled = false
    frame.updateInterval = 0.05
    frame.elapsed = 0

    -- Fragmented powers (Runes, Essences, Soul Shards) specific visual elements
    frame.fragmentedPowerBars = {}
    frame.fragmentedPowerBarTexts = {}

    -- METHODS
    function frame:CreateFragmentedPowerBars(layoutName)
        layoutName = layoutName or LEM.GetActiveLayoutName() or "Default"
        local data = SenseiClassResourceBarDB[self.config.dbName][layoutName]
        if not data then return end

        local defaults = CopyTable(commonDefaults)
        for k, v in pairs(self.config.defaultValues or {}) do
            defaults[k] = v
        end

        local resource = self.config.getResource()
        if not resource then return end
        for i = 1, UnitPowerMax("player", resource) or 0 do
            if not self.fragmentedPowerBars[i] then
                -- Create a small status bar for each rune (behind main bar, in front of background)
                local bar = CreateFrame("StatusBar", nil, self)

                local fgStyleName = data.foregroundStyle or defaults.foregroundStyle
                local fgTexture = foregroundStyles[fgStyleName]
                
                if fgTexture then
                    bar:SetStatusBarTexture(fgTexture)
                end
                bar:GetStatusBarTexture():AddMaskTexture(self.mask)
                bar:SetOrientation("HORIZONTAL")
                bar:SetFrameLevel(1)
                self.fragmentedPowerBars[i] = bar
                
                -- Create text for reload time display
                local text = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                text:SetPoint("CENTER", bar, "CENTER", 0, 0)
                text:SetJustifyH("CENTER")
                text:SetText("")
                self.fragmentedPowerBarTexts[i] = text
            end
        end
    end

    function frame:UpdateFragmentedPowerVisuals(layoutName)
        layoutName = layoutName or LEM.GetActiveLayoutName() or "Default"
        local data = SenseiClassResourceBarDB[self.config.dbName][layoutName]
        if not data then return end

        local defaults = CopyTable(commonDefaults)
        for k, v in pairs(self.config.defaultValues or {}) do
            defaults[k] = v
        end
        
        local resource = self.config.getResource()
        if not resource then return end
        local maxPower = UnitPowerMax("player", resource)
        if maxPower <= 0 then return end

        local barWidth = self:GetWidth()
        local barHeight = self:GetHeight()
        local fragmentedBarWidth = barWidth / maxPower
        
        -- Hide the main status bar fill (we display bars representing one (1) unit of resource each)
        self.statusBar:SetAlpha(0)

        local color = self:GetResourceColor(resource)

        if resource == Enum.PowerType.Runes then
            -- Collect rune states: ready and recharging
            local readyList = {}
            local cdList = {}
            local now = GetTime()
            for i = 1, maxPower do
                local start, duration, runeReady = GetRuneCooldown(i)
                if runeReady then
                    table.insert(readyList, { index = i })
                else
                    if start and duration and duration > 0 then
                        local elapsed = now - start
                        local remaining = math.max(0, duration - elapsed)
                        local frac = math.max(0, math.min(1, elapsed / duration))
                        table.insert(cdList, { index = i, remaining = remaining, frac = frac })
                    else
                        table.insert(cdList, { index = i, remaining = math.huge, frac = 0 })
                    end
                end
            end

            -- Sort cdList by ascending remaining time (least remaining on the left of the CD group)
            table.sort(cdList, function(a, b)
                return a.remaining < b.remaining
            end)

            -- Build final display order: ready runes first (left), then CD runes sorted by remaining
            local displayOrder = {}
            local readyLookup = {}
            local cdLookup = {}
            for _, v in ipairs(readyList) do
                table.insert(displayOrder, v.index)
                readyLookup[v.index] = true
            end
            for _, v in ipairs(cdList) do
                table.insert(displayOrder, v.index)
                cdLookup[v.index] = v
            end

            for pos = 1, #displayOrder do
                local runeIndex = displayOrder[pos]
                local runeFrame = self.fragmentedPowerBars[runeIndex]
                local runeText = self.fragmentedPowerBarTexts[runeIndex]

                if runeFrame then
                    runeFrame:SetSize(fragmentedBarWidth, barHeight)
                    runeFrame:ClearAllPoints()
                    runeFrame:SetPoint("LEFT", self, "LEFT", (pos - 1) * fragmentedBarWidth, 0)

                    if readyLookup[runeIndex] then
                        runeFrame:SetMinMaxValues(0, 1)
                        runeFrame:SetValue(1)
                        runeText:SetText("")
                        runeFrame:SetStatusBarColor(color.r, color.g, color.b)
                    else
                        local cdInfo = cdLookup[runeIndex]
                        if cdInfo then
                            runeFrame:SetMinMaxValues(0, 1)
                            runeFrame:SetValue(cdInfo.frac)
                            runeText:SetText(string.format("%.1f", math.max(0, cdInfo.remaining)))
                            runeFrame:SetStatusBarColor(color.r * 0.5, color.g * 0.5, color.b * 0.5)
                        else
                            runeFrame:SetMinMaxValues(0, 1)
                            runeFrame:SetValue(0)
                            runeText:SetText("")
                            runeFrame:SetStatusBarColor(color.r * 0.5, color.g * 0.5, color.b * 0.5)
                        end
                    end

                    runeFrame:Show()
                    self:ApplyFontSettings(layoutName)
                end
            end

            -- Hide any extra rune frames beyond current maxPower
            for i = maxPower + 1, #self.fragmentedPowerBars do
                if self.fragmentedPowerBars[i] then
                    self.fragmentedPowerBars[i]:Hide()
                    if self.fragmentedPowerBarTexts[i] then
                        self.fragmentedPowerBarTexts[i]:SetText("")
                    end
                end
            end
        end
    end

    function frame:GetResourceColor(resource)
        local color = nil

        if resource == "STAGGER" then
            color = { r = 0.5216, g = 1.0, b = 0.5216 }
        elseif resource == Enum.PowerType.Runes then
            local spec = GetSpecialization()
            local specID = GetSpecializationInfo(spec)

            if specID == 250 then -- Blood
                color = { r = 1, g = 0.2, b = 0.3 }
            elseif specID == 251 then -- Frost
                color = { r = 0.0, g = 0.6, b = 1.0 }
            elseif specID == 252 then -- Unholy
                color = { r = 0.1, g = 1.0, b = 0.1 }
            end
            -- Else fallback on Blizzard Runes color, grey...
        elseif resource == Enum.PowerType.Essence then
            color = { r = 0.0, g = 0.55, b = 0.50 }
        end

        return color or PowerBarColor[resource] or PowerBarColor["MANA"]
    end

    function frame:UpdateDisplay(layoutName)
        layoutName = layoutName or LEM.GetActiveLayoutName() or "Default"
        local data = SenseiClassResourceBarDB[self.config.dbName][layoutName]
        if not data then return end

        local resource = self.config.getResource()
        if not resource then
            if not self._inEditMode then
                self:Hide()
            else 
                -- White bar, "0" text for edit mode is resource does not exist (e.g. Secondary resource for warrior)
                self.textValue:SetText("0")
                self.statusBar:SetStatusBarColor(1, 1, 1)
                self.statusBar:SetMinMaxValues(0, 1)
                self.statusBar:SetValue(1)
            end
            return
        end

        local max, current, displayValue, valueType = self.config.getValue(resource, self.config, data)
        if not max then
            if not self._inEditMode then
                self:Hide()
            end
            return
        end

        self.statusBar:SetMinMaxValues(0, max)
        self.statusBar:SetValue(current)

        if valueType == "percent" then
            self.textValue:SetText(string.format("%.0f%%", displayValue))
        else
            self.textValue:SetText(AbbreviateNumbers(displayValue))
        end

        local color = self:GetResourceColor(resource)
        self.statusBar:SetStatusBarColor(color.r, color.g, color.b)

        if fragmentedPowerTypes[resource] then
            self:UpdateFragmentedPowerVisuals(layoutName)
        end
    end

    function frame:ApplyFontSettings(layoutName)
        layoutName = layoutName or LEM.GetActiveLayoutName() or "Default"
        local data = SenseiClassResourceBarDB[self.config.dbName][layoutName]
        if not data then return end

        local defaults = CopyTable(commonDefaults)
        for k, v in pairs(self.config.defaultValues or {}) do
            defaults[k] = v
        end

        local font = data.font or defaults.font
        local size = data.fontSize or defaults.fontSize
        local outline = data.fontOutline or defaults.fontOutline

        self.textValue:SetFont(font, size, outline)
        self.textValue:SetShadowColor(0, 0, 0, 0.8)
        self.textValue:SetShadowOffset(1, -1)

        for _, fragmentedPowerBarText in ipairs(self.fragmentedPowerBarTexts) do
            fragmentedPowerBarText:SetFont(font, math.max(6, size - 2), outline)
            fragmentedPowerBarText:SetShadowColor(0, 0, 0, 0.8)
            fragmentedPowerBarText:SetShadowOffset(1, -1)
        end

        -- Text alignment: LEFT, CENTER, RIGHT
        local align = data.textAlign or defaults.textAlign or "CENTER"
        self.textValue:SetJustifyH(align)
        -- Re-anchor the text inside the text frame depending on alignment
        self.textValue:ClearAllPoints()
        if align == "LEFT" then
            self.textValue:SetPoint("LEFT", self.textFrame, "LEFT", 4, 0)
        elseif align == "RIGHT" then
            self.textValue:SetPoint("RIGHT", self.textFrame, "RIGHT", -4, 0)
        else
            self.textValue:SetPoint("CENTER", self.textFrame, "CENTER", 0, 0)
        end
    end

    function frame:ApplyMaskAndBorderSettings(layoutName)
        layoutName = layoutName or LEM.GetActiveLayoutName() or "Default"
        local data = SenseiClassResourceBarDB[self.config.dbName][layoutName]
        if not data then return end

        local defaults = CopyTable(commonDefaults)
        for k, v in pairs(self.config.defaultValues or {}) do
            defaults[k] = v
        end

        local styleName = data.maskAndBorderStyle or defaults.maskAndBorderStyle
        local style = maskAndBorderStyles[styleName]
        if not style then return end
        
        if self.mask then
            self.statusBar:GetStatusBarTexture():RemoveMaskTexture(self.mask)
            self.background:RemoveMaskTexture(self.mask)
        end

        if not self.mask then
            self.mask = self.statusBar:CreateMaskTexture()
            self.mask:SetAllPoints()
        end
        self.mask:SetTexture(style.mask)

        self.statusBar:GetStatusBarTexture():AddMaskTexture(self.mask)
        self.background:AddMaskTexture(self.mask)

        self.border:SetTexture(style.border)
    end

    function frame:UpdateTicks(layoutName, resource, max)
        layoutName = layoutName or LEM.GetActiveLayoutName() or "Default"
        resource = resource or self.config.getResource()
        max = max or (resource ~= "STAGGER" and UnitPowerMax("player", resource)) or 0

        local data = SenseiClassResourceBarDB[self.config.dbName][layoutName]
        if not data then return end

        local defaults = CopyTable(commonDefaults)
        for k, v in pairs(self.config.defaultValues or {}) do
            defaults[k] = v
        end

        -- Arbitrarily show 4 ticks for edit mode for preview, if spec does not support it
        if self._inEditMode and data.showTicks == true and resource ~= "STAGGER" and not tickedPowerTypes[resource] then
            max = 5
            resource = Enum.PowerType.ComboPoints
        end

        self.ticks = self.ticks or {}
        if data.showTicks == false or not tickedPowerTypes[resource] then
            for _, t in ipairs(self.ticks) do
                t:Hide()
            end
            return
        end

        local width = self.statusBar:GetWidth()
        local height = self.statusBar:GetHeight()
        if width <= 0 or height <= 0 then return end

        local needed = max - 1
        for i = 1, needed do
            local t = self.ticks[i]
            if not t then
                t = self:CreateTexture(nil, "OVERLAY")
                t:SetColorTexture(0, 0, 0, 1)
                self.ticks[i] = t
            end
            t:SetSize(data.tickWidth or 1, height)
            local x = (i / max) * width
            t:ClearAllPoints()
            t:SetPoint("LEFT", self.statusBar, "LEFT", x - 0.5, 0)
            t:Show()
        end

        -- Hide any extra ticks
        for i = needed + 1, #self.ticks do
            self.ticks[i]:Hide()
        end
    end

    function frame:ApplyBackgroundSettings(layoutName)
        layoutName = layoutName or LEM.GetActiveLayoutName() or "Default"
        local data = SenseiClassResourceBarDB[self.config.dbName][layoutName]
        if not data then return end

        local defaults = CopyTable(commonDefaults)
        for k, v in pairs(self.config.defaultValues or {}) do
            defaults[k] = v
        end

        local bgStyleName = data.backgroundStyle or defaults.backgroundStyle
        local bgConfig = backgroundStyles[bgStyleName]

        if not bgConfig then return end

        if bgConfig.type == "color" then
            self.background:SetColorTexture(bgConfig.r or 1, bgConfig.g or 1, bgConfig.b or 1, bgConfig.a or 1)
        elseif bgConfig.type == "texture" then
            self.background:SetTexture(bgConfig.value)
            self.background:SetVertexColor(1, 1, 1, 1)
        end
    end

    function frame:ApplyForegroundSettings(layoutName)
        layoutName = layoutName or LEM.GetActiveLayoutName() or "Default"
        local data = SenseiClassResourceBarDB[self.config.dbName][layoutName]
        if not data then return end

        local defaults = CopyTable(commonDefaults)
        for k, v in pairs(self.config.defaultValues or {}) do
            defaults[k] = v
        end

        local fgStyleName = data.foregroundStyle or defaults.foregroundStyle
        local fgTexture = foregroundStyles[fgStyleName]
        
        if fgTexture then
            frame.statusBar:SetStatusBarTexture(fgTexture)

            for _, fragmentedPowerBar in ipairs(self.fragmentedPowerBars) do
                fragmentedPowerBar:SetStatusBarTexture(fgTexture)
            end
        end
    end

    function frame:ApplyVisibilitySettings(layoutName, inCombat)
        layoutName = layoutName or LEM.GetActiveLayoutName() or "Default"
        local data = SenseiClassResourceBarDB[self.config.dbName][layoutName]
        if not data then return end

        -- Don't hide while in edit mode
        if self._inEditMode then
            self:Show()
            return
        end


        if data.barVisible == "Always Visible" then
            self:Show()
        elseif data.barVisible == "Hidden" then
            self:Hide()
        elseif data.barVisible == "In Combat" then
            inCombat = inCombat or InCombatLockdown()
            if inCombat then
                self:Show()
            else
                self:Hide()
            end
        elseif data.barVisible == "Has Target Selected" then
            if UnitExists("target") then
                self:Show()
            else
                self:Hide()
            end
        elseif data.barVisible == "Has Target Selected OR In Combat" then
            inCombat = inCombat or InCombatLockdown()
            if UnitExists("target") or inCombat then
                self:Show()
            else
                self:Hide()
            end
        else
            self:Show()
        end
    end

    function frame:ApplyTextVisibilitySettings(layoutName)
        layoutName = layoutName or LEM.GetActiveLayoutName() or "Default"
        local data = SenseiClassResourceBarDB[self.config.dbName][layoutName]
        if not data then return end

        self.textFrame:SetShown(data.showText ~= false)

        for _, fragmentedPowerBarText in ipairs(self.fragmentedPowerBarTexts) do
            fragmentedPowerBarText:SetShown(data.showFragmentedPowerBarText ~= false)
        end
    end

    function frame:EnableSmoothProgress()
        self.smoothEnabled = true
        self:SetScript("OnUpdate", function(_, delta)
            if not self.smoothEnabled then return end
            self.elapsed = self.elapsed + delta
            if self.elapsed >= self.updateInterval then
                self.elapsed = 0
                self:UpdateDisplay()
            end
        end)
    end

    function frame:DisableSmoothProgress()
        self.smoothEnabled = false
        self:SetScript("OnUpdate", nil)
    end

    function frame:InitCooldownManagerWidthHook(layoutName)
        layoutName = layoutName or LEM.GetActiveLayoutName() or "Default"
        local data = SenseiClassResourceBarDB[self.config.dbName][layoutName]

        local v = _G["EssentialCooldownViewer"]
        if v and not v._SCRB_Essential_hooked then
            v:HookScript("OnSizeChanged", function()
                if data.widthMode == "Sync With Essential Cooldowns" then
                    self:ApplyLayout(layoutName)
                end
            end)
            v:HookScript("OnShow", function()
                if data.widthMode == "Sync With Essential Cooldowns" then
                    self:ApplyLayout(layoutName)
                end
            end)
            v:HookScript("OnHide", function()
                if data.widthMode == "Sync With Essential Cooldowns" then
                    self:ApplyLayout(layoutName)
                end
            end)
            v._SCRB_Essential_hooked = true
        end

        v = _G["UtilityCooldownViewer"]
        if v and not v._SCRB_Utility_hooked then
            v:HookScript("OnSizeChanged", function(_, width)
                if data.widthMode == "Sync With Utility Cooldowns" then
                    self:ApplyLayout(layoutName)
                end
            end)
            v:HookScript("OnShow", function()
                if data.widthMode == "Sync With Utility Cooldowns" then
                    self:ApplyLayout(layoutName)
                end
            end)
            v:HookScript("OnHide", function()
                print("essential show")
                if data.widthMode == "Sync With Utility Cooldowns" then
                    self:ApplyLayout(layoutName)
                end
            end)
            v._SCRB_Utility_hooked = true
        end
    end

    function frame:GetCooldownManagerWidth(layoutName)
        layoutName = LEM.GetActiveLayoutName() or "Default"
        local data = SenseiClassResourceBarDB[self.config.dbName][layoutName]
        if not data then return nil end

        if data.widthMode == "Sync With Essential Cooldowns" then
            local v = _G["EssentialCooldownViewer"]
            if v then
                return v:IsShown() and v:GetWidth() or nil
            end
        elseif data.widthMode == "Sync With Utility Cooldowns" then
            local v = _G["UtilityCooldownViewer"]
            if v then
                return v:IsShown() and v:GetWidth() or nil
            end
        end

        return nil
    end

    function frame:ApplyLayout(layoutName)
        layoutName = layoutName or LEM.GetActiveLayoutName() or "Default"
        local data = SenseiClassResourceBarDB[self.config.dbName][layoutName]
        if not data then return end

        local defaults = CopyTable(commonDefaults)
        for k, v in pairs(self.config.defaultValues or {}) do
            defaults[k] = v
        end

        local scale = data.scale or defaults.scale
        local point = data.point or defaults.point
        local x = data.x or defaults.x
        local y = data.y or defaults.y

        local width = nil
        if data.widthMode == "Sync With Essential Cooldowns" or data.widthMode == "Sync With Utility Cooldowns" then
            width = self:GetCooldownManagerWidth(layoutName) or defaults.width
        else -- Use manual width
            width = data.width or defaults.width
        end
        local height = data.height or defaults.height

        self:SetSize(width * scale, height * scale)
        self:ClearAllPoints()
        self:SetPoint(point, UIParent, point, x, y)

        self:ApplyFontSettings(layoutName)
        self:ApplyMaskAndBorderSettings(layoutName)
        self:ApplyBackgroundSettings(layoutName)
        self:ApplyForegroundSettings(layoutName)
        
        if data.showTicks == true then
            self:UpdateTicks(layoutName)
        end

        if data.smoothProgress then
            self:EnableSmoothProgress()
        else
            self:DisableSmoothProgress()
        end
        
        local resource = self.config.getResource()
        if fragmentedPowerTypes[resource] then
            self:CreateFragmentedPowerBars(layoutName)
            self:UpdateFragmentedPowerVisuals(layoutName)
        end
    end

    -- EVENTS
    local playerClass = select(2, UnitClass("player"))
    
    frame:RegisterEvent("PLAYER_LOGIN")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("UNIT_POWER_UPDATE")
    frame:RegisterEvent("UNIT_MAXPOWER")
    frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    frame:RegisterEvent("PLAYER_TARGET_CHANGED")

    if playerClass == "DEATHKNIGHT" then
        frame:RegisterEvent("RUNE_POWER_UPDATE")
    elseif playerClass == "DRUID" then
        frame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
    end

    frame:SetScript("OnEvent", function(self, event, arg1)
        if event == "PLAYER_LOGIN" then
            
            self:InitCooldownManagerWidthHook()

        elseif event == "PLAYER_ENTERING_WORLD"
            or event == "UPDATE_SHAPESHIFT_FORM"
            or event == "PLAYER_SPECIALIZATION_CHANGED" then

            self:ApplyLayout()
            self:ApplyVisibilitySettings()
            self:UpdateDisplay()
         
        elseif event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_TARGET_CHANGED" then
                
                self:ApplyVisibilitySettings(nil, event == "PLAYER_REGEN_DISABLED")
                self:UpdateDisplay()

        elseif ((event == "UNIT_POWER_UPDATE" or event == "UNIT_MAXPOWER") and arg1 == "player")
                or event == "RUNE_POWER_UPDATE" then
            
            self:UpdateDisplay()
            if event == "UNIT_MAXPOWER" then
                self:UpdateTicks()
            end

        end
    end)

    frame:ApplyLayout()
    frame:ApplyVisibilitySettings()
    frame:UpdateDisplay()

    return frame
end

------------------------------------------------------------
-- LEM SETTINGS BUILDER
------------------------------------------------------------
local function BuildLemSettings(config, frame)
    local defaults = CopyTable(commonDefaults)
    for k, v in pairs(config.defaultValues or {}) do
        defaults[k] = v
    end

    local settings = {
        {
            order = 1,
            name = "Bar Visible",
            kind = LEM.SettingType.Dropdown,
            default = defaults.barVisible,
            values = availableBarVisibilityOptions,
            get = function(layoutName)
                return (SenseiClassResourceBarDB[config.dbName][layoutName] and SenseiClassResourceBarDB[config.dbName][layoutName].barVisible) or defaults.barVisible
            end,
            set = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].barVisible = value
            end,
        },
        {
            order = 10,
            name = "Bar Size",
            kind = LEM.SettingType.Slider,
            default = defaults.scale,
            minValue = 0.5,
            maxValue = 2,
            valueStep = 0.1,
            formatter = function(value)
                return string.format("%d%%", value * 100)
            end,
            get = function(layoutName)
                local data = SenseiClassResourceBarDB[config.dbName][layoutName]
                return data and data.scale or defaults.scale
            end,
            set = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].scale = value
                frame:ApplyLayout(layoutName)
            end,
        },
        {
            order = 11,
            name = "Width Mode",
            kind = LEM.SettingType.Dropdown,
            default = defaults.widthMode,
            values = availableWidthModes,
            get = function(layoutName)
                return (SenseiClassResourceBarDB[config.dbName][layoutName] and SenseiClassResourceBarDB[config.dbName][layoutName].widthMode) or defaults.widthMode
            end,
            set = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].widthMode = value
                frame:ApplyLayout(layoutName)
            end,
        },
        {
            order = 11,
            name = "Width",
            kind = LEM.SettingType.Slider,
            default = defaults.width,
            minValue = 50,
            maxValue = 500,
            valueStep = 1,
            get = function(layoutName)
                local data = SenseiClassResourceBarDB[config.dbName][layoutName]
                return data and data.width or defaults.width
            end,
            set = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].width = value
                frame:ApplyLayout(layoutName)
            end,
        },
        {
            order = 12,
            name = "Height",
            kind = LEM.SettingType.Slider,
            default = defaults.height,
            minValue = 10,
            maxValue = 100,
            valueStep = 1,
            get = function(layoutName)
                local data = SenseiClassResourceBarDB[config.dbName][layoutName]
                return data and data.height or defaults.height
            end,
            set = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].height = value
                frame:ApplyLayout(layoutName)
            end,
        },
        {
            order = 20,
            name = "Smooth Progress (Higher CPU Usage)",
            kind = LEM.SettingType.Checkbox,
            default = defaults.smoothProgress,
            get = function(layoutName)
                local data = SenseiClassResourceBarDB[config.dbName][layoutName]
                return data and data.smoothProgress or defaults.smoothProgress
            end,
            set = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].smoothProgress = value
                if value then
                    frame:EnableSmoothProgress()
                else
                    frame:DisableSmoothProgress()
                end
            end,
        },
        {
            order = 40,
            name = "Show Resource Number",
            kind = LEM.SettingType.Checkbox,
            default = defaults.showText,
            get = function(layoutName)
                local data = SenseiClassResourceBarDB[config.dbName][layoutName]
                return data and data.showText ~= false
            end,
            set = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].showText = value
                frame:ApplyTextVisibilitySettings(layoutName)
            end,
        },
        {
            order = 50,
            name = "Font Face",
            kind = LEM.SettingType.Dropdown,
            default = defaults.font,
            values = fontStyles,
            get = function(layoutName)
                return (SenseiClassResourceBarDB[config.dbName][layoutName] and SenseiClassResourceBarDB[config.dbName][layoutName].font) or defaults.font
            end,
            set = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].font = value
                frame:ApplyFontSettings(layoutName)
            end,
        },
        {
            order = 51,
            name = "Font Size",
            kind = LEM.SettingType.Slider,
            default = defaults.fontSize,
            minValue = 8,
            maxValue = 24,
            valueStep = 1,
            get = function(layoutName)
                local data = SenseiClassResourceBarDB[config.dbName][layoutName]
                return data and data.fontSize or defaults.fontSize
            end,
            set = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].fontSize = value
                frame:ApplyFontSettings(layoutName)
            end,
        },
        {
            order = 52,
            name = "Font Outline",
            kind = LEM.SettingType.Dropdown,
            default = defaults.fontOutline,
            values = outlineStyles,
            get = function(layoutName)
                return (SenseiClassResourceBarDB[config.dbName][layoutName] and SenseiClassResourceBarDB[config.dbName][layoutName].fontOutline) or defaults.fontOutline
            end,
            set = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].fontOutline = value
                frame:ApplyFontSettings(layoutName)
            end,
        },
        {
            order = 53,
            name = "Text Alignment",
            kind = LEM.SettingType.Dropdown,
            default = defaults.textAlign,
            values = availableTextAlignmentStyles,
            get = function(layoutName)
                return (SenseiClassResourceBarDB[config.dbName][layoutName] and SenseiClassResourceBarDB[config.dbName][layoutName].textAlign) or defaults.textAlign
            end,
            set = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].textAlign = value
                frame:ApplyFontSettings(layoutName)
            end,
        },
        {
            order = 60,
            name = "Border",
            kind = LEM.SettingType.Dropdown,
            default = defaults.maskAndBorderStyle,
            values = availableMaskAndBorderStyles,
            get = function(layoutName)
                return (SenseiClassResourceBarDB[config.dbName][layoutName] and SenseiClassResourceBarDB[config.dbName][layoutName].maskAndBorderStyle) or defaults.maskAndBorderStyle
            end,
            set = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].maskAndBorderStyle = value
                frame:ApplyMaskAndBorderSettings(layoutName)
            end,
        },
        {
            order = 61,
            name = "Background",
            kind = LEM.SettingType.Dropdown,
            default = defaults.backgroundStyle,
            values = availableBackgroundStyles,
            get = function(layoutName)
                return (SenseiClassResourceBarDB[config.dbName][layoutName] and SenseiClassResourceBarDB[config.dbName][layoutName].backgroundStyle) or defaults.backgroundStyle
            end,
            set = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].backgroundStyle = value
                frame:ApplyBackgroundSettings(layoutName)
            end,
        },
        {
            order = 62,
            name = "Foreground",
            kind = LEM.SettingType.Dropdown,
            default = defaults.foregroundStyle,
            values = availableForegroundStyles,
            get = function(layoutName)
                return (SenseiClassResourceBarDB[config.dbName][layoutName] and SenseiClassResourceBarDB[config.dbName][layoutName].foregroundStyle) or defaults.foregroundStyle
            end,
            set = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].foregroundStyle = value
                frame:ApplyForegroundSettings(layoutName)
            end,
        },
    }

    -- Add config-specific settings
    if config.lemSettings and type(config.lemSettings) == "function" then
        local customSettings = config.lemSettings(config.dbName, defaults, frame)
        for _, setting in ipairs(customSettings) do
            table.insert(settings, setting)
        end
    end

    -- Sort settings by order field
    table.sort(settings, function(a, b)
        local orderA = a.order or 999
        local orderB = b.order or 999
        return orderA < orderB
    end)

    return settings
end

------------------------------------------------------------
-- INITIALIZE BARS
------------------------------------------------------------
local barInstances = {}

local function InitializeBar(config)
    local defaults = CopyTable(commonDefaults)
    for k, v in pairs(config.defaultValues or {}) do
        defaults[k] = v
    end

    local frame = CreateBarInstance(config, UIParent)
    barInstances[config.name] = frame

    local function OnPositionChanged(frame, layoutName, point, x, y)
        SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
        SenseiClassResourceBarDB[config.dbName][layoutName].point = point
        SenseiClassResourceBarDB[config.dbName][layoutName].x = x
        SenseiClassResourceBarDB[config.dbName][layoutName].y = y
        frame:ApplyLayout(layoutName)
    end

    LEM:RegisterCallback("enter", function()
        frame._inEditMode = true
        frame:ApplyLayout()
        frame:ApplyVisibilitySettings()
        frame:UpdateDisplay()
    end)

    LEM:RegisterCallback("exit", function()
        frame._inEditMode = false
        frame:ApplyLayout()
        frame:ApplyVisibilitySettings()
        frame:UpdateDisplay()
    end)

    LEM:RegisterCallback("layout", function(layoutName)
        SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
        frame:ApplyLayout()
        frame:ApplyVisibilitySettings()
        frame:UpdateDisplay()
    end)

    LEM:AddFrame(frame, OnPositionChanged, defaults)
    LEM:AddFrameSettings(frame, BuildLemSettings(config, frame))

    return frame
end

-- Initialize primary bar
InitializeBar(barConfigs.primary)

-- Initialize secondary bar
InitializeBar(barConfigs.secondary)
