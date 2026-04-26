-- CONEXÕES
local Tunnel = module("vrp", "lib/Tunnel")
local Proxy = module("vrp", "lib/Proxy")

vRP = Proxy.getInterface("vRP")
vRPC = Tunnel.getInterface('vRP')

Creative = {}
Tunnel.bindInterface("bancada", Creative)
vCLIENT = Tunnel.getInterface("bancada")
vKEYBOARD = Tunnel.getInterface("keyboard")
local Objects = {}
bancadas = {}
local ImageUrl = "http://94.23.74.57/inventory/"
local quantidadePolicia = 0
local dinheiro = { -- valor de cada droga (1 qtd)
    ["joint"] = 1400,
    ["meth"] = 1300,
    ["cocaine"] = 1400,
    ["lean"] = 1300,
    ["oxy"] = 1400,
}
local drogas = { -- drogas disponiveis para colocar na bancada
    "joint",
    "meth",
    "cocaine",
    "lean",
    "oxy"
}

function Creative.getBancadas()
    return bancadas
end

function Creative.checkPolice()
	local source = source
	local Passport = vRP.Passport(source)
	if Passport then
        local Service,Total = vRP.NumPermission("Police")
        if Total >= quantidadePolicia then
            return true
        else
            TriggerClientEvent("Notify",source,"amarelo","Contingente indisponível.",5000)
        end
    end
    return false
end

function Creative.getDroga(perm)
    return drogas[perm],itemName(drogas[perm])
end

function Creative.returnDrugs(number)
    local source = source
    local Passport = vRP.Passport(source)
    if Passport then
        if not bancadas[Passport] then
            bancadas[Passport] = {}
            for Index,item in pairs(drogas) do 
                local itemIndexValue = itemIndex(item)
                bancadas[Passport][Index] = {
                    item = item,
                    name = itemName(item),
                    image = itemIndexValue and (ImageUrl..itemIndexValue..".png") or (ImageUrl.."default.png"), -- Verificação adicionada
                    invQtd = vRP.ItemAmount(Passport,item),
                    counnInTable = 0
                }
            end
        else
            for Index,Value in pairs(bancadas[Passport]) do 
                bancadas[Passport][Index]["invQtd"] = vRP.ItemAmount(Passport,Value.item)
            end
        end  
    end
    return bancadas[Passport]
end


function Creative.AddDrug(Index,Number)
    local source = source
    local Passport = vRP.Passport(source)
    if Passport then
        local Drug = bancadas[Passport][tonumber(Index)]["item"]
        local Keyboard = vKEYBOARD.keySingle(source,"Digite a quantidade de "..itemName(Drug).." para ser vendida: ")
        if Keyboard then
            local Amount = parseInt(Keyboard[1])
            if Amount > 0 and bancadas[Passport][Index]["counnInTable"] + Amount <= 200 and vRP.TakeItem(Passport,Drug,Amount,true) then
                bancadas[Passport][Index]["counnInTable"] = bancadas[Passport][Index]["counnInTable"] + Amount
                TriggerClientEvent("bancada:attCountInTable",source,Index,bancadas[Passport][Index]["counnInTable"])
                local table = {}
                for Index,Value in pairs(bancadas[Passport]) do 
                    for i = 1, Value["counnInTable"] do
                        table[#table+1] = Value.item
                    end
                end

                Objects[Number].props = table

                TriggerClientEvent("bancada:addProps",-1,Number,table)
                SendWebhookMessage(config.webhookDrogasAdded,"```prolog\n[ID]: "..Passport.." \n[ADD ITEM]: "..bancadas[Passport][Index]["item"].."\n[QUANTIDADE]:"..Amount.."  "..os.date("\n[Data]: %d/%m/%Y [Hora]: %H:%M:%S").." \r```",source)
            else
                TriggerClientEvent("Notify",source,"amarelo","Quantidade inválida.",5000)
            end
        end
    end
end

function Creative.remDrug(Index,Number)
    local source = source
    local Passport = vRP.Passport(source)
    if Passport then
        local Drug = bancadas[Passport][tonumber(Index)]["item"]
        local Keyboard = vKEYBOARD.keySingle(source,"Digite a quantidade de "..itemName(Drug).." para recolher: ")
        if Keyboard then
            local Amount = parseInt(Keyboard[1])
            if Amount > 0 then
                if bancadas[Passport][Index]["counnInTable"] >= Amount then
                    if vRP.InventoryWeight(Passport) + itemWeight(Drug)*Amount <= vRP.GetWeight(Passport) then
                        bancadas[Passport][Index]["counnInTable"] = bancadas[Passport][Index]["counnInTable"] - Amount
                        vRP.GenerateItem(Passport,Drug,Amount,true)
                        TriggerClientEvent("bancada:attCountInTable",source,Index,bancadas[Passport][Index]["counnInTable"])
                        local table = {}
                        for Index,Value in pairs(bancadas[Passport]) do 
                            for i = 1, Value["counnInTable"] do
                                table[#table+1] = Value.item
                            end
                        end

                        Objects[Number].props = table

                        TriggerClientEvent("bancada:remProps",-1,Number,table)
                        SendWebhookMessage(config.webhookRemove,"```prolog\n[ID]: "..Passport.." \n[REM ITEM]: "..bancadas[Passport][Index]["item"].."\n[QUANTIDADE]:"..Amount.."  "..os.date("\n[Data]: %d/%m/%Y [Hora]: %H:%M:%S").." \r```",source)
                    else
                        TriggerClientEvent("Notify",source,"sucesso","Espaço insuficiente.",5000)
                    end
                else
                    TriggerClientEvent("Notify",source,"amarelo","Não há <b>"..Amount.."x "..itemName(Drug).."</b> na bancada!",5000)
                end
            else
                TriggerClientEvent("Notify",source,"sucesso","Quantidade inválida.",5000)
            end
        end
    end
end

function Creative.callPmesp()
	local source = source
    local Passport = vRP.Passport(source)
    if Passport then
        if math.random(100) >= 70 then
            TriggerEvent("Wanted",source,Passport,300)
            local Coords = GetEntityCoords(GetPlayerPed(source))
            local Service = vRP.NumPermission("Policia")
            for Passports,Sources in pairs(Service) do
                async(function()
                    vRPC.PlaySound(Sources,"ATM_WINDOW","HUD_FRONTEND_DEFAULT_SOUNDSET")
                    TriggerClientEvent("NotifyPush",Sources,{ code = "QRU", title = "Denúncia Anônima", x = Coords["x"], y = Coords["y"], z = Coords["z"], criminal = "Suspeita de tráfico de drogas", time = "Recebido às "..os.date("%H:%M"), blipColor = 16 })
                end)
            end
        end
    end
end

RegisterServerEvent("bancada:Guardar")
AddEventHandler("bancada:Guardar",function(Number)
	local source = source
    local Passport = vRP.Passport(source)
    if Passport then
        if bancadas[Passport] then
            for Index,Value in pairs(bancadas[Passport]) do 
                if Value.counnInTable > 0 then
                    return TriggerClientEvent("Notify",source,"vermelho","existe drogas na bancada",5000)
                end
            end 
            bancadas[Passport] = nil
        end  
        local Ped = GetPlayerPed(source)
        local Coords = GetEntityCoords(Ped)
        SendWebhookMessage(config.webhookExit,"```prolog\n[ID]: "..Passport.." \n[CDS]: "..(json.encode(Coords)).."  "..os.date("\n[Data]: %d/%m/%Y [Hora]: %H:%M:%S").." \r```",source)
        vRP.GenerateItem(Passport,"drugtable",1,true)
        TriggerClientEvent("bancada:Remover",-1,Number)
        Objects[Number] = nil
    end
end)


function Creative.sellDrug(Number)
    local source = source
    local Passport = vRP.Passport(source)
    local Amount,Index = genTransaction(Passport)
    if vRP.Request(source, itemName(bancadas[Passport][Index].item), getRandomMessage()) then
        if bancadas[Passport][Index]["counnInTable"] >= Amount then
            bancadas[Passport][Index]["counnInTable"] = bancadas[Passport][Index]["counnInTable"] - Amount
            local money = dinheiro[bancadas[Passport][Index].item] * Amount
            vRP.GenerateItem(Passport, "dollars2", money)
            local table = {}
            for Index,Value in pairs(bancadas[Passport]) do 
                for i = 1, Value["counnInTable"] do
                    table[#table+1] = Value.item
                end
            end

            Objects[Number].props = table

            TriggerClientEvent("bancada:remProps",-1,Number,table)
            TriggerClientEvent("Notify", source, "verde", "Ta na mão, R$ " .. parseFormat(money) .. " por " .. Amount .. "x " .. itemName(bancadas[Passport][Index].item), 5000)
        else
            TriggerClientEvent("Notify", source, "verde", "Cadê as minhas " .. Amount .. "x " .. itemName(bancadas[Passport][Index].item) .. " no bagulho!", 5000)
        end
    end
end

local Active = {}
function genTransaction(Passport)
    local Amount = math.random(1,10)
    local Index = math.random(#drogas)
    Active[Passport] = os.time() + 3
    while true do
        if bancadas[Passport][Index]["counnInTable"] and bancadas[Passport][Index]["counnInTable"] >= Amount then
            break
        else
            if Active[Passport] and os.time() >= parseInt(Active[Passport]) then
                Active[Passport] = nil
                break
            end
        end
        Amount = math.random(1,4)
        Index = math.random(#drogas)
        Wait(100)
    end
    return Amount,Index
end

-- Tabela de mensagens
Messages = {
    'Eae, meu chapa! Tô em busca daquele conteúdo diferenciado, sabe? Tem a parada da boa pra vender? 👀💨',
    'Oi, boa noite me vê 2 Ck de 20 cria? 🌬️💨',
    'Oba oba, 4 po de 5 família? 🌬️💨',
    'Coe cria bom, tem skank paizão? Me vê 2 ai paizão? 🌬️💨',
    'Parada de 20 pai a forte? 🌬️💨',
    'Matin de 10 mano, me da uma aí? 🌬️💨',
    'cria tem? É quanto? Me da um ai paizão? 🌬️💨',
    'Solta a braba de galo aí pra nois marola no baile mais tarde? 🌬️💨',
    'Me vé uma Droga ai? 🌬️💨',
    'Boa me vé um Chá? 🌬️💨',
    'Tem de 10 padrinho? 🌬️💨',
    'Tem 2 do bom Chefe? 🌬️💨',
    'Tem a braba ai? 🌬️💨',
    'Visão da boca tem droga? 🌬️💨',
    'Fé, droga de 20 cria? 🌬️💨'
}

-- Função para obter uma mensagem aleatória
function getRandomMessage()
    -- Semente do gerador de números aleatórios
    math.randomseed(os.time())
    -- Seleciona um índice aleatório de 1 ao tamanho da tabela Messages
    local randomIndex = math.random(1, #Messages)
    -- Retorna a mensagem aleatória
    return Messages[randomIndex]
end

function SendWebhookMessage(webhook,message,Source)
	if webhook ~= nil and webhook ~= "" then
		PerformHttpRequest(webhook, function(err, text, headers) end, 'POST', json.encode({content = message}), { ['Content-Type'] = 'application/json' })
	end
    if Source then
		TriggerClientEvent("Screenshot",Source,webhook)
	end
end



RegisterServerEvent("bancada:Adicionar")
AddEventHandler("bancada:Adicionar",function(Number,Table)
	Objects[Number] = Table
end)

AddEventHandler("Connect",function(Passport,source)
	TriggerClientEvent("bancada:Table",source,Objects)
end)

exports("canSell",function(source)
--[[     local playercoords = GetEntityCoords(GetPlayerPed(source))
    for i in ipairs(config.LocalCoords) do
        local coords = config.LocalCoords[i][1]
        local distance = #(playercoords - coords)
        if distance <= config.LocalCoords[i][4] then
            return true
        end
    end ]]
    return true
end)