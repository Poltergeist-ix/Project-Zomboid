local pzVehicleWorkshop = pzVehicleWorkshop

do
    require "TimedActions/ISCraftAction"
    local Action = ISCraftAction:derive("pzVehicleWorkshop_CraftAction")

    function Action:new(character, vehicle, part, item, recipe, containers)
        local o = {}
        setmetatable(o, self)
        self.__index = self
        o.character = character
        o.vehicle = vehicle
        o.part = part
        o.recipe = recipe
        o.item = item
        --o.container = recipe:isCanBeDoneFromFloor() and item:getContainer() or character:getInventory() --item key is not in container
        o.containers = recipe:isCanBeDoneFromFloor() and containers or nil
        o.stopOnWalk = recipe:isStopOnWalk()
        o.stopOnRun = recipe:isStopOnRun()
        o.jobType = recipe:getName()
        --o.forceProgressBar = true
        if character:isTimedActionInstant() or ISVehicleMechanics.cheat then
            o.maxTime = 1
        else
            o.maxTime = recipe:getTimeToMake()

            local count = recipe:getRequiredSkillCount()
            if count > 0 then
                local sum = 0
                for i = 0, count - 1 do
                    local reqSkill = recipe:getRequiredSkill(i)
                    sum = sum + character:getPerkLevel(reqSkill:getPerk()) - reqSkill:getLevel()
                end
                o.maxTime = o.maxTime - o.maxTime / 20 * sum / count
            end
        end
        --jobtype
        return o
    end

    function Action:isValid()
        return RecipeManager.IsRecipeValid(self.recipe, self.character, self.item, self.containers) or ISVehicleMechanics.cheat
    end
    
    function Action:waitToStart()
        if ISVehicleMechanics.cheat then return false end
        self.character:faceThisObject(self.vehicle)
        return self.character:shouldBeTurning()
    end

    function Action:update()
        self.character:faceThisObject(self.vehicle)
        self.character:setMetabolicTarget(Metabolics.UsingTools)
    end

    function Action:start()
        if self.recipe:getSound() then
            self.craftSound = self.character:playSound(self.recipe:getSound())
        end

        --self.item:setJobType(self.recipe:getName())
        --self.item:setJobDelta(0.0)
        if self.recipe:getProp1() or self.recipe:getProp2() then
            self:setOverrideHandModels(self:getPropItemOrModel(self.recipe:getProp1()), self:getPropItemOrModel(self.recipe:getProp2()))
        end
        if self.recipe:getAnimNode() then
            self:setActionAnim(self.recipe:getAnimNode())
        else
            if self.part:getWheelIndex() ~= -1 or self.part:getId():contains("Brake") then
                self:setActionAnim("VehicleWorkOnTire")
            else
                self:setActionAnim("VehicleWorkOnMid")
            end
        end
    end
    
    function Action:stop()
        if self.craftSound and self.character:getEmitter():isPlaying(self.craftSound) then
            self.character:stopOrTriggerSound(self.craftSound)
        end
        --self.item:setJobDelta(0.0)
        ISBaseTimedAction.stop(self)
    end
    
    function Action:perform()
        --self.item:setJobDelta(0.0)
        if self.craftSound and self.character:getEmitter():isPlaying(self.craftSound) then
            self.character:stopOrTriggerSound(self.craftSound)
        end
        if ISVehicleMechanics.cheat then
            if not self.recipe:isRemoveResultItem() then
                self.resultItem = InventoryItemFactory.CreateItem(self.recipe:getResult():getFullType())
            end
        else
            self.resultItem = RecipeManager.PerformMakeItem(self.recipe, self.item, self.character, self.containers)
        end

        self:onPerform()

        --self.container:setDrawDirty(true)
        ISInventoryPage.dirtyUI()

        -- needed to remove from queue / start next.
        ISBaseTimedAction.perform(self)
    end

    function Action:onPerform()
        self:addOrDropResult(self.containers~=nil)
    end

    function Action:addOrDropResult(toFloor)
        if self.resultItem == nil then return end
        if not toFloor then
            local inv = self.character:getInventory()
            if inv:getCapacityWeight() + self.resultItem:getWeight() < inv:getEffectiveCapacity(self.character) then
                inv:AddItem(self.resultItem)
                return
            end
        end
        if instanceof(self.resultItem, "Moveable") and not self.resultItem:CanBeDroppedOnFloor() then
            return --bye bye
        end
        self.character:getCurrentSquare():AddWorldInventoryItem(self.resultItem, self.character:getX() %1, self.character:getY() %1, self.character:getZ() %1)
    end

    pzVehicleWorkshop.VehicleCraftAction = Action
end

do
    local Action = pzVehicleWorkshop.VehicleCraftAction:derive("pzVehicleWorkshop_InstallAction")

    function Action:new(character, vehicle, part, item, recipe, containers)
        local o = pzVehicleWorkshop.VehicleCraftAction.new(self, character, vehicle, part, item, recipe, containers)
        o.jobType = getText("Tooltip_Vehicle_Installing", getText("IGUI_VehiclePart" .. part:getId()))
        return o
    end

    --function Action:isValid()
    --    return ISVehicleMechanics.cheat or self.vehicle:canInstallPart(self.character, self.part) and RecipeManager.IsRecipeValid(self.vehicleRecipe, self.character, self.item, self.containers)
    --end

    function Action:onPerform()
        sendClientCommand(self.character, 'pzVehicleWorkshop', 'setPartItem',  { vehicle = self.vehicle:getId(), part = self.part:getId(), item = self.resultItem, setModelFromType = true })
    end

    pzVehicleWorkshop.installAction = Action
end

do
    local Action = pzVehicleWorkshop.VehicleCraftAction:derive("pzVehicleWorkshop_UninstallAction")

    function Action:new(character, vehicle, part, item, recipe, containers)
        local o = pzVehicleWorkshop.VehicleCraftAction.new(self, character, vehicle, part, item, recipe, containers)
        o.jobType = getText("Tooltip_Vehicle_Uninstalling", getText("IGUI_VehiclePart" .. part:getId()))
        return o
    end

    --function Action:isValid()
    --    return ISVehicleMechanics.cheat or self.part:getInventoryItem() and self.vehicle:canUninstallPart(self.character, self.part) and RecipeManager.IsRecipeValid(self.vehicleRecipe, self.character, self.item, self.containers)
    --end

    function Action:onPerform()
        sendClientCommand(self.character, 'pzVehicleWorkshop', 'setPartItem',  { vehicle = self.vehicle:getId(), part = self.part:getId(), item = false })
    end

    pzVehicleWorkshop.uninstallAction = Action
end
