if GetResourceState('es_extended') ~= 'started' then return end
print('Current Framework: ESX')

local ESX = exports["es_extended"]:getSharedObject()

function SvNotify(msg, type)
    local src = source
    if Cfg.Notification == 'default' then
        TriggerClientEvent('esx:showNotification', src, msg, type)
    elseif Cfg.Notification == 'ox' then
        TriggerClientEvent('ox_lib:notify', src, { description = msg, type = type, position = 'top' })
    elseif Cfg.Notification == 'custom' then
        -- Insert your notification system here
    end
end

function GetPlayerIdentifier(player)
    local xPlayer = ESX.GetPlayerFromId(player)
    local id = xPlayer.getIdentifier()
    return id
end