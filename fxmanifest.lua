fx_version 'cerulean'
game 'gta5'

description 'ps-hud'
version '2.1.2'

dependencies {
	'ox_lib',
	'qbx_core'
}

shared_scripts {
	'@ox_lib/init.lua',
	'@vanguard_lib/init.lua',
	'@qbx_core/shared/locale.lua',
	'locales/en.lua',
	'locales/*.lua',
	'config.lua',
	'uiconfig.lua'
}

client_script 'client.lua'
server_script 'server.lua'
lua54 'yes'
use_fxv2_oal 'yes'

ui_page 'html/index.html'

files {
	'html/*',
}
