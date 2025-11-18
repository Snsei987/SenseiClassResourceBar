local addonName, addonTable = ...

local version = GetBuildInfo()
local addonCategoryId = "SenseiClassResourceBar_Addon_Category"

local function Register()
	if not SenseiClassResourceBarDB then
		SenseiClassResourceBarDB = {}
	end

	if not SenseiClassResourceBarDB["_Settings"] then
		SenseiClassResourceBarDB["_Settings"] = {}
	end

	if not SenseiClassResourceBarDB["_Settings"]["NewFeaturesShown"] then
		SenseiClassResourceBarDB["_Settings"]["NewFeaturesShown"] = {}
	end

	local category, layout = Settings.RegisterVerticalLayoutCategory(addonName)
    addonTable.settingsCategory = category

    for _, feature in pairs(addonTable.AvailableFeatures or {}) do
		local metadata = addonTable.FeaturesMetadata[feature] or {}
		local data = Mixin(metadata.data or {}, { categoryID = category:GetID() })

		local initializer = Settings.CreatePanelInitializer(metadata.panel, data)
		initializer:AddSearchTags(unpack(metadata.searchTags or {}))
		layout:AddInitializer(initializer)
    end

    Settings.RegisterAddOnCategory(category)
end

addonTable.SettingsRegistrar = Register