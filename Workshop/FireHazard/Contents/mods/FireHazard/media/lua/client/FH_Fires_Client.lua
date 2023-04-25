local Fires = {}
function Fires.Sandbox()
    if SandboxVars.WorldOnFire.ThunderHazard then
        Events.OnThunderEvent.Add(Fires.OnThunderEvent)
    end
end

function Fires.OnThunderEvent(eventX, eventY, doStrike, doLightning, doRumble)
    if doStrike then
        local pl = getPlayer()
        if eventX == math.floor(pl:getX()) and eventY == math.floor(pl:getY()) then
            for i = 7, 0, -1 do
                local isquare = getSquare(eventX,eventY,i)
                if isquare then
                    if zxFiresUtils.hasGround(isquare) then break end
                    if i == pl:getZ() then
                        local parts = pl:getBodyDamage():getBodyParts()
                        local size = parts:size()
                        local random = ZombRand(size)
                        local rngSize = 0
                        for v = 0, size - 1 do
                            if ZombRand(rngSize) == 0 then
                                rngSize = rngSize + 3
                                local part = parts:get((v + random) % size)
                                part:setBurned()
                            end
                        end
                        pl:forceAwake()
                    end
                end
            end
        end
        sendClientCommand(pl,"Fires","Thunder",{ x = eventX, y = eventY })
    end
end
Events.OnInitGlobalModData.Add(Fires.Sandbox)
