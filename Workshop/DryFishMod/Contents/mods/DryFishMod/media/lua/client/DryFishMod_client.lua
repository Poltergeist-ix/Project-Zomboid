local DryFishMod = DryFishMod
local Client = {}

do
    require "Map/CGlobalObject"
    local Object = CGlobalObject:derive("CDryFishModObject")

    function Object:new(luaSystem, globalObject)
        return CGlobalObject.new(self, luaSystem, globalObject)
    end

    DryFishMod.ClientObject = Object
end

do
    require "Map/CGlobalObjectSystem"

    local System = CGlobalObjectSystem:derive("CDryFishModSystem")

    function System:new()
        return CGlobalObjectSystem.new(self, "DryFishModSystem")
    end

    function System:isValidIsoObject(isoObject)
        return instanceof(isoObject, "IsoThumpable") and DryFishMod.tiles[isoObject:getTextureName()] == "Drier"
    end

    function System:newLuaObject(globalObject)
        return DryFishMod.ClientObject:new(self, globalObject)
    end

    function System:OnServerCommand(command, args)
        local command = self.Commands[command]
        if command ~= nil then
            command(args)
        end
    end

    System.Commands = {}

    System.Commands["NewObject"] = function(args)
        local square = getSquare(args.x,args.y,args.z)
        if not square then return end
        local objects = square:getObjects()
        for i = objects:size() - 1, 0, - 1 do
            local object = objects:get(i)
            local modType = DryFishMod.tiles[object:getTextureName()]
            if modType then
                object:getContainer():setAcceptItemFunction("DryFishMod.DryFishContainer")
                if modType == "Skewer" then object:setSpecialTooltip(true) end
                break
            end
        end
    end

    System.Commands["containerChanged"] = function(args)
        local square = getSquare(args.x,args.y,args.z)

        if not square then return end

        --containerDrawDirty, do these work?
        ISInventoryPage.dirtyUI()
        --triggerEvent("OnContainerUpdate")

        for i = 0, getNumActivePlayers() -1 do
            local player = getSpecificPlayer(i)
            if player and player:getZ() == args.z and IsoUtils.DistanceToSquared(player:getX(),player:getY(),args.x+0.5,args.y+0.5) <= 4 then
                --clear both java / lua
                ISTimedActionQueue.clear(player)
            end
        end
    end

    CGlobalObjectSystem.RegisterSystemClass(System)

    DryFishMod.ClientSystem = System
end

--function Client.placeSkewer(player, campfire, skewer)
--    player:getInventory():Remove(skewer)
--    local square = campfire:getSquare()
--    local isoObject  = IsoObject.new(square:getCell(), square, DryFishMod.skewer)
--    isoObject:createContainersFromSpriteProperties()
--    isoObject:getContainer():setExplored(true)
--    square:transmitAddObjectToSquare(isoObject, -1)
--    triggerEvent("OnObjectAdded", isoObject)
--
--    local luaObject = CCampfireSystem.instance:getLuaObjectOnSquare(square)
--    if luaObject then
--        luaObject.dryFishHours = 0
--    end
--end

--function Client.OnFillWorldObjectContextMenu(playerNum, context, worldobjects, test)
--    if test and ISWorldObjectContextMenu.Test then return true end
--    local character, campfire
--
--    for _,object in ipairs(worldobjects) do
--        local texture = object:getTextureName()
--        --local modType = DryFishMod.tiles[texture]
--        if DryFishMod.campfires[texture] then
--            campfire = object
--            break
--        end
--    end
--
--    if campfire then
--        zxTest = campfire
--        character = character or getSpecificPlayer(playerNum)
--        local skewer = character:getInventory():getFirstType(DryFishMod.skewer)
--        if skewer then
--            if test then return ISWorldObjectContextMenu.setTest() end
--            context:addOption(getText("ContextMenu_DryFishMod_AddDrier"),character,Client.placeSkewer,campfire,skewer)
--        end
--    end
--end

function DryFishMod.patchISToolTipInv_render(render)
    return function(self)
        if self.item:getType() == "PreppedFish" then self.item:setTooltip(getText("IGUI_DryFishMod_DryProgressTooltip",tostring(self.item:getModData().dryingProgress or 0))) end

        return render(self)
    end
end

---when mouse hovers over it
function Client.DoSpecialTooltip(ObjectTooltip, square)
    if ObjectTooltip:getHeight() > 0 then return end

    local skewer, campfire
    local objects = square:getObjects()
    for i = 0, objects:size() - 1 do
        local object = objects:get(i)
        if not campfire and object:getName() == "Campfire" then campfire = object; if skewer then return end
        elseif not skewer and DryFishMod.tiles[object:getTextureName()] == "Skewer" then skewer = object; if campfire then return end
        end
    end

    --if true then
    if skewer ~= nil then
    --local luaObject = CCampfireSystem.instance:getLuaObjectOnSquare(square)
    --if not (luaObject and luaObject.dryFishHours) then
        local text = getText("IGUI_DryFishMod_RequiresCampfire")
        local width = getTextManager():MeasureStringX(UIFont.Medium, text) + 20
        local height = getTextManager():getFontHeight(UIFont.Medium) + 10
        local bhc = getCore():getBadHighlitedColor()

        ObjectTooltip:setWidth(width)
        ObjectTooltip:setHeight(height)
        ObjectTooltip:DrawTextureScaledColor(nil,0, 0, width, height, 0.12, 0.12, 0.12, 0.75)
        ObjectTooltip:DrawText(UIFont.Medium,text,10,5,bhc:getR(), bhc:getG(), bhc:getB(),1)
    end
end

--Events.OnFillWorldObjectContextMenu.Add(Client.OnFillWorldObjectContextMenu)
Events.DoSpecialTooltip.Add(Client.DoSpecialTooltip)

DryFishMod.Client = Client