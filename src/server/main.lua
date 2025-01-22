local punished = {}
local zone = lib.zones.sphere({ coords = Cfg.Zone.coords, radius = Cfg.Zone.radius, debug = Cfg.Debug })

local function generateTaskList(length)
    local generated = {}
    while #generated < length do
        local num1, num2 = math.random(0, (Cfg.Zone.radius - 10) * 2), math.random(0, (Cfg.Zone.radius - 10) * 2)
        local coords = vec3(Cfg.Zone.coords.x + num1, Cfg.Zone.coords.y + num2, Cfg.Zone.coords.z)
        if zone:contains(coords) then
            table.insert(generated, coords)
        end
        if #generated == length then
            return generated
        end
        Wait(0)
    end
end

lib.callback.register('r_communityservice:antiCombatLog', function(src)
    local src = source
    local identifier = Core.Framework.GetPlayerIdentifier(src)
    local data = MySQL.query.await('SELECT * FROM `r_communityservice` WHERE `identifier` = @identifier', { ['@identifier'] = identifier })
    if #data == 0 then return false end
    table.insert(punished, { serverId = src, identifier = identifier, tasks = data[1].tasks, items = json.decode(data[1].items) })
    MySQL.update.await('DELETE FROM `r_communityservice` WHERE `identifier` = @identifier', { ['@identifier'] = identifier })
    local taskList = generateTaskList(data[1].tasks)
    return true, taskList
end)

lib.callback.register('r_communityservice:getPermissionLevel', function(src)
    local ace, job = IsPlayerAceAllowed(src, 'communityservice'), Core.Framework.GetPlayerJob(src)
    _debug('[DEBUG] - ace:', ace, '| job:', job)
    if ace then return 2 end
    for i = 1, #Cfg.Server.policeJobs do
        if job == Cfg.Server.policeJobs[i] then
            return 1
        end
    end
    return 0
end)

lib.callback.register('r_communityservice:getActivePunishments', function(src)
    return punished
end)

RegisterNetEvent('r_communityservice:confiscateItems', function()
    local src = source
    local items = Core.Inventory.GetInventoryItems(src)
    punished[#punished].items = items
    for _, item in pairs(items) do
        Core.Inventory.RemoveItem(src, item.name, item.count)
    end
    _debug('[DEBUG] - confiscated items:', items)
end)

local function returnInventory(src)
    for _, data in pairs(punished) do
        if tonumber(data.serverId) == tonumber(src) then
            for _, item in pairs(data.items) do
                Core.Inventory.AddItem(src, item.name, item.count, item.metadata)
            end
            punished[_].items = {}
            _debug('[DEBUG] - returned items:', data.items)
            break
        end
    end
end

lib.callback.register('r_communityservice:issuePunishment', function(src, target, tasks)
    local taskList = generateTaskList(tasks)
    local identifier = Core.Framework.GetPlayerIdentifier(target)
    table.insert(punished, { serverId = target, identifier = identifier, tasks = tasks, items = {} })
    TriggerClientEvent('r_communityservice:issuePunishment', target, taskList)
    _debug('[DEBUG] - issued punishment:', target, '| tasks:', tasks)
    return true
end)

lib.callback.register('r_communityservice:removePunishment', function(src, target)
    for _, data in pairs(punished) do
        if tonumber(data.serverId) == tonumber(target) then
            returnInventory(target)
            while #punished[_].items > 0 do Wait(100) end
            table.remove(punished, _)
            TriggerClientEvent('r_communityservice:removePunishment', target)
            _debug('[DEBUG] - removed punishment:', target)
            return true
        end
    end
end)

lib.callback.register('r_communityservice:removeTask', function(src)
    for _, data in pairs(punished) do
        if tonumber(data.serverId) == tonumber(src) then
            punished[_].tasks = punished[_].tasks - 1
            _debug('[DEBUG] - removed task:', src)
            if punished[_].tasks == 0 then
                returnInventory(src)
                while #punished[_].items > 0 do Wait(100) end
                table.remove(punished, _)
                TriggerClientEvent('r_communityservice:removePunishment', src)
                _debug('[DEBUG] - removed punishment:', src)
            end
            return true
        end
    end
    return false
end)

lib.callback.register('r_communityservice:checkIfFinished', function(src)
    for _, data in pairs(punished) do
        if data.serverId == src then
            return false
        end
    end
    return true
end)