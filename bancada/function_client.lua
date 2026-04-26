function loadModel(model)
    local model = model
    local mhash = GetHashKey(model)
    while not HasModelLoaded(mhash) do
        RequestModel(mhash)
        Citizen.Wait(10)
    end
    return mhash
end

function createEntity(model,coord,needed,table,h)
    local mhash = loadModel(model)
    local object = CreateObjectNoOffset(mhash,coord[1],coord[2],coord[3],true,false,false)
    SetEntityAsMissionEntity(object,true,true)
    if needed then
        SetEntityAsNoLongerNeeded(object)
    end
    if table then
        local rotation = h
        if not rotation then
            rotation = GetEntityRotation(mesa)
        end
        PlaceObjectOnGroundProperly(object)
        SetEntityRotation(object,rotation,2,true)
        FreezeEntityPosition(object,true)
    end
    SetEntityAsNoLongerNeeded(object)
    return object, vec3(coord.x,coord.y,coord.z), ObjToNet(object)
end


function createNpc(x,y,z)
    local model = loadModel("g_m_y_ballaorig_01")
    local npc = CreatePed(8,model,x,y,z,GetEntityHeading(PlayerPedId()) - 180,true,false)
    SetPedCanBeTargetted(npc,false)
    SetEntityCanBeDamaged(npc,false)
    SetBlockingOfNonTemporaryEvents(npc,true)
    CanPedInCombatSeeTarget(PlayerPedId(),false)
    SetEntityInvincible(npc,true)
    SetPedCanRagdollFromPlayerImpact(npc,false)
    SetEntityAsNoLongerNeeded(npc)
    return npc
end

function playAnim(ped,dict,anim)
	while not HasAnimDictLoaded(dict) do
        Citizen.Wait(1)
        RequestAnimDict(dict)
    end
    TaskPlayAnim(ped,dict,anim,3.0,-3.0,-1,48,0,0,0,0)
end

-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
Objects = {}
initObjects = {}
-----------------------------------------------------------------------------------------------------------------------------------------
-- OBJECTS:TABLE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("bancada:Table")
AddEventHandler("bancada:Table",function(Table)
	Objects = Table
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- OBJECTS:ADICIONAR
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("bancada:Adicionar")
AddEventHandler("bancada:Adicionar",function(Number,Table)
    Objects[Number] = Table
    Objects[Number].props = {}
    TriggerServerEvent("bancada:Adicionar",Number,Objects[Number])
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- PROPS:ADICIONAR
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("bancada:addProps")
AddEventHandler("bancada:addProps",function(Number,Table)
    if Objects[Number] then 
        Objects[Number].props = Table
    end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- PROPS:REMOVER
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("bancada:remProps")
AddEventHandler("bancada:remProps",function(Number,Table)
    if Objects[Number] then 
        Objects[Number].props = Table
    end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- OBJECTCOORDS
-----------------------------------------------------------------------------------------------------------------------------------------
function targetLabel(x,y,z,Number,item)
	exports["target"]:AddCircleZone("tableDrugs:"..Number,vector3(x,y,z),1.5,{
		name = "tableDrugs:"..Number,
		heading = 3374176
	},{
		shop = Number,
		Distance = 1.5,
		options = {
			{
				event = "bancada:Guardar",
				label = "Guardar",
				tunnel = "server"
			},{
				event = "bancada:open",
				label = "Abrir",
				tunnel = "shop"
			}
		}
	})
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- THREADOBJECTS
-----------------------------------------------------------------------------------------------------------------------------------------
Citizen.CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        if not next(Objects) then goto continue end
        for k, v in pairs(Objects) do
            local distance = #(coords - vector3(v["x"], v["y"], v["z"]))
            if distance <= v["Distance"] then
                if not initObjects[k] then
                    initObjects[k] = {}
                    local mHash = GetHashKey(v["object"])
                    RequestModel(mHash)
                    while not HasModelLoaded(mHash) do
                        Citizen.Wait(1)
                    end
                    if HasModelLoaded(mHash) then
                        targetLabel(v["x"], v["y"], v["z"], k, v["item"])
                        initObjects[k].mainObject = CreateObject(mHash, v["x"], v["y"], v["z"], false, false, false)
                        FreezeEntityPosition(initObjects[k].mainObject, true)
                        SetEntityHeading(initObjects[k].mainObject, v["h"])
                        SetEntityLodDist(initObjects[k].mainObject, 0xFFFF)
                        SetModelAsNoLongerNeeded(mHash)
                    end
                elseif next(v.props) and (not initObjects[k].props or (#initObjects[k].props <= (#v.props <= 1 and #v.props or 1))) then
                    if not initObjects[k].props then
                        initObjects[k].props = {}
                    end
                    local offsetX = 0.3 
                    for i = 1, (#v.props <= 1 and #v.props or 1) do
                        local mHash = GetHashKey("penhashop_mesa_nm_v2")
                        RequestModel(mHash)
                        while not HasModelLoaded(mHash) do
                            Citizen.Wait(1)
                        end
                        if HasModelLoaded(mHash) then
                            local coord
                    
                            if i == 1 then
                                coord = GetOffsetFromEntityInWorldCoords(initObjects[k].mainObject, -0.09, 0.10, 1.0) 
                            else
                                local prevProp = initObjects[k].props[i - 1]
                                coord = GetOffsetFromEntityInWorldCoords(prevProp, offsetX, 0.0, 0.0)
                            end
                    
							if not initObjects[k].props[i] then
                            	initObjects[k].props[i] = CreateObject(mHash, coord.x, coord.y, coord.z, false, false, false)
                            	local rotation = GetEntityRotation(initObjects[k].mainObject)
                            	PlaceObjectOnGroundProperly(initObjects[k].props[i])
                            	SetEntityRotation(initObjects[k].props[i], rotation, 2, true)
                            	FreezeEntityPosition(initObjects[k].props[i], true)
							end
                        end
                    end
				elseif initObjects[k].props and #initObjects[k].props > #v.props then
					for i = #initObjects[k].props,(#v.props+1),-1 do
						DeleteEntity(initObjects[k].props[i])
						initObjects[k].props[i] = nil
					end
                end
            else
                if initObjects[k] then
                    exports["target"]:RemCircleZone("tableDrugs:" .. k)
                    if DoesEntityExist(initObjects[k].mainObject) then
                        DeleteEntity(initObjects[k].mainObject)
                        if initObjects[k].props and next(initObjects[k].props) then
                            for i,props in pairs(initObjects[k].props) do
                                DeleteEntity(props)
                            end
                        end
                        initObjects[k] = nil
                    end
                end
            end
        end
        ::continue::
        Citizen.Wait(1000)
    end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- OBJECTS:REMOVER
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("bancada:Remover")
AddEventHandler("bancada:Remover",function(Number)
    if Objects[Number] then 
        Objects[Number] = nil
        if initObjects[Number] then
            exports["target"]:RemCircleZone("tableDrugs:"..Number)
            if DoesEntityExist(initObjects[Number].mainObject) then
                DeleteEntity(initObjects[Number].mainObject)
                if initObjects[Number].props then 
                    for i,prop in pairs(initObjects[Number].props) do 
                        DeleteEntity(prop)
                    end
                end
                initObjects[Number] = nil
            end
        end
    end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DWTEXT
-----------------------------------------------------------------------------------------------------------------------------------------
function dwText(text,font,x,y,scale,r,g,b,a)
	SetTextFont(font)
	SetTextScale(scale,scale)
	SetTextColour(r,g,b,a)
	SetTextOutline()
	SetTextEntry("STRING")
	AddTextComponentString(text)
	DrawText(x,y)
end