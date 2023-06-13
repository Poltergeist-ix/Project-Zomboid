--[[        \<.<\        ┏(-Д-┏)～        ]]
--[[
    Author Poltergeist
    module for using special item that only exists in player hands
--]]

local self

do
    local version = "1.0.0"
    local __version = __HandsExclusiveItem and __HandsExclusiveItem.version
    if __HandsExclusiveItem ~= nil then
        local split1 = version:split("\\.")
        local split2 = __version:split("\\.")
        if tonumber(split1[1]) > tonumber(split2[1]) or tonumber(split1[2]) > tonumber(split2[2]) or tonumber(split1[3]) > tonumber(split2[3]) then
            __version = nil
        end
    end

    if __version then return end
    self = { version = version }
    __HandsExclusiveItem = self
end

function self.OnTick()
    Events.OnTick.Remove(self.OnTick)

    if __HandsExclusiveItem ~= self then return end

    function self.onItemFall(item)
        if item:getModData().isHandsExclusiveItem then
            local wItem = item:getWorldItem()
            if wItem ~= nil then
                wItem:getSquare():transmitRemoveItemFromSquare(wItem)
                wItem:removeFromWorld()
                wItem:removeFromSquare()
                wItem:setSquare(nil)
                triggerEvent("OnContainerUpdate")
            end
        end
    end
    Events.onItemFall.Add(self.onItemFall)

    ---patch createMenu to remove drop options and errors
    local createMenu = ISInventoryPaneContextMenu.createMenu
    ISInventoryPaneContextMenu.createMenu = function(player, isInPlayerInventory, items, ...)
        if isInPlayerInventory and type(items[1]) == "userdata" and items[1]:getModData().isHandsExclusiveItem then
            items[1] = nil
        end
        return createMenu(player, isInPlayerInventory, items, ...)
    end

end

Events.OnTick.Add(self.OnTick)
