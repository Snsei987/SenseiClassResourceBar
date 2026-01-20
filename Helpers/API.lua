local addonName, addonTable = ...

local LEM = addonTable.LEM or LibStub("LibEQOLEditMode-1.0")
local LibSerialize = addonTable.LibSerialize or LibStub("LibSerialize")
local LibDeflate = addonTable.LibDeflate or LibStub("LibDeflate")

local EXPORT_VERSION = 1

addonTable.updateBar = function(name)
    local bar = addonTable.barInstances[name]
    if not bar then return end

    bar:ApplyLayout()
end

addonTable.updateBars = function()
    for name, _ in pairs(addonTable.barInstances) do
        addonTable.updateBar(name)
    end
end

addonTable.fullUpdateBar = function(name)
    local bar = addonTable.barInstances[name]
    if not bar then return end

    bar:InitCooldownManagerWidthHook()
    bar:ApplyVisibilitySettings()
    bar:ApplyLayout()
    bar:UpdateDisplay()
end

addonTable.fullUpdateBars = function()
    for name, _ in pairs(addonTable.barInstances) do
        addonTable.fullUpdateBar(name)
    end
end

addonTable.decodeImportString = function(importString)
    local prefix, version, encoded = importString:match("^([^:]+):(%d+):(.+)$")
    if prefix ~= addonName then
        return nil, "This import string is not suitable for " .. addonName
    end
    if not version or version ~= tostring(EXPORT_VERSION) then
        return nil, "This import string is meant for an older version of " .. addonName
    end
    if not encoded then
        return nil, "Invalid import string"
    end

    local compressed = LibDeflate:DecodeForPrint(encoded)
    if not compressed then
        return nil, "Decode failed"
    end

    local serialized = LibDeflate:DecompressDeflate(compressed)
    if not serialized then
        return nil, "Decompression failed"
    end

    local success, data = LibSerialize:Deserialize(serialized)
    if not success then
        return nil, "Deserialization failed"
    end

    return data
end

addonTable.encodeDataAsString = function(data)
    local serialized = LibSerialize:Serialize(data)
    local compressed = LibDeflate:CompressDeflate(serialized, {level = 9})
    local encoded = LibDeflate:EncodeForPrint(compressed)

    return addonName .. ":" .. EXPORT_VERSION .. ":" .. encoded
end

addonTable.exportBarAsString = function(dbName)
    local data = {
        BARS = {},
    }

    local layoutName = LEM.GetActiveLayoutName() or "Default"
    if dbName
    and SenseiClassResourceBarDB
    and SenseiClassResourceBarDB[dbName]
    and SenseiClassResourceBarDB[dbName][layoutName] then
        data.BARS[dbName] = SenseiClassResourceBarDB[dbName][layoutName] or nil
    end

    return addonTable.encodeDataAsString(data)
end

--- Can work with default global export string
addonTable.importBarAsString = function(importString, dbName)
    local data, errMsg = addonTable.decodeImportString(importString)
    if not data or errMsg then
        return nil, errMsg or "?"
    end

    if data.BARS[dbName] then
        if not SenseiClassResourceBarDB then
            SenseiClassResourceBarDB = {}
        end

        local layoutName = LEM.GetActiveLayoutName() or "Default"
        SenseiClassResourceBarDB[dbName][layoutName] = data.BARS[dbName]
    end

    return data
end

addonTable.exportProfileAsString = function(includeBarSettings, includeAddonSettings)
    local data = {
        BARS = {},
        GLOBAL = nil,
    }

    if includeBarSettings then
        local layoutName = LEM.GetActiveLayoutName() or "Default"
        for _, barSettings in pairs(addonTable.RegistereredBar or {}) do
            if barSettings
            and barSettings.dbName
            and SenseiClassResourceBarDB
            and SenseiClassResourceBarDB[barSettings.dbName]
            and SenseiClassResourceBarDB[barSettings.dbName][layoutName] then
                data.BARS[barSettings.dbName] = SenseiClassResourceBarDB[barSettings.dbName][layoutName] or nil
            end
        end
    end

    if includeAddonSettings then
        if SenseiClassResourceBarDB and SenseiClassResourceBarDB["_Settings"] then
            data.GLOBAL = SenseiClassResourceBarDB["_Settings"]
        end
    end

    return addonTable.encodeDataAsString(data)
end
SCRB.exportProfileAsString = addonTable.exportProfileAsString

--- Can work with individual export string
addonTable.importProfileFromString = function(importString)
    local data, errMsg = addonTable.decodeImportString(importString)
    if not data or errMsg then
        return nil, errMsg or "?"
    end

    local layoutName = LEM.GetActiveLayoutName() or "Default"
    for dbName, barSettings in pairs(data.BARS or {}) do
        if not SenseiClassResourceBarDB then
            SenseiClassResourceBarDB = {}
        end

        if not SenseiClassResourceBarDB[dbName] then
            SenseiClassResourceBarDB[dbName] = {}
        end

        SenseiClassResourceBarDB[dbName][layoutName] = barSettings
    end

    if data.GLOBAL then
        if not SenseiClassResourceBarDB then
            SenseiClassResourceBarDB = {}
        end

		SenseiClassResourceBarDB["_Settings"] = data.GLOBAL
    end

    return data
end
SCRB.importProfileFromString = addonTable.importProfileFromString

addonTable.prettyPrint = function(...)
  print("|cffb5a707"..addonName..":|r", ...)
end