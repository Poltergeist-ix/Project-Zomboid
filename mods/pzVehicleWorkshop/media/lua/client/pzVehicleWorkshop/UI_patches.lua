local modTable = require "pzVehicleWorkshop/Definitions"

local UI = {}

UI.settings = {
    fontSmallHeight = getTextManager():getFontHeight(UIFont.Small),
    fontMediumHeight = getTextManager():getFontHeight(UIFont.Medium)
}

---VehicleMechanics functions
UI.VehicleMechanics = {}
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

---VehicleMechanics patches
UI.VehicleMechanicsPatches = {}

function UI.VehicleMechanicsPatches.titleBarHeight(titleBarHeight)
    return function(self)
        return titleBarHeight(self) + (self.extraTitleSpace or 0)
    end
end

function UI.VehicleMechanicsPatches.initParts(initParts)
    return function(self)
        initParts(self)
        if not self.vehicle then return end

        ---sort protection parts to relative items
        ---two tables: vehiclePart unordered categories that contains parts tables / the bodyworklist ordered items
        ---iterate and remove protection, place after part - what if no part ?
        ---^ validate defs when generating them
        ---reverse iterate and move if part found - need move everything again?

        ---get vehicle settings
        local vehiclesToSort = { ["AVC.CarStationWagonTiered"] = true }
        --local vehicleSettings = vehiclesToSort
        --self.vwVehicleSettings = {}

        ---UI.VehicleMechanics.updateTitle(self, vehicleSettings)
        --window scales with text, resize on open
        if not self.vwBodyworklistElement then
            local x,y,w,h = self.bodyworklist:getX(), self.bodyworklist:getY() - (self.vwBodyworklistOffset or 0), self.bodyworklist:getWidth(), UI.settings.fontMediumHeight

            local panel = ISPanel:new(x,y,w,h)
            panel.borderColor = {r=0.18, g=0.22, b=0.26, a=1}
            panel.backgroundColor = {r=0.12, g=0.14, b=0.16, a=0.7}
            self.vwBodyworklistElement = panel
            self:addChild(panel)

            local offset = math.floor((h - 12)/2) --getHeight
            panel.image = ISImage:new(2, offset, h, h, getTexture("QualityStar_5") ) --save text
            panel:addChild(panel.image)

            panel.label = ISLabel:new(20, 0, UI.settings.fontMediumHeight, getText("Tier %1 Vehicle",tostring(1)), self.partCatRGB.r, self.partCatRGB.g, self.partCatRGB.b, self.partCatRGB.a, UIFont.Medium, true)
            panel:addChild(panel.label)
        end

        local y1 = self:titleBarHeight() + 10 + 5 + getTextManager():getFontHeight(UIFont.Medium) + getTextManager():getFontHeight(UIFont.Small) * (5 + 1) + 10 --createChildren

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
        self.bodyworklist:setY(self.vwBodyworklistElement.y + self.vwBodyworklistElement.height)

        zxtest = self.vwBodyworklistElement
        if not vehiclesToSort[self.vehicle:getScriptName()] then
            return
        end

        ---generate list if it doesn't exist
        local def = {}
        local def2 = {}
        for i = 1, #self.bodyworklist.items do
            local part = self.bodyworklist.items[i].item.part
            if part ~= nil then
                local partId = part:getId()
                local sub, n = partId:gsub("^Armor_","")
                if n == 1 then
                    def[partId] = sub
                    def2[sub] = partId
                end
            end
        end

        --local index = 2
        --while true do
        --    local part = self.bodyworklist.items[index].item.part
        --    if part then
        --        local partId = part:getId()
        --        local iSub = part:getId():find("Protection$")
        --        if iSub ~= nil then
        --            def[partId] = partId:sub(0,iSub-1)
        --        end
        --        index = index + 1
        --    else
        --        break
        --    end
        --end
        --zx.printTableRecursive(self.bodyworklist.items)
        zx.printTableRecursive(def)

        ---sort test

        local popped = {}
        local index = 0
        for i,item in ipairs(self.bodyworklist.items) do
            local part = item.item.part
            local id = part and part:getId()

            if def[id] then
                popped[def[id]] = item
            else
                index = index + 1
                item.itemindex = index
                self.bodyworklist.items[index] = item
                if popped[id] then
                    index = index + 1
                    popped[id].itemindex = index
                    self.bodyworklist.items[index] = popped[id]
                    popped[id] = nil
                end
            end
        end
        if not table.isempty(popped) then
            print("AVC Warning: bad parts")
            local cat = {name="Misc Armor",cat=true}
            local item = self.bodyworklist:addItem(cat.name,cat)
            index = index + 1
            item.itemindex = index
            self.bodyworklist.items[index] = item
            for i,v in pairs(popped) do
                index = index + 1
                v.itemindex = index
                self.bodyworklist.items[index] = v
            end
        end
    end
end

function UI.VehicleMechanicsPatches.doPartContextMenu(doPartContextMenu)
    local function addArmor(player,vehicle,part,item,itemType)
        print("add armor ",player,vehicle,part,item,itemType)
        local partId = part:getId()
        part:setInventoryItem(item)
        part:setModelVisible(itemType,true)
    end
    local function removeArmor(player,vehicle,part)
        print("removeArmor ",player,vehicle,part)
        part:setInventoryItem(nil)
    end

    return function(self,part,x,y)
        doPartContextMenu(self,part,x,y)

        if isGamePaused() then return end
        local playerObj = getSpecificPlayer(self.playerNum);
        if playerObj:getVehicle() ~= nil and not (isDebugEnabled() or (isClient() and (isAdmin() or getAccessLevel() == "moderator"))) then return end

        local context = self.context
        if part:getInventoryItem() then
            if part:getTable("unmount") then
                local recipe = getScriptManager():getRecipe(part:getTable("unmount").recipe)
                if recipe ~= nil then
                    context:addOption("Remove " .. getText("IGUI_VehiclePart" .. part:getId()),playerObj,removeArmor,self.vehicle,part)
                end
            end
        else
            if part:getTable("mount") then
                local containerList = ISInventoryPaneContextMenu.getContainers(playerObj)
                for i = 0, part:getItemType():size() - 1 do
                    local itemType = part:getItemType():get(i)
                    local item = playerObj:getInventory():getFirstType(itemType) or getDebug() and playerObj:getInventory():AddItem(itemType)
                    local recipes = RecipeManager.getUniqueRecipeItems(item, playerObj, containerList) --only shows recipes that can be done
                    if recipes ~= nil then
                        context:addOption("Add Armor to " .. getText("IGUI_VehiclePart" .. part:getId()),playerObj,addArmor,self.vehicle,part,item,itemType)
                    end
                end
            end
        end
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

return UI