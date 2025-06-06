local helpers = require("/utils/helpers")
local ui = require("/utils/ui")
local turtleInventory = require("/turtles/utils/inventory")

-- Create the miner-specific inventory manager
local inventory = {}

-- Re-export slot constants for convenience
inventory.SLOTS = turtleInventory.SLOTS

-- Create slot manager instance
inventory.slots = turtleInventory.createSlotManager()

-- Miner-specific slot configuration
local function createSlotConfig(config)
    local order = {inventory.SLOTS.CHEST_SLOT}
    local descriptions = {
        [inventory.SLOTS.CHEST_SLOT] = "Chests",
        [inventory.SLOTS.BLOCK_SLOT] = "Cobblestone",
        [inventory.SLOTS.FUEL_SLOT] = "Fuel (only coal supported)",
        [inventory.SLOTS.FUEL_CHEST_SLOT] = "Fuel Entangled Chest",
        [inventory.SLOTS.CHUNK_LOADER_SLOT] = "2 Chunk Loaders"
    }
    
    if config.useFuelEntangledChest then
        table.insert(order, inventory.SLOTS.FUEL_CHEST_SLOT)
    else
        table.insert(order, inventory.SLOTS.FUEL_SLOT)
    end
    
    if config.mineLoop then
        table.insert(order, inventory.SLOTS.CHUNK_LOADER_SLOT)
    end
    
    table.insert(order, inventory.SLOTS.BLOCK_SLOT)
    table.insert(order, inventory.SLOTS.MISC_SLOT)
    
    if config.useEntangledChests then
        descriptions[inventory.SLOTS.CHEST_SLOT] = "Entangled Chest"
    end
    
    return {order = order, descriptions = descriptions}
end

-- Override slot assignment to use miner config
local originalAssignSlots = inventory.slots.assignSlots
inventory.slots.assignSlots = function(config)
    local slotConfig = createSlotConfig(config)
    originalAssignSlots(slotConfig)
end

-- Miner-specific inventory functions
inventory.sortInventory = function(sortFuel, config)
    local wrapt = require("/turtles/utils/wrapper").createWrapper() -- Get current wrapper instance
    
    -- Clear cobble slot
    local initCobbleData = wrapt.getItemDetail(inventory.slots.get(inventory.SLOTS.BLOCK_SLOT))
    if initCobbleData and initCobbleData.name ~= "minecraft:cobblestone" then
        wrapt.select(inventory.slots.get(inventory.SLOTS.BLOCK_SLOT))
        wrapt.drop()
    end
    
    -- Clear fuel slot
    if sortFuel then
        local initFuelData = wrapt.getItemDetail(inventory.slots.get(inventory.SLOTS.FUEL_SLOT))
        if initFuelData and initFuelData.name ~= "minecraft:coal" then
            wrapt.select(inventory.slots.get(inventory.SLOTS.FUEL_SLOT))
            wrapt.drop()
        end
    end
    
    -- Sort inventory items
    local fuelData = sortFuel and wrapt.getItemDetail(inventory.slots.get(inventory.SLOTS.FUEL_SLOT)) or {count = 64}
    local cobbleData = wrapt.getItemDetail(inventory.slots.get(inventory.SLOTS.BLOCK_SLOT))
    
    for i = inventory.slots.get(inventory.SLOTS.MISC_SLOT), 16 do
        local curData = wrapt.getItemDetail(i)
        if curData then
            if curData.name == "minecraft:cobblestone" then
                wrapt.select(i)
                wrapt.transferTo(inventory.slots.get(inventory.SLOTS.BLOCK_SLOT))
            elseif sortFuel and curData.name == "minecraft:coal" then
                wrapt.select(i)
                wrapt.transferTo(inventory.slots.get(inventory.SLOTS.FUEL_SLOT))
            elseif not helpers.shouldKeepBlock(curData.name, config) then
                -- Drop unwanted blocks
                wrapt.select(i)
                wrapt.drop()
            end
        end
    end
    wrapt.select(inventory.slots.get(inventory.SLOTS.MISC_SLOT))
end

inventory.printInfo = function()
    local wrapt = require("/turtles/utils/wrapper").createWrapper()
    ui.print("Current fuel level is", wrapt.getFuelLevel())
    ui.print("Item slots, can change based on config:")
    inventory.slots.printSlotInfo()
end

-- Placeholder functions for chest and refuel operations
-- These would need full implementation based on the original script
inventory.tryDropOffThings = function(chestData, diggingArea, entangledChest, force)
    -- Implementation would go here
end

inventory.tryToRefuel = function(chestData, diggingArea, dropOffEntangledChest, refuelEntangledChest)
    -- Implementation would go here
end

return inventory