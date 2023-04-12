local modTable = require "pzVehicleWorkshop/Definitions"
local vwServer = require "pzVehicleWorkshop/vwServer"

require "Vehicles/Vehicles"
Vehicles.Create.Engine = vwServer.patchCreateEngine(Vehicles.Create.Engine)