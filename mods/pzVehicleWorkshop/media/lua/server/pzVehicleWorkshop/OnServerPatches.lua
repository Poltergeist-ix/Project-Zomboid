local Patches = {}

Patches["UninstallTest.Default"] = function(uninstall)
    return function(vehicle, part, character)
        local r = uninstall(vehicle, part, character)
        if not r then return r end
        local t = part:getTable("uninstall")
        if not (t and t.requireUninstalledList) then return r end
        for _,partId in ipairs(t.requireUninstalledList) do
            if vehicle:getPartById(partId):getInventoryItem() ~= nil then return false end
        end
        return r
    end
end

-- not called for client by default
function Patches.patchCreateEngine(CreateEngine)
    return function(vehicle,...)
        pzVehicleWorkshop.VehicleSettings.call("createEngine",vehicle:getScriptName(),vehicle,...)

        return CreateEngine(vehicle,...)
    end
end

return Patches