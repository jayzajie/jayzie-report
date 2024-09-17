fx_version 'cerulean'
game 'gta5'

author 'jayzie-report'
description 'Standalone /report command with ESX Legacy and ox_lib'
version '1.0.0'

shared_script {
'@ox_lib/init.lua',
'config.lua',}

-- Client Scripts
client_scripts {
    'client.lua'
}

-- Server Scripts
server_scripts {
    '@mysql-async/lib/MySQL.lua', 
    'server.lua'
}

lua54 'yes'

escrow_ignore {
    'client.lua',
    'server.lua',
    'config.lua'
}
