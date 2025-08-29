--                                                _ _                             _
-- _ __  ___ ___  _ __ ___  _ __ ___  _   _ _ __ (_) |_ _   _ ___  ___ _ ____   _(_) ___ ___
-- | '__|/ __/ _ \| '_ ` _ \| '_ ` _ \| | | | '_ \| | __| | | / __|/ _ \ '__\ \ / / |/ __/ _ \
-- | |  | (_| (_) | | | | | | | | | | | |_| | | | | | |_| |_| \__ \  __/ |   \ V /| | (_|  __/
-- |_|___\___\___/|_| |_| |_|_| |_| |_|\__,_|_| |_|_|\__|\__, |___/\___|_|    \_/ |_|\___\___|
--  |_____|                                              |___/
--
--  Need support? Join our Discord server for help: https://discord.gg/rscripts
--
Cfg = {
    --  ___  ___ _ ____   _____ _ __
    -- / __|/ _ \ '__\ \ / / _ \ '__|
    -- \__ \  __/ |   \ V /  __/ |
    -- |___/\___|_|    \_/ \___|_|
    Server = {
        Language = 'en',     -- Resource language ('en': English, 'es': Spanish, 'fr': French, 'de': German, 'pt': Portuguese, 'zh': Chinese)
        VersionCheck = true, -- Version check (true: enabled, false: disabled)
    },
    --              _   _
    --   ___  _ __ | |_(_) ___  _ __  ___
    --  / _ \| '_ \| __| |/ _ \| '_ \/ __|
    -- | (_) | |_) | |_| | (_) | | | \__ \
    --  \___/| .__/ \__|_|\___/|_| |_|___/
    --       |_|
    Options = {
        Command = 'communityservice', -- Command to open the community service menu

        PoliceJobs = {                -- Jobs that can assign tasks
            'police',
            -- 'sheriff',
        },

        ZoneCoords = vec3(1496.70, 2409.15, 48.24), -- Zone coordinates (vector3)
        ZoneRadius = 50.0,                          -- Zone radius (number)

        MaxTasks = 60,                              -- Maximum number of tasks admins/police can assign (number)
        TaskTime = 10,                              -- Time (in seconds) to complete each task (number)

        WebhookEnabled = true,                      -- Enable webhook logging (true: enabled, false: disabled)
        -- Webhook URL can be set in core/server/webhook.lua
    },
    --      _      _
    --   __| | ___| |__  _   _  __ _
    --  / _` |/ _ \ '_ \| | | |/ _` |
    -- | (_| |  __/ |_) | |_| | (_| |
    --  \__,_|\___|_.__/ \__,_|\__, |
    --                         |___/
    Debug = false -- Enable debug prints (true: enabled, false: disabled)
}
