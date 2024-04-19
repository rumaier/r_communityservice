if not Cfg.Inventory then return end
print('Current Inventory: ' .. Cfg.Inventory .. '')

RegisterNetEvent('r_communityservice:confiscateInven')
AddEventHandler('r_communityservice:confiscateInven', function()
    if Cfg.Inventory == 'ox_inventory' then
        exports.ox_inventory:ConfiscateInventory(source)
    elseif Cfg.Inventory == 'custom' then
        -- Insert Your Inventories Exports Here
    end
end)

RegisterNetEvent('r_communityservice:returnInven')
AddEventHandler('r_communityservice:returnInven', function()
    if Cfg.Inventory == 'ox_inventory' then
        exports.ox_inventory:ReturnInventory(source)
    elseif Cfg.Inventory == 'custom' then
        -- Insert Your Inventories Exports Here
    end
end)
