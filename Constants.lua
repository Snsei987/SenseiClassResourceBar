local _, addonTable = ...

addonTable.LSM = LibStub("LibSharedMedia-3.0")
local LSM = addonTable.LSM

addonTable.LEM = LibStub("LibEditMode")

------------------------------------------------------------
-- LIBSHAREDMEDIA INTEGRATION
------------------------------------------------------------
local function InitLSM()
    LSM:Register(LSM.MediaType.BACKGROUND, "SCRB BG Bevelled", [[Interface\AddOns\SenseiClassResourceBar\Textures\BarBackgrounds\bevelled.png]])
    LSM:Register(LSM.MediaType.BACKGROUND, "SCRB BG Bevelled Grey", [[Interface\AddOns\SenseiClassResourceBar\Textures\BarBackgrounds\bevelled-grey.png]])
    
    LSM:Register(LSM.MediaType.STATUSBAR, "SCRB FG Fade Left", [[Interface\AddOns\SenseiClassResourceBar\Textures\BarForegrounds\fade-left.png]])
    LSM:Register(LSM.MediaType.STATUSBAR, "SCRB FG Fade Bottom", [[Interface\AddOns\SenseiClassResourceBar\Textures\BarForegrounds\fade-bottom.png]])
    LSM:Register(LSM.MediaType.STATUSBAR, "SCRB FG Fade Top", [[Interface\AddOns\SenseiClassResourceBar\Textures\BarForegrounds\fade-top.png]])
    LSM:Register(LSM.MediaType.STATUSBAR, "SCRB FG Solid", [[Interface\AddOns\SenseiClassResourceBar\Textures\BarForegrounds\solid.png]])
    LSM:Register(LSM.MediaType.STATUSBAR, "None", [[Interface\AddOns\SenseiClassResourceBar\Textures\Specials\transparent.png]])

    LSM:Register(LSM.MediaType.BORDER, "SCRB Border Blizzard Classic", [[Interface\AddOns\SenseiClassResourceBar\Textures\BarBorders\blizzard-classic.png]])

    LSM:Register(LSM.MediaType.FONT, "Friz Quadrata TT", [[Fonts\FRIZQT___CYR.TTF]])
    LSM:Register(LSM.MediaType.FONT, "Morpheus", [[Fonts\MORPHEUS_CYR.TTF]])
    LSM:Register(LSM.MediaType.FONT, "Arial Narrow", [[Fonts\ARIALN.TTF]])
    LSM:Register(LSM.MediaType.FONT, "Skurri", [[Fonts\SKURRI_CYR.TTF]])
end
InitLSM()

------------------------------------------------------------
-- Constants
------------------------------------------------------------

addonTable.TextId = {
    ResourceNumber = 0,
    ResourceChargeTimer = 1,
}

------------------------------------------------------------
-- COMMON DEFAULTS & DROPDOWN OPTIONS
------------------------------------------------------------
addonTable.commonDefaults = {
    point = "CENTER",
    x = 0,
    y = 0,
    barVisible = "Always Visible",
    scale = 1,
    width = 200,
    widthMode = "Manual",
    height = 15,
    fillDirection = "Left to Right",
    smoothProgress = true,
    showText = true,
    showFragmentedPowerBarText = false,
    font = LSM:Fetch(LSM.MediaType.FONT, "Friz Quadrata TT"),
    fontSize = 12,
    fontOutline = "OUTLINE",
    textAlign = "CENTER",
    maskAndBorderStyle = "Thin",
    backgroundStyle = "SCRB Semi-transparent",
    foregroundStyle = "SCRB FG Fade Left",
    noBorderBGMode = false,
}

addonTable.availableBarVisibilityOptions = {
    { text = "Always Visible", isRadio = true },
    { text = "In Combat", isRadio = true },
    { text = "Has Target Selected", isRadio = true },
    { text = "Has Target Selected OR In Combat", isRadio = true },
    { text = "Hidden", isRadio = true },
}

addonTable.availableWidthModes = {
    { text = "Manual", isRadio = true },
    { text = "Sync With Essential Cooldowns", isRadio = true },
    { text = "Sync With Utility Cooldowns", isRadio = true },
}

addonTable.availableFillDirections = {
    { text = "Left to Right", isRadio = true },
    { text = "Right to Left", isRadio = true },
    { text = "Top to Bottom", isRadio = true },
    { text = "Bottom to Top", isRadio = true },
}

addonTable.availableOutlineStyles = {
    { text = "NONE", isRadio = true },
    { text = "OUTLINE", isRadio = true },
    { text = "THICKOUTLINE", isRadio = true },
}

addonTable.availableTextAlignmentStyles = {
    { text = "TOP", isRadio = true },
    { text = "LEFT", isRadio = true },
    { text = "CENTER", isRadio = true },
    { text = "RIGHT", isRadio = true },
    { text = "BOTTOM", isRadio = true },
}

addonTable.maskAndBorderStyles = {
    ["1 Pixel"] = {
        type = "fixed",
        thickness = 1,
    },
    ["Thin"] = {
        type = "fixed",
        thickness = 2,
    },
    ["Slight"] = {
        type = "fixed",
        thickness = 3,
    },
    ["Bold"] = {
        type = "fixed",
        thickness = 5,
    },
    ["Blizzard Classic"] = {
        type = "texture",
        mask = [[Interface\AddOns\SenseiClassResourceBar\Textures\BarBorders\blizzard-classic-mask.png]],
        border = LSM:Fetch(LSM.MediaType.BORDER, "SCRB Border Blizzard Classic"),
    },
    ["None"] = {}
    -- Add more styles here as needed
    -- ["style-name"] = {
    --     type = "", -- texture or fixed. Other value will not be displayed (i.e hidden)
    --     mask = "path/to/mask.png", -- Default to the whole status bar 
    --     border = "path/to/border.png", -- Only for texture type
    --     thickness = 1, -- Only for fixed type
    -- },
}

addonTable.availableMaskAndBorderStyles = {}
for styleName, _ in pairs(addonTable.maskAndBorderStyles) do
    table.insert(addonTable.availableMaskAndBorderStyles, { text = styleName, isRadio = true })
end

addonTable.backgroundStyles = {
    ["SCRB Semi-transparent"] = { type = "color", r = 0, g = 0, b = 0, a = 0.5 },
}

addonTable.availableBackgroundStyles = {}
for name, _ in pairs(addonTable.backgroundStyles) do
    table.insert(addonTable.availableBackgroundStyles, name)
end

-- Power types that should show discrete ticks
addonTable.tickedPowerTypes = {
    [Enum.PowerType.ArcaneCharges] = true,
    [Enum.PowerType.Chi] = true,
    [Enum.PowerType.ComboPoints] = true,
    [Enum.PowerType.Essence] = true,
    [Enum.PowerType.HolyPower] = true,
    [Enum.PowerType.Runes] = true,
    [Enum.PowerType.SoulShards] = true,
}

-- Power types that are fragmented (multiple independent segments)
addonTable.fragmentedPowerTypes = {
    --[Enum.PowerType.Essence] = true,
    [Enum.PowerType.Runes] = true,
}