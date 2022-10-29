require "BuildingObjects/ISUI/ISBuildMenu"

local function predicateNotBroken(item)
    return not item:isBroken()
end

-- oISBuildMenubuildMiscMenu = oISBuildMenubuildMiscMenu or ISBuildMenu.buildMiscMenu
local oISBuildMenubuildMiscMenu = ISBuildMenu.buildMiscMenu
ISBuildMenu.buildMiscMenu = function(subMenu, option, player,...)
    local o = oISBuildMenubuildMiscMenu(subMenu, option, player,...)

    local playerObj = getSpecificPlayer(player)

    local sheetrope = subMenu:addOption(getText("ContextMenu_Add_escape_rope_sheet"), {}, ISBuildMenu.onSheetRope, playerObj)
    --local toolTip = ISWorldObjectContextMenu.addToolTip()
    --sheetrope.toolTip = toolTip
    --toolTip.description = "Sheet Rope: " .. tostring(playerObj:getInventory():getItemCountRecurse("SheetRope"))
    --toolTip.description = toolTip.description .. "\nFloor: " .. playerObj:getZ()
    --toolTip:setName(getText("ContextMenu_Add_escape_rope_sheet"))
    --ISBuildMenu.requireHammer(crossOption);

     local barricade = subMenu:addOption(getText("ContextMenu_Barricade"), {}, ISBuildMenu.onBarricade, playerObj)
    -- local toolTip = ISBuildMenu.addToolTip()
    -- sheetrope.tooltip = toolTip
    -- toolTip.description = "Sheet Rope: " .. tostring(playerInv:getItemCountRecurse("SheetRope"))
    -- toolTip.description = toolTip.description .. "\nFloor: " .. player:getZ()
    -- toolTip:setName(getText("ContextMenu_Add_escape_rope_sheet"))

    option.notAvailable = false;
    return o
end

ISBuildMenu.onSheetRope = function(worldobjects, player)
    ISBuildMenu.cursor = ISBuildCursorMouse:new(player, ISBuildMenu.onSheetRopeBuild, ISBuildMenu.isSheetRopeValid)
    getCell():setDrag(ISBuildMenu.cursor, player:getPlayerNum())

    ISBuildMenu.cursor.sprite = "crafted_01_3"
    ISBuildMenu.cursor.westSprite = "crafted_01_3"
    ISBuildMenu.cursor.northSprite = "crafted_01_4"
    --ISBuildMenu.cursor.eastSprite = "crafted_01_0"
    --ISBuildMenu.cursor.southSprite = "crafted_01_1"
end

ISBuildMenu.onSheetRopeBuild = function(cursor)
    if ISBuildMenu.cheat then
        local inv = ISBuildMenu.cursor.character:getInventory()
        inv:AddItems("SheetRope",ISBuildMenu.cursor.item:countAddSheetRope())
        inv:AddItem(InventoryItemFactory.CreateItem("Nails"))
    end
    return ISWorldObjectContextMenu.onAddSheetRope({}, ISBuildMenu.cursor.item, ISBuildMenu.cursor.character:getPlayerNum())
end


ISBuildMenu.isSheetRopeValid = function()
    if not ISBuildMenu.cursor or not ISBuildMenu.cursor.sq then
        return false;
    end
    local cursor = ISBuildMenu.cursor
    local player = cursor.character
    local sq = cursor.sq
    local validObject

    if cursor.nSprite > 2 then cursor.nSprite = 1 end
    if cursor.nSprite == 1 then
        cursor.sprite = cursor.westSprite
        cursor.west = true
        cursor.north = false
    else
        cursor.sprite = cursor.northSprite
        cursor.west = false
        cursor.north = true
    end

    for i = 0, sq:getObjects():size() - 1 do
        local object = sq:getObjects():get(i);
        if instanceof(object, "IsoThumpable") and not object:isDoor() and object:isWindow() or instanceof(object, "IsoWindow") then
            if not object:isBarricaded() and cursor.north == object:getNorth() then
                validObject = object
            end
        elseif object:getSprite() and object:getSprite():getProperties() and (object:getSprite():getProperties():Is(IsoFlagType.HoppableN) or object:getSprite():getProperties():Is(IsoFlagType.HoppableW)) then
            if cursor.north and object:getSprite():getProperties():Is(IsoFlagType.HoppableN) or cursor.west and object:getSprite():getProperties():Is(IsoFlagType.HoppableW) then
                validObject = object
            end
        end

        if instanceof(object, "IsoObject") and object:getSprite() and object:getSprite():getProperties() and object:getSprite():getProperties():Is(IsoFlagType.makeWindowInvincible) then
        	return false
        end
    end
    if not validObject or not validObject:canAddSheetRope() then return false end

    cursor.item = validObject
    if player:getZ() > 0 and player:getInventory():containsTypeRecurse("Nails") and player:getInventory():getItemCountRecurse("SheetRope") >= validObject:countAddSheetRope() then
        return true
    elseif ISBuildMenu.cheat then
        return true
    end

    return false
end
ISBuildMenu.onBarricade = function(worldobjects, player)
    ISBuildMenu.cursor = ISBuildCursorMouse:new(player, ISBuildMenu.onBarricadeBuild, ISBuildMenu.isBarricadeValid)
    getCell():setDrag(ISBuildMenu.cursor, player:getPlayerNum())

    ISBuildMenu.cursor.sprite = "carpentry_01_8"
    ISBuildMenu.cursor.westSprite = "carpentry_01_8"
    ISBuildMenu.cursor.northSprite = "carpentry_01_9"
end

ISBuildMenu.onBarricadeBuild = function(cursor)
    if ISBuildMenu.cheat then
        local inv = ISBuildMenu.cursor.character:getInventory()
        inv:AddItem("Plank")
        inv:AddItems("Nails",2)
    end
    return ISWorldObjectContextMenu.onBarricade(nil, ISBuildMenu.cursor.item, ISBuildMenu.cursor.player)
end


ISBuildMenu.isBarricadeValid = function()
    if not ISBuildMenu.cursor or not ISBuildMenu.cursor.sq then
        return false;
    end
    local cursor = ISBuildMenu.cursor
    local player = cursor.character
    local sq = cursor.sq
    local validObject

    --rotateCursor(cursor)
    if cursor.nSprite > 2 then cursor.nSprite = 1 end
    if cursor.nSprite == 1 then
        cursor.sprite = cursor.westSprite
        cursor.west = true
        cursor.north = false
    else
        cursor.sprite = cursor.northSprite
        cursor.west = false
        cursor.north = true
    end

    for i = 0, sq:getObjects():size() - 1 do
        local object = sq:getObjects():get(i)
        if (instanceof(object, "IsoThumpable") or instanceof(object, "IsoWindow") or instanceof(object, "IsoDoor")) and cursor.north == object:getNorth() and object:isBarricadeAllowed() then
            --thump and not object:haveSheetRope()
            local barricade = object:getBarricadeForCharacter(player)
            if not barricade or barricade:canAddPlank() then
                validObject = object
                break
            end
        end
    end

    if not validObject then return end
    if player:getInventory():containsTagEvalRecurse("Hammer", predicateNotBroken) and player:getInventory():containsTypeRecurse("Plank") and player:getInventory():getItemCountRecurse("Base.Nails") >= 2 or ISBuildMenu.cheat then
        cursor.item = validObject
        return true
    end
    return false
end
