local helpers = require("/utils/helpers")

local ui = {}

-- Color management
ui.colors = {
    ERROR = colors.red,
    WARNING = colors.yellow,
    INFO = colors.white,
    INPUT = colors.lightGray
}

-- Output functions
ui.printError = function(...)
    term.setTextColor(ui.colors.ERROR)
    print(...)
    term.setTextColor(ui.colors.INFO)
end

ui.printWarning = function(...)
    term.setTextColor(ui.colors.WARNING)
    print(...)
    term.setTextColor(ui.colors.INFO)
end

ui.print = function(...)
    term.setTextColor(ui.colors.INFO)
    print(...)
end

ui.write = function(...)
    term.setTextColor(ui.colors.INFO)
    term.write(...)
end

ui.read = function()
    term.setTextColor(ui.colors.INPUT)
    local data = read()
    term.setTextColor(ui.colors.INFO)
    return data
end

-- Generic input validation
ui.testRange = function(range, value)
    if range == "str" then
        return "string"
    end
    if type(value) ~= "number" then
        return false
    end

    local subRanges = helpers.splitString(range, " ")
    for _, subRange in ipairs(subRanges) do
        local borders = helpers.splitString(subRange, "..")
        local tableLength = helpers.tableLength(borders)
        if tableLength == 2 then
            local left = tonumber(borders[1])
            local right = tonumber(borders[2])
            if helpers.inRange(value, left, right) then
                return true
            end
        elseif tableLength == 1 then
            local isLeft = string.sub(subRange, 0, 1) ~= "."
            local border = tonumber(borders[1])
            local good = isLeft and (value >= border) or not isLeft and (value <= border)
            if good then
                return true
            end
        end
    end
    return false
end

ui.parseArgs = function(argPattern, args)
    if helpers.tableLength(argPattern) ~= helpers.tableLength(args) then
        return nil
    end

    local parsed = {}
    for _, value in ipairs(args) do
        local number = tonumber(value)
        if not number then
            table.insert(parsed, value)
        end
        table.insert(parsed, number)
    end

    for index, value in ipairs(argPattern) do
        local result = ui.testRange(value, parsed[index])
        if result == "string" then
            parsed[index] = args[index]
        elseif not result then
            return nil
        end
    end
    return parsed
end

return ui
