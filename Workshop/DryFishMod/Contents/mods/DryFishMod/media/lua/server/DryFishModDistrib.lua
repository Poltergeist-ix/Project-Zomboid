require 'Items/ProceduralDistributions'

local function insertSimilarItems(base,targets,items)
    for _,name in ipairs(targets) do
        local itemTable = base[name] and base[name].items
        if itemTable then
            for _,i in ipairs(items) do
                table.insert(itemTable,i)
            end
        end
    end
end

local lists = { "GigamartCannedFood" }
local items = { "DFM.DryFish", 1 }

insertSimilarItems(ProceduralDistributions.list,lists,items)
