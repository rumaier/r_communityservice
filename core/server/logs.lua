--  _                    
-- | |    ___   __ _ ___ 
-- | |   / _ \ / _` / __|
-- | |__| (_) | (_| \__ \
-- |_____\___/ \__, |___/
--             |___/     
--
local enabled = true -- Enable or disable logging (boolean)
local webhookUrl = ''    -- Webhook URL for logging (string)

function Log(src, action, fields)
    if not enabled or webhookUrl == '' then return end
    local username = src ~= 0 and GetPlayerName(src) or 'Console'
    PerformHttpRequest(webhookUrl, function()
    end, 'POST', json.encode({
        username = GetCurrentResourceName(),
        avatar_url = 'https://cdn.rscripts.store/brand-assets/logo.png',
        embeds = {
            {
                title = locale(action),
                color = 0x2C1B47,
                image = {
                    url = 'https://cdn.rscripts.store/brand-assets/banner.png'
                },
                fields = {
                    { name = locale('server_id'), value = '`' .. src .. '`',      inline = true },
                    { name = locale('username'),  value = '`' .. username .. '`', inline = true },
                    { name = utf8.char(0x200B),   value = utf8.char(0x200B),      inline = true },
                    table.unpack(fields or {})
                },
                footer = { text = GetCurrentResourceName() },
                timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ')
            }
        }
    }), { ['Content-Type'] = 'application/json' })
end