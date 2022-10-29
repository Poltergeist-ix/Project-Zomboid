local fakeUtils = {}

fakeUtils.patchClassMethod = function(class, methodName, createPatch)
    local metatable = __classmetatables[class]
    if not metatable then
        error("Unable to find metatable for class "..tostring(class))
    end
    local metatable__index = metatable.__index
    if not metatable__index then
        error("Unable to find __index in metatable for class "..tostring(class))
    end
    local originalMethod = metatable__index[methodName]
    metatable__index[methodName] = createPatch(originalMethod)
end
--[[
    Usage example:

    ArendamethUtils.patchClassMethod(zombie.inventory.types.Moveable.class, "getDisplayName", function(original_fn)
            return function(self, arg1, arg2, ...)
                local modData = self:getModData()
                if modData and modData.new_value then
                    return modData.new_value
                end
                local result = original_fn(self, arg1, arg2, ...)
                result.someProperty = false
                return result
            end
        end)
]]

local fakeNotPaused
local speedPatch = function(original_fn)
    return function(...)
        local speed = original_fn(...)
        if fakeNotPaused and speed == 0 then
            return 1
        else
            return speed
        end
    end
end
local pausePatch = function(original_fn)
    return function(...)
        if fakeNotPaused then
            return false
        else
            return original_fn(...)
        end
    end
end
local fnPatch = function(obj,funcName, eventList)
    local original_f = obj[funcName]
    eventList = eventList or {}
    for _,event in ipairs(eventList) do
        Events[event].Remove(original_f)
    end
    obj[funcName] = function(...)
        fakeNotPaused = true
        local result = original_f(...)
        fakeNotPaused = nil
        return result
    end
    for _,event in ipairs(eventList) do
        Events[event].Add(obj[funcName])
    end
end

fakeUtils.patchClassMethod(zombie.ui.SpeedControls.class, "getCurrentGameSpeed", speedPatch)
getGameSpeed = speedPatch(getGameSpeed)
isGamePaused = pausePatch(isGamePaused)

-- Client Files

require "Context/ISMenuContextWorld"
local ISMenuContextWorldnew = ISMenuContextWorld.new
ISMenuContextWorld.new = function(...)
    local original = ISMenuContextWorldnew(...)
    fnPatch(original,"createMenu")
    return original
end

require "Hotbar/ISHotbar"
fnPatch(ISHotbar,"onKeyStartPressed")
fnPatch(ISHotbar,"doMenu")
fnPatch(ISHotbar,"onKeyPressed")
fnPatch(ISHotbar,"onKeyKeepPressed")

require "ISUI/Maps/ISWorldMap"
fnPatch(ISWorldMap,"checkKey")

require "ISUI/ISFirearmRadialMenu"
fnPatch(ISFirearmRadialMenu,"checkKey")

require "ISUI/ISInventoryPage"
fnPatch(ISInventoryPage,"toggleStove")
fnPatch(ISInventoryPage,"onKeyPressed",{"OnKeyPressed"})

require "ISUI/ISInventoryPaneContextMenu"
fnPatch(ISInventoryPaneContextMenu,"createMenu")

require "ISUI/ISLightSourceRadialMenu"
fnPatch(ISLightSourceRadialMenu,"checkKey")

require "Vehicles/ISUI/ISVehicleMechanics"
fnPatch(ISVehicleMechanics,"onListMouseDown")

require "XpSystem/ISUI/ISHealthPanel"
fnPatch(ISHealthBodyPartListBox,"onRightMouseUp")

-- Server Files

require "XpSystem/XpUpdate"
fnPatch(xpUpdate,"displayCharacterInfo",{"OnKeyPressed"})
