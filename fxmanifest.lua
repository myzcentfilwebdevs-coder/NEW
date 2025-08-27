fx_version 'cerulean'
game 'gta5'

name 'qbx_truckerjob'
description 'Advanced Trucker Job with NUI'
author 'Your Name'
version '2.0.0'

shared_scripts {
    '@ox_lib/init.lua'
}

server_scripts {
    '@qbx_core/modules/lib.lua',
    'server/main.lua'
}

client_scripts {
    '@qbx_core/modules/lib.lua',
    'client/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'config/client.lua',
    'config/server.lua',
    'config/shared.lua'
}

lua54 'yes'
use_experimental_fxv2_oal 'yes'

dependencies {
    'qbx_core',
    'ox_lib',
    'ox_target'
}

provide 'qb-truckerjob'