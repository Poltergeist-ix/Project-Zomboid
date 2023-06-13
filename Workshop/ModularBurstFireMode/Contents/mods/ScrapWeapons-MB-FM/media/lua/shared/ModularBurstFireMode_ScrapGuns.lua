for _,each in ipairs({
    { type = "SGuns.SSMGUnfolded", Speed = 6, Shots = 4 },
    { type = "SGuns.SSMGFolded", Speed = 6, Shots = 4 },
    { type = "SGuns.SAR", Speed = 6, Shots = 3 },
    { type = "SGuns.SARB", Speed = 6, Shots = 3 },
    { type = "SGuns.ScrapSMG", Speed = 4.4, Shots = 3 },
    { type = "SGuns.ScrapGatling", Speed = 10, Shots = 10, Delay = 30 },
}) do
    local Item = getScriptManager():getItem(each.type)
    local InvItem = Item ~= nil and InventoryItemFactory.CreateItem(each.type)
    if InvItem ~= nil then
        local list = InvItem:getFireModePossibilities()
        local t = {}
        if list ~= nil then
            for i = 0, list:size() do
                table.insert(t,list:get(i))
            end
        else
            table.insert(t,InvItem:getFireMode())
        end
        table.insert(t,"modBurst")
        Item:DoParam("fireModePossibilities="..table.concat(t,"/"))
        Item:DoParam("modBurst_Shots="..each.Shots)
        Item:DoParam("modBurst_Speed="..each.Speed)
        if each.Delay then Item:DoParam("modBurst_Delay="..each.Delay) end
    end
end