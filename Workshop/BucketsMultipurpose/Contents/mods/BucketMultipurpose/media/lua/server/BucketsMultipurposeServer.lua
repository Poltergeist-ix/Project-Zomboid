require "recipecode"
function Recipe.OnTest.BucketTypeChange(item)
    return not instanceof(item, "InventoryContainer") or item:getInventory():getItems():isEmpty()
end
