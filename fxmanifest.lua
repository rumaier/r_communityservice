---@diagnostic disable: undefined-global
fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'r_'
description 'A Simple '
author 'r_scripts'
version '1.0.3'

shared_scripts {
    '@es_extended/imports.lua',
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'bridge/**/client.lua',
    'client/*.lua',
}

server_scripts {
    'bridge/**/server.lua',
    'server/*.lua',
}

dependencies {
    'ox_lib',
}