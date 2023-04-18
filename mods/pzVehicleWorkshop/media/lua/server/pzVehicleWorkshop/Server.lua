if isClient() then return end

local pzVehicleWorkshop = pzVehicleWorkshop

local Server = {}

-- not called for client
function Server.patchCreateEngine(CreateEngine)
    return function(vehicle,...)
        pzVehicleWorkshop.VehicleSettings.call("createEngine",vehicle:getScriptName(),vehicle,...)

        return CreateEngine(vehicle,...)
    end
end

--- Server Commands

pzVehicleWorkshop.serverCommands = pzVehicleWorkshop.serverCommands or {}

function pzVehicleWorkshop.serverCommands.setPartItem(player,args)
    local vehicle = getVehicleById(args.vehicle)
    if vehicle == nil then return end
    local part = vehicle:getPartById(args.part)
    if part == nil then return end

    if args.item == false then
        part:setInventoryItem(nil)
        part:setAllModelsVisible(false)
    elseif instanceof(args.item,"InventoryItem") then
        part:setInventoryItem(args.item)
        if args.setModelFromType then
            part:setModelVisible(args.item:getFullType(),true)
        end
    end
    vehicle:transmitPartItem(part)
end

function Server.OnClientCommand(module, command, player, args)
    if module == "pzVehicleWorkshop" then
        local f = pzVehicleWorkshop.serverCommands[command]
        if type(f) == "function" then
            return f(player,args)
        else
            print("pzVehicleWorkshop: received invalid command ",command)
        end
    end
end

Events.OnClientCommand.Add(Server.OnClientCommand)

pzVehicleWorkshop.Server = Server