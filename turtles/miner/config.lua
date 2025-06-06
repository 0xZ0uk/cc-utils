local configUtils = require("/utils/config")
local helpers = require("/utils/helpers")

local cfg = {}

cfg.localConfig = {
    keepBlocks = {},
    -- if true, the program will attempt to download and use the config from remoteConfigPath
    -- useful if you have many turtles and you don't want to change the config of each one manually
    useRemoteConfig = false,
    remoteConfigPath = "http://localhost:33344/config.lua",
    -- this command will be used when the program is started as "mine def" (mineLoop overrides this command)
    defaultCommand = "cube 3 3 8",
    -- false: build walls/floor/ceiling everywhere, true: only where there is fluid
    plugFluidsOnly = true,
    -- maximum taxicab distance from enterance point when collecting ores, 0 = disable ore traversal
    oreTraversalRadius = 0,
    -- layer mining order, use "z" for branch mining, "y" for anything else
    -- "y" - mine top to bottom layer by layer, "z" - mine forward in vertical slices
    layerSeparationAxis = "y",
    -- false: use regular chests, true: use entangled chests
    -- if true, the turtle will place a single entangled chest to drop off items and break it afterwards.
    -- tested with chests from https://www.curseforge.com/minecraft/mc-mods/kibe
    useEntangledChests = false,
    -- false: refuel from inventory, true: refuel from (a different) entangled chest
    -- if true, the turtle won't store any coal. Instead, when refueling, it will place the entangled chest, grab fuel from it, refuel, and then break the chest.
    useFuelEntangledChest = false,
    -- true: use two chuck loaders to mine indefinitely without moving into unloaded chunks.
    -- This doesn't work with chunk loaders from https://www.curseforge.com/minecraft/mc-mods/kibe, but might work with some other mod.
    -- After an area is mined, the turtle will shift by mineLoopOffset and execute mineLoopCommand
    -- mineLoopCommand is used in place of defaultCommand when launching as "mine def"
    mineLoop = false,
    mineLoopOffset = {x = 0, y = 0, z = 8},
    mineLoopCommand = "rcube 1 1 1"
}

local manager = configUtils.createConfigManager(cfg.localConfig)

cfg.processConfig = function()
    local config = manager.processConfig()
    return helpers.readOnlyTable(config)
end

return cfg