require "DryFishMod_util"
local DryFishMod = DryFishMod

--Advanced Fishing by Snake
if getActivatedMods():contains("LeGourmetRevolution") then
    --bait
    DryFishMod.excludeFishes["AdvancedFishing.Anguila"] = true
    DryFishMod.excludeFishes["AdvancedFishing.Crab"] = true
    DryFishMod.excludeFishes["AdvancedFishing.Dentudo"] = true
    DryFishMod.excludeFishes["AdvancedFishing.Palometa"] = true
    DryFishMod.excludeFishes["AdvancedFishing.Peje"] = true
    DryFishMod.excludeFishes["AdvancedFishing.Piranha"] = true
    --other
    DryFishMod.excludeFishes["AdvancedFishing.Piraiba"] = true
    DryFishMod.excludeFishes["AdvancedFishing.Rtcatfish"] = true
    DryFishMod.excludeFishes["AdvancedFishing.Ray"] = true
    --DryFishMod.excludeFishes["AdvancedFishing.FSalmon"] = true
    --DryFishMod.excludeFishes["AdvancedFishing.Tarpon"] = true
    DryFishMod.excludeFishes["AdvancedFishing.Surubi"] = true
    DryFishMod.excludeFishes["AdvancedFishing.Waterturtle"] = true
end