--[[        \<.<\        ┏(-Д-┏)～        ]]
--[[
    Author Poltergeist
    module to soft block action from being stopped
--]]

do
    local version = "1.0.1"
    if __ActionThatCanNotBeCanceled ~= nil then
        local split1 = version:split("\\.")
        local split2 = __ActionThatCanNotBeCanceled.version:split("\\.")
        if tonumber(split1[1]) < tonumber(split2[1]) or tonumber(split1[2]) < tonumber(split2[2]) or tonumber(split1[3]) < tonumber(split2[3]) then
            return
        end
    end

    local Mod = { version = version }

    function Mod.initialize()
        Events.OnTick.Remove(Mod.initialize)

        if __ActionThatCanNotBeCanceled ~= Mod then return end

        local canStopCurrentAction = function(queue)
            return queue.current == nil or queue.current.canBeCancelled ~= false
        end

        local clearQueue = ISTimedActionQueue.clearQueue
        ISTimedActionQueue.clearQueue = function(self)
            clearQueue(self)
            if not canStopCurrentAction(self) then
                self.queue[1] = self.current
            end
        end

        ISTimedActionQueue.resetQueue = ISTimedActionQueue.resetQueue

        ISTimedActionQueue.tick = ISTimedActionQueue.tick

        local StopAllActionQueue = __classmetatables[IsoPlayer.class].__index.StopAllActionQueue
        __classmetatables[IsoPlayer.class].__index.StopAllActionQueue = function(player)
            if canStopCurrentAction(ISTimedActionQueue.getTimedActionQueue(player)) then
                return StopAllActionQueue(player)
            end
        end

        local _isPlayerDoingActionThatCanBeCancelled = isPlayerDoingActionThatCanBeCancelled
        isPlayerDoingActionThatCanBeCancelled = function(player)
            return _isPlayerDoingActionThatCanBeCancelled(player) and canStopCurrentAction(ISTimedActionQueue.getTimedActionQueue(player))
        end

        __ActionThatCanNotBeCanceled = nil
    end

    Events.OnTick.Add(Mod.initialize)

    __ActionThatCanNotBeCanceled = Mod
end
