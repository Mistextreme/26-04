------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- CONEXÕES
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
local Tunnel = module("vrp", "lib/Tunnel")
local Proxy = module("vrp", "lib/Proxy")
vRP = Proxy.getInterface("vRP")
vRPS = Tunnel.getInterface("vRP")
Creative = {}
Tunnel.bindInterface("bancada", Creative)
vSERVER = Tunnel.getInterface("bancada")
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- VARIÁVEIS
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
local vendendo = false
local drugs = {}
local tableOpen
local stopSelling = false
local trySellExec = false
local npc
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FUNÇÕES
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("bancada:open")
AddEventHandler("bancada:open", function(number)
    tableOpen = number
    if vSERVER.checkPolice() then
        SendNUIMessage({ action = "openNui", drugs = vSERVER.returnDrugs(tableOpen) })
        SetNuiFocus(true, true)
    end
end)

-- Evento para atualizar a contagem de drogas na interface da bancada
RegisterNetEvent("bancada:attCountInTable", function(drugKey, drugInTable)
    SendNUIMessage({ action = "attCountInTable", drug = drugKey, drugcount = drugInTable })
end)

-- Função para redefinir a venda de drogas
local function resetSellDrugs()
    if DoesEntityExist(npc) then
        DeleteEntity(npc)
    end
    trySellExec = false
    vendendo = false
    stopSelling = false
end

-- Evento para parar a venda de drogas
RegisterNetEvent("bancada:stopSale")
AddEventHandler("bancada:stopSale", function()
    if vendendo or trySellExec then
        stopSelling = true
        vendendo = false
    end
end)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- SISTEMA DE VENDA
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function trySellDrugs()
    if trySellExec or DoesEntityExist(npc) then
        TriggerEvent("Notify", "vermelho", "Aguarde a transação já existente.", 5000)
        return
    end

    trySellExec = true
    local mesa = initObjects[tableOpen]

    if not mesa or not DoesEntityExist(mesa.mainObject) then
        TriggerEvent("Notify", "vermelho", "Não há nenhuma bancada montada!", 5000)
        resetSellDrugs()
        return
    elseif not mesa.props or #mesa.props < 1 then
        TriggerEvent("Notify", "vermelho", "Não há droga suficiente para uma venda na bancada!", 5000)
        resetSellDrugs()
        return
    end

    local ped = PlayerPedId()
    local playercoords = GetEntityCoords(ped)
    local distance = #(playercoords - GetEntityCoords(mesa.mainObject))

    if distance > 5 or IsPedInAnyVehicle(ped) then
        TriggerEvent("Notify", "vermelho", "Você está muito longe da bancada.", 5000)
        resetSellDrugs()
        return
    end

    local mesaCoords = GetEntityCoords(mesa.mainObject)
    local spawnDistance = 10.0
    local spawnX = mesaCoords.x + math.random(-spawnDistance, spawnDistance)
    local spawnY = mesaCoords.y + math.random(-spawnDistance, spawnDistance)
    local spawnZ = mesaCoords.z

    Citizen.CreateThread(function()
        npc = createNpc(spawnX, spawnY, spawnZ + 1)

        local coordToGo = GetEntityCoords(mesa.mainObject)
        TaskGoStraightToCoord(npc, coordToGo, 1.0, -1, GetEntityHeading(mesa.mainObject), 1.0)

        local pedcoords = GetEntityCoords(npc)
        local distanceToMesa = #(pedcoords - coordToGo)
        local timeout = 30000

        while distanceToMesa > 2 do
            if timeout <= 0 then
                TriggerEvent("Notify", "amarelo", "Vendas canceladas por tempo excedido!", 5000)
                resetSellDrugs()
                return
            elseif IsEntityDead(npc) then
                resetSellDrugs()
                return
            elseif stopSelling then
                resetSellDrugs()
                return
            end

            pedcoords = GetEntityCoords(npc)
            distanceToMesa = #(pedcoords - coordToGo)
            timeout = timeout - 1
            Citizen.Wait(0)
        end

        TaskTurnPedToFaceCoord(npc, GetEntityCoords(ped), -1)
        TaskLookAtEntity(npc, ped, -1, 2048, 3)
        Wait(1000)

        if not IsPedInAnyVehicle(ped) and not IsEntityDead(npc) then
            vSERVER.sellDrug(tableOpen)
        end

        if not IsEntityDead(npc) then
            ClearPedTasks(npc)
            TaskGoToCoordAnyMeans(npc, vec3(spawnX, spawnY, spawnZ), 1.0, 0, 0, 786603, 0xbf800000)
            Wait(6000)
            DeleteEntity(npc)
            npc = nil
            Wait(10 * 1000)

            if stopSelling then
                resetSellDrugs()
                return
            end

            trySellExec = false
            trySellDrugs()
        end
    end)
end


-- Verifica periodicamente se o comprador foi morto
Citizen.CreateThread(function()
    while true do
        if npc and vendendo then
            if IsEntityDead(npc) then
                TriggerEvent("Notify", "amarelo", "O comprador foi morto.",5000)
                vendendo = false
                stopSelling = true
                trySellExec = false
                if DoesEntityExist(npc) then
                    DeleteEntity(npc)
                end
            end
        end
        Citizen.Wait(1000)
    end
end)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- CALLBACK
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Callback para iniciar ou parar a venda de drogas
RegisterNUICallback("startSale", function()
    if tableOpen and initObjects[tableOpen] then
        if vendendo then
            stopSelling = true
            TriggerEvent("Notify", "verde", "Vendas canceladas!",5000)
        else
            TriggerEvent("Notify", "verde", "Vendas iniciadas!",5000)
            trySellDrugs()
        end
    end
    vendendo = not vendendo
    SetNuiFocus(false)
end)

-- Callback para fechar a interface da bancada
RegisterNUICallback("closeNui", function()
    SetNuiFocus(false)
end)

-- Callback para adicionar drogas à bancada
RegisterNUICallback("addDrug", function(data)
    if tableOpen and initObjects[tableOpen] then
        if data["dataKey"] then
            vSERVER.AddDrug(data["dataKey"],tableOpen)
        end
    end
end)

-- Callback para remover drogas da bancada
RegisterNUICallback("removeDrug", function(data)
    if tableOpen and initObjects[tableOpen] then
        if data["dataKey"] then
            vSERVER.remDrug(data["dataKey"],tableOpen)
        end
    end
end)

-----------------------------------------------------------------------------------------------------------------------------------------
-- THREADSTART
-----------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
	for Number = 1,#config.LocalCoords do
		local Blip = AddBlipForRadius(config.LocalCoords[Number][1]["x"],config.LocalCoords[Number][1]["y"],config.LocalCoords[Number][1]["z"],config.LocalCoords[Number][4])
		SetBlipAlpha(Blip,config.LocalCoords[Number][2])
		SetBlipColour(Blip,config.LocalCoords[Number][3])
	end
end)