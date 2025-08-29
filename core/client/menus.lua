local function attemptAssignCommunityService(target, tasks)
    local success, reason = lib.callback.await('r_communityservice:assignCommunityService', false, target, tasks)
    if success then 
        Core.Interface.notify(_L('noti_title'), _L('assigned_comms', tasks, target), 'success')
        _debug('[^6DEBUG^0] - Assigned ' .. tasks .. ' tasks to player ID: ' .. target)
    else
        if not reason then
            _debug('[^1ERROR^0] - Failed to assign comms to player ' .. target .. ', check server console for details.')
        else
            Core.Interface.notify(_L('noti_title'), reason, 'error')
        end
    end
end

local function triggerGiveCommsInput()
    _debug('[^6DEBUG^0] - Opening give comms input dialog...')
    local response = Core.Interface.inputDialog(_L('give_comms'), {
        { type = 'number',  label = _L('player_id'),   required = true, min = 1, step = 1 },
        { type = 'number', label = _L('task_amount'), required = true, min = 1, max = Cfg.Options.MaxTasks, step = 1 }
    })
    if not response or #response ~= 2 then _debug('[^1ERROR^0] - Invalid input dialog response') return end
    local target, tasks = tonumber(response[1]), tonumber(response[2])
    -- if target == cache.serverId then Core.Interface.notify(_L('noti_title'), _L('no_self_assign'), 'error') return end
    _debug('[^6DEBUG^0] - Attempting to assign ' .. tasks .. ' tasks to player ID: ' .. target)
    attemptAssignCommunityService(target, tasks)
end

local function attemptRemoveCommunityService(target)
    local success, reason = lib.callback.await('r_communityservice:removeCommunityService', false, target)
    if success then
        Core.Interface.notify(_L('noti_title'), _L('remove_comms', target), 'success')
        _debug('[^6DEBUG^0] - Removed community service from player ID: ' .. target)
        Core.Interface.showContext('comms_manage')
    else
        if not reason then
            _debug('[^1ERROR^0] - Failed to remove comms from player ' .. target .. ', check server console for details.')
        else
            Core.Interface.notify(_L('noti_title'), reason, 'error')
        end
    end
end

local function triggerRemoveCommsConfirmation(target)
    _debug('[^6DEBUG^0] - Opening remove alert dialog...')
    local response = Core.Interface.alertDialog({
        header = _L('remove_comms'),
        content = _L('remove_comms_content'),
        centered = true,
        cancel = true,
    })
    _debug('[^6DEBUG^0] - Remove dialog response: ' .. tostring(response))
    if response == 'confirm' then
        attemptRemoveCommunityService(target)
    elseif response == 'cancel' then
        Core.Interface.showContext('comms_manage')
    end
end

local function openCommunityServiceManagementMenu()
    local options = { { title = _L('refresh'), icon = 'arrows-rotate', onSelect = openCommunityServiceManagementMenu } }
    local assigned = lib.callback.await('r_communityservice:fetchAssignedPlayers', false)
    for _, player in pairs(assigned) do
        table.insert(options, {
            title = player.name .. ' (' .. player.id .. ')',
            description = _L('task_amount') .. ': ' .. player.tasks_remaining .. ' | ' .. _L('click_to_remove'),
            icon = 'user',
            onSelect = function()
                triggerRemoveCommsConfirmation(player.id)
            end
        })
    end
    table.insert(options, { title = _L('go_back'), icon = 'caret-left', onSelect = function() Core.Interface.showContext('comms_menu') end })
    Core.Interface.registerContext({ id = 'comms_manage', title = _L('manage_comms'), options = options })
    _debug('[^6DEBUG^0] - Opening community service management menu...')
    Core.Interface.showContext('comms_manage')
end

local function openCommunityServiceMenu(accessLevel)
    Core.Interface.registerContext({
        id = 'comms_menu',
        title = _L('menu_title'),
        options = {
            {
                title = _L('give_comms'),
                description = _L('give_comms_desc'),
                icon = 'fas fa-gavel',
                onSelect = triggerGiveCommsInput
            },
            {
                title = _L('manage_comms'),
                description = accessLevel < 2 and _L('admins_only') or _L('manage_comms_desc'),
                icon = 'fas fa-clipboard-list',
                disabled = accessLevel < 2,
                onSelect = openCommunityServiceManagementMenu
            }
        }
    })
    _debug('[^6DEBUG^0] - Opening community service menu...')
    Core.Interface.showContext('comms_menu')
end

RegisterNetEvent('r_communityservice:openMenu', function()
    local accessLevel = lib.callback.await('r_communityservice:getPlayerAccess', false)
    if accessLevel < 2 then Core.Interface.notify(_L('noti_title'), _L('no_access'), 'error') return end
    openCommunityServiceMenu(accessLevel)
end)