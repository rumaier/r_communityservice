Core = exports.r_bridge:returnCoreObject()

local framework = Core.Framework.Current

local onPlayerLoaded = framework == 'es_extended' and 'esx:playerLoaded' or 'QBCore:Client:OnPlayerLoaded'
RegisterNetEvent(onPlayerLoaded, function()
    InitializeZone()
    SetTimeout(1000, TriggerRelogCheck)
end)

function _debug(...)
    if not Cfg.Debug then return end
    print(...)
end
