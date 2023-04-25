local IFP = IndustrialFuelPumps or {}
IFP.thumpOn = true
IFP.soundChance = 8
IFP.addSoundMax = 24

IFP.tiles = {
    --industry_02_66 = true,
    industry_02_67 = true,
    industry_02_71 = true,
}

IFP.gridTiles = {
    industry_02_64 = 3,
    industry_02_65 = 2,
    industry_02_66 = 1,
    industry_02_67 = 0,
    industry_02_68 = 3,
    industry_02_69 = 2,
    industry_02_70 = 1,
    industry_02_71 = 0,
}

function IFP.getPumpOnSquare(square)
    if not square then return end
    local objects = square:getObjects()
    for i = objects:size() - 1, 0, - 1 do
        local object = objects:get(i)
        if IFP.tiles[object:getTextureName()] then return object end
    end
end

function IFP.OnLoadedTileDefinitions(manager)
    for sprite,_ in pairs(IFP.tiles) do
        manager:getSprite(sprite):getProperties():Set("fuelAmount","20000",false)
    end
end

Events.OnLoadedTileDefinitions.Add(IFP.OnLoadedTileDefinitions)

IndustrialFuelPumps = IFP