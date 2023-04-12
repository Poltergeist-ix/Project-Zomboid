pzVehicleWorkshop = pzVehicleWorkshop or {}
local util = pzVehicleWorkshop
util.vehicleSettings = {}

--util.vehicleDefs["Base.CarStationWagon"] = {}
--util.vehicleDefs["Base.CarStationWagon2"] = util.vehicleDefs["Base.CarStationWagon"]

function util.add(scriptName,values,events)
    local def = util.vehicleSettings[scriptName] or {id=scriptName}

    for k,v in pairs(values) do
        def[k] = v
    end

    for k,v in pairs (events) do
        if type(v) == "function" then
            if def[k] then table.insert(def[k],v) else def[k] = {v} end
        end
    end

    util.vehicleSettings[scriptName] = def
end

function util.getSettings(scriptName)
    return util.vehicleSettings[scriptName]
end

--util.generateDef(vehicle,defName)

function util.getVehicleDef(vehicleName,defName)
    local vehicle = util.vehicleSettings[vehicleName]
    if not vehicle then return end
    --return vehicle[defName] or util.generateDef[defName](vehicle)
end

function util.call(event,scriptName,...)
    local modScript = util.vehicleSettings[scriptName]
    if not modScript or not modScript[event] then return end
    for _ , f in ipairs(modScript[event]) do
        f(modScript,...)
    end
end

return util


--[[
    All Settings

    VehicleMechanics
        OnOpen / initParts
        doVehicleContext
        Title - set an Element above The Vehicle box - won't work working
--]]