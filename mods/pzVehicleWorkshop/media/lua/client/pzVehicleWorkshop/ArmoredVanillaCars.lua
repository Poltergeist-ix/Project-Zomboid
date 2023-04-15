local pzVehicleWorkshop = pzVehicleWorkshop
local ArmoredVanillaCars = {}
ArmoredVanillaCars.definitions = {}

function ArmoredVanillaCars.addUpgradeOptions(self,x,y)
    if isGamePaused() then return end
    local playerObj = getSpecificPlayer(self.playerNum)
    local player = playerObj
    if playerObj:getVehicle() ~= nil and not (isDebugEnabled() or (isClient() and (isAdmin() or getAccessLevel() == "moderator"))) then return end
    if not (self.context and self.context:isReallyVisible()) then
        self.context = ISContextMenu.get(self.playerNum, x + self:getAbsoluteX(), y + self:getAbsoluteY())
    end

    local recipe = ArmoredVanillaCars.definitions[self.vwVehicleSettings.id].upgradeRecipe
    recipe = recipe ~= nil and getScriptManager():getRecipe(recipe)
    if recipe ~= nil then
        local tool = player:getInventory():getFirstTagEvalRecurse("WeldingMask")
        local option = self.context:addOption(getText("Upgrade %1",getText("IGUI_VehicleName" .. self.vehicle:getScript():getName())), player, ArmoredVanillaCars.OnUpgrade,recipe,tool, self) --text
        if not tool or not RecipeManager.IsRecipeValid(recipe,playerObj,tool,ISInventoryPaneContextMenu.getContainers(playerObj)) then
            --option.notAvailable = true
        end
    end
end

--[[
        ---sort protection parts to relative items
        ---two tables: vehiclePart unordered categories that contains parts tables / the bodyworklist ordered items
        ---iterate and remove protection, place after part - what if no part ?
        ---^ validate defs when generating them
        ---reverse iterate and move if part found - need move everything again?

        ---get vehicle settings

--]]
function ArmoredVanillaCars.openPanel(window)
    -- cache table, validate
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
    --zx.printTableRecursive(def)

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

function ArmoredVanillaCars.drawArmorItems(def,window,y,item,alt)
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

--[[ ISInventoryPaneContextMenu.OnCraft ]]
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

--[[
moved from patch
window scales with text, resize on open

        --local y1 = self:titleBarHeight() + 10 + 5 + getTextManager():getFontHeight(UIFont.Medium) + getTextManager():getFontHeight(UIFont.Small) * (5 + 1) + 10 --createChildren
        --local h = UI.settings.medLineHeight
        --local x,y,w,h = self.bodyworklist:getX(), y1, self.bodyworklist:getWidth(), h
        --local x,y,w,h = 10, self:titleBarHeight() + 10 + 5, 280, 20

        --self.zxPanel:setX(x)
        --self.zxPanel:setY(y)
        --self.zxPanel:setWidth(w)
        --self.zxPanel:setHeight(h)

        --self.zxPanel:setVisible(true)

        --self.zxPanel.render = function(self) self:drawTextCentre("Tier 1", self.width/2, 5, 1, 0.1, 0.1, 1, UIFont.Small) end
        --self.zxPanel.render = function(self) self:drawText("* Tier 1 Vehicle", 10, 0, 1, 0.1, 0.1, 1, UIFont.Medium) end

        --self.listbox:setY(y)
        --self.bodyworklist:setY(self.vwBodyworklistElement.y + self.vwBodyworklistElement.height)

--]]
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

function ArmoredVanillaCars.onVehicleAction(player, vehicle, part, item, recipe, containers)
    --ISVehiclePartMenu.transferRequiredItems(player, part, tbl)
    --ISVehiclePartMenu.equipRequiredItems(player, part, tbl)
    if not ISVehicleMechanics.cheat then
        if player:getVehicle() ~= nil then
            ISVehicleMenu.onExit(player)
        end
        ISTimedActionQueue.add(ISPathFindAction:pathToVehicleArea(player, vehicle, part:getArea()))
    end
end

function ArmoredVanillaCars.onAddArmor(player, vehicle, part, item, recipe, containers)
    --print("add armor ",player, part, item, recipe, containers)
    ArmoredVanillaCars.onVehicleAction(player, vehicle, part, item, recipe, containers)
    ISTimedActionQueue.add(pzVehicleWorkshop.installAction:new(player, vehicle, part, item, recipe, containers))

    --local result = InventoryItemFactory.CreateItem(recipe:getResult():getFullType())
    --sendClientCommand(player, 'pzVehicleWorkshop', 'setItemPart',  { vehicle = vehicle:getId(), part = part:getId(), item = result, setModelFromType = true })

end

function ArmoredVanillaCars.onRemoveArmor(player,vehicle,part)
    --print("removeArmor ",player,vehicle,part)
    sendClientCommand(player, 'pzVehicleWorkshop', 'setItemPart',  { vehicle = vehicle:getId(), part = part:getId(), item = false })
end

function ArmoredVanillaCars.addArmorOptions(def,self,part,x,y)
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
                    local fullType = recipe:getSource():get(0):getItems():get(0)
                    local item = playerInv:getFirstType(fullType) or ISVehicleMechanics.cheat and playerInv:AddItem(fullType)
                    local valid = item and RecipeManager.IsRecipeValid(recipe, player, item, containers) or ISVehicleMechanics.cheat
                    local option = context:addOption(getText("IGUI_Uninstall") .. " " .. partText, player, ArmoredVanillaCars.onRemoveArmor, self.vehicle, part, containers) --text
                    if not valid then
                        option.notAvailable = true
                    end
                else
                    local option = context:addOption(getText("Recipe %1 not found ", recipeName)) --text
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
                    local item = InventoryItemFactory.CreateItem("KeyRing"):getInventory():AddItem("CarKey")
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
                    local option = context:addOption(getText("Recipe %1 for %2 not found ", recipeName, partText))
                    option.notAvailable = true
                end
            end
            hasOptions = true
        end
    end

    if hasOptions then self.context:setVisible(true) end
end

if getPlayer() and not addDebugDefinitions then return end

--[[ CarStationWagon ]]
local UI = require "pzVehicleWorkshop/UI_patches"
--local ArmoredVanillaCars = require "pzVehicleWorkshop/ArmoredVanillaCars.lua"

local scriptName = "AVC.CarStationWagonTiered"
pzVehicleWorkshop.UI.add{
    vehicle = scriptName,
    VehicleMechanics = {
        openPanel = ArmoredVanillaCars.openPanel,
        customDrawItems = ArmoredVanillaCars.drawArmorItems,
    }
}

pzVehicleWorkshop.add(scriptName,nil,{ partContext = ArmoredVanillaCars.addArmorOptions})

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

return ArmoredVanillaCars