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
local allowedUnpause
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

local function keysPatch(removedList)
    return function(key)
        if not MainScreen.instance:isVisible() then
            allowedUnpause = true
            for i,v in pairs(removedList) do
                v[i](key)
            end
            allowedUnpause = false
        end
    end
end

--patch the checks
patchClassMethod(zombie.ui.SpeedControls.class, "getCurrentGameSpeed", speedPatch)
getGameSpeed = speedPatch(getGameSpeed)
isGamePaused = pausePatch(isGamePaused)

--patch ui
fnPatch(ISContextManager.getInstance(),"createWorldMenu")
fnPatch(ISVehicleDashboard,"onClickTrunk")
fnPatch(ISHotbar,"doMenu")
fnPatch(ISInventoryPage,"toggleStove")
fnPatch(ISInventoryPane,"doButtons")
fnPatch(ISInventoryPaneContextMenu,"createMenu")
fnPatch(ISVehicleDashboard,"onClickEngine")
fnPatch(ISVehicleDashboard,"onClickHeadlights")
fnPatch(ISVehicleDashboard,"onClickDoors")
fnPatch(ISVehicleDashboard,"onClickHeater")
fnPatch(ISVehicleDashboard,"onClickKeys")
fnPatch(ISVehicleMechanics,"onListMouseDown")
fnPatch(ISVehicleMechanics,"doPartContextMenu")
fnPatch(ISHealthBodyPartListBox,"onRightMouseUp")
fnPatch(ISObjectClickHandler,"doClickSpecificObject")

--patch the keys
Events.OnGameStart.Add(function()
    for i,v in pairs({
        OnKeyStartPressed = {
            onKeyPressed = ISFirearmRadialMenu,
            onKeyStartPressed = ISHotbar,
            onKeyPressed = ISLightSourceRadialMenu,
            onKeyStartPressed = ISUIHandler,
            onKeyStartPressed = ISVehicleMenu,
            onKeyStartPressed = ISWorldMap,
        },
        OnKeyKeepPressed = {
            onKeyRepeat = ISFirearmRadialMenu,
            onKeyKeepPressed = ISHotbar,
            onKeyRepeat = ISLightSourceRadialMenu,
            onKeyKeepPressed = ISWorldMap,
        },
        OnKeyPressed = {
            onKeyReleased = ISFirearmRadialMenu,
            onKeyReleased = ISHotbar,
            onKeyPressed = ISInventoryPage,
            onKeyReleased = ISLightSourceRadialMenu,
            handleKeyPressed = ISSearchManager,
            onKeyPressed = ISUIHandler,
            onKeyReleased = ISWorldMap,
            displayCharacterInfo = xpUpdate,
        }
    }) do
        for ii,vv in pairs(v) do
            Events[i].Remove(vv[ii])
        end
        Events[i].Add(keysPatch(v))
    end
end)

--[[
skipped: BaseIcon,SearchManager,SpeedControls,Joystick,BackButton,ButtonPrompt,ISDPadWheels,ISEmoteRadialMenu,ISLcdBar,ISSineWaveDisplay,ISTimedActionQueue,ISVehicleRegulator
other: ISInventoryPaneContextMenu.createMenuNoItems,ISObjectClickHandler.doClick

check inventory key right function
--]]
