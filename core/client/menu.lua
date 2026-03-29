local inputFields = {
    {
        type = 'number',
        label = locale('server_id'),
        required = true,
        min = 1,
        step = 1
    },
    {
        type = 'number',
        label = locale('tasks'),
        required = true,
        min = 1,
        max = Cfg.MaxTasks,
        step = 1
    }
}

local function removeComms(target)
    local removed, resp = lib.callback.await('r_communityservice:removeComms', false, target)
    if not removed then
        if not resp then
            _error('Failed to remove comms from player ' .. target .. ', check server console for details')
        else
            Core.Interface.notify(locale('community_service'), locale(resp), 'error')
        end
    else
        Core.Interface.notify(locale('community_service'), locale('comms_removed', target), 'success')
        TriggerEvent('r_communityservice:openMenu')
    end
end

local function confirmRemoval(target)
    local dialog = Core.Interface.alertDialog({
        header = locale('remove_comms'),
        content = locale('remove_comms_desc', target),
        centered = true,
        cancel = true
    })
    if dialog ~= 'confirm' then
        Core.Interface.showContext('comms_menu')
    else
        removeComms(target)
    end
end

local function assignComms()
    local input = Core.Interface.inputDialog(locale('assign_comms'), inputFields)
    if not input or #input ~= 2 then return end
    local target = tonumber(input[1])
    local tasks = tonumber(input[2])
    local success, reason = lib.callback.await('r_communityservice:assignComms', false, target, tasks)
    if not success then
        if not reason then
            _error('Failed to assign comms to player ' .. target .. ', check server console for details')
        else
            Core.Interface.notify(locale('community_service'), locale(reason), 'error')
        end
    else
        Core.Interface.notify(locale('community_service'), locale('comms_assigned', target, tasks), 'success')
    end
    TriggerEvent('r_communityservice:openMenu')
end

local function buildMenuOptions(active)
    local options = {}
    table.insert(options, {
        title = locale('assign_comms'),
        icon = 'fas fa-gavel',
        onSelect = assignComms
    })
    if #options == 0 then
        table.insert(options, {
            description = locale('no_active_players'),
            disabled = true
        })
    else
        for id, p in pairs(active) do
            table.insert(options, {
                title = p.name .. ' (' .. id .. ')',
                description = locale('tasks') .. ': ' .. p.tasks .. ' (' .. locale('click_to_remove') .. ')',
                icon = 'fas fa-user',
                onSelect = function()
                    confirmRemoval(id)
                end
            })
        end
    end
    return options
end

RegisterNetEvent('r_communityservice:openMenu', function(active)
    Core.Interface.registerContext({
        id = 'comms_menu',
        title = locale('community_service'),
        options = buildMenuOptions(active)
    })
    Core.Interface.showContext('comms_menu')
end)