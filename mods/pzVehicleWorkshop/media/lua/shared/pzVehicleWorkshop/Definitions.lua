local util = {}
util.vehicleDefs = {}

--util.generateDef(vehicle,defName)


function util.getVehicleDef(vehicleName,defName)
    local vehicle = util.vehicleDefs[vehicleName]
    if not vehicle then return end
    --return vehicle[defName] or util.generateDef[defName](vehicle)
end

--[[
    All Settings

    OnOpenMechanicsUI
    VehicleMechanicsTitle - set an Element above The Vehicle box
--]]