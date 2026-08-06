--                                                _ _                             _
-- _ __  ___ ___  _ __ ___  _ __ ___  _   _ _ __ (_) |_ _   _ ___  ___ _ ____   _(_) ___ ___
-- | '__|/ __/ _ \| '_ ` _ \| '_ ` _ \| | | | '_ \| | __| | | / __|/ _ \ '__\ \ / / |/ __/ _ \
-- | |  | (_| (_) | | | | | | | | | | | |_| | | | | | |_| |_| \__ \  __/ |   \ V /| | (_|  __/
-- |_|___\___\___/|_| |_| |_|_| |_| |_|\__,_|_| |_|_|\__|\__, |___/\___|_|    \_/ |_|\___\___|
--  |_____|                                              |___/
--
--  Need support? Join our Discord server for help: https://discord.gg/TR38cZFdQk
--
Cfg = {}

Cfg.Language = 'en'     -- Languages: 'en': English, 'es': Spanish, 'fr': French, 'de': German, 'pt': Portuguese, 'zh': Chinese
Cfg.VersionCheck = true -- Intermittent version checking (boolean)
Cfg.Debug = true        -- Debug prints, not recommended for live servers (boolean)

Cfg.Command = 'communityservice' -- Command to open the community service menu (string)
Cfg.AllowedJobs = {              -- List of jobs that can use the menu
    'police',
    -- 'sheriff'
}
-- To allow server staff, add the ACE permission to your server.cfg:
-- add_ace group.admin "r_communityservice" allow

Cfg.ZoneCoords = vec3(1496.70, 2409.15, 48.24) -- Coordinates for the community service zone (vector3)
Cfg.ZoneRadius = 50.0                          -- Radius of the community service zone (float)

Cfg.MaxTasks = 60 -- Maximum number of community service tasks a player can be assigned (number)
Cfg.TaskTime = 10 -- Time in seconds it takes to complete a task (number)