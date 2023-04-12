if isClient() then return end
local modTable = require "pzVehicleWorkshop/Definitions"
local avc = {}

function avc.createEngine(self,vehicle,part)
    local function doOnce()
        Events.OnTick.Remove(doOnce)
        modTable.Server.changeVehicleScript(vehicle,self.avcType,vehicle:getSkinIndex())

        -- [[ send replace with? ]]
        --local function doOnceToo()
        --    Events.EveryTenMinutes.Remove(doOnceToo)
        --    vehicle:sendObjectChange("replaceWith","object",vehicle)
        --end
        --Events.EveryTenMinutes.Add(doOnceToo)
    end
    Events.OnTick.Add(doOnce)
end

--[[ ArmoredVanillaVehicles CarStationWagon ]]
for _,scriptName in ipairs({"Base.CarStationWagon","Base.CarStationWagon2"}) do
    modTable.add(scriptName,{avcType = "AVC.CarStationWagonTiered"},{ createEngine = avc.createEngine})
end

return avc