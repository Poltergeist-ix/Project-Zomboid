local DryFishMod = DryFishMod
local notIsClient = not isClient()

local function OnLoadWithSprite(isoObject)
    isoObject:getContainer():setAcceptItemFunction("DryFishMod.DryFishContainer")
    if notIsClient then
        DryFishMod.ServerSystem.instance:loadIsoObject(isoObject)
    end
end

for tile,modType in pairs(DryFishMod.tiles) do
    MapObjects.OnLoadWithSprite(tile, OnLoadWithSprite, 5)
end
