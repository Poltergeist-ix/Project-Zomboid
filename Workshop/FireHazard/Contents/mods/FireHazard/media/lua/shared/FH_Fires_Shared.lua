local Fires = {}
function Fires.hasGround(square)
    for i=1,square:getObjects():size() do
        local obj = square:getObjects():get(i-1)
        if obj:hasModData() and obj:getModData().shovelled then
            -- skip already-shovelled squares
        elseif obj:getSprite() and obj:getSprite():getName() then
            local spriteName = obj:getSprite():getName()
            if spriteName == "floors_exterior_natural_01_13" or
                    spriteName == "blends_street_01_55" or
                    spriteName == "blends_street_01_54" or
                    spriteName == "blends_street_01_53" or
                    spriteName == "blends_street_01_48" then
                return true
            end
            if spriteName == "blends_natural_01_0" or
                    spriteName == "blends_natural_01_5" or
                    spriteName == "blends_natural_01_6" or
                    spriteName == "blends_natural_01_7" or
                    spriteName == "floors_exterior_natural_01_24" then
                return true
            end
            if luautils.stringStarts(spriteName, "blends_natural_01_") or
                    luautils.stringStarts(spriteName, "floors_exterior_natural") then
                return true
            end
        end
    end
    return nil
end
zxFiresUtils = Fires
