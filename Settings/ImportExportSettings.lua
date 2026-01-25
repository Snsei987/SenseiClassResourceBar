local _, addonTable = ...

local SettingsLib = addonTable.SettingsLib or LibStub("LibEQOLSettingsMode-1.0")

local featureId = "SCRB_IMPORT_EXPORT"

addonTable.AvailableFeatures = addonTable.AvailableFeatures or {}
table.insert(addonTable.AvailableFeatures, featureId)

addonTable.FeaturesMetadata = addonTable.FeaturesMetadata or {}
addonTable.FeaturesMetadata[featureId] = {
	category = "Import / Export",
}

addonTable.SettingsPanelInitializers = addonTable.SettingsPanelInitializers or {}
addonTable.SettingsPanelInitializers[featureId] = function(category)
    SettingsLib:CreateText(category, "Export strings generated here encompass all bars of your current Edit Mode Layout.\nIf you wish to only export one bar in particular, please check the Export button in the Bar Settings panel in\nEdit Mode.")
    SettingsLib:CreateText(category, "The Import button below supports global and individual bar export strings. The one in each Bar Settings in\nEdit Mode is restricted to this particular bar.\nFor example, if you exported all your bars but wish to only import the Primary Resource Bar, then use the\nImport button of the Primary Resource bar in Edit Mode.")

    SettingsLib:CreateButton(category, {
		text = "Export Only Power Colors",
		func = function()
			local exportString = addonTable.exportProfileAsString(false, true)
			if not exportString then
				addonTable.prettyPrint("Export failed.")
				return
			end

			StaticPopupDialogs["SCRB_EXPORT_SETTINGS"].OnShow = function(self)
				self:SetFrameStrata("TOOLTIP")
				local editBox = self.editBox or self:GetEditBox()
				editBox:SetText(exportString)
				editBox:HighlightText()
				editBox:SetFocus()
			end
			StaticPopup_Show("SCRB_EXPORT_SETTINGS")
		end,
	})

    SettingsLib:CreateButton(category, {
		text = "Export With Power Colors",
		func = function()
			local exportString = addonTable.exportProfileAsString(true, true)
			if not exportString then
				addonTable.prettyPrint("Export failed.")
				return
			end

			StaticPopupDialogs["SCRB_EXPORT_SETTINGS"].OnShow = function(self)
				self:SetFrameStrata("TOOLTIP")
				local editBox = self.editBox or self:GetEditBox()
				editBox:SetText(exportString)
				editBox:HighlightText()
				editBox:SetFocus()
			end
			StaticPopup_Show("SCRB_EXPORT_SETTINGS")
		end,
	})

    SettingsLib:CreateButton(category, {
		text = "Export Without Power Colors",
		func = function()
			local exportString = addonTable.exportProfileAsString(true, false)
			if not exportString then
				addonTable.prettyPrint("Export failed.")
				return
			end

			StaticPopupDialogs["SCRB_EXPORT_SETTINGS"].OnShow = function(self)
				self:SetFrameStrata("TOOLTIP")
				local editBox = self.editBox or self:GetEditBox()
				editBox:SetText(exportString)
				editBox:HighlightText()
				editBox:SetFocus()
			end
			StaticPopup_Show("SCRB_EXPORT_SETTINGS")
		end,
	})

	SettingsLib:CreateButton(category, {
		text = "Import",
		func = function()
			StaticPopupDialogs["SCRB_IMPORT_SETTINGS"].OnAccept = function(self)
				local editBox = self.editBox or self:GetEditBox()
				local input = editBox:GetText() or ""

				local ok, error = addonTable.importProfileFromString(input)
				if not ok then
					addonTable.prettyPrint("Import failed with the following error: "..error)
				end

				addonTable.fullUpdateBars()
			end
			StaticPopup_Show("SCRB_IMPORT_SETTINGS")
		end,
	})
end