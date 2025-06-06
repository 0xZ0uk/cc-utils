local utils = require("utils")

local function createTurtleWrapper()
    local self = {
        selectedSlot = 1,
        direction = utils.DIRECTIONS.SOUTH,
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

    -- Override movement functions to track position
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

        if self.direction == utils.DIRECTIONS.EAST then
            self.x = self.x + 1
        elseif self.direction == utils.DIRECTIONS.WEST then
            self.x = self.x - 1
        elseif self.direction == utils.DIRECTIONS.SOUTH then
            self.z = self.z + 1
        elseif self.direction == utils.DIRECTIONS.NORTH then
            self.z = self.z - 1
        end
        return success
    end

    -- Add other overrides (up, down, turnRight, turnLeft)...

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

return createTurtleWrapper()
