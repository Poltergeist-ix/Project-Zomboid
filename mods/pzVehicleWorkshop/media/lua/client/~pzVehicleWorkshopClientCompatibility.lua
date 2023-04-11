local UI = require("pzVehicleWorkshop/UI_patches")

require "Vehicles/ISUI/ISVehicleMechanics"
UI.patchISVehicleMechanics(ISVehicleMechanics)
--ISVehicleMechanics.initParts = ui.patchISVehicleMechanics_initParts(ISVehicleMechanics.initParts)
--ui.patchISVehicleMechanics_doPartContextMenu(ISVehicleMechanics.doPartContextMenu)