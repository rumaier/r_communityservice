local onPunishment = {} -- { serverId = serverId, identifier = playeridentifier, tasks = integer, items = { item = string, amount = integer } }
local zone = lib.zones.sphere({ coords = Cfg.Zone.coords, radius = Cfg.Zone.radius, debug = Cfg.Debug.zones })

local function generateTaskList(tasks)
    local taskList = {}
    while true do
        local number = function() return math.random(0, (Cfg.Zone.radius - 20) * 2) - (Cfg.Zone.radius - 20) end
        local num1, num2 = number(), number()
        local coords = vec3(Cfg.Zone.coords.x + num1, Cfg.Zone.coords.y + num2, Cfg.Zone.coords.z)
        if zone:contains(coords) then
            table.insert(taskList, coords)
        end
        if #taskList >= tasks then
            return taskList
        end
        Wait(0)
    end
end

lib.callback.register('r_communityservice:antiCombatLog', function(src)
    local src = src or source
    local data = MySQL.query.await('SELECT * FROM `r_communityservice` WHERE `identifier` = @identifier', { ['@identifier'] = Framework.getPlayerIdentifier(src) })
    if not data then return false end
    table.insert(onPunishment, { serverId = src, identifier = Framework.getPlayerIdentifier(src), tasks = data[1].tasks, items = json.decode(data[1].items) })
    MySQL.update.await('DELETE FROM `r_communityservice` WHERE `identifier` = @identifier', { ['@identifier'] = Framework.getPlayerIdentifier(src) })
    SendWebhook('Punishment Re-Issued', '', '', GetPlayerName(src), src, data[1].tasks)
    return true, generateTaskList(data[1].tasks)
end)

lib.callback.register('r_communityservice:getPermissionLevel', function(src)
    local ace, job = IsPlayerAceAllowed(src, 'communityservice'), Framework.getPlayerJob(src)
    debug('[DEBUG] - getPermissionLevel | Job:', job, 'ACE:', ace)
    if ace then return 2 end
    for _, police in pairs(Cfg.Server.policeJobs) do
        if job == police then return 1 end
    end
    return 0
end)

lib.callback.register('r_communityservice:getActivePunishments', function()
    return onPunishment
end)

RegisterNetEvent('r_communityservice:confiscateInventory', function()
    local src = source
    local items = Inventory.getPlayerInventory(src)
    onPunishment[#onPunishment].items = items
    for _, item in pairs(items) do
        if GetResourceState('qb-inventory') == 'started' then
            item.count = item.amount
        end
        Inventory.removePlayerItem(src, item.name, item.count)
    end
    debug('[DEBUG] - confiscateInventory | Confiscated inventory from:', src)
end)

local function returnInventory()
    local src = source
    for _, data in pairs(onPunishment) do
        if tonumber(data.serverId) == tonumber(src) then
            for _, item in pairs(data.items) do
                print(json.encode(item))
                Inventory.givePlayerItem(src, item.name, item.count)
            end
            onPunishment[_].items = {}
            debug('[DEBUG] - returnInventory | Returned inventory to:', src)
            return
        end
    end
end

lib.callback.register('r_communityservice:removeTask', function(src)
    for i, data in pairs(onPunishment) do
        if tonumber(data.serverId) == tonumber(src) then
            onPunishment[i].tasks = onPunishment[i].tasks - 1
            if onPunishment[i].tasks <= 0 then
                returnInventory()
                while #onPunishment[i].items > 0 do Wait(0) end
                table.remove(onPunishment, i)
                return true
            end
            debug('[DEBUG] - removeTask | Removed task from:', src, 'Remaining:', onPunishment[i].tasks)
            return true
        end
    end
    debug('[DEBUG] - removeTask | Task not found:', src)
    return false
end)

lib.callback.register('r_communityservice:checkIfFinished', function(src)
    for _, data in pairs(onPunishment) do
        if tonumber(data.serverId) == tonumber(src) then
            return false
        end
    end
    SendWebhook('Punishment Complete', '', '', GetPlayerName(src), src, '')
    return true
end)

lib.callback.register('r_communityservice:issuePunishment', function(src, target, tasks)
    local ace, job = IsPlayerAceAllowed(src, 'communityservice'), Framework.getPlayerJob(src)
    for _, police in pairs (Cfg.Server.policeJobs) do
        if job == police then
            local taskList = generateTaskList(tasks)
            table.insert(onPunishment, { serverId = target, identifier = Framework.getPlayerIdentifier(target), tasks = tasks, items = {} })
            TriggerClientEvent('r_communityservice:issuePunishment', target, taskList)
            debug('[DEBUG] - issuePunishment | Issued by:', src, 'Target:', target, 'Tasks:', tasks)
            return true
        end
    end
    if not ace then return false end
    local taskList = generateTaskList(tasks)
    table.insert(onPunishment, { serverId = target, identifier = Framework.getPlayerIdentifier(target), tasks = tasks, items = {} })
    TriggerClientEvent('r_communityservice:issuePunishment', target, taskList)
    SendWebhook('Punishment Issued', GetPlayerName(src), src, GetPlayerName(target), target, tasks)
    debug('[DEBUG] - issuePunishment | Issued by:', src, 'Target:', target, 'Tasks:', tasks)
    return true
end)

lib.callback.register('r_communityservice:removePunishment', function(src, target)
    local ace = IsPlayerAceAllowed(src, 'communityservice')
    if not ace then return false end
    for i, data in pairs(onPunishment) do
        if tonumber(data.serverId) == tonumber(target) then
            returnInventory()
            while #onPunishment[i].items > 0 do Wait(0) end
            table.remove(onPunishment, i)
            TriggerClientEvent('r_communityservice:removePunishment', target)
            SendWebhook('Punishment Removed', GetPlayerName(target), src, GetPlayerName(target), target, '')
            debug('[DEBUG] - removePunishment | Removed punishment for:', target)
            return true
        end
    end
    debug('[DEBUG] - removePunishment | Punishment not found:', src)
    return false
end)

function SendWebhook(title, src, ...)
    if not Cfg.Webhook.enabled then return end
    if (type(src) == 'number') then src = Framework.getPlayerIdentifier(src) end
    PerformHttpRequest(Cfg.Webhook.url, function(err, text, headers)
    end, 'POST', json.encode({
        username = GetCurrentResourceName(), 
        avatar_url = 'https://i.ibb.co/z700S5H/square.png', 
        embeds = {
        {
            ["color"] = 0,
            ["title"] = _L('webhook_title', GetCurrentResourceName(), title), 
            ["description"] = _L('webhook_desc', src, ...),
            ["thumbnail"] = {
                url = 'https://i.ibb.co/z700S5H/square.png'
            },
            ["footer"] ={
                ["text"] = os.date("%c"),
            },
        }
    }}), { ['Content-Type']= 'application/json' })
end

function debug(...)
    if Cfg.Debug.prints then
        print(...)
    end
end

AddEventHandler('playerDropped', function(reason)
    local src = source
    for i, data in pairs(onPunishment) do
        if tonumber(data.serverId) == tonumber(src) then
            MySQL.insert.await('INSERT INTO `r_communityservice` (`identifier`, `tasks`, `items`) VALUES (@identifier, @tasks, @items)', { ['@identifier'] = data.identifier, ['@tasks'] = data.tasks, ['@items'] = json.encode(data.items) })
            table.remove(onPunishment, i)
            SendWebhook('Player Left', '', '', GetPlayerName(src), src, data.tasks)
            debug('[DEBUG] - playerDropped | Saved punishment for:', src)
        end
    end
end)

AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() == resourceName) then
        print('------------------------------')
        print(_L('version', GetCurrentResourceName(), GetResourceMetadata(GetCurrentResourceName(), 'version', 0)))
        print(_L('framework', Core.Framework))
        print(_L('inventory', Core.Inventory))
        print(_L('target', Core.Target))
        print('------------------------------')
    end
end)
