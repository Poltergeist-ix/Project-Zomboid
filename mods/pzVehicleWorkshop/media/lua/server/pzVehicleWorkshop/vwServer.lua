if isClient() then return end
local modTable = require "pzVehicleWorkshop/Definitions"
local Server = {}

function Server.changeVehicleScript(vehicle,scriptName,skinIndex)
    vehicle:setScriptName(scriptName)
    vehicle:scriptReloaded()
    if skinIndex then vehicle:setSkinIndex(skinIndex) end
end

function Server.patchCreateEngine(CreateEngine)
    return function(vehicle,...)
        modTable.call("createEngine",vehicle:getScriptName(),...)
        --local scriptName = vehicle:getScriptName()
        --local opt = modTable.vehicleSettings[scriptName]
        --if opt.createEngine ~= nil then
        --    opt:createEngine(vehicle, part)
        --end

        return CreateEngine(vehicle,...)
    end
end

modTable.Server = Server
return Server