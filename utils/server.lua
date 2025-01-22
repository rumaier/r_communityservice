Core = exports['r_bridge']:returnCoreObject()

local function buildDatabase()
    local builtTables = MySQL.query.await('SHOW TABLES LIKE "r_communityservice"')
    if #builtTables == 0 then
        local built = MySQL.query.await('CREATE TABLE `r_communityservice` ( `identifier` varchar(46) NOT NULL, `tasks` smallint(6) DEFAULT NULL, `items` longtext DEFAULT NULL, PRIMARY KEY (`identifier`) )')
        if not built then return print('[^8ERROR^0] Failed to create database table r_communityservice') end
        print('[^2SUCCESS^0] Created database table r_communityservice, this only happens once.')
    end
end

local function checkResourceVersion()
    if not Cfg.Server.VersionCheck then return end
    Core.VersionCheck(GetCurrentResourceName())
    SetTimeout(3600000, checkResourceVersion)
end

function _debug(...)
    if Cfg.Debug then
        print(...)
    end
end

AddEventHandler('onResourceStart', function(resource)
    if (resource == GetCurrentResourceName()) then
        print('------------------------------')
        print(_L('version', resource, GetResourceMetadata(resource, 'version', 0)))
        if GetResourceState('r_bridge') ~= 'started' then
            print('^1Bridge not detected, please ensure it is running.^0')
        else
            print('^2Bridge detected and loaded.^0')
        end
        print('------------------------------')
        checkResourceVersion()
        buildDatabase()
    end
end)