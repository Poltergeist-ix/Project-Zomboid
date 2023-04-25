--[[
    Use different settings per Safehouse (v41.78)
    Author Poltergeist
    requested by Alfa-Z 343 for PZO server

    Notes
        option SafehouseAllowTrepass should be set to true on server
--]]

if not isServer() then return end
-----------------------------------------------------------------------------------------
local defaultValue = 2
-----------------------------------------------------------------------------------------
local modData

local function updateData()
    local oldData = ModData.remove("azShelters") or {}
    local newData = ModData.create("azShelters")

    local safehouseList= SafeHouse.getSafehouseList()
    for i=0, safehouseList:size() - 1 do
        local safehouse = safehouseList:get(i)
        local x,y = safehouse:getX(), safehouse:getY()
        newData[x] = newData[x] or {}
        newData[x][y] = (oldData[x] or {})[y] or defaultValue
    end

    modData = newData
end

local function OnClientCommand(module, command, player, args)
    if module == "azShelters" then
        if command == "shelterType" then
            if not player:isAccessLevel("Admin") then return end

            modData[args.x] = modData[args.x] or {}
            modData[args.x][args.y] = args.t

            sendServerCommand("azShelters","shelterType",args)
        end
    end
end

getServerOptions():getOptionByName("SafehouseAllowTrepass"):setValue(true)

Events.OnLoadedMapZones.Add(updateData)
Events.OnSafehousesChanged.Add(updateData)
Events.OnClientCommand.Add(OnClientCommand)
