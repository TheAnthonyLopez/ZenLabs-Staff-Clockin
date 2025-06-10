fx_version 'cerulean'
games { 'gta5' }

author 'Anthony @ ZenLabs Development'
description 'Staff Clockin with AFK Timer/Automatic AFK Clockout.'
version '1.5.0'
lua54 'yes'

dependency 'ox_lib'

shared_script 'config.lua'

shared_scripts {
  "config.lua",
  "@ox_lib/init.lua",
  "functions.lua"
}

client_scripts {
	'client.lua'
}

server_scripts {
	'server.lua'
}
