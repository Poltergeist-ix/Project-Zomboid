if not isClient() then return end
local Shelters = require "azShelters/Shelters"

require "ISUI/UserPanel/ISSafehouseUI"
ISSafehouseUI.initialise = Shelters.ISSafehouseUI_patch(ISSafehouseUI.initialise)
