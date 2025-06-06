local utils = require("utils")

local shapes = {}

shapes.cuboid = {
    command = "cube",
    shortDesc = "cube <left> <up> <forward>",
    longDesc = "Mine a cuboid of a specified size",
    args = {"..-2 2..", "..-2 2..", "..-2 2.."},
    generate = function(x, y, z)
        local blocks = {}
        local sX = utils.sign(x)
        local sY = utils.sign(y)
        local sZ = utils.sign(z)
        local tX = sX * (math.abs(x) - 1)
        local tY = sY * (math.abs(y) - 1)
        local tZ = sZ * (math.abs(z) - 1)

        for i = 0, tX, sX do
            for j = 0, tY, sY do
                for k = 0, tZ, sZ do
                    blocks[utils.getIndex(i, j, k)] = {
                        x = i,
                        y = j,
                        z = k
                    }
                end
            end
            utils.osYield()
        end
        return blocks
    end
}

shapes.cylinder = {
    command = "cylinder",
    shortDesc = "cylinder <radius> <height>",
    longDesc = "Mine a cylinder of a specified size",
    args = {"..-2 2..", "..-2 2.."},
    generate = function(r, h)
        local radius = r
        local height = h
        local blocks = {}
        for x = -radius, radius do
            for z = -radius, radius do
                for y = 0, height do
                    if x * x + z * z < radius * radius then
                        table.insert(blocks, {
                            x = x,
                            y = y,
                            z = z
                        })
                    end
                end
            end
        end
        return blocks
    end

}

-- Add other shapes...

return shapes
