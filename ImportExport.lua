-- Import / Export of custom spells (and, optionally, their per-spell settings)
-- so players can share their BigDebuffs setup with each other. The payload is
-- AceSerializer-serialized, deflate-compressed and print-encoded into a single
-- copy/paste string prefixed for identification and versioning.

local BigDebuffs = LibStub("AceAddon-3.0"):GetAddon("BigDebuffs")
local L = LibStub("AceLocale-3.0"):GetLocale("BigDebuffs")
local AceGUI = LibStub("AceGUI-3.0")
local AceSerializer = LibStub("AceSerializer-3.0")
local LibDeflate = LibStub("LibDeflate")
local GetSpellInfo = C_Spell and C_Spell.GetSpellInfo or GetSpellInfo

local function GetSpellName(id)
    if C_Spell and C_Spell.GetSpellName then
        return C_Spell.GetSpellName(id)
    else
        return GetSpellInfo(id)
    end
end

-- String format: "!BD:<version>!<print-encoded deflate of AceSerializer blob>"
local PREFIX = "!BD:1!"

local function CopyTable(src)
    local dst = {}
    for k, v in pairs(src) do
        if type(v) == "table" then
            dst[k] = CopyTable(v)
        else
            dst[k] = v
        end
    end
    return dst
end

-- Fields on a profile.spells[id] entry that are visual "settings", as opposed
-- to the category (type) override which is part of the spell definition itself.
local SETTING_KEYS = {
    "raidFrames", "unitFrames", "nameplates",
    "customPriority", "priority", "customSize", "size",
}

-- Build the export payload from the current profile. Custom spells, preset
-- category re-categorizations and preset ID replacements are always included
-- (they define *which* spells are tracked and in *what* category). The visual
-- per-spell settings (visibility, priority, size) are only included when
-- includeSettings is true.
local function BuildPayload(includeSettings)
    local profile = BigDebuffs.db.profile
    local payload = { v = 1, customSpells = {}, spells = {} }

    for id, cs in pairs(profile.customSpells) do
        if cs.type then
            payload.customSpells[id] = CopyTable(cs)
        end
    end

    for id, ov in pairs(profile.spells) do
        local entry = {}
        if ov.type then entry.type = ov.type end            -- preset category override
        if includeSettings then
            for _, k in ipairs(SETTING_KEYS) do
                if ov[k] ~= nil then entry[k] = ov[k] end
            end
        end
        if next(entry) ~= nil then payload.spells[id] = entry end
    end

    if profile.spellReplacements and next(profile.spellReplacements) ~= nil then
        payload.spellReplacements = CopyTable(profile.spellReplacements)
    end

    return payload
end

-- Returns the encoded share string, or nil if there is nothing to export.
function BigDebuffs:ExportSpellString(includeSettings)
    local payload = BuildPayload(includeSettings)
    if next(payload.customSpells) == nil
        and next(payload.spells) == nil
        and not payload.spellReplacements then
        return nil
    end

    local serialized = AceSerializer:Serialize(payload)
    local compressed = LibDeflate:CompressDeflate(serialized)
    local encoded = LibDeflate:EncodeForPrint(compressed)
    return PREFIX .. encoded
end

-- Decode a share string back into a payload table. Returns payload, or
-- nil + error message on any malformed input.
local function DecodeString(str)
    if type(str) ~= "string" then return nil, L["The import string is not valid"] end
    str = str:gsub("%s+", "")
    if str:sub(1, #PREFIX) ~= PREFIX then
        return nil, L["The import string is not valid"]
    end
    local encoded = str:sub(#PREFIX + 1)

    local compressed = LibDeflate:DecodeForPrint(encoded)
    if not compressed then return nil, L["The import string is not valid"] end
    local serialized = LibDeflate:DecompressDeflate(compressed)
    if not serialized then return nil, L["The import string is not valid"] end
    local ok, payload = AceSerializer:Deserialize(serialized)
    if not ok or type(payload) ~= "table" then
        return nil, L["The import string is not valid"]
    end
    return payload
end

-- Apply a share string to the current profile. In merge mode (replace false)
-- existing entries with the same spell ID are overwritten and every other spell
-- the player has is left untouched. In replace mode the player's custom spells
-- and overrides are cleared first, so the profile ends up matching the string.
-- Returns true + a counts table {spells, overrides, skipped}, or false + message.
function BigDebuffs:ImportSpellString(str, replace)
    local payload, err = DecodeString(str)
    if not payload then return false, err end

    local profile = self.db.profile
    local counts = { spells = 0, overrides = 0, skipped = 0 }

    if replace then
        wipe(profile.customSpells)
        wipe(profile.spells)
        wipe(profile.spellReplacements)
    end

    if type(payload.customSpells) == "table" then
        for id, cs in pairs(payload.customSpells) do
            id = tonumber(id)
            if id and type(cs) == "table" and cs.type and GetSpellName(id) then
                local entry = { type = cs.type }
                if type(cs.duration) == "number" and cs.duration > 0 then
                    entry.duration = cs.duration
                end
                profile.customSpells[id] = entry
                counts.spells = counts.spells + 1
            else
                counts.skipped = counts.skipped + 1
            end
        end
    end

    if type(payload.spells) == "table" then
        for id, ov in pairs(payload.spells) do
            id = tonumber(id)
            if id and type(ov) == "table" and next(ov) ~= nil and GetSpellName(id) then
                -- Merge field-by-field so an import that only carries a category
                -- change does not wipe the importer's own visibility/priority/size.
                local target = profile.spells[id] or {}
                for k, v in pairs(ov) do target[k] = v end
                profile.spells[id] = target
                counts.overrides = counts.overrides + 1
            end
        end
    end

    if type(payload.spellReplacements) == "table" then
        for baseID, newID in pairs(payload.spellReplacements) do
            baseID, newID = tonumber(baseID), tonumber(newID)
            if baseID and newID and GetSpellName(newID) then
                profile.spellReplacements[baseID] = newID
            end
        end
    end

    self:BuildSpellList()
    self:RefreshSpellOptions()
    self:Refresh()
    return true, counts
end

-- ---------------------------------------------------------------------------
-- Options node (a sub-tab under the Spells tab).
--
-- The copy/paste boxes live in dedicated AceGUI popup windows rather than as
-- inline options widgets: an inline MultiLineEditBox is recycled by
-- AceConfigDialog when the user switches sub-tabs and comes back, which leaves
-- the box blank until it is redrawn. A standalone window (the pattern used by
-- WeakAuras, Plater, etc.) is immune to that and is what players expect.
-- ---------------------------------------------------------------------------

local exportIncludeSettings = false
local importReplace = false

-- Popup window showing the export string, pre-selected so the player can copy
-- it straight away with Ctrl+C.
local function ShowExportWindow()
    local text = BigDebuffs:ExportSpellString(exportIncludeSettings)
    if not text then return end

    local frame = AceGUI:Create("Frame")
    frame:SetTitle(L["Export"])
    frame:SetLayout("Fill")
    frame:SetWidth(520)
    frame:SetHeight(300)
    frame:SetCallback("OnClose", function(widget) AceGUI:Release(widget) end)

    local editBox = AceGUI:Create("MultiLineEditBox")
    editBox:SetLabel(L["Copy the string below to share your spells and preset changes with others."])
    editBox:DisableButton(true)
    editBox:SetFullWidth(true)
    editBox:SetFullHeight(true)
    editBox:SetText(text)
    frame:AddChild(editBox)

    local box = editBox.editBox
    box:HighlightText()
    box:SetFocus()
    box:SetScript("OnEscapePressed", function() frame:Hide() end)
end

-- Popup window with an empty box to paste a shared string into and an Import
-- button that respects the Replace toggle.
local function ShowImportWindow()
    local frame = AceGUI:Create("Frame")
    frame:SetTitle(L["Import"])
    frame:SetLayout("Flow")
    frame:SetWidth(520)
    frame:SetHeight(360)
    frame:SetCallback("OnClose", function(widget) AceGUI:Release(widget) end)

    local editBox = AceGUI:Create("MultiLineEditBox")
    editBox:SetLabel(L["Paste a shared string below and click Import."])
    editBox:DisableButton(true)
    editBox:SetFullWidth(true)
    editBox:SetNumLines(10)
    frame:AddChild(editBox)

    local replaceCheck = AceGUI:Create("CheckBox")
    replaceCheck:SetLabel(L["Replace my spells (reset before importing)"])
    replaceCheck:SetValue(importReplace)
    replaceCheck:SetFullWidth(true)
    replaceCheck:SetCallback("OnValueChanged", function(_, _, value) importReplace = value end)
    frame:AddChild(replaceCheck)

    local function DoImport()
        local ok, res = BigDebuffs:ImportSpellString(editBox:GetText(), importReplace)
        if ok then
            frame:SetStatusText("|cff20ff20" .. L["Imported %d custom spell(s) and %d override(s)."]
                :format(res.spells, res.overrides) .. "|r")
            editBox:SetText("")
        else
            frame:SetStatusText("|cffff2020" .. tostring(res) .. "|r")
        end
    end

    local button = AceGUI:Create("Button")
    button:SetText(L["Import"])
    button:SetFullWidth(true)
    button:SetCallback("OnClick", function()
        if importReplace then
            -- Confirm the destructive reset before wiping the profile.
            StaticPopupDialogs["BIGDEBUFFS_IMPORT_REPLACE"] = StaticPopupDialogs["BIGDEBUFFS_IMPORT_REPLACE"] or {
                text = L["This will remove all your current custom spells and overrides, then import the shared set. Continue?"],
                button1 = ACCEPT,
                button2 = CANCEL,
                timeout = 0,
                whileDead = true,
                hideOnEscape = true,
                preferredIndex = 3,
            }
            StaticPopupDialogs["BIGDEBUFFS_IMPORT_REPLACE"].OnAccept = DoImport
            StaticPopup_Show("BIGDEBUFFS_IMPORT_REPLACE")
        else
            DoImport()
        end
    end)
    frame:AddChild(button)
end

function BigDebuffs:GetImportExportOptions()
    return {
        name = L["Import / Export"],
        type = "group",
        order = 101,
        args = {
            exportHeader = {
                order = 1,
                type = "header",
                name = L["Export"],
            },
            exportDesc = {
                order = 2,
                type = "description",
                name = L["Share your spells and preset changes with others. Click Export for a copy/paste string."] .. "\n",
            },
            includeSettings = {
                order = 3,
                type = "toggle",
                width = "full",
                name = L["Include settings (visibility, priority and size)"],
                get = function() return exportIncludeSettings end,
                set = function(_, value) exportIncludeSettings = value end,
            },
            exportButton = {
                order = 4,
                type = "execute",
                name = L["Export"],
                disabled = function()
                    return BigDebuffs:ExportSpellString(exportIncludeSettings) == nil
                end,
                func = ShowExportWindow,
            },
            importHeader = {
                order = 10,
                type = "header",
                name = L["Import"],
            },
            importDesc = {
                order = 11,
                type = "description",
                name = L["Load spells shared by another player. Click Import to paste a string."] .. "\n",
            },
            importButton = {
                order = 12,
                type = "execute",
                name = L["Import"],
                func = ShowImportWindow,
            },
        },
    }
end
