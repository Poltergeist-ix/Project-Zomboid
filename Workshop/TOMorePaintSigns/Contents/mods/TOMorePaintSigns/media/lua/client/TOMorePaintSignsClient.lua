--[[
    Add more "paintSign" patterns for wall
    Author Poltergeist
--]]

local Paint = {}
Paint.textureCache = {}

--- ordered table with paint options
--- W/N sprites are alternating in the pack
--- to add translations for options set group.optionsTranslated to true
Paint.optionMenus = {
    [1] = {
        name = "IGUI_TOMorePaintOptions_patA",
        tileset = "topaintsigns_01_",
        min = 0,
        max = 47,
        needFullWall = true,
    },
    [2] = {
        name = "IGUI_TOMorePaintOptions_patB",
        tileset = "topaintsigns_02_",
        min = 0,
        max = 33,
        needFullWall = true,
    },
}

Paint.partialWalls = {
    constructedobjects_signs_01_11 = true,
    constructedobjects_signs_01_27 = true,
}

--- hook to add options
function Paint.patchAddSignOption(addSignOption)
    return function(...)
        addSignOption(...)
        local args = {...}
        args.player = ISPaintMenu.player
        local context = args[1]
        local topSubMenu = context:getSubMenu(context.options[#context.options].subOption)
        local ToolTip = Paint.ToolTip:new()
        ToolTip.offset = 5
        ToolTip.tex = { r=args[5],g=args[6],b=args[7],a=1 }
        for _,group in ipairs(Paint.optionMenus) do
            local subMenu = topSubMenu:getNew(topSubMenu)
            topSubMenu:addSubMenu(topSubMenu:addOption(getText(group.name)), subMenu)
            for i = group.min, group.max, 2 do
                local text = group.optionsTranslated and getText(group.name.."_"..tostring(i)) or tostring(i/2)
                local option = subMenu:addOption(text,args,Paint.OnPaintSign,group,i)
                option.toolTip = ToolTip
            end
        end
    end
end

function Paint.OnPaintSign(args,group,selected)
    getCell():setDrag(Paint.Cursor:new(args,group,selected), args.player)
end

do
    require "ISUI/ISToolTip"
    local ToolTip = ISToolTip:derive("TOMorePaintSignsTooltip")

    function ToolTip:prerender()
        local texture
        local opt = self.contextMenu.options[(self.contextMenu or {}).mouseOver]
        if opt ~= nil then
            local tileset = opt.param1.tileset
            texture = (Paint.textureCache[tileset] or {})[opt.param2]
            if not texture then
                texture = getTexture(tileset..tostring(opt.param2))
                Paint.textureCache[tileset]  = Paint.textureCache[tileset] or {}
                Paint.textureCache[opt.param2]  = texture
            end
        end
        if texture ~= self.tex.texture then
            local width, height
            if not texture then
                width, height = 50, 50
            else
                height = texture:getHeight()
                width = texture:getWidth()
            end
            self.tex.texture = texture
            self.tex.height = height
            self.tex.width = width
            self:setHeight(height+self.offset*2)
            self:setWidth(width+self.offset*2)
        end
        self:drawRect(0, 0, self.width, self.height, self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b)
    end

    function ToolTip:render()
        ISToolTip.render(self)

        if self.tex.texture ~= nil then
            self:drawTextureScaled(self.tex.texture, self.offset, self.offset, self.tex.width, self.tex.height, self.tex.a, self.tex.r, self.tex.g, self.tex.b)
        end
    end

    Paint.ToolTip = ToolTip
end

do
    require "BuildingObjects/TimedActions/ISPaintSignAction"
    local Action = ISPaintSignAction:derive("TOMorePaintSignsAction")

    function Action:perform()
        if self.sound then self.character:stopOrTriggerSound(self.sound) end
        self.wall:setOverlaySprite(self.sprite,self.r,self.g,self.b,1)
        if not ISBuildMenu.cheat then
            self.paintPot:Use()
        end
        -- needed to remove from queue / start next.
        ISBaseTimedAction.perform(self)
    end

    Paint.Action = Action
end

--- patch and create the modified "server" classes
function Paint.OnGameStart()

    --- require "BuildingObjects/ISUI/ISPaintMenu"
    ISPaintMenu.addSignOption = Paint.patchAddSignOption(ISPaintMenu.addSignOption)

    --- require BuildingObjects\ISPaintCursor
    local Cursor = ISPaintCursor:derive("TOMorePaintSignsCursor")
    
    Cursor.renderColor = {
        PaintBlack 		= {r=0.20,g=0.20,b=0.20},
        PaintBlue  		= {r=0.35,g=0.35,b=0.80},
        PaintBrown 		= {r=0.45,g=0.23,b=0.11},
        PaintCyan  		= {r=0.50,g=0.80,b=0.80},
        PaintGreen 		= {r=0.41,g=0.80,b=0.41},
        PaintGrey  		= {r=0.50,g=0.50,b=0.50},
        PaintLightBlue  = {r=0.55,g=0.55,b=0.87},
        PaintLightBrown = {r=0.59,g=0.44,b=0.21},
        PaintOrange		= {r=0.79,g=0.44,b=0.19},
        PaintPink  		= {r=0.81,g=0.60,b=0.60},
        PaintPurple		= {r=0.61,g=0.40,b=0.63},
        PaintRed   		= {r=0.63,g=0.10,b=0.10},
        PaintTurquoise  = {r=0.49,g=0.70,b=0.80},
        PaintWhite 		= {r=0.92,g=0.92,b=0.92},
        PaintYellow 	= {r=0.84,g=0.78,b=0.30},
    }

    function Cursor:new(args, group, selected)
        local o = ISPaintCursor.new(self, getSpecificPlayer(args.player), "paintSign", { paintType = args[4], sign = selected, r=args[5], g=args[6], b=args[7] })
        o.wSprite = group.tileset..tostring(selected)
        o.nSprite = group.tileset..tostring(selected+1)
        o.needFullWall = group.needFullWall
        return o
    end

    function Cursor:render(x, y, z, square) --rip
        if not self.floorSprite then
            self.floorSprite = IsoSprite.new()
            self.floorSprite:LoadFramesNoDirPageSimple('media/ui/FloorTileCursor.png')
        end

        local hc = getCore():getGoodHighlitedColor()
        if not self:isValid(square) then
            hc = getCore():getBadHighlitedColor()
        end
        self.floorSprite:RenderGhostTileColor(x, y, z, hc:getR(), hc:getG(), hc:getB(), 0.8)

        if self.currentSquare ~= square then
            self.objectIndex = 1
            self.currentSquare = square
        end

        self.renderX = x
        self.renderY = y
        self.renderZ = z

        local objects = self:getObjectList()
        if self.objectIndex >= 1 and self.objectIndex <= #objects then
            local object = objects[self.objectIndex]
            local color = {r=0.8, g=0.8, b=0.8}
            color = Cursor.renderColor[self.args.paintType]
            if not color then color = {r=1,g=0,b=0} end
            if self.action == "paintSign" then
                if object:getProperties():Is("WallW") then
                    self.sprite = self.wSprite
                else
                    self.sprite = self.nSprite
                end
                self.signSprite = self.signSprite or IsoSprite.new()
                self.signSprite:LoadFramesNoDirPageSimple(self.sprite)
                self.signSprite:RenderGhostTileColor(x, y, z, color.r, color.g, color.b, 1.0)
            end
        end
    end

    function Cursor:canPaint(object)
        return ISPaintCursor.canPaint(self,object) and (not self.needFullWall or not Paint.partialWalls[object:getTextureName()])
    end
    
    function Cursor:create(x, y, z, north, sprite)
        local playerObj = self.character
        local playerInv = playerObj:getInventory()
        local object = self:getObjectList()[self.objectIndex]
        local args = self.args
        local paintCan = nil
        if not ISBuildMenu.cheat then
            local paintBrush = playerInv:getFirstTypeRecurse("Paintbrush")
            ISWorldObjectContextMenu.transferIfNeeded(playerObj, paintBrush)
            paintCan = playerInv:getFirstTypeRecurse(args.paintType)
            ISWorldObjectContextMenu.transferIfNeeded(playerObj, paintCan)
        end
        local action = Paint.Action:new(playerObj, object, paintCan, args.sign, args.r, args.g, args.b, 100)
        action.sprite = self.sprite
        ISTimedActionQueue.add(action)
    end

    Paint.Cursor = Cursor
end

Events.OnGameStart.Add(Paint.OnGameStart)

return Paint