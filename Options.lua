local BigDebuffs = LibStub("AceAddon-3.0"):GetAddon("BigDebuffs")
local L = LibStub("AceLocale-3.0"):GetLocale("BigDebuffs")
local LibSharedMedia = LibStub("LibSharedMedia-3.0")
local GetSpellTexture = C_Spell and C_Spell.GetSpellTexture or GetSpellTexture
local GetSpellInfo = C_Spell and C_Spell.GetSpellInfo or GetSpellInfo
local GetAddOnMetadata = C_AddOns.GetAddOnMetadata

local function GetSpellName(id)
    if C_Spell and C_Spell.GetSpellName then
        return C_Spell.GetSpellName(id)
    else
        return GetSpellInfo(id)
    end
end

-- A trimmed EditBox widget with no confirm ("okay") button. Stock AceGUI
-- EditBoxes only commit their value (and trigger a full options panel
-- rebuild) when Enter is pressed or the checkmark is clicked; anything typed
-- but not yet confirmed is lost the moment a sibling widget (e.g. a select
-- dropdown) triggers that rebuild. This widget instead calls the option's
-- `set` directly on every keystroke, so the backing value is always current
-- and no explicit confirmation step is needed.
do
    local AceGUI = LibStub("AceGUI-3.0")
    local WidgetType = "BigDebuffsLiveEditBox"
    if not AceGUI:GetWidgetVersion(WidgetType) then
        local function Control_OnEnter(frame) frame.obj:Fire("OnEnter") end
        local function Control_OnLeave(frame) frame.obj:Fire("OnLeave") end
        local function EditBox_OnEscapePressed(frame) AceGUI:ClearFocus() end
        local function EditBox_OnEnterPressed(frame)
            local self = frame.obj
            self:Fire("OnEnterPressed", frame:GetText())
        end
        local function EditBox_OnFocusGained(frame) AceGUI:SetFocus(frame.obj) end

        local function EditBox_OnTextChanged(frame)
            local self = frame.obj
            local value = frame:GetText()
            if tostring(value) ~= tostring(self.lasttext) then
                self.lasttext = value
                self:Fire("OnTextChanged", value)
                -- Commit immediately, bypassing AceConfigDialog's Enter-only
                -- ActivateControl path so no full panel rebuild happens
                -- while typing (which would steal keyboard focus).
                local user = self:GetUserDataTable()
                local option = user and user.option
                if option and type(option.set) == "function" then
                    option.set(nil, value)
                end
            end
        end

        local methods = {
            ["OnAcquire"] = function(self)
                self:SetWidth(200)
                self:SetDisabled(false)
                self:SetLabel()
                self:SetText()
                self:SetMaxLetters(0)
            end,
            ["OnRelease"] = function(self) self:ClearFocus() end,
            ["SetDisabled"] = function(self, disabled)
                self.disabled = disabled
                if disabled then
                    self.editbox:EnableMouse(false)
                    self.editbox:ClearFocus()
                    self.editbox:SetTextColor(0.5, 0.5, 0.5)
                    self.label:SetTextColor(0.5, 0.5, 0.5)
                else
                    self.editbox:EnableMouse(true)
                    self.editbox:SetTextColor(1, 1, 1)
                    self.label:SetTextColor(1, .82, 0)
                end
            end,
            ["SetText"] = function(self, text)
                self.lasttext = text or ""
                self.editbox:SetText(text or "")
                self.editbox:SetCursorPosition(0)
            end,
            ["GetText"] = function(self) return self.editbox:GetText() end,
            ["SetLabel"] = function(self, text)
                if text and text ~= "" then
                    self.label:SetText(text)
                    self.label:Show()
                    self.editbox:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 7, -18)
                    self:SetHeight(44)
                    self.alignoffset = 30
                else
                    self.label:SetText("")
                    self.label:Hide()
                    self.editbox:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 7, 0)
                    self:SetHeight(26)
                    self.alignoffset = 12
                end
            end,
            ["SetMaxLetters"] = function(self, num) self.editbox:SetMaxLetters(num or 0) end,
            ["ClearFocus"] = function(self)
                self.editbox:ClearFocus()
                self.frame:SetScript("OnShow", nil)
            end,
            ["SetFocus"] = function(self) self.editbox:SetFocus() end,
            ["HighlightText"] = function(self, from, to) self.editbox:HighlightText(from, to) end,
        }

        local function Constructor()
            local num = AceGUI:GetNextWidgetNum(WidgetType)
            local frame = CreateFrame("Frame", nil, UIParent)
            frame:Hide()

            local editbox = CreateFrame("EditBox", "AceGUI-3.0"..WidgetType..num, frame, "InputBoxTemplate")
            editbox:SetAutoFocus(false)
            editbox:SetFontObject(ChatFontNormal)
            editbox:SetScript("OnEnter", Control_OnEnter)
            editbox:SetScript("OnLeave", Control_OnLeave)
            editbox:SetScript("OnEscapePressed", EditBox_OnEscapePressed)
            editbox:SetScript("OnEnterPressed", EditBox_OnEnterPressed)
            editbox:SetScript("OnTextChanged", EditBox_OnTextChanged)
            editbox:SetScript("OnEditFocusGained", EditBox_OnFocusGained)
            editbox:SetTextInsets(0, 0, 3, 3)
            editbox:SetMaxLetters(256)
            editbox:SetPoint("BOTTOMLEFT", 6, 0)
            editbox:SetPoint("BOTTOMRIGHT")
            editbox:SetHeight(19)

            local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            label:SetPoint("TOPLEFT", 0, -2)
            label:SetPoint("TOPRIGHT", 0, -2)
            label:SetJustifyH("LEFT")
            label:SetHeight(18)

            local widget = {
                editbox = editbox,
                label = label,
                frame = frame,
                type = WidgetType,
            }
            for method, func in pairs(methods) do
                widget[method] = func
            end
            editbox.obj = widget

            return AceGUI:RegisterAsWidget(widget)
        end

        AceGUI:RegisterWidgetType(WidgetType, Constructor, 1)
    end
end

-- A Button that reserves the same header space a labeled EditBox/Dropdown
-- does (and shares their alignoffset), so it lines up with the input row
-- instead of sitting higher, centred on its own shorter, label-less height.
do
    local AceGUI = LibStub("AceGUI-3.0")
    local WidgetType = "BigDebuffsAlignedButton"
    if not AceGUI:GetWidgetVersion(WidgetType) then
        local function Button_OnClick(frame, ...)
            AceGUI:ClearFocus()
            PlaySound(852) -- SOUNDKIT.IG_MAINMENU_OPTION
            frame.obj:Fire("OnClick", ...)
        end
        local function Control_OnEnter(frame) frame.obj:Fire("OnEnter") end
        local function Control_OnLeave(frame) frame.obj:Fire("OnLeave") end

        local methods = {
            ["OnAcquire"] = function(self)
                self:SetWidth(200)
                self:SetHeight(44)
                self:SetDisabled(false)
                self:SetText()
            end,
            ["SetText"] = function(self, text) self.text:SetText(text) end,
            ["SetDisabled"] = function(self, disabled)
                self.disabled = disabled
                if disabled then self.button:Disable() else self.button:Enable() end
            end,
        }

        local function Constructor()
            local num = AceGUI:GetNextWidgetNum(WidgetType)
            local frame = CreateFrame("Frame", nil, UIParent)
            frame:Hide()

            local button = CreateFrame("Button", "AceGUI30"..WidgetType..num, frame, "UIPanelButtonTemplate")
            button:EnableMouse(true)
            button:SetScript("OnClick", Button_OnClick)
            button:SetScript("OnEnter", Control_OnEnter)
            button:SetScript("OnLeave", Control_OnLeave)
            button:SetPoint("BOTTOMLEFT", 0, 0)
            button:SetPoint("BOTTOMRIGHT", 0, 0)
            button:SetHeight(19)

            local text = button:GetFontString()
            text:ClearAllPoints()
            text:SetPoint("TOPLEFT", 15, -1)
            text:SetPoint("BOTTOMRIGHT", -15, 1)
            text:SetJustifyV("MIDDLE")

            local widget = {
                button = button,
                text = text,
                frame = frame,
                alignoffset = 30, -- matches the labeled EditBox/Dropdown offset
                type = WidgetType,
            }
            for method, func in pairs(methods) do
                widget[method] = func
            end
            button.obj = widget

            return AceGUI:RegisterAsWidget(widget)
        end

        AceGUI:RegisterWidgetType(WidgetType, Constructor, 1)
    end
end

-- A full-width, globally named status line. Explains live (as the user types
-- a Spell ID) why the Add Spell button is disabled - e.g. that the ID is
-- already tracked - instead of leaving a greyed-out button with no reason.
do
    local AceGUI = LibStub("AceGUI-3.0")
    local WidgetType = "BigDebuffsStatusLabel"
    if not AceGUI:GetWidgetVersion(WidgetType) then
        local methods = {
            ["OnAcquire"] = function(self)
                self:SetHeight(18)
                self:SetText("")
            end,
            ["SetText"] = function(self, text) self.fontstring:SetText(text or "") end,
            -- AceConfigDialog calls this on every render after creation, which
            -- would otherwise reset the fontstring to its font object's default
            -- (white) colour - reapply the warning colour each time.
            ["SetFontObject"] = function(self, font)
                self.fontstring:SetFontObject(font)
                self.fontstring:SetTextColor(1, 0.5, 0.2)
            end,
        }

        local function Constructor()
            local num = AceGUI:GetNextWidgetNum(WidgetType)
            local frame = CreateFrame("Frame", "AceGUI30"..WidgetType..num, UIParent)
            frame:Hide()

            local fontstring = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            fontstring:SetPoint("TOPLEFT", 4, 0)
            fontstring:SetPoint("TOPRIGHT", -4, 0)
            fontstring:SetJustifyH("LEFT")
            fontstring:SetTextColor(1, 0.5, 0.2)

            local widget = {
                fontstring = fontstring,
                frame = frame,
                type = WidgetType,
            }
            for method, func in pairs(methods) do
                widget[method] = func
            end

            return AceGUI:RegisterAsWidget(widget)
        end

        AceGUI:RegisterWidgetType(WidgetType, Constructor, 1)
    end
end

local WarningDebuffs = {}
if WOW_PROJECT_ID ~= WOW_PROJECT_CLASSIC then
    for i = 1, #BigDebuffs.WarningDebuffs do
        local id = BigDebuffs.WarningDebuffs[i]
        local name = GetSpellName(id)
        if name then
            WarningDebuffs[name] = {
                type = "toggle",
                get = function(info) local key = info[#info-2] return BigDebuffs.db.profile[key].warningList[id] end,
                set = function(info, value)
                    local key = info[#info-2]
                    BigDebuffs.db.profile[key].warningList[id] = value BigDebuffs:Refresh()
                end,
                name = name,
                desc = function()
                    local s = Spell:CreateFromSpellID(id)
                    local spellDesc = s:GetSpellDescription() or ""
                    local extra =
                    "\n\n|cffffd700"..L["Spell ID"].."|r "..id..
                    "\n------------------\n"..
                    L["Show this debuff if present while BigDebuffs are displayed"]
                    return spellDesc..extra
                end,
            }
        end
    end
end

local order = {
    immunities = 1,
    immunities_spells = 2,
    cc = 3,
    buffs_defensive = 4,
    buffs_offensive = 5,
    debuffs_offensive = 6,
    buffs_other = 7,
    roots = 8,
    buffs_speed_boost = 9,
}
local SpellNames = {}
local SpellIcons = {}

-- Categories offered in the category dropdown (localized), in display order
local categorySorting = {
    "immunities", "immunities_spells", "cc", "interrupts",
    "buffs_defensive", "buffs_offensive", "debuffs_offensive",
    "buffs_other", "roots", "buffs_speed_boost",
}
local categoryValues = {}
for _, key in ipairs(categorySorting) do categoryValues[key] = L[key] end

-- Preset spells that other spells link to as a parent (shared ranks) must not
-- be re-mapped to a different ID, or their children would be orphaned.
local parentIDs = {}
for _, s in pairs(BigDebuffs.BaseSpells) do
    if s.parent then parentIDs[s.parent] = true end
end

-- Build the options card for a single spell (preset or custom). The card is
-- keyed by spellID and reads its effective category from BigDebuffs.Spells so
-- category overrides and custom spells are reflected the moment they change.
local function BuildSpellCard(spellID, spell, isCustom)
        local raidFrames = spell.type == "cc" or
            spell.type == "roots" or
            spell.type == "special" or
            spell.type == "interrupts" or
            spell.type == "debuffs_offensive"
        return {
            type = "group",
            get = function(info)
                local name = info[#info]
                return BigDebuffs.db.profile.spells[spellID] and BigDebuffs.db.profile.spells[spellID][name]
            end,
            set = function(info, value)
                local name = info[#info]
                BigDebuffs.db.profile.spells[spellID] = BigDebuffs.db.profile.spells[spellID] or {}
                BigDebuffs.db.profile.spells[spellID][name] = value
                BigDebuffs:Refresh()
            end,
            name = function(info)
                local name = SpellNames[spellID] or GetSpellName(spellID)
                SpellNames[spellID] = name
                return name
            end,
            icon = function()
                local icon = SpellIcons[spellID] or GetSpellTexture(spellID)
                SpellIcons[spellID] = icon
                return icon
            end,
            desc = function()
                local s = Spell:CreateFromSpellID(spellID)
                local spellDesc = s:GetSpellDescription() or ""
                local extra = "\n\n|cffffd700"..L["Spell ID"].."|r "..spellID
                return spellDesc..extra
            end,
            args = {
                spellId = {
                    order = 0,
                    type = "input",
                    name = L["Spell ID"],
                    desc = function()
                        local s = BigDebuffs.Spells[spellID]
                        if s and s.replacedFrom then
                            local baseName = GetSpellName(s.replacedFrom) or "?"
                            return L["Replaces preset"]..": "..baseName.." ("..s.replacedFrom..")"
                                .."\n\n"..L["Change the spell ID this entry tracks (enter the original ID to reset)"]
                        end
                        return L["Change the spell ID this entry tracks (enter the original ID to reset)"]
                    end,
                    width = "relative",
                    relWidth = 0.5,
                    disabled = function()
                        if isCustom then return false end
                        local s = BigDebuffs.Spells[spellID]
                        local baseKey = (s and s.replacedFrom) or spellID
                        return parentIDs[baseKey] and true or false
                    end,
                    get = function() return tostring(spellID) end,
                    validate = function(_, value)
                        local n = tonumber(value)
                        if not n then return L["Please enter a number"] end
                        if not GetSpellName(n) then return L["No spell exists with that ID"] end
                        if n ~= spellID and BigDebuffs.Spells[n] then return L["That spell is already tracked"] end
                        return true
                    end,
                    set = function(_, value)
                        local newID = tonumber(value)
                        if not newID or newID == spellID then return end
                        local sp = BigDebuffs.db.profile.spells
                        if isCustom then
                            local cs = BigDebuffs.db.profile.customSpells
                            cs[newID] = cs[spellID]
                            cs[spellID] = nil
                        else
                            local s = BigDebuffs.Spells[spellID]
                            local baseID = (s and s.replacedFrom) or spellID
                            local repl = BigDebuffs.db.profile.spellReplacements
                            if newID == baseID then
                                repl[baseID] = nil
                            else
                                repl[baseID] = newID
                            end
                        end
                        -- Move per-spell overrides to the new effective ID
                        if sp[spellID] then
                            sp[newID] = sp[spellID]
                            sp[spellID] = nil
                        end
                        BigDebuffs:BuildSpellList()
                        BigDebuffs:RefreshSpellOptions()
                        BigDebuffs:Refresh()
                    end,
                },
                category = {
                    order = 1,
                    type = "select",
                    name = L["Category"],
                    desc = L["Change which category this spell belongs to"],
                    width = "relative",
                    relWidth = 0.5,
                    values = categoryValues,
                    sorting = categorySorting,
                    get = function()
                        local s = BigDebuffs.Spells[spellID]
                        return s and s.type
                    end,
                    set = function(_, value)
                        if isCustom then
                            local c = BigDebuffs.db.profile.customSpells
                            c[spellID] = c[spellID] or {}
                            c[spellID].type = value
                        else
                            local ov = BigDebuffs.db.profile.spells
                            ov[spellID] = ov[spellID] or {}
                            local base = BigDebuffs.BaseSpells[spellID]
                            if base and base.type == value then
                                ov[spellID].type = nil
                            else
                                ov[spellID].type = value
                            end
                        end
                        BigDebuffs:BuildSpellList()
                        BigDebuffs:RefreshSpellOptions()
                        BigDebuffs:Refresh()
                    end,
                },
                visibility = {
                    order = 2,
                    type = "group",
                    name = L["Visibility"],
                    inline = true,
                    get = function(info)
                        local name = info[#info]
                        local value = (BigDebuffs.db.profile.spells[spellID] and
                            BigDebuffs.db.profile.spells[spellID][name]) or
                            (not BigDebuffs.Spells[spellID]["no"..name] and 1)
                        return value and value == 1
                    end,
                    set = function(info, value)
                        local name = info[#info]
                        BigDebuffs.db.profile.spells[spellID] = BigDebuffs.db.profile.spells[spellID] or {}
                        value = value and 1 or 0
                        BigDebuffs.db.profile.spells[spellID][name] = value

                        -- unset if default visibility
                        local no = BigDebuffs.Spells[spellID]["no"..name]
                        if (value == 1 and not no) or
                            (value == 0 and no) then
                            BigDebuffs.db.profile.spells[spellID][name] = nil
                        end
                        BigDebuffs:Refresh()
                    end,
                    args = {
                        raidFrames = raidFrames and {
                            type = "toggle",
                            name = L["Raid Frames"],
                            desc = L["Show this spell on the raid frames"],
                            width = "full",
                            order = 1,
                        } or nil,
                        unitFrames = {
                            type = "toggle",
                            name = L["Unit Frames"],
                            desc = L["Show this spell on the unit frames"],
                            width = "full",
                            order = 2
                        },
						nameplates = {
                            type = "toggle",
                            name = "Nameplates",
                            desc = L["Show this spell on nameplates"],
                            width = "full",
                            order = 3
                        },
                    },
                },
                priority = {
                    type = "group",
                    inline = true,
                    name = L["Priority"],
                    args = {
                        customPriority = {
                            name = L["Custom Priority"],
                            type = "toggle",
                            order = 2,
                            set = function(info, value)
                                BigDebuffs.db.profile.spells[spellID] = BigDebuffs.db.profile.spells[spellID] or {}
                                BigDebuffs.db.profile.spells[spellID].customPriority = value
                                if not value then
                                    BigDebuffs.db.profile.spells[spellID].priority = nil
                                end
                                BigDebuffs:Refresh()
                            end,
                        },
                        priority = {
                            name = L["Priority"],
                            desc = L["Higher priority spells will take precedence regardless of duration"],
                            type = "range",
                            min = 1,
                            max = 100,
                            step = 1,
                            order = 3,
                            disabled = function()
                                return not BigDebuffs.db.profile.spells[spellID] or
                                not BigDebuffs.db.profile.spells[spellID].customPriority
                            end,
                            get = function(info)
                                -- Pull the category priority
                                return BigDebuffs.db.profile.spells[spellID] and
                                    BigDebuffs.db.profile.spells[spellID].priority and
                                    BigDebuffs.db.profile.spells[spellID].priority or
                                    BigDebuffs.db.profile.priority[spell.type]
                            end,
                        },
                    },
                },

                size = raidFrames and {
                    name = L["Size"],
                    type = "group",
                    inline = true,
                    args = {
                        customSize = {
                            name = L["Custom Size"],
                            type = "toggle",
                            order = 4,
                            set = function(info, value)
                                local name = info[#info]
                                BigDebuffs.db.profile.spells[spellID] = BigDebuffs.db.profile.spells[spellID] or {}
                                BigDebuffs.db.profile.spells[spellID].customSize = value
                                if not value then
                                    BigDebuffs.db.profile.spells[spellID].size = nil
                                end
                                BigDebuffs:Refresh()
                            end,
                        },
                        size = {
                            type = "range",
                            isPercent = true,
                            name = L["Size"],
                            desc = L["Set the custom size of this spell"],
                            get = function(info)
                                -- Pull the category size
                                return BigDebuffs.db.profile.spells[spellID] and
                                    BigDebuffs.db.profile.spells[spellID].size and
                                    BigDebuffs.db.profile.spells[spellID].size/100 or
                                    BigDebuffs.db.profile.raidFrames[string.lower(spell.type)]/100
                            end,
                            set = function(info, value)
                                local name = info[#info]
                                BigDebuffs.db.profile.spells[spellID] = BigDebuffs.db.profile.spells[spellID] or {}
                                BigDebuffs.db.profile.spells[spellID][name] = value*100
                                BigDebuffs:Refresh()
                            end,
                            disabled = function() return not BigDebuffs.db.profile.spells[spellID] or
                                not BigDebuffs.db.profile.spells[spellID].customSize end,
                            min = 0,
                            max = 1,
                            step = 0.01,
                            order = 5,
                        },
                    },
                } or nil,
                duration = isCustom and {
                    order = 6,
                    type = "input",
                    name = L["Duration"],
                    desc = L["Override the icon timer duration in seconds (leave empty to use the spell default)"],
                    get = function()
                        local c = BigDebuffs.db.profile.customSpells[spellID]
                        return (c and c.duration) and tostring(c.duration) or ""
                    end,
                    set = function(_, value)
                        local c = BigDebuffs.db.profile.customSpells[spellID]
                        if c then
                            local n = tonumber(value)
                            c.duration = (n and n > 0) and n or nil
                        end
                        BigDebuffs:BuildSpellList()
                        BigDebuffs:Refresh()
                    end,
                    validate = function(_, value)
                        if value == "" or tonumber(value) then return true end
                        return L["Please enter a number"]
                    end,
                } or nil,
                remove = isCustom and {
                    order = 7,
                    type = "execute",
                    name = L["Remove Spell"],
                    desc = L["Remove this custom spell"],
                    width = "full",
                    confirm = true,
                    func = function()
                        BigDebuffs.db.profile.customSpells[spellID] = nil
                        BigDebuffs.db.profile.spells[spellID] = nil
                        BigDebuffs:BuildSpellList()
                        BigDebuffs:RefreshSpellOptions()
                        BigDebuffs:Refresh()
                    end,
                } or nil,
            },
        }
end

-- Pending values for the "add custom spell" form
local pendingID
local pendingType = "cc"

-- Returns nil if the pending ID can be added, or an explanatory message if
-- not (blank field, no such spell, or already tracked - and where).
local function GetPendingSpellIssue()
    if not pendingID then return nil end
    if not GetSpellName(pendingID) then
        return L["No spell exists with that ID"]
    end
    local existing = BigDebuffs.Spells[pendingID]
    if existing then
        local catName = L[existing.type] or existing.type
        return L["Already tracked"].." ("..catName.."). "..L["Edit its category card above instead of adding it again."]
    end
    return nil
end

local function IsPendingSpellValid()
    return pendingID ~= nil and GetPendingSpellIssue() == nil
end

-- The currently rendered "Add Spell" exec option and status label (rebuilt
-- fresh by BuildSpellOptions on every panel refresh), kept so
-- SyncAddSpellForm can find the matching live widgets below.
local currentAddExecOption
local currentAddStatusOption

-- The Spell ID field commits on every keystroke without forcing a panel
-- refresh (see BigDebuffsLiveEditBox above), so the Add Spell button's
-- disabled state and the status message - normally only re-checked on a
-- full redraw - would go stale while typing. Update them directly on the
-- live widgets instead.
local function SyncAddSpellForm()
    local issue = GetPendingSpellIssue()
    local disabled = pendingID == nil or issue ~= nil
    local AceGUI = LibStub("AceGUI-3.0")

    if currentAddExecOption then
        for i = 1, AceGUI:GetWidgetCount("BigDebuffsAlignedButton") do
            local frame = _G["AceGUI30BigDebuffsAlignedButton"..i]
            if frame and frame.obj and frame:IsVisible() then
                local user = frame.obj:GetUserDataTable()
                if user and user.option == currentAddExecOption then
                    frame.obj:SetDisabled(disabled)
                end
            end
        end
    end

    if currentAddStatusOption then
        for i = 1, AceGUI:GetWidgetCount("BigDebuffsStatusLabel") do
            local frame = _G["AceGUI30BigDebuffsStatusLabel"..i]
            if frame and frame.obj and frame:IsVisible() then
                local user = frame.obj:GetUserDataTable()
                if user and user.option == currentAddStatusOption then
                    frame.obj:SetText(issue)
                end
            end
        end
    end
end

-- Tracks whether the Custom Spells tab title is currently drawn highlighted
-- (green) so the tab bar can be refreshed when the selection changes
-- (see the tab colour sync below)
local customTabHighlighted = true
local tabSyncPending = false

-- Assemble the whole Spells tab: presets grouped by their (effective) category,
-- plus a Custom Spells page for adding, editing and removing user spells.
function BigDebuffs:BuildSpellOptions()
    local groups = {}

    for spellID, spell in pairs(BigDebuffs.Spells) do
        if not spell.parent and not spell.custom then
            local t = spell.type
            groups[t] = groups[t] or {
                name = L[t] or t,
                type = "group",
                order = order[t] or 50,
                args = {},
            }
            groups[t].args["spell"..spellID] = BuildSpellCard(spellID, spell, false)
        end
    end

    local custom = {
        name = function()
            local status = LibStub("AceConfigDialog-3.0"):GetStatusTable("BigDebuffs", { "spells" })
            local selected = status and status.groups and status.groups.selected
            customTabHighlighted = selected ~= "custom"
            if customTabHighlighted then
                return "|cff20ff20"..L["Custom Spells"].."|r"
            end
            return L["Custom Spells"]
        end,
        type = "group",
        order = 100,
        args = {
            add = {
                order = 1,
                type = "group",
                inline = true,
                name = L["Add Custom Spell"],
                args = {
                    desc = {
                        order = 0,
                        type = "description",
                        name = L["Add a spell by its ID and assign it a category. Use this to track debuffs the presets are missing."].."\n",
                    },
                    id = {
                        order = 1,
                        type = "input",
                        dialogControl = "BigDebuffsLiveEditBox",
                        name = L["Spell ID"],
                        get = function() return pendingID and tostring(pendingID) or "" end,
                        set = function(_, value)
                            pendingID = tonumber(value)
                            SyncAddSpellForm()
                        end,
                        validate = function(_, value)
                            local n = tonumber(value)
                            if not n then return L["Please enter a number"] end
                            if not GetSpellName(n) then return L["No spell exists with that ID"] end
                            if BigDebuffs.Spells[n] then return L["That spell is already tracked"] end
                            return true
                        end,
                    },
                    category = {
                        order = 2,
                        type = "select",
                        name = L["Category"],
                        values = categoryValues,
                        sorting = categorySorting,
                        get = function() return pendingType end,
                        set = function(_, value) pendingType = value end,
                    },
                    exec = {
                        order = 3,
                        type = "execute",
                        dialogControl = "BigDebuffsAlignedButton",
                        name = L["Add Spell"],
                        disabled = function() return not IsPendingSpellValid() end,
                        func = function()
                            if not IsPendingSpellValid() then return end
                            BigDebuffs.db.profile.customSpells[pendingID] = { type = pendingType or "cc" }
                            pendingID = nil
                            BigDebuffs:BuildSpellList()
                            BigDebuffs:RefreshSpellOptions()
                            BigDebuffs:Refresh()
                        end,
                    },
                    status = {
                        order = 4,
                        type = "description",
                        dialogControl = "BigDebuffsStatusLabel",
                        name = function() return GetPendingSpellIssue() or "" end,
                    },
                },
            },
            noneDesc = {
                order = 2,
                type = "description",
                name = L["No custom spells added yet."],
                hidden = function() return next(BigDebuffs.db.profile.customSpells) ~= nil end,
            },
        },
    }
    currentAddExecOption = custom.args.add.args.exec
    currentAddStatusOption = custom.args.add.args.status

    for spellID in pairs(BigDebuffs.db.profile.customSpells) do
        local spell = BigDebuffs.Spells[spellID]
        if spell then
            custom.args["custom"..spellID] = BuildSpellCard(spellID, spell, true)
        end
    end

    groups.custom = custom

    -- Keep the Custom Spells tab title highlighted while it is not the active
    -- sub-tab. The tab bar is only rebuilt on a full panel refresh, not when a
    -- sub-tab is clicked, so every sub-tab carries a hidden checker that requests
    -- a refresh when the drawn colour no longer matches the current selection.
    for key, group in pairs(groups) do
        group.args._tabColorSync = {
            order = -1000,
            type = "description",
            name = "",
            hidden = function()
                local shouldHighlight = key ~= "custom"
                if customTabHighlighted ~= shouldHighlight and not tabSyncPending then
                    tabSyncPending = true
                    C_Timer.After(0, function()
                        tabSyncPending = false
                        LibStub("AceConfigRegistry-3.0"):NotifyChange("BigDebuffs")
                    end)
                end
                return true
            end,
        }
    end

    return groups
end

-- Rebuild the Spells tab in place and refresh the open panel
function BigDebuffs:RefreshSpellOptions()
    if not self.options then return end
    self.options.args.spells.args = self:BuildSpellOptions()
    LibStub("AceConfigRegistry-3.0"):NotifyChange("BigDebuffs")
end

function BigDebuffs:SetupOptions()
    self.options = {
        name = "BigDebuffs",
        descStyle = "inline",
        type = "group",
        plugins = {},
        childGroups = "tab",
        args = {
            vers = {
                order = 1,
                type = "description",
                name = "|cffffd700"..L["Version"].."|r "..GetAddOnMetadata("BigDebuffs", "Version").."\n",
                cmdHidden = true
            },
            desc = {
                order = 2,
                type = "description",
                name = "|cffffd700 "..L["Author"].."|r Jordon\n",
                cmdHidden = true
            },
            test = {
                type = "execute",
                name = L["Toggle Test Mode"],
                order = 3,
                func = "Test",
                handler = BigDebuffs,
            },
            raidFrames = {
                name = L["Raid Frames"],
                type = "group",
                disabled = function(info) return info[2] and not self.db.profile[info[1]].enabled end,
                order = 10,
                get = function(info) local name = info[#info] return self.db.profile.raidFrames[name] end,
                set = function(info, value)
                    local name = info[#info]
                    self.db.profile.raidFrames[name] = value
                    self:Refresh()
                end,
                args = {
                    enabled = {
                        type = "toggle",
                        width = "normal",
                        disabled = false,
                        name = L["Enabled"],
                        desc = L["Enable BigDebuffs on raid frames"],
                        order = 1,
                    },
                    hideBliz = {
                        type = "toggle",
                        width = "normal",
                        name = L["Hide Other Debuffs"],
                        hidden = function() return WOW_PROJECT_ID == WOW_PROJECT_MAINLINE end,
                        set = function(info, value)
                            if value then
                                self.db.profile.raidFrames.redirectBliz = false
                            end
                            self.db.profile.raidFrames.hideBliz = value
                            self:Refresh()
                        end,
                        desc = L["Hides other debuffs when BigDebuffs are displayed"],
                        order = 2,
                    },
                    redirectBliz = {
                        type = "toggle",
                        width = "normal",
                        name = L["Redirect Other Debuffs"],
                        hidden = function() return WOW_PROJECT_ID == WOW_PROJECT_MAINLINE end,
                        set = function(info, value)
                            if value then
                                self.db.profile.raidFrames.hideBliz = false
                            end
                            self.db.profile.raidFrames.redirectBliz = value
                            self:Refresh()
                        end,
                        desc = L["Redirects other debuffs to the BigDebuffs anchor"],
                        order = 3,
                    },
                    showAllClassBuffs = {
                        type = "toggle",
                        width = "normal",
                        name = L["Show All Class Buffs"],
                        desc = L["Show all the buffs our class can apply"],
                        hidden = function() return WOW_PROJECT_ID == WOW_PROJECT_MAINLINE end,
                        order = 4,
                    },
                    increaseBuffs = {
                        type = "toggle",
                        width = "normal",
                        name = L["Increase Maximum Buffs"],
                        desc = L["Sets the maximum buffs to 6"],
                        hidden = function() return WOW_PROJECT_ID == WOW_PROJECT_MAINLINE end,
                        order = 5,
                    },
                    cooldownCount = {
                        type = "toggle",
                        width = "normal",
                        name = L["Cooldown Count"],
                        desc = L["Allow Blizzard and other addons to display countdown text on the icons"],
                        order = 6,
                    },
                    cooldownFont = {
                        type = "select",
                        name = L["Font"],
                        desc = L["Select font for cd timers"],
                        order = 7,
                        values = function()
                            local fonts, newFonts = LibSharedMedia:List("font"), {}
                            for k, v in pairs(fonts) do
                                newFonts[v] = v
                            end
                            return newFonts
                        end,
                    },
                    cooldownFontSize = {
                        type = "range",
                        name = L["Font Size"],
                        desc = L["Set the cd timers font size"],
                        min = 1,
                        max = 30,
                        step = 1,
                        order = 8,
                    },
                    cooldownFontEffect = {
                        type = "select",
                        name = L["Font Effect"],
                        desc = L["Set the cd timers font effect"],
                        values = {
                            ["MONOCHROME"] = "MONOCHROME",
                            ["OUTLINE"] = "OUTLINE",
                            ["THICKOUTLINE"] = "THICKOUTLINE",
                            [""] = "NONE",
                        },
                        order = 9,
                    },
                    maxDebuffs = {
                        type = "range",
                        name = L["Max Debuffs"],
                        desc = L["Set the maximum number of debuffs displayed"],
                        min = 1,
                        max = 20,
                        step = 1,
                        order = 10,
                    },
                    wrapAt = {
                        type = "range",
                        name = L["Wrap After"],
                        desc = L["Begin a new row or column after this many debuffs"],
                        min = 0,
                        max = 10,
                        step = 1,
                        order = 11,
                    },
                    anchor = {
                        name = L["Anchor"],
                        desc = L["Anchor to attach the BigDebuffs frames"],
                        type = "select",
                        values = {
                            ["INNER"] = L["INNER"],
                            ["LEFT"] = L["LEFT"],
                            ["RIGHT"] = L["RIGHT"],
                            ["TOP"] = L["TOP"],
                            ["BOTTOM"] = L["BOTTOM"],
                        },
                        order = 11,
                    },
                    scale = {
                        name = L["Size"],
                        type = "group",
                        inline = true,
                        order = 20,
                        get = function(info)
                            local name = info[#info]
                            return self.db.profile.raidFrames[name]/100
                        end,
                        set = function(info, value)
                            local name = info[#info]
                            self.db.profile.raidFrames[name] = value*100
                            self:Refresh()
                        end,
                        args = {
                            dispellable = {
                                type = "range",
                                isPercent = true,
                                name = L["Dispellable CC"],
                                desc = L["Set the size of dispellable crowd control debuffs"],
                                hidden = function() return WOW_PROJECT_ID == WOW_PROJECT_MAINLINE end,
                                min = 0,
                                max = 1,
                                step = 0.01,
                                order = 1,
                                get = function(info)
                                    local name = info[#info]
                                    return self.db.profile.raidFrames.dispellable.cc/100
                                end,
                                set = function(info, value)
                                    local name = info[#info]
                                    self.db.profile.raidFrames.dispellable.cc = value*100
                                    self:Refresh()
                                end,
                            },
                            cc = {
                                type = "range",
                                isPercent = true,
                                name = function() return WOW_PROJECT_ID == WOW_PROJECT_MAINLINE and L["cc"] or L["Other CC"] end,
                                desc = L["Set the size of crowd control debuffs"],
                                min = 0,
                                max = 1,
                                step = 0.01,
                                order = 2,
                            },
                            dispellableRoots = {
                                type = "range",
                                isPercent = true,
                                name = L["Dispellable Roots"],
                                desc = L["Set the size of dispellable roots"],
                                hidden = function() return WOW_PROJECT_ID == WOW_PROJECT_MAINLINE end,
                                min = 0,
                                max = 1,
                                step = 0.01,
                                order = 4,
                                get = function(info)
                                    local name = info[#info]
                                    return self.db.profile.raidFrames.dispellable.roots/100
                                end,
                                set = function(info, value)
                                    local name = info[#info]
                                    self.db.profile.raidFrames.dispellable.roots= value*100
                                    self:Refresh()
                                end,
                            },
                            roots = {
                                type = "range",
                                isPercent = true,
                                name = L["Other Roots"],
                                desc = L["Set the size of roots"],
                                hidden = function() return WOW_PROJECT_ID == WOW_PROJECT_MAINLINE end,
                                min = 0,
                                max = 1,
                                step = 0.01,
                                order = 5,
                            },
                            debuffs_offensive = {
                                type = "range",
                                isPercent = true,
                                name = L["Offensive Debuffs"],
                                desc = L["Set the size of offensive debuffs"],
                                hidden = function() return WOW_PROJECT_ID == WOW_PROJECT_MAINLINE end,
                                min = 0,
                                max = 1,
                                step = 0.01,
                                order = 7,
                            },
                            default = {
                                type = "range",
                                isPercent = true,
                                name = L["Other Debuffs"],
                                desc = L["Set the size of other debuffs"],
                                hidden = function() return WOW_PROJECT_ID == WOW_PROJECT_MAINLINE end,
                                min = 0,
                                max = 1,
                                step = 0.01,
                                order = 8,
                            },
                            pve = {
                                type = "range",
                                isPercent = true,
                                name = L["Dispellable PvE"],
                                desc = L["Set the size of dispellable PvE debuffs"],
                                hidden = function() return WOW_PROJECT_ID == WOW_PROJECT_MAINLINE end,
                                min = 0,
                                max = 1,
                                step = 0.01,
                                order = 3,
                            },
                            interrupts = {
                                type = "range",
                                isPercent = true,
                                name = L["interrupts"],
                                desc = L["Set the size of interrupts"],
                                hidden = function() return WOW_PROJECT_ID == WOW_PROJECT_MAINLINE end,
                                min = 0,
                                max = 1,
                                step = 0.01,
                                order = 9,
                            },
                            buffs = {
                                type = "range",
                                isPercent = true,
                                name = function() return WOW_PROJECT_ID == WOW_PROJECT_MAINLINE and L["buffs_defensive"] or L["buffs"] end,
                                desc = L["Set the size of buffs"],
                                min = 0,
                                max = 0.5,
                                step = 0.01,
                                order = 10,
                            },
                        },
                    },
                    inRaid = {
                        name = L["Extras"],
                        order = 40,
                        type = "group",
                        inline = true,
                        get = function(info)
                            local name = info[#info]
                            return self.db.profile.raidFrames.inRaid[name]
                        end,
                        set = function(info, value)
                            local name = info[#info]
                            self.db.profile.raidFrames.inRaid[name] = value
                            self:Refresh()
                        end,
                        args = {
                            hide = {
                                name = L["Hide in Raids"],
                                desc = L["Hide BigDebuffs in Raids"],
                                type = "toggle",
                                order = 1
                            },
                            size = {
                                type = "range",
                                disabled = function(info)
                                    local name = info[2]
                                    return not self.db.profile.raidFrames[name].hide
                                end,
                                name = L["Group Size"],
                                desc = L["Hides BigDebuffs for groups larger than group size"],
                                width = "double",
                                min = 5,
                                max = 40,
                                step = 5,
                                order = 2
                            }
                        }
                    }

                }
            },
            unitFrames = {
                name = L["Unit Frames"],
                type = "group",
                order = 20,
                disabled = function(info) return info[2] and not self.db.profile[info[1]].enabled end,
                childGroups = "tab",
                get = function(info) local name = info[#info] return self.db.profile.unitFrames[name] end,
                set = function(info, value)
                    local name = info[#info]
                    self.db.profile.unitFrames[name] = value
                    self:Refresh()
                end,
                args = {
                    enabled = {
                        type = "toggle",
                        disabled = false,
                        width = "normal",
                        name = L["Enabled"],
                        desc = L["Enable BigDebuffs on unit frames"],
                        order = 1,
                    },
                    cooldownCount = {
                        type = "toggle",
                        width = "normal",
                        name = L["Cooldown Count"],
                        desc = L["Allow Blizzard and other addons to display countdown text on the icons"],
                        order = 2,
                    },
                    tooltips = {
                        type = "toggle",
                        width = "normal",
                        name = L["Show Tooltips"],
                        desc = L["Show spell information when mousing over the icon"],
                        order = 3,
                    },
                    cooldownFont = {
                        type = "select",
                        name = L["Font"],
                        desc = L["Select font for cd timers"],
                        order = 4,
                        values = function()
                            local fonts, newFonts = LibSharedMedia:List("font"), {}
                            for k, v in pairs(fonts) do
                                newFonts[v] = v
                            end
                            return newFonts
                        end,
                    },
                    cooldownFontSize = {
                        type = "range",
                        name = L["Font Size"],
                        desc = L["Set the cd timers font size"],
                        min = 1,
                        max = 30,
                        step = 1,
                        order = 5,
                    },
                    cooldownFontEffect = {
                        type = "select",
                        name = L["Font Effect"],
                        desc = L["Set the cd timers font effect"],
                        values = {
                            ["MONOCHROME"] = "MONOCHROME",
                            ["OUTLINE"] = "OUTLINE",
                            ["THICKOUTLINE"] = "THICKOUTLINE",
                            [""] = "NONE",
                        },
                        order = 6,
                    },
                    player = {
                        type = "group",
                        disabled = function(info)
                            return not self.db.profile[info[1]].enabled or
                                (info[3] and not self.db.profile.unitFrames[info[2]].enabled)
                        end,
                        get = function(info)
                            local name = info[#info]
                            return self.db.profile.unitFrames.player[name]
                        end,
                        set = function(info, value)
                            local name = info[#info]
                            self.db.profile.unitFrames.player[name] = value
                            self:Refresh()
                        end,
                        args = {
                            enabled = {
                                type = "toggle",
                                disabled = function(info) return not self.db.profile[info[1]].enabled end,
                                name = L["Enabled"],
                                order = 1,
                                width = "full",
                                desc = L["Enable BigDebuffs on the player frame"],
                            },
                            anchor = {
                                name = L["Anchor"],
                                desc = L["Anchor to attach the BigDebuffs frames"],
                                type = "select",
                                values = {
                                    ["auto"] = L["Automatic"],
                                    ["manual"] = L["Manual"],
                                },
                                width = "normal",
                                order = 2,
                            },
                            anchorPoint = {
                                name = L["Anchor Point"],
                                desc = L["Anchor point to attach the BigDebuffs frames"],
                                type = "select",
                                disabled = function(info)
                                    local name = info[2]
                                    return not self.db.profile.unitFrames[name].enabled or self.db.profile.unitFrames[name].anchor == "manual"
                                end,
                                values = {
                                    ["auto"] = L["Automatic"],
                                    ["TOP"] = L["TOP"],
                                    ["RIGHT"] = L["RIGHT"],
                                    ["BOTTOM"] = L["BOTTOM"],
                                    ["LEFT"] = L["LEFT"],
                                    ["TOPRIGHT"] = L["TOPRIGHT"],
                                    ["TOPLEFT"] = L["TOPLEFT"],
                                    ["BOTTOMLEFT"] = L["BOTTOMLEFT"],
                                    ["BOTTOMRIGHT"] = L["BOTTOMRIGHT"],
                                    ["CENTER"] = L["CENTER"],
                                },
                                order = 3,
                            },
                            relativePoint = {
                                name = L["Relative Point"],
                                desc = L["Relative point to attach the BigDebuffs frames"],
                                type = "select",
                                disabled = function(info)
                                    local name = info[2]
                                    return not self.db.profile.unitFrames[name].enabled or self.db.profile.unitFrames[name].anchor == "manual" or
                                        self.db.profile.unitFrames[name].anchorPoint == "auto"
                                end,
                                values = {
                                    ["auto"] = L["Automatic"],
                                    ["TOP"] = L["TOP"],
                                    ["RIGHT"] = L["RIGHT"],
                                    ["BOTTOM"] = L["BOTTOM"],
                                    ["LEFT"] = L["LEFT"],
                                    ["TOPRIGHT"] = L["TOPRIGHT"],
                                    ["TOPLEFT"] = L["TOPLEFT"],
                                    ["BOTTOMLEFT"] = L["BOTTOMLEFT"],
                                    ["BOTTOMRIGHT"] = L["BOTTOMRIGHT"],
                                    ["CENTER"] = L["CENTER"],
                                },
                                order = 4,
                            },
                            x = {
                                type = "range",
                                name = L["X offset"],
                                desc = L["Set the X offset"],
                                width = 1.5,
                                min = -100,
                                max = 100,
                                step = 1,
                                disabled = function(info)
                                    local name = info[2]
                                    return not self.db.profile.unitFrames[name].enabled or self.db.profile.unitFrames[name].anchor == "manual" or
                                        self.db.profile.unitFrames[name].anchorPoint == "auto"
                                end,
                                order = 5,
                            },
                            y = {
                                type = "range",
                                name = L["Y offset"],
                                desc = L["Set the Y offset"],
                                width = 1.5,
                                min = -100,
                                max = 100,
                                step = 1,
                                disabled = function(info)
                                    local name = info[2]
                                    return not self.db.profile.unitFrames[name].enabled or self.db.profile.unitFrames[name].anchor == "manual" or
                                        self.db.profile.unitFrames[name].anchorPoint == "auto"
                                end,
                                order = 6,
                            },
                            matchFrameHeight = {
                                name = L["Match Frame Height"],
                                desc = L["Match the height of the frame"],
                                type = "toggle",
                                disabled = function(info)
                                    local name = info[2]
                                    return not self.db.profile.unitFrames[name].enabled or self.db.profile.unitFrames[name].anchor == "manual"
                                end,
                                order = 7,
                            },
                            size = {
                                type = "range",
                                disabled = function(info)
                                    local name = info[2]
                                    return not self.db.profile.unitFrames[name].enabled or
                                        (self.db.profile.unitFrames[name].anchor == "auto" and self.db.profile.unitFrames[name].matchFrameHeight)
                                end,
                                name = L["Size"],
                                width = "double",
                                desc = L["Set the size of the frame"],
                                min = 8,
                                max = 512,
                                step = 1,
                                order = 8,
                            },
                        },
                        name = L["Player Frame"],
                        order = 1,
                    },
                    target = {
                        type = "group",
                        disabled = function(info)
                            return not self.db.profile[info[1]].enabled or
                                (info[3] and not self.db.profile.unitFrames[info[2]].enabled)
                        end,
                        get = function(info)
                            local name = info[#info]
                            return self.db.profile.unitFrames.target[name]
                        end,
                        set = function(info, value)
                            local name = info[#info]
                            self.db.profile.unitFrames.target[name] = value
                            self:Refresh()
                        end,
                        args = {
                            enabled = {
                                type = "toggle",
                                disabled = function(info) return not self.db.profile[info[1]].enabled end,
                                name = L["Enabled"],
                                order = 1,
                                width = "full",
                                desc = L["Enable BigDebuffs on the target frame"],
                            },
                            anchor = {
                                name = L["Anchor"],
                                desc = L["Anchor to attach the BigDebuffs frames"],
                                type = "select",
                                values = {
                                    ["auto"] = L["Automatic"],
                                    ["manual"] = L["Manual"],
                                },
                                width = "normal",
                                order = 2,
                            },
                            anchorPoint = {
                                name = L["Anchor Point"],
                                desc = L["Anchor point to attach the BigDebuffs frames"],
                                type = "select",
                                disabled = function(info)
                                    local name = info[2]
                                    return not self.db.profile.unitFrames[name].enabled or self.db.profile.unitFrames[name].anchor == "manual"
                                end,
                                values = {
                                    ["auto"] = L["Automatic"],
                                    ["TOP"] = L["TOP"],
                                    ["RIGHT"] = L["RIGHT"],
                                    ["BOTTOM"] = L["BOTTOM"],
                                    ["LEFT"] = L["LEFT"],
                                    ["TOPRIGHT"] = L["TOPRIGHT"],
                                    ["TOPLEFT"] = L["TOPLEFT"],
                                    ["BOTTOMLEFT"] = L["BOTTOMLEFT"],
                                    ["BOTTOMRIGHT"] = L["BOTTOMRIGHT"],
                                    ["CENTER"] = L["CENTER"],
                                },
                                order = 3,
                            },
                            relativePoint = {
                                name = L["Relative Point"],
                                desc = L["Relative point to attach the BigDebuffs frames"],
                                type = "select",
                                disabled = function(info)
                                    local name = info[2]
                                    return not self.db.profile.unitFrames[name].enabled or self.db.profile.unitFrames[name].anchor == "manual" or
                                        self.db.profile.unitFrames[name].anchorPoint == "auto"
                                end,
                                values = {
                                    ["auto"] = L["Automatic"],
                                    ["TOP"] = L["TOP"],
                                    ["RIGHT"] = L["RIGHT"],
                                    ["BOTTOM"] = L["BOTTOM"],
                                    ["LEFT"] = L["LEFT"],
                                    ["TOPRIGHT"] = L["TOPRIGHT"],
                                    ["TOPLEFT"] = L["TOPLEFT"],
                                    ["BOTTOMLEFT"] = L["BOTTOMLEFT"],
                                    ["BOTTOMRIGHT"] = L["BOTTOMRIGHT"],
                                    ["CENTER"] = L["CENTER"],
                                },
                                order = 4,
                            },
                            x = {
                                type = "range",
                                name = L["X offset"],
                                desc = L["Set the X offset"],
                                width = 1.5,
                                min = -100,
                                max = 100,
                                step = 1,
                                disabled = function(info)
                                    local name = info[2]
                                    return not self.db.profile.unitFrames[name].enabled or self.db.profile.unitFrames[name].anchor == "manual" or
                                        self.db.profile.unitFrames[name].anchorPoint == "auto"
                                end,
                                order = 5,
                            },
                            y = {
                                type = "range",
                                name = L["Y offset"],
                                desc = L["Set the Y offset"],
                                width = 1.5,
                                min = -100,
                                max = 100,
                                step = 1,
                                disabled = function(info)
                                    local name = info[2]
                                    return not self.db.profile.unitFrames[name].enabled or self.db.profile.unitFrames[name].anchor == "manual" or
                                        self.db.profile.unitFrames[name].anchorPoint == "auto"
                                end,
                                order = 6,
                            },
                            matchFrameHeight = {
                                name = L["Match Frame Height"],
                                desc = L["Match the height of the frame"],
                                type = "toggle",
                                disabled = function(info)
                                    local name = info[2]
                                    return not self.db.profile.unitFrames[name].enabled or self.db.profile.unitFrames[name].anchor == "manual"
                                end,
                                order = 7,
                            },
                            size = {
                                type = "range",
                                disabled = function(info)
                                    local name = info[2]
                                    return not self.db.profile.unitFrames[name].enabled or
                                        (self.db.profile.unitFrames[name].anchor == "auto" and self.db.profile.unitFrames[name].matchFrameHeight)
                                end,
                                name = L["Size"],
                                width = "double",
                                desc = L["Set the size of the frame"],
                                min = 8,
                                max = 512,
                                step = 1,
                                order = 8,
                            },
                        },
                        name = L["Target Frame"],
                        desc = L["Enable BigDebuffs on the target frame"],
                        order = 2,
                    },
                    targettarget = {
                        type = "group",
                        disabled = function(info)
                            return not self.db.profile[info[1]].enabled or
                                (info[3] and not self.db.profile.unitFrames[info[2]].enabled)
                        end,
                        get = function(info)
                            local name = info[#info]
                            return self.db.profile.unitFrames.targettarget[name]
                        end,
                        set = function(info, value)
                            local name = info[#info]
                            self.db.profile.unitFrames.targettarget[name] = value
                            self:Refresh()
                        end,
                        args = {
                            enabled = {
                                type = "toggle",
                                disabled = function(info) return not self.db.profile[info[1]].enabled end,
                                name = L["Enabled"],
                                order = 1,
                                width = "full",
                                desc = "Enable BigDebuffs on the target of target frame",
                            },
                            anchor = {
                                name = L["Anchor"],
                                desc = L["Anchor to attach the BigDebuffs frames"],
                                type = "select",
                                values = {
                                    ["auto"] = L["Automatic"],
                                    ["manual"] = L["Manual"],
                                },
                                width = "normal",
                                order = 2,
                            },
                            anchorPoint = {
                                name = L["Anchor Point"],
                                desc = L["Anchor point to attach the BigDebuffs frames"],
                                type = "select",
                                disabled = function(info)
                                    local name = info[2]
                                    return not self.db.profile.unitFrames[name].enabled or self.db.profile.unitFrames[name].anchor == "manual"
                                end,
                                values = {
                                    ["auto"] = L["Automatic"],
                                    ["TOP"] = L["TOP"],
                                    ["RIGHT"] = L["RIGHT"],
                                    ["BOTTOM"] = L["BOTTOM"],
                                    ["LEFT"] = L["LEFT"],
                                    ["TOPRIGHT"] = L["TOPRIGHT"],
                                    ["TOPLEFT"] = L["TOPLEFT"],
                                    ["BOTTOMLEFT"] = L["BOTTOMLEFT"],
                                    ["BOTTOMRIGHT"] = L["BOTTOMRIGHT"],
                                    ["CENTER"] = L["CENTER"],
                                },
                                order = 3,
                            },
                            relativePoint = {
                                name = L["Relative Point"],
                                desc = L["Relative point to attach the BigDebuffs frames"],
                                type = "select",
                                disabled = function(info)
                                    local name = info[2]
                                    return not self.db.profile.unitFrames[name].enabled or self.db.profile.unitFrames[name].anchor == "manual" or
                                        self.db.profile.unitFrames[name].anchorPoint == "auto"
                                end,
                                values = {
                                    ["auto"] = L["Automatic"],
                                    ["TOP"] = L["TOP"],
                                    ["RIGHT"] = L["RIGHT"],
                                    ["BOTTOM"] = L["BOTTOM"],
                                    ["LEFT"] = L["LEFT"],
                                    ["TOPRIGHT"] = L["TOPRIGHT"],
                                    ["TOPLEFT"] = L["TOPLEFT"],
                                    ["BOTTOMLEFT"] = L["BOTTOMLEFT"],
                                    ["BOTTOMRIGHT"] = L["BOTTOMRIGHT"],
                                    ["CENTER"] = L["CENTER"],
                                },
                                order = 4,
                            },
                            x = {
                                type = "range",
                                name = L["X offset"],
                                desc = L["Set the X offset"],
                                width = 1.5,
                                min = -100,
                                max = 100,
                                step = 1,
                                disabled = function(info)
                                    local name = info[2]
                                    return not self.db.profile.unitFrames[name].enabled or self.db.profile.unitFrames[name].anchor == "manual" or
                                        self.db.profile.unitFrames[name].anchorPoint == "auto"
                                end,
                                order = 5,
                            },
                            y = {
                                type = "range",
                                name = L["Y offset"],
                                desc = L["Set the Y offset"],
                                width = 1.5,
                                min = -100,
                                max = 100,
                                step = 1,
                                disabled = function(info)
                                    local name = info[2]
                                    return not self.db.profile.unitFrames[name].enabled or self.db.profile.unitFrames[name].anchor == "manual" or
                                        self.db.profile.unitFrames[name].anchorPoint == "auto"
                                end,
                                order = 6,
                            },
                            matchFrameHeight = {
                                name = L["Match Frame Height"],
                                desc = L["Match the height of the frame"],
                                type = "toggle",
                                disabled = function(info)
                                    local name = info[2]
                                    return not self.db.profile.unitFrames[name].enabled or self.db.profile.unitFrames[name].anchor == "manual"
                                end,
                                order = 7,
                            },
                            size = {
                                type = "range",
                                disabled = function(info)
                                    local name = info[2]
                                    return not self.db.profile.unitFrames[name].enabled or
                                        (self.db.profile.unitFrames[name].anchor == "auto" and self.db.profile.unitFrames[name].matchFrameHeight)
                                end,
                                name = L["Size"],
                                width = "double",
                                desc = L["Set the size of the frame"],
                                min = 8,
                                max = 512,
                                step = 1,
                                order = 8,
                            },
                        },
                        name = "Target of Target Frame",
                        desc = "Enable BigDebuffs on the target of target frame",
                        order = 3,
                    },
                    pet = {
                        type = "group",
                        disabled = function(info)
                            return not self.db.profile[info[1]].enabled or
                                (info[3] and not self.db.profile.unitFrames[info[2]].enabled)
                        end,
                        get = function(info)
                            local name = info[#info]
                            return self.db.profile.unitFrames.pet[name]
                        end,
                        set = function(info, value)
                            local name = info[#info]
                            self.db.profile.unitFrames.pet[name] = value
                            self:Refresh()
                        end,
                        args = {
                            enabled = {
                                type = "toggle",
                                disabled = function(info) return not self.db.profile[info[1]].enabled end,
                                name = L["Enabled"],
                                order = 1,
                                width = "full",
                                desc = L["Enable BigDebuffs on the pet frame"],
                            },
                            anchor = {
                                name = L["Anchor"],
                                desc = L["Anchor to attach the BigDebuffs frames"],
                                type = "select",
                                values = {
                                    ["auto"] = L["Automatic"],
                                    ["manual"] = L["Manual"],
                                },
                                width = "normal",
                                order = 2,
                            },
                            anchorPoint = {
                                name = L["Anchor Point"],
                                desc = L["Anchor point to attach the BigDebuffs frames"],
                                type = "select",
                                disabled = function(info)
                                    local name = info[2]
                                    return not self.db.profile.unitFrames[name].enabled or self.db.profile.unitFrames[name].anchor == "manual"
                                end,
                                values = {
                                    ["auto"] = L["Automatic"],
                                    ["TOP"] = L["TOP"],
                                    ["RIGHT"] = L["RIGHT"],
                                    ["BOTTOM"] = L["BOTTOM"],
                                    ["LEFT"] = L["LEFT"],
                                    ["TOPRIGHT"] = L["TOPRIGHT"],
                                    ["TOPLEFT"] = L["TOPLEFT"],
                                    ["BOTTOMLEFT"] = L["BOTTOMLEFT"],
                                    ["BOTTOMRIGHT"] = L["BOTTOMRIGHT"],
                                    ["CENTER"] = L["CENTER"],
                                },
                                order = 3,
                            },
                            relativePoint = {
                                name = L["Relative Point"],
                                desc = L["Relative point to attach the BigDebuffs frames"],
                                type = "select",
                                disabled = function(info)
                                    local name = info[2]
                                    return not self.db.profile.unitFrames[name].enabled or self.db.profile.unitFrames[name].anchor == "manual" or
                                        self.db.profile.unitFrames[name].anchorPoint == "auto"
                                end,
                                values = {
                                    ["auto"] = L["Automatic"],
                                    ["TOP"] = L["TOP"],
                                    ["RIGHT"] = L["RIGHT"],
                                    ["BOTTOM"] = L["BOTTOM"],
                                    ["LEFT"] = L["LEFT"],
                                    ["TOPRIGHT"] = L["TOPRIGHT"],
                                    ["TOPLEFT"] = L["TOPLEFT"],
                                    ["BOTTOMLEFT"] = L["BOTTOMLEFT"],
                                    ["BOTTOMRIGHT"] = L["BOTTOMRIGHT"],
                                    ["CENTER"] = L["CENTER"],
                                },
                                order = 4,
                            },
                            x = {
                                type = "range",
                                name = L["X offset"],
                                desc = L["Set the X offset"],
                                width = 1.5,
                                min = -100,
                                max = 100,
                                step = 1,
                                disabled = function(info)
                                    local name = info[2]
                                    return not self.db.profile.unitFrames[name].enabled or self.db.profile.unitFrames[name].anchor == "manual" or
                                        self.db.profile.unitFrames[name].anchorPoint == "auto"
                                end,
                                order = 5,
                            },
                            y = {
                                type = "range",
                                name = L["Y offset"],
                                desc = L["Set the Y offset"],
                                width = 1.5,
                                min = -100,
                                max = 100,
                                step = 1,
                                disabled = function(info)
                                    local name = info[2]
                                    return not self.db.profile.unitFrames[name].enabled or self.db.profile.unitFrames[name].anchor == "manual" or
                                        self.db.profile.unitFrames[name].anchorPoint == "auto"
                                end,
                                order = 6,
                            },
                            matchFrameHeight = {
                                name = L["Match Frame Height"],
                                desc = L["Match the height of the frame"],
                                type = "toggle",
                                disabled = function(info)
                                    local name = info[2]
                                    return not self.db.profile.unitFrames[name].enabled or self.db.profile.unitFrames[name].anchor == "manual"
                                end,
                                order = 7,
                            },
                            size = {
                                type = "range",
                                disabled = function(info)
                                    local name = info[2]
                                    return not self.db.profile.unitFrames[name].enabled or
                                        (self.db.profile.unitFrames[name].anchor == "auto" and self.db.profile.unitFrames[name].matchFrameHeight)
                                end,
                                name = L["Size"],
                                width = "double",
                                desc = L["Set the size of the frame"],
                                min = 8,
                                max = 512,
                                step = 1,
                                order = 8,
                            },
                        },
                        name = L["Pet Frame"],
                        desc = L["Enable BigDebuffs on the pet frame"],
                        order = 4,
                    },
                    party = {
                        type = "group",
                        disabled = function(info)
                            return not self.db.profile[info[1]].enabled or
                                (info[3] and not self.db.profile.unitFrames[info[2]].enabled)
                        end,
                        get = function(info)
                            local name = info[#info]
                            return self.db.profile.unitFrames.party[name]
                        end,
                        set = function(info, value)
                            local name = info[#info]
                            self.db.profile.unitFrames.party[name] = value
                            self:Refresh()
                        end,
                        args = {
                            enabled = {
                                type = "toggle",
                                disabled = function(info) return not self.db.profile[info[1]].enabled end,
                                name = L["Enabled"],
                                order = 1,
                                width = "full",
                                desc = L["Enable BigDebuffs on the party frames"],
                            },
                            anchor = {
                                name = L["Anchor"],
                                desc = L["Anchor to attach the BigDebuffs frames"],
                                type = "select",
                                values = {
                                    ["auto"] = L["Automatic"],
                                    ["manual"] = L["Manual"],
                                },
                                width = "normal",
                                order = 2,
                            },
                            anchorPoint = {
                                name = L["Anchor Point"],
                                desc = L["Anchor point to attach the BigDebuffs frames"],
                                type = "select",
                                disabled = function(info)
                                    local name = info[2]
                                    return not self.db.profile.unitFrames[name].enabled or self.db.profile.unitFrames[name].anchor == "manual"
                                end,
                                values = {
                                    ["auto"] = L["Automatic"],
                                    ["TOP"] = L["TOP"],
                                    ["RIGHT"] = L["RIGHT"],
                                    ["BOTTOM"] = L["BOTTOM"],
                                    ["LEFT"] = L["LEFT"],
                                    ["TOPRIGHT"] = L["TOPRIGHT"],
                                    ["TOPLEFT"] = L["TOPLEFT"],
                                    ["BOTTOMLEFT"] = L["BOTTOMLEFT"],
                                    ["BOTTOMRIGHT"] = L["BOTTOMRIGHT"],
                                    ["CENTER"] = L["CENTER"],
                                },
                                order = 3,
                            },
                            relativePoint = {
                                name = L["Relative Point"],
                                desc = L["Relative point to attach the BigDebuffs frames"],
                                type = "select",
                                disabled = function(info)
                                    local name = info[2]
                                    return not self.db.profile.unitFrames[name].enabled or self.db.profile.unitFrames[name].anchor == "manual" or
                                        self.db.profile.unitFrames[name].anchorPoint == "auto"
                                end,
                                values = {
                                    ["auto"] = L["Automatic"],
                                    ["TOP"] = L["TOP"],
                                    ["RIGHT"] = L["RIGHT"],
                                    ["BOTTOM"] = L["BOTTOM"],
                                    ["LEFT"] = L["LEFT"],
                                    ["TOPRIGHT"] = L["TOPRIGHT"],
                                    ["TOPLEFT"] = L["TOPLEFT"],
                                    ["BOTTOMLEFT"] = L["BOTTOMLEFT"],
                                    ["BOTTOMRIGHT"] = L["BOTTOMRIGHT"],
                                    ["CENTER"] = L["CENTER"],
                                },
                                order = 4,
                            },
                            x = {
                                type = "range",
                                name = L["X offset"],
                                desc = L["Set the X offset"],
                                width = 1.5,
                                min = -100,
                                max = 100,
                                step = 1,
                                disabled = function(info)
                                    local name = info[2]
                                    return not self.db.profile.unitFrames[name].enabled or self.db.profile.unitFrames[name].anchor == "manual" or
                                        self.db.profile.unitFrames[name].anchorPoint == "auto"
                                end,
                                order = 5,
                            },
                            y = {
                                type = "range",
                                name = L["Y offset"],
                                desc = L["Set the Y offset"],
                                width = 1.5,
                                min = -100,
                                max = 100,
                                step = 1,
                                disabled = function(info)
                                    local name = info[2]
                                    return not self.db.profile.unitFrames[name].enabled or self.db.profile.unitFrames[name].anchor == "manual" or
                                        self.db.profile.unitFrames[name].anchorPoint == "auto"
                                end,
                                order = 6,
                            },
                            matchFrameHeight = {
                                name = L["Match Frame Height"],
                                desc = L["Match the height of the frame"],
                                type = "toggle",
                                disabled = function(info)
                                    local name = info[2]
                                    return not self.db.profile.unitFrames[name].enabled or self.db.profile.unitFrames[name].anchor == "manual"
                                end,
                                order = 7,
                            },
                            size = {
                                type = "range",
                                disabled = function(info)
                                    local name = info[2]
                                    return not self.db.profile.unitFrames[name].enabled or
                                        (self.db.profile.unitFrames[name].anchor == "auto" and self.db.profile.unitFrames[name].matchFrameHeight)
                                end,
                                name = L["Size"],
                                width = "double",
                                desc = L["Set the size of the frame"],
                                min = 8,
                                max = 512,
                                step = 1,
                                order = 8,
                            },
                        },
                        name = L["Party Frames"],
                        desc = L["Enable BigDebuffs on the party frames"],
                        order = 5,
                    },
                    spells = {
                        order = 20,
                        name = L["Spells"],
                        type = "group",
                        inline = true,
                        args = {
                            cc = {
                                type = "toggle",
                                width = "normal",
                                name = L["cc"],
                                desc = L["Show Crowd Control on the unit frames"],
                                order = 1,
                            },
                            immunities = {
                                type = "toggle",
                                width = "normal",
                                name = L["immunities"],
                                desc = L["Show Immunities on the unit frames"],
                                hidden = function() return WOW_PROJECT_ID == WOW_PROJECT_MAINLINE end,
                                order = 2,
                            },
                            interrupts = {
                                type = "toggle",
                                width = "normal",
                                name = L["interrupts"],
                                desc = L["Show Interrupts on the unit frames"],
                                hidden = function() return WOW_PROJECT_ID == WOW_PROJECT_MAINLINE end,
                                order = 3,
                            },
                            immunities_spells = {
                                type = "toggle",
                                width = "normal",
                                name = L["immunities_spells"],
                                desc = L["Show Spell Immunities on the unit frames"],
                                hidden = function() return WOW_PROJECT_ID == WOW_PROJECT_MAINLINE end,
                                order = 4,
                            },
                            buffs_defensive = {
                                type = "toggle",
                                width = "normal",
                                name = L["buffs_defensive"],
                                desc = L["Show Defensive Buffs on the unit frames"],
                                order = 5,
                            },
                            buffs_offensive = {
                                type = "toggle",
                                width = "normal",
                                name = L["buffs_offensive"],
                                desc = L["Show Offensive Buffs on the unit frames"],
                                hidden = function() return WOW_PROJECT_ID == WOW_PROJECT_MAINLINE end,
                                order = 6,
                            },
                            debuffs_offensive = {
                                type = "toggle",
                                width = "normal",
                                name = L["debuffs_offensive"],
                                desc = L["Show Offensive Debuffs on the unit frames"],
                                hidden = function() return WOW_PROJECT_ID == WOW_PROJECT_MAINLINE end,
                                order = 7,
                            },
                            buffs_other = {
                                type = "toggle",
                                width = "normal",
                                name = L["buffs_other"],
                                desc = L["Show Other Buffs on the unit frames"],
                                hidden = function() return WOW_PROJECT_ID == WOW_PROJECT_MAINLINE end,
                                order = 8,
                            },
                            roots = {
                                type = "toggle",
                                width = "normal",
                                name = L["roots"],
                                desc = L["Show Roots on the unit frames"],
                                hidden = function() return WOW_PROJECT_ID == WOW_PROJECT_MAINLINE end,
                                order = 9,
                            },
                            buffs_speed_boost = {
                                type = "toggle",
                                width = "normal",
                                name = L["buffs_speed_boost"],
                                desc = L["Show Speed Boosts on the unit frames"],
                                hidden = function() return WOW_PROJECT_ID == WOW_PROJECT_MAINLINE end,
                                order = 10,
                            },
                        },
                    },
                }
            },
			nameplates = {
				type = "group",
				disabled = function(info) return info[2] and not self.db.profile[info[1]].enabled end,
                childGroups = "tab",
                get = function(info) local name = info[#info] return self.db.profile.nameplates[name] end,
                set = function(info, value)
                    local name = info[#info]
                    self.db.profile.nameplates[name] = value
                    self:Refresh()
                end,
				args = {
					enabled = {
						type = "toggle",
						disabled = false,
						name = L["Enabled"],
						order = 1,
						desc = L["Enable BigDebuffs on the nameplates"],
					},
					enemy = {
						type = "toggle",
						name = "Enemy Nameplates",
						order = 1,
						desc = L["Enable BigDebuffs on enemy nameplates"],
					},
					friendly = {
						type = "toggle",
						name = "Friendly Nameplates",
						order = 1,
						desc = L["Enable BigDebuffs on friendly nameplates"],
					},
					npc = {
						type = "toggle",
						name = "NPC Nameplates",
						order = 1,
						width = "normal",
						desc = L["Enable BigDebuffs on non-player nameplates"],
					},
					cooldownCount = {
                        type = "toggle",
                        width = "normal",
                        name = L["Cooldown Count"],
                        desc = L["Allow Blizzard and other addons to display countdown text on the icons"],
                        order = 2,
                    },
                    tooltips = {
                        type = "toggle",
                        width = "normal",
                        name = L["Show Tooltips"],
                        desc = L["Show spell information when mousing over the icon"],
                        order = 2,
                    },
                    cooldownFont = {
                        type = "select",
                        name = L["Font"],
                        desc = L["Select font for cd timers"],
                        order = 3,
                        values = function()
                            local fonts, newFonts = LibSharedMedia:List("font"), {}
                            for k, v in pairs(fonts) do
                                newFonts[v] = v
                            end
                            return newFonts
                        end,
                    },
                    cooldownFontSize = {
                        type = "range",
                        name = L["Font Size"],
                        desc = L["Set the cd timers font size"],
                        min = 1,
                        max = 30,
                        step = 1,
                        order = 4,
                    },
                    cooldownFontEffect = {
                        type = "select",
                        name = L["Font Effect"],
                        desc = L["Set the cd timers font effect"],
                        values = {
                            ["MONOCHROME"] = "MONOCHROME",
                            ["OUTLINE"] = "OUTLINE",
                            ["THICKOUTLINE"] = "THICKOUTLINE",
                            [""] = "NONE",
                        },
                        order = 5,
                    },
					spells = {
                        order = 7,
                        name = L["Spells"],
                        type = "group",
                        inline = true,
                        args = {
                            cc = {
                                type = "toggle",
                                width = "normal",
                                name = L["cc"],
                                desc = L["Show Crowd Control on nameplates"],
                                order = 1,
                            },
                            immunities = {
                                type = "toggle",
                                width = "normal",
                                name = L["immunities"],
                                desc = L["Show Immunities on nameplates"],
                                hidden = function() return WOW_PROJECT_ID == WOW_PROJECT_MAINLINE end,
                                order = 2,
                            },
                            interrupts = {
                                type = "toggle",
                                width = "normal",
                                name = L["interrupts"],
                                desc = L["Show Interrupts on nameplates"],
                                hidden = function() return WOW_PROJECT_ID == WOW_PROJECT_MAINLINE end,
                                order = 3,
                            },
                            immunities_spells = {
                                type = "toggle",
                                width = "normal",
                                name = L["immunities_spells"],
                                desc = L["Show Spell Immunities on nameplates"],
                                hidden = function() return WOW_PROJECT_ID == WOW_PROJECT_MAINLINE end,
                                order = 4,
                            },
                            buffs_defensive = {
                                type = "toggle",
                                width = "normal",
                                name = L["buffs_defensive"],
                                desc = L["Show Defensive Buffs on nameplates"],
                                order = 5,
                            },
                            buffs_offensive = {
                                type = "toggle",
                                width = "normal",
                                name = L["buffs_offensive"],
                                desc = L["Show Offensive Buffs on nameplates"],
                                hidden = function() return WOW_PROJECT_ID == WOW_PROJECT_MAINLINE end,
                                order = 6,
                            },
                            debuffs_offensive = {
                                type = "toggle",
                                width = "normal",
                                name = L["debuffs_offensive"],
                                desc = L["Show Offensive Debuffs on nameplates"],
                                hidden = function() return WOW_PROJECT_ID == WOW_PROJECT_MAINLINE end,
                                order = 7,
                            },
                            buffs_other = {
                                type = "toggle",
                                width = "normal",
                                name = L["buffs_other"],
                                desc = L["Show Other Buffs on nameplates"],
                                hidden = function() return WOW_PROJECT_ID == WOW_PROJECT_MAINLINE end,
                                order = 8,
                            },
                            roots = {
                                type = "toggle",
                                width = "normal",
                                name = L["roots"],
                                desc = L["Show Roots on nameplates"],
                                hidden = function() return WOW_PROJECT_ID == WOW_PROJECT_MAINLINE end,
                                order = 9,
                            },
                            buffs_speed_boost = {
                                type = "toggle",
                                width = "normal",
                                name = L["buffs_speed_boost"],
                                desc = L["Show Speed Boosts on nameplates"],
                                hidden = function() return WOW_PROJECT_ID == WOW_PROJECT_MAINLINE end,
                                order = 10,
                            },
                        },
                    },
                    enemyAnchor = {
                        type = "group",
                        name = L["Anchor"],
                        get = function(info)
                            local name = info[#info]
                            return self.db.profile.nameplates.enemyAnchor[name]
                        end,
                        set = function(info, value)
                            local name = info[#info]
                            self.db.profile.nameplates.enemyAnchor[name] = value
                            self:Refresh()
                        end,
                        order = 9,
                        args = {
                            anchor = {
                                name = L["Anchor"],
                                desc = L["Anchor to attach the BigDebuffs frames"],
                                width = "normal",
                                type = "select",
                                values = {
                                    ["RIGHT"] = L["RIGHT"],
                                    ["TOP"] = L["TOP"],
                                    ["BOTTOM"] = L["BOTTOM"],
                                    ["LEFT"] = L["LEFT"],
                                },
                                order = 1,
                            },
                            size = {
                                type = "range",
                                name = L["Size"],
                                desc = L["Set the size of the frame"],
                                width = "double",
                                min = 8,
                                max = 100,
                                step = 1,
                                order = 2,
                            },
                            x = {
                                type = "range",
                                name = L["X offset"],
                                desc = L["Set the X offset"],
                                width = 1.5,
                                min = -100,
                                max = 100,
                                step = 1,
                                order = 3,
                            },
                            y = {
                                type = "range",
                                name = L["Y offset"],
                                desc = L["Set the Y offset"],
                                width = 1.5,
                                min = -100,
                                max = 100,
                                step = 1,
                                order = 4,
                            },
                        },
					},
                    friendlyAnchor = {
                        type = "group",
                        name = L["Friendly Anchor"],
                        get = function(info)
                            local name = info[#info]
                            return self.db.profile.nameplates.friendlyAnchor[name]
                        end,
                        set = function(info, value)
                            local name = info[#info]
                            self.db.profile.nameplates.friendlyAnchor[name] = value
                            self:Refresh()
                        end,
                        order = 9,
                        args = {
                            friendlyAnchorEnabled = {
                                name = L["Enable Friendly Anchor"],
                                desc = "Use a separate anchor for friendly nameplates. If disabled, will use the primary anchor settings instead",
                                type = "toggle",
                                width = "full",
                                order = 1,
                            },
                            anchor = {
                                name = L["Anchor"],
                                desc = L["Anchor to attach the BigDebuffs frames"],
                                type = "select",
                                width = "normal",
                                values = {
                                    ["RIGHT"] = L["RIGHT"],
                                    ["TOP"] = L["TOP"],
                                    ["BOTTOM"] = L["BOTTOM"],
                                    ["LEFT"] = L["LEFT"],
                                },
                                disabled = function(info)
                                    local name = info[2]
                                    return not self.db.profile.nameplates[name].friendlyAnchorEnabled
                                end,
                                order = 2,
                            },
                            size = {
                                type = "range",
                                name = L["Size"],
                                desc = L["Set the size of the frame"],
                                width = "double",
                                min = 8,
                                max = 100,
                                step = 1,
                                disabled = function(info)
                                    local name = info[2]
                                    return not self.db.profile.nameplates[name].friendlyAnchorEnabled
                                end,
                                order = 3,
                            },
                            x = {
                                type = "range",
                                name = L["X offset"],
                                desc = L["Set the X offset"],
                                width = 1.5,
                                min = -100,
                                max = 100,
                                step = 1,
                                disabled = function(info)
                                    local name = info[2]
                                    return not self.db.profile.nameplates[name].friendlyAnchorEnabled
                                end,
                                order = 4,
                            },
                            y = {
                                type = "range",
                                name = L["Y offset"],
                                desc = L["Set the Y offset"],
                                width = 1.5,
                                min = -100,
                                max = 100,
                                step = 1,
                                disabled = function(info)
                                    local name = info[2]
                                    return not self.db.profile.nameplates[name].friendlyAnchorEnabled
                                end,
                                order = 5,
                            },
                        },
					},
				},
				name = L["Nameplates"],
				desc = L["Enable BigDebuffs on the nameplates"],
				order = 30,
			},
            spells = {
                name = L["Spells"],
                type = "group",
                childGroups = "tab",
                hidden = function() return WOW_PROJECT_ID == WOW_PROJECT_MAINLINE end,
                order = 40,
                args = {},
            },
        }
    }

    -- Populate the Spells tab (presets + custom) after the options tree exists
    self.options.args.spells.args = self:BuildSpellOptions()

    if WOW_PROJECT_ID ~= WOW_PROJECT_CLASSIC then
        self.options.args.raidFrames.args.warning = {
            name = L["Warning Debuffs"],
            order = 30,
            type = "group",
            inline = true,
            hidden = function() return WOW_PROJECT_ID == WOW_PROJECT_MAINLINE end,
            args = WarningDebuffs,
        }

        self.options.args.raidFrames.args.scale.args.warning = {
            type = "range",
            isPercent = true,
            name = L["Warning Debuffs"],
            desc = L["Set the size of warning debuffs"],
            hidden = function() return WOW_PROJECT_ID == WOW_PROJECT_MAINLINE end,
            min = 0,
            max = 1,
            step = 0.01,
            order = 6,
        }

        self.options.args.unitFrames.args.focus = {
            type = "group",
            disabled = function(info)
                return not self.db.profile[info[1]].enabled or
                    (info[3] and not self.db.profile.unitFrames[info[2]].enabled)
            end,
            get = function(info)
                local name = info[#info]
                return self.db.profile.unitFrames.focus[name]
            end,
            set = function(info, value)
                local name = info[#info] self.db.profile.unitFrames.focus[name] = value
                self:Refresh()
            end,
            args = {
                enabled = {
                    type = "toggle",
                    disabled = function(info)
                        return not self.db.profile[info[1]].enabled
                    end,
                    name = L["Enabled"],
                    order = 1,
                    width = "full",
                    desc = L["Enable BigDebuffs on the focus frame"],
                },
                anchor = {
                    name = L["Anchor"],
                    desc = L["Anchor to attach the BigDebuffs frames"],
                    type = "select",
                    values = {
                        ["auto"] = L["Automatic"],
                        ["manual"] = L["Manual"],
                    },
                    width = "normal",
                    order = 2,
                },
                anchorPoint = {
                    name = L["Anchor Point"],
                    desc = L["Anchor point to attach the BigDebuffs frames"],
                    type = "select",
                    disabled = function(info)
                        local name = info[2]
                        return not self.db.profile.unitFrames[name].enabled or self.db.profile.unitFrames[name].anchor == "manual"
                    end,
                    values = {
                        ["auto"] = L["Automatic"],
                        ["TOP"] = L["TOP"],
                        ["RIGHT"] = L["RIGHT"],
                        ["BOTTOM"] = L["BOTTOM"],
                        ["LEFT"] = L["LEFT"],
                        ["TOPRIGHT"] = L["TOPRIGHT"],
                        ["TOPLEFT"] = L["TOPLEFT"],
                        ["BOTTOMLEFT"] = L["BOTTOMLEFT"],
                        ["BOTTOMRIGHT"] = L["BOTTOMRIGHT"],
                        ["CENTER"] = L["CENTER"],
                    },
                    order = 3,
                },
                relativePoint = {
                    name = L["Relative Point"],
                    desc = L["Relative point to attach the BigDebuffs frames"],
                    type = "select",
                    disabled = function(info)
                        local name = info[2]
                        return not self.db.profile.unitFrames[name].enabled or self.db.profile.unitFrames[name].anchor == "manual" or
                            self.db.profile.unitFrames[name].anchorPoint == "auto"
                    end,
                    values = {
                        ["auto"] = L["Automatic"],
                        ["TOP"] = L["TOP"],
                        ["RIGHT"] = L["RIGHT"],
                        ["BOTTOM"] = L["BOTTOM"],
                        ["LEFT"] = L["LEFT"],
                        ["TOPRIGHT"] = L["TOPRIGHT"],
                        ["TOPLEFT"] = L["TOPLEFT"],
                        ["BOTTOMLEFT"] = L["BOTTOMLEFT"],
                        ["BOTTOMRIGHT"] = L["BOTTOMRIGHT"],
                        ["CENTER"] = L["CENTER"],
                    },
                    order = 4,
                },
                x = {
                    type = "range",
                    name = L["X offset"],
                    desc = L["Set the X offset"],
                    width = 1.5,
                    min = -100,
                    max = 100,
                    step = 1,
                    disabled = function(info)
                        local name = info[2]
                        return not self.db.profile.unitFrames[name].enabled or self.db.profile.unitFrames[name].anchor == "manual" or
                            self.db.profile.unitFrames[name].anchorPoint == "auto"
                    end,
                    order = 5,
                },
                y = {
                    type = "range",
                    name = L["Y offset"],
                    desc = L["Set the Y offset"],
                    width = 1.5,
                    min = -100,
                    max = 100,
                    step = 1,
                    disabled = function(info)
                        local name = info[2]
                        return not self.db.profile.unitFrames[name].enabled or self.db.profile.unitFrames[name].anchor == "manual" or
                            self.db.profile.unitFrames[name].anchorPoint == "auto"
                    end,
                    order = 6,
                },
                matchFrameHeight = {
                    name = L["Match Frame Height"],
                    desc = L["Match the height of the frame"],
                    type = "toggle",
                    disabled = function(info)
                        local name = info[2]
                        return not self.db.profile.unitFrames[name].enabled or self.db.profile.unitFrames[name].anchor == "manual"
                    end,
                    order = 7,
                },
                size = {
                    type = "range",
                    disabled = function(info)
                        local name = info[2]
                        return not self.db.profile.unitFrames[name].enabled or
                            (self.db.profile.unitFrames[name].anchor == "auto" and self.db.profile.unitFrames[name].matchFrameHeight)
                    end,
                    name = L["Size"],
                    width = "double",
                    desc = L["Set the size of the frame"],
                    min = 8,
                    max = 512,
                    step = 1,
                    order = 8,
                },
            },
            name = L["Focus Frame"],
            desc = L["Enable BigDebuffs on the focus frame"],
            order = 3,
        }

        self.options.args.unitFrames.args.arena = {
            type = "group",
            disabled = function(info)
                return not self.db.profile[info[1]].enabled or
                    (info[3] and not self.db.profile.unitFrames[info[2]].enabled)
            end,
            get = function(info)
                local name = info[#info]
                return self.db.profile.unitFrames.arena[name]
            end,
            set = function(info, value)
                local name = info[#info]
                self.db.profile.unitFrames.arena[name] = value
                self:Refresh()
            end,
            args = {
                enabled = {
                    type = "toggle",
                    disabled = function(info) return not self.db.profile[info[1]].enabled end,
                    name = L["Enabled"],
                    order = 1,
                    width = "full",
                    desc = L["Enable BigDebuffs on the arena frames"],
                },
                anchor = {
                    name = L["Anchor"],
                    desc = L["Anchor to attach the BigDebuffs frames"],
                    type = "select",
                    values = {
                        ["auto"] = L["Automatic"],
                        ["manual"] = L["Manual"],
                    },
                    width = "normal",
                    order = 2,
                },
                anchorPoint = {
                    name = L["Anchor Point"],
                    desc = L["Anchor point to attach the BigDebuffs frames"],
                    type = "select",
                    disabled = function(info)
                        local name = info[2]
                        return not self.db.profile.unitFrames[name].enabled or self.db.profile.unitFrames[name].anchor == "manual"
                    end,
                    values = {
                        ["auto"] = L["Automatic"],
                        ["TOP"] = L["TOP"],
                        ["RIGHT"] = L["RIGHT"],
                        ["BOTTOM"] = L["BOTTOM"],
                        ["LEFT"] = L["LEFT"],
                        ["TOPRIGHT"] = L["TOPRIGHT"],
                        ["TOPLEFT"] = L["TOPLEFT"],
                        ["BOTTOMLEFT"] = L["BOTTOMLEFT"],
                        ["BOTTOMRIGHT"] = L["BOTTOMRIGHT"],
                        ["CENTER"] = L["CENTER"],
                    },
                    order = 3,
                },
                relativePoint = {
                    name = L["Relative Point"],
                    desc = L["Relative point to attach the BigDebuffs frames"],
                    type = "select",
                    disabled = function(info)
                        local name = info[2]
                        return not self.db.profile.unitFrames[name].enabled or self.db.profile.unitFrames[name].anchor == "manual" or
                            self.db.profile.unitFrames[name].anchorPoint == "auto"
                    end,
                    values = {
                        ["auto"] = L["Automatic"],
                        ["TOP"] = L["TOP"],
                        ["RIGHT"] = L["RIGHT"],
                        ["BOTTOM"] = L["BOTTOM"],
                        ["LEFT"] = L["LEFT"],
                        ["TOPRIGHT"] = L["TOPRIGHT"],
                        ["TOPLEFT"] = L["TOPLEFT"],
                        ["BOTTOMLEFT"] = L["BOTTOMLEFT"],
                        ["BOTTOMRIGHT"] = L["BOTTOMRIGHT"],
                        ["CENTER"] = L["CENTER"],
                    },
                    order = 4,
                },
                x = {
                    type = "range",
                    name = L["X offset"],
                    desc = L["Set the X offset"],
                    width = 1.5,
                    min = -100,
                    max = 100,
                    step = 1,
                    disabled = function(info)
                        local name = info[2]
                        return not self.db.profile.unitFrames[name].enabled or self.db.profile.unitFrames[name].anchor == "manual" or
                            self.db.profile.unitFrames[name].anchorPoint == "auto"
                    end,
                    order = 5,
                },
                y = {
                    type = "range",
                    name = L["Y offset"],
                    desc = L["Set the Y offset"],
                    width = 1.5,
                    min = -100,
                    max = 100,
                    step = 1,
                    disabled = function(info)
                        local name = info[2]
                        return not self.db.profile.unitFrames[name].enabled or self.db.profile.unitFrames[name].anchor == "manual" or
                            self.db.profile.unitFrames[name].anchorPoint == "auto"
                    end,
                    order = 6,
                },
                matchFrameHeight = {
                    name = L["Match Frame Height"],
                    desc = L["Match the height of the frame"],
                    type = "toggle",
                    disabled = function(info)
                        local name = info[2]
                        return not self.db.profile.unitFrames[name].enabled or self.db.profile.unitFrames[name].anchor == "manual"
                    end,
                    order = 7,
                },
                size = {
                    type = "range",
                    disabled = function(info)
                        local name = info[2]
                        return not self.db.profile.unitFrames[name].enabled or
                            (self.db.profile.unitFrames[name].anchor == "auto" and self.db.profile.unitFrames[name].matchFrameHeight)
                    end,
                    name = L["Size"],
                    width = "double",
                    desc = L["Set the size of the frame"],
                    min = 8,
                    max = 512,
                    step = 1,
                    order = 8,
                },
            },
            name = L["Arena Frames"],
            desc = L["Enable BigDebuffs on the arena frames"],
            order = 6,
        }
    end

    self.options.args.priority = {
        name = L["Priority"],
        type = "group",
        get = function(info) local name = info[#info] return self.db.profile.priority[name] end,
        set = function(info, value) local name = info[#info] self.db.profile.priority[name] = value self:Refresh() end,
        order = 30,
        args = {
            immunities = {
                type = "range",
                width = "double",
                name = L["immunities"],
                desc = L["Higher priority spells will take precedence regardless of duration"],
                hidden = function() return WOW_PROJECT_ID == WOW_PROJECT_MAINLINE end,
                min = 1,
                max = 100,
                step = 1,
                order = 10,
            },
            immunities_spells = {
                type = "range",
                width = "double",
                name = L["immunities_spells"],
                desc = L["Higher priority spells will take precedence regardless of duration"],
                hidden = function() return WOW_PROJECT_ID == WOW_PROJECT_MAINLINE end,
                min = 1,
                max = 100,
                step = 1,
                order = 11,
            },
            cc = {
                type = "range",
                width = "double",
                name = L["cc"],
                desc = L["Higher priority spells will take precedence regardless of duration"],
                min = 1,
                max = 100,
                step = 1,
                order = 12,
            },
            interrupts = {
                type = "range",
                width = "double",
                name = L["interrupts"],
                desc = L["Higher priority spells will take precedence regardless of duration"],
                hidden = function() return WOW_PROJECT_ID == WOW_PROJECT_MAINLINE end,
                min = 1,
                max = 100,
                step = 1,
                order = 13,
            },
            buffs_defensive = {
                type = "range",
                width = "double",
                name = L["buffs_defensive"],
                desc = L["Higher priority spells will take precedence regardless of duration"],
                min = 1,
                max = 100,
                step = 1,
                order = 14,
            },
            buffs_offensive = {
                type = "range",
                width = "double",
                name = L["buffs_offensive"],
                desc = L["Higher priority spells will take precedence regardless of duration"],
                hidden = function() return WOW_PROJECT_ID == WOW_PROJECT_MAINLINE end,
                min = 1,
                max = 100,
                step = 1,
                order = 15,
            },
            debuffs_offensive = {
                type = "range",
                width = "double",
                name = L["debuffs_offensive"],
                desc = L["Higher priority spells will take precedence regardless of duration"],
                hidden = function() return WOW_PROJECT_ID == WOW_PROJECT_MAINLINE end,
                min = 1,
                max = 100,
                step = 1,
                order = 16,
            },
            buffs_other = {
                type = "range",
                width = "double",
                name = L["buffs_other"],
                desc = L["Higher priority spells will take precedence regardless of duration"],
                hidden = function() return WOW_PROJECT_ID == WOW_PROJECT_MAINLINE end,
                min = 1,
                max = 100,
                step = 1,
                order = 17,
            },
            roots = {
                type = "range",
                width = "double",
                name = L["roots"],
                desc = L["Higher priority spells will take precedence regardless of duration"],
                hidden = function() return WOW_PROJECT_ID == WOW_PROJECT_MAINLINE end,
                min = 1,
                max = 100,
                step = 1,
                order = 18,
            },
            buffs_speed_boost = {
                type = "range",
                width = "double",
                name = L["buffs_speed_boost"],
                desc = L["Higher priority spells will take precedence regardless of duration"],
                hidden = function() return WOW_PROJECT_ID == WOW_PROJECT_MAINLINE end,
                min = 1,
                max = 100,
                step = 1,
                order = 19,
            },
        },
    }

    self.options.plugins.profiles = { profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db) }

    if WOW_PROJECT_ID ~= WOW_PROJECT_CLASSIC and WOW_PROJECT_ID ~= WOW_PROJECT_BURNING_CRUSADE_CLASSIC then
        local LibDualSpec = LibStub('LibDualSpec-1.0')
        LibDualSpec:EnhanceDatabase(self.db, "BigDebuffsDB")
        LibDualSpec:EnhanceOptions(self.options.plugins.profiles.profiles, self.db)
    end

    LibStub("AceConfig-3.0"):RegisterOptionsTable("BigDebuffs", self.options)
    local _, categoryID = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("BigDebuffs", "BigDebuffs")
    self.optionsCategory = categoryID
end
