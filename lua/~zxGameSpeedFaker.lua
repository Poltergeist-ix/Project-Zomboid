if isClient() or isServer() then return end

--metatable patcher, thanks Tyrir
local patchClassMethod = function(class, methodName, createPatch)
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

--patchers
local allowedUnpause --maybe use integer instead of boolean for depth
local speedPatch = function(original_fn)
    return function(...)
        if not allowedUnpause then
            return original_fn(...)
        else
            local speed = original_fn(...)
            return speed ~= 0 and speed or 1
        end
    end
end

local pausePatch = function(original_fn)
    return function(...)
        if allowedUnpause then
            return false
        else
            return original_fn(...)
        end
    end
end

local fnPatch = function(obj,funcName, event)
    local original_fn = obj[funcName]

    obj[funcName] = function(...)
        allowedUnpause = true
        local result = original_fn(...)
        allowedUnpause = false
        return result
    end
end

local function keyPatch( obj, fnName, event )
    local original_fn = obj[fnName]
    if event then
        Events[event].Remove(original_fn)
    end

    obj[fnName] = function(...)
        if MainScreen.instance:isVisible() then
            return original_fn(...)
        else
            allowedUnpause = true
            local result = original_fn(...)
            allowedUnpause = false
            return result
        end
    end

    if event then
        Events[event].Add(obj[fnName])
    end
end

--patch the checks
patchClassMethod(zombie.ui.SpeedControls.class, "getCurrentGameSpeed", speedPatch)
getGameSpeed = speedPatch(getGameSpeed)
isGamePaused = pausePatch(isGamePaused)

--patch ui
fnPatch(ISContextManager.getInstance(),"createWorldMenu")
fnPatch(ISHotbar,"doMenu")
fnPatch(ISInventoryPage,"toggleStove")
fnPatch(ISInventoryPane,"doButtons")
fnPatch(ISInventoryPaneContextMenu,"createMenu")
fnPatch(ISVehicleDashboard,"onClickEngine")
fnPatch(ISVehicleDashboard,"onClickHeadlights")
fnPatch(ISVehicleDashboard,"onClickDoors")
fnPatch(ISVehicleDashboard,"onClickHeater")
fnPatch(ISVehicleDashboard,"onClickKeys")
fnPatch(ISVehicleDashboard,"onClickTrunk")
fnPatch(ISVehicleMechanics,"onListMouseDown")
fnPatch(ISVehicleMechanics,"doPartContextMenu")
fnPatch(ISHealthBodyPartListBox,"onRightMouseUp")
fnPatch(ISObjectClickHandler,"doClickSpecificObject")

--patch the keys
keyPatch(ISFirearmRadialMenu,"checkKey")
keyPatch(ISHotbar,"onKeyStartPressed")
keyPatch(ISHotbar,"onKeyPressed")
keyPatch(ISHotbar,"onKeyKeepPressed")
keyPatch(ISInventoryPage,"onKeyPressed","OnKeyPressed")
keyPatch(ISLightSourceRadialMenu,"checkKey")
keyPatch(ISSearchManager,"handleKeyPressed")
keyPatch(ISVehicleMenu,"onShowSeatUI")
keyPatch(ISVehicleMenu,"showRadialMenu")
keyPatch(ISWorldMap,"checkKey")
keyPatch(xpUpdate,"displayCharacterInfo","OnKeyPressed")



--[[
skipped: BaseIcon,SearchManager,SpeedControls,Joystick,BackButton,ButtonPrompt,ISDPadWheels,ISEmoteRadialMenu,ISLcdBar,ISSineWaveDisplay,ISTimedActionQueue,ISVehicleRegulator
other: ISInventoryPaneContextMenu.createMenuNoItems,ISObjectClickHandler.doClick
--]]
