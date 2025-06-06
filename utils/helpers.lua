local helpers = {}

-- String utilities
helpers.splitString = function(string, separator)
    if not separator then
        separator = "%s"
    end
    local split = {}
    for str in string.gmatch(string, "([^" .. separator .. "]+)") do
        table.insert(split, str)
    end
    return split
end

helpers.stringEndsWith = function(str, ending)
    return ending == "" or str:sub(-#ending) == ending
end

-- Table utilities
helpers.tableLength = function(T)
    local count = 0
    for _ in pairs(T) do
        count = count + 1
    end
    return count
end

helpers.tableContains = function(table, element, comparison)
    for _, value in pairs(table) do
        if comparison(value, element) then
            return true
        end
    end
    return false
end

helpers.readOnlyTable = function(t)
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

-- Math utilities
helpers.sign = function(number)
    return number > 0 and 1 or (number == 0 and 0 or -1)
end

helpers.inRange = function(number, a, b)
    return number >= a and number <= b
end

helpers.distance3D = function(from, to)
    return math.abs(from.x - to.x) + math.abs(from.y - to.y) + math.abs(from.z - to.z)
end

-- System utilities
helpers.osYield = function()
    os.queueEvent("fakeEvent")
    os.pullEvent()
end

-- Position utilities
helpers.getIndex3D = function(x, y, z)
    return tostring(x) .. "," .. tostring(y) .. "," .. tostring(z)
end

helpers.isPosEqual3D = function(pos1, pos2)
    return pos1.x == pos2.x and pos1.y == pos2.y and pos1.z == pos2.z
end

helpers.getSurroundings3D = function(pos)
    return {
        [helpers.getIndex3D(pos.x + 1, pos.y, pos.z)] = {
            x = pos.x + 1,
            y = pos.y,
            z = pos.z
        },
        [helpers.getIndex3D(pos.x - 1, pos.y, pos.z)] = {
            x = pos.x - 1,
            y = pos.y,
            z = pos.z
        },
        [helpers.getIndex3D(pos.x, pos.y + 1, pos.z)] = {
            x = pos.x,
            y = pos.y + 1,
            z = pos.z
        },
        [helpers.getIndex3D(pos.x, pos.y - 1, pos.z)] = {
            x = pos.x,
            y = pos.y - 1,
            z = pos.z
        },
        [helpers.getIndex3D(pos.x, pos.y, pos.z + 1)] = {
            x = pos.x,
            y = pos.y,
            z = pos.z + 1
        },
        [helpers.getIndex3D(pos.x, pos.y, pos.z - 1)] = {
            x = pos.x,
            y = pos.y,
            z = pos.z - 1
        }
    }
end

return helpers
