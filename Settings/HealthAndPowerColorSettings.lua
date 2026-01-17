local _, addonTable = ...

local SettingsLib = addonTable.SettingsLib or LibStub("LibEQOLSettingsMode-1.0")

local featureId = "SCRB_POWER_COLORS"

addonTable.AvailableFeatures = addonTable.AvailableFeatures or {}
table.insert(addonTable.AvailableFeatures, featureId)

addonTable.FeaturesMetadata = addonTable.FeaturesMetadata or {}
addonTable.FeaturesMetadata[featureId] = {
}

local HealthData = {
	{
		label = "Health",
		key = "HEALTH",
	},
}

local PowerData = {
    {
        label = "Mana",
        key = Enum.PowerType.Mana, -- Key in config, passed to addonTable.GetOverrideResourceColor and addonTable.GetResourceColor to retrieve the color values
    },
    {
        label = "Rage",
        key = Enum.PowerType.Rage,
    },
    {
        label = "Focus",
        key = Enum.PowerType.Focus,
    },
    {
        label = "Energy",
        key = Enum.PowerType.Energy,
    },
    {
        label = "Runic Power",
        key = Enum.PowerType.RunicPower,
    },
    {
        label = "Astral Power",
        key = Enum.PowerType.LunarPower,
    },
    {
        label = "Maelstrom",
        key = Enum.PowerType.Maelstrom,
    },
    {
        label = "Maelstrom Weapon",
        key = "MAELSTROM_WEAPON",
    },
    {
        label = "Maelstrom Weapon > 5",
        key = "MAELSTROM_WEAPON_ABOVE_5",
    },
    {
        label = "Insanity",
        key = Enum.PowerType.Insanity,
    },
    {
        label = "Fury",
        key = Enum.PowerType.Fury,
    },
    {
        label = "Blood Runes",
        key = Enum.PowerType.RuneBlood,
    },
    {
        label = "Frost Runes",
        key = Enum.PowerType.RuneFrost,
    },
    {
        label = "Unholy Runes",
        key = Enum.PowerType.RuneUnholy,
    },
    {
        label = "Combo Points",
        key = Enum.PowerType.ComboPoints,
    },
    {
        label = "Overcharged Combo Points",
        key = "OVERCHARGED_COMBO_POINTS",
    },
    {
        label = "Soul Shards",
        key = Enum.PowerType.SoulShards,
    },
    {
        label = "Holy Power",
        key = Enum.PowerType.HolyPower,
    },
    {
        label = "Chi",
        key = Enum.PowerType.Chi,
    },
    {
        label = "Low Stagger",
        key = "STAGGER_LOW",
    },
    {
        label = "Medium Stagger",
        key = "STAGGER_MEDIUM",
    },
    {
        label = "High Stagger",
        key = "STAGGER_HEAVY",
    },
    {
        label = "Arcane Charges",
        key = Enum.PowerType.ArcaneCharges,
    },
    {
        label = "Soul Fragments",
        key = "SOUL_FRAGMENTS",
    },
    {
        label = "Soul Fragments Void Meta.",
        key = "SOUL_FRAGMENTS_VOID_META",
    },
    {
        label = "Essence",
        key = Enum.PowerType.Essence,
    },
    {
        label = "Ebon Might",
        key = "EBON_MIGHT",
    },
}

addonTable.SettingsPanelInitializers = addonTable.SettingsPanelInitializers or {}
addonTable.SettingsPanelInitializers[featureId] = function(category)
    if not SenseiClassResourceBarDB["_Settings"]["HealthColors"] then
		SenseiClassResourceBarDB["_Settings"]["HealthColors"] = {}
	end

    if not SenseiClassResourceBarDB["_Settings"]["PowerColors"] then
		SenseiClassResourceBarDB["_Settings"]["PowerColors"] = {}
	end

	SettingsLib:CreateHeader(category, "Power Colors")

    SettingsLib:CreateColorOverrides(category, {
        entries = PowerData,
        hasOpacity = true,
        getColor = function(key)
            local color = addonTable:GetOverrideResourceColor(key)
            return color.r, color.g, color.b, color.a or 1
        end,
        setColor = function(key, r, g, b, a)
            SenseiClassResourceBarDB["_Settings"]["PowerColors"][key] = { r = r, g = g, b = b, a = a or 1 }
            addonTable.updateBars()
        end,
        getDefaultColor = function(key)
            local color = addonTable:GetResourceColor(key)
            return color.r, color.g, color.b, color.a or 1
        end,
        colorizeLabel = true,
    })

	SettingsLib:CreateHeader(category, "Health Color")

    SettingsLib:CreateColorOverrides(category, {
        entries = HealthData,
        hasOpacity = true,
        getColor = function(key)
            local color = addonTable:GetOverrideHealthBarColor(key)
            return color.r, color.g, color.b, color.a or 1
        end,
        setColor = function(key, r, g, b, a)
            SenseiClassResourceBarDB["_Settings"]["HealthColors"][key] = { r = r, g = g, b = b, a = a or 1 }
            addonTable.updateBars()
        end,
        getDefaultColor = function(key)
            local color = addonTable:GetHealthBarColor(key)
            return color.r, color.g, color.b, color.a or 1
        end,
        colorizeLabel = true,
    })
end