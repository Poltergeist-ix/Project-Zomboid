local IFP = IndustrialFuelPumps

local function predicatePetrol(item)
    return (item:hasTag("Petrol") or item:getType() == "PetrolCan") and (item:getRemainingUses() > 0)
end

do
    require "TimedActions/ISTakeFuel"
    local Action = ISBaseTimedAction:derive("IFPPutFuel")

    function Action:new(character, fuelStation, item, all)
        local o = {}
        setmetatable(o, self)
        self.__index = self
        o.character = character
        o.fuelStation = fuelStation
        o.square = fuelStation:getSquare()
        o.item = item
        o.stopOnWalk = true
        o.stopOnRun = true
        o.addAll = all
        o.maxTime = 111
        return o;
    end

    function Action:isValid()
        return self.character:isPrimaryHandItem(self.item)
    end

    function Action:waitToStart()
        self.character:faceThisObject(self.fuelStation)
        return self.character:shouldBeTurning()
    end

    function Action:update()
        self.character:faceThisObject(self.fuelStation)
        local delta = self:getJobDelta()
        self.item:setJobDelta(delta)

        local df = self.dFuel * delta - self.fuelTransferred
        if df >= 1 then
            self:checkFuel(df)
        end

        self.character:setMetabolicTarget(Metabolics.HeavyDomestic)
    end

    function Action:start()

        self.dFuel = math.min(tonumber(self.fuelStation:getSprite():getProperties():Val("fuelAmount")) - tonumber(self.fuelStation:getPipedFuelAmount()),self.item:getRemainingUses())
        self.fuelTransferred = 0

        self.action:setTime(self.dFuel * 50)
        self:setActionAnim("refuelgascan")
        self:setOverrideHandModels(self.item:getStaticModel(),nil)

        self.sound = self.character:playSound("CanisterAddFuelSiphon")

    end

    function Action:stop()
        self.character:stopOrTriggerSound(self.sound)
        self.item:setJobDelta(0.0)

        self:checkFuel()

        ISBaseTimedAction.stop(self)
    end

    function Action:perform()
        self.character:stopOrTriggerSound(self.sound)
        self.item:setJobDelta(0)

        self:checkFuel()

        if self.addAll then IFP.onAddFuel(self.character,self.fuelStation,nil,true) end

        ISBaseTimedAction.perform(self)
    end

    function Action:checkFuel(df) --java commands only accept int in v41.78, even though it is saved as double in modData
        df = math.floor(df or (self.dFuel * self:getJobDelta() - self.fuelTransferred))
        if df > 0 then
            for i = 1, df do
                self.item:Use()
            end
            self.fuelStation:setPipedFuelAmount(tonumber(self.fuelStation:getPipedFuelAmount()) + df)
            self.fuelTransferred = self.fuelTransferred + df
        end
    end

    IFP.Action = Action
end

function IFP.onAddFuel(character,pump,item,all)
    if luautils.walkAdj(character, pump:getSquare(), true) then --:getAdjacentSquare(IsoDirections.W)
        item = ISWorldObjectContextMenu.equip(character, character:getPrimaryHandItem(), all and predicatePetrol or item, true, false)
        if item ~= nil then ISTimedActionQueue.add(IFP.Action:new(character, pump, item, all)) end
    end
end

function IFP.OnFillWorldObjectContextMenu(player, context, worldobjects, test)
    if test and ISWorldObjectContextMenu.Test then return true end
    local tileObj = haveFuel
    if tileObj ~= nil then
        tileObj = IFP.tiles[tileObj:getTextureName()] and tileObj
    else
        local checked = {}
        for _,object in ipairs(worldobjects) do
            local square = object:getSquare()
            if not checked[square] then
                checked[square] = true
                tileObj = IFP.getPumpOnSquare(square)
                if tileObj ~= nil then break end
            end
        end
    end
    if tileObj then
        local character = getSpecificPlayer(player)
        local fuelFull = tonumber(tileObj:getPipedFuelAmount()) / tonumber(tileObj:getSprite():getProperties():Val("fuelAmount")) * 100
        local fuelItems = character:getInventory():getAllEvalRecurse(predicatePetrol)
        local count = fuelItems:size()

        local option = context:addOption(string.format("%s %d%%",getText("ContextMenu_GeneratorAddFuel"),fuelFull))
        if count == 0 or fuelFull >= 100 then
            option.notAvailable = true
        else
            if test then return ISWorldObjectContextMenu.setTest() end
            local subMenu = context:getNew(context)
            context:addSubMenu(option, subMenu)
            if count > 1 then
                if test then return ISWorldObjectContextMenu.setTest() end
                subMenu:addOption(getText("ContextMenu_AllWithCount",count), character, IFP.onAddFuel, tileObj, nil, true)
            end
            for i = 0, count - 1 do
                if test then return ISWorldObjectContextMenu.setTest() end
                local item = fuelItems:get(i)
                subMenu:addOption(string.format("%s %d%%",item:getName(),item:getUsedDelta()*100), character, IFP.onAddFuel, tileObj, item, false)
            end
        end
    end
end

Events.OnPreFillWorldObjectContextMenu.Add(IFP.OnFillWorldObjectContextMenu)
