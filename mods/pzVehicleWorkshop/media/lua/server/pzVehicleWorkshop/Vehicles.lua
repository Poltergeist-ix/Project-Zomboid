local vw = pzVehicleWorkshop

vw.util.Install = {}

function vw.util.Install(vehicle,part)
    part:setModelVisible(part:getInventoryItem(),true)
end

function vw.util.createEmpty(vehicle,part)
    part:setCondition(0)
    --return nil --no effect
end
