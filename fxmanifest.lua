fx_version 'cerulean'
game 'gta5'

author 'Your Name'
description 'Modern Bus Job System with Enhanced NUI'
version '2.0.0'

lua54 'yes'

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}

shared_scripts {
    'config.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

dependencies {
    'qb-core',
    'ox_target'
}