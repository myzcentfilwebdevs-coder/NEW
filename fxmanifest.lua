fx_version 'cerulean'
game 'gta5'

name 'Modern Bus Job System'
description 'Enhanced Bus Job System with Modern NUI Interface and Improved Dropoff Detection'
version '2.0.0'
author 'YourName'

lua54 'yes'

shared_scripts {
    'config/client.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
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