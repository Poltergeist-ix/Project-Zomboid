if isClient() then return end

require "pzVehicleWorkshop/Server"

require "Vehicles/Vehicles"
Vehicles.Create.Engine = pzVehicleWorkshop.Server.patchCreateEngine(Vehicles.Create.Engine)