local helpers = require("/utils/helpers")

-- Turtle-specific direction constants
local DIRECTIONS = {
    SOUTH = 0,
    WEST = 1,
    NORTH = 2,
    EAST = 3
}

local function createTurtleWrapper()
    local self = {
        selectedSlot = 1,
        direction = DIRECTIONS.SOUTH,
        x = 0,
        y = 0,
        z = 0
    }

    local public = {}

    -- Copy all turtle functions
    for key, value in pairs(turtle) do
        public[key] = value
    end

    turtle.select(self.selectedSlot)

    public.select = function(slot)
        if self.selectedSlot ~= slot then
            turtle.select(slot)
            self.selectedSlot = slot
        end
    end

    public.forward = function()
        local success = turtle.forward()
        if not success then
            return success
        end

        if self.direction == DIRECTIONS.EAST then
            self.x = self.x + 1
        elseif self.direction == DIRECTIONS.WEST then
            self.x = self.x - 1
        elseif self.direction == DIRECTIONS.SOUTH then
            self.z = self.z + 1
        elseif self.direction == DIRECTIONS.NORTH then
            self.z = self.z - 1
        end
        return success
    end

    public.up = function()
        local success = turtle.up()
        if not success then
            return success
        end
        self.y = self.y + 1
        return success
    end

    public.down = function()
        local success = turtle.down()
        if not success then
            return success
        end
        self.y = self.y - 1
        return success
    end

    public.turnRight = function()
        local success = turtle.turnRight()
        if not success then
            return success
        end
        self.direction = (self.direction + 1) % 4
        return success
    end

    public.turnLeft = function()
        local success = turtle.turnLeft()
        if not success then
            return success
        end
        self.direction = (self.direction - 1) % 4
        if self.direction < 0 then
            self.direction = 3
        end
        return success
    end

    -- Position getters
    public.getX = function()
        return self.x
    end
    public.getY = function()
        return self.y
    end
    public.getZ = function()
        return self.z
    end
    public.getDirection = function()
        return self.direction
    end
    public.getPosition = function()
        return {
            x = self.x,
            y = self.y,
            z = self.z,
            direction = self.direction
        }
    end

    return public
end

-- Export direction constants along with wrapper
return {
    createWrapper = createTurtleWrapper,
    DIRECTIONS = DIRECTIONS
}
