local HOME_FALLBACK = vec3(464.57, -992.0, 30.69)
local RESTORE_RETRY_MS = 2100

local taskZone = nil
local homeCoords = nil
local isServing = false
local serviceGeneration = 0
local teleportingToZone = false
local clientInitialized = false

local function removeTasks(id)
    local success, err = lib.callback.await('r_communityservice:removeTasks', false, id)
    if not success then
        if err then bridge.interface.notify(locale('community_service'), locale(err), 'error') end
        return
    end
    bridge.interface.notify(locale('community_service'), locale('tasks_removed', id), 'success')
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
    if not success then
        if err then bridge.interface.notify(locale('community_service'), locale(err), 'error') end
        return
    end
    bridge.interface.notify(locale('community_service'), locale('tasks_assigned', tasks, target), 'success')
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
    options[#options + 1] = { title = locale('assign_tasks'), icon = 'fas fa-plus', onSelect = openAssignInput }
    for i = 1, #data do
        local player = data[i]
        options[#options + 1] = {
            title = player.name .. ' (' .. player.id .. ')',
            description = locale('tasks') .. ': ' .. player.tasks .. ' (' .. locale('click_to_remove') .. ')',
            icon = 'fas fa-user',
            onSelect = function()
                confirmTaskRemoval(player.id)
            end
        }
    end
    if #data == 0 then
        options[#options + 1] = { description = locale('no_players'), disabled = true }
    end
    return options
end

RegisterNetEvent('r_communityservice:openMenu', function()
    local access, data = lib.callback.await('r_communityservice:menuRequest', false)
    if not access then return end
    bridge.interface.registerContext({
        id = 'comms_menu',
        title = locale('community_service'),
        options = buildMenuOptions(data)
    })
    bridge.interface.showContext('comms_menu')
end)

local function clearServiceUi()
    bridge.interface.hideTextUi()
    bridge.interface.clearHelpText()
end

local function stopTasks()
    serviceGeneration = serviceGeneration + 1
    isServing = false
    clearServiceUi()
end

RegisterNetEvent('r_communityservice:release', function()
    stopTasks()
    local heading = GetEntityHeading(cache.ped)
    bridge.natives.teleportPlayer(homeCoords or HOME_FALLBACK, heading)
    bridge.interface.notify(locale('community_service'), locale('tasks_completed'), 'success')
    homeCoords = nil
end)

local function toTaskCoords(task)
    if not task or not task.x or not task.y or not task.z then return end
    return vec3(task.x + 0.0, task.y + 0.0, task.z + 0.0)
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

local function restartTasksWhenReady()
    CreateThread(function()
        while IsEntityDead(cache.ped) do Wait(500) end
        Wait(RESTORE_RETRY_MS)
        local access = lib.callback.await('r_communityservice:getAccessLevel', false)
        if access == 1 then
            TriggerServerEvent('r_communityservice:resyncService')
        end
    end)
end

local function startTasks()
    if isServing then return end
    isServing = true
    serviceGeneration = serviceGeneration + 1
    local generation = serviceGeneration
    local currentTask, remainingTasks = nil, nil

    CreateThread(function()
        while isServing and generation == serviceGeneration do
            if not teleportingToZone and IsEntityDead(cache.ped) then
                stopTasks()
                restartTasksWhenReady()
                return
            end

            if not currentTask then
                local success, taskOrErr, remaining, done = lib.callback.await('r_communityservice:requestTask', false)
                if generation ~= serviceGeneration then return end
                if not success then
                    if taskOrErr then
                        bridge.interface.notify(locale('community_service'), locale(taskOrErr), 'error')
                        stopTasks()
                        return
                    end
                    Wait(500)
                elseif done then
                    return
                else
                    currentTask = toTaskCoords(taskOrErr)
                    remainingTasks = remaining
                    if not currentTask then
                        Wait(500)
                    end
                end
            else
                local playerCoords = GetEntityCoords(cache.ped)
                local distance = #(playerCoords.xy - currentTask.xy)
                local foundGround, groundZ = GetGroundZFor_3dCoord(
                    currentTask.x,
                    currentTask.y,
                    currentTask.z + 50.0,
                    false
                )
                ---@diagnostic disable-next-line: param-type-mismatch
                DrawMarker( 2, currentTask.x, currentTask.y, (foundGround and groundZ or currentTask.z) + 2.5, 0, 0, 0, 0, 180.0, 0, 0.8, 0.8, 0.8, 255, 55, 55, 200, true, true, 2, false, nil, nil, false)

                if distance > 1.0 then
                    bridge.interface.showHelpText(locale('move_to_task'), -1)
                    if bridge.interface.isTextUiOpen() then bridge.interface.hideTextUi() end
                else
                    bridge.interface.clearHelpText()
                    if not bridge.interface.isTextUiOpen() then
                        bridge.interface.showTextUi(locale('dig_here'))
                    end
                    if IsControlJustReleased(0, 38) then
                        bridge.interface.hideTextUi()
                        local started = lib.callback.await('r_communityservice:startTask', false)
                        if started and attemptDig() and generation == serviceGeneration then
                            local completed, remainingOrErr, finished =
                                lib.callback.await('r_communityservice:completeTask', false)
                            if generation ~= serviceGeneration then return end
                            if not completed then
                                if remainingOrErr then
                                    bridge.interface.notify(
                                        locale('community_service'),
                                        locale(remainingOrErr),
                                        'error'
                                    )
                                end
                                Wait(1000)
                            elseif finished then
                                stopTasks()
                                return
                            else
                                remainingTasks = remainingOrErr
                                bridge.interface.notify(
                                    locale('community_service'),
                                    locale('task_completed', remainingTasks),
                                    'success'
                                )
                                currentTask = nil
                            end
                        end
                    end
                end
                Wait(0)
            end
        end
        clearServiceUi()
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
    if isServing or teleportingToZone then return end
    local access = lib.callback.await('r_communityservice:getAccessLevel', false)
    if access == 0 then
        removeFromZone()
    elseif access == 1 then
        startTasks()
    end
end

local function initTaskZone()
    if taskZone or not Cfg.ZoneCoords or not Cfg.ZoneRadius then return end
    taskZone = lib.zones.sphere({
        coords = Cfg.ZoneCoords,
        radius = Cfg.ZoneRadius,
        debug = Cfg.Debug,
        onEnter = onZoneEnter,
        onExit = onZoneExit,
    })
    log('debug','Task zone initialized at: ' .. taskZone.coords)
end

RegisterNetEvent('r_communityservice:sendToZone', function(tasks)
    initTaskZone()
    local home = GetEntityCoords(cache.ped)
    if #(home - Cfg.ZoneCoords) > Cfg.ZoneRadius then
        homeCoords = home
    end
    local coords = Cfg.ZoneCoords
    local heading = GetEntityHeading(cache.ped)
    teleportingToZone = true
    bridge.natives.teleportPlayer(coords, heading)
    while IsPlayerTeleportActive() do Wait(0) end
    teleportingToZone = false
    bridge.interface.notify(locale('community_service'), locale('assigned_tasks', tasks), 'info')
    CreateThread(function()
        Wait(0)
        if isServing or teleportingToZone then return end
        local access = lib.callback.await('r_communityservice:getAccessLevel', false)
        if access == 1 then startTasks() end
    end)
end)

local function initialize()
    if clientInitialized or not Cfg.ZoneCoords or not Cfg.ZoneRadius then return end
    clientInitialized = true
    initTaskZone()
    TriggerServerEvent('r_communityservice:playerLoaded')
end

local function tryInitialize()
    if not bridge.framework.isPlayerLoaded() then return end
    initialize()
end

AddEventHandler('r_bridge:playerLoaded', tryInitialize)
AddEventHandler('r_communityservice:clientConfigLoaded', tryInitialize)

AddEventHandler('onClientResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    tryInitialize()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    stopTasks()
    if taskZone then
        taskZone:remove()
        taskZone = nil
    end
end)
