require "Foraging/ISSearchManager"

zx = zx or {}
zx.search = {interval = 0, active = false}

function ISSearchManager:updateOverlay()
	local darkness = 0
	local radius = self:getOverlayRadius();
	local sm = self.searchModeOverlay;
	sm:getBlur():setTargets(0, 0);
	sm:getDesat():setTargets(0, 0);
	sm:getRadius():setTargets(radius, radius);
	sm:getDarkness():setTargets(darkness, darkness);
	sm:getGradientWidth():setTargets(2, 2);
	self.overlayValues.darkness = darkness;
	self.radius = radius;
	getSearchMode():setEnabled(self.player, self.isSearchMode or self.isEffectOverlay);
end

local function SearchOnPlayerUpdate(player)
	-- zx.search.interval = zx.search.interval + 1
	-- print(zx.search.interval)
	-- if zx.search.interval > 100 then
		-- zx.search.interval = 0
		if player:getVehicle() or ISSearchManager.getManager(player):checkShouldDisable() then
			return
		else
			zx.search.interval = zx.search.interval +1
			if zx.search.interval > 20 then
				zx.search.interval = 0
				ISSearchManager.getManager(player):toggleSearchMode(true)
				Events.OnPlayerUpdate.Remove(SearchOnPlayerUpdate)
			end
		end
	-- end
end

-- local function SearchOnPlayerUpdate(player)
    -- if player:getVehicle() or ISSearchManager.getManager(player):checkShouldDisable() then
        -- return
    -- else
        -- ISSearchManager.getManager(player):toggleSearchMode(true)
    -- end
-- end


local function SearchToggle(player, smode)
    if zx.search.active and not smode then Events.OnPlayerUpdate.Add(SearchOnPlayerUpdate); return end
    if not zx.search.active and smode then ISSearchManager.getManager(player):toggleSearchMode(false); print("zx: sync search keys"); end
end

local function SearchKey(_keyPressed)
    if _keyPressed == getCore():getKey("Toggle Search Mode") then
        zx.search.active = not zx.search.active
    end
end

Events.onToggleSearchMode.Add(SearchToggle)
Events.OnKeyPressed.Add(SearchKey)
