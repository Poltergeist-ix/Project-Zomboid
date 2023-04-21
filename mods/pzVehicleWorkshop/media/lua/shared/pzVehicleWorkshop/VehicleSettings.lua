
--- Vehicle Settings

local VehicleSettings = {}

local allSettings = {}
local proxies = {}

local function functionField(t,k,v)
    if type(v) ~= "function" then print("pzVehicleWorkShop: "..k.." is not a function") return end
    if t[k] then table.insert(t[k],v) else t[k] = {v} end
end

local function tableField(t,k,v)
    if type(v) ~= "table" then print("pzVehicleWorkShop: "..k.." is not a table") return end
    t[k] = v
end

local specialFields = {
    id = function() end,
    createEngine = functionField,
    VehicleMechanics_OnOpen = functionField,
    VehicleMechanics_VehicleContext = functionField,
    VehicleMechanics_PartContext = functionField,
    VehicleMechanics_DrawItems = functionField,
    partParents = tableField,
}

local function setFieldValue(t,k,v)
    --t = getmetatable(t).__index -- if ref removed
    t = t.__index

    if specialFields[k] then
        specialFields[k](t,k,v)
    else
        t[k] = v
    end
end

function VehicleSettings.add(_settings)
    if type(_settings) ~= "table" or type(_settings.id) ~= "string" then return print("pzVehicleWorkShop: invalid settings") end

    local proxy = proxies[_settings.id]

    if not proxy then
        local settings = {id = _settings.id}
        allSettings[_settings.id] = settings

        proxy = setmetatable({}, {__index=settings,__newindex=setFieldValue})
        --proxy.__index = proxy --should remove ref?

        proxies[_settings.id] = proxy
    end

    for k,v in pairs(_settings) do setFieldValue(proxy,k,v) end

end

function VehicleSettings.get(scriptName)
    return proxies[scriptName]
end

function VehicleSettings.call(event, scriptName,...)
    local modScript = proxies[scriptName]
    if not modScript or not modScript[event] then return end
    for _ , f in ipairs(modScript[event]) do
        f(modScript,...)
    end
end

--function VehicleSettings.removeFunctions(settings)
--    local def = allSettings[settings.id]
--    if not def then return end
--    for k,v in pairs(settings) do
--        if type(v) == "function" and type(def[k]) == "table" then
--            for i,fn in ipairs(def[k]) do
--                if fn == v then return table.remove(def[k],i) end
--            end
--        end
--    end
--end

--function pzVehicleWorkshop.add(scriptName, values, events)
--    local def = pzVehicleWorkshop.vehicleSettings[scriptName] or {}
--
--    if values ~= nil then
--        for k,v in pairs(values) do
--            def[k] = v
--        end
--    end
--
--    if events ~= nil then
--        for k,v in pairs (events) do
--            if type(v) == "function" then
--                if def[k] then table.insert(def[k],v) else def[k] = {v} end
--            end
--        end
--    end
--
--    pzVehicleWorkshop.vehicleSettings[scriptName] = def
--
--    --return def
--end


--util.generateDef(vehicle,defName)

--function pzVehicleWorkshop.getVehicleDef(vehicleName, defName)
--    local vehicle = pzVehicleWorkshop.vehicleSettings[vehicleName]
--    if not vehicle then return end
--    --return vehicle[defName] or util.generateDef[defName](vehicle)
--end

pzVehicleWorkshop = pzVehicleWorkshop or {}
pzVehicleWorkshop.VehicleSettings = VehicleSettings