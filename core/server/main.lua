local r_communityservice = GetCurrentResourceName()
local zone = lib.zones.sphere({ coords = Cfg.ZoneCoords, radius = Cfg.ZoneRadius })
local comms = {}
local active = {}

local function saveTasks()
    local path = 'core/server/tasks.json'
    local data = json.encode(comms)
    local saved = SaveResourceFile(r_communityservice, path, data, -1)
    if not saved then
        _error('Failed to save tasks to: ' .. path)
    end
end

local function cacheTasks()
    local path = 'core/server/tasks.json'
    local file = LoadResourceFile(r_communityservice, path)
    if not file then
        _error('Failed to load tasks from: ' .. path)
    end
    comms = file and json.decode(file) or {}
end

local function registerCommand()
    local cmd = Cfg.Command
    local type = type(cmd)
    if not type == 'string' then
        return _error('Cfg.Command must be a string, got ' .. type)
    end
    lib.addCommand(cmd, { help = locale('command_help') }, function(src)
        TriggerClientEvent('r_communityservice:openMenu', src, active)
    end)
end

local function getPermissionLevel(src)
    local ace = IsPlayerAceAllowed(src, 'communityservice')
    local job = Core.Framework.getPlayerJob(src)
    if ace then
        return 3
    elseif lib.table.contains(Cfg.AllowedJobs, job.name) then
        return 2
    elseif active[src] then
        return 1
    else
        return 0
    end
end

lib.callback.register('r_communityservice:getPermissionLevel', function(src)
    return getPermissionLevel(src)
end)

local function confiscateItems(src)
    local items = Core.Inventory.getPlayerInventory(src)
    for _, item in pairs(items) do
        local removed = Core.Inventory.removeItem(src, item.name, item.count)
        if not removed then
            return _error('Failed to remove item ' .. item.name .. ' x' .. item.count .. ' from player ' .. src)
        end
    end
    return items
end

local function returnItems(src, items)
    for _, item in pairs(items) do
        local added = Core.Inventory.addItem(src, item.name, item.count, item.metadata)
        if not added then
            return _error('Failed to return item ' .. item.name .. ' x' .. item.count .. ' to player ' .. src)
        end
    end
    return true
end

local function isPlayerNearby(src, location)
    local player = GetPlayerPed(src)
    local coords = GetEntityCoords(player)
    local dist = #(coords.xy - location.xy)
    return dist <= 5.0
end

local function logAssignment(src, target, tasks)
    SendLog(src, {
        action = locale('log_assigned'),
        fields = {
            {
                name = locale('target_id'),
                value = '`' .. target .. '`',
                inline = true
            },
            {
                name = locale('username'),
                value = '`' .. GetPlayerName(target) .. '`',
                inline = true
            },
            {
                name = locale('tasks'),
                value = '`' .. tasks .. '`',
                inline = true
            },
        }
    })
end

local function logRemoval(src, target)
    SendLog(src, {
        action = locale('log_removed'),
        fields = {
            {
                name = locale('target_id'),
                value = '`' .. target .. '`',
                inline = true
            },
            {
                name = locale('username'),
                value = '`' .. GetPlayerName(target) .. '`',
                inline = true
            },
            {
                name = utf8.char(0x200B),
                value = utf8.char(0x200B),
                inline = true
            },
        }
    })
end

local function logFinished(src)
    SendLog(src, {
        action = locale('log_finished'),
    })
end

local function releasePlayer(src, identifier)
    local items = comms[identifier].items
    if not returnItems(src, items) then return end
    comms[identifier] = nil
    active[src] = nil
    TriggerClientEvent('r_communityservice:release', src)
end

local function getNextLocation(src)
    local loc = zone.coords
    local rad = zone.radius
    local next = nil
    repeat
        next = vec3(loc.x + math.random(-rad, rad), loc.y + math.random(-rad, rad), loc.z)
        Wait(100)
    until zone:contains(next)
    active[src].current = next
    return next
end

lib.callback.register('r_communityservice:requestTask', function(src)
    local assigned = active[src]
    if not assigned then
        _error('Player ' .. src .. ' is not currently assigned to community service')
        return false, true
    end
    local identifier = Core.Framework.getPlayerIdentifier(src)
    if assigned.current then
        if not isPlayerNearby(src, assigned.current) then
            _error('Player ' .. src .. ' is not near their last task location')
            return false, true
        else
            assigned.tasks = assigned.tasks - 1
            comms[identifier].tasks = assigned.tasks
        end
    end
    if assigned.tasks == 0 then
        releasePlayer(src, identifier)
        logFinished(src)
        return
    end
    return getNextLocation(src)
end)

lib.callback.register('r_communityservice:assignComms', function(src, target, tasks)
    if src == target then
        return false, 'no_self_assign'
    end
    if getPermissionLevel(src) < 2 then
        return _error('Player ' .. src .. ' does not have permission to assign comms')
    end
    local identifier = Core.Framework.getPlayerIdentifier(target)
    if not identifier then
        return false, 'player_not_found'
    end
    if comms[identifier] then
        return false, 'player_already_assigned'
    end
    local items = confiscateItems(target)
    comms[identifier] = { tasks = tasks, items = items }
    active[target] = {
        identifier = identifier,
        name = GetPlayerName(target),
        tasks = tasks
    }
    -- TODO: log    
    TriggerClientEvent('r_communityservice:sendToZone', target, tasks)
    logAssignment(src, target, tasks)
    return true
end)

lib.callback.register('r_communityservice:removeComms', function(src, target)
    if getPermissionLevel(src) < 2 then
        return _error('Player ' .. src .. ' does not have permission to remove comms')
    end
    local identifier = Core.Framework.getPlayerIdentifier(target)
    if not identifier or not comms[identifier] then
        return _error('Player ' .. target .. ' is offline or not currently assigned to community service')
    end
    releasePlayer(target, identifier)
    logRemoval(src, target)
    return true
end)

RegisterNetEvent('r_communityservice:relog', function()
    local src = source
    local identifier = Core.Framework.getPlayerIdentifier(src)
    if not identifier or not comms[identifier] then return end
    active[src] = {
        identifier = identifier,
        name = GetPlayerName(src),
        tasks = comms[identifier].tasks,
        current = nil
    }
    TriggerClientEvent('r_communityservice:sendToZone', src, comms[identifier].tasks)
end)

AddEventHandler('onResourceStart', function(resource)
    if resource ~= r_communityservice then return end
    registerCommand()
    cacheTasks()
end)

AddEventHandler('txAdmin:events:serverShuttingDown', function()
    saveTasks()
end)

AddEventHandler('playerDropped', function()
    local src = source
    if active[src] then
        local identifier = Core.Framework.getPlayerIdentifier(src)
        comms[identifier].tasks = active[src].tasks + 1
        active[src] = nil
    end
end)
