local helpers = require("/utils/helpers")

local region = {}

-- Constants
region.VALIDATION_RESULTS = {
    SUCCESS = 0,
    FAILED_NONONE_COMPONENTCOUNT = 1,
    FAILED_TURTLE_NOTINREGION = 2,
    FAILED_REGION_EMPTY = 4
}

region.cloneBlocks = function(allBlocks)
    local cloned = {}
    for key, value in pairs(allBlocks) do
        local blockClone = {
            x = value.x,
            y = value.y,
            z = value.z
        }
        cloned[key] = blockClone
    end
    return cloned
end

-- mark blocks that are next to walls
region.markAdjacentInPlace = function(allBlocks)
    for key, value in pairs(allBlocks) do
        local xMinus = allBlocks[helpers.getIndex3D(value.x - 1, value.y, value.z)]
        local xPlus = allBlocks[helpers.getIndex3D(value.x + 1, value.y, value.z)]
        local yMinus = allBlocks[helpers.getIndex3D(value.x, value.y - 1, value.z)]
        local yPlus = allBlocks[helpers.getIndex3D(value.x, value.y + 1, value.z)]
        local zMinus = allBlocks[helpers.getIndex3D(value.x, value.y, value.z - 1)]
        local zPlus = allBlocks[helpers.getIndex3D(value.x, value.y, value.z + 1)]
        if not xMinus or not xPlus or not yMinus or not yPlus or not zMinus or not zPlus then
            value.adjacent = true
            if yMinus then
                yMinus.checkedInFirstPass = true
            end
            if yPlus then
                yPlus.checkedInFirstPass = true
            end
        end
    end
end

-- mark positions where the turtle can check both the block above and the block below
region.markTripleInPlace = function(allBlocks)
    local minY = 9999999
    for key, value in pairs(allBlocks) do
        if not value.checkedInFirstPass and not value.adjacent then
            minY = math.min(minY, value.y)
        end
    end
    for key, value in pairs(allBlocks) do
        if not value.checkedInFirstPass and not value.adjacent then
            local offset = (value.y - minY) % 3
            if offset == 0 then
                local blockAbove = allBlocks[helpers.getIndex3D(value.x, value.y + 1, value.z)]
                if blockAbove ~= nil and blockAbove.checkedInFirstPass ~= true then
                    value.checkedInFirstPass = true
                else
                    value.inacc = true
                end
            elseif offset == 1 then
                value.triple = true
            elseif offset == 2 and allBlocks[helpers.getIndex3D(value.x, value.y - 1, value.z)] ~= nil then
                local blockBelow = allBlocks[helpers.getIndex3D(value.x, value.y - 1, value.z)]
                if blockBelow ~= nil and blockBelow.checkedInFirstPass ~= true then
                    value.checkedInFirstPass = true
                else
                    value.inacc = true
                end
            end
        end
    end
end

region.findConnectedComponents = function(allBlocks)
    local visited = {}
    local components = {}
    local counter = 0
    local lastTime = os.clock()
    for key, value in pairs(allBlocks) do
        if not visited[key] then
            local component = {}
            local toVisit = {[key] = value}
            while true do
                local newToVisit = {}
                local didSomething = false
                for currentKey, current in pairs(toVisit) do
                    didSomething = true
                    visited[currentKey] = true
                    component[currentKey] = current
                    local minusX = helpers.getIndex3D(current.x - 1, current.y, current.z)
                    local plusX = helpers.getIndex3D(current.x + 1, current.y, current.z)
                    local minusY = helpers.getIndex3D(current.x, current.y - 1, current.z)
                    local plusY = helpers.getIndex3D(current.x, current.y + 1, current.z)
                    local minusZ = helpers.getIndex3D(current.x, current.y, current.z - 1)
                    local plusZ = helpers.getIndex3D(current.x, current.y, current.z + 1)
                    if allBlocks[minusX] and not visited[minusX] then
                        newToVisit[minusX] = allBlocks[minusX]
                    end
                    if allBlocks[plusX] and not visited[plusX] then
                        newToVisit[plusX] = allBlocks[plusX]
                    end
                    if allBlocks[minusY] and not visited[minusY] then
                        newToVisit[minusY] = allBlocks[minusY]
                    end
                    if allBlocks[plusY] and not visited[plusY] then
                        newToVisit[plusY] = allBlocks[plusY]
                    end
                    if allBlocks[minusZ] and not visited[minusZ] then
                        newToVisit[minusZ] = allBlocks[minusZ]
                    end
                    if allBlocks[plusZ] and not visited[plusZ] then
                        newToVisit[plusZ] = allBlocks[plusZ]
                    end
                    counter = counter + 1
                    if counter % 50 == 0 then
                        local curTime = os.clock()
                        if curTime - lastTime > 1 then
                            lastTime = curTime
                            helpers.osYield()
                        end
                    end
                end
                toVisit = newToVisit
                if not didSomething then
                    break
                end
            end
            table.insert(components, component)
        end
    end
    return components
end

region.separateLayers = function(allBlocks, direction)
    if direction ~= "y" and direction ~= "z" then
        error("Invalid direction value", 2)
    end
    local layers = {}
    local min = 999999
    local max = -999999
    for key, value in pairs(allBlocks) do
        if not (not value.adjacent and value.checkedInFirstPass) then
            local index = direction == "y" and value.y or value.z
            if not layers[index] then
                layers[index] = {}
            end
            layers[index][key] = value
            min = math.min(min, index)
            max = math.max(max, index)
        end
    end
    if min == 999999 then
        error("There should be at least one block in passed table", 2)
    end
    local reassLayers = {}
    for key, value in pairs(layers) do
        local index = direction == "y" and (max - min + 1) - (key - min) or (key - min + 1)
        reassLayers[index] = value
    end
    return reassLayers
end

region.sortFunction = function(a, b)
    return (a.y ~= b.y and a.y < b.y or (a.x ~= b.x and a.x > b.x or a.z > b.z))
end

region.findClosestPoint = function(location, points, usedPoints)
    local surroundings = helpers.getSurroundings3D(location)
    local existingSurroundings = {}
    local foundClose = false
    for key, value in pairs(surroundings) do
        if points[key] and not usedPoints[key] then
            table.insert(existingSurroundings, value)
            foundClose = true
        end
    end
    if foundClose then
        table.sort(existingSurroundings, region.sortFunction)
        local closest = table.remove(existingSurroundings)
        return points[helpers.getIndex3D(closest.x, closest.y, closest.z)]
    end
    local minDist = 999999
    local minValue = nil
    for key, value in pairs(points) do
        if not usedPoints[key] then
            local dist = helpers.distance3D(value, location)
            if dist < minDist then
                minDist = dist
                minValue = value
            end
        end
    end
    if not minValue then
        return nil
    end
    return minValue
end

-- travelling salesman, nearest neighbour method
region.findOptimalBlockOrder = function(layers)
    local newLayers = {}
    local lastTime = os.clock()
    for index, layer in ipairs(layers) do
        local newLayer = {}
        local usedPoints = {}
        local current = region.findClosestPoint({x = 0, y = 0, z = 0}, layer, usedPoints)
        repeat
            usedPoints[helpers.getIndex3D(current.x, current.y, current.z)] = true
            table.insert(newLayer, current)
            current = region.findClosestPoint(current, layer, usedPoints)
            local curTime = os.clock()
            if curTime - lastTime > 1 then
                lastTime = curTime
                helpers.osYield()
            end
        until not current
        newLayers[index] = newLayer
    end
    return newLayers
end

region.createLayersFromArea = function(diggingArea, direction)
    local blocksToProcess = region.cloneBlocks(diggingArea)
    region.markAdjacentInPlace(blocksToProcess)
    region.markTripleInPlace(blocksToProcess)
    local layers = region.separateLayers(blocksToProcess, direction)
    local orderedLayers = region.findOptimalBlockOrder(layers)
    return orderedLayers
end

region.shiftRegion = function(shape, delta)
    local newShape = {}
    for key, value in pairs(shape) do
        local newPos = {x = value.x + delta.x, y = value.y + delta.y, z = value.z + delta.z}
        newShape[helpers.getIndex3D(newPos.x, newPos.y, newPos.z)] = newPos
    end
    return newShape
end

region.reserveChests = function(blocks)
    local blocksCopy = {}
    local counter = 0
    for _, value in pairs(blocks) do
        counter = counter + 1
        blocksCopy[counter] = value
    end
    table.sort(blocksCopy, function(a, b)
        if a.y ~= b.y then
            return a.y > b.y
        elseif a.z ~= b.z then
            return a.z > b.z
        else
            return a.x > b.x
        end
    end)
    return {reserved = blocksCopy}
end

region.validateRegion = function(blocks)
    local result = region.VALIDATION_RESULTS.SUCCESS
    -- there must be only one connected component
    local components = region.findConnectedComponents(blocks)
    if helpers.tableLength(components) == 0 then
        result = result + region.VALIDATION_RESULTS.FAILED_REGION_EMPTY
    end
    if helpers.tableLength(components) > 1 then
        result = result + region.VALIDATION_RESULTS.FAILED_NONONE_COMPONENTCOUNT
    end
    -- the turtle must be inside of the region
    if not blocks[helpers.getIndex3D(0, 0, 0)] then
        result = result + region.VALIDATION_RESULTS.FAILED_TURTLE_NOTINREGION
    end
    return result
end

return region