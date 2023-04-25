local Edits = {}

Edits.Items = {
    ["CompostBag"] = {
        Tags = { _FertilizerContainer = true },
    },
    ["Dirtbag"] = {
        Tags = { _DirtContainer = true },
    },
    ["EmptySandbag"] = {
        Tags = { _EmptySolidContainer = true },
        ReplaceTypes = "DirtSource Dirtbag;GravelSource Gravelbag;SandSource Sandbag;CompostSource CompostBag"
    },
    ["Fertilizer"] = {
        Tags = { _FertilizerContainer = true },
    },
    ["Gravelbag"] = {
        Tags = { _GravelContainer = true },
    },
    ["Sandbag"] = {
        Tags = { _SandContainer = true },
    },
    ["SackCabbages"] = {
        Tags = { _EmptySolidContainer = true },
        ReplaceTypes = "DirtSource Dirtbag;GravelSource Gravelbag;SandSource Sandbag;CompostSource CompostBag"
    },
    ["SackCarrots"] = {
        Tags = { _EmptySolidContainer = true },
        ReplaceTypes = "DirtSource Dirtbag;GravelSource Gravelbag;SandSource Sandbag;CompostSource CompostBag"
    },
    ["SackPotatoes"] = {
        Tags = { _EmptySolidContainer = true },
        ReplaceTypes = "DirtSource Dirtbag;GravelSource Gravelbag;SandSource Sandbag;CompostSource CompostBag"
    },
    ["SackOnions"] = {
        Tags = { _EmptySolidContainer = true },
        ReplaceTypes = "DirtSource Dirtbag;GravelSource Gravelbag;SandSource Sandbag;CompostSource CompostBag"
    },
}

--local noise = getDebug() and print or function() end --lol
function Edits.applyEdits()
    if not Edits.Items then return end
    local manager = getScriptManager()
    local item
    for k,v in pairs(Edits.Items) do
        item = manager:getItem(k)
        if item ~= nil then
            for key,value in pairs(v) do
                if key == "Tags" then
                    local tags = item:getTags()
                    for tag,bool in pairs(v.Tags) do
                        if bool then
                            tags:add(tag)
                        else
                            tag:remove(tag)
                        end
                    end
                else
                    item:DoParam(key.." = "..value)
                end
                --noise("Script Edit: "..key..", "..value) --lol
            end
        end
    end
    Edits.Items = nil
end

function Edits.addItem(itemName, itemProperty, propertyValue)
    if not Edits.Items[itemName] then Edits.Items[itemName] = {} end
    Edits.Items[itemName][itemProperty] = propertyValue
end

--Edits.applyEdits()
Events.OnGameBoot.Add(Edits.applyEdits)

return Edits