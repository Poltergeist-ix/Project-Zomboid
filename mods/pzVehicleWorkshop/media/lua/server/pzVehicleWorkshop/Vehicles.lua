local vw = pzVehicleWorkshop


function vw.util.createEmpty(vehicle,part)
    part:setCondition(0)
    --return nil --no effect
end

function vw.util.initDefault(vehicle,part)
    local item = part:getInventoryItem()
    if item == nil then return end
    part:setModelVisible(item:getFullType(),true)
end

function vw.util.BasicVehicleRecipe_OnCanPerform(recipe,player,item)
    local vehicle = item and item:getModData().vehicleObj
    if not vehicle then return false end

    return player:getNearVehicle() == vehicle and vehicle:getSquare() ~= nil --etc vehicle:getSquare():getMovingObjects():indexOf(vehicle) < 0
end

function vw.util.BasicVehicleRecipe_OnCreate(items, result, player)
    result:setCondition(ZombRand(10,101))
end

--[[
    getNearVehicle
--]]