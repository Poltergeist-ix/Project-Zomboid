# Lua load order (client / SP)
- shared, vanilla files
- shared, mod files
- client, vanilla files
- client, mod files
> Main Menu
- server, vanilla files
- server, mod files

# Lua load order (server)
- shared, vanilla files
- shared, mod files
- server, vanilla files
- server, mod files

> Files load in Unicode ~~ASCII~~ order.  
> Mod files overwriting vanilla files load with vanilla files.

# require
If you want a file from the same folder to load first, use `require "file"`. You can use it like this: `require "file"`, `require "file.lua"`, or `require("file")`.

Specify the file path. For example, to require `lua/server/BuildingObjects/ISBuildingObject.lua`, use `require "BuildingObjects/ISBuildingObject"`. There's no way to target a specific file between shared, client, server folders if they have the same path and name.

Require is also used with modules. You can require files after their folder has started loading. Requiring a server file from the shared folder needs an event like OnInitWorld or later. Recursive require is not allowed; two module files would fail to require each other.

# Module example
```lua
--- Module file, this file returns the module table.
--- Only the first returned variable is stored, the rest are discarded.
local Module = {}
-- ...
return Module
```
```lua
--- Another file, require function returns the module table of the module file.
local module = require ("file")
```
