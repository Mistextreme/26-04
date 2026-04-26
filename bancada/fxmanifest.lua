fx_version 'bodacious'
game "gta5"

client_scripts {
	"@vrp/config/Native.lua",
	"@vrp/lib/utils.lua",
	"shared.lua",
	"function_client.lua",
	"client.lua"
}

server_script {
	"@vrp/config/Item.lua",
	"@vrp/lib/utils.lua",
	"shared.lua",
	"server.lua"
}

files {
    'web-side/*.*',
    'web-side/**/*',
}

ui_page 'web-side/index.html'

data_file 'DLC_ITYP_REQUEST' 'stream/*.ytyp'

files {
    'stream/*.ydr',
    'stream/*.ytd',
    'stream/*.ytyp'
}
