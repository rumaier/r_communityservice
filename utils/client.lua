Core = exports.r_bridge:returnCoreObject()

local framework = Core.Framework.Current

local onPlayerLoaded = framework == 'es_extended' and 'esx:playerLoaded' or 'QBCore:Client:OnPlayerLoaded'
RegisterNetEvent(onPlayerLoaded, function()
    InitializeZone()
    TriggerRelogCheck()
end)

function _debug(...)
    if not Cfg.Debug then return end
    print(...)
end

RegisterNUICallback('getLocales', function(_, cb) cb(Language[Cfg.Server.Language]) end)

RegisterNUICallback('getConfig', function(_, cb)
    Cfg.Server.InventoryPath = Core.Inventory.IconPath
    cb(Cfg)
end)
