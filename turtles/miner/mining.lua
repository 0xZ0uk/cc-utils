local helpers = require("/utils/helpers")
local pathfinding = require("/utils/pathfinding")
local ui = require("/utils/ui")
local turtleWrapper = require("/turtles/utils/wrapper")
local movement = require("/turtles/utils/movement")
local turtleInventory = require("/turtles/utils/inventory")
local region = require("/turtles/miner/region")
local inventory = require("/turtles/miner/inventory")
local minerUi = require("/turtles/miner/ui")

local mining = {}

-- Create turtle wrapper and pathfinder
local wrapt = turtleWrapper.createWrapper()
local pathfinder = pathfinding.createPathfinder()

-- Constants
local REFUEL_THRESHOLD = 500
local RETRY_DELAY = 3
local FALLING_BLOCKS = {
    ["minecraft:gravel"] = true,
    ["minecraft:sand"] = true
}

-- Pathfinding constants
local PATHFIND_INSIDE_AREA = 0
local PATHFIND_OUTSIDE_AREA = 1
local PATHFIND_INSIDE_NONPRESERVED_AREA = 2
local PATHFIND_ANYWHERE_NONPRESERVED = 3

-- Block inspection functions
local function isWaterSource(inspectFunction)
    local success, data = inspectFunction()
    if success and data.name == "minecraft:water" and data.state.level == 0 then
        return true
    end
    return false
end

local function isFluidSource(inspectFunction)
    local success, data = inspectFunction()
    if success and (data.name == "minecraft:lava" or data.name == "minecraft:water") and data.state.level == 0 then
        return true
    end
    return false
end

local function isFluid(inspectFunction)
    local success, data = inspectFunction()
    if success and (data.name == "minecraft:lava" or data.name == "minecraft:water") then
        return true
    end
    return false
end

local function isSand(inspectFunction)
    local success, data = inspectFunction()
    if success and FALLING_BLOCKS[data.name] then
        return true
    end
    return false
end

local function isOre(inspectFunction)
    local success, data = inspectFunction()
    if success and helpers.stringEndsWith(data.name, "_ore") then
        return true
    end
    return false
end

-- Mining functions with block filtering
local function mineBlockSelectively(digFunction, config)
    -- Get current slot count before digging
    local totalBefore = 0
    for i = 1, 16 do
        totalBefore = totalBefore + wrapt.getItemCount(i)
    end
    
    digFunction()
    
    -- Check if we picked up items
    local totalAfter = 0
    for i = 1, 16 do
        totalAfter = totalAfter + wrapt.getItemCount(i)
    end
    
    -- If we picked up items, check if we should keep them
    if totalAfter > totalBefore then
        for i = inventory.slots.get(inventory.SLOTS.MISC_SLOT), 16 do
            local itemDetail = wrapt.getItemDetail(i)
            if itemDetail and not helpers.shouldKeepBlock(itemDetail.name, config) then
                wrapt.select(i)
                wrapt.drop()
            end
        end
        wrapt.select(inventory.slots.get(inventory.SLOTS.MISC_SLOT))
    end
end

local function digAbove(config)
    if isFluidSource(wrapt.inspectUp) then
        turtleInventory.execWithSlot(wrapt, wrapt.placeUp, inventory.slots.get(inventory.SLOTS.BLOCK_SLOT))
    end
    mineBlockSelectively(wrapt.digUp, config)
end

local function digBelow(config)
    if isFluidSource(wrapt.inspectDown) then
        turtleInventory.execWithSlot(wrapt, wrapt.placeDown, inventory.slots.get(inventory.SLOTS.BLOCK_SLOT))
    end
    mineBlockSelectively(wrapt.digDown, config)
end

local function digInFront(config)
    if isFluidSource(wrapt.inspect) then
        turtleInventory.execWithSlot(wrapt, wrapt.place, inventory.slots.get(inventory.SLOTS.BLOCK_SLOT))
    end
    mineBlockSelectively(wrapt.dig, config)
end

-- Movement functions
local function forceMoveForward()
    if isWaterSource(wrapt.inspect) then
        turtleInventory.execWithSlot(wrapt, wrapt.place, inventory.slots.get(inventory.SLOTS.BLOCK_SLOT))
    end
    repeat
        wrapt.dig()
    until wrapt.forward()
end

local function stepTo(tX, tY, tZ)
    local dX = tX - wrapt.getX()
    local dY = tY - wrapt.getY()
    local dZ = tZ - wrapt.getZ()
    if dY < 0 then
        repeat
            wrapt.digDown()
        until wrapt.down()
    elseif dY > 0 then
        repeat
            wrapt.digUp()
        until wrapt.up()
    else
        local dir = movement.deltaToDirection(dX, dZ)
        movement.turnTowardsDirection(wrapt, dir)
        forceMoveForward()
    end
end

-- Pathfinding wrapper
local function createTraversableCheck(allBlocks, pathfindingType)
    return function(index)
        if pathfindingType == PATHFIND_INSIDE_AREA then
            return allBlocks[index] ~= nil
        elseif pathfindingType == PATHFIND_INSIDE_NONPRESERVED_AREA then
            return not not (allBlocks[index] and not allBlocks[index].preserve)
        elseif pathfindingType == PATHFIND_OUTSIDE_AREA then
            return allBlocks[index] == nil
        elseif pathfindingType == PATHFIND_ANYWHERE_NONPRESERVED then
            return allBlocks[index] == nil or not allBlocks[index].preserve
        end
        error("Unknown pathfinding type", 2)
    end
end

local function goToCoords(curBlock, pathfindingArea, pathfindingType)
    local pos = wrapt.getPosition()
    local traversableCheck = createTraversableCheck(pathfindingArea, pathfindingType)
    local pth = pathfinder.findPath(pos, curBlock, traversableCheck)
    
    if not pth then
        ui.printWarning("No path from", pos.x, pos.y, pos.z, "to", curBlock.x, curBlock.y, curBlock.z)
        return false
    end
    
    for k = 1, pth.length do
        if not helpers.isPosEqual3D(pth[k], pos) then
            stepTo(pth[k].x, pth[k].y, pth[k].z)
        end
    end
    return true
end

-- Main mining logic functions
local function executeDigging(layers, diggingArea, chestData, config)
    local counter = 0
    for layerIndex, layer in ipairs(layers) do
        for blockIndex, block in ipairs(layer) do
            if counter % 5 == 0 or not wrapt.getItemDetail(inventory.slots.get(inventory.SLOTS.BLOCK_SLOT)) then
                inventory.sortInventory(not config.useFuelEntangledChest, config)
            end
            if counter % 5 == 0 then
                inventory.tryToRefuel(chestData, diggingArea, config.useEntangledChests, config.useFuelEntangledChest)
            end
            inventory.tryDropOffThings(chestData, diggingArea, config.useEntangledChests)
            
            if not diggingArea[helpers.getIndex3D(block.x, block.y, block.z)].preserve then
                if not goToCoords(block, diggingArea, PATHFIND_INSIDE_NONPRESERVED_AREA) then
                    ui.printWarning("Couldn't find a path to next block, trying again ignoring walls...")
                    if not goToCoords(block, diggingArea, PATHFIND_ANYWHERE_NONPRESERVED) then
                        ui.printWarning("Fallback pathfinding failed, skipping the block")
                        break
                    end
                end
                
                if block.adjacent then
                    mining.processAdjacent(diggingArea, config)
                elseif block.triple then
                    mining.processTriple(diggingArea, config)
                end
            end
            counter = counter + 1
        end
    end
    inventory.tryDropOffThings(chestData, diggingArea, config.useEntangledChests, true)
end

mining.processAdjacent = function(allBlocks, config)
    -- Implementation of adjacent block processing
    local pos = wrapt.getPosition()
    -- Process horizontal neighbors
    for _, dir in ipairs({movement.DIRECTIONS.NORTH, movement.DIRECTIONS.SOUTH, movement.DIRECTIONS.EAST, movement.DIRECTIONS.WEST}) do
        movement.turnTowardsDirection(wrapt, dir)
        if not isFluid(wrapt.inspect) and config.plugFluidsOnly then
            -- Don't plug if only plugging fluids and this isn't a fluid
        else
            turtleInventory.execWithSlot(wrapt, wrapt.place, inventory.slots.get(inventory.SLOTS.BLOCK_SLOT))
        end
    end
    
    -- Process vertical neighbors
    local minusY = helpers.getIndex3D(pos.x, pos.y - 1, pos.z)
    local plusY = helpers.getIndex3D(pos.x, pos.y + 1, pos.z)
    
    if allBlocks[minusY] then
        if not allBlocks[minusY].preserve then
            digBelow(config)
        end
    elseif not config.plugFluidsOnly or isFluidSource(wrapt.inspectDown) then
        turtleInventory.execWithSlot(wrapt, wrapt.placeDown, inventory.slots.get(inventory.SLOTS.BLOCK_SLOT))
    end
    
    if allBlocks[plusY] then
        if not allBlocks[plusY].preserve then
            digAbove(config)
        end
    elseif not config.plugFluidsOnly or isFluid(wrapt.inspectUp) then
        if wrapt.getItemCount(inventory.slots.get(inventory.SLOTS.BLOCK_SLOT)) > 0 then
            local tries = 0
            repeat
                tries = tries + 1
            until turtleInventory.execWithSlot(wrapt, wrapt.placeUp, inventory.slots.get(inventory.SLOTS.BLOCK_SLOT)) or tries > 10
        end
    end
end

mining.processTriple = function(diggingArea, config)
    local pos = wrapt.getPosition()
    local minusY = helpers.getIndex3D(pos.x, pos.y - 1, pos.z)
    local plusY = helpers.getIndex3D(pos.x, pos.y + 1, pos.z)
    
    if not diggingArea[plusY].preserve then
        digAbove(config)
    end
    if not diggingArea[minusY].preserve then
        digBelow(config)
    end
end

mining.launchDigging = function(config, default)
    local diggingArea = minerUi.getValidatedRegion(config, default)
    local layers = region.createLayersFromArea(diggingArea, config.layerSeparationAxis)
    local chestData = region.reserveChests(diggingArea)
    executeDigging(layers, diggingArea, chestData, config)
end

mining.launchMineLoop = function(config, autostart)
    ui.print("Verifying mineLoopCommand...")
    local shape = minerUi.parseProgram(config.mineLoopCommand)
    if not shape then
        ui.printError("mineLoopCommand is invalid")
        return
    end
    
    local areaToValidate = shape.shape.generate(table.unpack(shape.args))
    local validationResult = region.validateRegion(areaToValidate)
    if validationResult ~= region.VALIDATION_RESULTS.SUCCESS then
        minerUi.showValidationError(validationResult)
        return
    end
    
    if not autostart then
        inventory.printInfo()
        ui.print("Press Enter to start the loop")
        ui.read()
    end
    
    mining.executeMineLoop(config)
end

mining.executeMineLoop = function(config)
    local cumDelta = {x = 0, y = 0, z = 0}
    local prevPos = nil
    
    while true do
        -- Create a region to dig
        local shape = minerUi.parseProgram(config.mineLoopCommand)
        local diggingArea = shape.shape.generate(table.unpack(shape.args))
        diggingArea = region.shiftRegion(diggingArea, cumDelta)
        local layers = region.createLayersFromArea(diggingArea, config.layerSeparationAxis)
        local chestData = region.reserveChests(diggingArea)
        
        -- Place chunk loader logic would go here
        
        -- Dig the region
        executeDigging(layers, diggingArea, chestData, config)
        
        cumDelta = {
            x = cumDelta.x + config.mineLoopOffset.x,
            y = cumDelta.y + config.mineLoopOffset.y,
            z = cumDelta.z + config.mineLoopOffset.z
        }
    end
end

return mining