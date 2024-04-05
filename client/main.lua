local onPunishment = false
local tasksLeft = 0
local hole = nil

local function getHole()
    if hole == nil then
        hole = Cfg.Holes[math.random(1, #Cfg.Holes)]
    end
end

local function startPunishment(tasks)
    local initCoords = GetEntityCoords(PlayerPedId())
    onPunishment = true
    tasksLeft = tasks
    SetEntityCoords(PlayerPedId(), Cfg.Center, true, false, false, false)
    TriggerServerEvent('r_communityservice:confiscateInven')
    ClNotify('You have ' .. tasks .. ' holes left to dig!', 'info')
    while onPunishment do
        local digZone = lib.zones.poly({
            points = Cfg.Zone,
            thickness = 100,
            onExit = function()
                SetEntityCoords(PlayerPedId(), Cfg.Center, true, false, false, false)
                ClNotify('You may leave when you complete your tasks.', 'error')
            end,
            debug = Cfg.ZoneDebug
        })
        getHole()
        while hole ~= nil do
            local pCoords = GetEntityCoords(PlayerPedId())
            local mCoords = hole
            local distance = #(mCoords - pCoords)
            DrawMarker(0, hole.x, hole.y, hole.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.75, 0.75, 0.75, 255, 0, 0, 80, true,
                true, 2, false, nil, nil, false)
            if distance <= 1.0 then
                lib.showTextUI('[E] - Start Digging')
                if IsControlJustReleased(0, 38) then
                    local animDict = 'random@burial'
                    local prop = joaat('prop_tool_shovel')
                    lib.requestAnimDict(animDict)
                    lib.requestModel(prop)
                    lib.hideTextUI()
                    local shovel = CreateObject(prop, hole.x, hole.y, hole.z, true, false, false)
                    AttachEntityToEntity(shovel, PlayerPedId(), GetPedBoneIndex(PlayerPedId(), 28422), 0.0, 0.0, 0.24, 0,
                        0, 0.0, true, true, false, true, 1, true)
                    TaskPlayAnim(PlayerPedId(), animDict, 'a_burial', 8.0, 8.0, -1, 1, 1.0, false, false, false)
                    ClProgress(10000)
                    DeleteEntity(shovel)
                    ClearPedTasks(PlayerPedId())
                    tasksLeft = tasksLeft - 1
                    hole = nil
                end
            end
            if distance >= 1.0 then
                lib.hideTextUI()
            end
            Wait(0)
        end
        if tasksLeft == 0 then
            digZone:remove()
            SetEntityCoords(PlayerPedId(), initCoords, true, false, false, false)
            TriggerServerEvent('r_communityservice:returnInven')
            ClNotify('Tasks Fulfilled, you\'re free to go.', 'success')
            onPunishment = false
        end
        Wait(0)
    end
end

RegisterNetEvent('r_communityservice:getData', function(time)
    if not onPunishment then
        startPunishment(time)
    else
        return
    end
end)

RegisterCommand('communityservice', function()
    local admin = lib.callback.await('getAcePerm', false)
    if not admin then return end
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
