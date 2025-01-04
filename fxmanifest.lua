---@diagnostic disable: undefined-global
fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'r_communityservice'
description 'A simple player punishment resource.'
author 'r_scripts'
version '2.0.6'

shared_scripts {
    '@ox_lib/init.lua',
    'utils/shared.lua',
    'locales/*.lua',
    'config.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'utils/server.lua',
    'src/server/*.lua',
}

client_scripts {
    'utils/client.lua',
    'src/client/*.lua',
}

dependencies {
    'ox_lib',
    'oxmysql',
    'r_bridge'
}
crow_ignore {
    'install/**/*.*',
    'locales/*.*',
    'config.*' 
}