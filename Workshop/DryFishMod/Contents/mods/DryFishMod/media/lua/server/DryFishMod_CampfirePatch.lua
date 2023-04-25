if isClient() then return end
require "Camping/SCampfireSystem"

local DryFishMod = DryFishMod
local Campfires = {}

do
    require "Camping/SCampfireGlobalObject"
    function SCampfireGlobalObject:fromModData(modData)
        for _,key in ipairs(self.luaSystem.savedObjectModData) do
            self[key] = modData[key]
        end
    end

    function SCampfireGlobalObject:toModData(modData)
        for _,key in ipairs(self.luaSystem.savedObjectModData) do
            modData[key] = self[key]
        end
    end
end

--add extra saved object field
function Campfires.OnSGlobalObjectSystemInit()
    local instance = SCampfireSystem.instance
    if instance then
        if instance.savedObjectModData then
            table.insert(instance.savedObjectModData,"dryFishHours")
        else
            instance.savedObjectModData = {'exterior', 'isLit', 'fuelAmt', "dryFishHours"}
        end
        SCampfireSystem.instance.system:setObjectModDataKeys(instance.savedObjectModData)

        SCampfireGlobalObject.addObject = Campfires.SCampfireGlobalObject_addObject_patch(SCampfireGlobalObject.addObject)
    end
end

function Campfires.SCampfireGlobalObject_addObject_patch(addObject)
    local IsoObject_new
    local function IsoObject_new_patch(square,sprite,name)
        local object = IsoObject_new(square,sprite,name)
        object:setSprite(sprite)
        return object
    end
    return function(self)
        IsoObject_new = IsoObject.new
        IsoObject.new = IsoObject_new_patch

        local status, res = pcall(addObject, self)

        IsoObject.new = IsoObject_new

        if status then return res else return print(res) end
    end
end

function Campfires.updateLuaSkewer(luaObject)
    if luaObject.dryFishHours >= 10000 then luaObject.dryFishHours = 10000 else luaObject.dryFishHours = luaObject.dryFishHours + 1 end
    local square = luaObject:getSquare()
    if square then
        local skewer
        local objects = square:getObjects()
        for i = objects:size() - 1, 0, -1 do
            local object = objects:get(i)
            if object:getTextureName() == DryFishMod.skewer then
                skewer = object
                break
            end
        end
        if skewer then
            DryFishMod.ServerSystem.updateObjectContainer(luaObject,skewer)
            luaObject.dryFishHours = 0
        else
            luaObject.dryFishHours = nil
        end
    end
end

function Campfires.EveryHours()
    local self = SCampfireSystem.instance

    for i=0, self.system:getObjectCount() - 1 do
        local luaObject = self.system:getObjectByIndex(i):getModData()
        if luaObject.dryFishHours then
            Campfires.updateLuaSkewer(luaObject)
        end
    end
end

Events.OnSGlobalObjectSystemInit.Add(Campfires.OnSGlobalObjectSystemInit)
Events.EveryHours.Add(Campfires.EveryHours)

DryFishMod.Campfires = Campfires