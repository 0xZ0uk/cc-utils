local ui = require("/utils/ui")

local config = {}

-- Generic config management that can be used by any ComputerCraft program
config.createConfigManager = function(localConfig)
    local manager = {}

    manager.getRemoteConfig = function(remotePath)
        local handle = http.get(remotePath)
        if not handle then
            ui.printError("Server not responding, using local config")
            return nil
        end

        local data = handle.readAll()
        handle.close()
        local deser = textutils.unserialise(data)

        if not deser then
            ui.printError("Couldn't parse remote config, using local")
            return nil
        end

        -- Validate all local keys exist in remote config
        for key, _ in pairs(localConfig) do
            if deser[key] == nil then
                ui.printError("No key", key, "in remote config, using local")
                return nil
            end
        end

        return deser
    end

    manager.processConfig = function()
        local config = localConfig
        if localConfig.useRemoteConfig then
            ui.print("Downloading config...")
            local remoteConfig = manager.getRemoteConfig(localConfig.remoteConfigPath)
            config = remoteConfig or localConfig
        end
        return config
    end

    return manager
end

return config
