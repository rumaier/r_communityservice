if GetResourceState('ox_inventory') ~= 'started' then return end

local ox_inventory = exports.ox_inventory

Inventory = {

    getPlayerInventory = function()
        return ox_inventory:GetPlayerItems()
    end,

    getPlayerInventoryWeight = function()
        return ox_inventory:GetPlayerWeight()
    end,

    getMaxWeight = function()
        return ox_inventory:GetPlayerMaxWeight()
    end,

    openStash = function(name)
        ox_inventory:openInventory('stash', name)
    end,

    getServerItem = function(item)
        if item == 'all' then return ox_inventory:Items() end
        return ox_inventory:Items(item)
    end
}