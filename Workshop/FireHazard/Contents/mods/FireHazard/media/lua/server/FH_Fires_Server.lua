if isClient() then return end

local Fires = {}
zxFireHazard = Fires

Fires.SandboxRandomChance = { 0, 5, 10, 15, 20, 30 }
Fires.RoomTypes = { kitchen = 10, livingroom = 5}
Fires.BodyPartsSeverity = { 0.1, 0.1, 0.1, 0.1, 0.1, 1.0, 1.0, 0.0, 0.1, 10, 1.0, 1.0, 0.1, 0.1, 0.1, 0.1 }
local DeadZombies = {}
local ZombieHits = {}
local ThunderStrikes = {}

function Fires.Sandbox()
    if SandboxVars.WorldOnFire.RBBurnt ~= 2 then
        for i=1,getWorld():getRandomizedBuildingList():size() do
            local story = getWorld():getRandomizedBuildingList():get(i-1)
            if instanceof(story,"RBBurnt") or instanceof(story,"RBBurntCorpse") or instanceof(story,"RBBurntFireman") then
                story:setChance(Fires.SandboxRandomChance[SandboxVars.WorldOnFire.RBBurnt])
            end
        end
    end
    if SandboxVars.WorldOnFire.BurnRoomChance > 0 then
        Events.OnSeeNewRoom.Add(Fires.OnSeeNewRoom)
    end
    if SandboxVars.WorldOnFire.ZombieInvenoryHazard > 0 then
        Events.OnHitZombie.Add(Fires.OnHitZombie)
        Events.OnZombieDead.Add(Fires.OnZombieDead)
    end
end

function Fires.OnSeeNewRoom(room)
    local chance = room:getBuilding():getRoomsNumber() <= 20 and Fires.RoomTypes[room:getName()] or SandboxVars.WorldOnFire.AnyRoom and 0.2
    if chance and chance * SandboxVars.WorldOnFire.BurnRoomChance > ZombRand(1000) then
        Fires.startRoomFire(room)
    end
end

function Fires.startRoomFire(room)
    local square = room:getRoomDef():getFreeSquare()
    if not square then square = room:getRandomSquare() end
    if square then
        IsoFireManager.StartFire(square:getCell(), square, true, 100, 0)
        IsoFireManager.explode(square:getCell(), square, 10)
    end
end

function Fires.getInventoryHazard(inventory)
    local hazard = 0
    if not inventory:isExplored() then
        ItemPicker.fillContainer(inventory,getPlayer()) --mp ok
        inventory:setExplored(true)
    end
    local items = inventory:getItems()
    for i=0, items:size()-1 do
        local item = items:get(i)
        local type = item:getType()
        if item:hasTag("StartFire") then
            hazard = hazard + 1
        elseif type == "Torch" or type == "HandTorch" then
            hazard = hazard + 0.1
        elseif instanceof(item,"Radio") then
            hazard = hazard + 0.1
        elseif instanceof(item,"HandWeapon") and ( item:getExplosionPower() > 0 or item:getFirePower() > 0 ) then
            hazard = hazard + 3
        end
    end
    return hazard
end

function Fires.doCorpseHazard(inventory, hits)
    local hazard = Fires.getInventoryHazard(inventory)
    local square = inventory:getParent():getSquare()

    if ZombRand(1000) < hazard * hits * 10 * SandboxVars.WorldOnFire.ZombieInvenoryHazard then
        IsoFireManager.StartFire(square:getCell(), square, true, 100, 0)
    end
end

function Fires.OnHitZombie(zombie, IsoGC, bodypart, weapon)
    local severity = Fires.BodyPartsSeverity[bodypart:index()]
    ZombieHits[zombie] = (ZombieHits[zombie] or 0) + (severity or 0)
end

function Fires.OnZombieDead(zombie)
    if ZombieHits[zombie] then
        table.insert(DeadZombies, { zombie:getInventory(), ZombieHits[zombie], 0})
        ZombieHits[zombie] = nil
        if #DeadZombies == 1 then
            Events.OnTick.Add(Fires.waitForCorpse)
        end
    end
end

function Fires.waitForCorpse(ntick)
    if ntick%10 == 0 then
        for i = #DeadZombies, 1, -1 do
            if instanceof(DeadZombies[i][1]:getParent(),"IsoDeadBody") then
                Fires.doCorpseHazard(DeadZombies[i][1],DeadZombies[i][2])
                table.remove(DeadZombies,i)
            else
                DeadZombies[i][3] = DeadZombies[i][3] + 1
                if DeadZombies[i][3] > 100 then
                    table.remove(DeadZombies,i)
                end
            end
        end
        if #DeadZombies == 0 then
            Events.OnTick.Remove(Fires.waitForCorpse)
        end
    end
end

function Fires.ThunderEvent(args)
    local eventX = args.x
    local eventY = args.y
    local xy = tostring(eventX) .. tostring(eventY)
    local time = getGameTime():getWorldAgeHours()
    if not (ThunderStrikes[xy] and time - ThunderStrikes[xy] < 1) then
        ThunderStrikes[xy] = time
        for i = 7, 0, -1 do
            local isquare = getSquare(eventX,eventY,i)
            if isquare then
                if zxFiresUtils.hasGround(isquare) then break end
                if not isquare:getPlayer() then
                    IsoFireManager.StartFire(isquare:getCell(), isquare, false, 100, 0)
                else
                    if IsoFire.CanAddFire(isquare,false) then
                        isquare:Burn()
                    end
                end
            end
        end
    end
end

function Fires.OnClientCommand(module, command, player, args)
    if module == "Fires" then
        if command == "Thunder" then
            Fires.ThunderEvent(args)
        end
    end
end

Events.OnInitGlobalModData.Add(Fires.Sandbox)
Events.OnClientCommand.Add(Fires.OnClientCommand)
