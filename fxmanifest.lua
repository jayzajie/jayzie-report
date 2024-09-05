fx_version 'cerulean'
game 'gta5'

-- Metadata
author 'Your Name'
description 'Standalone /report command with ESX Legacy and ox_lib'
version '1.0.0'

-- Shared Scripts (Config)
shared_script {
'@ox_lib/init.lua',
'config.lua',}

-- Client Scripts
client_scripts {
    'client.lua'
}

-- Server Scripts
server_scripts {
    '@mysql-async/lib/MySQL.lua',  -- Jika menggunakan mysql-async
    'server.lua'
}

-- ox_lib dependency untuk menggunakan fungsi notifikasi dan dialog
lua54 'yes'

-- Tentukan apakah menggunakan ox_lib untuk versi 5.x atau lebih tinggi
escrow_ignore {
    'client.lua',
    'server.lua',
    'config.lua'
}
