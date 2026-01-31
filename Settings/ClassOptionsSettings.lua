local _, addonTable = ...

local SettingsLib = addonTable.SettingsLib or LibStub("LibEQOLSettingsMode-1.0")
local L = addonTable.L

local featureId = "SCRB_CLASS_OPTIONS"

addonTable.AvailableFeatures = addonTable.AvailableFeatures or {}
table.insert(addonTable.AvailableFeatures, featureId)

addonTable.FeaturesMetadata = addonTable.FeaturesMetadata or {}
addonTable.FeaturesMetadata[featureId] = {
    category = L["SETTINGS_CATEGORY_CLASS_OPTIONS"],
}

addonTable.SettingsPanelInitializers = addonTable.SettingsPanelInitializers or {}
addonTable.SettingsPanelInitializers[featureId] = function(category)
    if not SenseiClassResourceBarDB["_Settings"] then
        SenseiClassResourceBarDB["_Settings"] = {}
    end
    if not SenseiClassResourceBarDB["_Settings"].ClassOptions then
        SenseiClassResourceBarDB["_Settings"].ClassOptions = {}
    end

    -- Druid: show mana in cat and bear form
    SettingsLib:CreateText(category, L["DRUID_ALWAYS_SHOW_MANA"])
    SettingsLib:CreateText(category, L["DRUID_ALWAYS_SHOW_MANA_TOOLTIP"])
    SettingsLib:CreateButton(category, {
        text = addonTable.GetClassOption("showDruidManaInCatAndBearForm") and L["SETTINGS_OPTION_ENABLED"] or L["SETTINGS_OPTION_DISABLED"],
        func = function()
            addonTable.SetClassOption("showDruidManaInCatAndBearForm", not addonTable.GetClassOption("showDruidManaInCatAndBearForm"))
            addonTable.fullUpdateBars()
        end,
    })

    -- Warrior: show Whirlwind bar (Fury)
    SettingsLib:CreateText(category, L["WARRIOR_SHOW_WHIRLWIND_BAR"])
    SettingsLib:CreateText(category, L["WARRIOR_SHOW_WHIRLWIND_BAR_TOOLTIP"])
    SettingsLib:CreateButton(category, {
        text = addonTable.GetClassOption("showWarriorWhirlwindBar") and L["SETTINGS_OPTION_ENABLED"] or L["SETTINGS_OPTION_DISABLED"],
        func = function()
            addonTable.SetClassOption("showWarriorWhirlwindBar", not addonTable.GetClassOption("showWarriorWhirlwindBar"))
            addonTable.fullUpdateBars()
        end,
    })
end
