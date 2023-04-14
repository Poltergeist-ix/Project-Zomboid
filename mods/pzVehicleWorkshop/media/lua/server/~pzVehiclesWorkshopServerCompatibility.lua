if isClient() then return end

--local pzVehicleWorkshop = pzVehicleWorkshop

--local modTable = require "pzVehicleWorkshop/Definitions"
--local vwServer = require "pzVehicleWorkshop/vwServer"
require "pzVehicleWorkshop/vwServer"

require "Vehicles/Vehicles"
Vehicles.Create.Engine = pzVehicleWorkshop.Server.patchCreateEngine(Vehicles.Create.Engine)