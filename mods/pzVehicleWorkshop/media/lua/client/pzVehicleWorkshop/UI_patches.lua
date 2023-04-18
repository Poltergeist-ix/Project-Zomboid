local pzVehicleWorkshop = pzVehicleWorkshop

local UI = {}

--function UI.add(config)
--    if config.VehicleMechanics ~= nil then
--        local vehicleSettings = UI.VehicleMechanics.vehicleSettings[config.vehicle] or {id=config.vehicle}
--        for k,v in pairs (config.VehicleMechanics) do
--            if type(v) == "function" then
--                if vehicleSettings[k] then table.insert(vehicleSettings[k],v) else vehicleSettings[k] = {v} end
--            end
--        end
--        UI.VehicleMechanics.vehicleSettings[config.vehicle] = vehicleSettings
--    end
--end

UI.settings = {
    fontSmallHeight = getTextManager():getFontHeight(UIFont.Small),
    fontMediumHeight = getTextManager():getFontHeight(UIFont.Medium),
}

--[[ VehicleMechanics functions
TODO pass conf table together with call // vehicleConf:onOpen(window)
]]
UI.VehicleMechanics = {}
--UI.VehicleMechanics.vehicleSettings = {}

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
    local t = (window.vwVehicleSettings or {}).VehicleMechanics_OnOpen
    if not t then return end
    for _,f in ipairs(t) do
        f(window.vwVehicleSettings,window)
    end
end

--[[
pass context
if prev options and not visible get new
if not visible and options then set visible
--]]
function UI.VehicleMechanics.doVehicleContext(self,x,y)
    --print("UI.VehicleMechanics.doVehicleContext")
    local t = (self.vwVehicleSettings or {}).VehicleMechanics_VehicleContext
    if not t then return end
    for _,f in ipairs(t) do
        f(self,x,y)
    end
end

function UI.VehicleMechanics.doPartContext(self,...)
    --print("UI.VehicleMechanics.doVehicleContext")
    local t = (self.vwVehicleSettings or {}).VehicleMechanics_PartContext
    if not t then return end
    for _,f in ipairs(t) do
        f(self.vwVehicleSettings,self,...)
    end
end

--- VehicleMechanics patches

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
        self.vwVehicleSettings = pzVehicleWorkshop.VehicleSettings.get(vehicleScriptName)

        --[[ prev state ]]

        --[[ calls ]]
        UI.VehicleMechanics.onOpenPanel(self)

        --[[ finish ]]
    end
end

function UI.VehicleMechanicsPatches.doPartContextMenu(doPartContextMenu)
    return function(self,part,x,y)
        --alt call before
        doPartContextMenu(self,part,x,y)

        if self.vwVehicleSettings ~= nil then
            if isGamePaused() then return end
            if not self.playerObj then self.playerObj = getSpecificPlayer(self.playerNum) end
            if self.playerObj:getVehicle() ~= nil and not (isDebugEnabled() or (isClient() and (isAdmin() or getAccessLevel() == "moderator"))) then return end

            --pzVehicleWorkshop.call("partContext",self.vwVehicleSettings.id,self,part,x,y)
            UI.VehicleMechanics.doPartContext(self,part,x,y)

            if JoypadState.players[self.playerNum + 1] then UI.VehicleMechanics.doVehicleContext(self,x,y) end
        end
    end
end

function UI.VehicleMechanicsPatches.doDrawItem(doDrawItem)
    return function(self,...)
        local t = self.vwVehicleSettings or self.parent and self.parent.vwVehicleSettings
        --if t ~= nil and t.VehicleMechanics_DrawItems ~= nil then
        t = t and t.VehicleMechanics_DrawItems
        if t ~= nil then
            for _ , f in ipairs(t) do
                local r = f(t,self,...)
                if r ~= nil then return r end
            end
        end

        return doDrawItem(self,...)
    end
end

function UI.VehicleMechanicsPatches.onRightMouseUp(onRightMouseUp)
    return function(self,x,y)
        onRightMouseUp(self,x,y)

        UI.VehicleMechanics.doVehicleContext(self,x,y)
    end
end

function UI.patchISVehicleMechanics()
    local ISVehicleMechanics = ISVehicleMechanics
    for key,patchFn in pairs(UI.VehicleMechanicsPatches) do
        ISVehicleMechanics[key] = patchFn(ISVehicleMechanics[key])
    end
end

local function reloaded()
    local id = 0
    local data = getPlayerData(id)
    if not data then return end
    local instance = data.mechanicsUI
    instance:close()

    reloadLuaFile("media/lua/client/Vehicles/ISUI/ISVehicleMechanics.lua")

    UI.patchISVehicleMechanics(ISVehicleMechanics)
    data.mechanicsUI = ISVehicleMechanics:new(0,0,getPlayer(),nil)
    data.mechanicsUI:initialise()
    ISLayoutManager.RegisterWindow('mechanics'..id, ISVehicleMechanics, data.mechanicsUI)
end
if getPlayer() then reloaded() end

pzVehicleWorkshop.UI_patches = UI
