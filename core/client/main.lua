local zone = nil
local home = nil
local serving = false
local fallbackHome = vec3(464.57, -992.0, 30.69)

local function teleportPlayer(coords, heading)
    DoScreenFadeOut(750)
    Wait(800)
    StartPlayerTeleport(cache.playerId, coords.x, coords.y, coords.z, heading, false, true, false)
    Wait(200)
    DoScreenFadeIn(325)
end

local function digProgress()
    local duration = Cfg.TaskTime * 1000
    return Core.Interface.progress({
        duration = duration,
        label = locale('digging'),
        position = 'bottom',
        useWhileDead = false,
        canCancel = false,
        disable = {
            move = true,
            combat = true
        },
        anim = {
            dict = 'random@burial',
            clip = 'a_burial'
        },
        prop = {
            model = `prop_tool_shovel`,
            pos = vec3(0, 0, 0.24),
            rot = vec3(0, 0, 0),
            bone = 28422
        }
    })
end

RegisterNetEvent('r_communityservice:release', function()
    serving = false
    local heading = GetEntityHeading(cache.ped)
    teleportPlayer(home or fallbackHome, heading)
    home = nil
    Core.Interface.notify(locale('community_service'), locale('comms_complete'), 'success')
end)

local function getNextTask()
    local task, err = lib.callback.await('r_communityservice:requestTask')
    if not task then
        serving = false
    end
    if err then
        _error('Failed to get next task, check server console for details')
    end
    return task
end

local function startCommunityService()
    serving = true
    local task = nil
    CreateThread(function()
        while serving do
            if task then
                local coords = GetEntityCoords(cache.ped)
                local dist = #(coords.xy - task.xy)
                local ground, z = GetGroundZFor_3dCoord(task.x, task.y, task.z + 50.0, false)
                if dist > 1.0 then
                    if not Core.Interface.isHelpTextActive() then
                        Core.Interface.hideHelpText()
                    end
                    if Core.Interface.isTextUiActive() then
                        Core.Interface.hideTextUI()
                    end
                    DrawMarker(2, task.xy.x, task.xy.y, (ground and z or task.z) + 2.5, 0, 0, 0, 0, 180.0, 0, 0.8, 0.8, 0.8, 255, 55, 55, 200, true, true, 2, false, false, false, false)
                else
                    if Core.Interface.isHelpTextActive() then
                        Core.Interface.hideHelpText()
                    end
                    if not Core.Interface.isTextUiActive() then
                        Core.Interface.showTextUI(locale('dig_here'))
                    end
                    if IsControlJustReleased(0, 38) then
                        Core.Interface.hideTextUI()
                        if digProgress() then
                            Core.Interface.notify(locale('community_service'), locale('task_complete'), 'success')
                            task = nil
                        end
                    end
                end
            end
            if not task then
                task = getNextTask()
                if not task then break end
            end
            Wait(0)
        end
    end)
end

RegisterNetEvent('r_communityservice:sendToZone', function(tasks)
    local init = GetEntityCoords(cache.ped)
    if not zone:contains(init) then
        home = init
    end
    local coords = Cfg.ZoneCoords
    local heading = GetEntityHeading(cache.ped)
    teleportPlayer(coords, heading)
    Core.Interface.notify(locale('community_service'), locale('assigned_comms', tasks))
end)

local function canEnterZone()
    if serving then return end
    local permission = lib.callback.await('r_communityservice:getPermissionLevel')
    if permission == 0 then
        local behind = GetOffsetFromEntityInWorldCoords(cache.ped, 0.0, -5.0, 0.5)
        SetEntityCoords(cache.ped, behind.x, behind.y, behind.z, true, false, false, true)
        Core.Interface.notify(locale('community_service'), locale('restricted_area'), 'error')
    end
    if permission == 1 then
        startCommunityService()
    end
end

local function canExitZone()
    local permission = lib.callback.await('r_communityservice:getPermissionLevel')
    if permission ~= 1 then return end
    local coords = Cfg.ZoneCoords
    SetEntityCoords(cache.ped, coords.x, coords.y, coords.z, true, false, false, true)
    Core.Interface.notify(locale('community_service'), locale('not_finished'), 'error')
end

function Initialize()
    if zone then
        zone:remove()
    end
    zone = lib.zones.sphere({
        coords = Cfg.ZoneCoords,
        radius = Cfg.ZoneRadius,
        onEnter = canEnterZone,
        onExit = canExitZone,
        debug = Cfg.Debug
    })
    TriggerServerEvent('r_communityservice:relog')
end