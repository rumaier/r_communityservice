CommsCache = {}
local serving = {}
local zone = lib.zones.sphere({ coords = Cfg.Options.ZoneCoords, radius = Cfg.Options.ZoneRadius })

lib.callback.register('r_communityservice:runPlayerRelogCheck', function(src)
    local identifier = Core.Framework.getPlayerIdentifier(src)
    if not identifier then _debug('[^1ERROR^0] - Could not fetch identifier for player ID: ' .. src) return false end
    local data = CommsCache[identifier]
    if not data then _debug('[^1ERROR^0] - No community service record found for player ID: ' .. src) return false end
    serving[src] = true
    return true, data.tasks_remaining
end)

local function confiscateInventory(src)
    local items = Core.Inventory.getPlayerInventory(src) or {}
    for _, item in pairs(items) do
        local removed = Core.Inventory.removeItem(src, item.name, item.count)
        if not removed then _debug('[^1ERROR^0] - Failed to remove item: ' .. item.name .. ' from player: ' .. src) return false end
    end
    return items
end

local function returnInventory(src, items)
    for _, item in pairs(items) do
        local added = Core.Inventory.addItem(src, item.name, item.count, item.metadata)
        if not added then _debug('[^1ERROR^0] - Failed to return item: ' .. item.name .. ' to player: ' .. src) return false end
    end
    return true
end

local function getPlayerAccess(src)
    local access = 0
    local ace = IsPlayerAceAllowed(src, 'communityservice')
    local job = Core.Framework.getPlayerJob(src)
    local policeJobs = Cfg.Options.PoliceJobs
    _debug('[^6DEBUG^0] - Checking access for ' .. src ..' | Ace: ' .. tostring(ace) .. ' | Job: ' .. tostring(job.name))
    if serving[src] then return 1 end
    if lib.table.contains(policeJobs, job.name) then access = 2 end
    if ace then access = 3 end
    return access
end

lib.callback.register('r_communityservice:getPlayerAccess', getPlayerAccess)

local function releasePlayer(src, identifier)
    local inventory = CommsCache[identifier] and CommsCache[identifier].stored_items or {}
    local invReturned = returnInventory(src, inventory)
    if not invReturned then _debug('[^1ERROR^0] - Failed to return inventory to player ID: ' .. src) return false, 'sv_err' end
    local deleted = MySQL.query.await('DELETE FROM r_communityservice WHERE identifier = ?', { identifier })
    if not deleted then _debug('[^1ERROR^0] - Failed to delete database record for player ID: ' .. src) return false, 'sv_err' end
    CommsCache[identifier] = nil
    if Cfg.Options.WebhookEnabled then --[[ //TODO: implement webhook  ]] end
    _debug('[^6DEBUG^0] - Releasing player: ' .. src .. ' from community service.')
    TriggerClientEvent('r_communityservice:releaseFromCommunityService', src)
    serving[src] = nil
    return false, 'done'
end

lib.callback.register('r_communityservice:requestTask', function(src)
    local identifier = Core.Framework.getPlayerIdentifier(src)
    if not identifier then _debug('[^1ERROR^0] - Could not fetch identifier for player ID: ' .. src) return false, 'sv_err' end
    local data = CommsCache[identifier]
    if not data then _debug('[^1ERROR^0] - No community service record found for player ID: ' .. src) return false, 'sv_err' end
    if type(serving[src]) == 'vector3' then
        _debug('[^6DEBUG^0] - Distance checking player '.. src ..' at task location: ' .. tostring(serving[src]))
        local player = GetPlayerPed(src)
        local playerCoords = GetEntityCoords(player)
        local dist = #(playerCoords.xy - serving[src].xy)
        if dist > 2.0 then _debug('[^1ERROR^0] - Player: ' .. src .. ' is too far from their task location. Distance: ' .. dist) return false, 'sv_err' end
    end
    if data.tasks_remaining == 0 then return releasePlayer(src, identifier) end
    data.tasks_remaining = data.tasks_remaining - 1
    local updated = MySQL.update.await([[
        UPDATE r_communityservice
        SET tasks_remaining = tasks_remaining - 1
        WHERE identifier = ? AND tasks_remaining > 0;
    ]], { identifier })
    if updated == 0 then _debug('[^1ERROR^0] - Failed to update database for player ID: ' .. src) return false, 'sv_err' end
    local radius = (zone.radius or Cfg.Options.ZoneRadius) - 5.0
    repeat
        serving[src] = vec3(zone.coords.x + math.random(-radius, radius), zone.coords.y + math.random(-radius, radius), zone.coords.z)
        Wait(100)
    until zone:contains(serving[src])
    _debug('[^6DEBUG^0] - Sending coords: ' .. serving[src] .. ' to player: ' .. src)
    return serving[src], data.tasks_remaining
end)

lib.callback.register('r_communityservice:assignCommunityService', function(src, target, tasks)
    local access = getPlayerAccess(src)
    if access < 2 then _debug('[^1ERROR^0] - Player '.. src ..' insufficient perms to assign comms') return false end
    local identifier = Core.Framework.getPlayerIdentifier(target)
    if not identifier then return false, _L('player_not_found', target) end
    local inventory = confiscateInventory(target)
    if not inventory then _debug('[^1ERROR^0] - Failed to confiscate inventory from player ID: ' .. target) return false end
    local inserted = MySQL.insert.await([[
        INSERT INTO r_communityservice (identifier, tasks_remaining, stored_items)
        VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE tasks_remaining = VALUES(tasks_remaining), stored_items = VALUES(stored_items)
    ]], { identifier, tasks, json.encode(inventory) })
    if not inserted then _debug('[^1ERROR^0] - Failed to insert/update database for player ID: ' .. target) return false end
    CommsCache[identifier] = { identifier = identifier, tasks_remaining = tasks, stored_items = inventory }
    if Cfg.Options.WebhookEnabled then --[[ //TODO: implement webhook  ]] end
    _debug('[^6DEBUG^0] - Assigned ' .. tasks .. ' tasks to ID: ' .. target ..', sending player...')
    TriggerClientEvent('r_communityservice:teleportToCommunityService', target, tasks)
    serving[target] = true
    return true
end)

lib.callback.register('r_communityservice:removeCommunityService', function(src, target)
    local access = getPlayerAccess(src)
    if access < 2 then _debug('[^1ERROR^0] - Player '.. src ..' insufficient perms to remove comms') return false end
    local identifier = Core.Framework.getPlayerIdentifier(target)
    if not identifier then return false, _L('player_not_found', target) end
    local deleted = MySQL.query.await('DELETE FROM r_communityservice WHERE identifier = ?', { identifier })
    if not deleted then _debug('[^1ERROR^0] - Failed to delete database record for player ID: ' .. target) return false end
    CommsCache[identifier] = nil
    if Cfg.Options.WebhookEnabled then --[[ //TODO: implement webhook  ]] end
    _debug('[^6DEBUG^0] - Removed comms from ID: ' .. target ..', releasing player...')
    TriggerClientEvent('r_communityservice:releaseFromCommunityService', target)
    serving[target] = nil
    return true
end)

lib.callback.register('r_communityservice:fetchAssignedPlayers', function(src)
    local active = {}
    for id, _ in pairs(serving) do
        local identifier = Core.Framework.getPlayerIdentifier(id)
        if not identifier then _debug('[^1ERROR^0] - Could not fetch identifier for player ID: ' .. id) return end
        local data = CommsCache[identifier]
        if data then table.insert(active, { id = id, name = GetPlayerName(id), tasks_remaining = data.tasks_remaining }) end
    end
    _debug('[^6DEBUG^0] - Fetched ' .. #active .. ' active assigned players from cache.')
    return active
end)

local function cacheDatabase()
    repeat Wait(0) until DatabaseBuilt
    local data = MySQL.query.await('SELECT * FROM r_communityservice')
    for _, row in pairs(data) do
        CommsCache[row.identifier] = {
            identifier = row.identifier,
            tasks_remaining = row.tasks_remaining,
            stored_items = json.decode(row.stored_items)
        }
    end
    _debug('[^6DEBUG^0] - Cached ' .. #data .. ' community service records from database.')
end

local function syncDatabase()
    local synced = 0
    for identifier, entry in pairs(CommsCache) do
        local updated = MySQL.update.await([[
            UPDATE r_communityservice
            SET tasks_remaining = ?, stored_items = ?
            WHERE identifier = ?;
        ]], { entry.tasks_remaining, json.encode(entry.stored_items), identifier })
        if updated and updated > 0 then
            synced = synced + 1
        else
            _debug('[^1ERROR^0] - Failed to sync database for identifier: ' .. identifier)
        end
    end
    _debug('[^6DEBUG^0] - Synced ' .. synced .. ' community service records to database.')
end

AddEventHandler('txAdmin:events:serverShuttingDown', syncDatabase)

local function registerInteractCommand()
    local commandName = Cfg.Options.Command
    _debug('[^6DEBUG^0] - Registering command: /' .. commandName)
    lib.addCommand(commandName, {
        help = _L('command_help')
    }, function(src)
        TriggerClientEvent('r_communityservice:openMenu', src)
    end)
end

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    registerInteractCommand()
    cacheDatabase()
end)

AddEventHandler('playerDropped', function()
    local src = source
    if serving[src] then
        local identifier = Core.Framework.getPlayerIdentifier(src)
        local data = CommsCache[identifier]
        data.tasks_remaining = data.tasks_remaining + 1
        serving[src] = nil
        _debug('[^6DEBUG^0] - Player ' .. src .. ' dropped while serving, incremented current task.')
        syncDatabase()
    end
end)