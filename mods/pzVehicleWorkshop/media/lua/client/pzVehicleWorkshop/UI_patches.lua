local modTable = require "pzVehicleWorkshop/Definitions"

local UI = {}

function UI.add(config)
    if config.VehicleMechanics ~= nil then
        local vehicleSettings = UI.VehicleMechanics.vehicleSettings[config.vehicle] or {id=config.vehicle}
        for k,v in pairs (config.VehicleMechanics) do
            if type(v) == "function" then
                if vehicleSettings[k] then table.insert(vehicleSettings[k],v) else vehicleSettings[k] = {v} end
            end
        end
        UI.VehicleMechanics.vehicleSettings[config.vehicle] = vehicleSettings
    end
end

UI.settings = {
    fontSmallHeight = getTextManager():getFontHeight(UIFont.Small),
    fontMediumHeight = getTextManager():getFontHeight(UIFont.Medium)
}

--[[ VehicleMechanics functions
TODO pass conf table together with call // vehicleConf:onOpen(window)
]]
UI.VehicleMechanics = {}
UI.VehicleMechanics.vehicleSettings = {}

function UI.VehicleMechanics.updateTitle(window,vehicleSettings)
    window.extraTitleSpace = 0
    local prevTitle = window.VWTitle
    local newTitle = vehicleSettings and vehicleSettings:get("VehicleMechanicsTitle",window)--todo get set visible if already has an obj // may want to refresh so call again
    if prevTitle and prevTitle ~= newTitle then
        prevTitle:setVisible(false)
    end
    if newTitle ~= nil then
        window.VWTitle = newTitle
        window.extraTitleSpace = newTitle.y
    end
end

function UI.VehicleMechanics.onOpenPanel(window)
    local t = (window.vwVehicleSettings or {}).openPanel
    if not t then return end
    for _,f in ipairs(t) do
        f(window)
    end
end

--[[
pass context
if prev options and not visible get new
if not visible and options then set visible
--]]
function UI.VehicleMechanics.doVehicleContext(self,x,y)
    --print("UI.VehicleMechanics.doVehicleContext")
    local contextCalls = (self.vwVehicleSettings or {}).vehicleContext
    if not contextCalls then return end
    for _,f in ipairs(contextCalls) do
        f(self,x,y)
    end
end


--[[ VehicleMechanics patches ]]
UI.VehicleMechanicsPatches = {}

--function UI.VehicleMechanicsPatches.titleBarHeight(titleBarHeight) --doesn't work as intended // makes title bar bigger
--    return function(self)
--        return titleBarHeight(self) + (self.extraTitleSpace or 0)
--    end
--end

function UI.VehicleMechanicsPatches.initParts(initParts)
    return function(self)
        initParts(self)
        if not self.vehicle then return end

        local vehicleScriptName = self.vehicle:getScriptName()
        self.vwVehicleSettings = UI.VehicleMechanics.vehicleSettings[vehicleScriptName]

        --[[ prev state ]]

        --[[ calls ]]
        UI.VehicleMechanics.onOpenPanel(self)

        --[[ finish ]]
    end
end

function UI.VehicleMechanicsPatches.doPartContextMenu(doPartContextMenu)
    local function addArmor(player, vehicle, part, item, recipe, containers)
        print("add armor ",player, part, item, recipe, containers)

        --local action = modTable.installAction:new(player,part,item,recipe:getTimeToMake())
        --action.vehicleRecipe = recipe
        --action.containers = containers
        --ISTimedActionQueue.add(action)

        local result = InventoryItemFactory.CreateItem(recipe:getResult():getFullType())
        sendClientCommand(player, 'pzVehicleWorkshop', 'setItemPart',  { vehicle = vehicle:getId(), part = part:getId(), item = result, setModelFromType = true })

    end
    local function removeArmor(player,vehicle,part)
        --print("removeArmor ",player,vehicle,part)
        sendClientCommand(player, 'pzVehicleWorkshop', 'setItemPart',  { vehicle = vehicle:getId(), part = part:getId(), item = false })
    end

    return function(self,part,x,y)
        doPartContextMenu(self,part,x,y)

        if isGamePaused() then return end
        local player = getSpecificPlayer(self.playerNum)
        if player:getVehicle() ~= nil and not (isDebugEnabled() or (isClient() and (isAdmin() or getAccessLevel() == "moderator"))) then return end

        local hasOptions
        local context = self.context
        if part:getInventoryItem() ~= nil then
            local unmount = part:getTable("unmountRecipes")
            if unmount ~= nil then
                local partText = getText("IGUI_VehiclePart" .. part:getId())
                local playerInv = player:getInventory()
                local containers = ISInventoryPaneContextMenu.getContainers(player)
                for _,recipeName in ipairs(unmount) do
                    local recipe = getScriptManager():getRecipe(recipeName)
                    if recipe ~= nil then
                        local fullType = recipe:getSource():get(0):getItems():get(0)
                        local item = playerInv:getFirstType(fullType) or getDebug() and player:getInventory():AddItem(fullType) --fixme
                        local valid = RecipeManager.IsRecipeValid(recipe, player, item, containers)
                        local option = context:addOption(getText("IGUI_Uninstall") .. " " .. partText, player, removeArmor, self.vehicle, part, containers) --text
                        if not valid then
                            option.notAvailable = true
                        end
                    else
                        local option = context:addOption(getText("Recipe %1 for %2 not found ", recipeName, partText))
                        option.notAvailable = true
                    end
                end
                hasOptions = true
            end
        else
            local mount = part:getTable("mountRecipes")
            if mount ~= nil then
                local partText = getText("IGUI_VehiclePart" .. part:getId())
                local playerInv = player:getInventory()
                local containers = ISInventoryPaneContextMenu.getContainers(player)
                for _,recipeName in ipairs(mount) do
                    local recipe = getScriptManager():getRecipe(recipeName)
                    if recipe ~= nil then
                        local fullType = recipe:getSource():get(0):getItems():get(0)
                        local item = playerInv:getFirstType(fullType) or getDebug() and InventoryItemFactory.CreateItem("")--player:getInventory():AddItem(fullType) --fixme
                        local valid = item and RecipeManager.IsRecipeValid(recipe, player, item, containers)
                        local option = context:addOption(getText("IGUI_Install") .. " " .. partText, player, addArmor, self.vehicle, part, item, recipe, containers) --text
                        if not valid then
                            option.notAvailable = true
                        end
                    else
                        local option = context:addOption(getText("Recipe %1 for %2 not found ", recipeName, partText))
                        option.notAvailable = true
                    end
                end
                hasOptions = true
            end

            --if part:getTable("mount") then
            --    local containerList = ISInventoryPaneContextMenu.getContainers(player)
            --    for i = 0, part:getItemType():size() - 1 do
            --        local itemType = part:getItemType():get(i)
            --        local item = player:getInventory():getFirstType(itemType) or getDebug() and player:getInventory():AddItem(itemType)
            --        local recipes = RecipeManager.getUniqueRecipeItems(item, player, containerList) --only shows recipes that can be done
            --        if recipes ~= nil then
            --            context:addOption("Add Armor to " .. getText("IGUI_VehiclePart" .. part:getId()), player,addArmor,self.vehicle,part,item,itemType)
            --        end
            --    end
            --end
        end

        if hasOptions then context:setVisible(true) end

        if JoypadState.players[self.playerNum + 1] then UI.VehicleMechanics.doVehicleContext(self,x,y) end
    end
end

function UI.VehicleMechanicsPatches.onRightMouseUp(onRightMouseUp)
    return function(self,x,y)
        onRightMouseUp(self,x,y)

        UI.VehicleMechanics.doVehicleContext(self,x,y)
    end
end

function UI.patchISVehicleMechanics(ISVehicleMechanics)
    for key,patchFn in pairs(UI.VehicleMechanicsPatches) do
        ISVehicleMechanics[key] = patchFn(ISVehicleMechanics[key])
    end
end

local function reloaded()
    local id = 0
    local data = getPlayerData(id)
    if not data then return end
    local instance = data.mechanicsUI
    reloadLuaFile("media/lua/client/Vehicles/ISUI/ISVehicleMechanics.lua")

    UI.patchISVehicleMechanics(ISVehicleMechanics)
    data.mechanicsUI = ISVehicleMechanics:new(0,0,getPlayer(),nil)
    --data.mechanicsUI.initParts = UI.patchISVehicleMechanics_initParts(ISVehicleMechanics.initParts)
end
if getPlayer() then reloaded() end

modTable.UI = UI
return UI