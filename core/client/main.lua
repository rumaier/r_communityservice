local zone
local initCoords
local serving = false

RegisterNetEvent('r_communityservice:releaseFromCommunityService', function()
    local heading = GetEntityHeading(cache.ped)
    DoScreenFadeOut(750)
    Wait(800)
    StartPlayerTeleport(cache.playerId, initCoords.x, initCoords.y, initCoords.z, heading, false, true, false)
    Wait(150)
    DoScreenFadeIn(325)
    initCoords = nil
    Core.Interface.notify(_L('noti_title'), _L('comms_complete'), 'success', 5000)
end)

local function taskCommunityService()
    if serving then return end
    serving = true
    local task, resp = nil, nil
    CreateThread(function()
        while serving do
            if not task then
                task, resp = lib.callback.await('r_communityservice:requestTask', false)
                if resp == 'done' then serving = false break end
            end
            if task then
                local playerCoords = GetEntityCoords(cache.ped)
                local distance = #(playerCoords.xy - task.xy)
                local ground, z = GetGroundZFor_3dCoord(task.x, task.y, task.z + 50.0, false)
                if distance > 1.0 then
                    if not Core.Interface.isHelpTextActive() then Core.Interface.showHelpText(_L('task_help')) end
                    if Core.Interface.isTextUiActive() then Core.Interface.hideTextUI() end
                    DrawMarker(2, task.x, task.y, (ground and z or task.z) + 2.5, 0, 0, 0, 0, 180.0, 0, 0.8, 0.8, 0.8, 255, 55, 55, 200, true, true, 2, false, false, false, false)
                elseif distance < 1.0 then
                    if Core.Interface.isHelpTextActive() then Core.Interface.hideHelpText() end
                    if not Core.Interface.isTextUiActive() then Core.Interface.showTextUI(_L('dig_here')) end
                    if IsControlJustReleased(0, 38) then
                        Core.Interface.hideTextUI()
                        if Core.Interface.progress({
                            duration = Cfg.Options.TaskTime * 1000,
                            label = _L('dig_progress'),
                            position = 'bottom',
                            useWhileDead = false,
                            canCancel = false,
                            disable = { move = true, combat = true },
                            anim = { dict = 'random@burial', clip = 'a_burial' },
                            prop = { model = `prop_tool_shovel`, bone = 28422, pos = vec3(0.0, 0.0, 0.24), rot = vec3(0.0, 0.0, 0.0) }
                        }) then
                            task = nil
                            Core.Interface.notify(_L('noti_title'), _L('task_complete', resp), 'success')
                        end
                    end
                end
            end
            Wait(0)
        end
    end)
end

RegisterNetEvent('r_communityservice:teleportToCommunityService', function(tasks)
    local coords = Cfg.Options.ZoneCoords
    local heading = GetEntityHeading(cache.ped)
    initCoords = GetEntityCoords(cache.ped)
    DoScreenFadeOut(750)
    Wait(800)
    StartPlayerTeleport(cache.playerId, coords.x, coords.y, coords.z, heading, false, true, false)
    Wait(150)
    DoScreenFadeIn(325)
    Core.Interface.notify(_L('noti_title'), _L('received_comms', tasks), 'info', 5000)
end)

local function checkCanEnterZone()
    _debug('[^6DEBUG^0] - Attempting to enter community service zone...')
    local accessLevel = lib.callback.await('r_communityservice:getPlayerAccess', false)
    _debug('[^6DEBUG^0] - Player access level: ' .. accessLevel)
    if accessLevel < 1 then
        local behind = GetOffsetFromEntityGivenWorldCoords(cache.ped, 0.0, -5.0, 1.0)
        SetEntityCoords(cache.ped, behind.x, behind.y, behind.z, true, false, false, true)
        Core.Interface.notify(_L('noti_title'), _L('restricted_area'), 'error')
        return
    end
    if accessLevel == 1 then taskCommunityService() end
end

local function checkCanExitZone()
    if serving then
        local coords = Cfg.Options.ZoneCoords
        SetEntityCoords(cache.ped, coords.x, coords.y, coords.z, true, false, false, true)
        Core.Interface.notify(_L('noti_title'), _L('finish_comms'), 'error')
        _debug('[^6DEBUG^0] - Teleported back to zone to finish tasks')
    end
end

function InitializeZone()
    if zone then zone:remove() end
    zone = lib.zones.sphere({
        coords = Cfg.Options.ZoneCoords,
        radius = Cfg.Options.ZoneRadius,
        onEnter = checkCanEnterZone,
        onExit = checkCanExitZone,
        debug = Cfg.Debug,
    })
    _debug('[^6DEBUG^0] - Zone initialized at coords: ' .. zone.coords .. ' with radius: ' .. zone.radius)
end