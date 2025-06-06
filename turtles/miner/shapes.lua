local helpers = require("/utils/helpers")
local ui = require("/utils/ui")

local shapes = {}

shapes.custom = {
    command = "custom",
    shortDesc = "custom <filename>",
    longDesc = "Executes a function named \"generate\" from the specified file and uses the data it returns as a shape",
    args = {"str"},
    generate = function(filename)
        local env = {
            table = table,
            fs = fs,
            http = http,
            io = io,
            math = math,
            os = os,
            parallel = parallel,
            string = string,
            vector = vector,
            textutils = textutils
        }
        local chunk, err = loadfile(filename, "bt", env)
        if err then
            ui.printError("Couldn't load file:", err)
            return {}
        end
        chunk()
        if type(env.generate) ~= "function" then
            ui.printError("File does not contain generate function")
            return {}
        end
        local generated = env.generate()
        if type(generated) ~= "table" then
            ui.printError("Generate function didn't return a table")
            return {}
        end
        local blocks = {}
        for _, value in ipairs(generated) do
            if type(value.x) ~= "number" or type(value.y) ~= "number" or type(value.z) ~= "number" then
                ui.printError("Invalid coordinates entry:", textutils.serialize(value))
                return {}
            end
            blocks[helpers.getIndex3D(value.x, value.y, value.z)] = {x = value.x, y = value.y, z = value.z}
        end
        return blocks
    end
}

shapes.sphere = {
    command = "sphere",
    shortDesc = "sphere <diameter>",
    longDesc = "Mine a sphere of diameter <diameter>, starting from it's bottom center",
    args = {"2.."},
    generate = function(diameter)
        local radius = math.ceil(diameter / 2.0)
        local radiusSq = (diameter / 2.0) * (diameter / 2.0)
        local blocks = {}
        local first = nil
        for j = -radius, radius do
            for i = -radius, radius do
                for k = -radius, radius do
                    if diameter % 2 == 0 then
                        if math.pow(i + 0.5, 2) + math.pow(j + 0.5, 2) + math.pow(k + 0.5, 2) < radiusSq then
                            if not first then
                                first = j
                            end
                            blocks[helpers.getIndex3D(i, j - first, k)] = {x = i, y = j - first, z = k}
                        end
                    else
                        if math.pow(i, 2) + math.pow(j, 2) + math.pow(k, 2) < radiusSq then
                            if not first then
                                first = j
                            end
                            blocks[helpers.getIndex3D(i, j - first, k)] = {x = i, y = j - first, z = k}
                        end
                    end
                end
            end
            helpers.osYield()
        end
        return blocks
    end
}

shapes.cuboid = {
    command = "cube",
    shortDesc = "cube <left> <up> <forward>",
    longDesc = "Mine a cuboid of a specified size. Use negative values to dig in an opposite direction",
    args = {"..-2 2..", "..-2 2..", "..-2 2.."},
    generate = function(x, y, z)
        local blocks = {}
        local sX = helpers.sign(x)
        local sY = helpers.sign(y)
        local sZ = helpers.sign(z)
        local tX = sX * (math.abs(x) - 1)
        local tY = sY * (math.abs(y) - 1)
        local tZ = sZ * (math.abs(z) - 1)
        for i = 0, tX, sX do
            for j = 0, tY, sY do
                for k = 0, tZ, sZ do
                    blocks[helpers.getIndex3D(i, j, k)] = {x = i, y = j, z = k}
                end
            end
            helpers.osYield()
        end
        return blocks
    end
}

shapes.centeredCuboid = {
    command = "rcube",
    shortDesc = "rcube <leftR> <upR> <forwardR>",
    longDesc = "Mine a cuboid centered on the turtle. Each dimension is a \"radius\", so typing \"rcube 1 1 1\" will yield a 3x3x3 cube",
    args = {"1..", "1..", "1.."},
    generate = function(rX, rY, rZ)
        local blocks = {}
        for i = -rX, rX do
            for j = -rY, rY do
                for k = -rZ, rZ do
                    blocks[helpers.getIndex3D(i, j, k)] = {x = i, y = j, z = k}
                end
            end
            helpers.osYield()
        end
        return blocks
    end
}

shapes.branch = {
    command = "branch",
    shortDesc = "branch <branchLen> <shaftLen>",
    longDesc = "Branch-mining. <branchLen> is the length of each branch, <shaftLen> is the length of the main shaft",
    args = {"0..", "3.."},
    generate = function(xRadius, zDepth)
        local blocks = {}
        -- generate corridor
        for x = -1, 1 do
            for y = 0, 2 do
                for z = 0, zDepth - 1 do
                    blocks[helpers.getIndex3D(x, y, z)] = {x = x, y = y, z = z}
                end
            end
        end
        -- generate branches
        for z = 2, zDepth - 1, 2 do
            local y = (z % 4 == 2) and 0 or 2
            for x = 0, xRadius - 1 do
                blocks[helpers.getIndex3D(x + 2, y, z)] = {x = x + 2, y = y, z = z}
                blocks[helpers.getIndex3D(-x - 2, y, z)] = {x = -x - 2, y = y, z = z}
            end
        end
        return blocks
    end
}

return shapes