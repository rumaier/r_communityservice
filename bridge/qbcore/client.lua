if GetResourceState('qb-core') ~= 'started' then return end

local QBCore = exports['qb-core']:GetCoreObject()

function ClNotify(msg, type)
    if Cfg.Notification == 'default' then
        TriggerEvent('QBCore:Notify', msg, type, 3000)
    elseif Cfg.Notification == 'ox' then
        lib.notify({ description = msg, type = type, position = 'top' })
    elseif Cfg.Notification == 'custom' then
        -- Insert your notification system here
    end
end