--if isClient() then return end

local Patches = require "pzVehicleWorkshop/OnServerPatches"

require "Vehicles/Vehicles"
Vehicles.Create.Engine = Patches.patchCreateEngine(Vehicles.Create.Engine)
Vehicles.UninstallTest.Default = Patches.patchCreateEngine(Vehicles.UninstallTest.Default)

