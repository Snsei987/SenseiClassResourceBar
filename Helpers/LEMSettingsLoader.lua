local _, addonTable = ...

local LSM = addonTable.LSM or LibStub("LibSharedMedia-3.0")
local LEM = addonTable.LEM or LibStub("LibEQOLEditMode-1.0")

local LEMSettingsLoaderMixin = {}

local function BuildLemSettings(bar, defaults)
    local config = bar:GetConfig()

    local uiWidth, uiHeight = GetPhysicalScreenSize()
    uiWidth = uiWidth / 2
    uiHeight = uiHeight / 2

    local settings = {
        {
            order = 100,
            name = "Bar Visibility",
            kind = LEM.SettingType.Collapsible,
            id = "Bar Visibility",
        },
        {
            parentId = "Bar Visibility",
            order = 101,
            name = "Bar Visible",
            kind = LEM.SettingType.Dropdown,
            default = defaults.barVisible,
            useOldStyle = true,
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
            parentId = "Bar Visibility",
            order = 102,
            name = "Bar Strata",
            kind = LEM.SettingType.Dropdown,
            default = defaults.barStrata,
            useOldStyle = true,
            values = addonTable.availableBarStrataOptions,
            get = function(layoutName)
                return (SenseiClassResourceBarDB[config.dbName][layoutName] and SenseiClassResourceBarDB[config.dbName][layoutName].barStrata) or defaults.barStrata
            end,
            set = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].barStrata = value
                bar:ApplyLayout(layoutName)
            end,
            tooltip = "The layer the bar is rendered on",
        },
        {
            parentId = "Bar Visibility",
            order = 104,
            name = "Hide While Mounted Or In Vehicule",
            kind = LEM.SettingType.Checkbox,
            default = defaults.hideWhileMountedOrVehicule,
            get = function(layoutName)
                local data = SenseiClassResourceBarDB[config.dbName][layoutName]
                if data and data.hideWhileMountedOrVehicule ~= nil then
                    return data.hideWhileMountedOrVehicule
                else
                    return defaults.hideWhileMountedOrVehicule
                end
            end,
            set = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].hideWhileMountedOrVehicule = value
            end,
            tooltip = "Includes Druid Travel Form",
        },
        {
            order = 200,
            name = "Position & Size",
            kind = LEM.SettingType.Collapsible,
            id = "Position & Size",
        },
        {
            parentId = "Position & Size",
            order = 202,
            name = "X Position",
            kind = LEM.SettingType.Slider,
            default = defaults.x,
            minValue = uiWidth * -1,
            maxValue = uiWidth,
            valueStep = 1,
            allowInput = true,
            get = function(layoutName)
                local data = SenseiClassResourceBarDB[config.dbName][layoutName]
                return data and addonTable.rounded(data.x) or defaults.x
            end,
            set = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].x = addonTable.rounded(value)
                bar:ApplyLayout(layoutName)
            end,
        },
        {
            parentId = "Position & Size",
            order = 203,
            name = "Y Position",
            kind = LEM.SettingType.Slider,
            default = defaults.y,
            minValue = uiHeight * -1,
            maxValue = uiHeight,
            valueStep = 1,
            allowInput = true,
            get = function(layoutName)
                local data = SenseiClassResourceBarDB[config.dbName][layoutName]
                return data and addonTable.rounded(data.y) or defaults.y
            end,
            set = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].y = addonTable.rounded(value)
                bar:ApplyLayout(layoutName)
            end,
        },
        {
            parentId = "Position & Size",
            order = 204,
            name = "Relative Frame",
            kind = LEM.SettingType.Dropdown,
            default = defaults.relativeFrame,
            useOldStyle = true,
            values = addonTable.availableRelativeFrames(config),
            get = function(layoutName)
                return (SenseiClassResourceBarDB[config.dbName][layoutName] and SenseiClassResourceBarDB[config.dbName][layoutName].relativeFrame) or defaults.relativeFrame
            end,
            set = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].relativeFrame = value
                -- Need to reset some settings so it does not go somewhere unintended
                SenseiClassResourceBarDB[config.dbName][layoutName].x = defaults.x
                SenseiClassResourceBarDB[config.dbName][layoutName].y = defaults.y
                SenseiClassResourceBarDB[config.dbName][layoutName].point = defaults.point
                SenseiClassResourceBarDB[config.dbName][layoutName].relativePoint = defaults.relativePoint
                bar:ApplyLayout(layoutName)
                LEM.internal:RefreshSettingValues({"X Position", "Y Position", "Anchor Point", "Relative Point"})
            end,
            tooltip = "Due to limitations, you may not drag the frame if anchored to another frame than UIParent. Use the X/Y sliders",
        },
        {
            parentId = "Position & Size",
            order = 205,
            name = "Anchor Point",
            kind = LEM.SettingType.Dropdown,
            default = defaults.point,
            useOldStyle = true,
            values = addonTable.availableAnchorPoints,
            get = function(layoutName)
                return (SenseiClassResourceBarDB[config.dbName][layoutName] and SenseiClassResourceBarDB[config.dbName][layoutName].point) or defaults.point
            end,
            set = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].point = value
                bar:ApplyLayout(layoutName)
            end,
        },
        {
            parentId = "Position & Size",
            order = 206,
            name = "Relative Point",
            kind = LEM.SettingType.Dropdown,
            default = defaults.relativePoint,
            useOldStyle = true,
            values = addonTable.availableRelativePoints,
            get = function(layoutName)
                return (SenseiClassResourceBarDB[config.dbName][layoutName] and SenseiClassResourceBarDB[config.dbName][layoutName].relativePoint) or defaults.relativePoint
            end,
            set = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].relativePoint = value
                bar:ApplyLayout(layoutName)
            end,
        },
        {
            parentId = "Position & Size",
            order = 210,
            kind = LEM.SettingType.Divider,
        },
        {
            parentId = "Position & Size",
            order = 211,
            name = "Bar Size",
            kind = LEM.SettingType.Slider,
            default = defaults.scale,
            minValue = 0.25,
            maxValue = 2,
            valueStep = 0.01,
            formatter = function(value)
                return string.format("%d%%", addonTable.rounded(value, 2) * 100)
            end,
            get = function(layoutName)
                local data = SenseiClassResourceBarDB[config.dbName][layoutName]
                return data and addonTable.rounded(data.scale, 2) or defaults.scale
            end,
            set = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].scale = addonTable.rounded(value, 2)
                bar:ApplyLayout(layoutName)
            end,
        },
        {
            parentId = "Position & Size",
            order = 212,
            name = "Width Mode",
            kind = LEM.SettingType.Dropdown,
            default = defaults.widthMode,
            useOldStyle = true,
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
            parentId = "Position & Size",
            order = 213,
            name = "Width",
            kind = LEM.SettingType.Slider,
            default = defaults.width,
            minValue = 1,
            maxValue = 500,
            valueStep = 1,
            allowInput = true,
            get = function(layoutName)
                local data = SenseiClassResourceBarDB[config.dbName][layoutName]
                return data and addonTable.rounded(data.width) or defaults.width
            end,
            set = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].width = addonTable.rounded(value)
                bar:ApplyLayout(layoutName)
            end,
            isEnabled = function (layoutName)
                local data = SenseiClassResourceBarDB[config.dbName][layoutName]
                return data.widthMode == "Manual"
            end,
        },
        {
            parentId = "Position & Size",
            order = 214,
            name = "Minimum Width",
            kind = LEM.SettingType.Slider,
            default = defaults.minWidth,
            minValue = 0,
            maxValue = 500,
            valueStep = 1,
            allowInput = true,
            get = function(layoutName)
                local data = SenseiClassResourceBarDB[config.dbName][layoutName]
                return data and addonTable.rounded(data.minWidth) or defaults.minWidth
            end,
            set = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].minWidth = addonTable.rounded(value)
                bar:ApplyLayout(layoutName)
            end,
            tooltip = "0 to disable. Only active if synced to the Cooldown Manager",
            isEnabled = function (layoutName)
                local data = SenseiClassResourceBarDB[config.dbName][layoutName]
                return data.widthMode == "Sync With Essential Cooldowns" or data.widthMode == "Sync With Utility Cooldowns" 
            end,
        },
        {
            parentId = "Position & Size",
            order = 215,
            name = "Height",
            kind = LEM.SettingType.Slider,
            default = defaults.height,
            minValue = 1,
            maxValue = 500,
            valueStep = 1,
            allowInput = true,
            get = function(layoutName)
                local data = SenseiClassResourceBarDB[config.dbName][layoutName]
                return data and addonTable.rounded(data.height) or defaults.height
            end,
            set = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].height = addonTable.rounded(value)
                bar:ApplyLayout(layoutName)
            end,
        },
        {
            order = 300,
            name = "Bar Settings",
            kind = LEM.SettingType.Collapsible,
            id = "Bar Settings",
            defaultCollapsed = true,
        },
        {
            parentId = "Bar Settings",
            order = 301,
            name = "Fill Direction",
            kind = LEM.SettingType.Dropdown,
            default = defaults.fillDirection,
            useOldStyle = true,
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
            parentId = "Bar Settings",
            order = 302,
            name = "Faster Updates (Higher CPU Usage)",
            kind = LEM.SettingType.Checkbox,
            default = defaults.fasterUpdates,
            get = function(layoutName)
                local data = SenseiClassResourceBarDB[config.dbName][layoutName]
                if data and data.fasterUpdates ~= nil then
                    return data.fasterUpdates
                else
                    return defaults.fasterUpdates
                end
            end,
            set = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].fasterUpdates = value
                if value then
                    bar:EnableFasterUpdates()
                else
                    bar:DisableFasterUpdates()
                end
            end,
        },
        {
            parentId = "Bar Settings",
            order = 303,
            name = "Smooth Progress",
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
            end,
        },
        {
            order = 400,
            name = "Bar Style",
            kind = LEM.SettingType.Collapsible,
            id = "Bar Style",
            defaultCollapsed = true,
        },
        {
            parentId = "Bar Style",
            order = 405,
            name = "Border",
            kind = LEM.SettingType.DropdownColor,
            default = defaults.maskAndBorderStyle,
            colorDefault = defaults.borderColor,
            useOldStyle = true,
            values = addonTable.availableMaskAndBorderStyles,
            get = function(layoutName)
                return (SenseiClassResourceBarDB[config.dbName][layoutName] and SenseiClassResourceBarDB[config.dbName][layoutName].maskAndBorderStyle) or defaults.maskAndBorderStyle
            end,
            colorGet = function(layoutName)
                local data = SenseiClassResourceBarDB[config.dbName][layoutName]
                return data and data.borderColor or defaults.borderColor
            end,
            set = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].maskAndBorderStyle = value
                bar:ApplyMaskAndBorderSettings(layoutName)
            end,
            colorSet = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].borderColor = value
                bar:ApplyMaskAndBorderSettings(layoutName)
            end,
        },
        {
            parentId = "Bar Style",
            order = 403,
            name = "Background",
            kind = LEM.SettingType.DropdownColor,
            default = defaults.backgroundStyle,
            colorDefault = defaults.backgroundColor,
            useOldStyle = true,
            height = 200,
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
            colorGet = function(layoutName)
                local data = SenseiClassResourceBarDB[config.dbName][layoutName]
                return data and data.backgroundColor or defaults.backgroundColor
            end,
            set = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].backgroundStyle = value
                bar:ApplyLayout(layoutName)
            end,
            colorSet = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].backgroundColor = value
                bar:ApplyBackgroundSettings(layoutName)
            end,
        },
        {
            parentId = "Bar Style",
            order = 404,
            name = "Use Bar Color For Background Color",
            kind = LEM.SettingType.Checkbox,
            default = defaults.useStatusBarColorForBackgroundColor,
            get = function(layoutName)
                local data = SenseiClassResourceBarDB[config.dbName][layoutName]
                if data and data.useStatusBarColorForBackgroundColor ~= nil then
                    return data.useStatusBarColorForBackgroundColor
                else
                    return defaults.useStatusBarColorForBackgroundColor
                end
            end,
            set = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].useStatusBarColorForBackgroundColor = value
                bar:ApplyBackgroundSettings(layoutName)
            end,
        },
        {
            parentId = "Bar Style",
            order = 402,
            name = "Bar Texture",
            kind = LEM.SettingType.Dropdown,
            default = defaults.foregroundStyle,
            useOldStyle = true,
            height = 200,
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
            isEnabled = function(layoutName)
                local data = SenseiClassResourceBarDB[config.dbName][layoutName]
                return not data.useResourceAtlas
            end,
        },
        {
            order = 500,
            name = "Text Settings",
            kind = LEM.SettingType.Collapsible,
            id = "Text Settings",
            defaultCollapsed = true,
        },
        {
            parentId = "Text Settings",
            order = 501,
            name = "Show Resource Number",
            kind = LEM.SettingType.CheckboxColor,
            default = defaults.showText,
            colorDefault = defaults.textColor,
            get = function(layoutName)
                local data = SenseiClassResourceBarDB[config.dbName][layoutName]
                if data and data.showText ~= nil then
                    return data.showText
                else
                    return defaults.showText
                end
            end,
            colorGet = function(layoutName)
                local data = SenseiClassResourceBarDB[config.dbName][layoutName]
                return data and data.textColor or defaults.textColor
            end,
            set = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].showText = value
                bar:ApplyTextVisibilitySettings(layoutName)
            end,
            colorSet = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].textColor = value
                bar:ApplyFontSettings(layoutName)
            end,
        },
        {
            parentId = "Text Settings",
            order = 502,
            name = "Format",
            kind = LEM.SettingType.Dropdown,
            default = defaults.textFormat,
            useOldStyle = true,
            values = addonTable.availableTextFormats,
            get = function(layoutName)
                return (SenseiClassResourceBarDB[config.dbName][layoutName] and SenseiClassResourceBarDB[config.dbName][layoutName].textFormat) or defaults.textFormat
            end,
            set = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].textFormat = value
                bar:UpdateDisplay(layoutName)
            end,
            isEnabled = function(layoutName)
                local data = SenseiClassResourceBarDB[config.dbName][layoutName]
                return data.showText
            end,
        },
        {
            parentId = "Text Settings",
            order = 503,
            name = "Precision",
            kind = LEM.SettingType.Dropdown,
            default = defaults.textPrecision,
            useOldStyle = true,
            values = addonTable.availableTextPrecisions,
            get = function(layoutName)
                return (SenseiClassResourceBarDB[config.dbName][layoutName] and SenseiClassResourceBarDB[config.dbName][layoutName].textPrecision) or defaults.textPrecision
            end,
            set = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].textPrecision = value
                bar:UpdateDisplay(layoutName)
            end,
            isEnabled = function(layoutName)
                local data = SenseiClassResourceBarDB[config.dbName][layoutName]
                return data.showText and addonTable.textPrecisionAllowedForType[data.textFormat] ~= nil
            end,
        },
        {
            parentId = "Text Settings",
            order = 504,
            name = "Alignment",
            kind = LEM.SettingType.Dropdown,
            default = defaults.textAlign,
            useOldStyle = true,
            values = addonTable.availableTextAlignmentStyles,
            get = function(layoutName)
                return (SenseiClassResourceBarDB[config.dbName][layoutName] and SenseiClassResourceBarDB[config.dbName][layoutName].textAlign) or defaults.textAlign
            end,
            set = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].textAlign = value
                bar:ApplyFontSettings(layoutName)
            end,
            isEnabled = function(layoutName)
                local data = SenseiClassResourceBarDB[config.dbName][layoutName]
                return data.showText
            end,
        },
        {
            order = 600,
            name = "Font",
            kind = LEM.SettingType.Collapsible,
            id = "Font",
            defaultCollapsed = true,
        },
        {
            parentId = "Font",
            order = 601,
            name = "Font",
            kind = LEM.SettingType.Dropdown,
            default = defaults.font,
            useOldStyle = true,
            height = 200,
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
            parentId = "Font",
            order = 602,
            name = "Size",
            kind = LEM.SettingType.Slider,
            default = defaults.fontSize,
            minValue = 5,
            maxValue = 50,
            valueStep = 1,
            get = function(layoutName)
                local data = SenseiClassResourceBarDB[config.dbName][layoutName]
                return data and addonTable.rounded(data.fontSize) or defaults.fontSize
            end,
            set = function(layoutName, value)
                SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][layoutName] or CopyTable(defaults)
                SenseiClassResourceBarDB[config.dbName][layoutName].fontSize = addonTable.rounded(value)
                bar:ApplyFontSettings(layoutName)
            end,
        },
        {
            parentId = "Font",
            order = 603,
            name = "Outline",
            kind = LEM.SettingType.Dropdown,
            default = defaults.fontOutline,
            useOldStyle = true,
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
        SenseiClassResourceBarDB[config.dbName][layoutName].relativePoint = point
        SenseiClassResourceBarDB[config.dbName][layoutName].x = x
        SenseiClassResourceBarDB[config.dbName][layoutName].y = y
        bar:ApplyLayout(layoutName)
        LEM.internal:RefreshSettingValues({"X Position", "Y Position"})
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

    LEM:RegisterCallback("layoutduplicate", function(_, duplicateIndices, _, _, layoutName)
        local original = LEM:GetLayouts()[duplicateIndices[1]].name
        SenseiClassResourceBarDB[config.dbName][layoutName] = SenseiClassResourceBarDB[config.dbName][original] and CopyTable(SenseiClassResourceBarDB[config.dbName][original]) or CopyTable(defaults)
        bar:InitCooldownManagerWidthHook(layoutName)
        bar:ApplyVisibilitySettings(layoutName)
        bar:ApplyLayout(layoutName, true)
        bar:UpdateDisplay(layoutName, true)
    end)

    LEM:RegisterCallback("layoutrenamed", function(oldLayoutName, newLayoutName)
        SenseiClassResourceBarDB[config.dbName][newLayoutName] = SenseiClassResourceBarDB[config.dbName][oldLayoutName] and CopyTable(SenseiClassResourceBarDB[config.dbName][oldLayoutName]) or CopyTable(defaults)
        SenseiClassResourceBarDB[config.dbName][oldLayoutName] = nil
        bar:InitCooldownManagerWidthHook(newLayoutName)
        bar:ApplyVisibilitySettings()
        bar:ApplyLayout()
        bar:UpdateDisplay()
    end)

    LEM:RegisterCallback("layoutdeleted", function(_, layoutName)
        SenseiClassResourceBarDB[config.dbName] = SenseiClassResourceBarDB[config.dbName] or {}
        SenseiClassResourceBarDB[config.dbName][layoutName] = nil
        bar:ApplyVisibilitySettings()
        bar:ApplyLayout()
        bar:UpdateDisplay()
    end)

    LEM:AddFrame(frame, OnPositionChanged, defaults)
end

function LEMSettingsLoaderMixin:LoadSettings()
    local frame = self.bar:GetFrame()

    LEM:AddFrameSettings(frame, BuildLemSettings(self.bar, self.defaults))

    local buttonSettings = {
        {
            text = "Power Color Settings",
            click = function() -- Cannot directly close Edit Mode because it is protected
                if not addonTable._SCRB_EditModeManagerFrame_OnHide_openSettingsOnExit then
                    addonTable.prettyPrint('Settings will open after leaving Edit Mode')
                end

                addonTable._SCRB_EditModeManagerFrame_OnHide_openSettingsOnExit = true

                if not addonTable._SCRB_EditModeManagerFrame_OnHide_hooked then

                    EditModeManagerFrame:HookScript("OnHide", function()
                        if addonTable._SCRB_EditModeManagerFrame_OnHide_openSettingsOnExit == true then
                            C_Timer.After(0.1, function ()
                                Settings.OpenToCategory(addonTable.rootSettingsCategory:GetID())
                            end)
                            addonTable._SCRB_EditModeManagerFrame_OnHide_openSettingsOnExit = false
                        end
                    end)

                    addonTable._SCRB_EditModeManagerFrame_OnHide_hooked = true
                end
            end
        },
        {
            text = "Export This Bar",
            click = function()
                local exportString = addonTable.exportBarAsString(self.bar:GetConfig().dbName)
                if not exportString then
                    addonTable.prettyPrint("Export failed.")
                    return
                end
                StaticPopupDialogs["SCRB_EXPORT_SETTINGS"] = StaticPopupDialogs["SCRB_EXPORT_SETTINGS"]
                    or {
                        text = "Export",
                        button1 = CLOSE,
                        hasEditBox = true,
                        editBoxWidth = 320,
                        timeout = 0,
                        whileDead = true,
                        hideOnEscape = true,
                        preferredIndex = 3,
                    }
                StaticPopupDialogs["SCRB_EXPORT_SETTINGS"].OnShow = function(self)
                    self:SetFrameStrata("TOOLTIP")
                    local editBox = self.editBox or self:GetEditBox()
                    editBox:SetText(exportString)
                    editBox:HighlightText()
                    editBox:SetFocus()
                end
                StaticPopup_Show("SCRB_EXPORT_SETTINGS")
            end,
        },
        {
            text = "Import This Bar",
            click = function()
                local dbName = self.bar:GetConfig().dbName
                StaticPopupDialogs["SCRB_IMPORT_SETTINGS"] = StaticPopupDialogs["SCRB_IMPORT_SETTINGS"]
				or {
					text = "Import",
					button1 = OKAY,
					button2 = CANCEL,
					hasEditBox = true,
					editBoxWidth = 320,
					timeout = 0,
					whileDead = true,
					hideOnEscape = true,
					preferredIndex = 3,
				}
                StaticPopupDialogs["SCRB_IMPORT_SETTINGS"].OnShow = function(self)
                    self:SetFrameStrata("TOOLTIP")
                    local editBox = self.editBox or self:GetEditBox()
                    editBox:SetText("")
                    editBox:SetFocus()
                end
                StaticPopupDialogs["SCRB_IMPORT_SETTINGS"].EditBoxOnEnterPressed = function(editBox)
                    local parent = editBox:GetParent()
                    if parent and parent.button1 then parent.button1:Click() end
                end
                StaticPopupDialogs["SCRB_IMPORT_SETTINGS"].OnAccept = function(self)
                    local editBox = self.editBox or self:GetEditBox()
                    local input = editBox:GetText() or ""

                    local ok, error = addonTable.importBarAsString(input, dbName)
                    if not ok then
                        addonTable.prettyPrint("Import failed with the following error: "..error)
                    end

                    addonTable.fullUpdateBars()
                    LEM.internal:RefreshSettingValues()
                end
                StaticPopup_Show("SCRB_IMPORT_SETTINGS")
            end
        }
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