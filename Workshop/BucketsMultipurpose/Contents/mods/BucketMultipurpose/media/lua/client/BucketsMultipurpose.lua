local Items = {}
Items.ModOptions = {}

local function predicateDirtToolNotBroken(item)
    return item:hasTag("TakeDirt") and not item:isBroken()
end

local function predicateDirtNotFull(item)
    return item:hasTag("_EmptySolidContainer") and item:hasReplaceType("DirtSource") or (item:hasTag("_DirtContainer") and item:getUsedDelta() + item:getUseDelta() <= 1)
end

local function predicateGravelNotFull(item)
    return item:hasTag("_EmptySolidContainer") and item:hasReplaceType("GravelSource") or (item:hasTag("_GravelContainer") and item:getUsedDelta() + item:getUseDelta() <= 1)
end

local function predicateSandNotFull(item)
    return item:hasTag("_EmptySolidContainer") and item:hasReplaceType("SandSource") or (item:hasTag("_SandContainer") and item:getUsedDelta() + item:getUseDelta() <= 1)
end

local function predicateCompostNotFull(item)
    return item:hasTag("_EmptySolidContainer") and item:hasReplaceType("CompostSource") or item:hasTag("_FertilizerContainer") and item:getUsedDelta() + item:getUseDelta() <= 1
end

local function predicateCompostNotEmpty(item)
    return item:hasTag("_FertilizerContainer")
end

local function comparatorMostFull(item1, item2)
    return item1:getUsedDelta() - item2:getUsedDelta()
end

local function addOrGroupContextOption(context, name, ...)
    local subMenu
    local identifier = "M' "..name
    for i,option in ipairs(context.options) do
        if option.name == name then
            if not option.subOption then
                local newOption = context:allocOption(name)
                newOption.id = option.id
                context.options[i] = newOption
                subMenu = context:getNew(context)
                context:addSubMenu(newOption,subMenu)
                option.id = 1
                subMenu.options[1] = option
                subMenu.numOptions = 2
            else
                subMenu = context:getSubMenu(option.subOption)
            end
            break
        end
    end
    if subMenu then
        subMenu:addOption(identifier,...)
    else
        context:addOption(identifier,...)
    end
end

local function addOrReplaceContextOption(context, name,...)
    local identifier = "M' "..name
    for i,option in ipairs(context.options) do
        if option.name == name then
            table.insert(context.optionPool, option)
            local newOption = context:allocOption(identifier,...)
            newOption.id = option.id
            context.options[i] = newOption
            return newOption
        end
    end
    return context:addOption(identifier,...)
end

local function onTakeDirt(playerObj,player,info)
    getCell():setDrag(Items.ShovelGroundCursor:new(playerObj,info), player)
end

local function onSpillDirt(info, player, playerObj, obj)
    getCell():setDrag(Items.NaturalFloor:new(info, playerObj, obj), player)
end

local ISGetCompost_perform = function(self)
    local COMPOST_PER_USE = 10
    local USES_PER_BAG = 4
    local COMPOST_PER_USE = 2.5
    local amount = self.compost:getCompost()
    local uses = math.floor(amount / COMPOST_PER_USE)
    if self.item:hasTag("_FertilizerContainer") then
        uses = math.min(uses, USES_PER_BAG - self.item:getDrainableUsesInt())
        self.item:setUsedDelta(self.item:getUsedDelta() + self.item:getUseDelta() * uses)
    else
        self.character:removeFromHands(self.item);
        self.character:getInventory():Remove(self.item);
        local compostBag = self.character:getInventory():AddItem(self.item:getReplaceType("FertilizerSource"))
        uses = math.min(uses, USES_PER_BAG)
        compostBag:setUsedDelta(compostBag:getUseDelta() * uses);
        self.character:setPrimaryHandItem(compostBag)
    end
    self.compost:setCompost(self.compost:getCompost() - uses * COMPOST_PER_USE);
    self.compost:updateSprite();
    if isClient() then
        self.compost:syncCompost();
    end
    -- needed to remove from queue / start next.
    ISBaseTimedAction.perform(self);
end

local onGetCompost = function(compost, item, playerObj)
    if luautils.walkAdj(playerObj, compost:getSquare()) then
        ISWorldObjectContextMenu.transferIfNeeded(playerObj, item)
        ISWorldObjectContextMenu.equip(playerObj, playerObj:getPrimaryHandItem(), item, true, false)
        local o = ISGetCompost:new(playerObj, compost, item, 100)
        o.perform = ISGetCompost_perform
        ISTimedActionQueue.add(o)
    end
end

local function isFertilizeValid()
    if not ISFarmingMenu.cursor then return false; end
    local valid = true
    local cursor = ISFarmingMenu.cursor
    local playerObj = cursor.character
    local playerInv = playerObj:getInventory()
    local plant = CFarmingSystem.instance:getLuaObjectOnSquare(cursor.sq)
    local plantName = ISFarmingMenu.getPlantName(plant)

    if not ISFarmingMenu.isValidPlant(plant) then
        cursor.tooltipTxt = "<RGB:1,0,0> " .. getText("Farming_Tooltip_NotAPlant")
        return false
    end

    cursor.tooltipTxt = plantName .. " <LINE> ";
    cursor.tooltipTxt = cursor.tooltipTxt .. getText("Farming_Fertilized") .. " : " .. plant.fertilizer

    if playerInv:containsEvalRecurse(predicateCompostNotEmpty) then
        return true
    end

    return false
end

local function onFertilizeSquareSelected()
    local cursor = ISFarmingMenu.cursor
    local playerObj = cursor.character
    if not ISFarmingMenu.walkToPlant(playerObj, cursor.sq) then
        return
    end
    local plant = CFarmingSystem.instance:getLuaObjectOnSquare(cursor.sq)
    local handItem = playerObj:getPrimaryHandItem()
    handItem = ISWorldObjectContextMenu.equip(playerObj, handItem, predicateCompostNotEmpty, true)
    ISTimedActionQueue.add(ISFertilizeAction:new(playerObj, handItem, plant, 40))
end

local onFertilize = function(worldobjects, plant, sq, playerObj)
    -- close the farming info window to avoid concurrent gorwing phase problem
    if not ISFarmingMenu.walkToPlant(playerObj, sq) then
        return;
    end
    local handItem = playerObj:getPrimaryHandItem()
    handItem = ISWorldObjectContextMenu.equip(playerObj, handItem, predicateCompostNotEmpty, true)
    if not handItem then return end
    ISTimedActionQueue.add(ISFertilizeAction:new(playerObj, handItem, plant, 40));

    if playerObj:getJoypadBind() ~= -1 then
        return
    end

    ISFarmingMenu.cursor = ISFarmingCursorMouse:new(playerObj, onFertilizeSquareSelected, isFertilizeValid)
    getCell():setDrag(ISFarmingMenu.cursor, playerObj:getPlayerNum())
end

---Radial Menu
Items.Items_RadialMenuView = ISBaseObject:derive("Items_RadialMenuView")
local RadialMenuView  = Items.Items_RadialMenuView
--RadialMenuView.initSliceFunctions = {}
RadialMenuView.sliceFunctions = {}
local radialKey = { name = "radial", key = Keyboard.KEY_NONE, delay = 250 }
Items.ModOptions.radialKey = radialKey

function RadialMenuView:new(player,radialMenu)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.player = player
    o.playerObj = getSpecificPlayer(player)
    o.radialMenu = radialMenu
    o.viewSlices = {}
    RadialMenuView.instance = o
    return o
end

function RadialMenuView:performRecipe(item, recipe, containers)
    local player = self.playerObj
    if RecipeManager.IsRecipeValid(recipe, player, item, containers) then
        local primary = player:isPrimaryHandItem(item)
        local secondary = player:isSecondaryHandItem(item)
        local resultItemCreated = RecipeManager.PerformMakeItem(recipe, item, player, containers)
        player:getInventory():AddItem(resultItemCreated)
        if primary then player:setPrimaryHandItem(resultItemCreated) end
        if secondary then player:setSecondaryHandItem(resultItemCreated) end
        ISInventoryPage.dirtyUI()

        return resultItemCreated
    end
end

function RadialMenuView:convertToWeapon(item, recipe, containers)
    ISInventoryPaneContextMenu.equipWeapon(self:performRecipe(item, recipe, containers), true, true, self.player)
end

function RadialMenuView:addFilteredItemRecipes(item, player, containers)
    local recipesList = RecipeManager.getUniqueRecipeItems(item, player, containers)
    if recipesList:isEmpty() then return end
    for i=0, recipesList:size()-1 do
        local recipe = recipesList:get(i)
        local type = recipe:getFullType()
        if type:contains("ConvertToBase") then
            table.insert(self.viewSlices,{ text = recipe:getName(), texture = getScriptManager():getItem(recipe:getResult():getFullType()):getNormalTexture(), command = {self.performRecipe, self, item, recipe, containers} })
        elseif type:contains("ConvertToWeapon") then
            table.insert(self.viewSlices,{ text = recipe:getName(), texture = getTexture("media/ui/MIC_Weapon.png"), command = { self.convertToWeapon, self, item, recipe, containers } })
            --table.insert(self.viewSlices,{ text = recipe:getName(), texture = getTexture("pvpicon_on"), command = { self.convertToWeapon, self, item, recipe, containers } })
        elseif type:contains("ConvertToContainer") then
            table.insert(self.viewSlices,{ text = recipe:getName(), texture = getTexture("media/ui/MIC_Container.png"), command = { self.performRecipe, self, item, recipe, containers } })
            --table.insert(self.viewSlices,{ text = recipe:getName(), texture = getTexture("Item_Backpack_Black"), command = { self.performRecipe, self, item, recipe, containers } })
        end
    end
end

--check item recipes for conversions, equipped first, then more recent
function RadialMenuView.sliceFunctions:recipeSlices()
    local player = self.playerObj
    local containers = ISInventoryPaneContextMenu.getContainers(player)
    local item = player:getPrimaryHandItem()
    if item then self:addFilteredItemRecipes(item, player, containers) end
    item = player:getSecondaryHandItem()
    if item then self:addFilteredItemRecipes(item, player, containers) end
    if #self.viewSlices == 0 then
        local items = player:getInventory():getItems()
        for i=items:size()-1,0,-1 do
            self:addFilteredItemRecipes(items:get(i), player, containers)
            if #self.viewSlices ~= 0 then break end
        end
    end
end

function RadialMenuView:activateRadialView()
    local menu = self.radialMenu

    menu.slices = self.viewSlices
    menu.slices.type = "MIC"
    if menu.javaObject then
        menu.javaObject:clear()
        for _,slice in ipairs(self.viewSlices) do
            menu.javaObject:addSlice(slice.text,slice.texture)
        end
    end

    menu:center()
    menu:addToUIManager()
    if JoypadState.players[self.player+1] then
        menu:setHideWhenButtonReleased(Joypad.RBumper)
        setJoypadFocus(self.playerNum, menu)
        self.playerObj:setJoypadIgnoreAimUntilCentered(true)
    end
    Events.OnPreUIDraw.Add(RadialMenuView.render)
end

local function checkKeyIsInGame()
    if MainScreen.instance:isVisible() then return false end
    local player = getPlayer()
    if not player or player:isDead() then return false end
    return true
end

function RadialMenuView.onKeyPressed(keyNum)
    if keyNum == radialKey.key and checkKeyIsInGame() then
        local radialMenu = getPlayerRadialMenu(0)
        if getCore():getOptionRadialMenuKeyToggle() and radialMenu:isReallyVisible() then
            radialKey.radialWasVisible = true
            radialMenu:removeFromUIManager()
            return
        end

        radialKey.targetMS = getTimestampMs() + radialKey.delay
        radialKey.radialWasVisible = false
    end
end

function RadialMenuView.onKeyRepeat(keyNum)
    if keyNum == radialKey.key and checkKeyIsInGame() then
        if not radialKey.targetMS then return end
        if radialKey.radialWasVisible then return end
        local radialMenu = getPlayerRadialMenu(0)
        if (getTimestampMs() >= radialKey.targetMS) and not radialMenu:isReallyVisible() then
            local rmv = RadialMenuView:new(0, radialMenu)
            for name,func in pairs(RadialMenuView.sliceFunctions) do
                func(rmv)
            end
            if #rmv.viewSlices ~= 0 then
                rmv:activateRadialView()
            end
            radialKey.targetMS = nil
        end
    end
end

function RadialMenuView.onKeyReleased(keyNum)
    if keyNum == radialKey.key and checkKeyIsInGame() then
        if not radialKey.targetMS then return end
        local radialMenu = getPlayerRadialMenu(0)
        if radialMenu:isReallyVisible() or radialKey.radialWasVisible then
            if not getCore():getOptionRadialMenuKeyToggle() then
                radialMenu:removeFromUIManager()
            end
            return
        end
        radialKey.targetMS = nil
    end
end

--add extra icons to Radial, width, height are hardcoded values so no calculations are required
function RadialMenuView.render()
    local menu = RadialMenuView.instance and RadialMenuView.instance.radialMenu
    if not menu or not menu:isReallyVisible() or not (menu.slices and menu.slices.type == "MIC") then return Events.OnPreUIDraw.Remove(RadialMenuView.render) end
    local x = (menu:getWidth() - menu.innerRadius) / 2
    menu:drawTextureScaledAspect(menu.slices[1]["command"][3]:getTex(), x, x, menu.innerRadius, menu.innerRadius, 1, 1, 1, 1)
end

local function setOverrideHandModels_patch(setOverrideHandModels)
    return function(self, _primaryHand, ...)
        _primaryHand = _primaryHand and instanceof(_primaryHand,"DrainableComboItem") and _primaryHand:getReplaceOnDeplete() == "BucketTypeEmpty" and _primaryHand:getStaticModel() or _primaryHand
        setOverrideHandModels(self, _primaryHand, ...)
    end
end

-- cursor is in server file, make sure it's loaded
-- inherit from edited class // likely to break with vanilla - mod changes
local function OnGameStart()

    do
        local action = ISShovelGround:derive("Items_ShovelGround")

        function action:new(character,emptyItem,sandTile,info)
            local o = ISShovelGround.new(self,character,emptyItem,sandTile,"blends_natural_01_64",info.jobType)
            o.validPredicate = info.validPredicate
            o.info = info
            return o
        end

        function action:isValid()
            if instanceof(self.emptyBag, "InventoryContainer") then
                if self.emptyBag:getInventory():isEmpty() == false then
                    return false
                end
            end
            return self.character:getInventory():contains(self.emptyBag) and
                    self.sandTile and self.sandTile:getSprite() and
                    --self.sandTile:getSprite():getName() ~= self.newSprite and
                    self.validPredicate(self.emptyBag)
        end

        function action:perform()
            self.emptyBag:setJobDelta(0.0)
            if self.sound ~= 0 and self.character:getEmitter():isPlaying(self.sound) then
                self.character:getEmitter():stopSound(self.sound);
            end
            local sq = self.sandTile:getSquare()
            local args = { x = sq:getX(), y = sq:getY(), z = sq:getZ() }
            sendClientCommand(self.character, 'object', 'shovelGround', args)

            -- FIXME: server should manage the player's inventory
            if self.emptyBag:hasTag("_EmptySolidContainer") then --change here!
                local isPrimary = self.character:isPrimaryHandItem(self.emptyBag)
                local isSecondary = self.character:isSecondaryHandItem(self.emptyBag)
                self.character:removeFromHands(self.emptyBag);
                self.character:getInventory():Remove(self.emptyBag);
                local item = self.character:getInventory():AddItem(self.emptyBag:getReplaceType(self.info.sourceType)) --change here!
                if item ~= nil then
                    item:setUsedDelta(item:getUseDelta())
                    if isPrimary then
                        self.character:setPrimaryHandItem(item)
                    end
                    if isSecondary then
                        self.character:setSecondaryHandItem(item)
                    end
                end
            elseif self.emptyBag:getUsedDelta() + self.emptyBag:getUseDelta() <= 1 then
                self.emptyBag:setUsedDelta(self.emptyBag:getUsedDelta() + self.emptyBag:getUseDelta())
            end
            if ZombRand(5) == 0 then
                self.character:getInventory():AddItem("Base.Worm");
            end
            -- refresh backpacks to hide equipped filled dirt bags
            getPlayerInventory(self.character:getPlayerNum()):refreshBackpacks();
            getPlayerLoot(self.character:getPlayerNum()):refreshBackpacks();
            -- needed to remove from queue / start next.
            ISBaseTimedAction.perform(self)
        end

        Items.ShovelGround = action
    end

    do
        local cursor = ISShovelGroundCursor:derive("Items_ShovelGroundCursor")

        cursor.groundTypes = {
            dirt = {groundType="dirt",contextText="ContextMenu_Take_some_dirt",tag="_DirtContainer",validPredicate=predicateDirtNotFull,sourceType="DirtSource",jobType="Base.Dirtbag"},
            gravel = {groundType="gravel",contextText="ContextMenu_Take_some_gravel",tag="_GravelContainer",validPredicate=predicateGravelNotFull,sourceType="GravelSource",jobType="Base.Gravelbag"},
            sand = {groundType="sand",contextText="ContextMenu_Take_some_sands",tag="_SandContainer",validPredicate=predicateSandNotFull,sourceType="SandSource",jobType="Base.Sandbag"},
        }

        function cursor:new(playerObj,info)
            local o = ISShovelGroundCursor.new(self,"floors_exterior_natural_01_13","floors_exterior_natural_01_13",playerObj,info.groundType)
            o.tag = info.tag
            o.validPredicate = info.validPredicate
            o.info = info
            return o
        end

        function cursor:isValid(square)
            local groundType,object = self:getDirtGravelSand(square)
            return (groundType == self.groundType) and self.character:getInventory():containsEvalRecurse(self.validPredicate)
        end

        function cursor:getEmptyItem()
            local playerInv = self.character:getInventory()
            local item = playerInv:getBestEvalRecurse(function(item) return item:hasTag(self.tag) and item:getUsedDelta() + item:getUseDelta() <= 1 end, comparatorMostFull)
            if not item then item = playerInv:getFirstEvalRecurse(function(item) return item:hasTag("_EmptySolidContainer") and item:hasReplaceType(self.info.sourceType) end) end
            return item
            --return "Base.Dirtbag",item --"string used as table key for name to set jobType in start"
        end

        function cursor:create(x, y, z, north, sprite)
            local playerObj = self.character
            local square = getWorld():getCell():getGridSquare(x, y, z)
            local groundType,object = self:getDirtGravelSand(square)
            local emptyItem = self:getEmptyItem()
            --local fullType,emptyItem = self:getEmptyItem()
            if luautils.walkAdj(playerObj, square, true) then
                ISWorldObjectContextMenu.transferIfNeeded(playerObj, emptyItem)
                ISWorldObjectContextMenu.equip(playerObj, playerObj:getPrimaryHandItem(), predicateDirtToolNotBroken, true, false)
                ISWorldObjectContextMenu.equip(playerObj, playerObj:getSecondaryHandItem(), emptyItem, false, false)
                ISTimedActionQueue.add(Items.ShovelGround:new(playerObj, emptyItem, object, self.info))
            end
        end

        function cursor.GetCountsNotFull(inventory)
            local counts = {}
            for key,info in pairs(cursor.groundTypes) do
                counts[key] = inventory:getCountEvalRecurse(info.validPredicate)
            end
            return counts
        end

        Items.ShovelGroundCursor = cursor
    end

    do
        local cursor = ISNaturalFloor:derive("Items_NaturalFloor")

        cursor.floorInfo = {
            dirt = {floorType="dirt",text="ContextMenu_Spill_Dirt",tag="_DirtContainer",textureName="blends_natural_01_64",bank="DropSoilFromDirtBag"},
            gravel = {floorType="gravel",text="ContextMenu_Spill_Gravel",tag="_GravelContainer",textureName="blends_street_01_55",bank="DropSoilFromGravelBag"},
            sand =  {floorType="sand",text="ContextMenu_Spill_Sand",tag="_SandContainer",textureName="blends_natural_01_5",bank="DropSoilFromSandBag"},
        }

        function cursor:new(info,playerObj,obj)
            local o = ISNaturalFloor.new(self,info.textureName, info.textureName, obj, playerObj)
            --print("buckets: ",o.floorType)
            o.floorType = info.floorType
            o.craftingBank = info.bank
            o.tag = info.tag
            return o
        end

        function cursor:isValid(square)
            local inv = self.character:getInventory()
            if not inv:containsRecursive(self.item) then
                self.item = inv:getFirstTagRecurse(self.tag)
            end
            return ISNaturalFloor.isValid(self,square)
        end

        function cursor:getFloorType(item)
            return self.floorType or "none"
        end

        function cursor:onTimedActionStart(action)
            action:setActionAnim(CharacterActionAnims.Pour)
            local eatType = self.item:getEatType()
            if eatType then
                action:setAnimVariable("FoodType", eatType)
                action:setOverrideHandModels(self.item:getStaticModel() or self.item, nil)
            else
                action:setOverrideHandModels(self.item, nil)
            end
        end

        Items.NaturalFloor = cursor
    end

    --fix for animations, can patch ISBaseTimedAction.setOverrideHandModels instead
    ISWaterPlantAction.setOverrideHandModels = setOverrideHandModels_patch(ISWaterPlantAction.setOverrideHandModels)
    ISDumpWaterAction.setOverrideHandModels = setOverrideHandModels_patch(ISDumpWaterAction.setOverrideHandModels)
    ISDumpContentsAction.setOverrideHandModels = setOverrideHandModels_patch(ISDumpContentsAction.setOverrideHandModels)

    --add composter interactions
    local ISWorldObjectContextMenu_handleCompost = ISWorldObjectContextMenu.handleCompost
    function ISWorldObjectContextMenu.handleCompost(test, context, worldobjects, playerObj, playerInv)
        if test == true then return true end
        local nOptions = #context.options
        ISWorldObjectContextMenu_handleCompost(test, context, worldobjects, playerObj, playerInv)

        local percent = round(compost:getCompost(), 1)
        --local COMPOST_PER_BAG = 10
        --local USES_PER_BAG = 1.0 / compostBagScriptItem:getUseDelta()
        --local COMPOST_PER_USE = COMPOST_PER_BAG / USES_PER_BAG
        local USES_PER_BAG = 4
        local COMPOST_PER_USE = 2.5

        if percent > COMPOST_PER_USE then
            local compostContainers = playerInv:getAllEvalRecurse(predicateCompostNotFull)
            if not compostContainers:isEmpty() then
                local compostOption = context.options[nOptions+1]
                compostOption.notAvailable = false
                local subMenu = compostOption.subOption and context:getSubMenu(compostOption.subOption)
                if not subMenu then subMenu = context:getNew(context); context:addSubMenu(compostOption, subMenu) end
                for i=0,compostContainers:size()-1 do
                    local compostBag = compostContainers:get(i)
                    local availableUses = USES_PER_BAG - (instanceof(compostBag,"DrainableComboItem") and compostBag:getDrainableUsesInt() or 0)
                    subMenu:addOption(getText("ContextMenu_GetCompostItem", compostBag:getDisplayName(), math.min(percent, availableUses * COMPOST_PER_USE)), compost, onGetCompost, compostBag, playerObj)
                    --break--
                end
            end
        end

        --if compost:getCompost() + COMPOST_PER_USE <= 100 then
        if percent + COMPOST_PER_USE <= 100 then
            local containers = playerInv:getAllEvalRecurse(predicateCompostNotEmpty)
            if not containers:isEmpty() then
                local addCompostOption = context.options[nOptions+2]
                local subMenu = addCompostOption and addCompostOption.name == getText("ContextMenu_AddCompost") and addCompostOption.subOption and context:getSubMenu(addCompostOption.subOption)
                if not subMenu then subMenu = context:getNew(context); context:addSubMenu(context:addOption(getText("ContextMenu_AddCompost")), subMenu) end
                for i=0,containers:size()-1 do
                    local container = containers:get(i)
                    subMenu:addOption(getText("ContextMenu_AddCompostItem", container:getDisplayName(), math.min(100 - percent, container:getDrainableUsesInt() * COMPOST_PER_USE)), compost, ISWorldObjectContextMenu.onAddCompost, container, playerObj)
                end
            end
        end
    end

    --add compost option for farming
    local ISFarmingMenu_doFarmingMenu2 = ISFarmingMenu.doFarmingMenu2
    ISFarmingMenu.doFarmingMenu2 = function(player, context, worldobjects, test, ...)
        ISFarmingMenu_doFarmingMenu2(player, context, worldobjects, test, ...)
        local playerObj = getSpecificPlayer(player)
        for _,obj in ipairs(worldobjects) do
            local square = obj:getSquare()
            local plant = CFarmingSystem.instance:getLuaObjectOnSquare(square)
            if plant then
                if playerObj:getInventory():containsEvalRecurse(predicateCompostNotEmpty) then
                    if test then return ISWorldObjectContextMenu.setTest() end
                    addOrGroupContextOption(context, getText("ContextMenu_Fertilize"), worldobjects, onFertilize, plant, square, playerObj)
                end
                break
            end
        end
    end

    Events.OnKeyStartPressed.Add(RadialMenuView.onKeyPressed)
    Events.OnKeyKeepPressed.Add(RadialMenuView.onKeyRepeat)
    Events.OnKeyPressed.Add(RadialMenuView.onKeyReleased)
end

local OnFillWorldObjectContextMenu = function(player, context, worldobjects, test)
    if test and ISWorldObjectContextMenu.Test then return true end
    local playerObj = getSpecificPlayer(player)
    local playerInv = playerObj:getInventory()
    if playerInv:containsEvalRecurse(predicateDirtToolNotBroken) then
        local takeOptions = {}
        local checkedSq = {}
        local counts = Items.ShovelGroundCursor.GetCountsNotFull(playerInv)
        for _,obj in ipairs(worldobjects) do
            local sq = obj:getSquare()
            if not checkedSq[sq] then
                checkedSq[sq] = true
                local groundType,object = ISShovelGroundCursor.GetDirtGravelSand(sq)
                if groundType and counts[groundType] > 0 then takeOptions[groundType] = object end
            end
        end
        for key,obj in pairs(takeOptions) do
            if test then return ISWorldObjectContextMenu.setTest() end
            local info = Items.ShovelGroundCursor.groundTypes[key]
            context:addOption(getText(info.contextText), playerObj, onTakeDirt, player, info) --todo test vanilla / mod items
        end
    end

    for key,spillType in pairs(Items.NaturalFloor.floorInfo) do
        local obj = playerInv:getFirstTagRecurse(spillType.tag)
        if obj then
            context:addOption(getText(spillType.text), spillType, onSpillDirt, player, playerObj, obj)
        end
    end
end

Events.OnGameStart.Add(OnGameStart)
Events.OnFillWorldObjectContextMenu.Add(OnFillWorldObjectContextMenu)



if getDebug() then
    if not ModOptions then radialKey = { key = Keyboard.KEY_T, delay = 250 } end
end
if getPlayer() then
    --reloadLuaFile("media/lua/shared/TimedActions/ISBaseTimedAction.lua")
    --reloadLuaFile("media/lua/client/ISUI/ISInventoryPane.lua")
    --reloadLuaFile("media/lua/client/ISUI/ISWorldObjectContextMenu.lua")
    --reloadLuaFile("media/lua/client/Farming/ISUI/ISFarmingMenu.lua")
    --reloadLuaFile("media/lua/client/TimedActions/ISDumpContentsAction.lua")
    OnGameStart()
end

return Items