local HOME_FALLBACK = vec3(464.57, -992.0, 30.69)

local taskZone = nil
local homeCoords = nil
local isServing = false

local function removeTasks(id)
    local success, err = lib.callback.await('r_communityservice:removeTasks', false, id)
    if not success and not err then
        error('Failed to remove tasks from player ' .. id .. ', check server console for more information')
    elseif not success and err then
        bridge.interface.notify(locale('community_service'), locale(err), 'error')
    else
        bridge.interface.notify(locale('community_service'), locale('tasks_removed', id), 'success')
    end
end

local function confirmTaskRemoval(id)
    local resp = bridge.interface.alert({
        header = locale('remove_tasks'),
        content = locale('remove_tasks_confirm', id),
        centered = true,
        cancel = true
    })
    if resp ~= 'confirm' then
        bridge.interface.showContext('comms_menu')
    else
        removeTasks(id)
    end
end

local function assignTasks(target, tasks)
    local success, err = lib.callback.await('r_communityservice:assignTasks', false, target, tasks)
    if not success and not err then
        error('Failed to assign community service tasks to player ' .. target .. ', check server console for more information')
    elseif not success and err then
        bridge.interface.notify(locale('community_service'), locale(err), 'error')
    else
        bridge.interface.notify(locale('community_service'), locale('tasks_assigned', tasks, target), 'success')
    end
    TriggerEvent('r_communityservice:openMenu')
end

local function openAssignInput()
    local resp = bridge.interface.input(locale('assign_tasks'), {
        { type = 'number', label = locale('server_id'), min = 1, step = 1, required = true },
        { type = 'number', label = locale('tasks'),     min = 1, max = Cfg.MaxTasks, step = 1, required = true }
    })
    if not resp or #resp ~= 2 then return end
    assignTasks(tonumber(resp[1]), tonumber(resp[2]))
end

local function buildMenuOptions(data)
    local options = {}
    table.insert(options, { title = locale('assign_tasks'), icon = 'fas fa-plus', onSelect = openAssignInput })
    for id, player in pairs(data) do
        table.insert(options, {
            title = player.name .. ' (' .. id .. ')',
            description = locale('tasks') .. ': ' .. player.tasks .. ' (' .. locale('click_to_remove') .. ')',
            icon = 'fas fa-user',
            onSelect = function()
                confirmTaskRemoval(id)
            end
        })
    end
    if #options == 0 then table.insert(options, { description = locale('no_players'), disabled = true }) end
    return options
end

RegisterNetEvent('r_communityservice:openMenu', function()
    local access, data = lib.callback.await('r_communityservice:menuRequest', false)
    if not access then
        return bridge.interface.notify(locale('community_service'), locale('access_denied'), 'error')
    end
    bridge.interface.registerContext({
        id = 'comms_menu',
        title = locale('community_service'),
        options = buildMenuOptions(data)
    })
    bridge.interface.showContext('comms_menu')
end)

RegisterNetEvent('r_communityservice:release', function()
    isServing = false
    local heading = GetEntityHeading(cache.ped)
    bridge.natives.teleportPlayer(homeCoords or HOME_FALLBACK, heading)
    bridge.interface.notify(locale('community_service'), locale('tasks_completed'), 'success')
    homeCoords = nil
end)

local function getNextTask()
    local task, remaining, err = lib.callback.await('r_communityservice:requestTask', false)
    if not task and err then
        error('Failed to get next task, check server console for more information')
    end
    return task, remaining
end

local function attemptDig()
    return bridge.interface.progress({
        duration = Cfg.TaskTime * 1000,
        label = locale('digging'),
        position = 'bottom',
        useWhileDead = false,
        disable = { move = true, combat = true },
        anim = { dict = 'random@burial', clip = 'a_burial' },
        prop = { model = `prop_tool_shovel`, bone = 28422, pos = vec3(0, 0, 0.24), rot = vec3(0, 0, 0) }
    })
end

local function startTasks()
    isServing = true
    local currentTask, remainingTasks = nil, nil
    CreateThread(function()
        while isServing do
            if currentTask then
                local playerCoords = GetEntityCoords(cache.ped)
                local distance = #(playerCoords.xy - currentTask.xy)
                local foundGround, groundZ = GetGroundZFor_3dCoord(currentTask.x, currentTask.y, currentTask.z + 50.0, false)
                if distance > 1.0 then
                    bridge.interface.showHelpText(locale('move_to_task'), -1)
                    if bridge.interface.isTextUiOpen() then bridge.interface.hideTextUi() end
                    DrawMarker(2, currentTask.x, currentTask.y, (foundGround and groundZ or currentTask.z) + 2.5, 0, 0, 0, 0, 180.0, 0, 0.8, 0.8, 0.8, 255, 55, 55, 200, true, true, 2, false, false, false, false)
                else
                    bridge.interface.clearHelpText()
                    if not bridge.interface.isTextUiOpen() then bridge.interface.showTextUi(locale('dig_here')) end
                    if IsControlJustReleased(0, 38) then
                        bridge.interface.hideTextUi()
                        if attemptDig() then
                            if remainingTasks - 1 > 0 then
                                bridge.interface.notify(locale('community_service'), locale('task_completed', remainingTasks - 1), 'success')
                            end
                            currentTask = nil
                        end
                    end
                end
            else
                currentTask, remainingTasks = getNextTask()
                if not currentTask and remainingTasks == 0 then break end
            end
            Wait(0)
        end
    end)
end

local function onZoneExit()
    local access = lib.callback.await('r_communityservice:getAccessLevel', false)
    if access ~= 1 then return end
    local coords = Cfg.ZoneCoords
    SetEntityCoords(cache.ped, coords.x, coords.y, coords.z, true, false, false, true)
    bridge.interface.notify(locale('community_service'), locale('finish_tasks'), 'error')
end

local function removeFromZone()
    local coords = GetOffsetFromEntityInWorldCoords(cache.ped, 0.0, -5.0, 0.5)
    SetEntityCoords(cache.ped, coords.x, coords.y, coords.z, true, false, false, true)
    bridge.interface.notify(locale('community_service'), locale('restricted_area'), 'error')
end

local function onZoneEnter()
    if isServing then return end
    local access = lib.callback.await('r_communityservice:getAccessLevel', false)
    if access == 0 then
        removeFromZone()
    elseif access == 1 then
        startTasks()
    end
end

RegisterNetEvent('r_communityservice:sendToZone', function(tasks)
    if not taskZone then return end
    local home = GetEntityCoords(cache.ped)
    if not taskZone:contains(home) then
        homeCoords = home
    end
    local coords = Cfg.ZoneCoords
    local heading = GetEntityHeading(cache.ped)
    bridge.natives.teleportPlayer(coords, heading)
    bridge.interface.notify(locale('community_service'), locale('assigned_tasks', tasks), 'info')
end)

local function initTaskZone()
    if taskZone then taskZone:remove() end
    taskZone = lib.zones.sphere({
        coords = Cfg.ZoneCoords,
        radius = Cfg.ZoneRadius,
        debug = Cfg.Debug,
        onEnter = onZoneEnter,
        onExit = onZoneExit,
    })
    _debug('Task zone initialized at: ' .. taskZone.coords)
end

AddEventHandler('r_bridge:playerLoaded', function()
    initTaskZone()
    TriggerServerEvent('r_communityservice:playerLoaded')
end)
