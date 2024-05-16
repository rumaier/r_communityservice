local onPunishment = false
local tasksLeft = 0
local initCoords = nil
local digZone = nil
local hole = { current = nil, last = nil }

local function getHole()
    while hole.current == nil do
        local roll = Cfg.Holes[math.random(1, #Cfg.Holes)]
        if roll ~= hole.last then
            hole.current = roll
            break
        end
    end
end

local function endPunishment()
    if not onPunishment then return end
    local playerId = cache.playerId
    DoScreenFadeOut(750)
    Wait(800)
    StartPlayerTeleport(playerId, initCoords.x, initCoords.y, (initCoords.z + 1.0), 0, false, true, true)
    Wait(150)
    DoScreenFadeIn(375)
    TriggerServerEvent('r_communityservice:returnInven')
    ClNotify('Tasks Fulfilled, you\'re free to go.', 'success')
    hole = { current = nil, last = nil }
    tasksLeft = 0
    onPunishment = false
end

local function startPunishment(tasks)
    local player = cache.ped
    initCoords = GetEntityCoords(player)
    onPunishment = true
    tasksLeft = tasks
    DoScreenFadeOut(750)
    Wait(800)
    SetEntityCoords(player, Cfg.Center, true, false, false, false)
    Wait(150)
    DoScreenFadeIn(375)
    TriggerServerEvent('r_communityservice:confiscateInven')
    ClNotify('You have been assigned '.. tasksLeft.. ' tasks!', 'info')
    while onPunishment do
        digZone = lib.zones.poly({
            points = Cfg.Zone,
            thickness = 100,
            onExit = function()
                if tasksLeft > 0 then
                    SetEntityCoords(player, hole.current, true, false, false, false)
                    ClNotify('You may leave when you complete your tasks.', 'error')
                end
            end,
            debug = Cfg.ZoneDebug
        })
        getHole()
        while hole.current ~= nil do
            local pCoords = GetEntityCoords(player)
            local mCoords = hole.current
            local distance = #(mCoords - pCoords)
            DrawMarker(0, hole.current.x, hole.current.y, hole.current.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.75, 0.75, 0.75, 255, 0, 0, 80, true, true, 2, false, nil, nil, false)
            if distance <= 1.0 then
                lib.showTextUI('[E] - Start Digging')
                if IsControlJustReleased(0, 38) then
                    local animDict = 'random@burial'
                    local prop = joaat('prop_tool_shovel')
                    lib.requestAnimDict(animDict)
                    lib.requestModel(prop)
                    lib.hideTextUI()
                    local shovel = CreateObject(prop, hole.current.x, hole.current.y, hole.current.z, true, false, false)
                    AttachEntityToEntity(shovel, player, GetPedBoneIndex(player, 28422), 0.0, 0.0, 0.24, 0, 0, 0.0, true, true, false, true, 1, true)
                    TaskPlayAnim(player, animDict, 'a_burial', 8.0, 8.0, -1, 1, 1.0, false, false, false)
                    ClProgress('Digging Hole...', (Cfg.DigTime * 1000))
                    DeleteEntity(shovel)
                    ClearPedTasks(player)
                    tasksLeft = tasksLeft - 1
                    if tasksLeft > 0 then
                        ClNotify(''.. tasksLeft.. ' more to go!', 'info')
                    end
                    hole.last = hole.current
                    hole.current = nil
                end
            end
            if distance >= 1.0 then
                lib.hideTextUI()
            end
            Wait(0)
        end
        if tasksLeft == 0 then
            digZone:remove()
            Wait(100)
            endPunishment()
        end
        Wait(0)
    end
end

RegisterNetEvent('r_communityservice:getData', function(time)
    if not onPunishment then return startPunishment(time) end
end)

RegisterNetEvent('r_communityservice:endPunishment', function()
    if not onPunishment then return end
    endPunishment()
end)

RegisterCommand('communityservice', function()
    local permission = lib.callback.await('r_communityservice:Perm', false)
    if not permission then return end

    local input = lib.inputDialog('Community Service', {
        { type = 'input',  label = 'Player ID:', required = true },                              -- input[1]
        { type = 'number', label = 'Tasks:',     required = true, min = 0, max = Cfg.MaxTasks }, -- input[2]
    })
    if not input then return end
    local alert = lib.alertDialog({
        header = 'Community Service',
        content = 'Give ID #' .. input[1] .. ' ' .. input[2] .. ' tasks?',
        centered = true,
        cancel = true
    })
    if alert == 'confirm' then
        TriggerServerEvent("r_communityservice:passData", input[1], input[2])
        ClNotify('Player ID #' .. input[1] .. ' was given ' .. input[2] .. ' tasks.', 'info')
    else
        return
    end
end, false)

RegisterCommand('endcommunityservice', function()
    local admin = lib.callback.await('r_communityservice:Perm', false)
    if not admin then return end
    local input = lib.inputDialog('End Community Service', {
        { type = 'input',  label = 'Player ID:', required = true },
    })
    if not input then return end
    TriggerServerEvent('r_communityservice:endPunishment', input[1])
end, false)
