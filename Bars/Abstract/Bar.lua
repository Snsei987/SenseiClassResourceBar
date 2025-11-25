local _, addonTable = ...

local LSM = addonTable.LSM or LibStub("LibSharedMedia-3.0")
local LEM = addonTable.LEM or LibStub("LibEditMode")

------------------------------------------------------------
-- YOU SHOULD NOT USE DIRECTLY THIS MIXIN -- YOU NEED TO OVERWRITE SOME METHODS
------------------------------------------------------------

local BarMixin = {}

------------------------------------------------------------
-- BAR FACTORY
------------------------------------------------------------

function BarMixin:Init(config, parent, frameLevel)
    local Frame = CreateFrame("Frame", config.frameName or "", parent or UIParent)

    Frame:SetFrameLevel(frameLevel)
    self.config = config
    self.barName = Frame:GetName()
    Frame.editModeName = config.editModeName

    local defaults = CopyTable(addonTable.commonDefaults)
    for k, v in pairs(self.config.defaultValues or {}) do
        defaults[k] = v
    end
    self.defaults = defaults

    -- BACKGROUND
    self.Background = Frame:CreateTexture(nil, "BACKGROUND")
    self.Background:SetAllPoints()
    self.Background:SetColorTexture(0, 0, 0, 0.5)

    -- STATUS BAR
    self.StatusBar = CreateFrame("StatusBar", nil, Frame)
    self.StatusBar:SetAllPoints()
    self.StatusBar:SetStatusBarTexture(LSM:Fetch(LSM.MediaType.STATUSBAR, "SCRB FG Fade Left"))
    self.StatusBar:SetFrameLevel(Frame:GetFrameLevel())

    -- MASK
    self.Mask = self.StatusBar:CreateMaskTexture()
    self.Mask:SetAllPoints()
    self.Mask:SetTexture([[Interface\AddOns\SenseiClassResourceBar\Textures\Specials\white.png]])

    self.StatusBar:GetStatusBarTexture():AddMaskTexture(self.Mask)
    self.Background:AddMaskTexture(self.Mask)

    -- BORDER
    self.Border = Frame:CreateTexture(nil, "OVERLAY")
    self.Border:SetAllPoints()
    self.Border:SetBlendMode("BLEND")
    self.Border:SetVertexColor(0, 0, 0)
    self.Border:Hide()

    -- TEXT FRAME
    self.TextFrame = CreateFrame("Frame", nil, Frame)
    self.TextFrame:SetAllPoints(Frame)
    self.TextFrame:SetFrameLevel(self.StatusBar:GetFrameLevel() + 2)

    self.TextValue = self.TextFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    self.TextValue:SetPoint("CENTER", self.TextFrame, "CENTER", 0, 0)
    self.TextValue:SetJustifyH("CENTER")
    self.TextValue:SetText("0")

    -- STATE
    self.smoothEnabled = false

    -- Fragmented powers (Runes, Essences) specific visual elements
    self.FragmentedPowerBars = {}
    self.FragmentedPowerBarTexts = {}

    self.Frame = Frame
end

function BarMixin:InitCooldownManagerWidthHook(layoutName)
    local data = self:GetData(layoutName)
    if not data then return nil end

    self._SCRB_Essential_Utility_hook_widthMode = data.widthMode

    local v = _G["EssentialCooldownViewer"]
    if v and not (self._SCRB_Essential_hooked or false) then
        local hookEssentialCooldowns = function(_, width)
            if self._SCRB_Essential_Utility_hook_widthMode ~= "Sync With Essential Cooldowns" then
                return
            end

            -- For some weird reasons, this is triggered with the scale or something ?
            if (width == nil) or (type(width) == "number" and math.floor(width) > 1) then
                self:ApplyLayout(nil, true)
            end
        end

        hooksecurefunc(v, "SetSize", hookEssentialCooldowns)
        hooksecurefunc(v, "Show", hookEssentialCooldowns)
        hooksecurefunc(v, "Hide", hookEssentialCooldowns)

        self._SCRB_Essential_hooked = true
    end

    v = _G["UtilityCooldownViewer"]
    if v and not (self._SCRB_Utility_hooked or false) then
        local hookUtilityCooldowns = function(width)
            if self._SCRB_Essential_Utility_hook_widthMode ~= "Sync With Utility Cooldowns" then
                return
            end

            if (width == nil) or (type(width) == "number" and math.floor(width) > 1) then
                self:ApplyLayout(nil, true)
            end
        end

        hooksecurefunc(v, "SetSize", hookUtilityCooldowns)
        hooksecurefunc(v, "Show", hookUtilityCooldowns)
        hooksecurefunc(v, "Hide", hookUtilityCooldowns)

        self._SCRB_Utility_hooked = true
    end
end

------------------------------------------------------------
-- FRAME methods
------------------------------------------------------------

function BarMixin:Show()
    self.Frame:Show()
end

function BarMixin:Hide()
    self.Frame:Hide()
end

function BarMixin:IsShown()
    return self.Frame:IsShown()
end

------------------------------------------------------------
-- GETTERs for some properties, should be used outside
------------------------------------------------------------

function BarMixin:GetFrame()
    return self.Frame
end

function BarMixin:GetConfig()
    return self.config
end

function BarMixin:GetData(layoutName)
    layoutName = layoutName or LEM.GetActiveLayoutName() or "Default"
    return SenseiClassResourceBarDB[self.config.dbName][layoutName]
end

------------------------------------------------------------
-- GETTERS -- Need to be redefined as they return dummy data
------------------------------------------------------------

---@param _ string|number|nil The value returned by BarMixin:GetResource()
---@return table { r = int, g = int, b = int, atlasElementName = string|nil, atlas = string|nil, hasClassResourceVariant = bool|nil }
---https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_UnitFrame/Mainline/PowerBarColorUtil.lua
function BarMixin:GetBarColor(_)
    return { r = 1, g = 1, b = 1 }
end

---@return table { r = int, g = int, b = int }
function BarMixin:GetResourceNumberColor()
    return { r = 1, b = 1, g = 1 }
end

---@return table { r = int, g = int, b = int }
function BarMixin:GetResourceChargeTimerColor()
    return { r = 1, b = 1, g = 1 }
end

---@return string|number|nil The resource, can be anything as long as you handle it in BarMixin:GetResourceValue
function BarMixin:GetResource()
    return nil
end

--- @param _ string|number|nil The value returned by BarMixin:GetResource()
--- @return number|nil Max used for the status bar
--- @return number|nil Value used for the status bar progression
--- @return number|nil DisplayValue Value to display as text
--- @return string|nil ValueType Type for the display, "percent", "number", "timer"
--- @return number|nil precision If needed by the format
function BarMixin:GetResourceValue(_)
    return nil, nil, nil, nil, nil
end

function BarMixin:OnLoad()
end

---@param event string
---@param ... any
function BarMixin:OnEvent(event, ...)
end

-- You should handle what to change here too and set self.smoothEnabled to true
function BarMixin:EnableSmoothProgress()
    self.smoothEnabled = true
    self.Frame:SetScript("OnUpdate", function(_, delta)
        self.Frame.elapsed = (self.Frame.elapsed or 0) + delta
        if self.Frame.elapsed >= 0.01 then
            self.Frame.elapsed = 0
            self:UpdateDisplay()
        end
    end)
end

-- You should handle what to change here too and set self.smoothEnabled to false
function BarMixin:DisableSmoothProgress()
    self.smoothEnabled = false
    self.Frame:SetScript("OnUpdate", function(_, delta)
        self.Frame.elapsed = (self.Frame.elapsed or 0) + delta
        if self.Frame.elapsed >= 0.25 then
            self.Frame.elapsed = 0
            self:UpdateDisplay()
        end
    end)
end

------------------------------------------------------------
-- DISPLAY related methods
------------------------------------------------------------

function BarMixin:UpdateDisplay(layoutName, force)
    if not self:IsShown() and not force then return end

    local data = self:GetData(layoutName)
    if not data then return end

    local resource = self:GetResource()
    if not resource then
        if not LEM:IsInEditMode() then
            self:Hide()
        else
            -- "4" text for edit mode is resource does not exist (e.g. Secondary resource for warrior)
            self.StatusBar:SetMinMaxValues(0, 5)
            self.TextValue:SetText("4")
            self.StatusBar:SetValue(4)
        end
        return
    end

    local max, current, displayValue, valueType, precision = self:GetResourceValue(resource)
    if not max then
        if not LEM:IsInEditMode() then
            self:Hide()
        end
        return
    end

    self.StatusBar:SetMinMaxValues(0, max)
    self.StatusBar:SetValue(current)

    if valueType == "percent" then
        self.TextValue:SetText(string.format("%.0f%%", displayValue))
    elseif valueType == "timer" then
        self.TextValue:SetText(string.format("%." .. (precision or 1) .. "f", displayValue))
    elseif valueType == "custom" then
        self.TextValue:SetText(displayValue)
    else -- Default to number
        self.TextValue:SetText(AbbreviateNumbers(displayValue))
    end

    if addonTable.fragmentedPowerTypes[resource] then
        self:UpdateFragmentedPowerDisplay(layoutName)
    end
end

------------------------------------------------------------
-- VISIBILITY related methods
------------------------------------------------------------

function BarMixin:ApplyVisibilitySettings(layoutName, inCombat)
    local data = self:GetData(layoutName)
    if not data then return end

    self:HideBlizzardPlayerContainer(layoutName)
    self:HideBlizzardSecondaryResource(layoutName)

    -- Don't hide while in edit mode...
    if LEM:IsInEditMode() then
        -- ...Unless config says otherwise
        if type(self.config.allowEditPredicate) == "function" and self.config.allowEditPredicate() == false then
            self:Hide()
            return
        end

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

    local resource = self:GetResource()
    local spec = C_SpecializationInfo.GetSpecialization()
    local role = select(5, C_SpecializationInfo.GetSpecializationInfo(spec))

    if resource == Enum.PowerType.Mana and role == "DAMAGER" and data.hideManaOnDps == true then
        self:Hide();
    end

    self:ApplyTextVisibilitySettings(layoutName)
end

function BarMixin:ApplyTextVisibilitySettings(layoutName)
    local data = self:GetData(layoutName)
    if not data then return end

    self.TextFrame:SetShown(data.showText ~= false)

    for _, fragmentedPowerBarText in ipairs(self.FragmentedPowerBarTexts) do
        fragmentedPowerBarText:SetShown(data.showFragmentedPowerBarText ~= false)
    end
end

function BarMixin:HideBlizzardPlayerContainer(layoutName)
    layoutName = layoutName or LEM.GetActiveLayoutName() or "Default"
    local data = SenseiClassResourceBarDB[self.config.dbName][layoutName]
    if not data then return end

    -- InCombatLockdown() means protected frames so we cannot touch it
    if data.hideBlizzardPlayerContainerUi == nil or InCombatLockdown() then return end

    if PlayerFrame then
        if data.hideBlizzardPlayerContainerUi then
            if LEM:IsInEditMode() then
                PlayerFrame:Show()
            else
                PlayerFrame:Hide()
            end
        else
            PlayerFrame:Show()
        end
    end
end

function BarMixin:HideBlizzardSecondaryResource(layoutName)
    layoutName = layoutName or LEM.GetActiveLayoutName() or "Default"
    local data = SenseiClassResourceBarDB[self.config.dbName][layoutName]
    if not data then return end

    -- InCombatLockdown() means protected frames so we cannot touch it
    if data.hideBlizzardSecondaryResourceUi == nil or InCombatLockdown() then return end

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

    for class, f in pairs(blizzardResourceFrames) do
        if f and playerClass == class then
            if data.hideBlizzardSecondaryResourceUi then
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

------------------------------------------------------------
-- LAYOUT related methods
------------------------------------------------------------

function BarMixin:ApplyLayout(layoutName, force)
    if not self:IsShown() and not force then return end

    local data = self:GetData(layoutName)
    if not data then return end

    local defaults = self.defaults or {}

    local scale = data.scale or defaults.scale
    local point = data.point or defaults.point
    local x = data.x or defaults.x
    local y = data.y or defaults.y

    local width = nil
    if data.widthMode == "Sync With Essential Cooldowns" or data.widthMode == "Sync With Utility Cooldowns" then
        width = self:GetCooldownManagerWidth(layoutName) or data.width or defaults.width
    else -- Use manual width
        width = data.width or defaults.width
    end
    local height = data.height or defaults.height

    self.Frame:SetSize(max(1, width * scale), max(1, height * scale))
    self.Frame:ClearAllPoints()
    self.Frame:SetPoint(point, UIParent, point, x, y)

    self:ApplyFontSettings(layoutName)
    self:ApplyFillDirectionSettings(layoutName)
    self:ApplyMaskAndBorderSettings(layoutName)
    self:ApplyBackgroundSettings(layoutName)
    self:ApplyForegroundSettings(layoutName)

    self:UpdateTicksLayout(layoutName)

    if data.smoothProgress then
        self:EnableSmoothProgress()
    else
        self:DisableSmoothProgress()
    end

    local resource = self:GetResource()
    if addonTable.fragmentedPowerTypes[resource] then
        self:CreateFragmentedPowerBars(layoutName)
        self:UpdateFragmentedPowerDisplay(layoutName)
    end
end

function BarMixin:ApplyFontSettings(layoutName)
    local data = self:GetData(layoutName)
    if not data then return end

    local defaults = self.defaults or {}

    local scale = data.scale or defaults.scale
    local font = data.font or defaults.font
    local size = data.fontSize or defaults.fontSize
    local outline = data.fontOutline or defaults.fontOutline

    self.TextValue:SetFont(font, size * scale, outline)
    self.TextValue:SetShadowColor(0, 0, 0, 0.8)
    self.TextValue:SetShadowOffset(1, -1)

    local color = self:GetResourceNumberColor()
    self.TextValue:SetTextColor(color.r, color.g, color.b, color.a or 1)

    color = self:GetResourceChargeTimerColor()
    for _, fragmentedPowerBarText in ipairs(self.FragmentedPowerBarTexts) do
        fragmentedPowerBarText:SetFont(font, math.max(6, size - 2) * scale, outline)
        fragmentedPowerBarText:SetShadowColor(0, 0, 0, 0.8)
        fragmentedPowerBarText:SetShadowOffset(1, -1)
        fragmentedPowerBarText:SetTextColor(color.r, color.g, color.b)
    end

    -- Text alignment: LEFT, CENTER, RIGHT, TOP, BOTTOM
    local align = data.textAlign or defaults.textAlign or "CENTER"

    if align == "LEFT" or align == "RIGHT" or align == "CENTER" then
        self.TextValue:SetJustifyH(align)
    else
        self.TextValue:SetJustifyH("CENTER") -- Top/Bottom center horizontally
    end

    -- Re-anchor the text inside the text frame depending on alignment
    self.TextValue:ClearAllPoints()
    if align == "LEFT" then
        self.TextValue:SetPoint("LEFT", self.TextFrame, "LEFT", 4, 0)
    elseif align == "RIGHT" then
        self.TextValue:SetPoint("RIGHT", self.TextFrame, "RIGHT", -4, 0)
    elseif align == "TOP" then
        self.TextValue:SetPoint("TOP", self.TextFrame, "TOP", 0, 4)
    elseif align == "BOTTOM" then
        self.TextValue:SetPoint("BOTTOM", self.TextFrame, "BOTTOM", 0, -4)
    else -- Center
        self.TextValue:SetPoint("CENTER", self.TextFrame, "CENTER", 0, 0)
    end
end

function BarMixin:ApplyFillDirectionSettings(layoutName)
    local data = self:GetData(layoutName)
    if not data then return end

    if data.fillDirection == "Top to Bottom" or data.fillDirection == "Bottom to Top" then
        self.StatusBar:SetOrientation("VERTICAL")
    else
        self.StatusBar:SetOrientation("HORIZONTAL")
    end

    if data.fillDirection == "Right to Left" or data.fillDirection == "Top to Bottom" then
        self.StatusBar:SetReverseFill(true)
    else
        self.StatusBar:SetReverseFill(false)
    end

    for _, fragmentedPowerBar in ipairs(self.FragmentedPowerBars) do
        if data.fillDirection == "Top to Bottom" or data.fillDirection == "Bottom to Top" then
            fragmentedPowerBar:SetOrientation("VERTICAL")
        else
            fragmentedPowerBar:SetOrientation("HORIZONTAL")
        end

        if data.fillDirection == "Right to Left" or data.fillDirection == "Top to Bottom" then
            fragmentedPowerBar:SetReverseFill(true)
        else
            fragmentedPowerBar:SetReverseFill(false)
        end
    end
end

function BarMixin:ApplyMaskAndBorderSettings(layoutName)
    local data = self:GetData(layoutName)
    if not data then return end

    -- Hide borders in text-only mode
    if data.noBorderBGMode then
        self.Border:Hide()
        if self.FixedThicknessBorders then
            for _, t in pairs(self.FixedThicknessBorders) do
                t:Hide()
            end
        end
        return
    end

    local defaults = self.defaults or {}

    local styleName = data.maskAndBorderStyle or defaults.maskAndBorderStyle
    local style = addonTable.maskAndBorderStyles[styleName]
    if not style then return end

    local width, height = self.StatusBar:GetSize()
    local verticalOrientation = self.StatusBar:GetOrientation() == "VERTICAL"

    if self.Mask then
        self.StatusBar:GetStatusBarTexture():RemoveMaskTexture(self.Mask)
        self.Background:RemoveMaskTexture(self.Mask)
        self.Mask:ClearAllPoints()
    else
        self.Mask = self.StatusBar:CreateMaskTexture()
    end

    self.Mask:SetTexture(style.mask or [[Interface\AddOns\SenseiClassResourceBar\Textures\Specials\white.png]])
    self.Mask:SetPoint("CENTER", self.StatusBar, "CENTER")
    self.Mask:SetSize(verticalOrientation and height or width, verticalOrientation and width or height)
    self.Mask:SetRotation(verticalOrientation and math.rad(90) or 0)

    self.StatusBar:GetStatusBarTexture():AddMaskTexture(self.Mask)
    self.Background:AddMaskTexture(self.Mask)

    if style.type == "fixed" then
        local bordersInfo = {
            top    = { "TOPLEFT", "TOPRIGHT" },
            bottom = { "BOTTOMLEFT", "BOTTOMRIGHT" },
            left   = { "TOPLEFT", "BOTTOMLEFT" },
            right  = { "TOPRIGHT", "BOTTOMRIGHT" },
        }

        if not self.FixedThicknessBorders then
            self.FixedThicknessBorders = {}
            for edge, _ in pairs(bordersInfo) do
                local t = self.Frame:CreateTexture(nil, "OVERLAY")
                t:SetColorTexture(0, 0, 0, 1)
                t:SetDrawLayer("OVERLAY")
                self.FixedThicknessBorders[edge] = t
            end
        end

        self.Border:Hide()

        -- Linear multiplier: for example, thickness grows 1x at scale 1, 2x at scale 2
        local thickness = (style.thickness or 1) * math.max(data.scale or defaults.scale, 1)
        thickness = math.max(thickness, 1)

        for edge, t in pairs(self.FixedThicknessBorders) do
            local points = bordersInfo[edge]
            t:ClearAllPoints()
            t:SetPoint(points[1], self.Frame, points[1])
            t:SetPoint(points[2], self.Frame, points[2])
            if edge == "top" or edge == "bottom" then
                t:SetHeight(thickness)
            else
                t:SetWidth(thickness)
            end
            t:Show()
        end
    elseif style.type == "texture" then
        self.Border:Show()
        self.Border:SetTexture(style.border)
        self.Border:ClearAllPoints()
        self.Border:SetPoint("CENTER", self.StatusBar, "CENTER")
        self.Border:SetSize(verticalOrientation and height or width, verticalOrientation and width or height)
        self.Border:SetRotation(verticalOrientation and math.rad(90) or 0)

        if self.FixedThicknessBorders then
            for _, t in pairs(self.FixedThicknessBorders) do
                t:Hide()
            end
        end
    else
        self.Border:Hide()

        if self.FixedThicknessBorders then
            for _, t in pairs(self.FixedThicknessBorders) do
                t:Hide()
            end
        end
    end
end

function BarMixin:GetCooldownManagerWidth(layoutName)
    local data = self:GetData(layoutName)
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

function BarMixin:ApplyBackgroundSettings(layoutName)
    local data = self:GetData(layoutName)
    if not data then return end

    -- Hide background in text-only mode
    if data.noBorderBGMode then
        self.Background:SetAlpha(0)
        return
    end

    self.Background:SetAlpha(1)

    local defaults = self.defaults or {}

    local bgStyleName = data.backgroundStyle or defaults.backgroundStyle
    local bgConfig = addonTable.backgroundStyles[bgStyleName]
        or
        (LSM:IsValid(LSM.MediaType.BACKGROUND, bgStyleName) and { type = "texture", value = LSM:Fetch(LSM.MediaType.BACKGROUND, bgStyleName) })
        or nil

    if not bgConfig then return end

    if bgConfig.type == "color" then
        self.Background:SetColorTexture(bgConfig.r or 1, bgConfig.g or 1, bgConfig.b or 1, bgConfig.a or 1)
    elseif bgConfig.type == "texture" then
        self.Background:SetTexture(bgConfig.value)
        self.Background:SetVertexColor(1, 1, 1, 1)
    end
end

function BarMixin:ApplyForegroundSettings(layoutName)
    local data = self:GetData(layoutName)
    if not data then return end

    -- Hide foreground in text-only mode
    if data.noBorderBGMode then
        self.StatusBar:SetAlpha(0)
        for _, fragmentedPowerBar in ipairs(self.FragmentedPowerBars) do
            fragmentedPowerBar:SetAlpha(0)
        end
        return
    end

    local resource = self:GetResource()
    local color = self:GetBarColor(resource)

    -- Apply alpha from color if present
    local alpha = color.a or 1
    self.StatusBar:SetAlpha(alpha)
    for _, fragmentedPowerBar in ipairs(self.FragmentedPowerBars) do
        fragmentedPowerBar:SetAlpha(alpha)
    end

    local defaults = self.defaults or {}

    local fgStyleName = data.foregroundStyle or defaults.foregroundStyle
    local fgTexture = LSM:Fetch(LSM.MediaType.STATUSBAR, fgStyleName)
    if data.useResourceAtlas == true and (color.atlasElementName or color.atlas) then
        if color.atlasElementName then
            if color.hasClassResourceVariant then
                fgTexture = "UI-HUD-UnitFrame-Player-PortraitOn-ClassResource-Bar-" .. color.atlasElementName
            else
                fgTexture = "UI-HUD-UnitFrame-Player-PortraitOn-Bar-" .. color.atlasElementName
            end
        elseif color.atlas then
            fgTexture = color.atlas
        end
    end

    if fgTexture then
        self.StatusBar:SetStatusBarTexture(fgTexture)

        for _, fragmentedPowerBar in ipairs(self.FragmentedPowerBars) do
            fragmentedPowerBar:SetStatusBarTexture(fgTexture)
        end
    end

    if data.useResourceAtlas == true and (color.atlasElementName or color.atlas) then
        self.StatusBar:SetStatusBarColor(1, 1, 1);
    else
        self.StatusBar:SetStatusBarColor(color.r or 1, color.g or 1, color.b or 1);
    end
end

function BarMixin:UpdateTicksLayout(layoutName)
    local data = self:GetData(layoutName)
    if not data then return end

    -- Hide ticks in text-only mode
    if data.noBorderBGMode then
        self.Ticks = self.Ticks or {}
        for _, t in ipairs(self.Ticks) do
            t:Hide()
        end
        return
    end

    local resource = self:GetResource()
    local max = (type(resource) ~= "number") and 0 or UnitPowerMax("player", resource)

    local defaults = self.defaults or {}

    -- Arbitrarily show 4 ticks for edit mode for preview, if spec does not support it
    if LEM:IsInEditMode() and data.showTicks == true and type(resource) ~= "string" and addonTable.tickedPowerTypes[resource] == nil then
        max = 5
        resource = Enum.PowerType.ComboPoints
    end

    self.Ticks = self.Ticks or {}
    if data.showTicks == false or not addonTable.tickedPowerTypes[resource] then
        for _, t in ipairs(self.Ticks) do
            t:Hide()
        end
        return
    end

    local width = self.StatusBar:GetWidth()
    local height = self.StatusBar:GetHeight()
    if width <= 0 or height <= 0 then return end

    local tickThickness = data.tickThickness or defaults.tickThickness or 1

    local needed = max - 1
    for i = 1, needed do
        local t = self.Ticks[i]
        if not t then
            t = self.Frame:CreateTexture(nil, "OVERLAY")
            t:SetColorTexture(0, 0, 0, 1)
            self.Ticks[i] = t
        end
        t:ClearAllPoints()
        if self.StatusBar:GetOrientation() == "VERTICAL" then
            local y = (i / max) * height
            t:SetSize(width, tickThickness)
            t:SetPoint("BOTTOM", self.StatusBar, "BOTTOM", 0, y - (tickThickness) / 2)
        else
            local x = (i / max) * width
            t:SetSize(tickThickness, height)
            t:SetPoint("LEFT", self.StatusBar, "LEFT", x - (tickThickness) / 2, 0)
        end
        t:Show()
    end

    -- Hide any extra ticks
    for i = needed + 1, #self.Ticks do
        local t = self.Ticks[i]
        if t then
            t:Hide()
        end
    end
end

function BarMixin:CreateFragmentedPowerBars(layoutName)
    local data = self:GetData(layoutName)
    if not data then return end

    local defaults = self.defaults or {}

    local resource = self:GetResource()
    if not resource then return end
    for i = 1, UnitPowerMax("player", resource) or 0 do
        if not self.FragmentedPowerBars[i] then
            -- Create a small status bar for each resource (behind main bar, in front of background)
            local bar = CreateFrame("StatusBar", nil, self.Frame)

            local fgStyleName = data.foregroundStyle or defaults.foregroundStyle
            local fgTexture = LSM:Fetch(LSM.MediaType.STATUSBAR, fgStyleName)

            if fgTexture then
                bar:SetStatusBarTexture(fgTexture)
            end
            bar:GetStatusBarTexture():AddMaskTexture(self.Mask)
            bar:SetOrientation("HORIZONTAL")
            bar:SetFrameLevel(self.StatusBar:GetFrameLevel())
            self.FragmentedPowerBars[i] = bar

            -- Create text for reload time display
            local text = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            text:SetPoint("CENTER", bar, "CENTER", 0, 0)
            text:SetJustifyH("CENTER")
            text:SetText("")
            self.FragmentedPowerBarTexts[i] = text
        end
    end
end

function BarMixin:UpdateFragmentedPowerDisplay(layoutName)
    local data = self:GetData(layoutName)
    if not data then return end

    local resource = self:GetResource()
    if not resource then return end
    local maxPower = UnitPowerMax("player", resource)
    if maxPower <= 0 then return end

    local barWidth = self.Frame:GetWidth()
    local barHeight = self.Frame:GetHeight()
    local fragmentedBarWidth = barWidth / maxPower
    local fragmentedBarHeight = barHeight / maxPower

    -- Hide the main status bar fill (we display bars representing one (1) unit of resource each)
    self.StatusBar:SetAlpha(0)

    local r, g, b = self.StatusBar:GetStatusBarColor()
    local color = { r = r, g = g, b = b }

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

        if data.fillDirection == "Right to Left" or data.fillDirection == "Bottom to Top" then
            for i = 1, math.floor(#displayOrder / 2) do
                displayOrder[i], displayOrder[#displayOrder - i + 1] = displayOrder[#displayOrder - i + 1],
                    displayOrder[i]
            end
        end

        for pos = 1, #displayOrder do
            local runeIndex = displayOrder[pos]
            local runeFrame = self.FragmentedPowerBars[runeIndex]
            local runeText = self.FragmentedPowerBarTexts[runeIndex]

            if runeFrame then
                runeFrame:ClearAllPoints()

                if self.StatusBar:GetOrientation() == "VERTICAL" then
                    runeFrame:SetSize(barWidth, fragmentedBarHeight)
                    runeFrame:SetPoint("BOTTOM", self.Frame, "BOTTOM", 0, (pos - 1) * fragmentedBarHeight)
                else
                    runeFrame:SetSize(fragmentedBarWidth, barHeight)
                    runeFrame:SetPoint("LEFT", self.Frame, "LEFT", (pos - 1) * fragmentedBarWidth, 0)
                end

                runeFrame:SetMinMaxValues(0, 1)
                if readyLookup[runeIndex] then
                    runeFrame:SetValue(1)
                    runeText:SetText("")
                    runeFrame:SetStatusBarColor(color.r, color.g, color.b)
                else
                    local cdInfo = cdLookup[runeIndex]
                    runeFrame:SetStatusBarColor(color.r * 0.5, color.g * 0.5, color.b * 0.5)
                    if cdInfo then
                        runeFrame:SetValue(cdInfo.frac)
                        runeText:SetText(string.format("%.1f", math.max(0, cdInfo.remaining)))
                    else
                        runeFrame:SetValue(0)
                        runeText:SetText("")
                    end
                end

                runeFrame:Show()
            end
        end
        self:ApplyFontSettings(layoutName)

        -- Hide any extra rune frames beyond current maxPower
        for i = maxPower + 1, #self.FragmentedPowerBars do
            if self.FragmentedPowerBars[i] then
                self.FragmentedPowerBars[i]:Hide()
                if self.FragmentedPowerBarTexts[i] then
                    self.FragmentedPowerBarTexts[i]:SetText("")
                end
            end
        end
    end
end

addonTable.BarMixin = BarMixin
