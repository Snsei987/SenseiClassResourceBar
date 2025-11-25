local _, addonTable = ...

local LSM = addonTable.LSM or LibStub("LibSharedMedia-3.0")
local LEM = addonTable.LEM or LibStub("LibEditMode")

local LEMSettingsLoaderMixin = {}

local function BuildLemSettings(bar, defaults)
    local config = bar:GetConfig()

    local settings = {
        {
            order = 1,
            name = "Bar Visible",
            kind = LEM.SettingType.Dropdown,
            default = defaults.barVisible,
            values = addonTable.availableBarVisibilityOptions,
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
            minValue = 0.25,
            maxValue = 2,
            valueStep = 0.01,
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
                bar:ApplyLayout(layoutName)
            end,
        },
        {
            order = 11,
            name = "Width Mode",
            kind = LEM.SettingType.Dropdown,
            default = defaults.widthMode,
            values = addonTable.availableWidthModes,
            get = function(layoutName)
                return (SenseiClassResourceBarDB[config.dbName][layoutName] and SenseiClassResourceBarDB[config.dbName][layoutName].widthMode) or defaults.widthMode
            end,
            set = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].widthMode = value
                bar:ApplyLayout(layoutName)
            end,
        },
        {
            order = 11,
            name = "Width",
            kind = LEM.SettingType.Slider,
            default = defaults.width,
            minValue = 1,
            maxValue = 500,
            valueStep = 1,
            get = function(layoutName)
                local data = SenseiClassResourceBarDB[config.dbName][layoutName]
                return data and data.width or defaults.width
            end,
            set = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].width = value
                bar:ApplyLayout(layoutName)
            end,
        },
        {
            order = 12,
            name = "Height",
            kind = LEM.SettingType.Slider,
            default = defaults.height,
            minValue = 1,
            maxValue = 500,
            valueStep = 1,
            get = function(layoutName)
                local data = SenseiClassResourceBarDB[config.dbName][layoutName]
                return data and data.height or defaults.height
            end,
            set = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].height = value
                bar:ApplyLayout(layoutName)
            end,
        },
        {
            order = 13,
            name = "Fill Direction",
            kind = LEM.SettingType.Dropdown,
            default = defaults.fillDirection,
            values = addonTable.availableFillDirections,
            get = function(layoutName)
                return (SenseiClassResourceBarDB[config.dbName][layoutName] and SenseiClassResourceBarDB[config.dbName][layoutName].fillDirection) or defaults.fillDirection
            end,
            set = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].fillDirection = value
                bar:ApplyLayout(layoutName)
            end,
        },
        {
            order = 20,
            name = "Smooth Progress (Higher CPU Usage)",
            kind = LEM.SettingType.Checkbox,
            default = defaults.smoothProgress,
            get = function(layoutName)
                local data = SenseiClassResourceBarDB[config.dbName][layoutName]
                if data and data.smoothProgress ~= nil then
                    return data.smoothProgress
                else
                    return defaults.smoothProgress
                end
            end,
            set = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].smoothProgress = value
                if value then
                    bar:EnableSmoothProgress()
                else
                    bar:DisableSmoothProgress()
                end
            end,
        },
        {
            order = 21,
            name = "Text Only Mode",
            kind = LEM.SettingType.Checkbox,
            default = defaults.textOnlyMode,
            get = function(layoutName)
                local data = SenseiClassResourceBarDB[config.dbName][layoutName]
                if data and data.textOnlyMode ~= nil then
                    return data.textOnlyMode
                else
                    return defaults.textOnlyMode
                end
            end,
            set = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].textOnlyMode = value
                bar:ApplyLayout(layoutName)
            end,
        },
        {
            order = 40,
            name = "Show Resource Number",
            kind = LEM.SettingType.Checkbox,
            default = defaults.showText,
            get = function(layoutName)
                local data = SenseiClassResourceBarDB[config.dbName][layoutName]
                if data and data.showText ~= nil then
                    return data.showText
                else
                    return defaults.showText
                end
            end,
            set = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].showText = value
                bar:ApplyTextVisibilitySettings(layoutName)
            end,
        },
        {
            order = 50,
            name = "Font Face",
            kind = LEM.SettingType.Dropdown,
            default = defaults.font,
            generator = function(dropdown, rootDescription, settingObject)
                dropdown.fontPool = {}

                local layoutName = LEM.GetActiveLayoutName() or "Default"
                local data = SenseiClassResourceBarDB[config.dbName][layoutName]
                if not data then return end

                if not dropdown._SCRB_FontFace_Dropdown_OnMenuClosed_hooked then
                    hooksecurefunc(dropdown, "OnMenuClosed", function() 
                        for _, fontDisplay in pairs(dropdown.fontPool) do
                            fontDisplay:Hide()
                        end
                    end)
                    dropdown._SCRB_FontFace_Dropdown_OnMenuClosed_hooked = true
                end

                local fonts = LSM:HashTable(LSM.MediaType.FONT)
                local sortedFonts = {}
                for fontName in pairs(fonts) do
                    table.insert(sortedFonts, fontName)
                end
                table.sort(sortedFonts)

                local maxVisibleItems = 25
                local itemHeight = 20
                local maxScrollExtent = maxVisibleItems * itemHeight
                rootDescription:SetScrollMode(maxScrollExtent)

                for index, fontName in ipairs(sortedFonts) do
                    local fontPath = fonts[fontName]

                    local button = rootDescription:CreateRadio(fontName, function(d)
                        return d.get(layoutName) == d.value
                    end, function(d)
                        d.set(layoutName, d.value)
                    end, {
                        get = settingObject.get,
                        set = settingObject.set,
                        value = fontPath
                    })

                    button:AddInitializer(function(self)
                        local fontDisplay = dropdown.fontPool[index]
                        if not fontDisplay then
                            fontDisplay = dropdown:CreateFontString(nil, "BACKGROUND")
                            dropdown.fontPool[index] = fontDisplay
                        end

                        self.fontString:Hide()

                        fontDisplay:SetParent(self)
                        fontDisplay:SetPoint("LEFT", self.fontString, "LEFT", 0, 0)
                        fontDisplay:SetFont(fontPath, 12)
                        fontDisplay:SetText(fontName)
                        fontDisplay:Show()
                    end)
                end
            end,
            get = function(layoutName)
                return (SenseiClassResourceBarDB[config.dbName][layoutName] and SenseiClassResourceBarDB[config.dbName][layoutName].font) or defaults.font
            end,
            set = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].font = value
                bar:ApplyFontSettings(layoutName)
            end,
        },
        {
            order = 51,
            name = "Font Size",
            kind = LEM.SettingType.Slider,
            default = defaults.fontSize,
            minValue = 5,
            maxValue = 50,
            valueStep = 1,
            get = function(layoutName)
                local data = SenseiClassResourceBarDB[config.dbName][layoutName]
                return data and data.fontSize or defaults.fontSize
            end,
            set = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].fontSize = value
                bar:ApplyFontSettings(layoutName)
            end,
        },
        {
            order = 52,
            name = "Font Outline",
            kind = LEM.SettingType.Dropdown,
            default = defaults.fontOutline,
            values = addonTable.availableOutlineStyles,
            get = function(layoutName)
                return (SenseiClassResourceBarDB[config.dbName][layoutName] and SenseiClassResourceBarDB[config.dbName][layoutName].fontOutline) or defaults.fontOutline
            end,
            set = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].fontOutline = value
                bar:ApplyFontSettings(layoutName)
            end,
        },
        {
            order = 53,
            name = "Text Alignment",
            kind = LEM.SettingType.Dropdown,
            default = defaults.textAlign,
            values = addonTable.availableTextAlignmentStyles,
            get = function(layoutName)
                return (SenseiClassResourceBarDB[config.dbName][layoutName] and SenseiClassResourceBarDB[config.dbName][layoutName].textAlign) or defaults.textAlign
            end,
            set = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].textAlign = value
                bar:ApplyFontSettings(layoutName)
            end,
        },
        {
            order = 60,
            name = "Border",
            kind = LEM.SettingType.Dropdown,
            default = defaults.maskAndBorderStyle,
            values = addonTable.availableMaskAndBorderStyles,
            get = function(layoutName)
                return (SenseiClassResourceBarDB[config.dbName][layoutName] and SenseiClassResourceBarDB[config.dbName][layoutName].maskAndBorderStyle) or defaults.maskAndBorderStyle
            end,
            set = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].maskAndBorderStyle = value
                bar:ApplyMaskAndBorderSettings(layoutName)
            end,
        },
        {
            order = 61,
            name = "Background",
            kind = LEM.SettingType.Dropdown,
            default = defaults.backgroundStyle,
            generator = function(dropdown, rootDescription, settingObject)
                dropdown.texturePool = {}

                local layoutName = LEM.GetActiveLayoutName() or "Default"
                local data = SenseiClassResourceBarDB[config.dbName][layoutName]
                if not data then return end

                if not dropdown._SCRB_Background_Dropdown_OnMenuClosed_hooked then
                    hooksecurefunc(dropdown, "OnMenuClosed", function() 
                        for _, texture in pairs(dropdown.texturePool) do
                            texture:Hide()
                        end
                    end)
                    dropdown._SCRB_Background_Dropdown_OnMenuClosed_hooked = true
                end

                dropdown:SetDefaultText(settingObject.get(layoutName))

                local textures = LSM:HashTable(LSM.MediaType.BACKGROUND)
                local sortedTextures = CopyTable(addonTable.availableBackgroundStyles)
                for textureName in pairs(textures) do
                    table.insert(sortedTextures, textureName)
                end
                table.sort(sortedTextures)

                local maxVisibleItems = 25
                local itemHeight = 20
                local maxScrollExtent = maxVisibleItems * itemHeight
                rootDescription:SetScrollMode(maxScrollExtent)

                for index, textureName in ipairs(sortedTextures) do
                    local texturePath = textures[textureName]

                    local button = rootDescription:CreateButton(textureName, function()
                        dropdown:SetDefaultText(textureName)
                        settingObject.set(layoutName, textureName)
                    end)

                    if texturePath then
                        button:AddInitializer(function(self)
                            local textureBackground = dropdown.texturePool[index]
                            if not textureBackground then
                                textureBackground = dropdown:CreateTexture(nil, "BACKGROUND")
                                dropdown.texturePool[index] = textureBackground
                            end

                            textureBackground:SetParent(self)
                            textureBackground:SetAllPoints(self)
                            textureBackground:SetTexture(texturePath)

                            textureBackground:Show()
                        end)
                    end
                end
            end,
            get = function(layoutName)
                return (SenseiClassResourceBarDB[config.dbName][layoutName] and SenseiClassResourceBarDB[config.dbName][layoutName].backgroundStyle) or defaults.backgroundStyle
            end,
            set = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].backgroundStyle = value
                bar:ApplyLayout(layoutName)
            end,
        },
        {
            order = 62,
            name = "Foreground",
            kind = LEM.SettingType.Dropdown,
            default = defaults.foregroundStyle,
            generator = function(dropdown, rootDescription, settingObject)
                dropdown.texturePool = {}

                local layoutName = LEM.GetActiveLayoutName() or "Default"
                local data = SenseiClassResourceBarDB[config.dbName][layoutName]
                if not data then return end

                if not dropdown._SCRB_Foreground_Dropdown_OnMenuClosed_hooked then
                    hooksecurefunc(dropdown, "OnMenuClosed", function() 
                        for _, texture in pairs(dropdown.texturePool) do
                            texture:Hide()
                        end
                    end)
                    dropdown._SCRB_Foreground_Dropdown_OnMenuClosed_hooked = true
                end

                dropdown:SetDefaultText(settingObject.get(layoutName))

                local textures = LSM:HashTable(LSM.MediaType.STATUSBAR)
                local sortedTextures = {}
                for textureName in pairs(textures) do
                    table.insert(sortedTextures, textureName)
                end
                table.sort(sortedTextures)

                local maxVisibleItems = 25
                local itemHeight = 20
                local maxScrollExtent = maxVisibleItems * itemHeight
                rootDescription:SetScrollMode(maxScrollExtent)

                for index, textureName in ipairs(sortedTextures) do
                    local texturePath = textures[textureName]

                    local button = rootDescription:CreateButton(textureName, function()
                        dropdown:SetDefaultText(textureName)
                        settingObject.set(layoutName, textureName)
                    end)

                    if texturePath then
                        button:AddInitializer(function(self)
                            local textureStatusBar = dropdown.texturePool[index]
                            if not textureStatusBar then
                                textureStatusBar = dropdown:CreateTexture(nil, "BACKGROUND")
                                dropdown.texturePool[index] = textureStatusBar
                            end

                            textureStatusBar:SetParent(self)
                            textureStatusBar:SetAllPoints(self)
                            textureStatusBar:SetTexture(texturePath)

                            textureStatusBar:Show()
                        end)
                    end
                end
            end,
            get = function(layoutName)
                return (SenseiClassResourceBarDB[config.dbName][layoutName] and SenseiClassResourceBarDB[config.dbName][layoutName].foregroundStyle) or defaults.foregroundStyle
            end,
            set = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].foregroundStyle = value
                bar:ApplyLayout(layoutName)
            end,
        },
    }

    -- Add config-specific settings
    if config.lemSettings and type(config.lemSettings) == "function" then
        local customSettings = config.lemSettings(bar, defaults)
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

function LEMSettingsLoaderMixin:Init(bar, defaults)
    self.bar = bar
    self.defaults = CopyTable(defaults)

    local frame = bar:GetFrame()
    local config = bar:GetConfig()

    local function OnPositionChanged(frame, layoutName, point, x, y)
        SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
        SenseiClassResourceBarDB[config.dbName][layoutName].point = point
        SenseiClassResourceBarDB[config.dbName][layoutName].x = x
        SenseiClassResourceBarDB[config.dbName][layoutName].y = y
        bar:ApplyLayout(layoutName)
    end

    LEM:RegisterCallback("enter", function()
        -- Support for Edit Mode Transparency from BetterBlizzFrames
        if not bar._SCRB_EditModeAlphaSlider_hooked and BBF and BBF.EditModeAlphaSlider then
            BBF.EditModeAlphaSlider:RegisterCallback("OnValueChanged", function(_, value)
                local rounded = math.floor((value / 0.05) + 0.5) * 0.05
                
                if frame and frame.Selection then
                    frame.Selection:SetAlpha(rounded)
                end
            end, bar._SCRB_EditModeAlphaSlider)

            if BetterBlizzFramesDB and BetterBlizzFramesDB["editModeSelectionAlpha"] then
                BBF.EditModeAlphaSlider:TriggerEvent("OnValueChanged", BetterBlizzFramesDB["editModeSelectionAlpha"])
            end

            bar._SCRB_EditModeAlphaSlider_hooked = true
        end

        bar:ApplyVisibilitySettings()
        bar:ApplyLayout()
        bar:UpdateDisplay()
    end)

    LEM:RegisterCallback("exit", function()
        bar:ApplyVisibilitySettings()
        bar:ApplyLayout()
        bar:UpdateDisplay()
    end)

    LEM:RegisterCallback("layout", function(layoutName)
        SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
        bar:InitCooldownManagerWidthHook(layoutName)
        bar:ApplyVisibilitySettings(layoutName)
        bar:ApplyLayout(layoutName, true)
        bar:UpdateDisplay(layoutName, true)
    end)

    -- LEM:RegisterCallback("rename", function(oldLayoutName, newLayoutName)
    --     SenseiClassResourceBarDB[config.dbName][newLayoutName] = CopyTable(SenseiClassResourceBarDB[config.dbName][oldLayoutName])
    --     SenseiClassResourceBarDB[config.dbName][oldLayoutName] = nil
    --     bar:ApplyVisibilitySettings()
    --     bar:ApplyLayout()
    --     bar:UpdateDisplay()
    -- end)

    -- LEM:RegisterCallback("delete", function(layoutName)
    --     SenseiClassResourceBarDB[config.dbName] = SenseiClassResourceBarDB[config.dbName] or {}
    --     SenseiClassResourceBarDB[config.dbName][layoutName] = nil
    --     bar:ApplyVisibilitySettings()
    --     bar:ApplyLayout()
    --     bar:UpdateDisplay()
    -- end)

    LEM:AddFrame(frame, OnPositionChanged, defaults)
end

function LEMSettingsLoaderMixin:LoadSettings()
    local frame = self.bar:GetFrame()

    LEM:AddFrameSettings(frame, BuildLemSettings(self.bar, self.defaults))

    local buttonSettings = {
        {
            text = "Color Settings",
            click = function() -- Cannot directly close Edit Mode because it is protected
                if not addonTable._SCRB_EditModeManagerFrame_OnHide_openSettingsOnExit then
                    addonTable.prettyPrint('Settings will open after leaving Edit Mode')
                end

                addonTable._SCRB_EditModeManagerFrame_OnHide_openSettingsOnExit = true

                if not addonTable._SCRB_EditModeManagerFrame_OnHide_hooked then

                    EditModeManagerFrame:HookScript("OnHide", function()
                        if addonTable._SCRB_EditModeManagerFrame_OnHide_openSettingsOnExit == true then
                            C_Timer.After(0.1, function ()
                                Settings.OpenToCategory(addonTable.settingsCategory:GetID())
                            end)
                            addonTable._SCRB_EditModeManagerFrame_OnHide_openSettingsOnExit = false
                        end
                    end)

                    addonTable._SCRB_EditModeManagerFrame_OnHide_hooked = true
                end
            end
        },
    }

    if LEM.AddFrameSettingsButtons then
        LEM:AddFrameSettingsButtons(frame, buttonSettings)
    else
        for _, buttonSetting in ipairs(buttonSettings) do
            LEM:AddFrameSettingsButton(frame, buttonSetting)
        end
    end
end

addonTable.LEMSettingsLoaderMixin = LEMSettingsLoaderMixin