local WM = _G.WineMorpher or {}
_G.WineMorpher = WM

local C = {
    bg = {0.045, 0.050, 0.055, 0.98},
    panel = {0.065, 0.070, 0.078, 0.96},
    panel2 = {0.085, 0.092, 0.102, 0.98},
    input = {0.025, 0.028, 0.032, 0.98},
    button = {0.105, 0.112, 0.124, 1.0},
    hover = {0.145, 0.156, 0.172, 1.0},
    active = {0.075, 0.335, 0.455, 1.0},
    border = {0.230, 0.240, 0.255, 1.0},
    soft = {0.135, 0.145, 0.158, 1.0},
    accent = {0.180, 0.720, 0.920, 1.0},
    gold = {1.000, 0.780, 0.220, 1.0},
    danger = {0.520, 0.105, 0.105, 1.0},
}

local slotList = {
    {1, "Head"},
    {3, "Shoulder"},
    {5, "Chest"},
    {6, "Waist"},
    {7, "Legs"},
    {8, "Feet"},
    {9, "Wrist"},
    {10, "Hands"},
    {15, "Back"},
    {16, "Main"},
    {17, "Off"},
    {18, "Ranged"},
    {19, "Tabard"},
}

local slotNames = {}
for _, slot in ipairs(slotList) do
    slotNames[slot[1]] = slot[2]
end

local slotIdsByName = {
    Head = 1,
    Shoulder = 3,
    Shirt = 4,
    Chest = 5,
    Waist = 6,
    Legs = 7,
    Feet = 8,
    Wrist = 9,
    Hands = 10,
    Back = 15,
    ["Main Hand"] = 16,
    ["Off-hand"] = 17,
    Ranged = 18,
    Tabard = 19,
}

local slotIconTextures = {
    Head = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Head",
    Shoulder = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Shoulder",
    Chest = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Chest",
    Waist = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Waist",
    Legs = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Legs",
    Feet = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Feet",
    Wrist = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Wrists",
    Hands = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Hands",
    Back = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Chest",
    ["Main Hand"] = "Interface\\PaperDoll\\UI-PaperDoll-Slot-MainHand",
    ["Off-hand"] = "Interface\\PaperDoll\\UI-PaperDoll-Slot-SecondaryHand",
    Ranged = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Ranged",
}

local raceMorphs = {
    {"Human M", 19723}, {"Human F", 19724}, {"Orc M", 6785}, {"Orc F", 20316},
    {"Dwarf M", 20317}, {"Dwarf F", 13250}, {"Night Elf M", 20318}, {"Night Elf F", 2222},
    {"Undead M", 28193}, {"Undead F", 23112}, {"Tauren M", 20585}, {"Tauren F", 20584},
    {"Gnome M", 20580}, {"Gnome F", 20581}, {"Troll M", 20321}, {"Troll F", 4358},
    {"Blood Elf M", 20578}, {"Blood Elf F", 20579}, {"Draenei M", 17155}, {"Draenei F", 20323},
}

local popularMorphs = {
    {"Lich King", 22234}, {"Illidan", 21135}, {"Sylvanas", 28213}, {"Alexstrasza", 28227},
    {"Ragnaros", 11121}, {"Brann Bronzebeard", 22266}, {"Malygos", 26752}, {"Tuskarr", 24685},
    {"Kel'Thuzad", 15945}, {"Yogg-Saron", 28817}, {"Kael'thas", 20023}, {"Lady Vashj", 20748},
    {"Nefarian", 11380}, {"Onyxia", 8570}, {"Arthas", 24949}, {"Uther", 16929},
    {"Evil Arthas", 22235}, {"Velen", 23749}, {"Dark Valkier", 25517}, {"Penguin", 24698},
}

local function GetData()
    if _G.WineMorpherData and _G.WineMorpherData.SearchItems then
        return _G.WineMorpherData
    end

    if type(LoadAddOn) == "function" then
        pcall(LoadAddOn, "WineMorpher_Data")
    end

    if _G.WineMorpherData and _G.WineMorpherData.SearchItems then
        return _G.WineMorpherData
    end

    return nil
end

local function StripColor(text)
    text = tostring(text or "")
    text = string.gsub(text, "|c%x%x%x%x%x%x%x%x", "")
    text = string.gsub(text, "|r", "")
    return text
end

local function ColorFromItemName(text)
    local color = string.match(tostring(text or ""), "|cff(%x%x%x%x%x%x)")
    if not color then
        return C.soft
    end

    local r = tonumber(string.sub(color, 1, 2), 16) or 255
    local g = tonumber(string.sub(color, 3, 4), 16) or 255
    local b = tonumber(string.sub(color, 5, 6), 16) or 255
    return {r / 255, g / 255, b / 255, 1}
end

local function GetLSM()
    if type(LoadAddOn) == "function" then
        if type(IsAddOnLoaded) ~= "function" or not IsAddOnLoaded("LibSharedMedia-3.0") then
            pcall(LoadAddOn, "LibSharedMedia-3.0")
        end
        if type(IsAddOnLoaded) ~= "function" or not IsAddOnLoaded("SharedMedia") then
            pcall(LoadAddOn, "SharedMedia")
        end
    end

    local libStub = _G.LibStub
    if not libStub then
        return nil
    end

    local ok, lib
    if type(libStub) == "function" then
        ok, lib = pcall(libStub, "LibSharedMedia-3.0", true)
    elseif type(libStub) == "table" and type(libStub.GetLibrary) == "function" then
        ok, lib = pcall(libStub.GetLibrary, libStub, "LibSharedMedia-3.0", true)
    end

    if ok then
        return lib
    end

    return nil
end

local function FetchPreferred(mediaType, names)
    local lsm = GetLSM()
    if not lsm then
        return nil, nil
    end

    for _, name in ipairs(names) do
        local ok, value = pcall(lsm.Fetch, lsm, mediaType, name, true)
        if ok and value then
            return value, name
        end
    end

    return nil, nil
end

local function RefreshMedia()
    local fontPath, fontName = FetchPreferred("font", {"Expressway", "PT Sans Narrow", "Friz Quadrata TT"})
    local barPath, barName = FetchPreferred("statusbar", {"ElvUI Norm", "ElvUI Blank", "Minimalist", "Blizzard"})

    WM.media = WM.media or {}
    WM.media.lsm = GetLSM()
    WM.media.fontPath = fontPath
    WM.media.fontName = fontName
    WM.media.barPath = barPath
    WM.media.barName = barName
    return WM.media
end

local function FontSize(fontObject)
    if fontObject == "GameFontNormalLarge" then
        return 16
    elseif fontObject == "GameFontNormal" then
        return 13
    end

    return 11
end

local function ApplyFont(fontString, fontObject)
    local media = WM.media or RefreshMedia()
    if media.fontPath then
        fontString:SetFont(media.fontPath, FontSize(fontObject), "")
    end
end

local function SetTextureColor(texture, color)
    texture:SetTexture(color[1], color[2], color[3], color[4] or 1)
end

local function SetPanelBorderColor(frame, color)
    if frame.wmTop then SetTextureColor(frame.wmTop, color) end
    if frame.wmBottom then SetTextureColor(frame.wmBottom, color) end
    if frame.wmLeft then SetTextureColor(frame.wmLeft, color) end
    if frame.wmRight then SetTextureColor(frame.wmRight, color) end
end

local function SetMediaTexture(texture, color)
    local media = WM.media or RefreshMedia()
    if media.barPath then
        texture:SetTexture(media.barPath)
        texture:SetVertexColor(color[1], color[2], color[3], color[4] or 1)
    else
        SetTextureColor(texture, color)
    end
end

local function Solid(parent, layer, color)
    local texture = parent:CreateTexture(nil, layer)
    SetTextureColor(texture, color)
    return texture
end

local function SetPanelColor(frame, color)
    if frame.wmBg then
        SetTextureColor(frame.wmBg, color)
    end
end

local function SkinPanel(frame, color, borderColor)
    frame.wmBg = frame.wmBg or Solid(frame, "BACKGROUND", color)
    frame.wmBg:SetAllPoints(frame)
    SetTextureColor(frame.wmBg, color)

    if not frame.wmTop then
        frame.wmTop = Solid(frame, "BORDER", borderColor)
        frame.wmBottom = Solid(frame, "BORDER", borderColor)
        frame.wmLeft = Solid(frame, "BORDER", borderColor)
        frame.wmRight = Solid(frame, "BORDER", borderColor)
    end

    frame.wmTop:SetHeight(1)
    frame.wmTop:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    frame.wmTop:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    frame.wmBottom:SetHeight(1)
    frame.wmBottom:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    frame.wmBottom:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    frame.wmLeft:SetWidth(1)
    frame.wmLeft:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    frame.wmLeft:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    frame.wmRight:SetWidth(1)
    frame.wmRight:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    frame.wmRight:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)

    SetTextureColor(frame.wmTop, borderColor)
    SetTextureColor(frame.wmBottom, borderColor)
    SetTextureColor(frame.wmLeft, borderColor)
    SetTextureColor(frame.wmRight, borderColor)
end

local function Label(parent, text, fontObject, color)
    local label = parent:CreateFontString(nil, "OVERLAY", fontObject or "GameFontHighlightSmall")
    label:SetText(text or "")
    ApplyFont(label, fontObject)
    if color then
        label:SetTextColor(color[1], color[2], color[3], color[4] or 1)
    end
    return label
end

local function MakeButton(parent, text, width, height)
    local button = CreateFrame("Button", nil, parent)
    button:SetWidth(width or 96)
    button:SetHeight(height or 24)
    button.normalColor = C.button
    SkinPanel(button, button.normalColor, C.soft)

    local font = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    font:SetPoint("CENTER", button, "CENTER", 0, 0)
    font:SetJustifyH("CENTER")
    font:SetTextColor(0.92, 0.94, 0.96, 1)
    ApplyFont(font, "GameFontHighlightSmall")
    button:SetFontString(font)
    button:SetText(text or "")

    button:SetScript("OnEnter", function(self)
        if not self.isSelected then
            SetPanelColor(self, C.hover)
        end
    end)
    button:SetScript("OnLeave", function(self)
        if not self.isSelected then
            SetPanelColor(self, self.normalColor or C.button)
        end
    end)
    button:SetScript("OnMouseDown", function(self)
        SetPanelColor(self, C.active)
    end)
    button:SetScript("OnMouseUp", function(self)
        if self.isSelected then
            SetPanelColor(self, C.active)
        else
            SetPanelColor(self, C.hover)
        end
    end)

    return button
end

local function MakeIconButton(parent, texturePath, tooltipText, size)
    local button = MakeButton(parent, "", size or 34, size or 34)
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetPoint("TOPLEFT", button, "TOPLEFT", 3, -3)
    button.icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -3, 3)
    button.icon:SetTexture(texturePath or "Interface\\Icons\\INV_Misc_QuestionMark")
    button.tooltipText = tooltipText
    button.isSlotIcon = true

    button:SetScript("OnEnter", function(self)
        if not self.isSelected then
            SetPanelColor(self, C.hover)
        end
        if self.tooltipText then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(self.tooltipText, 1, 0.82, 0.2)
            GameTooltip:Show()
        end
    end)
    button:SetScript("OnLeave", function(self)
        if not self.isSelected then
            SetPanelColor(self, self.normalColor or C.button)
        end
        GameTooltip:Hide()
    end)

    return button
end

local function MakeInput(parent, width, height, defaultText)
    local input = CreateFrame("EditBox", nil, parent)
    input:SetWidth(width or 120)
    input:SetHeight(height or 24)
    input:SetAutoFocus(false)
    input:SetFontObject(GameFontHighlightSmall)
    ApplyFont(input, "GameFontHighlightSmall")
    input:SetTextColor(0.94, 0.96, 0.98, 1)
    input:SetJustifyH("LEFT")
    input:SetTextInsets(7, 7, 0, 0)
    input:SetText(defaultText or "")
    SkinPanel(input, C.input, C.soft)
    input:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    input:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    return input
end

local function Section(parent, title, x, y, width, height)
    local section = CreateFrame("Frame", nil, parent)
    section:SetWidth(width)
    section:SetHeight(height)
    section:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    SkinPanel(section, C.panel2, C.soft)

    local titleText = Label(section, title, "GameFontNormalSmall", C.gold)
    titleText:SetPoint("TOPLEFT", section, "TOPLEFT", 12, -10)
    return section
end

local function NumberFromInput(input, label, min, max, allowZero)
    local value = tonumber(input:GetText() or "")
    if not value then
        WM.Print("Enter a valid " .. label .. ".")
        return nil
    end

    if not allowZero and value <= 0 then
        WM.Print(label .. " must be greater than 0.")
        return nil
    end

    if min and value < min then
        WM.Print(label .. " is too low.")
        return nil
    end

    if max and value > max then
        WM.Print(label .. " is too high.")
        return nil
    end

    return math.floor(value)
end

local function FloatFromInput(input, label, min, max)
    local value = tonumber(input:GetText() or "")
    if not value then
        WM.Print("Enter a valid " .. label .. ".")
        return nil
    end

    if min and value < min then
        WM.Print(label .. " is too low.")
        return nil
    end

    if max and value > max then
        WM.Print(label .. " is too high.")
        return nil
    end

    return value
end

local function Send(command)
    if WM.QueueCommand then
        return WM.QueueCommand(command)
    end

    WM.Print("Command bridge is not ready.")
    return false
end

local function SendMany(commands)
    if WM.QueueCommands then
        return WM.QueueCommands(commands)
    end

    local sent = false
    for _, command in ipairs(commands or {}) do
        if Send(command) then
            sent = true
        end
    end
    return sent
end

local function EnsureLoadouts()
    WineMorpherState.loadouts = WineMorpherState.loadouts or {}
    return WineMorpherState.loadouts
end

local function EnsureSettings()
    WineMorpherState.settings = WineMorpherState.settings or {}
    if WineMorpherState.settings.showMinimap == nil then
        WineMorpherState.settings.showMinimap = true
    end
    if WineMorpherState.settings.minimapAngle == nil then
        WineMorpherState.settings.minimapAngle = 225
    end
    return WineMorpherState.settings
end

local function EnsureFavorites(kind)
    WineMorpherState.favorites = WineMorpherState.favorites or {}
    WineMorpherState.favorites[kind] = WineMorpherState.favorites[kind] or {}
    return WineMorpherState.favorites[kind]
end

local function LowerText(text)
    return string.lower(tostring(text or ""))
end

local function Trim(text)
    text = tostring(text or "")
    text = string.gsub(text, "^%s+", "")
    text = string.gsub(text, "%s+$", "")
    return text
end

local function FavoriteKey(entry, fallback)
    if not entry then
        return nil
    end
    local key = entry.id or entry.displayID or entry.name or fallback
    if not key then
        return nil
    end
    return tostring(key)
end

local function IsFavorite(kind, entry, fallback)
    local key = FavoriteKey(entry, fallback)
    if not key then
        return false
    end
    return EnsureFavorites(kind)[key] ~= nil
end

local function ToggleFavorite(kind, entry, fallback)
    local key = FavoriteKey(entry, fallback)
    if not key then
        return false
    end

    local favorites = EnsureFavorites(kind)
    if favorites[key] then
        favorites[key] = nil
        WM.Print("Removed favorite.")
        return false
    end

    local snapshot = {}
    for k, v in pairs(entry or {}) do
        if type(v) ~= "function" then
            snapshot[k] = v
        end
    end
    favorites[key] = snapshot
    WM.Print("Added favorite.")
    return true
end

local function FavoriteList(kind, query, predicate)
    local list = {}
    local q = LowerText(query)
    for _, entry in pairs(EnsureFavorites(kind)) do
        local search = LowerText(entry.name) .. " " .. tostring(entry.id or "") .. " " .. tostring(entry.displayID or "") .. " " .. LowerText(entry.slot) .. " " .. LowerText(entry.subclass) .. " " .. LowerText(entry.group) .. " " .. LowerText(entry.description)
        if (q == "" or string.find(search, q, 1, true)) and (not predicate or predicate(entry)) then
            table.insert(list, entry)
        end
    end
    table.sort(list, function(a, b)
        return LowerText(a.name or a.id or a.displayID) < LowerText(b.name or b.id or b.displayID)
    end)
    return list
end

local function SliceList(list, limit, offset)
    local result = {}
    local startIndex = (offset or 0) + 1
    local stopIndex = math.min(#list, (offset or 0) + (limit or #list))
    for index = startIndex, stopIndex do
        table.insert(result, list[index])
    end
    return result, #list
end

local function ShowCopyDialog(title, text)
    if not WM.copyDialog then
        local dialog = CreateFrame("Frame", "WineMorpherCopyDialog", UIParent)
        WM.copyDialog = dialog
        dialog:SetWidth(420)
        dialog:SetHeight(118)
        dialog:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        dialog:SetFrameStrata("TOOLTIP")
        dialog:EnableMouse(true)
        SkinPanel(dialog, C.panel2, C.accent)

        dialog.title = Label(dialog, "", "GameFontNormal", C.gold)
        dialog.title:SetPoint("TOPLEFT", dialog, "TOPLEFT", 12, -12)

        dialog.input = MakeInput(dialog, 318, 24, "")
        dialog.input:SetPoint("TOPLEFT", dialog, "TOPLEFT", 12, -46)

        dialog.close = MakeButton(dialog, "Close", 70, 24)
        dialog.close:SetPoint("LEFT", dialog.input, "RIGHT", 10, 0)
        dialog.close:SetScript("OnClick", function()
            dialog:Hide()
        end)

        local hint = Label(dialog, "Press Cmd+C / Ctrl+C to copy.", "GameFontHighlightSmall", {0.66, 0.72, 0.78, 1})
        hint:SetPoint("TOPLEFT", dialog.input, "BOTTOMLEFT", 0, -10)
        dialog:Hide()
    end

    WM.copyDialog.title:SetText(title or "Copy")
    WM.copyDialog.input:SetText(text or "")
    WM.copyDialog.input:HighlightText()
    WM.copyDialog:Show()
    WM.copyDialog.input:SetFocus()
end

local function ShowTextInputDialog(title, initialText, onAccept)
    if not WM.textInputDialog then
        local dialog = CreateFrame("Frame", "WineMorpherTextInputDialog", UIParent)
        WM.textInputDialog = dialog
        dialog:SetWidth(520)
        dialog:SetHeight(136)
        dialog:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        dialog:SetFrameStrata("TOOLTIP")
        dialog:EnableMouse(true)
        SkinPanel(dialog, C.panel2, C.accent)

        dialog.title = Label(dialog, "", "GameFontNormal", C.gold)
        dialog.title:SetPoint("TOPLEFT", dialog, "TOPLEFT", 12, -12)

        dialog.input = MakeInput(dialog, 486, 24, "")
        dialog.input:SetPoint("TOPLEFT", dialog, "TOPLEFT", 12, -46)

        dialog.ok = MakeButton(dialog, "OK", 78, 24)
        dialog.ok:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -96, 12)
        dialog.cancel = MakeButton(dialog, "Cancel", 78, 24)
        dialog.cancel:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -12, 12)
        dialog.cancel:SetScript("OnClick", function()
            dialog:Hide()
        end)
        dialog:Hide()
    end

    WM.textInputDialog.title:SetText(title or "Input")
    WM.textInputDialog.input:SetText(initialText or "")
    WM.textInputDialog.input:HighlightText()
    WM.textInputDialog.ok:SetScript("OnClick", function()
        local value = WM.textInputDialog.input:GetText()
        WM.textInputDialog:Hide()
        if onAccept then
            onAccept(value)
        end
    end)
    WM.textInputDialog:Show()
    WM.textInputDialog.input:SetFocus()
end

local function WowheadItemUrl(itemId)
    return "https://www.wowhead.com/wotlk/item=" .. tostring(itemId)
end

local function EncodeLoadout(name, loadout)
    local itemParts = {}
    for slotName, itemId in pairs(loadout.items or {}) do
        if tonumber(itemId) then
            table.insert(itemParts, tostring(slotName) .. ":" .. tostring(itemId))
        end
    end
    table.sort(itemParts)

    local enchantParts = {}
    for key, enchantId in pairs(loadout.enchants or {}) do
        if tonumber(enchantId) then
            table.insert(enchantParts, tostring(key) .. ":" .. tostring(enchantId))
        end
    end
    table.sort(enchantParts)

    return "WMLOADOUT;name=" .. tostring(name or "Imported") .. ";items=" .. table.concat(itemParts, ",") .. ";enchants=" .. table.concat(enchantParts, ",")
end

local function DecodeLoadout(text)
    text = tostring(text or "")
    if not string.find(text, "^WMLOADOUT;") then
        return nil, "Invalid loadout string."
    end

    local loadout = {items = {}, enchants = {}}
    local name = "Imported"
    for part in string.gmatch(text, "([^;]+)") do
        local key, value = string.match(part, "^([^=]+)=(.*)$")
        if key == "name" then
            name = Trim(value)
        elseif key == "items" then
            for pair in string.gmatch(value or "", "([^,]+)") do
                local slotName, itemId = string.match(pair, "^([^:]+):(%d+)$")
                if slotName and itemId then
                    loadout.items[slotName] = tonumber(itemId)
                end
            end
        elseif key == "enchants" then
            for pair in string.gmatch(value or "", "([^,]+)") do
                local enchantSlot, enchantId = string.match(pair, "^([^:]+):(%d+)$")
                if enchantSlot and enchantId then
                    loadout.enchants[enchantSlot] = tonumber(enchantId)
                end
            end
        end
    end

    if name == "" then
        name = "Imported"
    end
    return name, loadout
end

local function CopyNumberMap(source)
    local copy = {}
    for key, value in pairs(source or {}) do
        if tonumber(value) then
            copy[key] = tonumber(value)
        end
    end
    return copy
end

local function BuildPreviewCommands(items, enchants)
    local commands = {}
    for slotName, itemId in pairs(items or {}) do
        local slotId = slotIdsByName[slotName]
        if slotId and itemId and itemId > 0 then
            table.insert(commands, "ITEM:" .. tostring(slotId) .. ":" .. tostring(itemId))
        end
    end

    if enchants and enchants.mh and enchants.mh > 0 then
        table.insert(commands, "ENCHANT_MH:" .. tostring(enchants.mh))
    end
    if enchants and enchants.oh and enchants.oh > 0 then
        table.insert(commands, "ENCHANT_OH:" .. tostring(enchants.oh))
    end

    return commands
end

local function Atan2(y, x)
    if math.atan2 then
        return math.atan2(y, x)
    end
    if x > 0 then
        return math.atan(y / x)
    elseif x < 0 and y >= 0 then
        return math.atan(y / x) + math.pi
    elseif x < 0 and y < 0 then
        return math.atan(y / x) - math.pi
    elseif x == 0 and y > 0 then
        return math.pi / 2
    elseif x == 0 and y < 0 then
        return -math.pi / 2
    end
    return 0
end

local function PositionMinimapButton()
    if not WM.minimapButton or not Minimap then
        return
    end

    local settings = EnsureSettings()
    local angle = math.rad(settings.minimapAngle or 225)
    local radius = 80
    WM.minimapButton:ClearAllPoints()
    WM.minimapButton:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
end

function WM.UpdateMinimapButton()
    if not WM.minimapButton then
        return
    end
    local settings = EnsureSettings()
    if settings.showMinimap then
        WM.minimapButton:Show()
        PositionMinimapButton()
    else
        WM.minimapButton:Hide()
    end
end

function WM.CreateMinimapButton()
    if WM.minimapButton or not Minimap then
        WM.UpdateMinimapButton()
        return WM.minimapButton
    end

    local button = CreateFrame("Button", "WineMorpherMinimapButton", Minimap)
    WM.minimapButton = button
    button:SetWidth(32)
    button:SetHeight(32)
    button:SetFrameStrata("MEDIUM")
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    button.icon = button:CreateTexture(nil, "BACKGROUND")
    button.icon:SetPoint("TOPLEFT", button, "TOPLEFT", 6, -6)
    button.icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -6, 6)
    button.icon:SetTexture("Interface\\Icons\\INV_Misc_Orb_05")

    button.overlay = button:CreateTexture(nil, "OVERLAY")
    button.overlay:SetAllPoints(button)
    button.overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    button:SetScript("OnClick", function(self, mouseButton)
        if mouseButton == "RightButton" then
            local frame = WM.CreateGUI()
            frame:Show()
            if WM.ShowGUIPage then
                WM.ShowGUIPage("settings")
            end
        else
            WM.ToggleGUI()
        end
    end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("WineMorpher", C.gold[1], C.gold[2], C.gold[3])
        GameTooltip:AddLine("Left click: open/close", 0.82, 0.88, 0.94)
        GameTooltip:AddLine("Right click: settings", 0.82, 0.88, 0.94)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    button:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            local px, py = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            px = px / scale
            py = py / scale
            local angle = math.deg(Atan2(py - my, px - mx))
            EnsureSettings().minimapAngle = angle
            PositionMinimapButton()
        end)
    end)
    button:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
        PositionMinimapButton()
    end)

    WM.UpdateMinimapButton()
    return button
end

local function MakePage(parent)
    local page = CreateFrame("Frame", nil, parent)
    page:SetAllPoints(parent)
    return page
end

local function CreateGearPage(parent)
    local page = MakePage(parent)
    local selectedSlot = WineMorpherState.guiSlot or 16
    local slotButtons = {}

    local slots = Section(page, "Gear Slot", 0, 0, 252, 272)
    local selectedText = Label(slots, "", "GameFontHighlightSmall", C.accent)
    selectedText:SetPoint("TOPLEFT", slots, "TOPLEFT", 12, -34)

    local function SelectSlot(slotId)
        selectedSlot = slotId
        WineMorpherState.guiSlot = slotId
        selectedText:SetText("Selected: " .. (slotNames[slotId] or "Slot") .. " (" .. tostring(slotId) .. ")")
        for _, button in ipairs(slotButtons) do
            button.isSelected = button.slotId == slotId
            if button.isSelected then
                SetPanelColor(button, C.active)
            else
                SetPanelColor(button, button.normalColor or C.button)
            end
        end
    end

    for index, slot in ipairs(slotList) do
        local button = MakeButton(slots, slot[2], 70, 24)
        button.slotId = slot[1]
        local col = (index - 1) % 3
        local row = math.floor((index - 1) / 3)
        button:SetPoint("TOPLEFT", slots, "TOPLEFT", 12 + col * 78, -62 - row * 30)
        button:SetScript("OnClick", function(self) SelectSlot(self.slotId) end)
        table.insert(slotButtons, button)
    end

    local item = Section(page, "Item Morph", 270, 0, 286, 132)
    local itemLabel = Label(item, "Item ID", "GameFontHighlightSmall")
    itemLabel:SetPoint("TOPLEFT", item, "TOPLEFT", 12, -38)
    local itemInput = MakeInput(item, 132, 24, "49623")
    itemInput:SetPoint("TOPLEFT", item, "TOPLEFT", 72, -32)

    local applyItem = MakeButton(item, "Apply", 78, 24)
    applyItem:SetPoint("TOPLEFT", item, "TOPLEFT", 12, -72)
    applyItem:SetScript("OnClick", function()
        local itemId = NumberFromInput(itemInput, "item ID", 1, nil, false)
        if itemId then
            Send("ITEM:" .. tostring(selectedSlot) .. ":" .. tostring(itemId))
        end
    end)

    local hideItem = MakeButton(item, "Hide", 78, 24)
    hideItem:SetPoint("LEFT", applyItem, "RIGHT", 8, 0)
    hideItem:SetScript("OnClick", function()
        Send("ITEM:" .. tostring(selectedSlot) .. ":-1")
    end)

    local resetItem = MakeButton(item, "Reset", 78, 24)
    resetItem:SetPoint("LEFT", hideItem, "RIGHT", 8, 0)
    resetItem:SetScript("OnClick", function()
        Send("ITEM:" .. tostring(selectedSlot) .. ":0")
    end)

    local enchant = Section(page, "Weapon Enchants", 270, -150, 286, 122)
    local mhLabel = Label(enchant, "Main", "GameFontHighlightSmall")
    mhLabel:SetPoint("TOPLEFT", enchant, "TOPLEFT", 12, -38)
    local mhInput = MakeInput(enchant, 96, 24, "3789")
    mhInput:SetPoint("TOPLEFT", enchant, "TOPLEFT", 54, -32)
    local mhApply = MakeButton(enchant, "Apply", 72, 24)
    mhApply:SetPoint("LEFT", mhInput, "RIGHT", 8, 0)
    mhApply:SetScript("OnClick", function()
        local enchantId = NumberFromInput(mhInput, "main-hand enchant ID", 0, nil, true)
        if enchantId then
            Send("ENCHANT_MH:" .. tostring(enchantId))
        end
    end)

    local ohLabel = Label(enchant, "Off", "GameFontHighlightSmall")
    ohLabel:SetPoint("TOPLEFT", enchant, "TOPLEFT", 12, -70)
    local ohInput = MakeInput(enchant, 96, 24, "3789")
    ohInput:SetPoint("TOPLEFT", enchant, "TOPLEFT", 54, -64)
    local ohApply = MakeButton(enchant, "Apply", 72, 24)
    ohApply:SetPoint("LEFT", ohInput, "RIGHT", 8, 0)
    ohApply:SetScript("OnClick", function()
        local enchantId = NumberFromInput(ohInput, "off-hand enchant ID", 0, nil, true)
        if enchantId then
            Send("ENCHANT_OH:" .. tostring(enchantId))
        end
    end)

    local resetEnchant = MakeButton(enchant, "Reset All", 82, 24)
    resetEnchant:SetPoint("TOPRIGHT", enchant, "TOPRIGHT", -12, -64)
    resetEnchant:SetScript("OnClick", function()
        Send("ENCHANT_RESET")
    end)

    SelectSlot(selectedSlot)
    return page
end

local function CreateMountPage(parent)
    local page = MakePage(parent)
    local results = {}
    local rowButtons = {}
    local selectedMount = nil
    local dataLoaded = false
    local activeGroup = "ALL"
    local favoritesOnly = false
    local pageIndex = 1
    local perPage = 12
    local matchedCount = 0

    local mount = Section(page, "Mount Morph", 0, 0, 330, 118)
    local idLabel = Label(mount, "Display ID", "GameFontHighlightSmall")
    idLabel:SetPoint("TOPLEFT", mount, "TOPLEFT", 12, -38)
    local input = MakeInput(mount, 130, 24, "31007")
    input:SetPoint("TOPLEFT", mount, "TOPLEFT", 88, -32)

    local apply = MakeButton(mount, "Apply", 82, 24)
    apply:SetPoint("TOPLEFT", mount, "TOPLEFT", 12, -74)
    apply:SetScript("OnClick", function()
        local displayId = NumberFromInput(input, "mount display ID", 1, nil, false)
        if displayId then
            Send("MOUNT:" .. tostring(displayId))
        end
    end)

    local reset = MakeButton(mount, "Reset", 82, 24)
    reset:SetPoint("LEFT", apply, "RIGHT", 8, 0)
    reset:SetScript("OnClick", function()
        Send("MOUNT:0")
    end)

    local mountLabel = Label(mount, "Select a mount from the database", "GameFontHighlightSmall", {0.88, 0.92, 0.96, 1})
    mountLabel:SetPoint("TOPLEFT", mount, "TOPLEFT", 184, -78)
    mountLabel:SetWidth(132)
    mountLabel:SetJustifyH("LEFT")

    local db = Section(page, "Mount Database", 350, 0, 482, 498)
    local search = MakeInput(db, 220, 24, "")
    search:SetPoint("TOPLEFT", db, "TOPLEFT", 12, -28)
    local dbCount = Label(db, "Open tab to load data", "GameFontHighlightSmall", {0.66, 0.72, 0.78, 1})
    dbCount:SetPoint("LEFT", search, "RIGHT", 10, 0)
    local favoritesButton = MakeButton(db, "Favorites", 78, 24)
    favoritesButton:SetPoint("TOPRIGHT", db, "TOPRIGHT", -12, -28)
    local groupButtons = {}
    local groupNames = {"All", "Ground", "Flying", "PvP", "Raid", "Dungeon", "Horses", "Rams", "Skeletal Horse", "Sabers", "Wolves", "Raptors", "Kodos", "Drakes", "Mammoths", "Bears", "Talbuks", "Elekks", "Hawkstriders", "Mechanostriders"}
    for i, groupName in ipairs(groupNames) do
        local button = MakeButton(db, groupName, 108, 20)
        local col = (i - 1) % 4
        local row = math.floor((i - 1) / 4)
        button:SetPoint("TOPLEFT", db, "TOPLEFT", 12 + col * 112, -60 - row * 23)
        button.groupName = groupName == "All" and "ALL" or groupName
        groupButtons[i] = button
    end
    local pageLabel = Label(db, "Page 1/1", "GameFontHighlightSmall", C.gold)
    pageLabel:SetPoint("BOTTOM", db, "BOTTOM", 0, 12)
    local prevButton = MakeButton(db, "<", 34, 22)
    prevButton:SetPoint("RIGHT", pageLabel, "LEFT", -10, 0)
    local nextButton = MakeButton(db, ">", 34, 22)
    nextButton:SetPoint("LEFT", pageLabel, "RIGHT", 10, 0)

    local function SelectMount(entry)
        selectedMount = entry
        if entry then
            input:SetText(tostring(entry.displayID))
            mountLabel:SetText(entry.name .. "  #" .. tostring(entry.displayID))
        end
    end

    local SearchMounts
    local function BuildMountRows()
        for _, row in ipairs(rowButtons) do
            row:Hide()
        end

        for i = 1, perPage do
            local entry = results[i]
            local row = rowButtons[i]
            if not row then
                row = MakeButton(db, "", 450, 22)
                row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
                row:SetPoint("TOPLEFT", db, "TOPLEFT", 12, -184 - (i - 1) * 23)
                row.name = Label(row, "", "GameFontHighlightSmall", {0.92, 0.94, 0.96, 1})
                row.name:SetPoint("LEFT", row, "LEFT", 8, 0)
                row.name:SetWidth(288)
                row.name:SetJustifyH("LEFT")
                row.meta = Label(row, "", "GameFontHighlightSmall", {0.58, 0.66, 0.72, 1})
                row.meta:SetPoint("RIGHT", row, "RIGHT", -8, 0)
                table.insert(rowButtons, row)
            end

            if entry then
                row.entry = entry
                row.name:SetText(entry.name)
                local star = IsFavorite("mounts", entry) and "* " or ""
                row.meta:SetText(star .. tostring(entry.group or entry.mountType) .. "  #" .. tostring(entry.displayID))
                row:SetScript("OnClick", function(self, mouseButton)
                    if mouseButton == "RightButton" then
                        ToggleFavorite("mounts", self.entry)
                        SearchMounts()
                    else
                        SelectMount(self.entry)
                    end
                end)
                row:SetScript("OnEnter", function(self)
                    SetPanelColor(self, C.hover)
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:AddLine(self.entry.name)
                    GameTooltip:AddLine("Display ID: " .. tostring(self.entry.displayID), 1, 1, 1)
                    GameTooltip:AddLine("Group: " .. tostring(self.entry.group or "Mount"), 0.7, 0.8, 0.9)
                    GameTooltip:AddLine("Right click: favorite", C.gold[1], C.gold[2], C.gold[3])
                    GameTooltip:Show()
                end)
                row:SetScript("OnLeave", function(self)
                    SetPanelColor(self, self.normalColor or C.button)
                    GameTooltip:Hide()
                end)
                row:Show()
            end
        end
    end

    SearchMounts = function()
        local data = GetData()
        if not data or not data.SearchMounts then
            dbCount:SetText("WineMorpher_Data not loaded")
            return
        end

        dataLoaded = true
        local total
        if favoritesOnly then
            local list = FavoriteList("mounts", search:GetText(), function(entry)
                return activeGroup == "ALL" or entry.group == activeGroup or entry.mountType == activeGroup
            end)
            results, matchedCount = SliceList(list, perPage, (pageIndex - 1) * perPage)
            total = #list
        else
            results, total, matchedCount = data.SearchMounts(search:GetText(), activeGroup, perPage, (pageIndex - 1) * perPage)
        end
        dbCount:SetText(tostring(matchedCount or #results) .. " found / " .. tostring(total) .. " mounts")
        local pages = math.max(1, math.ceil((matchedCount or 0) / perPage))
        if pageIndex > pages then
            pageIndex = pages
            if favoritesOnly then
                local list = FavoriteList("mounts", search:GetText(), function(entry)
                    return activeGroup == "ALL" or entry.group == activeGroup or entry.mountType == activeGroup
                end)
                results, matchedCount = SliceList(list, perPage, (pageIndex - 1) * perPage)
                total = #list
            else
                results, total, matchedCount = data.SearchMounts(search:GetText(), activeGroup, perPage, (pageIndex - 1) * perPage)
            end
        end
        pageLabel:SetText("Page " .. tostring(pageIndex) .. "/" .. tostring(pages))
        favoritesButton.isSelected = favoritesOnly
        SetPanelColor(favoritesButton, favoritesOnly and C.active or C.button)
        for _, button in ipairs(groupButtons) do
            button.isSelected = button.groupName == activeGroup
            SetPanelColor(button, button.isSelected and C.active or C.button)
        end
        BuildMountRows()
    end

    favoritesButton:SetScript("OnClick", function()
        favoritesOnly = not favoritesOnly
        pageIndex = 1
        SearchMounts()
    end)

    for _, button in ipairs(groupButtons) do
        button:SetScript("OnClick", function(self)
            activeGroup = self.groupName
            pageIndex = 1
            SearchMounts()
        end)
    end
    prevButton:SetScript("OnClick", function()
        if pageIndex > 1 then
            pageIndex = pageIndex - 1
            SearchMounts()
        end
    end)
    nextButton:SetScript("OnClick", function()
        local pages = math.max(1, math.ceil((matchedCount or 0) / perPage))
        if pageIndex < pages then
            pageIndex = pageIndex + 1
            SearchMounts()
        end
    end)

    search:SetScript("OnTextChanged", function()
        if dataLoaded then
            pageIndex = 1
            SearchMounts()
        end
    end)
    search:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        SearchMounts()
    end)

    page:SetScript("OnShow", function()
        if not dataLoaded then
            SearchMounts()
        end
    end)

    return page
end

local function CreateMorphPage(parent)
    local page = MakePage(parent)
    local morph = Section(page, "Player Morph", 0, 0, 332, 498)
    local displayLabel = Label(morph, "Display ID", "GameFontHighlightSmall")
    displayLabel:SetPoint("TOPLEFT", morph, "TOPLEFT", 12, -38)
    local displayInput = MakeInput(morph, 130, 24, "20578")
    displayInput:SetPoint("TOPLEFT", morph, "TOPLEFT", 88, -32)
    local applyDisplay = MakeButton(morph, "Apply", 82, 24)
    applyDisplay:SetPoint("LEFT", displayInput, "RIGHT", 8, 0)
    applyDisplay:SetScript("OnClick", function()
        local displayId = NumberFromInput(displayInput, "display ID", 1, nil, false)
        if displayId then
            Send("DISPLAY:" .. tostring(displayId))
        end
    end)

    local scaleLabel = Label(morph, "Scale", "GameFontHighlightSmall")
    scaleLabel:SetPoint("TOPLEFT", morph, "TOPLEFT", 12, -74)
    local scaleInput = MakeInput(morph, 130, 24, "1.00")
    scaleInput:SetPoint("TOPLEFT", morph, "TOPLEFT", 88, -68)
    local applyScale = MakeButton(morph, "Apply", 82, 24)
    applyScale:SetPoint("LEFT", scaleInput, "RIGHT", 8, 0)
    applyScale:SetScript("OnClick", function()
        local scale = FloatFromInput(scaleInput, "scale", 0.01, 10.0)
        if scale then
            Send(string.format("SCALE:%.2f", scale))
        end
    end)

    local reset = MakeButton(morph, "Reset", 82, 24)
    reset:SetPoint("TOPLEFT", morph, "TOPLEFT", 12, -108)
    reset:SetScript("OnClick", function()
        Send("RESET")
    end)

    local raceLabel = Label(morph, "Race Morph", "GameFontNormalSmall", C.gold)
    raceLabel:SetPoint("TOPLEFT", morph, "TOPLEFT", 12, -142)
    for i, race in ipairs(raceMorphs) do
        local button = MakeButton(morph, race[1], 142, 18)
        local col = (i - 1) % 2
        local row = math.floor((i - 1) / 2)
        button:SetPoint("TOPLEFT", morph, "TOPLEFT", 12 + col * 148, -160 - row * 20)
        button:SetScript("OnClick", function()
            displayInput:SetText(tostring(race[2]))
            Send("DISPLAY:" .. tostring(race[2]))
        end)
    end

    local popularLabel = Label(morph, "Popular Creatures", "GameFontNormalSmall", C.gold)
    popularLabel:SetPoint("TOPLEFT", morph, "TOPLEFT", 12, -366)
    for i = 1, 10 do
        local creature = popularMorphs[i]
        local button = MakeButton(morph, creature[1], 142, 18)
        local col = (i - 1) % 2
        local row = math.floor((i - 1) / 2)
        button:SetPoint("TOPLEFT", morph, "TOPLEFT", 12 + col * 148, -386 - row * 20)
        button:SetScript("OnClick", function()
            displayInput:SetText(tostring(creature[2]))
            Send("DISPLAY:" .. tostring(creature[2]))
        end)
    end

    local db = Section(page, "Creature Database", 350, 0, 482, 498)
    local search = MakeInput(db, 220, 24, "")
    search:SetPoint("TOPLEFT", db, "TOPLEFT", 12, -28)
    local countLabel = Label(db, "Search creature names or display IDs", "GameFontHighlightSmall", {0.66, 0.72, 0.78, 1})
    countLabel:SetPoint("LEFT", search, "RIGHT", 10, 0)
    local rows = {}
    local results = {}
    local pageIndex = 1
    local perPage = 16
    local matchedCount = 0
    local dataLoaded = false
    local favoritesOnly = false
    local pageLabel = Label(db, "Page 1/1", "GameFontHighlightSmall", C.gold)
    pageLabel:SetPoint("BOTTOM", db, "BOTTOM", 0, 10)
    local favoritesButton = MakeButton(db, "Favorites", 78, 24)
    favoritesButton:SetPoint("TOPRIGHT", db, "TOPRIGHT", -12, -28)
    local prevButton = MakeButton(db, "<", 32, 22)
    prevButton:SetPoint("RIGHT", pageLabel, "LEFT", -10, 0)
    local nextButton = MakeButton(db, ">", 32, 22)
    nextButton:SetPoint("LEFT", pageLabel, "RIGHT", 10, 0)

    local function SelectCreature(entry)
        displayInput:SetText(tostring(entry.displayID))
    end

    local SearchCreatures
    local function BuildRows()
        for _, row in ipairs(rows) do row:Hide() end
        for i = 1, perPage do
            local entry = results[i]
            local row = rows[i]
            if not row then
                row = MakeButton(db, "", 450, 22)
                row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
                row:SetPoint("TOPLEFT", db, "TOPLEFT", 12, -62 - (i - 1) * 24)
                row.name = Label(row, "", "GameFontHighlightSmall", {0.92, 0.94, 0.96, 1})
                row.name:SetPoint("LEFT", row, "LEFT", 8, 0)
                row.name:SetWidth(330)
                row.name:SetJustifyH("LEFT")
                row.meta = Label(row, "", "GameFontHighlightSmall", {0.58, 0.66, 0.72, 1})
                row.meta:SetPoint("RIGHT", row, "RIGHT", -8, 0)
                row:SetScript("OnClick", function(self, mouseButton)
                    if mouseButton == "RightButton" then
                        ToggleFavorite("creatures", self.entry)
                        SearchCreatures()
                    else
                        SelectCreature(self.entry)
                    end
                end)
                rows[i] = row
            end
            if entry then
                row.entry = entry
                row.name:SetText(entry.name)
                row.meta:SetText((IsFavorite("creatures", entry) and "* " or "") .. "#" .. tostring(entry.displayID))
                row:Show()
            end
        end
    end

    SearchCreatures = function()
        local data = GetData()
        if not data or not data.SearchCreatureDisplays then
            countLabel:SetText("WineMorpher_Data not loaded")
            return
        end
        dataLoaded = true
        local total
        if favoritesOnly then
            local list = FavoriteList("creatures", search:GetText())
            results, matchedCount = SliceList(list, perPage, (pageIndex - 1) * perPage)
            total = #list
        else
            results, total, matchedCount = data.SearchCreatureDisplays(search:GetText(), perPage, (pageIndex - 1) * perPage)
        end
        local pages = math.max(1, math.ceil((matchedCount or 0) / perPage))
        if pageIndex > pages then pageIndex = pages end
        countLabel:SetText(tostring(matchedCount or 0) .. " found / " .. tostring(total or 0))
        pageLabel:SetText("Page " .. tostring(pageIndex) .. "/" .. tostring(pages))
        favoritesButton.isSelected = favoritesOnly
        SetPanelColor(favoritesButton, favoritesOnly and C.active or C.button)
        BuildRows()
    end

    search:SetScript("OnTextChanged", function()
        if dataLoaded then
            pageIndex = 1
            SearchCreatures()
        end
    end)
    prevButton:SetScript("OnClick", function()
        if pageIndex > 1 then
            pageIndex = pageIndex - 1
            SearchCreatures()
        end
    end)
    nextButton:SetScript("OnClick", function()
        local pages = math.max(1, math.ceil((matchedCount or 0) / perPage))
        if pageIndex < pages then
            pageIndex = pageIndex + 1
            SearchCreatures()
        end
    end)
    favoritesButton:SetScript("OnClick", function()
        favoritesOnly = not favoritesOnly
        pageIndex = 1
        SearchCreatures()
    end)

    displayInput:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
    end)

    page:SetScript("OnShow", function()
        if not dataLoaded then
            SearchCreatures()
        end
    end)

    return page
end

local function CreatePetsPage(parent)
    local page = MakePage(parent)
    local pet = Section(page, "Hunter Pet", 0, 0, 330, 150)

    local displayLabel = Label(pet, "Display ID", "GameFontHighlightSmall")
    displayLabel:SetPoint("TOPLEFT", pet, "TOPLEFT", 12, -38)
    local displayInput = MakeInput(pet, 130, 24, "")
    displayInput:SetPoint("TOPLEFT", pet, "TOPLEFT", 88, -32)
    local applyDisplay = MakeButton(pet, "Apply", 82, 24)
    applyDisplay:SetPoint("LEFT", displayInput, "RIGHT", 8, 0)
    applyDisplay:SetScript("OnClick", function()
        local displayId = NumberFromInput(displayInput, "pet display ID", 1, nil, false)
        if displayId then
            Send("HPET_MORPH:" .. tostring(displayId))
        end
    end)

    local scaleLabel = Label(pet, "Scale", "GameFontHighlightSmall")
    scaleLabel:SetPoint("TOPLEFT", pet, "TOPLEFT", 12, -74)
    local scaleInput = MakeInput(pet, 130, 24, "1.00")
    scaleInput:SetPoint("TOPLEFT", pet, "TOPLEFT", 88, -68)
    local applyScale = MakeButton(pet, "Apply", 82, 24)
    applyScale:SetPoint("LEFT", scaleInput, "RIGHT", 8, 0)
    applyScale:SetScript("OnClick", function()
        local scale = FloatFromInput(scaleInput, "pet scale", 0.01, 10.0)
        if scale then
            Send(string.format("HPET_SCALE:%.2f", scale))
        end
    end)

    local reset = MakeButton(pet, "Reset", 82, 24)
    reset:SetPoint("TOPLEFT", pet, "TOPLEFT", 12, -108)
    reset:SetScript("OnClick", function()
        Send("HPET_RESET")
    end)

    return page
end

local function CreatePreviewPage(parent)
    local page = MakePage(parent)
    local dataLoaded = false
    local selectedEntry = nil
    local results = {}
    local totalCount = 0
    local matchedCount = 0
    local activeSlot = "All"
    local activeSubclass = "All"
    local activeMode = "items"
    local activeEnchantHand = "mh"
    local favoritesOnly = false
    WineMorpherState.previewItems = WineMorpherState.previewItems or {}
    WineMorpherState.previewEnchants = WineMorpherState.previewEnchants or {}
    local previewItems = WineMorpherState.previewItems
    local previewEnchants = WineMorpherState.previewEnchants
    local pageIndex = 1
    local perPage = 12
    local gridCells = {}
    local slotButtons = {}
    local paperdollButtons = {}
    local subclassButtons = {}
    local subclassPage = 1
    local subclasses = {}

    local left = Section(page, "Player Preview", 0, 0, 300, 498)
    local previewModel = CreateFrame("DressUpModel", nil, left)
    previewModel:SetPoint("TOPLEFT", left, "TOPLEFT", 46, -28)
    previewModel:SetPoint("BOTTOMRIGHT", left, "BOTTOMRIGHT", -46, 124)
    previewModel:SetUnit("player")
    previewModel:SetFacing(-0.2)

    local selectedLabel = Label(left, "Select a slot on the model", "GameFontHighlightSmall", {0.88, 0.92, 0.96, 1})
    selectedLabel:SetPoint("BOTTOMLEFT", left, "BOTTOMLEFT", 12, 72)
    selectedLabel:SetWidth(276)
    selectedLabel:SetJustifyH("LEFT")

    local applyButton = MakeButton(left, "Apply", 58, 24)
    applyButton:SetPoint("BOTTOMLEFT", left, "BOTTOMLEFT", 12, 12)
    local applyAllButton = MakeButton(left, "Apply All", 70, 24)
    applyAllButton:SetPoint("LEFT", applyButton, "RIGHT", 6, 0)
    local resetPreview = MakeButton(left, "Reset", 58, 24)
    resetPreview:SetPoint("LEFT", applyButton, "RIGHT", 8, 0)
    resetPreview:ClearAllPoints()
    resetPreview:SetPoint("LEFT", applyAllButton, "RIGHT", 6, 0)
    local undressPreview = MakeButton(left, "Undress", 70, 24)
    undressPreview:SetPoint("LEFT", resetPreview, "RIGHT", 8, 0)

    local SelectSlot
    local ShowEnchantMode
    local function MakePaperdollButton(slotName, x, y)
        local button = MakeIconButton(left, slotIconTextures[slotName], slotName, 34)
        button:SetPoint("TOPLEFT", left, "TOPLEFT", x, y)
        button.slotName = slotName
        button:SetScript("OnClick", function()
            if SelectSlot then
                SelectSlot(slotName)
            end
        end)
        paperdollButtons[slotName] = button
        return button
    end

    MakePaperdollButton("Head", 12, -34)
    MakePaperdollButton("Shoulder", 12, -74)
    MakePaperdollButton("Chest", 12, -114)
    MakePaperdollButton("Hands", 12, -154)
    MakePaperdollButton("Legs", 12, -194)
    MakePaperdollButton("Feet", 12, -234)
    MakePaperdollButton("Back", 254, -34)
    MakePaperdollButton("Waist", 254, -74)
    MakePaperdollButton("Main Hand", 78, -356)
    MakePaperdollButton("Off-hand", 134, -356)
    MakePaperdollButton("Ranged", 190, -356)

    local enchantMHButton = MakeButton(left, "Enchant MH", 88, 24)
    enchantMHButton:SetPoint("BOTTOMLEFT", left, "BOTTOMLEFT", 58, 42)
    enchantMHButton:SetScript("OnClick", function()
        if ShowEnchantMode then
            ShowEnchantMode("mh")
        end
    end)
    local enchantOHButton = MakeButton(left, "Enchant OH", 88, 24)
    enchantOHButton:SetPoint("LEFT", enchantMHButton, "RIGHT", 6, 0)
    enchantOHButton:SetScript("OnClick", function()
        if ShowEnchantMode then
            ShowEnchantMode("oh")
        end
    end)

    local browser = Section(page, "Items", 312, 0, 520, 498)
    local searchInput = MakeInput(browser, 310, 24, "")
    searchInput:SetPoint("TOPLEFT", browser, "TOPLEFT", 12, -28)
    local countLabel = Label(browser, "Loading data...", "GameFontHighlightSmall", {0.66, 0.72, 0.78, 1})
    countLabel:SetPoint("LEFT", searchInput, "RIGHT", 10, 0)
    local favoritesButton = MakeButton(browser, "Favorites", 78, 24)
    favoritesButton:SetPoint("TOPRIGHT", browser, "TOPRIGHT", -12, -28)

    local slotBar = CreateFrame("Frame", nil, browser)
    slotBar:SetPoint("TOPLEFT", browser, "TOPLEFT", 12, -62)
    slotBar:SetPoint("RIGHT", browser, "RIGHT", -12, 0)
    slotBar:SetHeight(52)

    local subclassBar = CreateFrame("Frame", nil, browser)
    subclassBar:SetPoint("TOPLEFT", browser, "TOPLEFT", 12, -118)
    subclassBar:SetPoint("RIGHT", browser, "RIGHT", -12, 0)
    subclassBar:SetHeight(26)
    local subclassPrev = MakeButton(browser, "<", 24, 22)
    subclassPrev:SetPoint("TOPRIGHT", subclassBar, "TOPRIGHT", -28, 0)
    local subclassNext = MakeButton(browser, ">", 24, 22)
    subclassNext:SetPoint("LEFT", subclassPrev, "RIGHT", 4, 0)

    local grid = CreateFrame("Frame", nil, browser)
    grid:SetPoint("TOPLEFT", browser, "TOPLEFT", 12, -150)
    grid:SetPoint("BOTTOMRIGHT", browser, "BOTTOMRIGHT", -12, 44)

    local pageLabel = Label(browser, "Page 0/0", "GameFontHighlightSmall", C.gold)
    pageLabel:SetPoint("BOTTOM", browser, "BOTTOM", 0, 14)
    local prevButton = MakeButton(browser, "<", 34, 24)
    prevButton:SetPoint("RIGHT", pageLabel, "LEFT", -12, 0)
    local nextButton = MakeButton(browser, ">", 34, 24)
    nextButton:SetPoint("LEFT", pageLabel, "RIGHT", 12, 0)

    local function GetPlayerPreviewInfo()
        local _, raceFileName = UnitRace("player")
        return raceFileName or "Human", UnitSex("player") or 2
    end

    local function ApplyModelCamera(model, setup, fallbackFacing)
        if setup then
            if setup.x and setup.y and setup.z then
                pcall(model.SetPosition, model, setup.x, setup.y, setup.z)
            end
            if setup.facing then
                pcall(model.SetFacing, model, setup.facing)
            else
                pcall(model.SetFacing, model, fallbackFacing or -0.2)
            end
            if setup.sequence then
                pcall(model.SetSequence, model, setup.sequence)
            end
        else
            pcall(model.SetPosition, model, 0, 0, 0)
            pcall(model.SetFacing, model, fallbackFacing or -0.2)
        end
    end

    local function ResetPreviewModel(model, setup, fallbackFacing)
        pcall(model.SetPosition, model, 0, 0, 0)
        pcall(model.SetFacing, model, 0)
        pcall(model.ClearModel, model)
        pcall(model.SetUnit, model, "player")
        pcall(model.Undress, model)
        if model.SetLight then
            pcall(model.SetLight, model, 1, 0, 0, 1, 0, 1, 0.7, 0.7, 0.7, 1, 0.8, 0.8, 0.64)
        end
        ApplyModelCamera(model, setup, fallbackFacing)
    end

    local function LockPreviewSequence(model, setup)
        if setup and setup.sequence then
            pcall(model.SetSequence, model, setup.sequence)
            if model.SetScript then
                model:SetScript("OnUpdateModel", function(self)
                    self:SetSequence(setup.sequence)
                end)
            end
        elseif model.SetScript then
            model:SetScript("OnUpdateModel", nil)
        end
    end

    local function GetPreviewSetup(slot, subclass)
        local data = GetData()
        if not data or not data.GetPreviewSetup then
            return nil
        end

        local raceFileName, sex = GetPlayerPreviewInfo()
        local fallbackRaces = {raceFileName, "Human", "BloodElf", "Draenei", "Scourge", "Orc", "Dwarf", "NightElf", "Tauren", "Gnome", "Troll"}
        local fallbackSexes = {sex, 2, 3}
        local seenRaces = {}
        local seenSexes = {}

        local function TryPreviewSetup(race, sexValue)
            local ok, setup = pcall(data.GetPreviewSetup, "classic", race, sexValue, slot or "Head", subclass or "Cloth")
            if ok and setup then
                return setup
            end
            return nil
        end

        for _, race in ipairs(fallbackRaces) do
            if race and not seenRaces[race] then
                seenRaces[race] = true
                for _, sexValue in ipairs(fallbackSexes) do
                    if sexValue and not seenSexes[tostring(race) .. tostring(sexValue)] then
                        seenSexes[tostring(race) .. tostring(sexValue)] = true
                        local setup = TryPreviewSetup(race, sexValue)
                        if setup then
                            return setup
                        end
                    end
                end
            end
        end

        return nil
    end

    local function SetupSingleModel(model, entry)
        local setup = GetPreviewSetup(entry and entry.slot, entry and entry.subclass)
        ResetPreviewModel(model, setup, -0.2)
        if entry and entry.id then
            model:TryOn(entry.id)
        end
        ApplyModelCamera(model, setup, -0.2)
        LockPreviewSequence(model, setup)
    end

    local function GetPreviewWeaponId(hand)
        local slot = hand == "oh" and "Off-hand" or "Main Hand"
        local inventorySlot = hand == "oh" and 17 or 16
        local itemId = previewItems[slot]

        if (not itemId or itemId <= 0) and type(GetInventoryItemID) == "function" then
            itemId = GetInventoryItemID("player", inventorySlot)
        end

        if not itemId or itemId <= 0 then
            if hand == "oh" then
                itemId = previewItems["Main Hand"] or 25
            else
                itemId = 49623
            end
        end

        return itemId
    end

    local function GetWeaponPreviewSubclass(itemId, hand)
        local subclass = nil
        local equipSlot = nil
        if type(GetItemInfo) == "function" then
            local ok, _, _, _, _, _, _, itemSubclass, _, itemEquipSlot = pcall(GetItemInfo, itemId)
            if ok then
                subclass = itemSubclass
                equipSlot = itemEquipSlot
            end
        end

        if not subclass or subclass == "" then
            subclass = "Sword"
        end

        if equipSlot == "INVTYPE_WEAPONOFFHAND" then
            return "OH " .. subclass
        elseif equipSlot == "INVTYPE_WEAPONMAINHAND" then
            return "MH " .. subclass
        elseif equipSlot == "INVTYPE_WEAPON" then
            return "1H " .. subclass
        elseif equipSlot == "INVTYPE_2HWEAPON" then
            return "2H " .. subclass
        elseif equipSlot == "INVTYPE_HOLDABLE" then
            return "Held in Off-hand"
        elseif hand == "oh" then
            return "OH " .. subclass
        end

        return "MH " .. subclass
    end

    local function SetupEnchantModel(model, entry)
        local weaponId = GetPreviewWeaponId(activeEnchantHand)
        local slot = activeEnchantHand == "oh" and "Off-hand" or "Main Hand"
        local subclass = GetWeaponPreviewSubclass(weaponId, activeEnchantHand)
        local setup = GetPreviewSetup(slot, subclass)

        ResetPreviewModel(model, setup, 0)
        model:TryOn(weaponId)
        if entry and entry.id then
            model:TryOn("item:" .. tostring(weaponId) .. ":" .. tostring(entry.id) .. ":0:0:0:0:0:0")
        end
        ApplyModelCamera(model, setup, 0)
        pcall(model.SetSequence, model, 52)
        if model.SetScript then
            model:SetScript("OnUpdateModel", function(self)
                self:SetSequence(52)
            end)
        end
    end

    local function ResetMainPreviewModel()
        previewModel:Show()
        pcall(previewModel.SetAlpha, previewModel, 1)
        pcall(previewModel.SetPosition, previewModel, 0, 0, 0)
        pcall(previewModel.SetFacing, previewModel, 0)
        pcall(previewModel.ClearModel, previewModel)
        pcall(previewModel.SetUnit, previewModel, "player")
        pcall(previewModel.Undress, previewModel)
        pcall(previewModel.SetFacing, previewModel, -0.2)
        if previewModel.SetLight then
            pcall(previewModel.SetLight, previewModel, 1, 0, 0, 1, 0, 1, 0.7, 0.7, 0.7, 1, 0.8, 0.8, 0.64)
        end
    end

    local function RebuildMainPreview(showEquippedWhenEmpty, extraEntry)
        ResetMainPreviewModel()
        local didTryOn = false

        for _, itemId in pairs(previewItems) do
            if itemId and itemId > 0 then
                previewModel:TryOn(itemId)
                didTryOn = true
            end
        end

        if extraEntry and extraEntry.id then
            previewModel:TryOn(extraEntry.id)
            didTryOn = true
        end

        if showEquippedWhenEmpty and not didTryOn and type(GetInventoryItemID) == "function" then
            for _, slot in ipairs(slotList) do
                local itemId = GetInventoryItemID("player", slot[1])
                if itemId and itemId > 0 then
                    previewModel:TryOn(itemId)
                    didTryOn = true
                end
            end
        end

        local mhEnchant = previewEnchants.mh
        local ohEnchant = previewEnchants.oh
        if mhEnchant and mhEnchant > 0 then
            local weaponId = GetPreviewWeaponId("mh")
            previewModel:TryOn("item:" .. tostring(weaponId) .. ":" .. tostring(mhEnchant) .. ":0:0:0:0:0:0")
            didTryOn = true
        end
        if ohEnchant and ohEnchant > 0 then
            local weaponId = GetPreviewWeaponId("oh")
            previewModel:TryOn("item:" .. tostring(weaponId) .. ":" .. tostring(ohEnchant) .. ":0:0:0:0:0:0")
            didTryOn = true
        end
        return didTryOn
    end

    local function RenderPreviewOutfit(extraEntry)
        RebuildMainPreview(true, extraEntry)
    end

    local function RefreshPaperdoll()
        for slotName, button in pairs(paperdollButtons) do
            local itemId = previewItems[slotName]
            if not button.isSlotIcon then
                if itemId and itemId > 0 then
                    button:SetText(slotName .. "*")
                else
                    button:SetText(slotName)
                end
            end

            button.isSelected = activeMode == "items" and activeSlot == slotName
            SetPanelColor(button, button.isSelected and C.active or C.button)
            if button.isSlotIcon then
                local slotId = slotIdsByName[slotName]
                local icon = itemId and itemId > 0 and type(GetItemIcon) == "function" and GetItemIcon(itemId) or nil
                if not icon and slotId and type(GetInventoryItemTexture) == "function" then
                    icon = GetInventoryItemTexture("player", slotId)
                end
                button.icon:SetTexture(icon or slotIconTextures[slotName] or "Interface\\Icons\\INV_Misc_QuestionMark")
                if button.isSelected then
                    SetPanelBorderColor(button, C.gold)
                elseif itemId and itemId > 0 then
                    SetPanelBorderColor(button, C.accent)
                else
                    SetPanelBorderColor(button, C.soft)
                end
            end
        end

        enchantMHButton.isSelected = activeMode == "enchants" and activeEnchantHand == "mh"
        enchantOHButton.isSelected = activeMode == "enchants" and activeEnchantHand == "oh"
        SetPanelColor(enchantMHButton, enchantMHButton.isSelected and C.active or C.button)
        SetPanelColor(enchantOHButton, enchantOHButton.isSelected and C.active or C.button)
    end

    local function PreviewItemEntry(entry)
        selectedEntry = entry
        if selectedEntry then
            selectedEntry.mode = "items"
        end
        if entry and entry.slot then
            previewItems[entry.slot] = entry.id
            selectedLabel:SetText(StripColor(entry.name or "Item") .. "  #" .. tostring(entry.id))
        else
            selectedLabel:SetText("Select an item")
        end
        RebuildMainPreview(true)
        RefreshPaperdoll()
    end

    local function PreviewEnchantEntry(entry)
        selectedEntry = entry
        if selectedEntry then
            selectedEntry.mode = "enchants"
            selectedEntry.hand = activeEnchantHand
        end
        if entry and entry.id then
            previewEnchants[activeEnchantHand] = entry.id
        end
        selectedLabel:SetText(entry and ((entry.name or "Enchant") .. "  #" .. tostring(entry.id)) or "Select an enchant")
        RenderPreviewOutfit(nil)
        RefreshPaperdoll()
    end

    local function Search()
        local data = GetData()
        if not data then
            countLabel:SetText("WineMorpher_Data not loaded")
            return
        end

        dataLoaded = true
        if activeMode == "enchants" then
            if favoritesOnly then
                local list = FavoriteList("enchants", searchInput:GetText())
                results, matchedCount = SliceList(list, perPage, (pageIndex - 1) * perPage)
                totalCount = #list
            else
                results, totalCount, matchedCount = data.SearchEnchants(searchInput:GetText(), perPage, (pageIndex - 1) * perPage)
            end
            countLabel:SetText(tostring(matchedCount) .. " enchants / " .. tostring(totalCount) .. " indexed")
        else
            if favoritesOnly then
                local list = FavoriteList("items", searchInput:GetText(), function(entry)
                    local slotOk = activeSlot == "All" or entry.slot == activeSlot
                    local subclassOk = activeSubclass == "All" or entry.subclass == activeSubclass
                    return slotOk and subclassOk
                end)
                results, matchedCount = SliceList(list, perPage, (pageIndex - 1) * perPage)
                totalCount = #list
            else
                results, totalCount, matchedCount = data.SearchItems(searchInput:GetText(), activeSlot, activeSubclass, perPage, (pageIndex - 1) * perPage)
            end
            countLabel:SetText(tostring(matchedCount) .. " results / " .. tostring(totalCount) .. " indexed")
        end
        favoritesButton.isSelected = favoritesOnly
        SetPanelColor(favoritesButton, favoritesOnly and C.active or C.button)

        for i, cell in ipairs(gridCells) do
            local entry = results[i]
            cell.entry = entry
            if entry then
                cell:Show()
                if activeMode == "enchants" then
                    cell.title:SetText(entry.name)
                    cell.meta:SetText((IsFavorite("enchants", entry) and "* " or "") .. "enchant #" .. tostring(entry.id))
                    SetPanelBorderColor(cell, C.soft)
                    cell.model:Show()
                    SetupEnchantModel(cell.model, entry)
                else
                    cell.title:SetText(StripColor(entry.name))
                    cell.meta:SetText((IsFavorite("items", entry) and "* " or "") .. tostring(entry.subclass) .. " #" .. tostring(entry.id))
                    SetPanelBorderColor(cell, ColorFromItemName(entry.name))
                    cell.model:Show()
                    SetupSingleModel(cell.model, entry)
                end
                if selectedEntry and selectedEntry.id == entry.id and selectedEntry.mode == activeMode then
                    SetPanelColor(cell, C.active)
                    SetPanelBorderColor(cell, C.gold)
                else
                    SetPanelColor(cell, cell.normalColor or C.panel2)
                end
            else
                cell:Hide()
            end
        end
        local pages = math.max(1, math.ceil((matchedCount or 0) / perPage))
        pageLabel:SetText("Page " .. tostring(pageIndex) .. "/" .. tostring(pages))
    end

    local function RefreshSubclasses()
        local data = GetData()
        subclasses = {"All"}
        if data and data.GetItemSubclasses then
            local list = data.GetItemSubclasses(activeSlot)
            for _, subclass in ipairs(list) do
                table.insert(subclasses, subclass)
            end
        end
        if subclassPage < 1 then subclassPage = 1 end
        local maxPage = math.max(1, math.ceil(#subclasses / 4))
        if subclassPage > maxPage then subclassPage = maxPage end
        activeSubclass = "All"

        for _, button in ipairs(subclassButtons) do
            button:Hide()
        end

        for i = 1, 4 do
            local index = (subclassPage - 1) * 4 + i
            local subclass = subclasses[index]
            local button = subclassButtons[i]
            if not button then
                button = MakeButton(subclassBar, "", 98, 22)
                button:SetPoint("LEFT", subclassBar, "LEFT", (i - 1) * 104, 0)
                subclassButtons[i] = button
            end
            if subclass then
                button.subclass = subclass
                button:SetText(subclass)
                button.isSelected = subclass == activeSubclass
                SetPanelColor(button, button.isSelected and C.active or C.button)
                button:SetScript("OnClick", function(self)
                    activeSubclass = self.subclass
                    pageIndex = 1
                    for _, b in ipairs(subclassButtons) do
                        if b:IsShown() then
                            b.isSelected = b.subclass == activeSubclass
                            SetPanelColor(b, b.isSelected and C.active or C.button)
                        end
                    end
                    Search()
                end)
                button:Show()
            end
        end
    end

    SelectSlot = function(slotName)
        activeMode = "items"
        activeSlot = slotName or "All"
        pageIndex = 1
        subclassPage = 1
        selectedEntry = nil

        for _, b in ipairs(slotButtons) do
            b.isSelected = b.slotName == activeSlot
            SetPanelColor(b, b.isSelected and C.active or C.button)
        end

        RefreshSubclasses()
        subclassPrev:Show()
        subclassNext:Show()
        RefreshPaperdoll()
        Search()
    end

    ShowEnchantMode = function(hand)
        activeMode = "enchants"
        activeEnchantHand = hand or "mh"
        pageIndex = 1
        selectedEntry = nil
        for _, b in ipairs(slotButtons) do
            b.isSelected = false
            SetPanelColor(b, C.button)
        end
        for _, b in ipairs(subclassButtons) do
            b:Hide()
        end
        subclassPrev:Hide()
        subclassNext:Hide()
        RefreshPaperdoll()
        Search()
    end

    local slotNamesForTabs = {"All", "Head", "Shoulder", "Chest", "Hands", "Waist", "Legs", "Feet", "Main Hand", "Off-hand", "Ranged", "Back"}
    for index, slotName in ipairs(slotNamesForTabs) do
        local button = MakeButton(slotBar, slotName, index >= 9 and 68 or 58, 22)
        local col = (index - 1) % 6
        local row = math.floor((index - 1) / 6)
        button:SetPoint("TOPLEFT", slotBar, "TOPLEFT", col * 78, -row * 26)
        button.slotName = slotName
        table.insert(slotButtons, button)
        button:SetScript("OnClick", function()
            SelectSlot(slotName)
        end)
    end

    subclassPrev:SetScript("OnClick", function()
        if subclassPage > 1 then
            subclassPage = subclassPage - 1
            RefreshSubclasses()
            Search()
        end
    end)
    subclassNext:SetScript("OnClick", function()
        local maxPage = math.max(1, math.ceil(#subclasses / 4))
        if subclassPage < maxPage then
            subclassPage = subclassPage + 1
            RefreshSubclasses()
            Search()
        end
    end)

    favoritesButton:SetScript("OnClick", function()
        favoritesOnly = not favoritesOnly
        pageIndex = 1
        Search()
    end)

    for i = 1, perPage do
        local cell = CreateFrame("Button", nil, grid)
        cell:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        cell:SetWidth(116)
        cell:SetHeight(96)
        cell.normalColor = C.panel2
        SkinPanel(cell, C.panel2, C.soft)
        local col = (i - 1) % 4
        local row = math.floor((i - 1) / 4)
        cell:SetPoint("TOPLEFT", grid, "TOPLEFT", col * 124, -row * 102)
        cell.model = CreateFrame("DressUpModel", nil, cell)
        cell.model:SetPoint("TOPLEFT", cell, "TOPLEFT", 2, -2)
        cell.model:SetPoint("BOTTOMRIGHT", cell, "BOTTOMRIGHT", -2, 2)
        cell.model:SetUnit("player")
        if cell.model.EnableMouse then
            cell.model:EnableMouse(false)
        end
        cell.title = Label(cell, "", "GameFontHighlightSmall", {0.90, 0.92, 0.95, 1})
        cell.title:SetPoint("BOTTOMLEFT", cell, "BOTTOMLEFT", 5, 11)
        cell.title:SetWidth(106)
        cell.title:SetJustifyH("LEFT")
        cell.title:Hide()
        cell.meta = Label(cell, "", "GameFontHighlightSmall", {0.58, 0.66, 0.72, 1})
        cell.meta:SetPoint("BOTTOMLEFT", cell, "BOTTOMLEFT", 5, 2)
        cell.meta:SetWidth(106)
        cell.meta:SetJustifyH("LEFT")
        cell.meta:Hide()
        cell:SetScript("OnClick", function(self, mouseButton)
            if not self.entry then
                return
            end
            if mouseButton == "RightButton" then
                ToggleFavorite(activeMode == "enchants" and "enchants" or "items", self.entry)
                Search()
                return
            end
            if activeMode == "items" and type(IsShiftKeyDown) == "function" and IsShiftKeyDown() then
                ShowCopyDialog("Wowhead item URL", WowheadItemUrl(self.entry.id))
                return
            end
            if activeMode == "enchants" then
                PreviewEnchantEntry(self.entry)
            else
                PreviewItemEntry(self.entry)
            end
            Search()
        end)
        cell:SetScript("OnEnter", function(self)
            if self.entry then
                SetPanelColor(self, C.hover)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                if activeMode == "enchants" then
                    GameTooltip:AddLine(self.entry.name or "Enchant", C.gold[1], C.gold[2], C.gold[3])
                    GameTooltip:AddLine("Enchant ID: " .. tostring(self.entry.id), 1, 1, 1)
                    GameTooltip:AddLine("Target: " .. string.upper(activeEnchantHand), 0.7, 0.8, 0.9)
                    GameTooltip:AddLine("Right click: favorite", C.gold[1], C.gold[2], C.gold[3])
                else
                    GameTooltip:AddLine(self.entry.name or "Item")
                    GameTooltip:AddLine("Item ID: " .. tostring(self.entry.id), 1, 1, 1)
                    GameTooltip:AddLine("Slot: " .. tostring(self.entry.slot), 0.7, 0.8, 0.9)
                    GameTooltip:AddLine("Subclass: " .. tostring(self.entry.subclass), 0.7, 0.8, 0.9)
                    GameTooltip:AddLine("Shift click: copy Wowhead URL", C.gold[1], C.gold[2], C.gold[3])
                    GameTooltip:AddLine("Right click: favorite", C.gold[1], C.gold[2], C.gold[3])
                    if self.entry.names and #self.entry.names > 1 then
                        GameTooltip:AddLine("Same appearance:", 0.55, 0.62, 0.70)
                        for i = 2, math.min(#self.entry.names, 5) do
                            local itemId = self.entry.ids and self.entry.ids[i] or "?"
                            GameTooltip:AddLine(StripColor(self.entry.names[i]) .. "  #" .. tostring(itemId), 0.75, 0.80, 0.86)
                        end
                    end
                end
                GameTooltip:Show()
            end
        end)
        cell:SetScript("OnLeave", function(self)
            if selectedEntry and self.entry and selectedEntry.id == self.entry.id then
                SetPanelColor(self, C.active)
                SetPanelBorderColor(self, C.gold)
            else
                SetPanelColor(self, self.normalColor or C.panel2)
                if activeMode == "items" and self.entry then
                    SetPanelBorderColor(self, ColorFromItemName(self.entry.name))
                else
                    SetPanelBorderColor(self, C.soft)
                end
            end
            GameTooltip:Hide()
        end)
        gridCells[i] = cell
    end

    applyButton:SetScript("OnClick", function()
        if not selectedEntry then
            WM.Print("Select an item or enchant first.")
            return
        end

        if activeMode == "enchants" then
            if activeEnchantHand == "mh" then
                Send("ENCHANT_MH:" .. tostring(selectedEntry.id))
            else
                Send("ENCHANT_OH:" .. tostring(selectedEntry.id))
            end
            return
        end

        local slotId = slotIdsByName[selectedEntry.slot]
        if not slotId then
            WM.Print("No WineMorpher slot mapping for " .. tostring(selectedEntry.slot) .. ".")
            return
        end

        Send("ITEM:" .. tostring(slotId) .. ":" .. tostring(selectedEntry.id))
    end)

    applyAllButton:SetScript("OnClick", function()
        local commands = BuildPreviewCommands(previewItems, previewEnchants)

        if #commands == 0 then
            WM.Print("No preview items to apply.")
            return
        end

        SendMany(commands)
    end)

    resetPreview:SetScript("OnClick", function()
        for slotName in pairs(previewItems) do
            previewItems[slotName] = nil
        end
        for key in pairs(previewEnchants) do
            previewEnchants[key] = nil
        end
        selectedEntry = nil
        selectedLabel:SetText("Preview cleared")
        RenderPreviewOutfit(nil)
        RefreshPaperdoll()
        local commands = {"RESET:ALL", "ENCHANT_RESET", "MOUNT:0", "HPET_RESET"}
        for _, slot in ipairs(slotList) do
            table.insert(commands, "ITEM:" .. tostring(slot[1]) .. ":0")
        end
        SendMany(commands)
    end)
    undressPreview:SetScript("OnClick", function()
        for slotName in pairs(previewItems) do
            previewItems[slotName] = nil
        end
        for key in pairs(previewEnchants) do
            previewEnchants[key] = nil
        end
        RebuildMainPreview(false)
        RefreshPaperdoll()
    end)
    prevButton:SetScript("OnClick", function()
        if pageIndex > 1 then
            pageIndex = pageIndex - 1
            Search()
        end
    end)
    nextButton:SetScript("OnClick", function()
        local pages = math.max(1, math.ceil((matchedCount or 0) / perPage))
        if pageIndex < pages then
            pageIndex = pageIndex + 1
            Search()
        end
    end)

    searchInput:SetScript("OnTextChanged", function()
        if dataLoaded then
            pageIndex = 1
            Search()
        end
    end)
    searchInput:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        Search()
    end)

    page:SetScript("OnShow", function()
        RenderPreviewOutfit(nil)
        RefreshPaperdoll()
        if not dataLoaded then
            for _, button in ipairs(slotButtons) do
                button.isSelected = button.slotName == activeSlot
                SetPanelColor(button, button.isSelected and C.active or C.button)
            end
            RefreshSubclasses()
            Search()
        end
    end)

    WM.RefreshPreview = function()
        RenderPreviewOutfit(nil)
        RefreshPaperdoll()
        if dataLoaded then
            Search()
        end
    end

    return page
end

local function CreateLoadoutsPage(parent)
    local page = MakePage(parent)
    local loadouts = EnsureLoadouts()
    local selectedName = nil
    local rows = {}
    local detailLines = {}

    local list = Section(page, "Saved Sets", 0, 0, 260, 498)
    local nameInput = MakeInput(list, 150, 24, "")
    nameInput:SetPoint("TOPLEFT", list, "TOPLEFT", 12, -30)
    local saveButton = MakeButton(list, "Save As", 78, 24)
    saveButton:SetPoint("LEFT", nameInput, "RIGHT", 8, 0)

    local updateButton = MakeButton(list, "Update", 72, 24)
    updateButton:SetPoint("TOPLEFT", list, "TOPLEFT", 12, -62)
    local deleteButton = MakeButton(list, "Delete", 72, 24)
    deleteButton:SetPoint("LEFT", updateButton, "RIGHT", 8, 0)
    local importButton = MakeButton(list, "Import", 72, 24)
    importButton:SetPoint("LEFT", deleteButton, "RIGHT", 8, 0)

    local detail = Section(page, "Loadout Preview", 272, 0, 560, 498)
    local selectedTitle = Label(detail, "No set selected", "GameFontNormal", C.gold)
    selectedTitle:SetPoint("TOPLEFT", detail, "TOPLEFT", 12, -34)
    selectedTitle:SetWidth(420)
    selectedTitle:SetJustifyH("LEFT")

    local loadPreviewButton = MakeButton(detail, "Load To Preview", 116, 24)
    loadPreviewButton:SetPoint("TOPRIGHT", detail, "TOPRIGHT", -12, -30)
    local applyButton = MakeButton(detail, "Apply Set", 92, 24)
    applyButton:SetPoint("RIGHT", loadPreviewButton, "LEFT", -8, 0)
    local exportButton = MakeButton(detail, "Export", 78, 24)
    exportButton:SetPoint("RIGHT", applyButton, "LEFT", -8, 0)

    local function SortedLoadoutNames()
        local names = {}
        for name in pairs(loadouts) do
            table.insert(names, name)
        end
        table.sort(names)
        return names
    end

    local function CurrentPreviewHasData()
        for _, itemId in pairs(WineMorpherState.previewItems or {}) do
            if itemId and itemId > 0 then
                return true
            end
        end
        for _, enchantId in pairs(WineMorpherState.previewEnchants or {}) do
            if enchantId and enchantId > 0 then
                return true
            end
        end
        return false
    end

    local function SaveFromPreview(name)
        name = tostring(name or "")
        name = string.gsub(name, "^%s+", "")
        name = string.gsub(name, "%s+$", "")
        if name == "" then
            WM.Print("Enter a loadout name.")
            return false
        end
        if not CurrentPreviewHasData() then
            WM.Print("Build a preview outfit first.")
            return false
        end

        loadouts[name] = {
            items = CopyNumberMap(WineMorpherState.previewItems),
            enchants = CopyNumberMap(WineMorpherState.previewEnchants),
        }
        selectedName = name
        nameInput:SetText(name)
        WM.Print("Saved loadout: " .. name)
        return true
    end

    local function LoadToPreview(loadout)
        WineMorpherState.previewItems = WineMorpherState.previewItems or {}
        WineMorpherState.previewEnchants = WineMorpherState.previewEnchants or {}
        for key in pairs(WineMorpherState.previewItems) do
            WineMorpherState.previewItems[key] = nil
        end
        for key in pairs(WineMorpherState.previewEnchants) do
            WineMorpherState.previewEnchants[key] = nil
        end
        for key, value in pairs(loadout.items or {}) do
            WineMorpherState.previewItems[key] = value
        end
        for key, value in pairs(loadout.enchants or {}) do
            WineMorpherState.previewEnchants[key] = value
        end
        if WM.RefreshPreview then
            WM.RefreshPreview()
        end
    end

    local Refresh
    local function SelectLoadout(name)
        selectedName = name
        nameInput:SetText(name or "")
        if Refresh then
            Refresh()
        end
    end

    local function SetDetailLine(index, text, color)
        local line = detailLines[index]
        if not line then
            line = Label(detail, "", "GameFontHighlightSmall", color or {0.82, 0.86, 0.90, 1})
            line:SetPoint("TOPLEFT", detail, "TOPLEFT", 16, -70 - (index - 1) * 22)
            line:SetWidth(520)
            line:SetJustifyH("LEFT")
            detailLines[index] = line
        end
        line:SetText(text or "")
        if color then
            line:SetTextColor(color[1], color[2], color[3], color[4] or 1)
        end
        line:Show()
    end

    local function RenderDetails()
        for _, line in ipairs(detailLines) do
            line:Hide()
        end

        local loadout = selectedName and loadouts[selectedName]
        if not loadout then
            selectedTitle:SetText("No set selected")
            SetDetailLine(1, "Save the current Preview outfit, then select it here.", {0.66, 0.72, 0.78, 1})
            return
        end

        selectedTitle:SetText(selectedName)
        local lineIndex = 1
        local detailSlots = {"Head", "Shoulder", "Chest", "Waist", "Legs", "Feet", "Wrist", "Hands", "Back", "Main Hand", "Off-hand", "Ranged", "Tabard"}
        for _, slotName in ipairs(detailSlots) do
            local itemId = loadout.items and loadout.items[slotName]
            if itemId and itemId > 0 then
                local itemName = GetItemInfo(itemId) or ("Item #" .. tostring(itemId))
                SetDetailLine(lineIndex, slotName .. ": " .. itemName .. "  #" .. tostring(itemId), {0.86, 0.90, 0.94, 1})
                lineIndex = lineIndex + 1
            end
        end

        if loadout.enchants and loadout.enchants.mh and loadout.enchants.mh > 0 then
            SetDetailLine(lineIndex, "Enchant MH: #" .. tostring(loadout.enchants.mh), C.gold)
            lineIndex = lineIndex + 1
        end
        if loadout.enchants and loadout.enchants.oh and loadout.enchants.oh > 0 then
            SetDetailLine(lineIndex, "Enchant OH: #" .. tostring(loadout.enchants.oh), C.gold)
            lineIndex = lineIndex + 1
        end
        if lineIndex == 1 then
            SetDetailLine(1, "This set is empty.", {0.66, 0.72, 0.78, 1})
        end
    end

    Refresh = function()
        local names = SortedLoadoutNames()
        for _, row in ipairs(rows) do
            row:Hide()
        end

        for index = 1, 12 do
            local name = names[index]
            local row = rows[index]
            if not row then
                row = MakeButton(list, "", 232, 26)
                row:SetPoint("TOPLEFT", list, "TOPLEFT", 12, -100 - (index - 1) * 30)
                row.label = Label(row, "", "GameFontHighlightSmall", {0.90, 0.94, 0.98, 1})
                row.label:SetPoint("LEFT", row, "LEFT", 8, 0)
                row.label:SetWidth(216)
                row.label:SetJustifyH("LEFT")
                row:SetScript("OnClick", function(self)
                    SelectLoadout(self.loadoutName)
                end)
                rows[index] = row
            end

            if name then
                row.loadoutName = name
                row.label:SetText(name)
                row.isSelected = name == selectedName
                SetPanelColor(row, row.isSelected and C.active or C.button)
                row:Show()
            end
        end

        if selectedName and not loadouts[selectedName] then
            selectedName = nil
        end
        RenderDetails()
    end

    saveButton:SetScript("OnClick", function()
        if SaveFromPreview(nameInput:GetText()) then
            Refresh()
        end
    end)

    updateButton:SetScript("OnClick", function()
        local name = selectedName or nameInput:GetText()
        if SaveFromPreview(name) then
            Refresh()
        end
    end)

    deleteButton:SetScript("OnClick", function()
        if not selectedName or not loadouts[selectedName] then
            WM.Print("Select a loadout first.")
            return
        end
        loadouts[selectedName] = nil
        WM.Print("Deleted loadout: " .. selectedName)
        selectedName = nil
        Refresh()
    end)

    importButton:SetScript("OnClick", function()
        ShowTextInputDialog("Import WineMorpher loadout", "", function(value)
            local name, loadoutOrError = DecodeLoadout(value)
            if not name then
                WM.Print(loadoutOrError or "Invalid loadout string.")
                return
            end
            loadouts[name] = loadoutOrError
            selectedName = name
            nameInput:SetText(name)
            WM.Print("Imported loadout: " .. name)
            Refresh()
        end)
    end)

    exportButton:SetScript("OnClick", function()
        local loadout = selectedName and loadouts[selectedName]
        if not loadout then
            WM.Print("Select a loadout first.")
            return
        end
        ShowCopyDialog("Export loadout", EncodeLoadout(selectedName, loadout))
    end)

    loadPreviewButton:SetScript("OnClick", function()
        local loadout = selectedName and loadouts[selectedName]
        if not loadout then
            WM.Print("Select a loadout first.")
            return
        end
        LoadToPreview(loadout)
        WM.Print("Loaded to Preview: " .. selectedName)
    end)

    applyButton:SetScript("OnClick", function()
        local loadout = selectedName and loadouts[selectedName]
        if not loadout then
            WM.Print("Select a loadout first.")
            return
        end
        local commands = BuildPreviewCommands(loadout.items, loadout.enchants)
        if #commands == 0 then
            WM.Print("Selected loadout is empty.")
            return
        end
        SendMany(commands)
    end)

    page:SetScript("OnShow", Refresh)
    Refresh()
    return page
end

local function CreateSetsPage(parent)
    local page = MakePage(parent)
    local results = {}
    local rows = {}
    local selectedSet = nil
    local activeClass = "ALL"
    local dataLoaded = false
    local pageIndex = 1
    local perPage = 11
    local matchedCount = 0
    local favoritesOnly = false

    local list = Section(page, "Item Sets", 0, 0, 320, 498)
    local search = MakeInput(list, 188, 24, "")
    search:SetPoint("TOPLEFT", list, "TOPLEFT", 12, -28)
    local favoritesButton = MakeButton(list, "Favorites", 78, 24)
    favoritesButton:SetPoint("TOPRIGHT", list, "TOPRIGHT", -12, -28)
    local classButtons = {}
    local classes = {{"ALL", "All"}, {"WARRIOR", "Warrior"}, {"PALADIN", "Paladin"}, {"HUNTER", "Hunter"}, {"ROGUE", "Rogue"}, {"PRIEST", "Priest"}, {"DEATHKNIGHT", "DK"}, {"SHAMAN", "Shaman"}, {"MAGE", "Mage"}, {"WARLOCK", "Warlock"}, {"DRUID", "Druid"}}
    for i, item in ipairs(classes) do
        local button = MakeButton(list, item[2], 58, 22)
        local col = (i - 1) % 5
        local row = math.floor((i - 1) / 5)
        button:SetPoint("TOPLEFT", list, "TOPLEFT", 12 + col * 60, -60 - row * 24)
        button.classKey = item[1]
        classButtons[i] = button
    end
    local countLabel = Label(list, "Available Sets: 0", "GameFontHighlightSmall", {0.66, 0.72, 0.78, 1})
    countLabel:SetPoint("TOPLEFT", list, "TOPLEFT", 12, -132)
    local pageLabel = Label(list, "Page 1/1", "GameFontHighlightSmall", C.gold)
    pageLabel:SetPoint("BOTTOM", list, "BOTTOM", 0, 12)
    local prevButton = MakeButton(list, "<", 34, 22)
    prevButton:SetPoint("RIGHT", pageLabel, "LEFT", -10, 0)
    local nextButton = MakeButton(list, ">", 34, 22)
    nextButton:SetPoint("LEFT", pageLabel, "RIGHT", 10, 0)

    local preview = Section(page, "Set Preview", 332, 0, 500, 498)
    local model = CreateFrame("DressUpModel", nil, preview)
    model:SetPoint("TOPLEFT", preview, "TOPLEFT", 24, -34)
    model:SetPoint("BOTTOMRIGHT", preview, "BOTTOMRIGHT", -150, 80)
    model:SetUnit("player")
    model:SetFacing(-0.2)
    local title = Label(preview, "Select a set", "GameFontNormal", C.gold)
    title:SetPoint("TOPRIGHT", preview, "TOPRIGHT", -16, -42)
    title:SetWidth(180)
    title:SetJustifyH("CENTER")
    local desc = Label(preview, "", "GameFontHighlightSmall", {0.82, 0.86, 0.90, 1})
    desc:SetPoint("TOP", title, "BOTTOM", 0, -8)
    desc:SetWidth(180)
    desc:SetJustifyH("CENTER")
    local apply = MakeButton(preview, "Apply Set", 112, 28)
    apply:SetPoint("TOP", desc, "BOTTOM", 0, -18)
    local loadPreview = MakeButton(preview, "Load Preview", 112, 24)
    loadPreview:SetPoint("TOP", apply, "BOTTOM", 0, -8)

    local function LoadSetToPreview(setData)
        WineMorpherState.previewItems = WineMorpherState.previewItems or {}
        for _, item in ipairs(setData.items or {}) do
            WineMorpherState.previewItems[item.slot] = item.itemId
        end
        if WM.RefreshPreview then
            WM.RefreshPreview()
        end
    end

    local function SelectSet(setData)
        selectedSet = setData
        model:ClearModel()
        model:SetUnit("player")
        model:Undress()
        for _, item in ipairs(setData.items or {}) do
            model:TryOn(item.itemId)
        end
        title:SetText(setData.name or "Set")
        desc:SetText(setData.description or "")
    end

    local SearchSets
    local function BuildRows()
        for _, row in ipairs(rows) do row:Hide() end
        for i = 1, perPage do
            local setData = results[i]
            local row = rows[i]
            if not row then
                row = MakeButton(list, "", 292, 24)
                row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
                row:SetPoint("TOPLEFT", list, "TOPLEFT", 12, -156 - (i - 1) * 26)
                row.icon = row:CreateTexture(nil, "ARTWORK")
                row.icon:SetWidth(20); row.icon:SetHeight(20)
                row.icon:SetPoint("LEFT", row, "LEFT", 4, 0)
                row.name = Label(row, "", "GameFontHighlightSmall", C.gold)
                row.name:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
                row.name:SetWidth(190)
                row.name:SetJustifyH("LEFT")
                row.meta = Label(row, "", "GameFontHighlightSmall", {0.58, 0.66, 0.72, 1})
                row.meta:SetPoint("RIGHT", row, "RIGHT", -8, 0)
                row:SetScript("OnClick", function(self, mouseButton)
                    if mouseButton == "RightButton" then
                        ToggleFavorite("sets", self.setData, self.setData and self.setData.name)
                        SearchSets()
                    else
                        SelectSet(self.setData)
                    end
                end)
                rows[i] = row
            end
            if setData then
                row.setData = setData
                row.name:SetText((IsFavorite("sets", setData, setData.name) and "* " or "") .. tostring(setData.name))
                row.meta:SetText(setData.description or "")
                local iconItem = setData.items and setData.items[1] and setData.items[1].itemId
                row.icon:SetTexture(iconItem and type(GetItemIcon) == "function" and GetItemIcon(iconItem) or "Interface\\Icons\\INV_Chest_Plate04")
                row:Show()
            end
        end
    end

    SearchSets = function()
        local data = GetData()
        if not data or not data.SearchItemSets then
            countLabel:SetText("WineMorpher_Data not loaded")
            return
        end
        dataLoaded = true
        local total
        if favoritesOnly then
            local list = FavoriteList("sets", search:GetText(), function(entry)
                return activeClass == "ALL" or entry.class == activeClass
            end)
            results, matchedCount = SliceList(list, perPage, (pageIndex - 1) * perPage)
            total = #list
        else
            results, total, matchedCount = data.SearchItemSets(search:GetText(), activeClass, perPage, (pageIndex - 1) * perPage)
        end
        local pages = math.max(1, math.ceil((matchedCount or 0) / perPage))
        if pageIndex > pages then pageIndex = pages end
        countLabel:SetText("Available Sets: " .. tostring(matchedCount or 0))
        pageLabel:SetText("Page " .. tostring(pageIndex) .. "/" .. tostring(pages))
        favoritesButton.isSelected = favoritesOnly
        SetPanelColor(favoritesButton, favoritesOnly and C.active or C.button)
        for _, button in ipairs(classButtons) do
            button.isSelected = button.classKey == activeClass
            SetPanelColor(button, button.isSelected and C.active or C.button)
        end
        BuildRows()
    end

    for _, button in ipairs(classButtons) do
        button:SetScript("OnClick", function(self)
            activeClass = self.classKey
            pageIndex = 1
            SearchSets()
        end)
    end
    favoritesButton:SetScript("OnClick", function()
        favoritesOnly = not favoritesOnly
        pageIndex = 1
        SearchSets()
    end)
    search:SetScript("OnTextChanged", function()
        if dataLoaded then pageIndex = 1; SearchSets() end
    end)
    prevButton:SetScript("OnClick", function()
        if pageIndex > 1 then pageIndex = pageIndex - 1; SearchSets() end
    end)
    nextButton:SetScript("OnClick", function()
        local pages = math.max(1, math.ceil((matchedCount or 0) / perPage))
        if pageIndex < pages then
            pageIndex = pageIndex + 1
            SearchSets()
        end
    end)
    loadPreview:SetScript("OnClick", function()
        if selectedSet then LoadSetToPreview(selectedSet) end
    end)
    apply:SetScript("OnClick", function()
        if selectedSet then
            LoadSetToPreview(selectedSet)
            SendMany(BuildPreviewCommands(WineMorpherState.previewItems, WineMorpherState.previewEnchants))
        end
    end)
    page:SetScript("OnShow", function()
        if not dataLoaded then SearchSets() end
    end)
    return page
end

local function CreateTitlesPage(parent)
    local page = MakePage(parent)
    local rows = {}
    local results = {}
    local pageIndex = 1
    local perPage = 16
    local matched = 0
    local dataLoaded = false
    local favoritesOnly = false

    local list = Section(page, "Titles", 0, 0, 540, 498)
    local search = MakeInput(list, 240, 24, "")
    search:SetPoint("TOPLEFT", list, "TOPLEFT", 12, -28)
    local countLabel = Label(list, "Search titles", "GameFontHighlightSmall", {0.66, 0.72, 0.78, 1})
    countLabel:SetPoint("LEFT", search, "RIGHT", 10, 0)
    local reset = MakeButton(list, "Reset", 72, 24)
    reset:SetPoint("TOPRIGHT", list, "TOPRIGHT", -12, -28)
    local favoritesButton = MakeButton(list, "Favorites", 78, 24)
    favoritesButton:SetPoint("RIGHT", reset, "LEFT", -8, 0)
    local pageLabel = Label(list, "Page 1/1", "GameFontHighlightSmall", C.gold)
    pageLabel:SetPoint("BOTTOM", list, "BOTTOM", 0, 12)
    local prev = MakeButton(list, "<", 34, 22)
    prev:SetPoint("RIGHT", pageLabel, "LEFT", -10, 0)
    local next = MakeButton(list, ">", 34, 22)
    next:SetPoint("LEFT", pageLabel, "RIGHT", 10, 0)

    local function ApplyTitle(entry)
        WineMorpherState.titleID = entry.id
        if type(SetCurrentTitle) == "function" then
            pcall(SetCurrentTitle, entry.id)
        end
        Send("TITLE:" .. tostring(entry.id))
    end

    local SearchTitles
    local function BuildRows()
        for _, row in ipairs(rows) do row:Hide() end
        for i = 1, perPage do
            local entry = results[i]
            local row = rows[i]
            if not row then
                row = MakeButton(list, "", 500, 22)
                row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
                row:SetPoint("TOPLEFT", list, "TOPLEFT", 12, -64 - (i - 1) * 24)
                row.name = Label(row, "", "GameFontHighlightSmall", {0.92, 0.94, 0.96, 1})
                row.name:SetPoint("LEFT", row, "LEFT", 8, 0)
                row.name:SetWidth(380)
                row.name:SetJustifyH("LEFT")
                row.id = Label(row, "", "GameFontHighlightSmall", {0.58, 0.66, 0.72, 1})
                row.id:SetPoint("RIGHT", row, "RIGHT", -8, 0)
                row:SetScript("OnClick", function(self, mouseButton)
                    if mouseButton == "RightButton" then
                        ToggleFavorite("titles", self.entry)
                        SearchTitles()
                    else
                        ApplyTitle(self.entry)
                    end
                end)
                rows[i] = row
            end
            if entry then
                row.entry = entry
                row.name:SetText((IsFavorite("titles", entry) and "* " or "") .. tostring(entry.name))
                row.id:SetText("#" .. tostring(entry.id))
                row:Show()
            end
        end
    end

    SearchTitles = function()
        local data = GetData()
        if not data or not data.SearchTitles then
            countLabel:SetText("WineMorpher_Data not loaded")
            return
        end
        dataLoaded = true
        local total
        if favoritesOnly then
            local list = FavoriteList("titles", search:GetText())
            results, matched = SliceList(list, perPage, (pageIndex - 1) * perPage)
            total = #list
        else
            results, total, matched = data.SearchTitles(search:GetText(), perPage, (pageIndex - 1) * perPage)
        end
        local pages = math.max(1, math.ceil((matched or 0) / perPage))
        if pageIndex > pages then pageIndex = pages end
        countLabel:SetText(tostring(matched or 0) .. " found / " .. tostring(total or 0))
        pageLabel:SetText("Page " .. tostring(pageIndex) .. "/" .. tostring(pages))
        favoritesButton.isSelected = favoritesOnly
        SetPanelColor(favoritesButton, favoritesOnly and C.active or C.button)
        BuildRows()
    end

    search:SetScript("OnTextChanged", function()
        if dataLoaded then pageIndex = 1; SearchTitles() end
    end)
    prev:SetScript("OnClick", function()
        if pageIndex > 1 then pageIndex = pageIndex - 1; SearchTitles() end
    end)
    next:SetScript("OnClick", function()
        local pages = math.max(1, math.ceil((matched or 0) / perPage))
        if pageIndex < pages then
            pageIndex = pageIndex + 1
            SearchTitles()
        end
    end)
    reset:SetScript("OnClick", function()
        WineMorpherState.titleID = nil
        if type(SetCurrentTitle) == "function" then pcall(SetCurrentTitle, 0) end
        Send("TITLE_RESET")
    end)
    favoritesButton:SetScript("OnClick", function()
        favoritesOnly = not favoritesOnly
        pageIndex = 1
        SearchTitles()
    end)
    page:SetScript("OnShow", function()
        if not dataLoaded then SearchTitles() end
    end)
    return page
end

local function CreateSimplePage(parent, title, message)
    local page = MakePage(parent)
    local section = Section(page, title, 0, 0, 500, 116)
    local label = Label(section, message, "GameFontHighlightSmall", {0.80, 0.84, 0.88, 1})
    label:SetPoint("TOPLEFT", section, "TOPLEFT", 12, -38)
    label:SetWidth(470)
    label:SetJustifyH("LEFT")
    return page
end

local function CreateSettingsPage(parent)
    local page = MakePage(parent)
    local section = Section(page, "Status", 0, 0, 500, 184)
    local elvui = type(_G.ElvUI) == "table" and "detected" or "not detected"
    local media = RefreshMedia()
    local lsm = media.lsm and "detected" or "not detected"
    local font = media.fontName or "default"
    local texture = media.barName or "flat fallback"
    local status = WINEMORPHER_DLL_LOADED == "TRUE" and "loaded" or "not loaded"

    local line1 = Label(section, "Skin: Standalone dark", "GameFontHighlightSmall", {0.86, 0.90, 0.94, 1})
    line1:SetPoint("TOPLEFT", section, "TOPLEFT", 12, -38)
    local line2 = Label(section, "ElvUI: " .. elvui, "GameFontHighlightSmall", {0.86, 0.90, 0.94, 1})
    line2:SetPoint("TOPLEFT", section, "TOPLEFT", 12, -62)
    local line3 = Label(section, "LibSharedMedia: " .. lsm, "GameFontHighlightSmall", {0.86, 0.90, 0.94, 1})
    line3:SetPoint("TOPLEFT", section, "TOPLEFT", 12, -86)
    local line4 = Label(section, "Font: " .. font, "GameFontHighlightSmall", {0.86, 0.90, 0.94, 1})
    line4:SetPoint("TOPLEFT", section, "TOPLEFT", 12, -110)
    local line5 = Label(section, "Texture: " .. texture, "GameFontHighlightSmall", {0.86, 0.90, 0.94, 1})
    line5:SetPoint("TOPLEFT", section, "TOPLEFT", 12, -134)
    local line6 = Label(section, "DLL: " .. status, "GameFontHighlightSmall", {0.86, 0.90, 0.94, 1})
    line6:SetPoint("TOPLEFT", section, "TOPLEFT", 12, -158)

    local refresh = MakeButton(section, "Status", 82, 24)
    refresh:SetPoint("TOPRIGHT", section, "TOPRIGHT", -12, -36)
    refresh:SetScript("OnClick", function()
        if WM.ShowStatus then
            WM.ShowStatus()
        else
            Send("STATUS")
        end
    end)

    local options = Section(page, "Options", 0, -196, 500, 154)
    local chatButton = MakeButton(options, "", 178, 24)
    chatButton:SetPoint("TOPLEFT", options, "TOPLEFT", 12, -36)
    local minimapButton = MakeButton(options, "", 178, 24)
    minimapButton:SetPoint("TOPLEFT", options, "TOPLEFT", 12, -68)
    local resetMinimap = MakeButton(options, "Reset Minimap Pos", 132, 24)
    resetMinimap:SetPoint("TOPLEFT", options, "TOPLEFT", 12, -100)

    local optionHint = Label(options, "Changes are saved per character.", "GameFontHighlightSmall", {0.66, 0.72, 0.78, 1})
    optionHint:SetPoint("TOPLEFT", options, "TOPLEFT", 210, -40)
    optionHint:SetWidth(260)
    optionHint:SetJustifyH("LEFT")

    local function RefreshOptions()
        local settings = EnsureSettings()
        chatButton:SetText((WineMorpherState.chatMessages and "Chat: On" or "Chat: Off"))
        minimapButton:SetText((settings.showMinimap and "Minimap: On" or "Minimap: Off"))
        chatButton.isSelected = WineMorpherState.chatMessages
        minimapButton.isSelected = settings.showMinimap
        SetPanelColor(chatButton, chatButton.isSelected and C.active or C.button)
        SetPanelColor(minimapButton, minimapButton.isSelected and C.active or C.button)
    end

    chatButton:SetScript("OnClick", function()
        WineMorpherState.chatMessages = not WineMorpherState.chatMessages
        RefreshOptions()
    end)
    minimapButton:SetScript("OnClick", function()
        local settings = EnsureSettings()
        settings.showMinimap = not settings.showMinimap
        if WM.UpdateMinimapButton then
            WM.UpdateMinimapButton()
        end
        RefreshOptions()
    end)
    resetMinimap:SetScript("OnClick", function()
        EnsureSettings().minimapAngle = 225
        if WM.UpdateMinimapButton then
            WM.UpdateMinimapButton()
        end
    end)

    page:SetScript("OnShow", RefreshOptions)
    RefreshOptions()

    return page
end

function WM.CreateGUI()
    if WM.frame then
        return WM.frame
    end

    RefreshMedia()

    local frame = CreateFrame("Frame", "WineMorpherFrame", UIParent)
    WM.frame = frame
    frame:SetWidth(1040)
    frame:SetHeight(560)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    SkinPanel(frame, C.bg, C.border)

    local titleBar = CreateFrame("Frame", nil, frame)
    titleBar:SetHeight(42)
    titleBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    titleBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    titleBar:EnableMouse(true)
    titleBar:RegisterForDrag("LeftButton")
    titleBar:SetScript("OnDragStart", function() frame:StartMoving() end)
    titleBar:SetScript("OnDragStop", function() frame:StopMovingOrSizing() end)
    SkinPanel(titleBar, C.panel2, C.border)

    local accentLine = titleBar:CreateTexture(nil, "ARTWORK")
    accentLine:SetHeight(2)
    accentLine:SetPoint("BOTTOMLEFT", titleBar, "BOTTOMLEFT", 1, 1)
    accentLine:SetPoint("BOTTOMRIGHT", titleBar, "BOTTOMRIGHT", -1, 1)
    SetMediaTexture(accentLine, C.accent)

    local title = Label(titleBar, "WineMorpher", "GameFontNormalLarge", C.gold)
    title:SetPoint("LEFT", titleBar, "LEFT", 14, 1)

    local subtitle = Label(titleBar, "v" .. tostring(WM.version or "0.2.1"), "GameFontHighlightSmall", {0.62, 0.66, 0.70, 1})
    subtitle:SetPoint("LEFT", title, "RIGHT", 8, -1)

    local close = MakeButton(titleBar, "X", 28, 24)
    close:SetPoint("RIGHT", titleBar, "RIGHT", -10, 0)
    close.normalColor = C.danger
    SetPanelColor(close, C.danger)
    close:SetScript("OnClick", function() frame:Hide() end)

    local statusText = Label(titleBar, "", "GameFontHighlightSmall", {0.70, 0.76, 0.82, 1})
    statusText:SetPoint("RIGHT", close, "LEFT", -12, 0)

    local nav = CreateFrame("Frame", nil, frame)
    nav:SetWidth(138)
    nav:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -52)
    nav:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 10, 10)
    SkinPanel(nav, C.panel, C.soft)

    local content = CreateFrame("Frame", nil, frame)
    content:SetPoint("TOPLEFT", nav, "TOPRIGHT", 10, 0)
    content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 10)
    SkinPanel(content, C.panel, C.soft)

    frame.pages = {
        preview = CreatePreviewPage(content),
        mount = CreateMountPage(content),
        morph = CreateMorphPage(content),
        pets = CreatePetsPage(content),
        loadouts = CreateLoadoutsPage(content),
        sets = CreateSetsPage(content),
        titles = CreateTitlesPage(content),
        settings = CreateSettingsPage(content),
    }

    frame.navButtons = {}
    local navItems = {
        {"preview", "Preview"},
        {"mount", "Mount"},
        {"morph", "Morph"},
        {"pets", "Pets"},
        {"loadouts", "Loadouts"},
        {"sets", "Sets"},
        {"titles", "Titles"},
        {"settings", "Settings"},
    }

    local function ShowPage(name)
        frame.activePage = name
        for pageName, page in pairs(frame.pages) do
            if pageName == name then
                page:Show()
            else
                page:Hide()
            end
        end

        for pageName, button in pairs(frame.navButtons) do
            button.isSelected = pageName == name
            if button.isSelected then
                SetPanelColor(button, C.active)
            else
                SetPanelColor(button, button.normalColor or C.button)
            end
        end
    end
    WM.ShowGUIPage = ShowPage

    for index, item in ipairs(navItems) do
        local pageName = item[1]
        local button = MakeButton(nav, item[2], 114, 28)
        button:SetPoint("TOPLEFT", nav, "TOPLEFT", 12, -12 - (index - 1) * 34)
        button:SetScript("OnClick", function() ShowPage(pageName) end)
        frame.navButtons[pageName] = button
    end

    frame.UpdateStatusText = function()
        local status = WINEMORPHER_DLL_LOADED == "TRUE" and "DLL loaded" or "Bridge pending"
        statusText:SetText(status)
    end

    frame:SetScript("OnShow", function(self)
        if WINEMORPHER_DLL_LOADED ~= "TRUE" then
            Send("STATUS")
        end
        self.UpdateStatusText()
    end)
    frame.statusElapsed = 0
    frame:SetScript("OnUpdate", function(self, elapsed)
        self.statusElapsed = (self.statusElapsed or 0) + elapsed
        if self.statusElapsed >= 1 then
            self.statusElapsed = 0
            self.UpdateStatusText()
        end
    end)

    ShowPage("preview")
    frame:Hide()
    return frame
end

function WM.ToggleGUI()
    local frame = WM.CreateGUI()
    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
    end
end

WM.CreateMinimapButton()
