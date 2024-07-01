if GetResourceState('qb-inventory') ~= 'started' then return end

local QBCore = exports['qb-core']:GetCoreObject()

Inventory = {
    
    getPlayerInventory = function()
        local player = QBCore.Functions.GetPlayerData()
        local inventory = player.items
        for k, v in pairs(inventory) do
            inventory[k].count = v.amount
        end
        return inventory
    end,

    getPlayerInventoryWeight = function()
        local weight = 0
        local items = Inventory.getPlayerInventory()
        for k, v in pairs(items) do
            weight = weight + (v.weight * v.count)
        end
        return weight
    end,

    getMaxWeight = function()
        return 120000
    end,

    openStash = function(name)
        TriggerEvent("inventory:client:SetCurrentStash", name)
        TriggerServerEvent("inventory:server:OpenInventory", "stash", name, {
            maxweight = 50000,
            slots = 50,
        })
    end,

    getServerItem = function(item)
        if item == 'all' then return QBCore.Shared.Items end
        return QBCore.Shared.Items[item]
    end
}
