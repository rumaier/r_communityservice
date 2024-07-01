--                                                _ _                             _
-- _ __  ___ ___  _ __ ___  _ __ ___  _   _ _ __ (_) |_ _   _ ___  ___ _ ____   _(_) ___ ___
-- | '__|/ __/ _ \| '_ ` _ \| '_ ` _ \| | | | '_ \| | __| | | / __|/ _ \ '__\ \ / / |/ __/ _ \
-- | |  | (_| (_) | | | | | | | | | | | |_| | | | | | |_| |_| \__ \  __/ |   \ V /| | (_|  __/
-- |_|___\___\___/|_| |_| |_|_| |_| |_|\__,_|_| |_|_|\__|\__, |___/\___|_|    \_/ |_|\___\___|
--  |_____|                                              |___/

Cfg = {
    --  ___  ___ _ ____   _____ _ __
    -- / __|/ _ \ '__\ \ / / _ \ '__|
    -- \__ \  __/ |   \ V /  __/ |
    -- |___/\___|_|    \_/ \___|_|
    Server = {
        language = 'en',          -- Determines the language. ('en': English, 'es': Spanish, 'fr': French, 'de': German, 'pt': Portuguese, 'zh': Chinese)
        notification = 'default', -- Determines the notification system. ('default', 'ox', 'custom': can be customized in bridge/framework/YOURFRAMEWORK)
        policeJobs = {            -- Determines the police jobs, you can add as many as you need.
            'police',
            -- 'sheriff',
        },
    },
    --  _______  _ __   ___
    -- |_  / _ \| '_ \ / _ \
    --  / / (_) | | | |  __/
    -- /___\___/|_| |_|\___|
    Zone = {
        coords = vec3(1493.966, 2405.158, 48.644), -- Determines the center of the dig area.
        radius = 55,                               -- Determines the radius of the dig area. DO NOT SET BELOW 25.
    },
    --  _            _
    -- | |_ __ _ ___| | _____
    -- | __/ _` / __| |/ / __|
    -- | || (_| \__ \   <\__ \
    --  \__\__,_|___/_|\_\___/
    Tasks = {
        maxTasks = 60, -- Determines the maximum amount of tasks that can be assigned to a player.
        digTime = 10,  -- Determines the time it takes to dig a hole.
    },
    --               _     _                 _
    -- __      _____| |__ | |__   ___   ___ | | __
    -- \ \ /\ / / _ \ '_ \| '_ \ / _ \ / _ \| |/ /
    --  \ V  V /  __/ |_) | | | | (_) | (_) |   <
    --   \_/\_/ \___|_.__/|_| |_|\___/ \___/|_|\_\
    Webhook = {
        enabled = true,         -- Enables Discord Webhook.
        url = 'INSERT_WEBHOOK', -- Your Discord Webhook URL.
    },
    --      _      _
    --   __| | ___| |__  _   _  __ _
    --  / _` |/ _ \ '_ \| | | |/ _` |
    -- | (_| |  __/ |_) | |_| | (_| |
    --  \__,_|\___|_.__/ \__,_|\__, |
    --                         |___/
    Debug = {
        prints = false,  -- Enables debug prints, not recommended for production.
        targets = false, -- Enables debug targets, not recommended for production.
        zones = false,   -- Enables debug zones, not recommended for production.
    }
}
