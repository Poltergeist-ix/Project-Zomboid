require "BuildingObjects/ISUI/ISBuildMenu"
require "BuildingObjects/ISBuildCursorMouse"

local richGood, richBad = " <RGB:0,1,0> ", " <RGB:1,0,0> "
local function wrapFn(class,method,patch)
    local original = class[method]
    class[method] = patch(original)
end

local function predicateNotBroken(item)
    return not item:isBroken()
end

local onSheetRope = function(worldobjects, player)
    ISBuildMenu.cursor = zxSheetRopeCursor:new(player)
    getCell():setDrag(ISBuildMenu.cursor, player)
end

local function onBarricade(worldobjects, player)
    ISBuildMenu.cursor = zxBarricadeCursor:new(player)
    getCell():setDrag(ISBuildMenu.cursor, player)
end

wrapFn(ISBuildMenu,"buildMiscMenu", function(originalFn) return function(subMenu, option, player, ...)
    local result = originalFn(subMenu, option, player, ...)

    local sheetrope = subMenu:addOption(getText("ContextMenu_Add_escape_rope_sheet"), {}, onSheetRope, player)
    local barricade = subMenu:addOption(getText("ContextMenu_Barricade"), {}, onBarricade, player)

    option.notAvailable = false;
    return result
 end end)

zxCommonCursor = ISBuildingObject:derive("zxCommonCursor")

function zxCommonCursor:new(player)
    local o = {};
    setmetatable(o, self);
    self.__index = self;
    o:init()
    o.player = player
    o.playerObj = getSpecificPlayer(player)
    --o.skipBuildAction = true
    --o.required = {}
    o.nFrame = 0
    o.refresh = getPerformance():getUIRenderFPS()
    return o
end

function zxCommonCursor:initialise()
    for key,req in pairs(self.required) do
        local text
        if req.isTag then
            text = key
        else
            text = getItemNameFromFullType(key)
        end
        if req.num then text = text .. ": %d/%d" end
        req.text = "\n%s" .. text
    end
end

function zxCommonCursor:render(x, y, z, square)
    local r,g,b,a = 0.0,1.0,0.0,0.8
    if not self.valid then r,g = 1,0 end
    local isoSprite = self.isoSprite or IsoSprite.new()
    isoSprite:LoadFramesNoDirPageSimple(self.choosenSprite)
    isoSprite:RenderGhostTileColor(x, y, z, r, g, b, a)

    self:renderTooltip()
end

function zxCommonCursor:renderTooltip()
    local tooltip = self.tooltip
    if not tooltip then
        tooltip = ISWorldObjectContextMenu.addToolTip()
        tooltip:setVisible(true)
        tooltip:addToUIManager()
        tooltip.maxLineWidth = 1000
        tooltip:setName(self.tooltipName)
        self.tooltip = tooltip
    end
    if self.item then
        tooltip:setTexture(self.item:getTextureName())
        --tooltip.texture = self.item:getSprite()
        local description = "Required:"
        for key,required in pairs(self.required) do
            description = description .. string.format(required.text,required.valid and richGood or richBad,required.num,required.have)
        end
        tooltip.description = description
    else
        tooltip.texture = nil
        tooltip.description = "No Valid Object"
    end
end

--buildUtil.getMaterialOnGround, only same side of walls
function zxCommonCursor:getMaterialOnGround()
    local result = {}
    if not self.item then return result end
    local squareToCheck = self.north and self.playerObj:getY() < self.item:getY() and self.sq:getAdjacentSquare(IsoDirections.N) or self.west and self.playerObj:getX() < self.item:getX() and self.sq:getAdjacentSquare(IsoDirections.W) or self.sq
    for x=squareToCheck:getX()-1,squareToCheck:getX()+1 do
        for y=squareToCheck:getY()-1,squareToCheck:getY()+1 do
            local square = getCell():getGridSquare(x,y,squareToCheck:getZ())
            if square and (square == squareToCheck or not square:isBlockedTo(squareToCheck)) then

                local wobs = square:getWorldObjects()
                for i = 0,wobs:size() -1 do
                    local item = wobs:get(i):getItem()
                    if buildUtil.predicateMaterial(item) then
                        local items = result[item:getFullType()] or {}
                        table.insert(items, item)
                        result[item:getFullType()] = items
                        result[item:getType()] = items
                    end
                end
            end
        end
    end
    return result
end

function zxCommonCursor:checkRequired(square)
    --local groundItems = buildUtil.getMaterialOnGround(square);
    local groundItems = self:getMaterialOnGround()
    local groundItemCounts = buildUtil.getMaterialOnGroundCounts(groundItems)
    --local groundItemUses = buildUtil.getMaterialOnGroundUses(groundItems)
    local playerInv = self.playerObj:getInventory()
    local haveRequired = true
    for key,required in pairs(self.required) do
        if required.num then
            local nbOfItem = playerInv:getCountTypeEvalRecurse(key, buildUtil.predicateMaterial)
            if groundItemCounts[key] then
                nbOfItem = nbOfItem + groundItemCounts[key]
            end
            --if key == "Base.Nails" then
            --    nbOfItem = nbOfItem + playerInv:getCountTypeEvalRecurse("Base.NailsBox", buildUtil.predicateMaterial)*100;
            --    if groundItemCounts["Base.NailsBox"] then
            --        nbOfItem = nbOfItem + groundItemCounts["Base.NailsBox"]*100;
            --    end
            --end
            required.have = nbOfItem
            if required.num <= nbOfItem then required.valid = true else required.valid = false; haveRequired = false end
        else
            if required.isTag then
                if playerInv:getFirstTagEvalRecurse(key, predicateNotBroken) then required.valid = true else required.valid = false; haveRequired = false end
            else
                if playerInv:getFirstTypeEvalRecurse(key, predicateNotBroken) then required.valid = true else required.valid = false; haveRequired = false end
            end
        end
    end
    return haveRequired or ISBuildMenu.cheat
end

function zxCommonCursor:tryBuild()
    local player = self.playerObj
    if not luautils.walkAdjWall(player, self.item:getSquare(), self.north ,true) then return player:Say("I can't walk there") end
    --if not luautils.walkAdj(player, self.item:getSquare(), true) then return player:Say("I can't walk there") end
    local inventory = self.playerObj:getInventory()
    local groundItems = self:getMaterialOnGround()

    for key,required in pairs(self.required) do
        if ISBuildMenu.cheat then
            if required.num then
                for i=1,required.num do
                    inventory:AddItem(InventoryItemFactory.CreateItem(key))
                end
            --else
            --    if required.isTag then
            --        if not inventory:getFirstTagEvalRecurse(key, predicateNotBroken) then
            --    else
            --
            --    end
            end
        end
        if required.equip or required.equip2 then
            local obj = required.isTag and inventory:getFirstTagEvalRecurse(key, predicateNotBroken) or inventory:getFirstTypeEvalRecurse(key, predicateNotBroken)
            if not obj and groundItems[key] then
                obj = groundItems[key][1]
                ISTimedActionQueue.add(ISGrabItemAction:new(player, obj:getWorldItem(), 100))
            end
            if not obj then return player:Say("No Equip Item") end
            local handitem = required.equip and player:getPrimaryHandItem() or player:getSecondaryHandItem()
            ISWorldObjectContextMenu.equip(player, handitem, obj, required.equip)
        end
        if required.num then
            local have = inventory:getItemCountRecurse(key)
            if required.equip then have = have + 1 end
            if required.equip2 then have = have + 1 end
            if have < required.num and groundItems[key] then
                for i = 1, required.num-have do
                    local item = groundItems[key][i]
                    if item then
                        ISTimedActionQueue.add(ISGrabItemAction:new(player, groundItems[key][i]:getWorldItem(), 100))
                        have = have +1
                    end
                end
            end

            ----alternatives, open box
            --local alt = key.."Box"
            --local have =
            --if have < required.num and groundItems[alt] then
            --    ISTimedActionQueue.add(ISGrabItemAction:new(player, groundItems[key.."Box"][i]:getWorldItem(), 100))
            --end
            if have < required.num then return player:Say("Where is "..key) end
        end
    end
    return self:create()
end

function zxCommonCursor:hideTooltip()
    if self.tooltip then
        self.tooltip:removeFromUIManager()
        self.tooltip:setVisible(false)
        self.tooltip = nil
    end
end

function zxCommonCursor:deactivate()
    self:hideTooltip();
end

zxSheetRopeCursor = zxCommonCursor:derive("zxSheetRopeCursor")

function zxSheetRopeCursor:new(player)
    local o = zxCommonCursor.new(self,player)
    o.sprite = "crafted_01_3"
    --o.westSprite = "crafted_01_3"
    o.northSprite = "crafted_01_4"
    --o.eastSprite = "crafted_01_0"
    --o.southSprite = "crafted_01_1"
    o.tooltipName = getText("ContextMenu_Add_escape_rope_sheet")
    o.required = { ["Hammer"] = { isTag = true, equip = true },
                  ["Base.SheetRope"] = { isMaterial = true, num = 2},
                  ["Base.Nails"] = { isMaterial = true, num = 1}}
    o:initialise()
    return o
end

function zxSheetRopeCursor:isValid(square)
    if self. sq ~= square or self.nFrame % self.refresh == 0 then
        self.sq = square
        self.nFrame = 0

        local validObject
        for i = 0, square:getObjects():size() - 1 do
            local object = square:getObjects():get(i);
            if instanceof(object, "IsoThumpable") and not object:isDoor() and object:isWindow() or instanceof(object, "IsoWindow") then
                if not object:isBarricaded() and self.north == object:getNorth() then
                    validObject = object
                end
            elseif object:getSprite() and object:getSprite():getProperties() and (object:getSprite():getProperties():Is(IsoFlagType.HoppableN) or object:getSprite():getProperties():Is(IsoFlagType.HoppableW)) then
                if self.north and object:getSprite():getProperties():Is(IsoFlagType.HoppableN) or self.west and object:getSprite():getProperties():Is(IsoFlagType.HoppableW) then
                    validObject = object
                end
            end
            if validObject then
                local count = validObject:countAddSheetRope()
                if count > 0 then
                    self.required["Base.SheetRope"].num = count
                else
                    validObject = nil
                end
            end
            if instanceof(object, "IsoObject") and object:getSprite() and object:getSprite():getProperties() and object:getSprite():getProperties():Is(IsoFlagType.makeWindowInvincible) then
                validObject = nil
                break
            end
        end
        self.item = validObject
        if validObject and self:checkRequired(square) then
            self.valid = true
        else
            self.valid = false
        end
    end
    self.nFrame = self.nFrame +1
    return self.valid
end

function zxSheetRopeCursor:create()
    ISTimedActionQueue.add(ISAddSheetRope:new(self.playerObj, self.item))
end

zxBarricadeCursor = zxCommonCursor:derive("zxBarricadeCursor")

function zxBarricadeCursor:new(player)
    local o = zxCommonCursor.new(self,player)
    o.sprite = "carpentry_01_8"
    --o.westSprite = "carpentry_01_8"
    o.northSprite = "carpentry_01_9"
    o.tooltipName = getText("ContextMenu_Barricade")
    o.required = { ["Hammer"] = { isTag = true, equip = true},
                  ["Base.Plank"] = { num = 1, equip2 = true },
                  ["Base.Nails"] = { isMaterial = true, num = 2}}
    o:initialise()
    return o
end

function zxBarricadeCursor:isValid(square)
    if self. sq ~= square or self.nFrame >= self.refresh then
        self.sq = square
        self.nFrame = 0
        local player = self.playerObj
        local validObject
        --test
        --if getDebug() then for i=0, square:getObjects():size()-1 do if instanceof(square:getObjects():get(i), "BarricadeAble") then print("zxtest, barricadeable", square:getObjects():get(i)) end end end

        for i = 0, square:getObjects():size() - 1 do
            local object = square:getObjects():get(i)
            if (instanceof(object, "IsoThumpable") or instanceof(object, "IsoWindow") or instanceof(object, "IsoDoor")) and self.north == object:getNorth() and object:isBarricadeAllowed() then
                --thump and not object:haveSheetRope()
                local barricade = object:getBarricadeForCharacter(player)
                if not barricade or barricade:canAddPlank() then
                    validObject = object
                    break
                end
            end
        end
        self.item = validObject
        if validObject and self:checkRequired(square) then
            self.valid = true
        else
            self.valid = false
        end
    end
    self.nFrame = self.nFrame + 1
    return self.valid
end

function zxBarricadeCursor:create()
    ISTimedActionQueue.add(ISBarricadeAction:new(self.playerObj, self.item, false, false, (100 - (self.playerObj:getPerkLevel(Perks.Woodwork) * 5))))
end
