require "Foraging/ISSearchManager"

local active = false
local interval = 0
local wait = true

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
	interval = interval + 1
	if interval >= 30 then
		interval = 0
		if player:getVehicle() or ISSearchManager.getManager(player):checkShouldDisable() then
			return
		else
			if wait then
				wait = false
			else
				wait = true
				ISSearchManager.getManager(player):toggleSearchMode(true)
				Events.OnPlayerUpdate.Remove(SearchOnPlayerUpdate)
			end
		end
	end
end

local function SearchToggle(player, smode)
    if active and not smode then return Events.OnPlayerUpdate.Add(SearchOnPlayerUpdate) end
    if not active and smode then ISSearchManager.getManager(player):toggleSearchMode(false) end
end

local function SearchKey(_keyPressed)
    if _keyPressed == getCore():getKey("Toggle Search Mode") then
        active = not active
    end
end

Events.onToggleSearchMode.Add(SearchToggle)
Events.OnKeyPressed.Add(SearchKey)
