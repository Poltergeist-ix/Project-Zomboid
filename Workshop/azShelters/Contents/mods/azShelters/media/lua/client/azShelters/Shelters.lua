--[[
    Use different settings per Safehouse (v41.78)
    Author Poltergeist
    requested by Alfa-Z 343 for PZO server
--]]

if not isClient() then return end
-----------------------------------------------------------------------------------------
local defaultValue = 2
-----------------------------------------------------------------------------------------
local SafeHouse, isAdmin = SafeHouse, isAdmin

local Shelters = {}
Shelters.modData = nil

function Shelters.ISSafehouseUI_patch(initialize)
    local labelText = getText("IGUI_azShelters_trespassLabel")
    local optionTexts = {getText("IGUI_azShelters_trespassAll"),getText("IGUI_azShelters_trespassOnline"),getText("IGUI_azShelters_trespassMembers")}
    local width = 0
    for _,i in ipairs(optionTexts) do local iwidth = getTextManager():MeasureStringX(UIFont.Small, i); if iwidth > width then width = iwidth end end
    width = width + 40
    local height = getTextManager():getFontHeight(UIFont.Small)
    local function onSelect(window,element)
        sendClientCommand(window.player,"azShelters","shelterType", {x=window.safehouse:getX(),y=window.safehouse:getY(),t=element.selected})
    end
    local tooltips = { format = getText("IGUI_azShelters_trespassFormat"), getText("IGUI_azShelters_trespassAll_tooltip"),
                       getText("IGUI_azShelters_trespassOnline_tooltip"), getText("IGUI_azShelters_trespassMembers_tooltip"),
    }
    local function getOptionTooltip(comboBox,index)
        return string.format(tooltips.format, tooltips[index] or "")
    end

    return function(self)
        initialize(self)

        self.trespassOptionLabel = ISLabel:new(self.width-width-20, self.refreshPlayerList.y, height, labelText, 1, 1, 1, 1, UIFont.Small, false)
        self.trespassOptionLabel:initialise()
        self:addChild(self.trespassOptionLabel)

        self.trespassOptionEnum = ISComboBox:new(self.width-width-10, self.refreshPlayerList.y, width, height, self, onSelect)
        self.trespassOptionEnum.textColor = {r=0.6, g=0.6, b=0.8, a=1}
        self.trespassOptionEnum.options = optionTexts
        self.trespassOptionEnum.selected = (Shelters.modData[self.safehouse:getX()] or {})[self.safehouse:getY()] or 0 --error
        if not isAdmin() then self.trespassOptionEnum.disabled = true end
        self.trespassOptionEnum.getOptionTooltip = getOptionTooltip
        self.trespassOptionEnum:initialise()
        self:addChild(self.trespassOptionEnum)

    end
end

Shelters.typeFunctions = {}
Shelters.typeFunctions[1] = function(player, safehouse)
    return true
end
Shelters.typeFunctions[2] = function(player, safehouse)
    return safehouse:getPlayerConnected() > 0 or safehouse:playerAllowed(player)
end
Shelters.typeFunctions[3] = function(player, safehouse)
    return safehouse:playerAllowed(player)
end

function Shelters.isPlayerAllowed(player, safehouse)
    if isAdmin() then return true end
    local shelterType = (Shelters.modData[safehouse:getX()] or {})[safehouse:getY()] or defaultValue
    local typeFn = Shelters.typeFunctions[shelterType]
    if typeFn then
        return typeFn(player, safehouse)
    else
        getServerOptions():getOptionByName("SafehouseAllowTrepass"):setValue(false)
        return true
    end
end

function Shelters.kickOut(player,safehouse)
    local x, y = player:getX(), player:getY()
    local x1,y1,x2,y2 = safehouse:getX(), safehouse:getY(), safehouse:getX2(), safehouse:getY2()

    local dir, dist, test
    dir, dist = "w", x-x1
    test = x2-x
    if test < dist then dir, dist = "e", test end
    test = y-y1
    if test < dist then dir, dist = "n", test end
    test = y2-y
    if test < dist then dir, dist = "s", test end

    if      dir == "w" then player:setX(x1-0.1)
    elseif  dir == "e" then player:setX(x2)
    elseif  dir == "n" then player:setY(y1-0.1)
    elseif  dir == "s" then player:setY(y2)
    end
end

function Shelters.OnPlayerUpdate(player)
    local square = player:getSquare()
    local safehouse = square and SafeHouse.getSafeHouse(square)
    if safehouse ~= nil and not Shelters.isPlayerAllowed(player, safehouse) then
        Shelters.kickOut(player,safehouse)
        getServerOptions():getOptionByName("SafehouseAllowTrepass"):setValue(false)
    end
end

function Shelters.resetOption()
    getServerOptions():getOptionByName("SafehouseAllowTrepass"):setValue(true);
end

function Shelters.OnReceiveGlobalModData(id,modData)
    if id == "azShelters" then Shelters.modData = modData or Shelters.modData or {} end
end

function Shelters.OnSafehousesChanged()
    local safehouseList= SafeHouse.getSafehouseList()
    for i=0, safehouseList:size() - 1 do
        local safehouse = safehouseList:get(i)
        local x,y = safehouse:getX(), safehouse:getY()
        Shelters.modData[x] = Shelters.modData[x] or {}
        Shelters.modData[x][y] = Shelters.modData[x][y] or defaultValue
    end
end

function Shelters.OnServerCommand(module,command,args)
    if module == "azShelters" then
        if command == "shelterType" then
            Shelters.modData[args.x] = Shelters.modData[args.x] or {}
            Shelters.modData[args.x][args.y] = args.t
        end
    end
end

ModData.request("azShelters")

Events.OnReceiveGlobalModData.Add(Shelters.OnReceiveGlobalModData)
Events.OnSafehousesChanged.Add(Shelters.OnSafehousesChanged)
Events.OnServerCommand.Add(Shelters.OnServerCommand)
Events.OnPlayerUpdate.Add(Shelters.OnPlayerUpdate)
Events.EveryOneMinute.Add(Shelters.resetOption)

return Shelters