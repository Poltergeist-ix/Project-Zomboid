if isClient() then return end

local pzVehicleWorkshop = pzVehicleWorkshop

local Server = {}

function Server.changeVehicleScript(vehicle,scriptName,skinIndex)
    vehicle:setScriptName(scriptName)
    vehicle:scriptReloaded()
    if skinIndex then vehicle:setSkinIndex(skinIndex) end
end

function Server.patchCreateEngine(CreateEngine)
    return function(vehicle,...)
        pzVehicleWorkshop.call("createEngine",vehicle:getScriptName(),vehicle,...)
        --local scriptName = vehicle:getScriptName()
        --local opt = modTable.vehicleSettings[scriptName]
        --if opt.createEngine ~= nil then
        --    opt:createEngine(vehicle, part)
        --end

        return CreateEngine(vehicle,...)
    end
end

--[[ serverCommands ]]
function pzVehicleWorkshop.serverCommands.setItemPart(player,args) --"install"
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
            print("set model",args.item:getFullType())
            part:setModelVisible(args.item:getFullType(),true)
        end
    --else
    --    return
    end
end

function Server.OnClientCommand(module, command, player, args)
    if module == "pzVehicleWorkshop" then
        local f = pzVehicleWorkshop.serverCommands[command]
        if type(f) == "function" then
            return f(player,args)
        else
            print("Debug: received invalid command ",command)
        end
    end
end

Events.OnClientCommand.Add(Server.OnClientCommand)

pzVehicleWorkshop.Server = Server