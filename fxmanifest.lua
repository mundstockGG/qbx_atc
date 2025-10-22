fx_version 'cerulean'
game 'gta5'

name 'qbx_atc'
author 'mundstock'
description 'Air Traffic Control job for qbx_core with ox_target'
version '1.1.0'
lua54 'yes'

dependencies {
  'qbx_core',   -- https://github.com/Qbox-project/qbx_core
  'ox_lib',     -- https://github.com/overextended/ox_lib
  'ox_target'   -- https://github.com/overextended/ox_target
}

shared_scripts {
  '@ox_lib/init.lua',
  'config.lua'
}

client_scripts {
  'client.lua'
}

server_scripts {
  '@oxmysql/lib/MySQL.lua', -- (optional; not used in v1)
  'server.lua'
}

ui_page 'html/index.html'

files {
  'html/index.html',
  'html/style.css',
  'html/app.js'
}
