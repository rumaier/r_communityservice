local RESOURCE_NAME = GetCurrentResourceName()
local TASKS_FILE = 'core/server/tasks.json'
local TASK_COMPLETE_DISTANCE = 1.5
local REQUEST_RATE_LIMIT_MS = 500
local START_RATE_LIMIT_MS = 500
local COMPLETE_RATE_LIMIT_MS = 750
local STAFF_RATE_LIMIT_MS = 1000
local RESTORE_RATE_LIMIT_MS = 2000

local assignedTasks = {}
local activePlayers = {}

local function isInteger(value, minimum, maximum)
    return type(value) == 'number'
        and value == value
        and value ~= math.huge
        and value ~= -math.huge
        and value % 1 == 0
        and value >= minimum
        and value <= maximum
end

local function cacheTasksToJson()
    local encodedSuccessfully, encoded = pcall(json.encode, assignedTasks, { indent = true })
    if not encodedSuccessfully then
        log('error', 'Failed to encode tasks json: ' .. tostring(encoded))
        return false
    end
    local saved = SaveResourceFile(
        RESOURCE_NAME,
        TASKS_FILE,
        encoded,
        -1
    )
    if not saved then
        log('error', 'Failed to cache tasks to json')
    end
    return saved
end

local function fetchTasksFromJson()
    local data = LoadResourceFile(RESOURCE_NAME, TASKS_FILE)
    if not data or data == '' then
        assignedTasks = {}
        return
    end

    local success, decoded = pcall(json.decode, data)
    if not success or type(decoded) ~= 'table' then
        log('error', 'Failed to decode tasks json; starting with an empty cache')
        assignedTasks = {}
        return
    end

    assignedTasks = decoded
    for identifier, record in pairs(assignedTasks) do
        if type(record) ~= 'table' or type(record.tasks) ~= 'number' then
            log('warn', ('Removed invalid cached assignment for %s'):format(identifier))
            assignedTasks[identifier] = nil
        else
            record.tasks = math.max(0, math.floor(record.tasks))
            if type(record.items) ~= 'table' then
                log('warn', ('Invalid custody data for %s; preserving sentence with empty custody'):format(identifier))
                record.items = {}
            end
        end
    end
end

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

local function getPlayerCoords(src)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return end
    return GetEntityCoords(ped)
end

local function isPlayerInsideZone(src)
    local coords = getPlayerCoords(src)
    return coords and #(coords - Cfg.ZoneCoords) <= Cfg.ZoneRadius + 1.0 or false
end

local function isPlayerNearTask(src, task)
    local coords = getPlayerCoords(src)
    if not coords then return false end
    return #(coords.xy - task.xy) <= TASK_COMPLETE_DISTANCE
end

local function isPlayerJobAllowed(src)
    local job = bridge.framework.getPlayerJob(src) or {}
    return lib.table.contains(Cfg.AllowedJobs, job.name)
end

local function getAccessLevel(src)
    if activePlayers[src] then return 1 end
    if IsPlayerAceAllowed(src, 'r_communityservice') then return 3 end
    if isPlayerJobAllowed(src) then return 2 end
    return 0
end

local API_VERSION = 1

local function canManage(src)
    return getAccessLevel(src) >= 2
end

local function getStaffRoster()
    local roster = {}
    for src, runtime in pairs(activePlayers) do
        local assignment = assignedTasks[runtime.identifier]
        if assignment then
            roster[#roster + 1] = {
                id = src,
                name = runtime.name,
                tasks = assignment.tasks,
            }
        end
    end
    return roster
end

local function cloneItemMetadata(metadata)
    if type(metadata) ~= 'table' then return metadata end
    return lib.table.deepclone(metadata)
end

local function metadataMatches(left, right)
    local a = type(left) == 'table' and left or {}
    local b = type(right) == 'table' and right or {}
    return lib.table.matches(a, b)
end

local function removeInventoryItem(src, item)
    if item.slot ~= nil then
        return bridge.inventory.removeItem(src, item.name, item.count, nil, item.slot)
    end
    return bridge.inventory.removeItem(src, item.name, item.count, item.metadata)
end

local function snapshotInventoryItems(src)
    local inventory = bridge.inventory.getInventory(src) or {}
    local snapshot = {}
    for _, item in pairs(inventory) do
        if type(item) == 'table' and item.name and item.count and item.count > 0 then
            snapshot[#snapshot + 1] = {
                name = item.name,
                count = item.count,
                metadata = cloneItemMetadata(item.metadata),
                slot = item.slot,
            }
        end
    end
    return snapshot
end

--- Resolve a live slot after addItem (custody slots are stale post-restore).
local function resolveRemovableItem(src, item)
    local inventory = bridge.inventory.getInventory(src) or {}
    for _, invItem in pairs(inventory) do
        if type(invItem) == 'table'
            and invItem.name == item.name
            and type(invItem.count) == 'number'
            and invItem.count >= item.count
            and metadataMatches(invItem.metadata, item.metadata)
        then
            return {
                name = invItem.name,
                count = item.count,
                metadata = cloneItemMetadata(invItem.metadata),
                slot = invItem.slot,
            }
        end
    end
    return {
        name = item.name,
        count = item.count,
        metadata = item.metadata,
    }
end

local function rollbackItems(src, items)
    local rollbackSucceeded = true
    for i = #items, 1, -1 do
        local item = items[i]
        if not bridge.inventory.addItem(src, item.name, item.count, item.metadata) then
            rollbackSucceeded = false
            log('error', ('failed to return %sx %s while rolling back player %s'):format(
                item.count,
                item.name,
                src
            ))
        end
    end
    return rollbackSucceeded
end

local function removeRestoredItems(src, items)
    local removed = {}
    for i = 1, #items do
        local item = resolveRemovableItem(src, items[i])
        if not removeInventoryItem(src, item) then
            log('error', ('failed to re-secure %sx %s (slot %s) for player %s'):format(
                item.count,
                item.name,
                tostring(item.slot),
                src
            ))
            for j = #removed, 1, -1 do
                local rollback = removed[j]
                if not bridge.inventory.addItem(src, rollback.name, rollback.count, rollback.metadata) then
                    log('error', ('failed to roll back removed %sx %s for player %s'):format(
                        rollback.count,
                        rollback.name,
                        src
                    ))
                end
            end
            return false
        end
        removed[#removed + 1] = item
    end
    return true
end

local function confiscateItems(src)
    local pending = snapshotInventoryItems(src)
    local removed = {}
    for i = 1, #pending do
        local item = pending[i]
        if not removeInventoryItem(src, item) then
            log('warn', ('Player %s could not have inventory confiscated (%sx %s, slot %s)'):format(
                src,
                item.count,
                item.name,
                tostring(item.slot)
            ))
            rollbackItems(src, removed)
            return nil, 'confiscate_failed'
        end
        removed[#removed + 1] = item
    end
    return removed
end

local function normalizeCustodyItems(items)
    local pending = {}
    if type(items) ~= 'table' then return pending end
    for _, item in pairs(items) do
        if type(item) == 'table' and item.name and item.count and item.count > 0 then
            pending[#pending + 1] = item
        end
    end
    return pending
end

local function restoreCustody(src, items)
    local pending = normalizeCustodyItems(items)
    if #pending == 0 then return true end

    for i = 1, #pending do
        local item = pending[i]
        if not bridge.inventory.canCarry(src, item.name, item.count) then
            return false, 'insufficient_space'
        end
    end

    local restored = {}
    for i = 1, #pending do
        local item = pending[i]
        if not bridge.inventory.addItem(src, item.name, item.count, item.metadata) then
            for j = #restored, 1, -1 do
                local rollback = restored[j]
                if not bridge.inventory.removeItem(src, rollback.name, rollback.count, rollback.metadata) then
                    log('error', ('failed to roll back restored %sx %s for player %s'):format(
                        rollback.count,
                        rollback.name,
                        src
                    ))
                end
            end
            return false, 'restore_failed'
        end
        restored[#restored + 1] = item
    end

    return true
end

local function releasePlayer(src, identifier)
    local assignment = assignedTasks[identifier]
    if not assignment then return false end
    local runtime = activePlayers[src]
    local custody = normalizeCustodyItems(assignment.items)

    local restored, err = restoreCustody(src, assignment.items)
    if not restored then return false, err end

    assignedTasks[identifier] = nil
    activePlayers[src] = nil
    if not cacheTasksToJson() then
        assignedTasks[identifier] = assignment
        activePlayers[src] = runtime
        if #custody > 0 and not removeRestoredItems(src, custody) then
            log('error', ('failed to roll back custody for %s after save failure'):format(identifier))
        end
        return false, 'persistence_failed'
    end
    TriggerClientEvent('r_communityservice:release', src)
    return true
end

local function syncPlayerToZone(src)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return end
    SetEntityCoords(ped, Cfg.ZoneCoords.x, Cfg.ZoneCoords.y, Cfg.ZoneCoords.z, false, false, false, false)
end

local function sendToZone(src, tasks)
    syncPlayerToZone(src)
    TriggerClientEvent('r_communityservice:sendToZone', src, tasks)
end

local function generateTaskCoords()
    local angle = math.random() * math.pi * 2.0
    local maxRadius = math.max(0.0, Cfg.ZoneRadius - 2.0)
    local distance = math.sqrt(math.random()) * maxRadius
    return vec3(
        Cfg.ZoneCoords.x + math.cos(angle) * distance,
        Cfg.ZoneCoords.y + math.sin(angle) * distance,
        Cfg.ZoneCoords.z
    )
end

local function hydratePlayer(src)
    if activePlayers[src] then return true end
    local identifier = bridge.framework.getPlayerIdentifier(src)
    local assignment = identifier and assignedTasks[identifier]
    if not assignment then return false end

    activePlayers[src] = {
        name = GetPlayerName(src),
        identifier = identifier,
        current = nil,
        startedAt = nil,
    }
    SetRateLimit(src, 'loaded')
    sendToZone(src, assignment.tasks)
    return true
end

--- Assign community service tasks to an online player.
---@param src number Acting officer source
---@param target number Target player source
---@param tasks number Task count
---@return boolean success
---@return string|nil err Locale error key
local function staffAssignTasks(src, target, tasks)
    if getAccessLevel(src) < 2 then
        log('warn', ('Player %s %s'):format(src, 'attempted to assign tasks without access'))
        return false
    end

    if not isInteger(target, 1, 65535) or not isInteger(tasks, 1, Cfg.MaxTasks) then
        log('warn', ('Player %s %s'):format(src, 'submitted an invalid task assignment'))
        return false
    end
    if src == target then return false, 'no_self_assign' end
    if not GetPlayerName(target) then return false, 'player_not_found' end

    local identifier = bridge.framework.getPlayerIdentifier(target)
    if not identifier then
        log('warn', ('Player %s %s'):format(src, ('could not resolve target %s identifier'):format(target)))
        return false
    end
    if assignedTasks[identifier] then return false, 'player_already_assigned' end

    local items, err = confiscateItems(target)
    if not items then return false, err end

    assignedTasks[identifier] = {
        tasks = tasks,
        items = items,
    }
    activePlayers[target] = {
        name = GetPlayerName(target),
        identifier = identifier,
        current = nil,
        startedAt = nil,
    }

    if not cacheTasksToJson() then
        assignedTasks[identifier] = nil
        activePlayers[target] = nil
        if not rollbackItems(target, items) then
            log('error', ('failed to roll back custody for %s after save failure'):format(identifier))
        end
        return false, 'persistence_failed'
    end

    SetRateLimit(target, 'loaded')
    sendToZone(target, tasks)
    logAssignment(src, target, tasks)
    return true
end

--- Remove community service from an online player.
---@param src number Acting officer source
---@param target number Target player source
---@return boolean success
---@return string|nil err Locale error key
local function staffRemoveTasks(src, target)
    if getAccessLevel(src) < 2 then
        log('warn', ('Player %s %s'):format(src, 'attempted to remove tasks without access'))
        return false
    end

    if not isInteger(target, 1, 65535) then
        log('warn', ('Player %s %s'):format(src, 'submitted an invalid task removal target'))
        return false
    end
    if src == target then return false, 'no_self_remove' end

    local runtime = activePlayers[target]
    if not runtime or not assignedTasks[runtime.identifier] then
        return false, 'player_not_found'
    end

    local released, err = releasePlayer(target, runtime.identifier)
    if not released then
        if err then
            TriggerClientEvent('r_bridge:notify', target, locale('community_service'), locale(err), 'error')
        end
        return false, err
    end

    logRemoval(src, target)
    return true
end

lib.callback.register('r_communityservice:getAccessLevel', function(src)
    return getAccessLevel(src)
end)

lib.callback.register('r_communityservice:menuRequest', function(src)
    if IsRateLimited(src, 'menu', STAFF_RATE_LIMIT_MS) then return false end
    SetRateLimit(src, 'menu')
    if not canManage(src) then
        log('warn', ('Player %s %s'):format(src, 'attempted to open the staff menu without access'))
        return false
    end
    return true, getStaffRoster()
end)

lib.callback.register('r_communityservice:requestTask', function(src)
    if IsRateLimited(src, 'request', REQUEST_RATE_LIMIT_MS) then return false end
    SetRateLimit(src, 'request')

    local runtime = activePlayers[src]
    local assignment = runtime and assignedTasks[runtime.identifier]
    if not runtime or not assignment then
        log('warn', ('Player %s %s'):format(src, 'requested a task without an active sentence'))
        return false
    end
    if not isPlayerInsideZone(src) then
        log('warn', ('Player %s %s'):format(src, 'requested a task outside the service zone'))
        return false
    end
    if assignment.tasks <= 0 then
        local released, err = releasePlayer(src, runtime.identifier)
        if not released then return false, err end
        return true, nil, 0, true
    end

    if not runtime.current then
        runtime.current = generateTaskCoords()
        runtime.startedAt = nil
    end
    return true, runtime.current, assignment.tasks, false
end)

lib.callback.register('r_communityservice:startTask', function(src)
    if IsRateLimited(src, 'start', START_RATE_LIMIT_MS) then return false end
    SetRateLimit(src, 'start')

    local runtime = activePlayers[src]
    local assignment = runtime and assignedTasks[runtime.identifier]
    if not runtime or not assignment or not runtime.current then
        log('warn', ('Player %s %s'):format(src, 'attempted to start a task without an issued task'))
        return false
    end
    if not isPlayerInsideZone(src) or not isPlayerNearTask(src, runtime.current) then
        log('warn', ('Player %s %s'):format(src, 'attempted to start a task away from its marker'))
        return false
    end

    runtime.startedAt = GetGameTimer()
    return true
end)

lib.callback.register('r_communityservice:completeTask', function(src)
    if IsRateLimited(src, 'complete', COMPLETE_RATE_LIMIT_MS) then return false end
    SetRateLimit(src, 'complete')

    local runtime = activePlayers[src]
    local assignment = runtime and assignedTasks[runtime.identifier]
    if not runtime or not assignment or not runtime.current or not runtime.startedAt then
        log('warn', ('Player %s %s'):format(src, 'attempted to complete a task without an issued task'))
        return false
    end
    if not isPlayerInsideZone(src) then
        log('warn', ('Player %s %s'):format(src, 'attempted to complete a task outside the service zone'))
        return false
    end
    if not isPlayerNearTask(src, runtime.current) then
        log('warn', ('Player %s %s'):format(src, 'attempted to complete a task away from its marker'))
        return false
    end
    if GetGameTimer() - runtime.startedAt < Cfg.TaskTime * 1000 then
        log('warn', ('Player %s %s'):format(src, 'attempted to complete a task before the required duration'))
        return false
    end

    if assignment.tasks == 1 then
        local released, err = releasePlayer(src, runtime.identifier)
        if not released then return false, err end
        Log(src, 'tasks_finished', {})
        return true, 0, true
    end

    assignment.tasks = assignment.tasks - 1
    runtime.current = nil
    runtime.startedAt = nil
    if not cacheTasksToJson() then
        assignment.tasks = assignment.tasks + 1
        return false, 'persistence_failed'
    end
    return true, assignment.tasks, false
end)

lib.callback.register('r_communityservice:assignTasks', function(src, target, tasks)
    if IsRateLimited(src, 'staff', STAFF_RATE_LIMIT_MS) then return false end
    SetRateLimit(src, 'staff')
    return staffAssignTasks(src, target, tasks)
end)

lib.callback.register('r_communityservice:removeTasks', function(src, target)
    if IsRateLimited(src, 'staff', STAFF_RATE_LIMIT_MS) then return false end
    SetRateLimit(src, 'staff')
    return staffRemoveTasks(src, target)
end)

local function registerCommand()
    lib.addCommand(Cfg.Command, {
        help = locale('command_help'),
    }, function(src)
        if not canManage(src) then return end
        TriggerClientEvent('r_communityservice:openMenu', src)
    end)
end

exports('GetApiVersion', function()
    return API_VERSION
end)

exports('CanManage', function(src)
    src = tonumber(src)
    if not src then return false end
    return canManage(src)
end)

exports('GetMaxTasks', function()
    return Cfg.MaxTasks
end)

exports('GetStaffRoster', function(src)
    src = tonumber(src)
    if not src or not canManage(src) then return nil, 'access_denied' end
    return getStaffRoster()
end)

exports('AssignTasks', function(src, target, tasks)
    src = tonumber(src)
    if not src then return false end
    return staffAssignTasks(src, target, tasks)
end)

exports('RemoveTasks', function(src, target)
    src = tonumber(src)
    if not src then return false end
    return staffRemoveTasks(src, target)
end)

RegisterNetEvent('r_communityservice:playerLoaded', function()
    local src = source
    if activePlayers[src] then return end
    if IsRateLimited(src, 'loaded', RESTORE_RATE_LIMIT_MS) then return end
    SetRateLimit(src, 'loaded')
    hydratePlayer(src)
end)

RegisterNetEvent('r_communityservice:resyncService', function()
    local src = source
    if IsRateLimited(src, 'loaded', RESTORE_RATE_LIMIT_MS) then return end
    local runtime = activePlayers[src]
    local assignment = runtime and assignedTasks[runtime.identifier]
    if not assignment then return end
    SetRateLimit(src, 'loaded')
    sendToZone(src, assignment.tasks)
end)

AddEventHandler('onResourceStart', function(resource)
    if resource ~= RESOURCE_NAME then return end
    fetchTasksFromJson()
    registerCommand()
    SetTimeout(1000, function()
        local players = GetPlayers()
        for i = 1, #players do
            local playerId = tonumber(players[i])
            if playerId then hydratePlayer(playerId) end
        end
    end)
end)

AddEventHandler('playerDropped', function()
    activePlayers[source] = nil
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= RESOURCE_NAME then return end
    cacheTasksToJson()
end)

AddEventHandler('txAdmin:events:serverShuttingDown', function()
    cacheTasksToJson()
end)
