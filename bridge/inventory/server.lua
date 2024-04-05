if Cfg.Inventory == 'none' then return end
print('Current Inventory: '.. Cfg.Inventory ..'')

RegisterNetEvent('r_communityservice:confiscateInven')
AddEventHandler('r_communityservice:confiscateInven', function()
    exports.ox_inventory:ConfiscateInventory(source)
end)

RegisterNetEvent('r_communityservice:returnInven')
AddEventHandler('r_communityservice:returnInven', function()
    exports.ox_inventory:ReturnInventory(source)
end)