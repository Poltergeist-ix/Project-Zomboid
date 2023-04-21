local pzVehicleWorkshop = pzVehicleWorkshop

local Util = {
    OnCreate = {},
    Update = {},
}

local notClient = not isClient()

function Util.changeVehicleScript(vehicle,scriptName,skinIndex)
    vehicle:setScriptName(scriptName)
    if notClient and not isServer() then
        vehicle:scriptReloaded()
    end
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
    local pData = part:getModData()


    local max = 9999
    if part:getId() == "Armor_FrontLeftWindow" then max = max * 2 end
    if part:getId() == "Armor_EngineDoor" then max = max * 7 end
    local partCondition = part:getCondition()
    local item = part:getInventoryItem()
    if not pData.armorCondition or partCondition > pData.prevArmorCondition then
        pData.armorConditionMax = max
        pData.armorCondition = item ~= nil and pData.armorConditionMax * partCondition / 100 or 0
        pData.prevArmorCondition = partCondition

        local prPartId = part:getId():gsub("^Armor_","")
        local prPart = vehicle:getPartById(prPartId)
        if part ~= nil then
            pData.protectedParts = { [prPartId] = prPart:getCondition() }
        end
        if prPartId == "TrunkDoor" then
            pData.protectedParts["TruckBed"] = vehicle:getPartById("TruckBed"):getCondition()
        end
    end


    if pData.armorCondition <= 0 then return end

    local armorCondition = pData.armorCondition - pData.prevArmorCondition + partCondition
    --if pData.armorCondition ~= armorCondition then print("vwDebug not same condition") end

    if pData.protectedParts ~= nil then
        for prId,cond in pairs(pData.protectedParts) do
            local protectedPart = vehicle:getPartById(prId)
            local prCondition = protectedPart:getCondition()
            if prCondition < cond then
                local dif = cond - prCondition
                if dif > armorCondition then
                    dif = armorCondition
                    armorCondition = 0
                else
                    armorCondition = armorCondition - dif
                    dif = 0
                end
                protectedPart:setCondition(cond-dif)
            else
                pData.protectedParts[prId] = prCondition
            end
            vehicle:transmitPartCondition(protectedPart)
        end
    end

    if armorCondition ~= pData.armorCondition then
        local newCondition = armorCondition > 0 and armorCondition / pData.armorConditionMax * 100 or 0
        if newCondition == 0 and not pData.keepDestroyed then
            --print("vwDebug Armor destroyed ",part:getId())
            part:setInventoryItem(nil)
            part:setAllModelsVisible(false)
            vehicle:transmitPartItem(part)
        else
            --print("vwDebug Armor new condition ",part:getId(),newCondition)
            part:setCondition(newCondition)
        end
        pData.armorCondition = armorCondition
        pData.prevArmorCondition = newCondition
        vehicle:transmitPartModData(part)
    end
    vehicle:transmitPartCondition(part)
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