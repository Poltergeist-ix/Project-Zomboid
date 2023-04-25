local IFP = IndustrialFuelPumps

function IFP.OnObjectAboutToBeRemoved(isoObject)
    if IFP.replaceObj == isoObject then return end

    local offset = IFP.gridTiles[isoObject:getTextureName()]
    if not offset then return end
    local square = isoObject:getSquare()
    for i = 1, offset do
        if not square then return end
        square = square:getAdjacentSquare(IsoDirections.E)
    end
    local pump = IFP.getPumpOnSquare(square)
    if pump ~= nil then
        square:transmitRemoveItemFromSquare(pump)
        IsoFireManager.StartFire(getCell(), square, true, 100, 0)
        for _,dir in ipairs({IsoDirections.N,IsoDirections.S}) do
            square = square:getAdjacentSquare(dir)
            pump = IFP.getPumpOnSquare(square)
            if pump ~= nil then
                square:transmitRemoveItemFromSquare(pump)
                IsoFireManager.StartFire(getCell(), square, true, 100, 0)
            end
        end
    end
end

function IFP.OnNewWithSprite(isoObject)
    local square = isoObject:getSquare()

    if not square or isoObject:getObjectIndex() == -1 then return print("IFP: OnNewWithSprite ",square,isoObject:getObjectIndex()) end

    IFP.replaceObj = isoObject
    local index = isoObject:getObjectIndex()
    local spriteName = isoObject:getTextureName()
    square:transmitRemoveItemFromSquare(isoObject)

    local isoObject = IsoThumpable.new(getCell(), square, spriteName, false, {})
    isoObject:setThumpDmg(8)
    --square:transmitAddObjectToSquare(isoObject, index)
    square:AddSpecialObject(isoObject)
    if isServer() then
        isoObject:transmitCompleteItemToClients()
    end

    if ZombRand(100) < IFP.soundChance then
        addSound(nil,isoObject:getX(),isoObject:getY(),isoObject:getZ(),ZombRand(IFP.addSoundMax),1)
    end

    IFP.replaceObj = nil
end

if not isClient() then
    if IFP.thumpOn then
        for sprite,_ in pairs(IFP.gridTiles) do
            MapObjects.OnNewWithSprite(sprite, IFP.OnNewWithSprite, 5)
        end
    end

    Events.OnObjectAboutToBeRemoved.Add(IFP.OnObjectAboutToBeRemoved)
end
