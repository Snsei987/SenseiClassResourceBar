local _, addonTable = ...

local featureId = "SCRB_POWER_COLORS"

addonTable.AvailableFeatures = addonTable.AvailableFeatures or {}
table.insert(addonTable.AvailableFeatures, featureId)

addonTable.FeaturesMetadata = addonTable.FeaturesMetadata or {}
addonTable.FeaturesMetadata[featureId] = {
	panel = "SCRBPowerColorSettings",
	searchTags = { "Color Powers" },
}

SCRBPowerColorSettingsMixin = {
    PowerData = {
		{
			text  = "Mana",
			power = Enum.PowerType.Mana, -- Key in config, passed to addonTable.GetOverrideResourceColor and addonTable.GetResourceColor to retrieve the color values
		},
		{
			text  = "Rage",
			power = Enum.PowerType.Rage,
		},
		{
			text  = "Focus",
			power = Enum.PowerType.Focus,
		},
		{
			text  = "Energy",
			power = Enum.PowerType.Energy,
		},
		{
			text = "Runic Power",
			power = Enum.PowerType.RunicPower,
		},
		{
			text = "Astral Power",
			power = Enum.PowerType.LunarPower,
		},
		{
			text = "Maelstrom",
			power = Enum.PowerType.Maelstrom,
		},
		{
			text = "Insanity",
			power = Enum.PowerType.Insanity,
		},
		{
			text = "Fury",
			power = Enum.PowerType.Fury,
		},
		{
			text = "Blood Runes",
			power = Enum.PowerType.RuneBlood,
		},
		{
			text = "Frost Runes",
			power = Enum.PowerType.RuneFrost,
		},
		{
			text = "Unholy Runes",
			power = Enum.PowerType.RuneUnholy,
		},
		{
			text = "Combo Points",
			power = Enum.PowerType.ComboPoints,
		},
		{
			text = "Soul Shards",
			power = Enum.PowerType.SoulShards,
		},
		{
			text = "Holy Power",
			power = Enum.PowerType.HolyPower,
		},
		{
			text = "Chi",
			power = Enum.PowerType.Chi,
		},
		{
			text = "Stagger",
			power = "STAGGER",
		},
		{
			text = "Arcane Charges",
			power = Enum.PowerType.ArcaneCharges,
		},
		{
			text = "Soul Fragments",
			power = "SOUL_FRAGMENTS",
		},
		{
			text = "Ebon Might",
			power = "EBON_MIGHT",
		},
	},
}

function SCRBPowerColorSettingsMixin:Init(initializer)
	if not SenseiClassResourceBarDB["_Settings"]["PowerColors"] then
		SenseiClassResourceBarDB["_Settings"]["PowerColors"] = {}
	end

	self.categoryID = initializer.data.categoryID;

	for _, data in ipairs(SCRBPowerColorSettingsMixin.PowerData) do
		initializer:AddSearchTags(data.text);
	end

	self.NewFeature:SetShown(not SenseiClassResourceBarDB["_Settings"]["NewFeaturesShown"][featureId])

	SenseiClassResourceBarDB["_Settings"]["NewFeaturesShown"][featureId] = true
end

function SCRBPowerColorSettingsMixin:OnLoad()
	self.ColorOverrideFramePool = CreateFramePool("FRAME", self.SCRBPowerColorSetting, "ColorOverrideTemplate", nil)
	self.colorOverrideFrames = {}

	local function ResetColorSwatches()
		for _, frame in ipairs(self.colorOverrideFrames) do
			SenseiClassResourceBarDB["_Settings"]["PowerColors"][frame.data.power] = nil -- Remove override
			addonTable.updateBars()

			local color = addonTable:GetResourceColor(frame.data.power) -- Default
			if color then
				frame.Text:SetTextColor(CreateColor(color.r, color.g, color.b):GetRGB())
				frame.ColorSwatch.Color:SetVertexColor(CreateColor(color.r, color.g, color.b):GetRGB())
			end
		end
	end
	EventRegistry:RegisterCallback("Settings.Defaulted", ResetColorSwatches)

	local function CategoryDefaulted(_, category)
		if self.categoryID == category:GetID() then
			ResetColorSwatches()
		end
	end
	EventRegistry:RegisterCallback("Settings.CategoryDefaulted", CategoryDefaulted)

	for index, data in ipairs(SCRBPowerColorSettingsMixin.PowerData) do
		local frame = self.ColorOverrideFramePool:Acquire()
		frame.layoutIndex = index
		self:SetupColorSwatch(frame, data)
		frame:Show()

		table.insert(self.colorOverrideFrames, frame)
	end
end

function SCRBPowerColorSettingsMixin:SetupColorSwatch(frame, data)
	frame.data = data

    frame.Text:SetText(frame.data.text)

	local color = addonTable:GetOverrideResourceColor(frame.data.power)
	if color then
		frame.Text:SetTextColor(CreateColor(color.r, color.g, color.b):GetRGB())
		frame.ColorSwatch.Color:SetVertexColor(CreateColor(color.r, color.g, color.b):GetRGB())
	end

	frame.ColorSwatch:SetScript("OnClick", function()
		self:OpenColorPicker(frame)
	end)
end

function SCRBPowerColorSettingsMixin:OpenColorPicker(frame)
	local info = UIDropDownMenu_CreateInfo()

	local overrideInfo = SenseiClassResourceBarDB["_Settings"]["PowerColors"][frame.data.power] -- Override

	local color = addonTable:GetOverrideResourceColor(frame.data.power)
	if color then
		info.r, info.g, info.b = color.r or 1, color.g or 1, color.b or 1
	end

	info.extraInfo = nil
	info.swatchFunc = function ()
		local r, g, b = ColorPickerFrame:GetColorRGB()
		frame.Text:SetTextColor(r, g, b)
		frame.ColorSwatch.Color:SetVertexColor(r, g, b)

		SenseiClassResourceBarDB["_Settings"]["PowerColors"][frame.data.power] = { r = r, g = g, b = b } -- Set override
		addonTable.updateBars()
	end

	info.cancelFunc = function ()
		local r, g, b = ColorPickerFrame:GetPreviousValues()
		frame.Text:SetTextColor(r, g, b)
		frame.ColorSwatch.Color:SetVertexColor(r, g, b)

		if overrideInfo then
			SenseiClassResourceBarDB["_Settings"]["PowerColors"][frame.data.power] = { r = r, g = g, b = b } -- Set override
		else
			SenseiClassResourceBarDB["_Settings"]["PowerColors"][frame.data.power] = nil -- Remove override
		end
		addonTable.updateBars()
	end

	ColorPickerFrame:SetupColorPickerAndShow(info)
end
