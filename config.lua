--  _ __  ___ ___  _ __ ___  _ __ ___  _   _ _ __ (_) |_ _   _ ___  ___ _ ____   _(_) ___ ___
-- | '__|/ __/ _ \| '_ ` _ \| '_ ` _ \| | | | '_ \| | __| | | / __|/ _ \ '__\ \ / / |/ __/ _ \
-- | |  | (_| (_) | | | | | | | | | | | |_| | | | | | |_| |_| \__ \  __/ |   \ V /| | (_|  __/
-- |_|___\___\___/|_| |_| |_|_| |_| |_|\__,_|_| |_|_|\__|\__, |___/\___|_|    \_/ |_|\___\___|
--  |_____|                                              |___/
Cfg = {
    -- Server Options
    Notification = 'ox',          -- Determines the notification system. ('default', 'ox', 'custom': can be customized in bridge/"FRAMEWORK")
    Inventory = false,            -- Toggles Inventory system for item confiscation/return. ('ox_inventory', 'custom': can be customized in bridge/inventory, false to disable.)
    Command = 'communityservice', -- Determines the command admins use to access the community service input dialog.

    -- Community Service Options
    MaxTasks = 100, -- The maximum amount of tasks an admin can assign.
    DigTime = 10,   -- Amount of time it takes to dig a single hole.

    -- Dig Site Options
    Zone = { -- PolyZone for the dig site. ALL Z VALUES MUST MATCH
        vec3(1517.38, 2455.64, 45.00),
        vec3(1506.54, 2449.04, 45.00),
        vec3(1468.34, 2423.24, 45.00),
        vec3(1427.48, 2408.62, 45.00),
        vec3(1446.09, 2379.07, 45.00),
        vec3(1456.49, 2377.49, 45.00),
        vec3(1469.50, 2370.92, 45.00),
        vec3(1486.91, 2361.09, 45.00),
        vec3(1501.10, 2358.96, 45.00),
        vec3(1521.51, 2363.13, 45.00),
        vec3(1560.97, 2422.40, 45.00)
    },

    Holes = { -- Holes within dig site, make sure they are inside Polyzone above.
        vec3(1444.08, 2404.12, 52.48),
        vec3(1475.14, 2384.09, 50.40),
        vec3(1517.85, 2370.08, 51.04),
        vec3(1532.10, 2391.01, 47.26),
        vec3(1489.71, 2398.04, 48.98),
        vec3(1465.33, 2417.95, 50.34),
        vec3(1488.62, 2431.65, 48.32),
        vec3(1524.61, 2416.79, 46.10),
        vec3(1546.54, 2408.18, 45.65),
        vec3(1554.39, 2420.35, 45.64),
        vec3(1534.73, 2431.38, 45.70),
        vec3(1515.50, 2448.64, 46.40)
    },

    Center = vec3(1487.30, 2391.14, 49.89), -- Center of zone. This is where players are teleported to.

    ZoneDebug = false                       -- Renders the zone for debug purposes.
}
