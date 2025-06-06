local utils = {}

-- Constants
utils.DIRECTIONS = {
    SOUTH = 0,
    WEST = 1,
    NORTH = 2,
    EAST = 3
}
utils.SLOTS = {
    CHEST_SLOT = "chest_slot",
    BLOCK_SLOT = "block_slot",
    FUEL_SLOT = "fuel_slot",
    FUEL_CHEST_SLOT = "fuel_chest_slot",
    CHUNK_LOADER_SLOT = "chunk_loader_slot",
    MISC_SLOT = "misc_slot"
}
utils.PATHFIND_TYPES = {
    INSIDE_AREA = 0,
    OUTSIDE_AREA = 1,
    INSIDE_NONPRESERVED_AREA = 2,
    ANYWHERE_NONPRESERVED = 3
}
utils.VALIDATION_RESULTS = {
    SUCCESS = 0,
    FAILED_NONONE_COMPONENTCOUNT = 1,
    FAILED_TURTLE_NOTINREGION = 2,
    FAILED_REGION_EMPTY = 4
}

utils.CONSTANTS = {
    REFUEL_THRESHOLD = 500,
    RETRY_DELAY = 3,
    FALLING_BLOCKS = {
        ["minecraft:gravel"] = true,
        ["minecraft:sand"] = true
    }
}

-- Helper functions
utils.deltaToDirection = function(dX, dZ)
    if dX > 0 then
        return utils.DIRECTIONS.EAST
    elseif dX < 0 then
        return utils.DIRECTIONS.WEST
    elseif dZ > 0 then
        return utils.DIRECTIONS.SOUTH
    elseif dZ < 0 then
        return utils.DIRECTIONS.NORTH
    end
    error("Invalid delta", 2)
end

utils.tableLength = function(T)
    local count = 0
    for _ in pairs(T) do
        count = count + 1
    end
    return count
end

utils.getIndex = function(x, y, z)
    return tostring(x) .. "," .. tostring(y) .. "," .. tostring(z)
end

utils.isPosEqual = function(pos1, pos2)
    return pos1.x == pos2.x and pos1.y == pos2.y and pos1.z == pos2.z
end

utils.distance = function(from, to)
    return math.abs(from.x - to.x) + math.abs(from.y - to.y) + math.abs(from.z - to.z)
end

-- Add all other helper functions...

utils.printError = function(...)
    term.setTextColor(colors.red)
    print(...)
end

utils.printWarning = function(...)
    term.setTextColor(colors.yellow)
    print(...)
end

utils.print = function(...)
    term.setTextColor(colors.white)
    print(...)
end

utils.readOnlyTable = function(t)
    local mt = {
        __index = t,
        __newindex = function(_, _, _)
            error("Cannot write into a read-only table", 2)
        end
    }
    local proxy = {}
    setmetatable(proxy, mt)
    return proxy
end

utils.shouldKeepBlock = function(blockName, config)
    if blockName == "minecraft:cobblestone" or blockName == "minecraft:coal" then
        return true
    end
    if #config.keepBlocks == 0 then
        return true
    end
    for _, keepBlock in ipairs(config.keepBlocks) do
        if blockName == keepBlock then
            return true
        end
    end
    return false
end

return utils
