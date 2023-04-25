--  \-.-\       ┏(-Д-┏)～
--patch for inconsistent jukebox behaviour in MP // playSound triggers event only on server in contrast to playSoundImpl (?) // difference between moving objects?
--playSound(String,boolena) --deprecated

if not isClient() then return end
local TrueMusicMood = require "TrueMusicMood"

local function pasta()
    local musicServerTable = ModData.getOrCreate("trueMusicData")
    for musicId, musicServerData in pairs(musicServerTable["now_play"]) do
        local pat = string.match(musicId,'%d*[-]%d*[-]%d*')
        if pat then
            local split = string.split(pat,"-")
            local x,y,z = tonumber(split[1]), tonumber(split[2]), tonumber(split[3])
            local square = getSquare(x,y,z)
            if square then
                local objects = square:getObjects()
                for i = objects:size() - 1, 0, -1 do
                    local obj = objects:get(i)
                    if TCMusic.WorldMusicPlayer[obj:getTextureName()] and instanceof(obj, "IsoWaveSignal") then
                        local data = obj:getModData().tcmusic
                        if data and data.isPlaying then
                            TrueMusicMood.checkPlayers(obj,x,y,z,60)
                            break
                        end
                    end
                end
            end
        end
    end
end

Events.EveryTenMinutes.Add(pasta)

return {pasta}