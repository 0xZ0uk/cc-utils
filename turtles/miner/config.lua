local utils = require("utils")

local cfg = {}

cfg.localConfig = {
    keepBlocks = {},
    useRemoteConfig = false,
    remoteConfigPath = "http://localhost:33344/config.lua",
    defaultCommand = "cube 3 3 8",
    plugFluidsOnly = true,
    oreTraversalRadius = 0,
    layerSeparationAxis = "y",
    useEntangledChests = false,
    useFuelEntangledChest = false,
    mineLoop = false,
    mineLoopOffset = {
        x = 0,
        y = 0,
        z = 8
    },
    mineLoopCommand = "rcube 1 1 1"
}

cfg.getRemoteConfig = function(remotePath)
    local handle = http.get(remotePath)
    if not handle then
        utils.printError("Server not responding, using local")
        return nil
    end
    local data = handle.readAll()
    handle.close()
    local deser = textutils.unserialise(data)
    if not deser then
        utils.printError("Couldn't parse remote config, using local")
        return nil
    end
    for key, _ in pairs(cfg.localConfig) do
        if deser[key] == nil then
            utils.printError("No key", key, "in remote config, using local")
            return nil
        end
    end
    return deser
end

cfg.processConfig = function()
    local config = cfg.localConfig
    if cfg.localConfig.useRemoteConfig then
        utils.print("Downloading config..")
        local remoteConfig = cfg.getRemoteConfig(config.remoteConfigPath)
        config = remoteConfig or cfg.localConfig
    end
    return utils.readOnlyTable(config)
end

return cfg
