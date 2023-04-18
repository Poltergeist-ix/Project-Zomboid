local pzVehicleWorkshop = pzVehicleWorkshop

local Util = {
    OnCreate = {}
}

local notClient = not isClient()

function Util.changeVehicleScript(vehicle,scriptName,skinIndex)
    vehicle:setScriptName(scriptName)
    --vehicle:scriptReloaded()
    --if skinIndex then vehicle:setSkinIndex(skinIndex) end
end

function Util.createEmpty(vehicle, part)
    part:setCondition(0)
end

function Util.initBaseArmor(vehicle, part)
    local item = part:getInventoryItem()
    if item == nil then return end
    part:setModelVisible(item:getFullType(),true)
end

function Util.updateBaseArmor(vehicle, part)
    if notClient then
        local item = part:getInventoryItem()
        if item == nil then return end
        if part:getCondition() <= 0 then
            part:setInventoryItem(nil)
            part:setAllModelsVisible(false)
        end
    end
end

function Util.BasicVehicleRecipe_OnCanPerform(recipe, player, item)
    local vehicle = item and item:getModData().vehicleObj
    if not vehicle then return false end

    return player:getVehicle() == nil and vehicle:getSquare() ~= nil and player:DistTo(vehicle:getX(), vehicle:getY()) < 7
    --etc distance / vehicle:getSquare():getMovingObjects():indexOf(vehicle) < 0 -  / player:getUseableVehicle() == vehicle or player:getNearVehicle() == vehicle
end

function Util.OnCreate.ArmorRecipe(items, result, player)
    local mod = player:getPerkLevel(Perks.Mechanics) + player:getPerkLevel(Perks.MetalWelding) - 5

    result:setCondition(math.min(100,ZombRand(50+mod*2,101+mod*mod)))
end

function Util.OnCreate.RemoveArmorRecipe(items, result, player)
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        local data = item:getModData()
        if data.vehicleObj and data.unmountCarPart then
            local item = data.unmountCarPart:getInventoryItem()
            local cond = data.unmountCarPart:getCondition()
            if item:getType() == "ArmorMetalSheet" then
                for i = 1, ZombRand(4 * cond / 100) do
                    player:getSquare():AddWorldInventoryItem("Base.SheetMetal", 0.5, 0.5, 0.5)
                end
            else
                for i = 1, ZombRand(6 * cond / 100) do
                    player:getSquare():AddWorldInventoryItem("Base.ScrapMetal", 0.5, 0.5, 0)
                end
            end
            return
        end
    end
end

pzVehicleWorkshop.VehicleUtilities = Util