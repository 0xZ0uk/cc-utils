local ui = require("/utils/ui")
local helpers = require("/utils/helpers")
local shapes = require("/turtles/miner/shapes")
local region = require("/turtles/miner/region")
local inventory = require("/turtles/miner/inventory")

local minerUi = {}

minerUi.printProgramsInfo = function()
    ui.print("Select a program:")
    ui.print("\thelp <program>")
    for _, value in pairs(shapes) do
        ui.print("\t" .. value.shortDesc)
    end
end

minerUi.tryShowHelp = function(input)
    if not input then
        return false
    end
    local split = helpers.splitString(input)
    if split[1] ~= "help" then
        return false
    end
    if #split == 1 then
        minerUi.printProgramsInfo()
        return true
    end
    if #split ~= 2 then
        return false
    end
    local program = split[2]
    local shape = nil
    for key, value in pairs(shapes) do
        if value.command == program then
            shape = value
        end
    end
    if not shape then
        ui.printError("Unknown program")
        return true
    end
    ui.print("Usage:", shape.shortDesc)
    ui.print("\t" .. shape.longDesc)
    return true
end

minerUi.parseProgram = function(string)
    if not string then
        return nil
    end
    local split = helpers.splitString(string)
    if not split or helpers.tableLength(split) == 0 then
        return nil
    end
    local program = split[1]
    local shape = nil
    for _, value in pairs(shapes) do
        if value.command == program then
            shape = value
        end
    end
    if not shape then
        return nil
    end
    local args = {table.unpack(split, 2, #split)}
    local parsed = ui.parseArgs(shape.args, args)
    if not parsed then
        return nil
    end
    return {shape = shape, args = parsed}
end

minerUi.promptForShape = function()
    local shape
    while true do
        ui.write("> ")
        local input = ui.read()
        shape = minerUi.parseProgram(input)
        if not shape then
            if not minerUi.tryShowHelp(input) then
                ui.printError("Invalid program")
            end
        else
            break
        end
    end
    return shape
end

minerUi.showValidationError = function(validationResult)
    if bit32.band(validationResult, region.VALIDATION_RESULTS.FAILED_REGION_EMPTY) ~= 0 then
        ui.printError("Invalid mining volume: \n\tVolume is empty")
        return
    end
    
    local error = "Invalid mining volume:"
    if bit32.band(validationResult, region.VALIDATION_RESULTS.FAILED_NONONE_COMPONENTCOUNT) ~= 0 then
        error = error .. "\n\tVolume has multiple disconnected parts"
    end
    if bit32.band(validationResult, region.VALIDATION_RESULTS.FAILED_TURTLE_NOTINREGION) ~= 0 then
        error = error .. "\n\tTurtle (pos(0,0,0)) not in volume"
    end
    ui.printError(error)
end

minerUi.getValidatedRegion = function(config, default)
    inventory.printInfo()
    minerUi.printProgramsInfo()
    while true do
        local shape = nil
        if default then
            shape = minerUi.parseProgram(config.defaultCommand)
            if not shape then
                ui.printError("defaultCommand is invalid")
                default = false
            end
        end
        if not default then
            shape = minerUi.promptForShape()
        end
        local genRegion = shape.shape.generate(table.unpack(shape.args))
        local validationResult = region.validateRegion(genRegion)
        if validationResult == region.VALIDATION_RESULTS.SUCCESS then
            return genRegion
        end
        minerUi.showValidationError(validationResult)
    end
end

return minerUi