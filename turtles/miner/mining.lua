local utils = require("utils")
local wrapt = require("turtle-wrapper")
local inventory = require("inventory")
local region = require("region")
local ui = require("ui")

local mining = {}

mining.launchDigging = function(config, default)
    local diggingArea = ui.getValidatedRegion(config, default)
    local layers = region.createLayersFromArea(diggingArea, config.layerSeparationAxis)
    local chestData = region.reserveChests(diggingArea)
    mining.executeDigging(layers, diggingArea, chestData, config)
end

mining.executeDigging = function(layers, diggingArea, chestData, config)
    -- Implementation moved from main script
end

-- Add other mining functions...

return mining
