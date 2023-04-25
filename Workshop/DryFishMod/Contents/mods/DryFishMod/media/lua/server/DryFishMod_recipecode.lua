
local DryFishMod = DryFishMod

do
    --make the fish valid for drying and fit the drying racks
    local manager = getScriptManager()
    for _,fish in ipairs(fishes) do
        if not DryFishMod.excludeFishes[fish.item] then
            local Item = manager:getItem(fish.item)
            if Item then
                Item:getTags():add("fitsDryFishModRack")
            end
        end
    end
end

DryFishMod.DryFishContainer = function(container,item)
    if item:hasTag("fitsDryFishModRack") then return true end
end

function DryFishMod.OnCreate_DryFishModProcessFish(items, result, player)
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if instanceof(item, "Food") and not item:isSpice() then
            DryFishMod.transferFishStats(item, result, 0.9)
            break
        end
    end
end

function DryFishMod.GetItemTypes_processFish(source)
    local manager = getScriptManager()
    for _,fish in ipairs(fishes) do
        if not DryFishMod.excludeFishes[fish.item] then
            local Item = manager:getItem(fish.item)
            if Item then
                source:add(Item)
            end
        end
    end
end

function DryFishMod.GetItemTypes_DryingFishSalt(scriptItems)
    scriptItems:addAll(getScriptManager():getItemsTag("SapphCookingSalt"));
	scriptItems:addAll(getScriptManager():getItemsTag("Salt"));
end

function DryFishMod.transferFishStats(oldItem,newItem,modifier)
    if not instanceof(oldItem,"Food") then return end
    newItem:setAge(oldItem:getAge())
    newItem:setActualWeight(oldItem:getActualWeight() * modifier)
    newItem:setCustomWeight(true)
    newItem:setWeight(oldItem:getWeight() * modifier)
    newItem:setBaseHunger(oldItem:getBaseHunger() * modifier)
    newItem:setHungChange(oldItem:getHungChange() * modifier)
    --newItem:setBoredomChange(oldItem:getBoredomChangeUnmodified() * modifier)
    --newItem:setUnhappyChange(oldItem:getUnhappyChangeUnmodified() * modifier)
    newItem:setCalories(oldItem:getCalories() * modifier)
    newItem:setCarbohydrates(oldItem:getCarbohydrates() * modifier)
    newItem:setLipids(oldItem:getLipids() * modifier)
    newItem:setProteins(oldItem:getProteins() * modifier)
    newItem:setPoisonPower(oldItem:getPoisonPower())
    newItem:setPoisonDetectionLevel(oldItem:getPoisonDetectionLevel())
    --item:setUseForPoison(item:getHungChange());
    --fishToCreate:setWorldScale(scaleMod + baseScale) -- no get function

    newItem:copyModData(oldItem:getModData())
end