local RESOURCE_NAME = GetCurrentResourceName()

local assignedTasks = {}
local activePlayers = {}
local taskZone = lib.zones.sphere({ coords = Cfg.ZoneCoords, radius = Cfg.ZoneRadius })

local function logAssignment(src, target, tasks)
    Log(src, 'assign_tasks', {
        { name = locale('target_id'), value = '`' .. target .. '`', inline = true },
        { name = locale('username'), value = '`' .. GetPlayerName(target) .. '`', inline = true },
        { name = locale('tasks'), value = '`' .. tasks .. '`', inline = true },
    })
end

local function logRemoval(src, target)
    Log(src, 'remove_tasks', {
        { name = locale('target_id'), value = '`' .. target .. '`', inline = true },
        { name = locale('username'), value = '`' .. GetPlayerName(target) .. '`', inline = true },
        { name = utf8.char(0x200B), value = utf8.char(0x200B), inline = true },
    })
end

local function isPlayerNearCoords(src, coords)
    local player = GetPlayerPed(src)
    local playerCoords = GetEntityCoords(player)
    return #(playerCoords - coords) < 5.0
end

local function isPlayerJobAllowed(src)
    local job = bridge.framework.getPlayerJob(src) or {}
    if lib.table.contains(Cfg.AllowedJobs, job.name) then return true end
    return false
end

local function getAccessLevel(src)
    if IsPlayerAceAllowed(src, 'r_communityservice') then return 3 end
    if isPlayerJobAllowed(src) then return 2 end
    if activePlayers[src] then return 1 end
    return 0
end

lib.callback.register('r_communityservice:getAccessLevel', function(src)
    return getAccessLevel(src)
end)

lib.callback.register('r_communityservice:menuRequest', function(src)
    if getAccessLevel(src) < 2 then
        _debug('Player %s does not have access to the community service menu', src)
        return false
    end
    return true, activePlayers
end)

local function returnItems(src, items)
    for k, v in pairs(items) do
        if not bridge.inventory.addItem(src, v.name, v.count, v.metadata or {}) then
            print('^1[r_communityservice]^0 Failed to add item ' .. v.name .. ' to player ' .. src)
            return false
        end
    end
    return true
end

local function confiscateItems(src)
    local inv = bridge.inventory.getInventory(src) or {}
    for k, v in pairs(inv) do
        if not bridge.inventory.removeItem(src, v.name, v.count) then
            print('^1[r_communityservice]^0 Failed to remove item ' .. v.name .. ' from player ' .. src)
            return false
        end
    end
    return inv
end

local function releasePlayer(src, identifier)
    if not returnItems(src, assignedTasks[identifier].items) then return end
    assignedTasks[identifier] = nil
    activePlayers[src] = nil
    TriggerClientEvent('r_communityservice:release', src)
end

local function generateTaskCoords(src)
    local coords = taskZone.coords
    local radius = taskZone.radius
    local task = nil
    repeat
        local x = coords.x + math.random(-radius, radius)
        local y = coords.y + math.random(-radius, radius)
        task = vec3(x, y, coords.z)
        Wait(100)
    until taskZone:contains(task)
    activePlayers[src].current = task
    return task
end

lib.callback.register('r_communityservice:requestTask', function(src)
    local assigned = activePlayers[src]
    if not assigned then
        print('^1[r_communityservice]^0 Player ' .. src .. ' is not assigned to any tasks')
        return nil, nil, true
    end
    if assigned.current then
        if not isPlayerNearCoords(src, assigned.current) then
            print('^1[r_communityservice]^0 Player ' .. src .. ' is not near their current task')
            return nil, nil, true
        else
            assigned.tasks = assigned.tasks - 1
        end
    end
    if assigned.tasks == 0 then
        releasePlayer(src, assigned.identifier)
        Log(src, 'tasks_finished', {})
        return
    end
    return generateTaskCoords(src), assigned.tasks
end)

lib.callback.register('r_communityservice:assignTasks', function(src, target, tasks)
    if src == target then return false, 'no_self_assign' end
    if getAccessLevel(src) < 2 then
        print('^1[r_communityservice]^0 Player ' .. src .. ' does not have access to assign tasks')
        return false
    end
    if not GetPlayerName(target) then return false, 'player_not_found' end
    local identifier = bridge.framework.getPlayerIdentifier(target)
    if not identifier then
        print('^1[r_communityservice]^0 Player ' .. target .. ' identifier not found')
        return false
    end
    if assignedTasks[identifier] then return false, 'player_already_assigned' end
    assignedTasks[identifier] = {
        tasks = tasks,
        items = confiscateItems(target),
    }
    activePlayers[target] = {
        name = GetPlayerName(target),
        identifier = identifier,
        tasks = tasks,
        current = nil,
    }
    TriggerClientEvent('r_communityservice:sendToZone', target, tasks)
    logAssignment(src, target, tasks)
    return true
end)

lib.callback.register('r_communityservice:removeTasks', function(src, target)
    if src == target then return end
    if getAccessLevel(src) < 2 then
        print('^1[r_communityservice]^0 Player ' .. src .. ' does not have access to remove tasks')
        return false
    end
    if not activePlayers[target] then
        return false, 'player_not_found'
    end
    local identifier = bridge.framework.getPlayerIdentifier(target)
    if not identifier then
        print('^1[r_communityservice]^0 Player ' .. target .. ' not found')
        return false
    end
    releasePlayer(target, identifier)
    logRemoval(src, target)
    return true
end)

local function registerCommand()
    lib.addCommand(Cfg.Command, {
        help = locale('command_help'),
    }, function(src)
        TriggerClientEvent('r_communityservice:openMenu', src)
    end)
end

local function cacheTasksToJson()
    local saved = SaveResourceFile(RESOURCE_NAME, 'core/server/tasks.json', json.encode(assignedTasks, { indent = true}), -1)
    if not saved then
        print('^1[r_communityservice]^0 Failed to cache tasks to json')
    end
end

local function fetchTasksFromJson()
    local data = LoadResourceFile(RESOURCE_NAME, 'core/server/tasks.json')
    if not data then
        print('^1[r_communityservice]^0 Failed to fetch tasks from json')
        return
    end
    assignedTasks = json.decode(data) or {}
end

RegisterNetEvent('r_communityservice:playerLoaded', function()
    local identifier = bridge.framework.getPlayerIdentifier(source)
    if not identifier or not assignedTasks[identifier] then return end
    activePlayers[source] = {
        name = GetPlayerName(source),
        identifier = identifier,
        tasks = assignedTasks[identifier].tasks,
        current = nil
    }
    TriggerClientEvent('r_communityservice:sendToZone', source, activePlayers[source].tasks)
end)

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    fetchTasksFromJson()
    registerCommand()
end)

AddEventHandler('playerDropped', function()
    if activePlayers[source] then
        local identifier = bridge.framework.getPlayerIdentifier(source)
        assignedTasks[identifier].tasks = activePlayers[source].tasks + 1
        activePlayers[source] = nil
    end
end)

AddEventHandler('txAdmin:events:serverShuttingDown', function()
    cacheTasksToJson()
end)