--[[
--module for executing functions when specific world squares are loaded on server, based on TheIndieStone SGlobalObjectSystem
--made by poltergeist
--]]

if isClient() then return end
--if isClient() or API and API["WorldActionsAPI"] then return end

--local System = ISBaseObject:derive("WorldActionsAPI")
local System = { Type = "OnSquareLoadedCommands" }

--table with functions to call
System.onLoadCommands = {}
System.wantNoise = getDebug()

function System.OnSGlobalObjectSystemInit()
    -- Create the GlobalObjectSystem called NAME and load gos_NAME.bin if it exists. *name is the type here
    local system = SGlobalObjects.registerSystem(System.Type)
    --add saved system fields
    system:setModDataKeys({"savedData"})
    --add saved luaObject fields
    system:setObjectModDataKeys({"actions"})

    -- NOTE: The table for this Lua object is the same one the System
    -- Java object created.  The Java class calls some of this Lua object's methods.
    -- At this point, system:getModData() has already been read from disk if the
    -- gos_name.bin file existed.
    local o = system:getModData()
    setmetatable(o, System)
    System.__index = System
    o.system = system
    o.savedData = o.savedData or {}
    o:addPreInitActions()
    --o:initSystem()
    --o:initLuaObjects()
    o:noise('OnSGlobalObjectSystemInit, #objects='..system:getObjectCount())
    System.instance = o
    return o
end

--function System:initSystem()
--    self.system:setModDataKeys(self.savedModData)
--    self.system:setObjectModDataKeys(self.savedObjModData)
--end

function System:addPreInitActions()
    if not self.actionsPreInit then return end
    for i,v in ipairs(self.actionsPreInit) do
        self:addActionToGlobalObject(unpack(v))
    end
    self.actionsPreInit = nil
end

-- Java calls this method only when a chunk with GlobalObjects managed by this system is loaded.
function System:OnChunkLoaded(wx, wy)
    local globalObjects = self.system:getObjectsInChunk(wx, wy)
    self:noise("load chunk with #objects="..globalObjects:size())
    for i=0,globalObjects:size() - 1 do
        local globalObject = globalObjects:get(i)
        local square = getSquare(globalObject:getX(), globalObject:getY(), globalObject:getZ())
        local luaObject = globalObject:getModData()
        local repeatActions = {}

        for i,action in ipairs(luaObject.actions) do
            if self:doAction(square,action) == true then
                table.insert(repeatActions,action)
            end
        end

        if repeatActions[1] then
            luaObject.actions = repeatActions
        else
            self.system:removeObject(globalObject)
        end

    end
    -- This returns the ArrayList to a pool for reuse.
    self.system:finishedWithList(globalObjects)
end

function System:doAction(square,action)
    if not square and not action.squareCanBeNil then return nil end
    local f = type(action) == "table" and self.onLoadCommands[action.command] or self.onLoadCommands[action]
    if type(f) == "function" then
        return f(square,action)
    else
        return print(string.format("%s: bad action %s"),self.Type,type(action) == "table" and action.command or action)
    end
end

function System.isValidAction(action)
    if type(action) == "string" then return true end
    if type(action) == "table" and type(action.command) == "string" then return true end
    return System:noise("action not valid")
end

function System:addActionToGlobalObject(x,y,z,action)
    local globalObject = self.system:getObjectAt(x,y,z)
    if globalObject then
        table.insert(globalObject:getModData()["actions"],action)
    else
        globalObject = self.system:newObject(x,y,z)
        globalObject:getModData()["actions"] = {action}
    end
    self:noise(string.format("added action for square: %d,%d,%d",x,y,z))
end

function System.addActionPreInit(...)
    System.actionsPreInit = System.actionsPreInit or {}
    table.insert(System.actionsPreInit,{...})
end

function System.addAction(x,y,z,action)
    if System.isValidAction(action) then
        return System.instance and System.instance:addActionToGlobalObject(x,y,z,action) or System.addActionPreInit(x,y,z,action)
    end
end

function System:noise(message)
    if self.wantNoise then print(self.Type..': '..message) end
end

--called from java, return nil or a Lua table that is used to initialize the client-side system
function System:getInitialStateForClient() return nil end

--try to sync when file is reloaded
function System.instanceCheck()
    for i=0,SGlobalObjects.getSystemCount() - 1 do
        local system = SGlobalObjects.getSystemByIndex(i)
        if system:getModData().Type == self.Type then
            System.instance = system:getModData()
            setmetatable(System.instance, System)
            System.__index = System
            return
        end
    end
end

Events.OnSGlobalObjectSystemInit.Add(System.OnSGlobalObjectSystemInit)
System.instanceCheck()

--fixes for global object debugger -SP only
if not isServer() and getDebug() then
    function System:getIsoObjectAt() return nil end

    local DebugGlobalObjectStateUI_ObjectList_doDrawItem = DebugGlobalObjectStateUI.ObjectList_doDrawItem
    function DebugGlobalObjectStateUI:ObjectList_doDrawItem(y, item, alt)
        if item.item.system:getName() == System.Type then
            local x = 4

            if self.selected == item.index then
                self:drawRect(0, y, self:getWidth(), item.height-1, 0.3, 0.7, 0.35, 0.15)
            end

            local r,g,b,a = 1,1,1,1
            --local data = item.item
            --local globalObject = data.system:getObjectAt(data.x, data.y, data.z)
            --if not globalObject then
            --    r,g,b = 1.0,0.0,0.0
            --elseif not globalObject:getModData():getIsoObject() then
            --    r,g,b = 0.5,0.5,0.5
            --end

            self:drawText(item.text, x, y, r, g, b, a, self.font)
            y = y + self.fontHgt

            self:drawRect(x, y, self.width - 4 * 2, 1, 1.0, 0.5, 0.5, 0.5)
            y = y + 2

            return y
        else
            return DebugGlobalObjectStateUI_ObjectList_doDrawItem(self, y, item, alt)
        end
    end
end

--__modules = __modules or {}
--__modules[System.Type] = System
----API[System.Type] = System
return System

--[[
# Actions
    Action can be the name of the command to call or a table with command field as name of the command
    action.squareCanBeNil = true will trigger your action even if the square has no object
    Command function
        System.onLoadCommands["myCommand"] = function(square,action) print("Do Action at ",square) end
        if the function returns true the action will be repeated, you can edit the action table inside the function call

# example

local OnSquareLoadedCommands = require "OnSquareLoadedCommands"

local addSpawns = function()
    local instance = OnSquareLoadedCommands.instance

    instance.onLoadCommands.ISASpawn = function(square,action)
        ISAWorldSpawns.addToWorld(square,action.sprite)
    end

    if instance.savedData["isaWorldSpawns"] then return end

    instance.addAction(x,y,z,{ command = "ISASpawn", sprite = spriteName})

    instance.savedData["isaWorldSpawns"] = true
end

Events.OnSGlobalObjectSystemInit.Add(addSpawns)

# Persistence
System saves the savedData table and it can be used after OnSGlobalObjectSystemInit event, it can be used just like a global ModData table
Global Objects are saved and they save their actions table
only primary elements are saved within the tables

functions and other objects are not persistent and need to be set or generated again

]]