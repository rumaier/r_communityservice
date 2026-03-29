DatabaseBuilt = false
Core = exports.r_bridge:returnCoreObject()

local resource = GetCurrentResourceName()
local version = GetResourceMetadata(resource, 'version', 0)

local function checkVersion()
    if not Cfg.VersionCheck then return end
    Core.VersionCheck(resource)
    SetTimeout(3600000, checkVersion)
end

local function startupPrints()
    local debug = Cfg.Debug
    print('------------------------------')
    print(locale('startup_info', resource, version))
    if debug then
        print(locale('debug_enabled'))
    end
    print('------------------------------')
end

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= resource then return end
    startupPrints()
    checkVersion()
end)
