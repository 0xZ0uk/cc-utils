-- Load all modules
local config = require("config")
local slots = require("inventory").slots
local ui = require("ui")
local mining = require("mining")

local function main(...)
    local args = {...}
    local cfg = config.processConfig()
    slots.assignSlots(cfg)
    local default = args[1] == "def"

    if cfg.mineLoop then
        mining.launchMineLoop(cfg, default)
        return
    end

    mining.launchDigging(cfg, default)
end

main(...)
