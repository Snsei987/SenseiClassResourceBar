local _, addonTable = ...

local SettingsLib = addonTable.SettingsLib or LibStub("LibEQOLSettingsMode-1.0")
local L = addonTable.L

local featureId = "SCRB_CLASS_OPTIONS"

addonTable.AvailableFeatures = addonTable.AvailableFeatures or {}
table.insert(addonTable.AvailableFeatures, featureId)

-- No category: add to root panel as an expandable section (like Power Colors / Health Colors)
addonTable.FeaturesMetadata = addonTable.FeaturesMetadata or {}
addonTable.FeaturesMetadata[featureId] = {}

addonTable.SettingsPanelInitializers = addonTable.SettingsPanelInitializers or {}
addonTable.SettingsPanelInitializers[featureId] = function(category)
    if not SenseiClassResourceBarDB["_Settings"] then
        SenseiClassResourceBarDB["_Settings"] = {}
    end
    if not SenseiClassResourceBarDB["_Settings"].ClassOptions then
        SenseiClassResourceBarDB["_Settings"].ClassOptions = {}
    end

    local classOptionsSection = SettingsLib:CreateExpandableSection(category, {
        name = L["SETTINGS_CATEGORY_CLASS_OPTIONS"],
        expanded = true,
        colorizeTitle = true,
    })

    -- Helper: setter may be called as (setting, value) or (value) depending on Blizzard API
    local function makeClassOptionSetter(key)
        return function(arg1, arg2)
            local value = (type(arg2) == "boolean" and arg2) or (type(arg1) == "boolean" and arg1) or false
            addonTable.SetClassOption(key, value)
            addonTable.fullUpdateBars()
        end
    end

    -- Druid: show mana in cat and bear form (checkbox)
    SettingsLib:CreateCheckbox(category, {
        key = "showDruidManaInCatAndBearForm",
        variable = "SCRB_ClassOptions_showDruidManaInCatAndBearForm",
        name = L["DRUID_ALWAYS_SHOW_MANA"],
        desc = L["DRUID_ALWAYS_SHOW_MANA_TOOLTIP"],
        default = false,
        get = function()
            return addonTable.GetClassOption("showDruidManaInCatAndBearForm")
        end,
        set = makeClassOptionSetter("showDruidManaInCatAndBearForm"),
        parentSection = classOptionsSection,
    })

    -- Warrior: show Whirlwind bar (Fury) (checkbox)
    SettingsLib:CreateCheckbox(category, {
        key = "showWarriorWhirlwindBar",
        variable = "SCRB_ClassOptions_showWarriorWhirlwindBar",
        name = L["WARRIOR_SHOW_WHIRLWIND_BAR"],
        desc = L["WARRIOR_SHOW_WHIRLWIND_BAR_TOOLTIP"],
        default = false,
        get = function()
            return addonTable.GetClassOption("showWarriorWhirlwindBar")
        end,
        set = makeClassOptionSetter("showWarriorWhirlwindBar"),
        parentSection = classOptionsSection,
    })
end
