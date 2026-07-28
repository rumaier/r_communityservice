Cfg = Cfg or {}

local function loadClientConfig()
    local config
    for attempt = 1, 10 do
        local success, response = pcall(lib.callback.await, 'r_communityservice:getClientConfig', false)
        if success and type(response) == 'table' then
            config = response
            break
        end
        Wait(attempt * 250)
    end
    if not config then
        log('warn', 'Failed to load client config; retrying in the background')
        CreateThread(function()
            while true do
                Wait(1000)
                local success, response = pcall(lib.callback.await, 'r_communityservice:getClientConfig', false)
                if success and type(response) == 'table' then
                    for key, value in pairs(response) do
                        Cfg[key] = value
                    end
                    return
                end
            end
        end)
        return
    end
    for key, value in pairs(config) do
        Cfg[key] = value
    end
end

loadClientConfig()
