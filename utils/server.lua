Core = exports['r_bridge']:returnCoreObject()

local function buildDatabase()
    local builtTables = MySQL.query.await('SHOW TABLES LIKE "r_communityservice"')
    if #builtTables == 0 then
        local built = MySQL.query.await('CREATE TABLE `r_communityservice` ( `identifier` varchar(46) NOT NULL, `tasks` smallint(6) DEFAULT NULL, `items` longtext DEFAULT NULL, PRIMARY KEY (`identifier`) )')
        if not built then return print('[^8ERROR^0] Failed to create database table r_communityservice') end
        print('[^2SUCCESS^0] Created database table r_communityservice, this only happens once.')
    end
end

local function checkVersion()
    if not Cfg.Server.VersionCheck then return end
    local url = 'https://api.github.com/repos/rumaier/r_communityservice/releases/latest'
    local current = GetResourceMetadata(GetCurrentResourceName(), 'version', 0)
    PerformHttpRequest(url, function(err, text, headers)
        if err == 200 then
            local data = json.decode(text)
            local latest = data.tag_name
            if latest ~= current then
                print('[^3WARNING^0] '.. _L('update', GetCurrentResourceName()))
                print('[^3WARNING^0] https://github.com/rumaier/r_communityservice/releases/tag/2.0.3 ^0')
            end
        end
    end, 'GET', '', { ['Content-Type'] = 'application/json' })
    SetTimeout(3600000, checkVersion)
end

function debug(...)
    if Cfg.Debug then
        print(...)
    end
end

AddEventHandler('onResourceStart', function(resource)
    if (resource == GetCurrentResourceName()) then
        print('------------------------------')
        print(_L('version', resource, GetResourceMetadata(resource, 'version', 0)))
        print(_L('framework', Core.Info.Framework))
        print(_L('inventory', Core.Info.Inventory))
        print(_L('target', Core.Info.Target))
        print('------------------------------')
        checkVersion()
        buildDatabase()
    end
end)