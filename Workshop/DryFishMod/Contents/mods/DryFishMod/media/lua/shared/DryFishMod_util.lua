DryFishMod = DryFishMod or {}

local DryFishMod = DryFishMod

--tile types used for AcceptFunction, globaObject
DryFishMod.tiles = {
    DryFishMod_1 = "Drier",
    DryFishMod_9 = "Drier",
    DryFishMod_8 = "Drier",
    DryFishMod_15 = "Skewer",
}

--used for context to place skewer, campfires object
DryFishMod.skewer = "DryFishMod_15"

--Not Ordered...
DryFishMod.driedOverlays = {
    DryFishMod_1 = "DryFishMod_5",
    DryFishMod_9 = "DryFishMod_13",
    DryFishMod_8 = "DryFishMod_2",
    DryFishMod_15 = "DryFishMod_7",
}

--list of fish to not use, temp
DryFishMod.excludeFishes = { ["Base.BaitFish"] = true }
