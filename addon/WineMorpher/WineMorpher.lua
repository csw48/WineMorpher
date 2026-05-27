local addonName = ...

local WM = _G.WineMorpher or {}
_G.WineMorpher = WM
WM.addonName = addonName
WM.version = "0.2.1"

WINEMORPHER_CMD = WINEMORPHER_CMD or ""
WINEMORPHER_DLL_LOADED = WINEMORPHER_DLL_LOADED or nil
WINEMORPHER_STATUS = WINEMORPHER_STATUS or "Addon loaded, waiting for DLL"
WINEMORPHER_LUA_READY = "TRUE"

WineMorpherState = WineMorpherState or {}

local prefix = "|cff66ccffWineMorpher|r: "
local commandQueue = {}

local function Print(message)
    if not WineMorpherState or not WineMorpherState.chatMessages then
        return
    end
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage(prefix .. tostring(message))
    end
end

local function QueueCommand(command)
    if WINEMORPHER_CMD and WINEMORPHER_CMD ~= "" then
        table.insert(commandQueue, command)
        return true
    end

    WINEMORPHER_CMD = command
    WineMorpherState.lastCommand = command
    return true
end

local function QueueCommands(commands)
    if type(commands) ~= "table" then
        return false
    end

    local queued = 0
    for _, command in ipairs(commands) do
        if command and command ~= "" then
            table.insert(commandQueue, command)
            queued = queued + 1
        end
    end

    return queued > 0
end

local function ShowStatus()
    local loaded = WINEMORPHER_DLL_LOADED == "TRUE" and "loaded" or "not loaded"
    Print("DLL " .. loaded .. "; " .. tostring(WINEMORPHER_STATUS or "no status"))
    QueueCommand("STATUS")
end

local function ShowHelp()
    Print("/wmorph or /wmorph gui")
    Print("/wmorph status")
    Print("/wmorph display <displayID>")
    Print("/wmorph reset")
    Print("/wmorph mount <displayID>")
    Print("/wmorph mount reset")
    Print("/wmorph scale <float>")
    Print("/wmorph item <slot 1-19> <itemID>")
    Print("/wmorph item <slot 1-19> hide")
    Print("/wmorph item <slot 1-19> reset")
    Print("/wmorph enchant mh <enchantID>")
    Print("/wmorph enchant oh <enchantID>")
    Print("/wmorph enchant reset")
    Print("/wmorph pet <displayID>")
    Print("/wmorph pet scale <float>")
    Print("/wmorph pet reset")
    Print("/wmorph title <titleID>")
    Print("/wmorph title reset")
end

WM.Print = Print
WM.QueueCommand = QueueCommand
WM.QueueCommands = QueueCommands
WM.ShowStatus = ShowStatus
WM.ShowHelp = ShowHelp

SLASH_WINEMORPHER1 = "/wmorph"
SlashCmdList.WINEMORPHER = function(msg)
    msg = string.gsub(msg or "", "^%s+", "")
    msg = string.gsub(msg, "%s+$", "")

    local command, rest = string.match(msg, "^(%S*)%s*(.-)$")
    command = string.lower(command or "")

    if command == "" or command == "gui" then
        if WM.ToggleGUI then
            WM.ToggleGUI()
        else
            ShowHelp()
        end
    elseif command == "help" then
        ShowHelp()
    elseif command == "status" then
        ShowStatus()
    elseif command == "display" or command == "morph" then
        local displayId = tonumber(rest)
        if not displayId or displayId <= 0 then
            Print("usage: /wmorph display <displayID>")
            return
        end
        QueueCommand("DISPLAY:" .. tostring(math.floor(displayId)))
    elseif command == "reset" then
        QueueCommand("RESET")
    elseif command == "mount" then
        if rest == "reset" or rest == "0" then
            QueueCommand("MOUNT:0")
        else
            local displayId = tonumber(rest)
            if not displayId or displayId < 0 then
                Print("usage: /wmorph mount <displayID> OR /wmorph mount reset")
                return
            end
            QueueCommand("MOUNT:" .. tostring(math.floor(displayId)))
        end
    elseif command == "scale" then
        local scale = tonumber(rest)
        if not scale or scale < 0.01 or scale > 10.0 then
            Print("usage: /wmorph scale <float> (bounds: 0.01 to 10.0)")
            return
        end
        QueueCommand(string.format("SCALE:%.2f", scale))
    elseif command == "item" then
        local slotText, itemText = string.match(rest, "^(%S+)%s+(%S+)$")
        local slot = tonumber(slotText)
        if not slot or slot < 1 or slot > 19 or not itemText then
            Print("usage: /wmorph item <slot 1-19> <itemID|hide|reset>")
            return
        end

        if itemText == "hide" then
            QueueCommand("ITEM:" .. tostring(math.floor(slot)) .. ":-1")
        elseif itemText == "reset" or itemText == "0" then
            QueueCommand("ITEM:" .. tostring(math.floor(slot)) .. ":0")
        else
            local itemId = tonumber(itemText)
            if not itemId or itemId < 0 then
                Print("usage: /wmorph item <slot 1-19> <itemID|hide|reset>")
                return
            end
            QueueCommand("ITEM:" .. tostring(math.floor(slot)) .. ":" .. tostring(math.floor(itemId)))
        end
    elseif command == "enchant" then
        local hand, enchantText = string.match(rest, "^(%S+)%s*(%S*)$")
        hand = string.lower(hand or "")

        if hand == "reset" then
            QueueCommand("ENCHANT_RESET")
            return
        end

        local enchantId = tonumber(enchantText)
        if (hand ~= "mh" and hand ~= "oh") or not enchantId or enchantId < 0 then
            Print("usage: /wmorph enchant <mh|oh> <enchantID> OR /wmorph enchant reset")
            return
        end

        if hand == "mh" then
            QueueCommand("ENCHANT_MH:" .. tostring(math.floor(enchantId)))
        else
            QueueCommand("ENCHANT_OH:" .. tostring(math.floor(enchantId)))
        end
    elseif command == "pet" or command == "hpet" then
        local subCommand, subRest = string.match(rest, "^(%S*)%s*(.-)$")
        subCommand = string.lower(subCommand or "")

        if subCommand == "reset" or subCommand == "0" then
            QueueCommand("HPET_RESET")
        elseif subCommand == "scale" then
            local scale = tonumber(subRest)
            if not scale or scale < 0.01 or scale > 10.0 then
                Print("usage: /wmorph pet scale <float> (bounds: 0.01 to 10.0)")
                return
            end
            QueueCommand(string.format("HPET_SCALE:%.2f", scale))
        else
            local displayId = tonumber(rest)
            if not displayId or displayId <= 0 then
                Print("usage: /wmorph pet <displayID> OR /wmorph pet scale <float> OR /wmorph pet reset")
                return
            end
            QueueCommand("HPET_MORPH:" .. tostring(math.floor(displayId)))
        end
    elseif command == "title" then
        if rest == "reset" or rest == "0" then
            QueueCommand("TITLE_RESET")
        else
            local titleId = tonumber(rest)
            if not titleId or titleId <= 0 then
                Print("usage: /wmorph title <titleID> OR /wmorph title reset")
                return
            end
            QueueCommand("TITLE:" .. tostring(math.floor(titleId)))
        end
    else
        ShowHelp()
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function()
    WINEMORPHER_LUA_READY = "TRUE"
    if WM.CreateMinimapButton then
        WM.CreateMinimapButton()
    end
    Print(addonName .. " ready. Type /wmorph status")
end)
frame:SetScript("OnUpdate", function()
    if WINEMORPHER_CMD and WINEMORPHER_CMD ~= "" then
        return
    end

    local nextCommand = table.remove(commandQueue, 1)
    if nextCommand then
        QueueCommand(nextCommand)
    end
end)
