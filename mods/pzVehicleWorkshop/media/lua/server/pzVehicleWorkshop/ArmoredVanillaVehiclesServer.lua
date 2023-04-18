if isClient() then return end

local avv = {}

function avv.createEngine(self,vehicle,part)
    local ticks = 0
    local function doOnce()
        ticks = ticks + 1
        if ticks > 5 then
            Events.OnTick.Remove(doOnce)
            local script = self.replaceTypes and self.replaceTypes[1]
            local skinIndex = vehicle:getSkinIndex()
            print("create Engine, ",vehicle,script,skinIndex)
            pzVehicleWorkshop.VehicleUtilities.changeVehicleScript(vehicle,script,skinIndex)
        end
    end
    Events.OnTick.Add(doOnce)
end

do
    local VehicleSettings = pzVehicleWorkshop.VehicleSettings

    for base,mod in pairs(pzVehicleWorkshop.ArmoredVanillaVehicles.vanillaVehicles ) do
        VehicleSettings.add{ id = base, createEngine = avv.createEngine, replaceTypes = mod }
    end
end

return avv