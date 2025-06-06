local helpers = require("/utils/helpers")

local inventory = {}

-- Turtle inventory slot constants
inventory.SLOTS = {
    CHEST_SLOT = "chest_slot",
    BLOCK_SLOT = "block_slot",
    FUEL_SLOT = "fuel_slot",
    FUEL_CHEST_SLOT = "fuel_chest_slot",
    CHUNK_LOADER_SLOT = "chunk_loader_slot",
    MISC_SLOT = "misc_slot"
}

-- Generic slot manager that can be configured for different turtle types
inventory.createSlotManager = function()
    local slotAssignments = {}
    local assigned = false
    local slotDesc = nil

    local public = {}

    public.assignSlots = function(slotConfig)
        if assigned then
            error("Slots have already been assigned", 2)
        end
        assigned = true

        local currentSlot = 1
        for _, slotType in ipairs(slotConfig.order) do
            slotAssignments[slotType] = currentSlot
            currentSlot = currentSlot + 1
        end

        slotDesc = slotConfig.descriptions
    end

    public.get = function(slotId)
        if slotAssignments[slotId] then
            return slotAssignments[slotId]
        else
            error("Slot " .. tostring(slotId) .. " was not assigned", 2)
        end
    end

    public.printSlotInfo = function()
        local inverse = {}
        for key, value in pairs(slotAssignments) do
            inverse[value] = key
        end
        for key, value in ipairs(inverse) do
            if slotDesc[value] then
                print("\tSlot", key, "-", slotDesc[value])
            end
        end
    end

    return public
end

-- Generic inventory operations
inventory.execWithSlot = function(turtle, func, slot)
    turtle.select(slot)
    local data = func()
    turtle.select(1) -- Return to default slot
    return data
end

inventory.dropInventory = function(turtle, dropFunction, startSlot, endSlot)
    local dropped = true
    for i = startSlot or 1, endSlot or 16 do
        if turtle.getItemCount(i) > 0 then
            turtle.select(i)
            dropped = dropFunction() and dropped
        end
    end
    turtle.select(1)
    return dropped
end

return inventory
