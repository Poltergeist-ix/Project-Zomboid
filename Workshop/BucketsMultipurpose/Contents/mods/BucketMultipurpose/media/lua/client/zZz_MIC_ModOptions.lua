if ModOptions then
    local options = require("BucketsMultipurpose")["ModOptions"]
    if options then
        if ModOptions.AddKeyBinding then
            if options.radialKey then ModOptions:AddKeyBinding("[UI]",options.radialKey) end
        end
        if ModOptions.getInstance then
            ModOptions:getInstance({
                mod_id = "MultipurposeItemConversions",
                mod_shortname = "Multipurpose",
                options_data = {
                    radialKeyDelay = {
                        "1","250","500","1000",
                        default = 2,
                        name = "UI_optionscreen_ModOptions_radialKeyDelay",
                        tooltip = "UI_optionscreen_ModOptions_radialKeyDelay_tooltip",
                        OnApply = function(obj,val) options.radialKey.delay = tonumber(obj[val]) end,
                    }
                }
            })
        end
    end
end
