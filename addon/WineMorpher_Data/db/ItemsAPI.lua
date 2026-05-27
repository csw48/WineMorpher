local addon, ns = ...

function ns.GetSubclassRecords(slotName, subclass)
    local items = ns.items or {}
    local slotData = items[slotName] or (items.Armor and items.Armor[slotName])

    if type(slotData) == "table" then
        return slotData[subclass]
    end

    return nil
end

function ns.FindRecord(slotName, itemId)
    local items = ns.items or {}
    local slotData = items[slotName] or (items.Armor and items.Armor[slotName])

    if type(slotData) ~= "table" then
        return nil
    end

    for subclass, records in pairs(slotData) do
        if type(records) == "table" then
            for _, record in ipairs(records) do
                local ids = record[1]
                local names = record[2]
                if type(ids) == "table" then
                    for index, id in ipairs(ids) do
                        if tonumber(id) == tonumber(itemId) then
                            return ids, names, index, subclass
                        end
                    end
                end
            end
        end
    end

    return nil
end
