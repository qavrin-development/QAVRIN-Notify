fx_version 'cerulean'
game 'gta5'

author 'QAVRIN Development'
description 'Lightweight, customizable notification system'
version '1.0.0'

ui_page 'html/index.html'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/version_checker.lua'
}

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'html/fonts/*.ttf',
    'html/fonts/OFL.txt'
}