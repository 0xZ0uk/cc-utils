local helpers = require("/utils/helpers")

local pathfinding = {}

-- Generic A* pathfinding that works with any 3D grid
pathfinding.createPathfinder = function()
    local pathfinder = {}

    local updateNeighbour = function(data, neighbour, destination, origin, neighbourIndex)
        local originIndex = helpers.getIndex3D(origin.x, origin.y, origin.z)
        if not data[neighbourIndex] then
            data[neighbourIndex] = {}
            data[neighbourIndex].startDist = data[originIndex].startDist + 1
            data[neighbourIndex].heuristicDist = helpers.distance3D(neighbour, destination)
            data[neighbourIndex].previous = origin
        elseif data[originIndex].startDist + 1 < data[neighbourIndex].startDist then
            data[neighbourIndex].startDist = data[originIndex].startDist + 1
            data[neighbourIndex].previous = origin
        end
    end

    pathfinder.findPath = function(from, to, traversableCheck)
        if helpers.isPosEqual3D(from, to) then
            return {
                length = 0
            }
        end

        local data = {}
        local openSet = {}
        local closedSet = {}
        local current = from
        local curIndex = helpers.getIndex3D(from.x, from.y, from.z)

        openSet[curIndex] = current
        data[curIndex] = {}
        data[curIndex].startDist = 0
        data[curIndex].heuristicDist = helpers.distance3D(current, to)

        while true do
            local surroundings = helpers.getSurroundings3D(current)
            for key, value in pairs(surroundings) do
                if traversableCheck(key) and not closedSet[key] then
                    updateNeighbour(data, value, to, current, key)
                    openSet[key] = value
                end
            end

            closedSet[curIndex] = current
            openSet[curIndex] = nil

            local minN = 9999999
            local minValue = nil
            for key, value in pairs(openSet) do
                local sum = data[key].startDist + data[key].heuristicDist
                if sum < minN then
                    minN = sum
                    minValue = value
                end
            end

            current = minValue
            if current == nil then
                return false -- No path found
            end

            curIndex = helpers.getIndex3D(current.x, current.y, current.z)
            if helpers.isPosEqual3D(current, to) then
                break
            end
        end

        -- Reconstruct path
        local almostFinalPath = {}
        local counter = 1
        while current ~= nil do
            almostFinalPath[counter] = current
            counter = counter + 1
            current = data[helpers.getIndex3D(current.x, current.y, current.z)].previous
        end

        local reversedPath = {}
        local newCounter = 1
        for i = counter - 1, 1, -1 do
            reversedPath[newCounter] = almostFinalPath[i]
            newCounter = newCounter + 1
        end

        reversedPath.length = newCounter - 1
        return reversedPath
    end

    return pathfinder
end

return pathfinding
