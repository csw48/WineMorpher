local addonName, ns = ...

local function Lower(text)
    return string.lower(tostring(text or ""))
end

local function AddItemEntry(index, slotName, subclass, ids, names, recordIndex)
    if type(ids) ~= "table" or type(names) ~= "table" then
        return
    end

    local primaryId = tonumber(ids[1])
    local primaryName = names[1]
    if not primaryId or not primaryName then
        return
    end

    local search = tostring(primaryId) .. " " .. Lower(primaryName) .. " " .. Lower(slotName) .. " " .. Lower(subclass)
    for i = 2, #ids do
        if ids[i] then
            search = search .. " " .. tostring(ids[i])
        end
        if names[i] then
            search = search .. " " .. Lower(names[i])
        end
    end

    table.insert(index, {
        id = primaryId,
        name = primaryName,
        slot = slotName,
        subclass = subclass,
        ids = ids,
        names = names,
        recordIndex = recordIndex,
        search = search,
    })
end

local function AddRecords(index, slotName, subclass, records)
    if type(records) ~= "table" then
        return
    end

    for recordIndex, record in ipairs(records) do
        AddItemEntry(index, slotName, subclass, record[1], record[2], recordIndex)
    end
end

function ns.BuildItemIndex()
    if ns.itemIndex then
        return ns.itemIndex
    end

    local index = {}
    local items = ns.items or {}

    for slotName, slotData in pairs(items) do
        if slotName == "Armor" then
            for armorSlot, armorData in pairs(slotData) do
                for subclass, records in pairs(armorData) do
                    AddRecords(index, armorSlot, subclass, records)
                end
            end
        else
            for subclass, records in pairs(slotData) do
                AddRecords(index, slotName, subclass, records)
            end
        end
    end

    table.sort(index, function(a, b)
        if a.slot == b.slot then
            if a.subclass == b.subclass then
                return a.name < b.name
            end
            return a.subclass < b.subclass
        end
        return a.slot < b.slot
    end)

    ns.itemIndex = index
    return index
end

function ns.GetItemSlots()
    ns.BuildItemIndex()
    local slots = {}
    local seen = {}

    for _, entry in ipairs(ns.itemIndex or {}) do
        if not seen[entry.slot] then
            table.insert(slots, entry.slot)
            seen[entry.slot] = true
        end
    end

    table.sort(slots)
    return slots
end

function ns.GetItemSubclasses(slotFilter)
    ns.BuildItemIndex()
    local subclasses = {}
    local seen = {}

    for _, entry in ipairs(ns.itemIndex or {}) do
        if (not slotFilter or slotFilter == "All" or entry.slot == slotFilter) and not seen[entry.subclass] then
            table.insert(subclasses, entry.subclass)
            seen[entry.subclass] = true
        end
    end

    table.sort(subclasses)
    return subclasses
end

function ns.SearchItems(query, slotFilter, subclassFilter, limit, offset)
    local result = {}
    local index = ns.BuildItemIndex()
    local q = Lower(query)
    local maxResults
    local startOffset
    local matched = 0

    if type(subclassFilter) == "number" then
        maxResults = subclassFilter
        subclassFilter = nil
        startOffset = limit or 0
    else
        maxResults = limit or 80
        startOffset = offset or 0
    end

    for _, entry in ipairs(index) do
        local slotOk = not slotFilter or slotFilter == "All" or entry.slot == slotFilter
        local subclassOk = not subclassFilter or subclassFilter == "All" or entry.subclass == subclassFilter
        if slotOk and subclassOk and (q == "" or string.find(entry.search, q, 1, true)) then
            matched = matched + 1
            if matched > startOffset then
                if #result < maxResults then
                    table.insert(result, entry)
                end
            end
        end
    end

    return result, #index, matched
end

function ns.SearchMounts(query, mountType, limit, offset)
    local result = {}
    local q = Lower(query)
    local maxResults = limit or 80
    local startOffset = offset or 0
    local matched = 0

    for _, entry in ipairs(ns.mountsDB or {}) do
        local kind = entry[5] or "G"
        local group = entry[6] or ns.MountGroupForEntry(entry)
        local kindOk = not mountType or mountType == "ALL" or kind == mountType or kind == "B" or group == mountType or (mountType == "Ground" and kind == "G")
        local search = Lower(entry[1]) .. " " .. tostring(entry[3] or "") .. " " .. Lower(group)
        if kindOk and (q == "" or string.find(search, q, 1, true)) then
            matched = matched + 1
            if matched > startOffset and #result < maxResults then
                table.insert(result, {
                    name = entry[1],
                    spellID = entry[2],
                    displayID = entry[3],
                    modelPath = entry[4],
                    mountType = kind,
                    group = group,
                })
            end
        end
    end

    return result, #(ns.mountsDB or {}), matched
end

function ns.MountGroupForEntry(entry)
    local name = Lower(entry and entry[1])
    local model = Lower(entry and entry[4])
    local kind = entry and entry[5] or "G"

    if kind == "F" then return "Flying" end
    if string.find(name, "war", 1, true) or string.find(name, "gladiator", 1, true) then return "PvP" end
    if string.find(name, "deathcharger", 1, true) or string.find(name, "raven lord", 1, true) or string.find(name, "white hawkstrider", 1, true) or string.find(name, "bronze drake", 1, true) or string.find(name, "blue proto", 1, true) then return "Dungeon" end
    if string.find(name, "zulian", 1, true) or string.find(name, "razzashi", 1, true) or string.find(name, "qiraji", 1, true) or string.find(name, "mimiron", 1, true) or string.find(name, "invincible", 1, true) then return "Raid" end
    if string.find(name, "horse", 1, true) or string.find(name, "steed", 1, true) or string.find(model, "horse", 1, true) then return "Horses" end
    if string.find(name, "ram", 1, true) or string.find(model, "ram", 1, true) then return "Rams" end
    if string.find(name, "skeletal", 1, true) or string.find(model, "skeletalhorse", 1, true) then return "Skeletal Horse" end
    if string.find(name, "saber", 1, true) or string.find(name, "tiger", 1, true) or string.find(model, "nightelfmount", 1, true) then return "Sabers" end
    if string.find(name, "wolf", 1, true) then return "Wolves" end
    if string.find(name, "raptor", 1, true) then return "Raptors" end
    if string.find(name, "kodo", 1, true) then return "Kodos" end
    if string.find(name, "hawkstrider", 1, true) then return "Hawkstriders" end
    if string.find(name, "elekk", 1, true) then return "Elekks" end
    if string.find(name, "mechanostrider", 1, true) then return "Mechanostriders" end
    if string.find(name, "mammoth", 1, true) then return "Mammoths" end
    if string.find(name, "bear", 1, true) then return "Bears" end
    if string.find(name, "talbuk", 1, true) then return "Talbuks" end
    if string.find(name, "drake", 1, true) or string.find(name, "dragon", 1, true) then return "Drakes" end
    return kind == "G" and "Ground" or "Other"
end

function ns.GetMountGroups()
    return {"All", "Ground", "Flying", "PvP", "Raid", "Dungeon", "Horses", "Rams", "Skeletal Horse", "Sabers", "Wolves", "Raptors", "Kodos", "Hawkstriders", "Elekks", "Mechanostriders", "Mammoths", "Bears", "Talbuks", "Drakes"}
end

function ns.SearchCreatureDisplays(query, limit, offset)
    local matches = {}
    local result = {}
    local q = Lower(query)
    local maxResults = limit or 80
    local startOffset = offset or 0
    local total = 0

    for displayID, name in pairs(ns.creatureDisplayDB or {}) do
        total = total + 1
        local search = Lower(name) .. " " .. tostring(displayID)
        if q == "" or string.find(search, q, 1, true) then
            table.insert(matches, {name = name, displayID = displayID})
        end
    end

    table.sort(matches, function(a, b)
        return a.name < b.name
    end)

    for index = startOffset + 1, math.min(#matches, startOffset + maxResults) do
        table.insert(result, matches[index])
    end

    return result, total, #matches
end

function ns.SearchItemSets(query, classFilter, limit, offset)
    if ns.InitializeItemSetsDB then
        ns.InitializeItemSetsDB()
    end

    local source = ns.itemSetsDB or {}
    if classFilter and classFilter ~= "ALL" and ns.itemSetsByClass then
        source = ns.itemSetsByClass[classFilter] or {}
    end

    local matches = {}
    local result = {}
    local q = Lower(query)
    local maxResults = limit or 80
    local startOffset = offset or 0

    for _, setData in ipairs(source) do
        local search = Lower(setData.name) .. " " .. Lower(setData.description)
        if q == "" or string.find(search, q, 1, true) then
            table.insert(matches, setData)
        end
    end

    table.sort(matches, function(a, b)
        return a.name < b.name
    end)

    for index = startOffset + 1, math.min(#matches, startOffset + maxResults) do
        table.insert(result, matches[index])
    end

    return result, #(source or {}), #matches
end

function ns.SearchTitles(query, limit, offset)
    local result = {}
    local q = Lower(query)
    local maxResults = limit or 80
    local startOffset = offset or 0
    local matched = 0
    local titles = _G.Transmorpher_Titles or {}

    for _, title in ipairs(titles) do
        local name = tostring(title.name or "")
        name = string.gsub(name, "%%s", "")
        name = string.gsub(name, "^%s+", "")
        name = string.gsub(name, "%s+$", "")
        if name == "" then
            name = tostring(title.name or "")
        end
        local search = Lower(name) .. " " .. tostring(title.id)
        if q == "" or string.find(search, q, 1, true) then
            matched = matched + 1
            if matched > startOffset and #result < maxResults then
                table.insert(result, {id = title.id, name = name})
            end
        end
    end

    return result, #titles, matched
end

function ns.SearchEnchants(query, limit, offset)
    local result = {}
    local q = Lower(query)
    local maxResults = limit or 80
    local startOffset = offset or 0
    local matched = 0

    for _, entry in ipairs(ns.enchantSorted or {}) do
        local search = entry.nameLower .. " " .. tostring(entry.id)
        if q == "" or string.find(search, q, 1, true) then
            matched = matched + 1
            if matched > startOffset and #result < maxResults then
                table.insert(result, entry)
            end
        end
    end

    return result, #(ns.enchantSorted or {}), matched
end

function ns.SearchPets(query, limit)
    local result = {}
    local q = Lower(query)
    local maxResults = limit or 80

    for _, entry in ipairs(ns.combatPetsDB or {}) do
        local search = Lower(entry[1]) .. " " .. Lower(entry[2]) .. " " .. tostring(entry[3] or "")
        if q == "" or string.find(search, q, 1, true) then
            table.insert(result, {
                name = entry[1],
                family = entry[2],
                displayID = entry[3],
                modelPath = entry[4],
                npcID = entry[5],
            })
            if #result >= maxResults then
                break
            end
        end
    end

    return result, #(ns.combatPetsDB or {})
end
