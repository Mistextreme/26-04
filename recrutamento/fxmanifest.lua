--  +--------------------------------------------------------------------------------------------+
--  |  ██████╗ ███████╗██╗  ██╗    ███╗   ██╗███████╗████████╗██╗    ██╗ ██████╗ ██████╗ ██╗  ██╗|
--  | ██╔════╝ ██╔════╝╚██╗██╔╝    ████╗  ██║██╔════╝╚══██╔══╝██║    ██║██╔═══██╗██╔══██╗██║ ██╔╝|
--  | ██║      █████╗   ╚███╔╝     ██╔██╗ ██║█████╗     ██║   ██║ █╗ ██║██║   ██║██████╔╝█████╔╝ |
--  | ██║      ██╔══╝   ██╔██╗     ██║╚██╗██║██╔══╝     ██║   ██║███╗██║██║   ██║██╔══██╗██╔═██╗ |
--  | ╚██████╗ ██║     ██╔╝ ██╗    ██║ ╚████║███████╗   ██║   ╚███╔███╔╝╚██████╔╝██║  ██║██║  ██╗|
--  |  ╚═════╝ ╚═╝     ╚═╝  ╚═╝    ╚═╝  ╚═══╝╚══════╝   ╚═╝    ╚══╝╚══╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝|
--  +--------------------------------------------------------------------------------------------+

-- ACESSE NOSSA COMUNIDADE PARA PEGAR A SENHA NA ABA MAPAS

-- Entre agora no nosso Discord e fique por dentro das novidades que vão turbinar seu servidor!
-- Aprenda, melhore e leve seu RP para outro nível com a nossa comunidade!

-- https://discord.gg/kCnuNkqR2q


fx_version "adamant"
game "gta5"
ui_page_preload 'yes'
ui_page "nui/index.html"
files {
	"nui/**",
}
shared_scripts { 
	"@vrp/lib/utils.lua",
	"lib/*.lua", 
	"config.lua" 
}
client_scripts {
	"@vrp/lib/utils.lua",
	"client/*",
} 
server_script {
	"@vrp/lib/utils.lua",
	"server/*",
}