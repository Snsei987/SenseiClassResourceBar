local addonName, addonTable = ...

local _, playerClass = UnitClass("player")

local classResources = {
    ["WARRIOR"]     = Enum.PowerType.Rage,
    ["PALADIN"]     = Enum.PowerType.Mana,
    ["HUNTER"]      = Enum.PowerType.Focus,
    ["ROGUE"]       = Enum.PowerType.Energy,
    ["PRIEST"]      = Enum.PowerType.Mana,
    ["DEATHKNIGHT"] = Enum.PowerType.RunicPower,
    ["SHAMAN"]      = Enum.PowerType.Mana,
    ["MAGE"]        = Enum.PowerType.Mana,
    ["WARLOCK"]     = Enum.PowerType.Mana,
    ["MONK"]        = Enum.PowerType.Energy,
    ["DRUID"]       = Enum.PowerType.Mana,     -- dynamic in code
    ["DEMONHUNTER"] = Enum.PowerType.Fury,
}

-- Function to get primary resource for current player
local function GetPlayerPrimaryResource()
    local playerClass = select(2, UnitClass("player")) -- e.g., "DRUID"
    local specID = GetSpecialization()                 -- current spec index

    -- Druid: form-based
    if playerClass == "DRUID" then
        local form = GetShapeshiftFormID() -- current form
        if form == 5 then
            return Enum.PowerType.Rage    -- Bear form
        elseif form == 1 then
            return Enum.PowerType.Energy  -- Cat form
        elseif form == 31 then
            return Enum.PowerType.LunarPower -- Moonkin form
        else
            return Enum.PowerType.Mana    -- caster form
        end
    end

    -- Other classes
    return classResources[playerClass]
end

-- Function to get power color
local function GetPlayerPowerColor()
    local powerType = GetPlayerPrimaryResource()
    local color = PowerBarColor[powerType] or PowerBarColor["MANA"]
    return color.r, color.g, color.b
end

------------------------------------------------------------
-- LIBEDITMODE INTEGRATION
------------------------------------------------------------
local LEM = LibStub("LibEditMode")
local defaultEditModeValues = {
    point = "CENTER",
    x = 0,
    y = 0,
    scale = 1,
    width = 200,
    height = 15,
    smoothProgress = false,
    hideOutOfCombat = false,
    showText = true,
    showManaAsPercent = false,
    font = "Fonts\\FRIZQT__.TTF",
    fontSize = 12,
    fontOutline = "OUTLINE",
    enabled = true,
}

if not ResourceBarDB then
    ResourceBarDB = {}
end

local function UpdateResource(frame, layoutName)
    layoutName = layoutName or LEM.GetActiveLayoutName() or "Default"
    local data = ResourceBarDB[layoutName]
    if not data then return end

    local primaryResource = GetPlayerPrimaryResource()
    local current = UnitPower("player", primaryResource)
    local max = UnitPowerMax("player", primaryResource)
    if max == 0 then return end

    frame.statusBar:SetMinMaxValues(0, max)
    frame.statusBar:SetValue(current)

    if data.showManaAsPercent and primaryResource == Enum.PowerType.Mana then
        frame.textValue:SetText(string.format("%.0f%%", UnitPowerPercent("player", primaryResource, false, true)))
    else
        frame.textValue:SetText(AbbreviateNumbers(current))
    end

    local r, g, b = GetPlayerPowerColor()
    frame.statusBar:SetStatusBarColor(r, g, b)
end

local ApplyVisibilitySettings

------------------------------------------------------------
-- CREATE RESOURCE BAR
------------------------------------------------------------
local function CreateResourceBar(parent)
    local frame = CreateFrame("Frame", "Primary Resource Bar", parent or UIParent)

    -- BACKGROUND
    frame.background = frame:CreateTexture(nil, "BACKGROUND")
    frame.background:SetAllPoints()
    frame.background:SetColorTexture(0, 0, 0, 0.5)

    -- MAIN RESOURCE BAR
    frame.statusBar = CreateFrame("StatusBar", nil, frame)
    frame.statusBar:SetAllPoints()
    frame.statusBar:SetStatusBarTexture("Interface\\AddOns\\SenseiClassResourceBar\\Textures\\fade-left.png")
    frame.statusBar:SetFrameLevel(1)

    -- MASK
    frame.mask = frame.statusBar:CreateMaskTexture()
    frame.mask:SetAllPoints()
    frame.mask:SetTexture("Interface\\AddOns\\SenseiClassResourceBar\\Textures\\blizzard-mask.png")
    frame.statusBar:GetStatusBarTexture():AddMaskTexture(frame.mask)

    -- BORDER
    frame.border = frame:CreateTexture(nil, "OVERLAY")
    frame.border:SetAllPoints()
    frame.border:SetTexture("Interface\\AddOns\\SenseiClassResourceBar\\Textures\\blizzard-classic.png")
    frame.border:SetBlendMode("BLEND")
    frame.border:SetVertexColor(0, 0, 0)

    -- TEXT FRAME
    frame.textFrame = CreateFrame("Frame", nil, frame)
    frame.textFrame:SetAllPoints(frame)
    frame.textFrame:SetFrameLevel(frame.statusBar:GetFrameLevel() + 2)

    frame.textValue = frame.textFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.textValue:SetPoint("CENTER", frame.textFrame, "CENTER", 0, 0)
    frame.textValue:SetJustifyH("CENTER")

    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("UNIT_POWER_UPDATE")
    frame:RegisterEvent("UNIT_MAXPOWER")
    frame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
    frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")

    frame:SetScript("OnEvent", function(self, event, arg1)
        if event == "PLAYER_ENTERING_WORLD"
            or event == "UPDATE_SHAPESHIFT_FORM"
            or event == "PLAYER_SPECIALIZATION_CHANGED" then
            ApplyVisibilitySettings()
            UpdateResource(self)
        elseif (arg1 == "player" and (event == "UNIT_POWER_UPDATE" or event == "UNIT_MAXPOWER")) then
            UpdateResource(self)
        end
    end)

    UpdateResource(frame)
    return frame
end

------------------------------------------------------------
-- INSTANTIATE FRAME
------------------------------------------------------------
local resourceBar = CreateResourceBar(UIParent)

------------------------------------------------------------
-- UTILITY FUNCTIONS
------------------------------------------------------------
local function ApplyFontSettings(layoutName)
    local layoutName = layout or LEM.GetActiveLayoutName() or "Default"
    local data = ResourceBarDB[layoutName]
    if not data then return end

    local font = data.font or defaultEditModeValues.font
    local size = data.fontSize or defaultEditModeValues.fontSize
    local outline = data.fontOutline or defaultEditModeValues.fontOutline

    resourceBar.textValue:SetFont(font, size, outline)
    resourceBar.textValue:SetShadowColor(0, 0, 0, 0.8)
    resourceBar.textValue:SetShadowOffset(1, -1)
end

ApplyVisibilitySettings = function(layoutName)
    local layoutName = layout or LEM.GetActiveLayoutName() or "Default"
    local data = ResourceBarDB[layoutName]
    if not data then return end

    if not data.enabled then
        resourceBar:Hide()
        return
    end

    resourceBar.textFrame:SetShown(data.showText ~= false)

    if data.hideOutOfCombat then
        if InCombatLockdown() then
            resourceBar:Show()
        else
            resourceBar:Hide()
        end
    else
        resourceBar:Show()
    end
end

local function ApplyScale(layoutName)
    local layoutName = layout or LEM.GetActiveLayoutName() or "Default"
    local data = ResourceBarDB[layoutName]
    if not data then return end

    local scale = data.scale or defaultEditModeValues.scale
    local point = data.point or "CENTER"
    local x = data.x or 0
    local y = data.y or 0

    local width = data.width or defaultEditModeValues.width
    local height = data.height or defaultEditModeValues.height
    resourceBar:SetSize(width * scale, height * scale)

    resourceBar:ClearAllPoints()
    resourceBar:SetPoint(point, UIParent, point, x, y)
end

local function ApplySize(layoutName)
    local layoutName = layout or LEM.GetActiveLayoutName() or "Default"
    local data = ResourceBarDB[layoutName]
    if not data then return end

    local width = data.width or defaultEditModeValues.width
    local height = data.height or defaultEditModeValues.height
    local point = data.point or "CENTER"
    local x = data.x or 0
    local y = data.y or 0

    resourceBar:SetSize(width, height)
    resourceBar:ClearAllPoints()
    resourceBar:SetPoint(point, UIParent, point, x, y)

    ApplyScale(layoutName)
end

local smoothEnabled = false
local updateInterval = 0.05 -- 50ms update
local elapsed = 0

local function EnableSmoothProgress()
    smoothEnabled = true
    smoothValue = UnitPower("player", GetPlayerPrimaryResource())

    resourceBar:SetScript("OnUpdate", function(self, delta)
        if not smoothEnabled then return end
        elapsed = elapsed + delta
        if elapsed >= updateInterval then
            elapsed = 0

            UpdateResource(resourceBar)
        end
    end)
end

local function DisableSmoothProgress()
    smoothEnabled = false
    resourceBar:SetScript("OnUpdate", nil)
    -- fallback to normal event update
    resourceBar:GetScript("OnEvent")(resourceBar, "PLAYER_ENTERING_WORLD", "player")
end

------------------------------------------------------------
-- EDIT MODE CALLBACKS
------------------------------------------------------------
local function OnPositionChanged(frame, layoutName, point, x, y)
    ResourceBarDB[layoutName] = ResourceBarDB[layoutName] or CopyTable(defaultEditModeValues)
    ResourceBarDB[layoutName].point = point
    ResourceBarDB[layoutName].x = x
    ResourceBarDB[layoutName].y = y
    ApplyScale(layoutName)
end

LEM:RegisterCallback("enter", function()
    resourceBar:Show()
end)

LEM:RegisterCallback("exit", function()
    local layoutName = LEM.GetActiveLayoutName() or "Default"
    ApplyVisibilitySettings(layoutName)
end)

LEM:RegisterCallback("layout", function(layoutName)
    ResourceBarDB[layoutName] = ResourceBarDB[layoutName] or CopyTable(defaultEditModeValues)
    local data = ResourceBarDB[layoutName]

    resourceBar:ClearAllPoints()
    resourceBar:SetPoint(data.point, UIParent, data.point, data.x, data.y)

    ApplyFontSettings(layoutName)
    ApplyVisibilitySettings(layoutName)
    ApplyScale(layoutName)
    ApplySize(layoutName)

    if data.smoothProgress then
        EnableSmoothProgress()
    else
        DisableSmoothProgress()
    end
end)

LEM:AddFrame(resourceBar, OnPositionChanged, defaultEditModeValues)

------------------------------------------------------------
-- DROPDOWN OPTIONS
------------------------------------------------------------
local availableFonts = {
    { text = "Fonts\\FRIZQT__.TTF" },
    { text = "Fonts\\ARIALN.TTF" },
    { text = "Fonts\\MORPHEUS.TTF" },
    { text = "Fonts\\SKURRI.TTF" },
}

local availableOutlines = {
    { text = "NONE" },
    { text = "OUTLINE" },
    { text = "THICKOUTLINE" },
}

LEM:AddFrameSettings(resourceBar, {
    {
        name = "Enabled",
        kind = LEM.SettingType.Checkbox,
        default = defaultEditModeValues.enabled,
        get = function(layoutName)
            local data = ResourceBarDB[layoutName]
            if data and data.enabled ~= nil then
                return data.enabled
            else
                return defaultEditModeValues.enabled
            end
        end,
        set = function(layoutName, value)
            ResourceBarDB[layoutName] = ResourceBarDB[layoutName] or CopyTable(defaultEditModeValues)
            ResourceBarDB[layoutName].enabled = value
        end,
    },
    {
        name = "Bar Size",
        kind = LEM.SettingType.Slider,
        default = defaultEditModeValues.scale,
        get = function(layoutName)
            local data = ResourceBarDB[layoutName]
            return data and data.scale or defaultEditModeValues.scale
        end,
        set = function(layoutName, value)
            ResourceBarDB[layoutName] = ResourceBarDB[layoutName] or CopyTable(defaultEditModeValues)
            ResourceBarDB[layoutName].scale = value
            ApplyScale(layoutName)
        end,
        minValue = 0.5,
        maxValue = 2,
        valueStep = 0.1,
        formatter = function(value)
            return string.format("%d%%", value * 100)
        end,
    },
    {
        name = "Width",
        kind = LEM.SettingType.Slider,
        default = defaultEditModeValues.width,
        minValue = 50,
        maxValue = 500,
        valueStep = 1,
        get = function(layoutName)
            local data = ResourceBarDB[layoutName]
            return data and data.width or defaultEditModeValues.width
        end,
        set = function(layoutName, value)
            ResourceBarDB[layoutName] = ResourceBarDB[layoutName] or CopyTable(defaultEditModeValues)
            ResourceBarDB[layoutName].width = value
            ApplySize(layoutName)
        end,
    },
    {
        name = "Height",
        kind = LEM.SettingType.Slider,
        default = defaultEditModeValues.height,
        minValue = 10,
        maxValue = 100,
        valueStep = 1,
        get = function(layoutName)
            local data = ResourceBarDB[layoutName]
            return data and data.height or defaultEditModeValues.height
        end,
        set = function(layoutName, value)
            ResourceBarDB[layoutName] = ResourceBarDB[layoutName] or CopyTable(defaultEditModeValues)
            ResourceBarDB[layoutName].height = value
            ApplySize(layoutName)
        end,
    },
    {
        name = "Smooth Progress",
        kind = LEM.SettingType.Checkbox,
        default = defaultEditModeValues.smoothProgress,
        get = function(layoutName)
            local data = ResourceBarDB[layoutName]
            return data and data.smoothProgress or defaultEditModeValues.smoothProgress
        end,
        set = function(layoutName, value)
            ResourceBarDB[layoutName] = ResourceBarDB[layoutName] or CopyTable(defaultEditModeValues)
            ResourceBarDB[layoutName].smoothProgress = value

            -- Apply immediately
            if value then
                EnableSmoothProgress()
            else
                DisableSmoothProgress()
            end
        end,
    },
    {
        name = "Hide When Not In Combat",
        kind = LEM.SettingType.Checkbox,
        default = defaultEditModeValues.hideOutOfCombat,
        get = function(layoutName)
            local data = ResourceBarDB[layoutName]
            return data and data.hideOutOfCombat or defaultEditModeValues.hideOutOfCombat
        end,
        set = function(layoutName, value)
            ResourceBarDB[layoutName] = ResourceBarDB[layoutName] or CopyTable(defaultEditModeValues)
            ResourceBarDB[layoutName].hideOutOfCombat = value
        end,
    },
    {
        name = "Show Resource Number",
        kind = LEM.SettingType.Checkbox,
        default = defaultEditModeValues.showText,
        get = function(layoutName)
            local data = ResourceBarDB[layoutName]
            return data and data.showText ~= false
        end,
        set = function(layoutName, value)
            ResourceBarDB[layoutName] = ResourceBarDB[layoutName] or CopyTable(defaultEditModeValues)
            ResourceBarDB[layoutName].showText = value
            resourceBar.textFrame:SetShown(value)
        end,
    },
    {
        name = "Show Mana As Percent",
        kind = LEM.SettingType.Checkbox,
        default = defaultEditModeValues.showManaAsPercent,
        get = function(layoutName)
            local data = ResourceBarDB[layoutName]
            return data and data.showManaAsPercent or defaultEditModeValues.showManaAsPercent
        end,
        set = function(layoutName, value)
            ResourceBarDB[layoutName] = ResourceBarDB[layoutName] or CopyTable(defaultEditModeValues)
            ResourceBarDB[layoutName].showManaAsPercent = value

            -- Immediately update display
            UpdateResource(resourceBar)
        end,
    },
    {
        name    = "Font Face",
        kind    = LEM.SettingType.Dropdown,
        default = defaultEditModeValues.font,
        values  = availableFonts,
        get     = function(layoutName)
            return (ResourceBarDB[layoutName] and ResourceBarDB[layoutName].font) or defaultEditModeValues.font
        end,
        set     = function(layoutName, value, t)
            ResourceBarDB[layoutName] = ResourceBarDB[layoutName] or CopyTable(defaultEditModeValues)
            ResourceBarDB[layoutName].font = value
            ApplyFontSettings(layoutName)
        end,
    },
    {
        name = "Font Size",
        kind = LEM.SettingType.Slider,
        default = defaultEditModeValues.fontSize,
        minValue = 8,
        maxValue = 24,
        valueStep = 1,
        get = function(layoutName)
            local data = ResourceBarDB[layoutName]
            return data and data.fontSize or defaultEditModeValues.fontSize
        end,
        set = function(layoutName, value)
            ResourceBarDB[layoutName] = ResourceBarDB[layoutName] or CopyTable(defaultEditModeValues)
            ResourceBarDB[layoutName].fontSize = value
            ApplyFontSettings(layoutName)
        end,
    },
    {
        name    = "Font Outline",
        kind    = LEM.SettingType.Dropdown,
        default = defaultEditModeValues.fontOutline,
        values  = availableOutlines,
        get     = function(layoutName)
            return (ResourceBarDB[layoutName] and ResourceBarDB[layoutName].fontOutline) or defaultEditModeValues.fontOutline
        end,
        set     = function(layoutName, value)
            ResourceBarDB[layoutName] = ResourceBarDB[layoutName] or CopyTable(defaultEditModeValues)
            ResourceBarDB[layoutName].fontOutline = value
            ApplyFontSettings(layoutName)
        end,
    },
})


------------------------------------------------------------
-- SECONDARY RESOURCE BAR
------------------------------------------------------------
local secondaryResources = {
    ["PALADIN"]     = Enum.PowerType.HolyPower,
    ["MONK"]        = nil, -- Chi Windwalker / Stagger Brewmaster
    ["ROGUE"]       = Enum.PowerType.ComboPoints,
    ["DEATHKNIGHT"] = Enum.PowerType.Runes,
    ["WARLOCK"]     = Enum.PowerType.SoulShards,
    ["SHAMAN"]      = nil, -- Maelstorm Elementalspe
    ["EVOKER"]      = Enum.PowerType.Essence,
    ["DRUID"]       = nil -- Combo with cat form
}

local defaultSecondaryValues = {
    point = "CENTER",
    x = 0,
    y = -40, -- appears just below main bar
    scale = 1,
    width = 200,
    height = 15,
    smoothProgress = false,
    hideOutOfCombat = false,
    showText = true,
    font = "Fonts\\FRIZQT__.TTF",
    fontSize = 12,
    fontOutline = "OUTLINE",
    enabled = true,
}

if not SecondaryResourceBarDB then
    SecondaryResourceBarDB = {}
end

------------------------------------------------------------
-- LOGIC
------------------------------------------------------------
local function GetPlayerSecondaryResource()
    local class = select(2, UnitClass("player"))
    local specID = GetSpecialization()

    -- Monk special handling
    if class == "MONK" then
        local spec = GetSpecializationInfo(specID)
        if spec == 268 then -- Brewmaster
            return "STAGGER"
        elseif spec == 269 then -- Windwalker
            return Enum.PowerType.Chi
        else -- Mistweaver
            return nil
        end
    end

    -- Shaman special handling
    if class == "SHAMAN" then
        local spec = GetSpecializationInfo(specID)
        if spec == 262 then -- Elemental
            return Enum.PowerType.Maelstrom
        else -- Enhancement / Restoration
            return nil
        end
    end

    -- Druid: form-based
    if playerClass == "DRUID" then
        local form = GetShapeshiftFormID() -- current form
        if form == 1 then
            return Enum.PowerType.ComboPoints    -- Cat form
        else
            return nil
        end
    end

    return secondaryResources[class]
end

local function UpdateSecondaryResource(frame, layoutName)
    layoutName = layoutName or LEM.GetActiveLayoutName() or "Default"
    local data = SecondaryResourceBarDB[layoutName]
    if not data then return end

    local resourceType = GetPlayerSecondaryResource()
    if not resourceType then
        frame:Hide()
        return
    end

    -- Handle Brewmaster Stagger separately
    if resourceType == "STAGGER" then
        local stagger = UnitStagger("player") or 0
        local maxHealth = UnitHealthMax("player") or 1

        frame.statusBar:SetMinMaxValues(0, maxHealth)
        frame.statusBar:SetValue(stagger)
        frame.textValue:SetText(AbbreviateNumbers(stagger))
        frame.statusBar:SetStatusBarColor(0.5216, 1.0, 0.5216)
        return
    end

    -- Regular secondary resource types (Combo Points, Chi, etc.)
    local current = UnitPower("player", resourceType)
    local max = UnitPowerMax("player", resourceType)
    if max == 0 then
        return
    end

    frame.statusBar:SetMinMaxValues(0, max)
    frame.statusBar:SetValue(current)
    frame.textValue:SetText(AbbreviateNumbers(current))

    local color = PowerBarColor[resourceType] or PowerBarColor["MANA"]
    frame.statusBar:SetStatusBarColor(color.r, color.g, color.b)
end

local ApplySecondaryVisibility

------------------------------------------------------------
-- CREATE BAR
------------------------------------------------------------
local function CreateSecondaryResourceBar(parent)
    local frame = CreateFrame("Frame", "Secondary Resource Bar", parent or UIParent)

    -- BACKGROUND
    frame.background = frame:CreateTexture(nil, "BACKGROUND")
    frame.background:SetAllPoints()
    frame.background:SetColorTexture(0, 0, 0, 0.5)

    -- SECONDARY RESOURCE BAR
    frame.statusBar = CreateFrame("StatusBar", nil, frame)
    frame.statusBar:SetAllPoints()
    frame.statusBar:SetStatusBarTexture("Interface\\AddOns\\SenseiClassResourceBar\\Textures\\fade-left.png")
    frame.statusBar:SetFrameLevel(1)

    -- MASK
    frame.mask = frame.statusBar:CreateMaskTexture()
    frame.mask:SetAllPoints()
    frame.mask:SetTexture("Interface\\AddOns\\SenseiClassResourceBar\\Textures\\blizzard-mask.png")
    frame.statusBar:GetStatusBarTexture():AddMaskTexture(frame.mask)

    -- BORDER
    frame.border = frame:CreateTexture(nil, "OVERLAY")
    frame.border:SetAllPoints()
    frame.border:SetTexture("Interface\\AddOns\\SenseiClassResourceBar\\Textures\\blizzard-classic.png")
    frame.border:SetBlendMode("BLEND")
    frame.border:SetVertexColor(0, 0, 0)

    -- TEXT FRAME
    frame.textFrame = CreateFrame("Frame", nil, frame)
    frame.textFrame:SetAllPoints(frame)
    frame.textFrame:SetFrameLevel(frame.statusBar:GetFrameLevel() + 2)

    frame.textValue = frame.textFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.textValue:SetPoint("CENTER", frame.textFrame, "CENTER", 0, 0)
    frame.textValue:SetJustifyH("CENTER")

    -- EVENTS
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("UNIT_POWER_UPDATE")
    frame:RegisterEvent("UNIT_MAXPOWER")
    frame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
    frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")

    frame:SetScript("OnEvent", function(self, event, arg1)
        if event == "PLAYER_ENTERING_WORLD"
            or event == "UPDATE_SHAPESHIFT_FORM"
            or event == "PLAYER_SPECIALIZATION_CHANGED" then
            ApplySecondaryVisibility()
            UpdateSecondaryResource(self)
        elseif (arg1 == "player" and (event == "UNIT_POWER_UPDATE" or event == "UNIT_MAXPOWER")) then
            UpdateSecondaryResource(self)
        end
    end)

    UpdateSecondaryResource(frame)
    return frame
end

local secondaryBar = CreateSecondaryResourceBar(UIParent)

------------------------------------------------------------
-- APPLY SETTINGS
------------------------------------------------------------
local function ApplySecondaryFontSettings(layoutName)
    local layoutName = layout or LEM.GetActiveLayoutName() or "Default"
    local data = SecondaryResourceBarDB[layoutName]
    if not data then return end

    local font = data.font or defaultSecondaryValues.font
    local size = data.fontSize or defaultSecondaryValues.fontSize
    local outline = data.fontOutline or defaultSecondaryValues.fontOutline

    secondaryBar.textValue:SetFont(font, size, outline)
    secondaryBar.textValue:SetShadowColor(0, 0, 0, 0.8)
    secondaryBar.textValue:SetShadowOffset(1, -1)
end

ApplySecondaryVisibility = function(layoutName)
    local layoutName = layout or LEM.GetActiveLayoutName() or "Default"
    local data = SecondaryResourceBarDB[layoutName]
    if not data then return end

    if not data.enabled then
        secondaryBar:Hide()
        return
    end

    secondaryBar.textFrame:SetShown(data.showText ~= false)

    if data.hideOutOfCombat then
        if InCombatLockdown() then
            secondaryBar:Show()
        else
            secondaryBar:Hide()
        end
    else
        secondaryBar:Show()
    end
end

local function ApplySecondaryScale(layoutName)
    local layoutName = layout or LEM.GetActiveLayoutName() or "Default"
    local data = SecondaryResourceBarDB[layoutName]
    if not data then return end
    local scale = data.scale or defaultSecondaryValues.scale
    local point = data.point or "CENTER"
    local x = data.x or 0
    local y = data.y or -40
    local width = data.width or defaultSecondaryValues.width
    local height = data.height or defaultSecondaryValues.height
    secondaryBar:SetSize(width * scale, height * scale)
    secondaryBar:ClearAllPoints()
    secondaryBar:SetPoint(point, UIParent, point, x, y)
end

------------------------------------------------------------
-- SMOOTH PROGRESS
------------------------------------------------------------
local smoothEnabled2 = false
local updateInterval2 = 0.05
local elapsed2 = 0

local function EnableSmoothProgress2()
    smoothEnabled2 = true
    secondaryBar:SetScript("OnUpdate", function(self, delta)
        if not smoothEnabled2 then return end
        elapsed2 = elapsed2 + delta
        if elapsed2 >= updateInterval2 then
            elapsed2 = 0
            UpdateSecondaryResource(secondaryBar)
        end
    end)
end

local function DisableSmoothProgress2()
    smoothEnabled2 = false
    secondaryBar:SetScript("OnUpdate", nil)
end

------------------------------------------------------------
-- EDIT MODE INTEGRATION
------------------------------------------------------------
local function OnSecondaryPositionChanged(frame, layoutName, point, x, y)
    SecondaryResourceBarDB[layoutName] = SecondaryResourceBarDB[layoutName] or CopyTable(defaultSecondaryValues)
    SecondaryResourceBarDB[layoutName].point = point
    SecondaryResourceBarDB[layoutName].x = x
    SecondaryResourceBarDB[layoutName].y = y
    ApplySecondaryScale(layoutName)
end

LEM:RegisterCallback("enter", function()
    secondaryBar:Show()
end)

LEM:RegisterCallback("exit", function()
    local layoutName = LEM.GetActiveLayoutName() or "Default"
    ApplySecondaryVisibility(layoutName)
end)

LEM:RegisterCallback("layout", function(layoutName)
    SecondaryResourceBarDB[layoutName] = SecondaryResourceBarDB[layoutName] or CopyTable(defaultSecondaryValues)
    local data = SecondaryResourceBarDB[layoutName]
    secondaryBar:ClearAllPoints()
    secondaryBar:SetPoint(data.point, UIParent, data.point, data.x, data.y)
    ApplySecondaryFontSettings(layoutName)
    ApplySecondaryVisibility(layoutName)
    ApplySecondaryScale(layoutName)
    if data.smoothProgress then
        EnableSmoothProgress2()
    else
        DisableSmoothProgress2()
    end
end)

LEM:AddFrame(secondaryBar, OnSecondaryPositionChanged, defaultSecondaryValues)

------------------------------------------------------------
-- SETTINGS (Same as main but no "Show Mana As Percent")
------------------------------------------------------------
local availableFonts = {
    { text = "Fonts\\FRIZQT__.TTF" },
    { text = "Fonts\\ARIALN.TTF" },
    { text = "Fonts\\MORPHEUS.TTF" },
    { text = "Fonts\\SKURRI.TTF" },
}
local availableOutlines = {
    { text = "NONE" },
    { text = "OUTLINE" },
    { text = "THICKOUTLINE" },
}

LEM:AddFrameSettings(secondaryBar, {
    {
        name = "Enabled",
        kind = LEM.SettingType.Checkbox,
        default = defaultSecondaryValues.enabled,
        get = function(layoutName)
            local data = SecondaryResourceBarDB[layoutName]
            if data and data.enabled ~= nil then
                return data.enabled
            else
                return defaultSecondaryValues.enabled
            end
        end,
        set = function(layoutName, value)
            SecondaryResourceBarDB[layoutName] = SecondaryResourceBarDB[layoutName] or CopyTable(defaultSecondaryValues)
            SecondaryResourceBarDB[layoutName].enabled = value
        end,
    },
    {
        name = "Bar Size",
        kind = LEM.SettingType.Slider,
        default = defaultSecondaryValues.scale,
        minValue = 0.5,
        maxValue = 2,
        valueStep = 0.1,
        get = function(layoutName)
            local data = SecondaryResourceBarDB[layoutName]
            return data and data.scale or defaultSecondaryValues.scale
        end,
        set = function(layoutName, value)
            SecondaryResourceBarDB[layoutName] = SecondaryResourceBarDB[layoutName] or CopyTable(defaultSecondaryValues)
            SecondaryResourceBarDB[layoutName].scale = value
            ApplySecondaryScale(layoutName)
        end,
        formatter = function(value)
            return string.format("%d%%", value * 100)
        end,
    },
    {
        name = "Width",
        kind = LEM.SettingType.Slider,
        default = defaultSecondaryValues.width,
        minValue = 50,
        maxValue = 500,
        valueStep = 1,
        get = function(layoutName)
            local data = SecondaryResourceBarDB[layoutName]
            return data and data.width or defaultSecondaryValues.width
        end,
        set = function(layoutName, value)
            SecondaryResourceBarDB[layoutName] = SecondaryResourceBarDB[layoutName] or CopyTable(defaultSecondaryValues)
            SecondaryResourceBarDB[layoutName].width = value
            ApplySecondaryScale(layoutName)
        end,
    },
    {
        name = "Height",
        kind = LEM.SettingType.Slider,
        default = defaultSecondaryValues.height,
        minValue = 10,
        maxValue = 100,
        valueStep = 1,
        get = function(layoutName)
            local data = SecondaryResourceBarDB[layoutName]
            return data and data.height or defaultSecondaryValues.height
        end,
        set = function(layoutName, value)
            SecondaryResourceBarDB[layoutName] = SecondaryResourceBarDB[layoutName] or CopyTable(defaultSecondaryValues)
            SecondaryResourceBarDB[layoutName].height = value
            ApplySecondaryScale(layoutName)
        end,
    },
    {
        name = "Smooth Progress",
        kind = LEM.SettingType.Checkbox,
        default = defaultSecondaryValues.smoothProgress,
        get = function(layoutName)
            local data = SecondaryResourceBarDB[layoutName]
            return data and data.smoothProgress or defaultSecondaryValues.smoothProgress
        end,
        set = function(layoutName, value)
            SecondaryResourceBarDB[layoutName] = SecondaryResourceBarDB[layoutName] or CopyTable(defaultSecondaryValues)
            SecondaryResourceBarDB[layoutName].smoothProgress = value
            if value then EnableSmoothProgress2() else DisableSmoothProgress2() end
        end,
    },
    {
        name = "Hide When Not In Combat",
        kind = LEM.SettingType.Checkbox,
        default = defaultSecondaryValues.hideOutOfCombat,
        get = function(layoutName)
            local data = SecondaryResourceBarDB[layoutName]
            return data and data.hideOutOfCombat or defaultSecondaryValues.hideOutOfCombat
        end,
        set = function(layoutName, value)
            SecondaryResourceBarDB[layoutName] = SecondaryResourceBarDB[layoutName] or CopyTable(defaultSecondaryValues)
            SecondaryResourceBarDB[layoutName].hideOutOfCombat = value

        end,
    },
    {
        name = "Show Resource Number",
        kind = LEM.SettingType.Checkbox,
        default = defaultSecondaryValues.showText,
        get = function(layoutName)
            local data = SecondaryResourceBarDB[layoutName]
            return data and data.showText ~= false
        end,
        set = function(layoutName, value)
            SecondaryResourceBarDB[layoutName] = SecondaryResourceBarDB[layoutName] or CopyTable(defaultSecondaryValues)
            SecondaryResourceBarDB[layoutName].showText = value
            secondaryBar.textFrame:SetShown(value)
        end,
    },
    {
        name = "Font Face",
        kind = LEM.SettingType.Dropdown,
        default = defaultSecondaryValues.font,
        values = availableFonts,
        get = function(layoutName)
            return (SecondaryResourceBarDB[layoutName] and SecondaryResourceBarDB[layoutName].font) or defaultSecondaryValues.font
        end,
        set = function(layoutName, value)
            SecondaryResourceBarDB[layoutName] = SecondaryResourceBarDB[layoutName] or CopyTable(defaultSecondaryValues)
            SecondaryResourceBarDB[layoutName].font = value
            ApplySecondaryFontSettings(layoutName)
        end,
    },
    {
        name = "Font Size",
        kind = LEM.SettingType.Slider,
        default = defaultSecondaryValues.fontSize,
        minValue = 8,
        maxValue = 24,
        valueStep = 1,
        get = function(layoutName)
            local data = SecondaryResourceBarDB[layoutName]
            return data and data.fontSize or defaultSecondaryValues.fontSize
        end,
        set = function(layoutName, value)
            SecondaryResourceBarDB[layoutName] = SecondaryResourceBarDB[layoutName] or CopyTable(defaultSecondaryValues)
            SecondaryResourceBarDB[layoutName].fontSize = value
            ApplySecondaryFontSettings(layoutName)
        end,
    },
    {
        name = "Font Outline",
        kind = LEM.SettingType.Dropdown,
        default = defaultSecondaryValues.fontOutline,
        values = availableOutlines,
        get = function(layoutName)
            return (SecondaryResourceBarDB[layoutName] and SecondaryResourceBarDB[layoutName].fontOutline) or defaultSecondaryValues.fontOutline
        end,
        set = function(layoutName, value)
            SecondaryResourceBarDB[layoutName] = SecondaryResourceBarDB[layoutName] or CopyTable(defaultSecondaryValues)
            SecondaryResourceBarDB[layoutName].fontOutline = value
            ApplySecondaryFontSettings(layoutName)
        end,
    },
})
