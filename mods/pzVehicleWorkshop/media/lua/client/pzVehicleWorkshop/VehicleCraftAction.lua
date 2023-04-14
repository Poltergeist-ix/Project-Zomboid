local modTable = require "pzVehicleWorkshop/Definitions"

require "TimedActions/ISCraftAction"
local VehicleCraftAction = ISCraftAction:derive("vwVehicleCraftAction")


modTable.VehicleCraftAction = VehicleCraftAction

do
    --[[ temp install action ]]
    local action = ISInstallVehiclePart:derive("vwVehicleCraftAction")

    function action:isValid()
        if ISVehicleMechanics.cheat then return true end
        return self.vehicle:canInstallPart(self.character, self.part) and RecipeManager.IsRecipeValid(self.vehicleRecipe, self.character, self.item, self.containers)
    end

    function action:perform()
        self.item:setJobDelta(0)
        --	self.character:addMechanicsItem(self.item:getID() .. self.vehicle:getMechanicalID() .. "1", getGameTime():getCalender():getTimeInMillis());

        local result = RecipeManager.PerformMakeItem(self.vehicleRecipe, self.item, self.character, self.containers)
        self.character:removeFromHands(self.item)
        self.character:getInventory():DoRemoveItem(self.item)

        local perksTable = {}
        local args = { vehicle = self.vehicle:getId(), part = self.part:getId(),
                       item = self.item,
                       perks = perksTable,
                       mechanicSkill = self.character:getPerkLevel(Perks.Mechanics) }
        sendClientCommand(self.character, 'vehicle', 'installPart', args)

        local pdata = getPlayerData(self.character:getPlayerNum());
        if pdata ~= nil then
            pdata.playerInventory:refreshBackpacks();
            pdata.lootInventory:refreshBackpacks();
        end
        -- needed to remove from queue / start next.
        ISBaseTimedAction.perform(self)
    end

    modTable.installAction = action
end

do
    --[[ temp uninstall action ]]
    local VehicleCraftAction = ISCraftAction:derive("vwVehicleCraftAction")
end