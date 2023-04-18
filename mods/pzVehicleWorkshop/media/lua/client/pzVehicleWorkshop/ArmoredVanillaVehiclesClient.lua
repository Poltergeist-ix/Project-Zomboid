local pzVehicleWorkshop = pzVehicleWorkshop
local ArmoredVanillaCars = pzVehicleWorkshop.ArmoredVanillaCars or {}

--function ArmoredVanillaCars.addUpgradeOptions(self,x,y)
--    if isGamePaused() then return end
--    local playerObj = getSpecificPlayer(self.playerNum)
--    local player = playerObj
--    if playerObj:getVehicle() ~= nil and not (isDebugEnabled() or (isClient() and (isAdmin() or getAccessLevel() == "moderator"))) then return end
--    if not (self.context and self.context:isReallyVisible()) then
--        self.context = ISContextMenu.get(self.playerNum, x + self:getAbsoluteX(), y + self:getAbsoluteY())
--    end
--
--    local recipe = ArmoredVanillaCars.definitions[self.vwVehicleSettings.id].upgradeRecipe
--    recipe = recipe ~= nil and getScriptManager():getRecipe(recipe)
--    if recipe ~= nil then
--        local tool = player:getInventory():getFirstTagEvalRecurse("WeldingMask")
--        local option = self.context:addOption(getText("Upgrade %1",getText("IGUI_VehicleName" .. self.vehicle:getScript():getName())), player, ArmoredVanillaCars.OnUpgrade,recipe,tool, self) --text
--        if not tool or not RecipeManager.IsRecipeValid(recipe,playerObj,tool,ISInventoryPaneContextMenu.getContainers(playerObj)) then
--            --option.notAvailable = true
--        end
--    end
--end

function ArmoredVanillaCars.openPanel(settings,window)
    local def = {}
    for i = 1, #window.bodyworklist.items do
        local part = window.bodyworklist.items[i].item.part
        if part ~= nil then
            local partId = part:getId()
            local sub, n = partId:gsub("^Armor_","")
            if n == 1 then
                def[partId] = sub
            end
        end
    end

    local popped = {}
    local index = 0
    for i, item in ipairs(window.bodyworklist.items) do
        local part = item.item.part
        local id = part and part:getId()

        if def[id] then
            popped[def[id]] = item
        else
            index = index + 1
            item.itemindex = index
            window.bodyworklist.items[index] = item
            if popped[id] then
                index = index + 1
                popped[id].itemindex = index
                window.bodyworklist.items[index] = popped[id]
                popped[id] = nil
            end
        end
    end
    if not table.isempty(popped) then
        print("AVC Warning: bad parts")
        local cat = {name="Misc Armor",cat=true}
        local item = window.bodyworklist:addItem(cat.name,cat)
        index = index + 1
        item.itemindex = index
        window.bodyworklist.items[index] = item
        for i,v in pairs(popped) do
            index = index + 1
            v.itemindex = index
            window.bodyworklist.items[index] = v
        end
    end
end

function ArmoredVanillaCars.drawArmorItems(settings,window,y,item,alt)
    if item.item.part ~= nil and item.item.part:getInventoryItem() == nil and item.item.part:getId():find("^Armor_") ~= nil then
        window:drawText(item.item.name, 20, y, 0.4, 0.32, 0.32, 1, UIFont.Small)

        return y + window.itemheight
    end
end

function ArmoredVanillaCars.OnUpgrade(player, recipe, item, ui)

    ArmoredVanillaCars.OnUpgradeTest1(player, recipe, item, ui.vehicle)
    --ArmoredVanillaCars.OnUpgradeTest2(player, recipe, item)
    ui:initParts()
end

function ArmoredVanillaCars.OnUpgradeTest1(player, recipe, item, vehicle)
    local scriptName = "AVC.CarStationWagonTiered"
    local skinIndex = vehicle:getSkinIndex()
    --vehicle:setScript(scriptName)
    vehicle:setScriptName(scriptName)
    vehicle:scriptReloaded()
    vehicle:setSkinIndex(skinIndex)
    --ArmoredVanillaCars.OnUpgradeTest2(player, recipe, item)
end

function ArmoredVanillaCars.OnUpgradeTest2(player, recipe, item)
    local containers = ISInventoryPaneContextMenu.getContainers(player)
    local container = item:getContainer()
    local selectedItemContainer = item:getContainer()
    if not recipe:isCanBeDoneFromFloor() then
        container = player:getInventory()
    end
    local items = RecipeManager.getAvailableItemsNeeded(recipe, player, containers, item, nil)
    local returnToContainer = {}; -- keep track of items we moved to put them back to their original container
    if not recipe:isCanBeDoneFromFloor() then
        for i=1,items:size() do
            local item = items:get(i-1)
            if item:getContainer() ~= player:getInventory() then
                ISTimedActionQueue.add(ISInventoryTransferAction:new(player, item, item:getContainer(), player:getInventory(), nil))
                table.insert(returnToContainer, item)
            end
        end
    end

    -- in case of movable dismantling equip tools:
    if instanceof(recipe, "MovableRecipe") then
        local primaryTool = RecipeManager.GetMovableRecipeTool(true, recipe, item, player, containers);
        if primaryTool then
            ISWorldObjectContextMenu.equip(player, player:getPrimaryHandItem(), primaryTool, true)
        end

        local secondaryTool = RecipeManager.GetMovableRecipeTool(false, recipe, item, player, containers);
        if secondaryTool then
            ISWorldObjectContextMenu.equip(player, player:getSecondaryHandItem(), secondaryTool, false)
        end
    end
    local additionalTime = 0
    if container == player:getInventory() and recipe:isCanBeDoneFromFloor() then
        for i=1,items:size() do
            local item = items:get(i-1)
            if item:getContainer() ~= player:getInventory() then
                local w = item:getActualWeight()
                if w > 3 then w = 3; end;
                additionalTime = additionalTime + 50*w
            end
        end
    end
    local action = ISCraftAction:new(player, item, recipe:getTimeToMake() + additionalTime, recipe, container, containers)
    if all then
        action:setOnComplete(ISInventoryPaneContextMenu.OnCraftComplete, action, recipe, player, container, containers, item:getFullType(), selectedItemContainer)
    end
    ISTimedActionQueue.add(action)

    -- add back their item to their original container
    ISCraftingUI.ReturnItemsToOriginalContainer(player, returnToContainer)

end

function ArmoredVanillaCars.showVehicleTierLevel()
    if not self.vwBodyworklistElement then
        local x,y,w,h = self.bodyworklist:getX(), self.bodyworklist:getY() - (self.vwBodyworklistOffset or 0), self.bodyworklist:getWidth(), UI.settings.fontMediumHeight
        function returnFalse() return false end

        local panel = ISPanel:new(x,y,w,h)
        panel.borderColor = {r=0.18, g=0.22, b=0.26, a=1}
        panel.backgroundColor = {r=0.12, g=0.14, b=0.16, a=0.7}
        --panel.onRightMouseUp = function(child,x,y) return self:onRightMouseUp(child.x + x,child.y + y) end
        panel.onRightMouseUp = returnFalse
        panel:instantiate()
        local obj = panel.javaObject
        obj:backMost()
        obj:setAlwaysOnTop(false)
        --obj:setCapture(false)
        --obj:setIgnoreLossControl(true)
        obj:setConsumeMouseEvents(false)
        self.vwBodyworklistElement = panel
        self:addChild(panel)
        local offset = math.floor((h - 12)/2) --getHeight
        panel.image = ISImage:new(2, offset, h, h, getTexture("QualityStar_5") ) --save text
        panel.image.onRightMouseUp = returnFalse

        panel:addChild(panel.image)

        panel.label = ISLabel:new(20, 0, UI.settings.fontMediumHeight, getText("Tier %1 Vehicle",tostring(1)), self.partCatRGB.r, self.partCatRGB.g, self.partCatRGB.b, self.partCatRGB.a, UIFont.Medium, true)
        panel.label.onRightMouseUp = returnFalse
        panel:addChild(panel.label)
    end
end

function ArmoredVanillaCars.onAddArmor(player, vehicle, part, item, recipe, containers)
    if ISVehicleMechanics.cheat then
        ISTimedActionQueue.add(pzVehicleWorkshop.installAction:new(player, vehicle, part, item, recipe, containers))
    else
        local pathAction = pzVehicleWorkshop.ActionUtil.pathToPart(player, vehicle, part)
        pathAction:setOnComplete(function()
            if RecipeManager.IsRecipeValid(recipe, player, item, containers) then
                pzVehicleWorkshop.ActionUtil.equipForRecipe(player, recipe, containers)
                ISTimedActionQueue.add(pzVehicleWorkshop.installAction:new(player, vehicle, part, item, recipe, containers))
            end
        end)
    end
end

function ArmoredVanillaCars.onRemoveArmor(player,vehicle,part,item,recipe,containers)
    if ISVehicleMechanics.cheat then
        ISTimedActionQueue.add(pzVehicleWorkshop.uninstallAction:new(player, vehicle, part, item, recipe, containers))
    else
        local pathAction = pzVehicleWorkshop.ActionUtil.pathToPart(player, vehicle, part)
        pathAction:setOnComplete(function()
            if RecipeManager.IsRecipeValid(recipe, player, item, containers) then
                pzVehicleWorkshop.ActionUtil.equipForRecipe(player, recipe, containers)
                ISTimedActionQueue.add(pzVehicleWorkshop.uninstallAction:new(player, vehicle, part, item, recipe, containers))
            end
        end)
    end
end

function ArmoredVanillaCars.addArmorOptions(settings,self,part,x,y)
    local hasOptions
    local context = self.context
    if part:getInventoryItem() ~= nil then
        local unmount = part:getTable("unmountRecipes")
        if unmount ~= nil then
            local player = self.playerObj
            local playerInv = player:getInventory()
            local containers = ISInventoryPaneContextMenu.getContainers(player)
            local partText = getText("IGUI_VehiclePart" .. part:getId())
            for _,recipeName in ipairs(unmount) do
                local recipe = getScriptManager():getRecipe(recipeName)
                if recipe ~= nil then
                    --local fullType = recipe:getSource():get(0):getItems():get(0)
                    --local item = playerInv:getFirstType(fullType) or ISVehicleMechanics.cheat and playerInv:AddItem(fullType)
                    --local valid = item and RecipeManager.IsRecipeValid(recipe, player, item, containers) or ISVehicleMechanics.cheat
                    --local option = context:addOption(getText("IGUI_Uninstall") .. " " .. partText, player, ArmoredVanillaCars.onRemoveArmor, self.vehicle, part, containers) --text
                    --if not valid then
                    --    option.notAvailable = true
                    --end

                    local keyInv = InventoryItemFactory.CreateItem("KeyRing"):getInventory()
                    containers:add(keyInv)
                    local item = keyInv:AddItem("CarKey")
                    item:getModData().vehicleObj = self.vehicle
                    item:getModData().unmountCarPart = part
                    local valid = RecipeManager.IsRecipeValid(recipe, player, item, containers) or ISVehicleMechanics.cheat

                    local option = context:addOption(getText("IGUI_Uninstall") .. " " .. partText, player, ArmoredVanillaCars.onRemoveArmor, self.vehicle, part, item, recipe, containers) --text
                    if not valid then
                        option.notAvailable = true
                    end
                    local tooltip = ISRecipeTooltip.addToolTip()
                    tooltip.character = player
                    tooltip.recipe = recipe
                    tooltip:setName(recipe:getName())
                    --if resultItem:getTexture() and resultItem:getTexture():getName() ~= "Question_On" then
                    --    tooltip:setTexture(resultItem:getTexture():getName())
                    --end
                    option.toolTip = tooltip


                else
                    local option = context:addOption(getText("Recipe %1 not found ",recipeName))
                    option.notAvailable = true
                end
            end

            hasOptions = true
        end
    else
        local mount = part:getTable("mountRecipes")
        if mount ~= nil then
            local player = self.playerObj
            local playerInv = player:getInventory()
            local containers = ISInventoryPaneContextMenu.getContainers(player)
            local partText = getText("IGUI_VehiclePart" .. part:getId())
            for _,recipeName in ipairs(mount) do
                local recipe = getScriptManager():getRecipe(recipeName)
                if recipe ~= nil then

                    --local fullType = recipe:getSource():get(0):getItems():get(0)
                    --local item = playerInv:getFirstType(fullType) or ISVehicleMechanics.cheat and playerInv:AddItem(fullType)
                    --local valid = item and RecipeManager.IsRecipeValid(recipe, player, item, containers) or ISVehicleMechanics.cheat

                    --local fullType = "Base.CarKey"
                    --local item = self.vehicle:createKey()
                    --local item = InventoryItemFactory.CreateItem("CarKey")
                    local keyInv = InventoryItemFactory.CreateItem("KeyRing"):getInventory()
                    containers:add(keyInv)
                    local item = keyInv:AddItem("CarKey")
                    item:getModData().vehicleObj = self.vehicle
                    local valid = RecipeManager.IsRecipeValid(recipe, player, item, containers) or ISVehicleMechanics.cheat

                    local option = context:addOption(getText("IGUI_Install") .. " " .. partText, player, ArmoredVanillaCars.onAddArmor, self.vehicle, part, item, recipe, containers) --text
                    if not valid then
                        option.notAvailable = true
                    end
                    local tooltip = ISRecipeTooltip.addToolTip()
                    tooltip.character = player
                    tooltip.recipe = recipe
                    tooltip:setName(recipe:getName())
                    --if resultItem:getTexture() and resultItem:getTexture():getName() ~= "Question_On" then
                    --    tooltip:setTexture(resultItem:getTexture():getName())
                    --end
                    option.toolTip = tooltip

                else
                    local option = context:addOption(getText("Recipe %1 not found ", recipeName))
                    option.notAvailable = true
                end
            end
            hasOptions = true
        end
    end

    if hasOptions then self.context:setVisible(true) end
end

do
    local VehicleSettings = pzVehicleWorkshop.VehicleSettings

    for mod, base in pairs(pzVehicleWorkshop.ArmoredVanillaVehicles.armorVehicles ) do
        VehicleSettings.add{
            id = mod,
            VehicleMechanics_OnOpen = ArmoredVanillaCars.openPanel,
            VehicleMechanics_DrawItems = ArmoredVanillaCars.drawArmorItems,
            VehicleMechanics_PartContext = ArmoredVanillaCars.addArmorOptions,
        }
    end
end

--[[
--for _,scriptName in ipairs({"Base.CarStationWagon","Base.CarStationWagon2"}) do
--    ArmoredVanillaCars.definitions[scriptName] = {
--        upgradeRecipe = "AVC.UpgradeVehicleType1",
--    }
--
--    modTable.UI.add{
--        vehicle = scriptName,
--        VehicleMechanics = {
--            vehicleContext = ArmoredVanillaCars.addUpgradeOptions,
--        }
--    }
--end
--]]

pzVehicleWorkshop.ArmoredVanillaCars = ArmoredVanillaCars