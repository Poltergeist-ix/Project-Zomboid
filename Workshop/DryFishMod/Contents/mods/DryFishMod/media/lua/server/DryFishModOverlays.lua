local overlayMap = {}
overlayMap.VERSION = 1

overlayMap["DryFishMod_1"] = {{ name = "other", tiles = {"DryFishMod_3"} }}
overlayMap["DryFishMod_9"] = {{ name = "other", tiles = {"DryFishMod_11"} }}
overlayMap["DryFishMod_8"] = {{ name = "other", tiles = {"DryFishMod_12","DryFishMod_10"} }}
overlayMap["DryFishMod_15"] = {{ name = "other", tiles = {"DryFishMod_6"} }}

if not TILEZED then
    getContainerOverlays():addOverlays(overlayMap)
end

return overlayMap
