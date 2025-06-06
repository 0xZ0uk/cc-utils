local helpers = require("/utils/helpers")

local movement = {}

movement.DIRECTIONS = {
    SOUTH = 0,
    WEST = 1,
    NORTH = 2,
    EAST = 3
}

movement.deltaToDirection = function(dX, dZ)
    if dX > 0 then
        return movement.DIRECTIONS.EAST
    elseif dX < 0 then
        return movement.DIRECTIONS.WEST
    elseif dZ > 0 then
        return movement.DIRECTIONS.SOUTH
    elseif dZ < 0 then
        return movement.DIRECTIONS.NORTH
    end
    error("Invalid delta", 2)
end

movement.getForwardPos = function(currentPos)
    local newPos = {
        x = currentPos.x,
        y = currentPos.y,
        z = currentPos.z
    }
    if currentPos.direction == movement.DIRECTIONS.EAST then
        newPos.x = newPos.x + 1
    elseif currentPos.direction == movement.DIRECTIONS.WEST then
        newPos.x = newPos.x - 1
    elseif currentPos.direction == movement.DIRECTIONS.SOUTH then
        newPos.z = newPos.z + 1
    elseif currentPos.direction == movement.DIRECTIONS.NORTH then
        newPos.z = newPos.z - 1
    end
    return newPos
end

movement.turnTowardsDirection = function(turtle, targetDir)
    local delta = (targetDir - turtle.getDirection()) % 4
    if delta == 1 then
        turtle.turnRight()
    elseif delta == 2 then
        turtle.turnRight()
        turtle.turnRight()
    elseif delta == 3 then
        turtle.turnLeft()
    end
    if targetDir ~= turtle.getDirection() then
        error("Could not turn to requested direction")
    end
end

return movement
