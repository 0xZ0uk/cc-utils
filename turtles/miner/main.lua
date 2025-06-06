local config = require("/turtles/miner/config")
local inventory = require("/turtles/miner/inventory")
local ui = require("/turtles/miner/ui")
local mining = require("/turtles/miner/mining")

local function main(...)
    local args = {...}
    local cfg = config.processConfig()
    inventory.slots.assignSlots(cfg)
    local default = args[1] == "def"

    if cfg.mineLoop then
        mining.launchMineLoop(cfg, default)
        return
    end

    mining.launchDigging(cfg, default)
end

main(...)
