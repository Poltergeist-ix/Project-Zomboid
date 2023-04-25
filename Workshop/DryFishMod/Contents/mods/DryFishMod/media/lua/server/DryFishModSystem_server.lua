--[[
    Global Object System for drying fish
--]]

if isClient() then return end

local DryFishMod = DryFishMod
local sandbox = SandboxVars.DryFishMod

do
    require "Map/SGlobalObject"

    local Object = SGlobalObject:derive("SDryFishModObject")

    function Object:new(luaSystem, globalObject)
        return SGlobalObject.new(self, luaSystem, globalObject)
    end

    function Object:initNew()
        self.dryFishHours = 0
    end

    function Object:stateFromIsoObject(isoObject)
        self:initNew()
    end

    function Object:stateToIsoObject(isoObject)
        if self.dryFishHours > 0 then
            self.luaSystem.updateObjectContainer(self,isoObject)
        end
    end

    DryFishMod.ServerObject = Object
end

do
    require "Map/SGlobalObjectSystem"

    local System = SGlobalObjectSystem:derive("SDryFishModSystem")

    function System:new()
        return SGlobalObjectSystem.new(self, "DryFishModSystem")
    end

    System.savedObjectModData = {"dryFishHours"}
    function System:initSystem()
        self.system:setObjectModDataKeys(self.savedObjectModData)
    end

    function System:isValidIsoObject(isoObject)
        return instanceof(isoObject, "IsoThumpable") and DryFishMod.tiles[isoObject:getTextureName()] == "Drier"
    end

    function System:newLuaObject(globalObject)
        return DryFishMod.ServerObject:new(self, globalObject)
    end

    --gos load, set accept function, special tooltip
    function System:OnObjectAdded(isoObject)
        local modType = DryFishMod.tiles[isoObject:getTextureName()]
        if not modType then return end

        local tick, args = 0, { x = isoObject:getX(), y = isoObject:getY(), z = isoObject:getZ()}
        local function SendCommand(ticks)
            tick = tick + 1
            if tick >= 8 then
                Events.OnTick.Remove(SendCommand)
                self:sendCommand("NewObject",args)
            end
        end
        Events.OnTick.Add(SendCommand)

        if modType == "Skewer" then
            isoObject:setSpecialTooltip(true)
            local campLuaObject = SCampfireSystem.instance:getLuaObjectOnSquare(isoObject:getSquare())
            if not campLuaObject then return end --< until can switch between systems
            campLuaObject.dryFishHours = 0
            campLuaObject:getObject()
            campLuaObject:getObject():getModData().dryFishHours = 0
            campLuaObject:getObject():transmitModData()
        end

        if not self:isValidIsoObject(isoObject) then return end
        self:loadIsoObject(isoObject)
    end

    --change global object types
    --function System:OnObjectAboutToBeRemoved(isoObject)
    --    local modType = DryFishMod.tiles[isoObject:getTextureName()]
    --    if not modType then return end
    --
    --    local campfireLua = SCampfireSystem.instance:getLuaObjectOnSquare(isoObject:getSquare())
    --
    --    if self:isValidIsoObject(isoObject) then
    --        local luaObject = self:getLuaObjectOnSquare(isoObject:getSquare())
    --        if not luaObject then return end
    --        self:removeLuaObject(luaObject)
    --    end
    --end

    function System.checkItem(luaObject, item)
        if item:getType() ~= "PreppedFish" or item:isRotten() or item:isBurnt() then
            return
        end

        local data = item:getModData()
        local prevProgress = data.dryingProgress or 0
        local hourMod = luaObject.isLit and sandbox.campfireDryingMod or sandbox.normalDryingMod
        data.dryingProgress = prevProgress + luaObject.dryFishHours * hourMod

        if not luaObject.isLit and ZombRand(sandbox.poisonChance) == 0 then
            local addPoison = luaObject.dryFishHours
            item:setPoisonPower(item:getPoisonPower() + addPoison)
            item:setPoisonDetectionLevel(item:getPoisonDetectionLevel() + addPoison)
        end

        if data.dryingProgress < 100 then return end

        local hoursToRot = (item:getOffAgeMax() - item:getAge()) * 24
        local hoursToDry = (100 - prevProgress) / hourMod
        if hoursToRot < hoursToDry then return end

        return true
    end

    function System.updateObjectContainer(luaObject,isoObject)
        local itemsChanged
        local container = isoObject:getContainer()
        local items = container:getItems()
        for i = items:size() -1, 0, - 1 do
            local item = items:get(i)
            if System.checkItem(luaObject, item) then
                local newItem = InventoryItemFactory.CreateItem("DFM.DryFish")
                DryFishMod.transferFishStats(item,newItem,0.9)
                container:addItem(newItem)
                container:Remove(item)
                itemsChanged = true
            end
        end
        if itemsChanged then
            local driedOverlay = DryFishMod.driedOverlays[isoObject:getTextureName()]
            if driedOverlay == "DryFishMod_2" and items:size() >= 7 then driedOverlay = "DryFishMod_4" end
            isoObject:setOverlaySprite(driedOverlay)
            isoObject:sendObjectChange("containers")

            local function SendCommand(ticks)
                Events.OnTick.Remove(SendCommand)
                System.instance:sendCommand("containerChanged",{ x = luaObject.x, y = luaObject.y, z = luaObject.z })
            end
            Events.OnTick.Add(SendCommand)
        end
    end

    function System.EveryHours()
        local self = System.instance
        for i=0, self.system:getObjectCount() - 1 do
            local luaObject = self.system:getObjectByIndex(i):getModData()
            if luaObject.dryFishHours >= 10000 then luaObject.dryFishHours = 10000 else luaObject.dryFishHours = luaObject.dryFishHours + 1 end
            local isoObject = luaObject:getIsoObject()
            if isoObject ~= nil then
                System.updateObjectContainer(luaObject,isoObject)
                luaObject.dryFishHours = 0
            end
        end
    end

    SGlobalObjectSystem.RegisterSystemClass(System)
    Events.EveryHours.Add(System.EveryHours)

    DryFishMod.ServerSystem = System

end
