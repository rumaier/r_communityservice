if GetResourceState('es_extended') ~= 'started' then return end

local ESX = exports['es_extended']:getSharedObject()

function ClNotify(msg, type)
    if Cfg.Notification == 'default' then
        ESX.ShowNotification(msg, type)
    elseif Cfg.Notification == 'ox' then
        lib.notify({ description = msg, type = type, position = 'top' })
    elseif Cfg.Notification == 'custom' then
        -- Insert your notification system here
    end
end

function ClJobCheck()
    local job = ESX.GetPlayerData().job
    for i = 1, #Cfg.PoliceJobs do
        if job.name == Cfg.PoliceJobs[i] then
            return true
        end
    end
    return false
end
