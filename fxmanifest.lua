---@diagnostic disable: undefined-global
fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'r_communityservice'
description 'A Simple Player Punishment Script for FiveM'
author 'rumaier'
version '3.2.0'

shared_scripts {
    '@ox_lib/init.lua',
    '@r_bridge/init.lua',
    'core/shared/_util.lua',
    'locales/*.lua',
}

server_scripts {
    'config.lua',
    'core/server/_util.lua',
    'core/server/logs.lua',
    'core/server/main.lua',
}

client_scripts {
    'core/client/_util.lua',
    'core/client/main.lua',
}

dependencies {
    'ox_lib',
    'r_bridge'
}

escrow_ignore {
    'core/server/logs.lua',
    'install/**/*.*',
    'locales/*.*',
    'config.lua'    
}