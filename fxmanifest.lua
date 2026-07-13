---@diagnostic disable: undefined-global
fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'r_communityservice'
description 'A Simple Player Punishment Script'
author 'rumaier'
version '3.2.0'

shared_scripts {
    '@ox_lib/init.lua',
    '@r_bridge/init.lua',
    'core/shared/*.lua',
    'locales/*.lua',
    'config.lua',
}

server_scripts {
    'core/server/*.lua',
}

client_scripts {
    'core/client/*.lua',
}

dependencies {
    'r_bridge'
}

escrow_ignore {
    'core/server/logs.lua',
    'install/**/*.*',
    'locales/*.*',
    'config.lua'    
}