fx_version 'cerulean'
games { 'gta5' }

author 'AP Code'
description 'Auto Shoot'

shared_script 'config.lua'

client_scripts {
    '@ox_lib/init.lua',
    'client/client.lua'
}

server_scripts {
    'server/server.lua'
}

files {
    'data/vehicles_list.json',
    'data/photographed_history.json'
}
