--  _ __  ___ ___  _ __ ___  _ __ ___  _   _ _ __ (_) |_ _   _ ___  ___ _ ____   _(_) ___ ___
-- | '__|/ __/ _ \| '_ ` _ \| '_ ` _ \| | | | '_ \| | __| | | / __|/ _ \ '__\ \ / / |/ __/ _ \
-- | |  | (_| (_) | | | | | | | | | | | |_| | | | | | |_| |_| \__ \  __/ |   \ V /| | (_|  __/
-- |_|___\___\___/|_| |_| |_|_| |_| |_|\__,_|_| |_|_|\__|\__, |___/\___|_|    \_/ |_|\___\___|
--  |_____|                                              |___/
Cfg = {
    -- Server Options
    Notification = 'ox', -- Determines the notification system. ('default', 'ox', 'custom': can be customized in bridge/"FRAMEWORK")
    Inventory = 'ox_inventory',    -- Toggles Inventory system for item confiscation/return. ('false', 'ox_inventory', 'custom': can be customized in bridge/inventory)
    
    -- Permissions Settings
    Command = 'communityservice',

    -- Community Service Options
    MaxTasks = 100, -- The maximum amount of tasks an admin can assign.

    -- Dig Site Options
    Zone = { -- PolyZone for the dig site. ALL Z VALUES MUST MATCH
        vec3(1510.3481445312, 2532.5766601562, 45.00), -- Shrink this before commit
        vec3(1420.6053466797, 2513.828125, 45.00),
        vec3(1432.2758789062, 2489.79296875, 45.00),
        vec3(1436.6235351562, 2452.9248046875, 45.00),
        vec3(1430.6436767578, 2403.8044433594, 45.00),
        vec3(1488.2258300781, 2359.7680664062, 45.00),
        vec3(1502.0706787109, 2352.6254882812, 45.00),
        vec3(1526.4932861328, 2363.490234375, 45.00),
        vec3(1575.7255859375, 2356.6762695312, 45.00),
        vec3(1602.0556640625, 2360.2722167969, 45.00),
        vec3(1627.8560791016, 2380.1638183594, 45.00),
        vec3(1534.9692382812, 2436.7224121094, 45.00),
        vec3(1516.3009033203, 2457.0541992188, 45.00)
    },

    Holes = { -- Holes within dig site, make sure they are inside Polyzone above.
        vec3(1590.4312, 2375.9036, 47.3764), -- Fix these before commit
        vec3(1560.4543, 2370.1694, 49.4815),
        vec3(1539.8328, 2405.6838, 46.0635),
        vec3(1520.4351, 2437.2800, 45.4366),
        vec3(1477.1300, 2399.7283, 49.4219),
        vec3(1448.6594, 2386.7498, 52.2334),
        vec3(1441.9659, 2419.7773, 54.2941),
        vec3(1454.0981, 2451.9968, 53.1939),
        vec3(1462.3070, 2495.9768, 46.5007),
        vec3(1492.0315, 2469.6206, 46.9719)
    },

    Center = vec3(1472.8463, 2416.7720, 49.2630), -- Center of zone. This is where players are teleported to. 

    ZoneDebug = false -- Renders the zone for debug purposes. 
}
