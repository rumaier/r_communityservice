local onPunishment = false
local initCoords = Cfg.Zone.coords
local taskList = {}
local zone = lib.zones.sphere({ coords = Cfg.Zone.coords, radius = Cfg.Zone.radius, debug = Cfg.Debug,
    onEnter = function()
        local permLevel = lib.callback.await('r_communityservice:getPermissionLevel', false)
        debug('[DEBUG] - permLevel:', permLevel, '| onPunishment:', onPunishment)
        if permLevel > 0 or onPunishment then return end
        local offsetCoords = GetOffsetFromEntityInWorldCoords(cache.ped, 0.0, -5.0, 0.0)
        local ground, z = GetGroundZFor_3dCoord(offsetCoords.x, offsetCoords.y, offsetCoords.z, false)
        StartPlayerTeleport(cache.playerId, offsetCoords.x, offsetCoords.y, z, GetEntityHeading(cache.ped), true, true, true)
        Core.Framework.Notify(_L('restricted_area'), 'error')
    end,
    onExit = function()
        if not onPunishment then return end
        local coords = Cfg.Zone.coords
        Core.Framework.Notify(_L('not_finished', 'error'))
        SetEntityCoordsNoOffset(cache.ped, coords.x, coords.y, coords.z, true, true, false)
    end,
})

local function startPunishment()
    onPunishment = true
    initCoords = GetEntityCoords(cache.ped)
    DoScreenFadeOut(750)
    Wait(800)
    StartPlayerTeleport(cache.playerId, Cfg.Zone.coords.x, Cfg.Zone.coords.y, Cfg.Zone.coords.z, 0.0, false, true, true)
    Wait(150)
    DoScreenFadeIn(325)
    Core.Framework.Notify(_L('starting_comms', #taskList), 'success')
    StartWorkTracker()
end

local function endPunishment()
    local finished = lib.callback.await('r_communityservice:checkIfFinished', false)
    if not finished then return end
    onPunishment = false
    taskList = {}
    DoScreenFadeOut(750)
    Wait(800)
    StartPlayerTeleport(cache.playerId, initCoords.x, initCoords.y, initCoords.z, 0.0, false, true, true)
    Wait(150)
    DoScreenFadeIn(325)
    Core.Framework.Notify(_L('finished_comms'), 'success')
end

RegisterNetEvent('r_communityservice:issuePunishment', function(tasks)
    taskList = tasks
    TriggerServerEvent('r_communityservice:confiscateItems')
    startPunishment()
end)

RegisterNetEvent('r_communityservice:removePunishment', function()
    endPunishment()
end)

local function giveCommsDialog()
    local input = lib.inputDialog(_L('give_comms'), {
        { type = 'input',  label = _L('player_id', ''),   required = true },
        { type = 'slider', label = _L('task_amount'), required = true, min = 1, max = Cfg.Tasks.maxTasks, step = 1 },
    })
    if not input then return end
    if tonumber(input[1]) == tonumber(cache.serverId) then return Core.Framework.Notify(_L('silly_goose'), 'error') end
    local players = GetActivePlayers()
    for i = 1, #players do
        local serverId = GetPlayerServerId(players[i])
        if tonumber(input[1]) == tonumber(serverId) then
            local issued = lib.callback.await('r_communityservice:issuePunishment', false, input[1], input[2])
            if issued then
                return Core.Framework.Notify(_L('comms_given', input[1], input[2]), 'success')
            end
        end
    end
    Core.Framework.Notify(_L('player_not_found'), 'error')
end

local function removeCommsDialog(id)
    local alert = lib.alertDialog({ header = _L('remove_comms'), content = _L('remove_comms_desc'), centered = true, cancel = true })
    if alert == 'cancel' then lib.showContext('comm_manage_menu') return end
    local removed = lib.callback.await('r_communityservice:removePunishment', false, id)
    if not removed then return Core.Framework.Notify(_L('unable_to_remove'), 'error') end
    Core.Framework.Notify(_L('comms_removed'), 'success')
end

local function openCommManagementMenu()
    local options = {}
    local data = lib.callback.await('r_communityservice:getActivePunishments', false)
    table.insert(options, {
        title = _L('refresh'),
        icon = 'arrows-rotate',
        onSelect = function()
            openCommManagementMenu()
        end,
    })
    for _, punishment in ipairs(data) do
        table.insert(options, {
            title = _L('player_id', punishment.serverId),
            description = _L('click_to_remove', punishment.tasks),
            icon = 'user',
            onSelect = function()
                removeCommsDialog(punishment.serverId)
            end,
        })
    end
    table.insert(options, {
        title = _L('go_back'),
        icon = 'caret-left',
        onSelect = function()
            lib.showContext('commservice_menu')
        end,
    })
    lib.registerContext({
        id = 'comm_manage_menu',
        title = _L('manage_comms'),
        options = options
    })
    lib.showContext('comm_manage_menu')
end

local function openCommunityServiceMenu(permLevel)
    local options = {
        {
            title = _L('give_comms'),
            description = _L('give_comms_desc'),
            icon = 'gavel',
            onSelect = function()
                giveCommsDialog()
            end,
        },
    }
    if permLevel == 2 then
        table.insert(options, {
            title = _L('manage_comms'),
            description = _L('manage_comms_desc'),
            icon = 'bars-progress',
            onSelect = function()
                openCommManagementMenu()
            end,
        })
    end
    lib.registerContext({
        id = 'commservice_menu',
        title = _L('comm_service'),
        options = options
    })
    lib.showContext('commservice_menu')
end

RegisterCommand('communityservice', function()
    local permLevel = lib.callback.await('r_communityservice:getPermissionLevel', false)
    debug('[DEBUG] - permLevel:', permLevel)
    if permLevel == 0 then return Core.Framework.Notify(_L('permission_denied'), 'error') end
    openCommunityServiceMenu(permLevel)
end, false)

function StartWorkTracker()
    local compass = Core.Natives.CreateProp('prop_ar_arrow_2', Cfg.Zone.coords, false)
    while onPunishment do
        if #taskList == 0 then
            DeleteEntity(compass)
            endPunishment()
            return
        end
        local task = taskList[#taskList]
        local pCoords = GetEntityCoords(cache.ped)
        local distance = #(pCoords.xy - task.xy)
        local ground, z = GetGroundZFor_3dCoord(task.x, task.y, task.z, false)
        SetEntityCoords(compass, pCoords.x, pCoords.y, pCoords.z + 1.0, true, true, true, false)
        SetEntityHeading(compass, GetHeadingFromVector_2d(task.x - pCoords.x, task.y - pCoords.y) + 90.0)
        DrawMarker(2, task.x, task.y, z + 1.0, 0, 0, 0, 0, 180.0, 0, 0.8, 0.8, 0.8, 225, 225, 225, 200, true, true, 2, false, false, false, false)
        if distance > 1.5 then
            SetEntityAlpha(compass, 255, false)
            if Core.Ui.isTextUiOpen() then Core.Ui.HideTextUi() end
            z = GetEntityCoords(cache.ped).z + 1.0
        elseif distance <= 1.5 then
            SetEntityAlpha(compass, 0, false)
            if not Core.Ui.isTextUiOpen() then Core.Ui.ShowTextUi('E', _L('dig_hole')) end
            if IsControlJustReleased(0, 38) then
                Core.Ui.HideTextUi()
                if lib.progressCircle({ duration = Cfg.Tasks.digTime * 1000, label = _L('digging'), position = 'bottom', useWhileDead = false, canCancel = true, disable = { move = true, combat = true }, anim = { dict = 'random@burial', clip = 'a_burial' }, prop = { model = `prop_tool_shovel`, bone = 28422, pos = vec3(0.0, 0.0, 0.24), rot = vec3(0.0, 0.0, 0.0) }, }) then
                    local removed = lib.callback.await('r_communityservice:removeTask', false)
                    if removed then
                        table.remove(taskList, #taskList)
                    end
                end
            end
        end
        Wait(0)
    end
end

function CombatLogCheck()
    local data, tasks = lib.callback.await('r_communityservice:checkCombatLog', false)
    if not data then return end
    taskList = tasks
    startPunishment()
end

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        zone:remove()
        Core.Ui.HideTextUi()
    end
end)