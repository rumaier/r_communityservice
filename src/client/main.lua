local onPunishment = false
local initCoords = nil
local taskList = {}
local zone = lib.zones.sphere({ coords = Cfg.Zone.coords, radius = Cfg.Zone.radius, debug = Cfg.Debug.zones,
    onEnter = function() 
        local clearLvl = lib.callback.await('r_communityservice:getPermissionLevel', false)
        debug('[DEBUG] - onEnter | Clearance:', clearLvl, 'Punishment:', onPunishment)
        if clearLvl > 0 then return end
        if onPunishment then return end
        local pCoords = GetEntityCoords(cache.ped)
        local fwdVec = GetEntityForwardVector(cache.ped)
        local ground, z = GetGroundZFor_3dCoord(pCoords.x - (fwdVec.x * 5.0), pCoords.y - (fwdVec.y * 5.0), pCoords.z, false)
        StartPlayerTeleport(cache.playerId, pCoords.x - (fwdVec.x * 5.0), pCoords.y - (fwdVec.y * 5.0), z + 2.0, GetEntityHeading(cache.ped), true, true, true)
        Framework.notify(_L('restricted_area'), 'error')
    end,
    onExit = function() 
        if not onPunishment then return end
        Framework.notify(_L('not_finished'), 'error')
        SetEntityCoordsNoOffset(cache.ped, Cfg.Zone.coords, true, true, false) 
    end
})

local function endPunishment()
    local finished = lib.callback.await('r_communityservice:checkIfFinished', false)
    if not finished then return end
    onPunishment = false
    taskList = {}
    DoScreenFadeOut(750)
    Wait(800)
    StartPlayerTeleport(cache.playerId, initCoords, 0.0, false, true, true)
    Wait(150)
    DoScreenFadeIn(325)
    Framework.notify(_L('finished_comms'), 'success')
end

local function startTaskCounter()
    CreateThread(function()
        while true do
            DrawText2D(4, 0.65, { 255, 255, 255, 255 }, _L('tasks_remaining', #taskList), vec2(0.35, 0.95))
            if #taskList <= 0 then break end
            Wait(0)
        end
    end)
end

local function startPunishment()
    onPunishment = true
    initCoords = GetEntityCoords(cache.ped)
    DoScreenFadeOut(750)
    Wait(800)
    StartPlayerTeleport(cache.playerId, Cfg.Zone.coords, 0.0, false, true, true)
    Wait(150)
    DoScreenFadeIn(325)
    startTaskCounter()
    local compass = CreateProp('prop_ar_arrow_2', Cfg.Zone.coords, false)
    Framework.notify(_L('starting_comms', #taskList), 'success')
    while true do
        if #taskList <= 0 then    
            endPunishment()
            DeleteEntity(compass)
            return
        end
        local task = taskList[#taskList]
        local ground, z = GetGroundZFor_3dCoord(task.x, task.y, task.z + 5.0, false)
        local pCoords = GetEntityCoords(cache.ped)
        local distance = #(pCoords.xy - task.xy)
        SetEntityCoords(compass, pCoords.x, pCoords.y, pCoords.z + 1.0, true, true, true, true)
        SetEntityHeading(compass, GetHeadingFromVector_2d(task.x - pCoords.x, task.y - pCoords.y) + 90.0)
        DrawMarker(2, task.x, task.y, z + 1.0, 0, 0, 0, 0, 180.0, 0, 0.8, 0.8, 0.8, 225, 225, 225, 200, true, true, 2, false, nil, nil, false)
        if distance > 1.5 then
            SetEntityAlpha(compass, 255, false)
            if lib.isTextUIOpen() then lib.hideTextUI() end
            z = GetEntityCoords(cache.ped).z + 1.0
        end
        if distance <= 1.5 then
            SetEntityAlpha(compass, 0, false)
            if not lib.isTextUIOpen() then lib.showTextUI(_L('dig_hole')) end
            if IsControlJustReleased(0, 38) then
                lib.hideTextUI()
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

RegisterNetEvent('r_communityservice:issuePunishment', function(tasks)
    taskList = tasks
    TriggerServerEvent('r_communityservice:confiscateInventory')
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
    -- if tonumber(input[1]) == tonumber(cache.serverId) then return Framework.notify(_L('silly_goose'), 'error') end
    local players = GetActivePlayers()
    for i = 1, #players do
        local serverId = GetPlayerServerId(players[i])
        if tonumber(input[1]) == tonumber(serverId) then
            local issued = lib.callback.await('r_communityservice:issuePunishment', false, input[1], input[2])
            if issued then
                return Framework.notify(_L('comms_given', input[1], input[2]), 'success')
            end
        end
    end
    Framework.notify(_L('player_not_found'), 'error')
end

local function removeCommsDialog(serverId)
    local alert = lib.alertDialog({ header = _L('remove_comms'), content = _L('remove_comms_desc'), centered = true, cancel = true })
    if alert == 'cancel' then lib.showContext('comm_manage_menu') return end
    local removed = lib.callback.await('r_communityservice:removePunishment', false, serverId)
    if not removed then return Framework.notify(_L('unable_to_remove'), 'error') end
    Framework.notify(_L('comms_removed'), 'success')
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
    for _, punishment in pairs(data) do
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

local function openCommunityServiceMenu()
    local clearLvl = lib.callback.await('r_communityservice:getPermissionLevel', false)
    debug('[DEBUG] - openCommunityServiceMenu | Clearance:', clearLvl)
    if clearLvl == 0 then return Framework.notify(_L('permission_denied'), 'error') end
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
    if clearLvl == 2 then
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
    openCommunityServiceMenu()
end, false)

function CombatLogCheck()
    local data, tasks = lib.callback.await('r_communityservice:antiCombatLog', false)
    if not data then return end
    taskList = tasks
    startPunishment()
end

function CreateProp(model, coords, isNetwork)
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(0) end
    local entity = CreateObject(model, coords.x, coords.y, coords.z, isNetwork, false, false)
    SetModelAsNoLongerNeeded(model)
    return entity
end

function DrawText2D(font, scale, color, text, position)
    SetTextFont(font)
    SetTextProportional(1)
    SetTextScale(0.0, scale)
    SetTextColour(color[1], color[2], color[3], color[4])
    SetTextEdge(1, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextEntry("STRING")
    AddTextComponentString(text)   
    DrawText(position.x, position.y)
end

function debug(...)
    if Cfg.Debug.prints then
        print(...)
    end
end

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        lib.hideTextUI()
    end
end)
