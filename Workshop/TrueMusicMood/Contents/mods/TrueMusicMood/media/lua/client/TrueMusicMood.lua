--[[
    Improve mood when listening to truemusic
    Author Poltergeist
    commissioned by MercDragon
--]]

local self = {
    boredomMod = 3,
    happinessMod = 1,
    stressMod = 0.01,
    playerLock = {}
}

function self.giveStats(player)
    self.playerLock[player] = true

    HaloTextHelper.addText(player,"Mood",HaloTextHelper.COLOR_GREEN)

    local bodyDamage = player:getBodyDamage()
    local stats = player:getStats()
    bodyDamage:setBoredomLevel(bodyDamage:getBoredomLevel() - self.boredomMod)
    bodyDamage:setUnhappynessLevel(bodyDamage:getUnhappynessLevel() - self.happinessMod)
    stats:setStress(stats:getStress() - self.stressMod)
end

function self.EveryTenMinutes()
    table.wipe(self.playerLock)
end

function self.isPlayingMusic(object)
    if not object then return end
    if instanceof(object,"IsoWaveSignal") then
        local data = object:getModData().tcmusic
        if data and data.isPlaying then return true end
    elseif instanceof(object, "BaseVehicle") then
        local radio = object:getPartById("Radio")
        local data = radio and radio:getModData().tcmusic
        if data and data.mediaItem and data.isPlaying then return true end
    elseif instanceof(object, "IsoPlayer") then
        local data = ModData.getOrCreate("trueMusicData")["now_play"][isClient() and object:getOnlineID() or object:getUsername()]
        if data then return true end
    end
end

function self.checkPlayers(object,x,y,z,v)
    print("Checking values: "..(x==object:getX() and y==object:getY() and z==object:getZ() and "same" or "different"),object)
    print(x,y,z,v)
    print(object:getX(),object:getY(),object:getZ())
    for i = 0,getNumActivePlayers() -1 do
        local player = getSpecificPlayer(i)
        if not self.playerLock[player] and (player == object or IsoUtils.DistanceToSquared(player:getX(), player:getY(), player:getZ() * 7, object:getX(), object:getY(), object:getZ() * 7) < v*v) then
            self.giveStats(player,object)
        end
    end
end

function self.OnWorldSound(x,y,z,r,v,object)
    if self.isPlayingMusic(object) then self.checkPlayers(object,x,y,z,v) end
end

Events.EveryTenMinutes.Add(self.EveryTenMinutes)
Events.OnWorldSound.Add(self.OnWorldSound)

return self