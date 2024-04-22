if GetResourceState('qb-core') ~= 'started' then return end

local QBCore = exports['qb-core']:GetCoreObject()

function ClNotify(msg, type)
    if Cfg.Notification == 'default' then
        TriggerEvent('QBCore:Notify', msg, 'primary', 3000)
    elseif Cfg.Notification == 'ox' then
        lib.notify({ description = msg, type = type, position = 'top' })
    elseif Cfg.Notification == 'custom' then
        -- Insert your notification system here
    end
end

function ClJobCheck()
    local playerData = QBCore.Functions.GetPlayerData()
    if not playerData then return false end

    for _, policeJob in ipairs(Cfg.PoliceJobs) do
        if playerData.job.name == policeJob then
            return true
        end
    end
    return false
end