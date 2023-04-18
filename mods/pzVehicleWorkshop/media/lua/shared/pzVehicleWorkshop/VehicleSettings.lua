
--- Vehicle Settings

local VehicleSettings = {}

local allSettings = {}
local proxies = {}

local function functionField(t,k,v)
    if type(v) == "function" then
        if t[k] then table.insert(t[k],v) else t[k] = {v} end
    else
        print("pzVehicleWorkShop: "..k.." is not a function")
    end
end

local specialFields = {
    id = function() end,
    createEngine = functionField,
    VehicleMechanics_OnOpen = functionField,
    VehicleMechanics_VehicleContext = functionField,
    VehicleMechanics_PartContext = functionField,
    VehicleMechanics_DrawItems = functionField,
}

local function setFieldValue(t,k,v)
    if specialFields[k] then
        specialFields[k](t,k,v)
    else
        t[k] = v
    end
end

function VehicleSettings.add(_settings)
    if type(_settings) ~= "table" or type(_settings.id) ~= "string" then return print("pzVehicleWorkShop: invalid settings") end

    local settings = allSettings[_settings.id]

    if not settings then
        settings = {id = _settings.id}
        allSettings[_settings.id] = settings
        --local t1,t2 = {}, {__index=settings,__newindex=setFieldValue}
        --setmetatable(t1,t2)
        --proxies[_settings.id] = t1
        proxies[_settings.id] = setmetatable({}, {__index=settings,__newindex=setFieldValue})
    end

    for k,v in pairs(_settings) do setFieldValue(settings,k,v) end

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