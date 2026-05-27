local addon, ns = ...

function ns.GetPreviewSetup(version, raceFileName, sex, slotName, subclass)
    local versionData = (ns.previewSetup or {})[version]
    local raceData = versionData and versionData[raceFileName]
    local sexData = raceData and raceData[sex]

    if type(sexData) ~= "table" then
        return nil
    end

    local slotData = sexData[slotName] or (sexData.Armor and sexData.Armor[slotName])
    if type(slotData) ~= "table" then
        return nil
    end

    if slotData.x then
        return slotData
    end

    if subclass and type(slotData[subclass]) == "table" then
        return slotData[subclass]
    end

    for _, setup in pairs(slotData) do
        if type(setup) == "table" and setup.x then
            return setup
        end
    end

    return nil
end
