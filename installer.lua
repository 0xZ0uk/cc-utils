local baseUrl = "https://raw.githubusercontent.com/0xZ0uk/cc-utils/main/"

local files = {
    -- General utils
    {"utils/helpers.lua", "utils/helpers.lua"},
    {"utils/ui.lua", "utils/ui.lua"},
    {"utils/config.lua", "utils/config.lua"},
    {"utils/pathfinding.lua", "utils/pathfinding.lua"},
    
    -- Turtle utils
    {"turtles/utils/wrapper.lua", "turtles/utils/wrapper.lua"},
    {"turtles/utils/movement.lua", "turtles/utils/movement.lua"},
    {"turtles/utils/inventory.lua", "turtles/utils/inventory.lua"},
    
    -- Miner files
    {"turtles/miner/main.lua", "turtles/miner/main.lua"},
    {"turtles/miner/config.lua", "turtles/miner/config.lua"},
    {"turtles/miner/shapes.lua", "turtles/miner/shapes.lua"},
    {"turtles/miner/region.lua", "turtles/miner/region.lua"},
    {"turtles/miner/mining.lua", "turtles/miner/mining.lua"},
    {"turtles/miner/inventory.lua", "turtles/miner/inventory.lua"},
    {"turtles/miner/ui.lua", "turtles/miner/ui.lua"}
}

print("Installing Advanced Miner...")

-- Create directories
local dirs = {"utils", "turtles", "turtles/utils", "turtles/miner"}
for _, dir in ipairs(dirs) do
    if not fs.exists(dir) then
        fs.makeDir(dir)
        print("Created directory:", dir)
    end
end

-- Download files
for _, file in ipairs(files) do
    local url = baseUrl .. file[1]
    local path = file[2]
    
    print("Downloading:", path)
    local success, err = pcall(function()
        shell.run("wget", url, path)
    end)
    
    if not success then
        print("Failed to download:", path, err)
        return
    end
end

print("Installation complete!")
print("Usage: turtles/miner/main")