---@diagnostic disable: undefined-global
fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'r_communityservice'
description 'A Simple Player Punishment Script'
author 'rumaier'
version '3.0.0'

shared_scripts {
  '@ox_lib/init.lua',
  'utils/shared.lua',
  'locales/*.lua',
  'configs/*.lua'
}

server_scripts {
  '@oxmysql/lib/MySQL.lua',
  'utils/server.lua',
  'core/server/*.lua',
}

client_scripts {
  'utils/client.lua',
  'core/client/*.lua',
}

dependencies {
  'ox_lib',
  'r_bridge',
  'oxmysql'
}