require "pzVehicleWorkshop/VehicleSettings"

local ArmoredVanillaVehicles = {
    armorVehicles = {},
    vanillaVehicles = {},
}

function ArmoredVanillaVehicles.addArmoredCar(armorTypes,vanillaTypes)
    if type(armorTypes) ~= "table" or type(vanillaTypes) ~= "table" then return print("ArmoredVanillaVehicles: invalid addArmoredCar call") end
    for _,v in ipairs(armorTypes) do
        ArmoredVanillaVehicles.armorVehicles[v] = vanillaTypes
    end
    for _,v in ipairs(vanillaTypes) do
        ArmoredVanillaVehicles.vanillaVehicles[v] = armorTypes
    end
end

pzVehicleWorkshop.ArmoredVanillaVehicles = ArmoredVanillaVehicles