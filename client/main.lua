local config = require 'config.client'
local sharedConfig = require 'config.shared'

-- State variables
local currentZones = {}
local currentLocation = {}
local currentBlip = 0
local hasBox = false
local truckVehBlip = 0
local truckerBlip = 0
local returningToStation = false
local returningToDepot = false
local currentPlate
local jobActive = false
local deliveryTimeout = 0
local npcPed = nil
local npcSpawned = false
local rentalNpcPed = nil
local rentalNpcSpawned = false
local totalDeliveries = 0
local completedDeliveries = 0
local waitingForNextDelivery = false
local driverNPC = nil
local locations = {}
local isDelivering = false

-- NUI Management
local nuiOpen = false

-- Cache frequently accessed values
local PlayerData = QBX.PlayerData or {}
local PlayerJob = PlayerData.job or {}

-- Cached native functions
local GetEntityCoords = GetEntityCoords
local GetVehicleDoorAngleRatio = GetVehicleDoorAngleRatio
local GetOffsetFromEntityInWorldCoords = GetOffsetFromEntityInWorldCoords
local DoesBlipExist = DoesBlipExist
local RemoveBlip = RemoveBlip
local AddBlipForCoord = AddBlipForCoord
local SetBlipRoute = SetBlipRoute
local ClearAllBlipRoutes = ClearAllBlipRoutes
local SetBlipColour = SetBlipColour
local SetBlipRouteColour = SetBlipRouteColour
local SetBlipSprite = SetBlipSprite
local SetBlipDisplay = SetBlipDisplay
local SetBlipScale = SetBlipScale
local SetBlipAsShortRange = SetBlipAsShortRange
local BeginTextCommandSetBlipName = BeginTextCommandSetBlipName
local AddTextComponentSubstringPlayerName = AddTextComponentSubstringPlayerName
local EndTextCommandSetBlipName = EndTextCommandSetBlipName
local GetVehiclePedIsIn = GetVehiclePedIsIn
local NetToVeh = NetToVeh
local GetEntityModel = GetEntityModel
local DeleteVehicle = DeleteVehicle
local SetVehicleEngineOn = SetVehicleEngineOn
local ClearPedTasks = ClearPedTasks
local CreatePed = CreatePed
local GetHashKey = GetHashKey
local SetVehicleDoorOpen = SetVehicleDoorOpen
local TaskVehicleDriveToCoord = TaskVehicleDriveToCoord
local SetPedIntoVehicle = SetPedIntoVehicle
local IsPedInVehicle = IsPedInVehicle
local NetworkRequestControlOfEntity = NetworkRequestControlOfEntity
local SetEntityAsMissionEntity = SetEntityAsMissionEntity
local DeleteEntity = DeleteEntity
local DoesEntityExist = DoesEntityExist
local IsModelValid = IsModelValid
local GetPlayerServerId = GetPlayerServerId
local PlayerId = PlayerId
local IsPedInAnyVehicle = IsPedInAnyVehicle
local GetClosestVehicle = GetClosestVehicle
local GetVehicleNumberPlateText = GetVehicleNumberPlateText
local GetPedInVehicleSeat = GetPedInVehicleSeat
local PlayerPedId = PlayerPedId

-- Pre-calculate locale strings
local localeStrings = {
    error_no_driver = "You need to be the driver to return the vehicle",
    error_vehicle_not_correct = "This is not the correct vehicle",
    error_backdoors_not_open = "Back doors are not open",
    error_too_far_from_trunk = "Too far from trunk",
    error_cancelled = "Action cancelled",
    error_get_out_vehicle = "Get out of the vehicle first",
    error_too_far_from_delivery = "Too far from delivery point",
    error_vehicle_already_out = "Vehicle already out",
    info_pickup_paycheck = "Pickup Paycheck",
    info_store_vehicle = "Store Vehicle",
    info_vehicles = "Vehicles",
    info_deliver_to_store = "Deliver to store",
    mission_job_completed = "Job completed",
    mission_store_reached = "Store reached",
    mission_another_box = "Another box",
    mission_return_to_station = "Return to station",
    mission_goto_next_point = "Go to next point",
    menu_header = "Delivery Services",
    npc_talk = "Talk to Manager",
    npc_name = "Delivery Coordinator",
    grab_box = "Grab Box",
    deliver_box = "Deliver Box",
    return_vehicle = "Return Vehicle"
}

-- NUI Functions
local function openTruckerNUI()
    if nuiOpen then return end
    
    local playerData = QBX.PlayerData or {}
    local money = 0
    
    if playerData.money then
        money = (playerData.money.cash or 0) + (playerData.money.bank or 0)
    end
    
    local vehicles = {}
    if sharedConfig.vehicles then
        for modelHash, vehicleName in pairs(sharedConfig.vehicles) do
            table.insert(vehicles, {
                name = vehicleName,
                model = modelHash,
                price = 500,
                capacity = "Medium",
                efficiency = "Good",
                durability = "High"
            })
        end
    end
    
    SetNuiFocus(true, true)
    nuiOpen = true
    
    SendNUIMessage({
        action = "openNUI",
        data = {
            playerData = {
                money = money,
                completedDeliveries = completedDeliveries,
                totalDeliveries = totalDeliveries
            },
            vehicles = vehicles,
            jobStatus = {
                active = jobActive,
                currentLocation = currentLocation,
                completedDeliveries = completedDeliveries,
                totalDeliveries = totalDeliveries
            }
        }
    })
end

local function closeTruckerNUI()
    if not nuiOpen then return end
    
    SetNuiFocus(false, false)
    nuiOpen = false
    
    SendNUIMessage({
        action = "closeNUI"
    })
end

local function updateNUIJobStatus()
    if not nuiOpen then return end
    
    SendNUIMessage({
        action = "updateJobStatus",
        data = {
            active = jobActive,
            currentLocation = currentLocation,
            completedDeliveries = completedDeliveries,
            totalDeliveries = totalDeliveries
        }
    })
end

local function updateNUIDeliveryProgress()
    if not nuiOpen then return end
    
    SendNUIMessage({
        action = "updateDeliveryProgress",
        data = {
            currentLocation = currentLocation,
            completedDeliveries = completedDeliveries,
            totalDeliveries = totalDeliveries
        }
    })
end

-- NUI Callbacks
RegisterNUICallback('closeNUI', function(data, cb)
    closeTruckerNUI()
    cb('ok')
end)

RegisterNUICallback('getVehicles', function(data, cb)
    local vehicles = {}
    if sharedConfig.vehicles then
        for modelHash, vehicleName in pairs(sharedConfig.vehicles) do
            table.insert(vehicles, {
                name = vehicleName,
                model = modelHash,
                price = 500,
                capacity = "Medium",
                efficiency = "Good",
                durability = "High"
            })
        end
    end
    
    SendNUIMessage({
        action = "updateVehicles",
        data = vehicles
    })
    cb('ok')
end)

RegisterNUICallback('rentVehicle', function(data, cb)
    if jobActive then
        SendNUIMessage({
            action = "showNotification",
            message = localeStrings.error_vehicle_already_out,
            type = "error"
        })
        cb('error')
        return
    end
    
    TriggerEvent('qbx_truckerjob:client:spawnVehicle', data.vehicleModel)
    cb('ok')
end)

RegisterNUICallback('getJobInfo', function(data, cb)
    updateNUIJobStatus()
    cb('ok')
end)

RegisterNUICallback('returnVehicle', function(data, cb)
    returnVehicle()
    cb('ok')
end)

RegisterNUICallback('collectPaycheck', function(data, cb)
    getPaid()
    cb('ok')
end)

RegisterNUICallback('getStatistics', function(data, cb)
    local stats = {
        totalBoxes = completedDeliveries * 3,
        totalEarned = completedDeliveries * 250,
        totalTime = 0,
        totalTrips = completedDeliveries
    }
    
    SendNUIMessage({
        action = "updateStats",
        data = stats
    })
    cb('ok')
end)

RegisterNUICallback('updateSettings', function(data, cb)
    debugPrint("Settings updated:", json.encode(data))
    cb('ok')
end)

-- Utility functions
local function isPlayerJobTrucker()
    -- REMOVED JOB RESTRICTION - SIDE JOB FOR EVERYONE
    return true
end

local function notify(message, type)
    if exports and exports.qbx_core then
        exports.qbx_core:Notify(message, type)
    else
        -- Fallback notification system
        BeginTextCommandThefeedPost('STRING')
        AddTextComponentSubstringPlayerName(message)
        EndTextCommandThefeedPostTicker(false, true)
    end
    
    -- Also send to NUI if open
    if nuiOpen then
        SendNUIMessage({
            action = "showNotification",
            message = message,
            type = type or "info"
        })
    end
end

local function debugPrint(...)
    if config.debug then
        print(...)
    end
end

-- Function to handle wait for next delivery
local function waitForNextDelivery()
    waitingForNextDelivery = true
    notify("Wait for delivery...", "inform")
    
    Citizen.Wait(60000)
    
    waitingForNextDelivery = false
    notify("Next delivery location available!", "success")
end

-- Enhanced NPC Functions with better error handling
local function createNPC()
    if npcSpawned or (npcPed and DoesEntityExist(npcPed)) then 
        debugPrint("NPC already exists, skipping creation")
        return 
    end
    
    if not sharedConfig.locations or not sharedConfig.locations.npc then
        debugPrint("❌ NPC configuration not found, using default values")
        local defaultNpcConfig = {
            model = 's_m_m_trucker_01',
            coords = vector3(129.6644, -3220.2898, 5.8576),
            heading = 1.1093
        }
        sharedConfig.locations = sharedConfig.locations or {}
        sharedConfig.locations.npc = defaultNpcConfig
    end
    
    local npcConfig = sharedConfig.locations.npc
    local model = GetHashKey(npcConfig.model)
    
    if not IsModelValid(model) then
        debugPrint("❌ Invalid NPC model:", npcConfig.model)
        return
    end
    
    RequestModel(model)
    local timeout = 0
    while not HasModelLoaded(model) and timeout < 10000 do
        timeout = timeout + 100
        Citizen.Wait(100)
    end
    
    if not HasModelLoaded(model) then
        debugPrint("❌ Failed to load NPC model after 10 seconds:", npcConfig.model)
        return
    end
    
    -- Enhanced coordinates handling
    local coords = npcConfig.coords
    if type(coords) == "table" and coords.x and coords.y and coords.z then
        -- Table format
        npcPed = CreatePed(0, model, coords.x, coords.y, coords.z - 1, npcConfig.heading or 0.0, false, false)
    elseif type(coords) == "vector3" then
        -- Vector3 format
        npcPed = CreatePed(0, model, coords.x, coords.y, coords.z - 1, npcConfig.heading or 0.0, false, false)
    else
        debugPrint("❌ Invalid NPC coordinates format")
        return
    end
    
    if not npcPed or not DoesEntityExist(npcPed) then
        debugPrint("❌ Failed to create NPC entity")
        return
    end
    
    -- Enhanced NPC setup
    SetEntityAsMissionEntity(npcPed, true, true)
    SetBlockingOfNonTemporaryEvents(npcPed, true)
    SetPedFleeAttributes(npcPed, 0, 0)
    SetPedCombatAttributes(npcPed, 17, 1)
    SetPedRandomComponentVariation(npcPed, 0)
    SetPedRandomProps(npcPed)
    FreezeEntityPosition(npcPed, true)
    SetEntityInvincible(npcPed, true)
    
    -- Enhanced ox_target integration
    if exports and exports.ox_target then
        exports.ox_target:addLocalEntity(npcPed, {
            {
                name = 'trucker_npc_talk',
                icon = 'fas fa-comments',
                label = localeStrings.npc_talk,
                distance = 3.0,
                onSelect = function()
                    openTruckerNUI()
                end,
                canInteract = function()
                    local ped = PlayerPedId()
                    return not IsPedInAnyVehicle(ped, false)
                end
            },
            {
                name = 'trucker_npc_garage',
                icon = 'fas fa-truck',
                label = "🚛 Vehicle Garage",
                distance = 3.0,
                onSelect = function()
                    openMenuGarage()
                end,
                canInteract = function()
                    local ped = PlayerPedId()
                    return not IsPedInAnyVehicle(ped, false) and not jobActive
                end
            }
        })
        debugPrint("✅ NPC target interactions added successfully")
    else
        debugPrint("⚠️ ox_target not available, NPC interactions disabled")
    end
    
    npcSpawned = true
    debugPrint("✅ Main NPC created successfully at", coords.x, coords.y, coords.z)
end

local function createRentalNPC()
    if rentalNpcSpawned or (rentalNpcPed and DoesEntityExist(rentalNpcPed)) then 
        debugPrint("Rental NPC already exists, skipping creation")
        return 
    end
    
    local rentalNpcConfig = sharedConfig.locations.rentalNpc or {
        model = 's_m_m_autoshop_02',
        coords = vector3(130.0339, -3178.6028, 5.8960),
        heading = 176.9028
    }
    
    local model = GetHashKey(rentalNpcConfig.model)
    
    if not IsModelValid(model) then
        debugPrint("❌ Invalid rental NPC model:", rentalNpcConfig.model)
        return
    end
    
    RequestModel(model)
    local timeout = 0
    while not HasModelLoaded(model) and timeout < 10000 do
        timeout = timeout + 100
        Citizen.Wait(100)
    end
    
    if not HasModelLoaded(model) then
        debugPrint("❌ Failed to load rental NPC model after 10 seconds")
        return
    end
    
    local coords = rentalNpcConfig.coords
    rentalNpcPed = CreatePed(0, model, coords.x, coords.y, coords.z - 1, rentalNpcConfig.heading or 0.0, false, false)
    
    if not DoesEntityExist(rentalNpcPed) then
        debugPrint("❌ Failed to create rental NPC entity")
        return
    end
    
    SetEntityAsMissionEntity(rentalNpcPed, true, true)
    SetBlockingOfNonTemporaryEvents(rentalNpcPed, true)
    SetPedFleeAttributes(rentalNpcPed, 0, 0)
    SetPedCombatAttributes(rentalNpcPed, 17, 1)
    SetPedRandomComponentVariation(rentalNpcPed, 0)
    SetPedRandomProps(rentalNpcPed)
    FreezeEntityPosition(rentalNpcPed, true)
    SetEntityInvincible(rentalNpcPed, true)
    
    if exports and exports.ox_target then
        exports.ox_target:addLocalEntity(rentalNpcPed, {
            {
                name = 'trucker_return_npc',
                icon = 'fas fa-undo',
                label = localeStrings.return_vehicle,
                distance = 5.0,
                onSelect = function()
                    if lib and lib.progressBar then
                        local success = lib.progressBar({
                            duration = 2000,
                            label = 'Processing vehicle return...',
                            useWhileDead = false,
                            canCancel = false,
                            disable = {
                                car = true,
                                move = true,
                                combat = true
                            }
                        })

                        if success then
                            returnVehicle()
                        else
                            notify("Vehicle return cancelled.", "error")
                        end
                    else
                        returnVehicle()
                    end
                end,
                canInteract = function()
                    return jobActive
                end
            }
        })
        debugPrint("✅ Rental NPC target interactions added successfully")
    else
        debugPrint("⚠️ ox_target not available for rental NPC")
    end
    
    rentalNpcSpawned = true
    debugPrint("✅ Rental NPC created successfully at", coords.x, coords.y, coords.z)
end

local function deleteNPC()
    if npcPed and DoesEntityExist(npcPed) then
        if exports and exports.ox_target then
            exports.ox_target:removeLocalEntity(npcPed, {'trucker_npc_talk', 'trucker_npc_garage'})
        end
        DeleteEntity(npcPed)
        npcPed = nil
        debugPrint("✅ Main NPC deleted")
    end
    npcSpawned = false
    
    if rentalNpcPed and DoesEntityExist(rentalNpcPed) then
        if exports and exports.ox_target then
            exports.ox_target:removeLocalEntity(rentalNpcPed, 'trucker_return_npc')
        end
        DeleteEntity(rentalNpcPed)
        rentalNpcPed = nil
        debugPrint("✅ Rental NPC deleted")
    end
    rentalNpcSpawned = false
    
    debugPrint("🧹 All NPCs cleaned up")
end

-- Main functions
local function returnToStation()
    if DoesBlipExist(truckVehBlip) then
        SetBlipRoute(truckVehBlip, true)
        returningToStation = true
    end
end

local function isTruckerVehicle(vehicle)
    if not vehicle or not DoesEntityExist(vehicle) then return false end
    if not sharedConfig.vehicles then return false end
    local model = GetEntityModel(vehicle)
    return sharedConfig.vehicles[model] ~= nil
end

local function removeElements()
    ClearAllBlipRoutes()
    
    local blips = {truckVehBlip, truckerBlip, currentBlip}
    for _, blip in ipairs(blips) do
        if blip and DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    
    truckVehBlip = 0
    truckerBlip = 0
    currentBlip = 0

    for _, zone in ipairs(currentZones) do
        if zone and zone.remove then
            zone:remove()
        end
    end

    currentZones = {}
end

local function getPaid()
    TriggerServerEvent('qbx_truckerjob:server:getPaid')

    if DoesBlipExist(currentBlip) then
        RemoveBlip(currentBlip)
        ClearAllBlipRoutes()
        currentBlip = 0
    end
end

-- Helper to safely delete a vehicle
local function safeDeleteVehicle(vehicle)
    if DoesEntityExist(vehicle) then
        NetworkRequestControlOfEntity(vehicle)
        SetEntityAsMissionEntity(vehicle, true, true)
        DeleteVehicle(vehicle)
    end
end

function returnVehicle()
    local ped = PlayerPedId()
    
    if IsPedInAnyVehicle(ped, false) then
        local vehicle = GetVehiclePedIsIn(ped, false)
        if GetPedInVehicleSeat(vehicle, -1) ~= ped then
            return notify(localeStrings.error_no_driver, 'error')
        end

        if not isTruckerVehicle(vehicle) then
            return notify(localeStrings.error_vehicle_not_correct, 'error')
        end

        safeDeleteVehicle(vehicle)
        TriggerServerEvent('qbx_truckerjob:server:returnVehicle')
    end

    if DoesBlipExist(currentBlip) then
        RemoveBlip(currentBlip)
        ClearAllBlipRoutes()
        currentBlip = 0
    end

    if currentLocation and currentLocation.zoneCombo and currentLocation.zoneCombo.remove then
        currentLocation.zoneCombo:remove()
    end

    if totalDeliveries > 0 and completedDeliveries > 0 then
        local basePay = 200
        local pay = math.floor(completedDeliveries * basePay)
        TriggerServerEvent('qbx_truckerjob:server:getPaid', pay, completedDeliveries, totalDeliveries)

        if completedDeliveries >= totalDeliveries then
            notify(("All deliveries completed! You earned $%d"):format(pay), 'success')
        else
            notify(("Partial deliveries done: %d/%d. You still earned $%d"):format(completedDeliveries, totalDeliveries, pay), 'inform')
        end
    else
        notify("Vehicle returned but no deliveries were completed.", 'error')
    end

    ClearAllBlipRoutes()
    returningToStation = false
    returningToDepot = false
    jobActive = false
    currentLocation = {}
    hasBox = false
    currentPlate = nil
    totalDeliveries = 0
    completedDeliveries = 0
    waitingForNextDelivery = false

    -- Update NUI
    updateNUIJobStatus()
    
    notify(localeStrings.mission_job_completed, 'success')
end

function openMenuGarage()
    if jobActive then
        return notify(localeStrings.error_vehicle_already_out, 'error')
    end
    
    if not sharedConfig.vehicles then
        return notify("No vehicles configured", 'error')
    end
    
    local truckMenu = {}
    for modelHash, vehicleName in pairs(sharedConfig.vehicles) do
        truckMenu[#truckMenu + 1] = {
            title = vehicleName,
            event = 'qbx_truckerjob:client:spawnVehicle',
            args = modelHash
        }
    end

    if lib and lib.registerContext then
        lib.registerContext({
            id = 'trucker_veh_menu',
            title = localeStrings.menu_header,
            options = truckMenu
        })

        lib.showContext('trucker_veh_menu')
    else
        -- Fallback to NUI
        openTruckerNUI()
    end
end

local function createMainTarget()
    local location = sharedConfig.locations and sharedConfig.locations.main
    if not location then
        debugPrint("Main location configuration not found")
        return
    end
    
    if exports and exports.ox_target then
        currentZones[#currentZones + 1] = exports.ox_target:addBoxZone({
            coords = location.coords,
            size = location.size,
            rotation = location.rotation,
            debug = config.debug,
            options = {
                {
                    name = location.label,
                    onSelect = getPaid,
                    icon = location.icon,
                    label = location.label,
                    distance = 2,
                    canInteract = function() return true end
                }
            }
        })
    end
end

local function createMainZone()
    local location = sharedConfig.locations and sharedConfig.locations.main
    if not location then
        debugPrint("Main location configuration not found")
        return
    end

    if lib and lib.zones then
        local zone = lib.zones.sphere({
            coords = location.coords,
            radius = location.markerRadius or 2.0,
            debug = location.debug
        })

        local innerZone = lib.zones.sphere({
            coords = location.coords,
            radius = location.interactionsRadius or 1.5,
            debug = location.debug
        })

        local marker = lib.marker.new({
            coords = location.coords,
            type = location.markerType or 1,
            height = 0.2,
            width = 0.3
        })

        function zone:inside()
            marker:draw()
        end

        function innerZone:onEnter()
            if not lib.isTextUIOpen() then
                lib.showTextUI(localeStrings.info_pickup_paycheck)
            end
        end

        function innerZone:inside()
            if IsControlJustPressed(0, 38) then
                getPaid()
            end
        end

        function innerZone:onExit()
            local isOpen, currentText = lib.isTextUIOpen()
            if isOpen and currentText == localeStrings.info_pickup_paycheck then
                lib.hideTextUI()
            end
        end

        currentZones[#currentZones + 1] = zone
        currentZones[#currentZones + 1] = innerZone
    end
end

local createMain = config.useTarget and createMainTarget or createMainZone

local function areBackDoorsOpen(vehicle)
    if not vehicle or not DoesEntityExist(vehicle) then return false end
    
    local model = GetEntityModel(vehicle)
    local doorIds = sharedConfig.truckDoors and sharedConfig.truckDoors[model] or {2, 3, 5}
    
    for _, doorId in ipairs(doorIds) do
        local angle = GetVehicleDoorAngleRatio(vehicle, doorId)
        if angle > 0.0 then
            return true
        end
    end
    
    return false
end

local function openTrunkDoors(vehicle)
    if not vehicle or not DoesEntityExist(vehicle) then return end
    
    local model = GetEntityModel(vehicle)
    local doorIds = sharedConfig.truckDoors and sharedConfig.truckDoors[model] or {2, 3, 5}
    
    for _, doorId in ipairs(doorIds) do
        SetVehicleDoorOpen(vehicle, doorId, false, false)
    end
end

local function getInTrunk() 
    local ped = PlayerPedId()
    
    if IsPedInAnyVehicle(ped, false) then
        return notify(localeStrings.error_get_out_vehicle, 'error')
    end

    local playerCoords = GetEntityCoords(ped)
    local vehicle = GetClosestVehicle(playerCoords.x, playerCoords.y, playerCoords.z, 5.0, 0, 71)
    
    if not vehicle or not DoesEntityExist(vehicle) then
        debugPrint("No vehicle found nearby")
        return notify(localeStrings.error_vehicle_not_correct, 'error')
    end
    
    local vehicleModel = GetEntityModel(vehicle)
    local vehiclePlate = GetVehicleNumberPlateText(vehicle)
    
    if not isTruckerVehicle(vehicle) or (currentPlate and currentPlate ~= vehiclePlate) then
        return notify(localeStrings.error_vehicle_not_correct, 'error')
    end

    if not areBackDoorsOpen(vehicle) then
        openTrunkDoors(vehicle)
        Wait(500)
        if not areBackDoorsOpen(vehicle) then
            return notify(localeStrings.error_backdoors_not_open, 'error')
        end
    end

    local pedCoords = GetEntityCoords(ped)
    local trunkCoords = GetOffsetFromEntityInWorldCoords(vehicle, 0, -2.5, 0)
    local distance = #(pedCoords - trunkCoords)
    
    if distance > (sharedConfig.boxGrab and sharedConfig.boxGrab.maxDistance or 3.0) then
        return notify(localeStrings.error_too_far_from_trunk, 'error')
    end

    if lib and lib.progressCircle then
        local success = lib.progressCircle({
            duration = sharedConfig.boxGrab and sharedConfig.boxGrab.grabTime or 2000,
            position = 'bottom',
            useWhileDead = false,
            canCancel = true,
            disable = {
                car = true,
                mouse = false,
                combat = true,
                move = true,
            },
            anim = sharedConfig.animations and sharedConfig.animations.grabBox or {
                dict = 'anim@gangops@facility@servers@',
                clip = 'hotwire'
            },
        })
        
        if success then
            local emoteCommand = sharedConfig.animations and sharedConfig.animations.boxEmote or 'box'
            if exports and exports.scully_emotemenu then
                exports.scully_emotemenu:playEmoteByCommand(emoteCommand)
            end
            hasBox = true

            deliveryTimeout = GetGameTimer() + (sharedConfig.boxGrab and sharedConfig.boxGrab.timeout or 300000)
            notify(localeStrings.info_deliver_to_store or "Deliver the box to the store.", 'info')

            CreateThread(function()
                while hasBox and GetGameTimer() < deliveryTimeout do
                    Wait(1000)
                end
                
                if hasBox then
                    notify('Delivery timed out. Return to the truck to get another box.', 'error')
                    if exports and exports.scully_emotemenu then
                        exports.scully_emotemenu:cancelEmote()
                    end
                    ClearPedTasks(ped)
                    hasBox = false
                end
            end)
        else
            notify(localeStrings.error_cancelled or "Action cancelled.", 'error')
            ClearPedTasks(ped)
        end
    else
        -- Fallback progress system
        hasBox = true
        notify(localeStrings.info_deliver_to_store or "Deliver the box to the store.", 'info')
    end
end

function addBoxGrabTarget(vehicle)
    if exports and exports.ox_target then
        exports.ox_target:addLocalEntity(vehicle, {
            {
                name = 'trucker_grab_box',
                icon = 'fas fa-box',
                label = localeStrings.grab_box,
                distance = 3.0,
                onSelect = getInTrunk,
                canInteract = function()
                    return not hasBox and areBackDoorsOpen(vehicle)
                end
            }
        })
    end
end

local function deliver()
    if isDelivering then 
        debugPrint("⚠️ Delivery already in progress")
        return false 
    end
    isDelivering = true

    local ped = PlayerPedId()

    -- Vehicle check
    if IsPedInAnyVehicle(ped, false) then
        notify("Get out of your vehicle first to deliver", "error")
        isDelivering = false
        return false
    end

    -- Box check
    if not hasBox then
        notify("You don't have a box to deliver", "error")
        isDelivering = false
        return false
    end

    -- Location check
    if not currentLocation or not currentLocation.coords then
        notify("No delivery location set", "error")
        isDelivering = false
        return false
    end

    -- Distance check
    local playerCoords = GetEntityCoords(ped)
    local deliveryCoords = currentLocation.coords
    local distance = #(playerCoords - vector3(deliveryCoords.x, deliveryCoords.y, deliveryCoords.z))

    debugPrint(("Distance check: %.2fm"):format(distance))

    if distance > 5.0 then
        notify("Too far from the delivery point", "error")
        isDelivering = false
        return false
    end

    -- Delivery progress
    debugPrint("Starting delivery sequence...")

    local deliveryTime = (currentLocation and currentLocation.deliveryTime) or (sharedConfig.boxGrab and sharedConfig.boxGrab.deliveryTime) or 3000
    local success = true

    if lib and lib.progressCircle then
        success = lib.progressCircle({
            duration = deliveryTime,
            label = 'Delivering package...',
            position = 'bottom',
            useWhileDead = false,
            canCancel = true,
            disable = { car = true, mouse = false, combat = true, move = true },
            anim = { dict = 'anim@gangops@facility@servers@', clip = 'hotwire', flag = 1 },
        })
    else
        Citizen.Wait(deliveryTime)
    end

    if not success then
        notify("Delivery cancelled", "error")
        ClearPedTasks(ped)
        isDelivering = false
        return false
    end

    -- Finish animation
    if exports and exports.scully_emotemenu then
        exports.scully_emotemenu:cancelEmote()
    end
    ClearPedTasks(ped)

    hasBox = false
    isDelivering = false

    -- Update counters
    currentLocation.currentCount = (currentLocation.currentCount or 0) + 1
    completedDeliveries = completedDeliveries + 1

    TriggerServerEvent('qbx_truckerjob:server:recordDrop')

    debugPrint(("Delivered: %d/%d at %s"):format(currentLocation.currentCount, currentLocation.dropCount, currentLocation.storeLabel))
    notify(("Package delivered! %d/%d here"):format(currentLocation.currentCount, currentLocation.dropCount), "success")

    -- Update NUI
    updateNUIDeliveryProgress()

    -- Batch complete
    if currentLocation.currentCount >= currentLocation.dropCount then
        debugPrint("Location completed:", currentLocation.storeLabel)
        notify("Delivery batch completed!", "success")

        -- Cleanup blip & NPC
        if DoesBlipExist(currentBlip) then
            RemoveBlip(currentBlip)
            ClearAllBlipRoutes()
            currentBlip = 0
        end

        if currentLocation.zoneCombo and currentLocation.zoneCombo.remove then
            currentLocation.zoneCombo:remove()
        end

        if currentLocation.npcPed and DoesEntityExist(currentLocation.npcPed) then
            if exports and exports.ox_target then
                exports.ox_target:removeLocalEntity(currentLocation.npcPed, 'deliver_box_npc')
            end
            DeleteEntity(currentLocation.npcPed)
        end

        currentLocation = {}

        -- All deliveries done?
        if completedDeliveries >= totalDeliveries then
            notify("All deliveries complete! Return to depot.", "success")
            createDepotReturnBlip()
        else
            Citizen.CreateThread(function()
                Citizen.Wait(1000)
                debugPrint("Requesting next delivery...")

                if lib and lib.callback then
                    local newLocationIndex, newDrop = lib.callback.await('qbx_truckerjob:server:getNewTask', false, 5000)
                    if newLocationIndex and newLocationIndex > 0 then
                        notify("New delivery assigned", "info")
                        getNewLocation(newLocationIndex, newDrop)
                    else
                        notify("No more tasks, return to depot", "success")
                        createDepotReturnBlip()
                    end
                else
                    notify("Could not request next delivery", "error")
                    createDepotReturnBlip()
                end
            end)
        end
    end

    return true
end

function getNewLocation(locationIndex, drop)
    debugPrint("=== GET NEW LOCATION DEBUG ===")
    debugPrint("Location Index:", locationIndex, "Drop Count:", drop)
    
    -- Debug: Print available deliveries
    if sharedConfig.deliveries then
        if sharedConfig.deliveries.stores then
            debugPrint("Available stores:", #sharedConfig.deliveries.stores)
        end
        if sharedConfig.deliveries.houses then
            debugPrint("Available houses:", #sharedConfig.deliveries.houses)
        end
    end

    -- Validate inputs
    if not locationIndex or locationIndex <= 0 then
        debugPrint("Invalid location index:", locationIndex)
        notify("Invalid delivery location index", "error")
        return false
    end

    if not sharedConfig.deliveries then
        debugPrint("No deliveries config found")
        notify("Delivery configuration not found", "error")
        return false
    end

    -- Enhanced logic: Try both stores and houses with better indexing
    local store = nil
    local storeType = nil
    
    -- First try stores
    if sharedConfig.deliveries.stores and sharedConfig.deliveries.stores[locationIndex] then
        store = sharedConfig.deliveries.stores[locationIndex]
        storeType = "store"
        debugPrint("Found store at index:", locationIndex, "Label:", store.label or "No label")
    -- Then try houses
    elseif sharedConfig.deliveries.houses and sharedConfig.deliveries.houses[locationIndex] then
        store = sharedConfig.deliveries.houses[locationIndex]
        storeType = "house" 
        debugPrint("Found house at index:", locationIndex, "Label:", store.label or "No label")
    else
        -- Try to find ANY available location as fallback
        local fallbackLocation = nil
        local fallbackType = nil
        
        if sharedConfig.deliveries.stores and #sharedConfig.deliveries.stores > 0 then
            local fallbackIndex = ((locationIndex - 1) % #sharedConfig.deliveries.stores) + 1
            fallbackLocation = sharedConfig.deliveries.stores[fallbackIndex]
            fallbackType = "store"
            debugPrint("Using fallback store at index:", fallbackIndex)
        elseif sharedConfig.deliveries.houses and #sharedConfig.deliveries.houses > 0 then
            local fallbackIndex = ((locationIndex - 1) % #sharedConfig.deliveries.houses) + 1
            fallbackLocation = sharedConfig.deliveries.houses[fallbackIndex]
            fallbackType = "house"
            debugPrint("Using fallback house at index:", fallbackIndex)
        end
        
        if fallbackLocation then
            store = fallbackLocation
            storeType = fallbackType
            debugPrint("Fallback location found:", store.label or "No label")
        else
            debugPrint("No locations available at all!")
            notify("No delivery locations available", "error")
            return false
        end
    end

    -- Final validation
    if not store then
        debugPrint("Store is still nil after all attempts")
        notify("Delivery location not found", "error")
        return false
    end

    if not store.coords then
        debugPrint("Store found but no coordinates:", json.encode(store))
        notify("Invalid delivery coordinates", "error")
        return false
    end
    
    store.type = storeType

    -- Cleanup previous location
    if currentLocation.npcPed and DoesEntityExist(currentLocation.npcPed) then
        if exports and exports.ox_target then
            exports.ox_target:removeLocalEntity(currentLocation.npcPed, 'deliver_box_npc')
        end
        DeleteEntity(currentLocation.npcPed)
    end
    
    if DoesBlipExist(currentBlip) then
        RemoveBlip(currentBlip)
        ClearAllBlipRoutes()
        currentBlip = 0
    end

    -- Set new location state with max box rule
    local maxDrops = 1
    if store.type == "store" then
        maxDrops = 3
    elseif store.type == "house" then
        maxDrops = 1
    end

    currentLocation = {
        dropCount = maxDrops,
        currentCount = 0,
        storeLabel = store.label or "Delivery Location",
        coords = store.coords,
        type = store.type or "store"
    }

    debugPrint(("New location set: %s | Type: %s | DropCount: %d"):format(currentLocation.storeLabel, currentLocation.type, currentLocation.dropCount))

    -- Spawn delivery NPC
    local npcModel = GetHashKey(store.npcModel or "s_m_m_trucker_01")
    RequestModel(npcModel)
    local timeout = 0
    while not HasModelLoaded(npcModel) and timeout < 5000 do
        timeout = timeout + 100
        Citizen.Wait(100)
    end

    if HasModelLoaded(npcModel) then
        local npcPed = CreatePed(4, npcModel, store.coords.x, store.coords.y, store.coords.z, store.rotation or 0.0, false, true)
        
        if DoesEntityExist(npcPed) then
            FreezeEntityPosition(npcPed, true)
            SetEntityInvincible(npcPed, true)
            SetBlockingOfNonTemporaryEvents(npcPed, true)
            currentLocation.npcPed = npcPed

            if exports and exports.ox_target then
                exports.ox_target:addLocalEntity(npcPed, {
                    name = 'deliver_box_npc',
                    icon = 'fas fa-box',
                    label = ('Deliver to %s'):format(currentLocation.storeLabel),
                    distance = 2.5,
                    onSelect = function()
                        local ped = PlayerPedId()
                        if IsPedInAnyVehicle(ped, false) then
                            notify("Get out of your vehicle first", "error")
                            return
                        end
                        if not hasBox then
                            notify("You need to grab a box from your truck first", "error")
                            return
                        end

                        deliver()
                    end,
                    canInteract = function()
                        local ped = PlayerPedId()
                        return not IsPedInAnyVehicle(ped, false) and hasBox
                    end
                })
            end
        end
    end

    -- Add delivery blip
    currentBlip = AddBlipForCoord(store.coords.x, store.coords.y, store.coords.z)
    if currentLocation.type == "house" then
        SetBlipSprite(currentBlip, 40)
        SetBlipColour(currentBlip, 5)
    else
        SetBlipSprite(currentBlip, 52)
        SetBlipColour(currentBlip, 2)
    end
    SetBlipRoute(currentBlip, true)
    SetBlipRouteColour(currentBlip, 2)
    SetBlipScale(currentBlip, 0.9)
    SetBlipDisplay(currentBlip, 4)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(currentLocation.storeLabel)
    EndTextCommandSetBlipName(currentBlip)

    notify(("New delivery: %s (%d boxes)"):format(currentLocation.storeLabel, currentLocation.dropCount), "success")
    
    -- Update NUI
    updateNUIDeliveryProgress()
    
    debugPrint("Location setup complete")
    return true
end

function createDepotReturnBlip()
    if not sharedConfig.locations or not sharedConfig.locations.vehicle then
        notify("Depot location not configured", "error")
        return
    end
    
    local depotCoords = sharedConfig.locations.vehicle.coords
    if DoesBlipExist(currentBlip) then
        RemoveBlip(currentBlip)
        ClearAllBlipRoutes()
        currentBlip = 0
    end

    currentBlip = AddBlipForCoord(depotCoords.x, depotCoords.y, depotCoords.z)
    SetBlipSprite(currentBlip, 50)
    SetBlipColour(currentBlip, 5)
    SetBlipScale(currentBlip, 0.9)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Return Van to Depot")
    EndTextCommandSetBlipName(currentBlip)

    SetBlipRoute(currentBlip, true)
    SetBlipRouteColour(currentBlip, 5)
    
    returningToDepot = true
end

function assignDelivery(poolIndex, boxCount)
    local pid = GetPlayerServerId(PlayerId())
    local playerLocations = locations[pid]

    debugPrint("=== ASSIGN DELIVERY DEBUG ===")
    debugPrint("Player ID:", pid)
    debugPrint("Pool Index:", poolIndex)
    debugPrint("Box Count:", boxCount)

    -- Enhanced validation with fallbacks
    if not playerLocations then
        debugPrint("No player locations, initializing...")
        locations[pid] = {}
        playerLocations = locations[pid]
    end

    if not playerLocations.pool then
        debugPrint("No pool found, trying to use direct config...")
        -- Fallback: Create a simple pool from available locations
        local fallbackPool = {}
        
        if sharedConfig.deliveries and sharedConfig.deliveries.stores then
            for i, store in ipairs(sharedConfig.deliveries.stores) do
                table.insert(fallbackPool, {type = "store", index = i})
            end
        end
        
        if sharedConfig.deliveries and sharedConfig.deliveries.houses then
            for i, house in ipairs(sharedConfig.deliveries.houses) do
                table.insert(fallbackPool, {type = "house", index = i})
            end
        end
        
        if #fallbackPool > 0 then
            playerLocations.pool = fallbackPool
            debugPrint("Created fallback pool with", #fallbackPool, "locations")
        else
            notify("No delivery locations configured", "error")
            return false
        end
    end

    -- Validate pool index with wrapping
    local adjustedPoolIndex = poolIndex
    if poolIndex > #playerLocations.pool then
        adjustedPoolIndex = ((poolIndex - 1) % #playerLocations.pool) + 1
        debugPrint("Adjusted pool index from", poolIndex, "to", adjustedPoolIndex)
    elseif poolIndex < 1 then
        adjustedPoolIndex = 1
        debugPrint("Adjusted pool index from", poolIndex, "to", adjustedPoolIndex)
    end

    local delivery = playerLocations.pool[adjustedPoolIndex]
    if not delivery or not delivery.type or not delivery.index then
        debugPrint("Invalid delivery data at adjusted index:", adjustedPoolIndex)
        -- Try to get any valid delivery from the pool
        for i, poolDelivery in ipairs(playerLocations.pool) do
            if poolDelivery and poolDelivery.type and poolDelivery.index then
                delivery = poolDelivery
                debugPrint("Using alternate delivery at pool index:", i)
                break
            end
        end
        
        if not delivery then
            notify("No valid delivery data found", "error")
            return false
        end
    end

    local deliveryType = delivery.type
    local realIndex = delivery.index

    debugPrint("Delivery type:", deliveryType, "Real index:", realIndex)

    -- Determine which pool to use with validation
    local deliveryPool
    if deliveryType == "house" then
        if not sharedConfig.deliveries.houses then
            debugPrint("Houses config not found, switching to stores")
            deliveryType = "store"
            deliveryPool = sharedConfig.deliveries.stores
        else
            deliveryPool = sharedConfig.deliveries.houses
        end
    elseif deliveryType == "store" then
        if not sharedConfig.deliveries.stores then
            debugPrint("Stores config not found, switching to houses")
            deliveryType = "house" 
            deliveryPool = sharedConfig.deliveries.houses
        else
            deliveryPool = sharedConfig.deliveries.stores
        end
    else
        debugPrint("Unknown delivery type, defaulting to store")
        deliveryType = "store"
        deliveryPool = sharedConfig.deliveries.stores or sharedConfig.deliveries.houses
    end

    if not deliveryPool or #deliveryPool == 0 then
        notify("No delivery locations available", "error")
        return false
    end

    -- Validate and adjust real index
    local adjustedRealIndex = realIndex
    if realIndex > #deliveryPool then
        adjustedRealIndex = ((realIndex - 1) % #deliveryPool) + 1
        debugPrint("Adjusted real index from", realIndex, "to", adjustedRealIndex)
    elseif realIndex < 1 then
        adjustedRealIndex = 1
        debugPrint("Adjusted real index from", realIndex, "to", adjustedRealIndex)
    end

    local location = deliveryPool[adjustedRealIndex]
    if not location then
        debugPrint("Location not found at adjusted index:", adjustedRealIndex)
        -- Get first available location as final fallback
        location = deliveryPool[1]
        if not location then
            notify("No locations in delivery pool", "error")
            return false
        end
        debugPrint("Using first available location as fallback")
    end

    if not location.coords then
        debugPrint("Location found but missing coordinates:", json.encode(location))
        notify("Invalid delivery coordinates", "error")
        return false
    end

    -- Set current location
    currentLocation = {
        dropCount = boxCount or 1,
        currentCount = 0,
        storeLabel = location.label or "Delivery Location",
        coords = location.coords,
        type = deliveryType,
        npcPed = nil
    }

    -- Clean up previous blip
    if currentBlip and DoesBlipExist(currentBlip) then
        RemoveBlip(currentBlip)
        ClearAllBlipRoutes()
        currentBlip = 0
    end

    -- Create new blip
    currentBlip = AddBlipForCoord(location.coords.x, location.coords.y, location.coords.z)
    
    if deliveryType == "house" then
        SetBlipSprite(currentBlip, 40)
        SetBlipColour(currentBlip, 5)
    else
        SetBlipSprite(currentBlip, 52)
        SetBlipColour(currentBlip, 3)
    end
    
    SetBlipRoute(currentBlip, true)
    SetBlipRouteColour(currentBlip, 3)
    SetBlipScale(currentBlip, 0.9)

    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(currentLocation.storeLabel)
    EndTextCommandSetBlipName(currentBlip)

    -- Spawn NPC
    local npcModel = GetHashKey(location.npcModel or "s_m_m_trucker_01")
    RequestModel(npcModel)
    local timeout = 0
    while not HasModelLoaded(npcModel) and timeout < 5000 do
        timeout = timeout + 100
        Citizen.Wait(100)
    end

    if HasModelLoaded(npcModel) then
        local npcPed = CreatePed(4, npcModel, location.coords.x, location.coords.y, location.coords.z, location.rotation or 0.0, false, true)
        
        if DoesEntityExist(npcPed) then
            FreezeEntityPosition(npcPed, true)
            SetEntityInvincible(npcPed, true)
            SetBlockingOfNonTemporaryEvents(npcPed, true)
            currentLocation.npcPed = npcPed

            if exports and exports.ox_target then
                exports.ox_target:addLocalEntity(npcPed, {
                    name = 'deliver_box_npc',
                    icon = 'fas fa-box',
                    label = ('Deliver to %s'):format(currentLocation.storeLabel),
                    distance = 2.5,
                    onSelect = function()
                        local ped = PlayerPedId()
                        if IsPedInAnyVehicle(ped, false) then
                            notify("Get out of your vehicle first", "error")
                            return
                        end
                        if not hasBox then
                            notify("You need to grab a box from your truck first", "error")
                            return
                        end
                        deliver()
                    end,
                    canInteract = function()
                        local ped = PlayerPedId()
                        return not IsPedInAnyVehicle(ped, false) and hasBox
                    end
                })
            end
        end
    end

    notify(("Next delivery: %s (%d boxes)"):format(currentLocation.storeLabel, boxCount), "success")
    
    -- Update NUI
    updateNUIDeliveryProgress()
    
    debugPrint("Delivery assigned successfully!")
    return true
end

local function createElement(location, spriteId)
    if not location or not location.coords then
        debugPrint("Location is nil or missing coords for createElement")
        return 0
    end

    local element = AddBlipForCoord(location.coords.x, location.coords.y, location.coords.z)
    SetBlipSprite(element, spriteId)
    SetBlipDisplay(element, 4)
    SetBlipScale(element, 0.6)
    SetBlipAsShortRange(element, true)
    SetBlipColour(element, 5)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(location.label or "Unknown")
    EndTextCommandSetBlipName(element)

    return element
end

local function createElements()
    if not sharedConfig.locations then
        debugPrint("Locations configuration not found")
        return
    end

    if sharedConfig.locations.vehicle then
        truckVehBlip = createElement(sharedConfig.locations.vehicle, 326)
    end
    
    if sharedConfig.locations.main then
        truckerBlip = createElement(sharedConfig.locations.main, 479)
    end

    createMain()
    createRentalNPC()
    createNPC()
end

-- Enhanced Driver NPC Creation
local function createDriverNPC(vehicle)
    if not vehicle or not DoesEntityExist(vehicle) then return end
    
    -- Delete existing driver NPC if any
    if driverNPC and DoesEntityExist(driverNPC) then
        DeleteEntity(driverNPC)
        driverNPC = nil
    end
    
    local driverModel = GetHashKey('s_m_m_trucker_01')
    RequestModel(driverModel)
    
    local timeout = 0
    while not HasModelLoaded(driverModel) and timeout < 5000 do
        timeout = timeout + 100
        Citizen.Wait(100)
    end
    
    if not HasModelLoaded(driverModel) then
        debugPrint("❌ Failed to load driver NPC model")
        return
    end
    
    local vehicleCoords = GetEntityCoords(vehicle)
    driverNPC = CreatePed(4, driverModel, vehicleCoords.x, vehicleCoords.y, vehicleCoords.z, 0.0, true, true)
    
    if not DoesEntityExist(driverNPC) then
        debugPrint("❌ Failed to create driver NPC")
        return
    end
    
    SetPedIntoVehicle(driverNPC, vehicle, -1)
    SetBlockingOfNonTemporaryEvents(driverNPC, true)
    SetPedKeepTask(driverNPC, true)
    
    -- Enhanced return to depot functionality
    if sharedConfig.locations and sharedConfig.locations.vehicle then
        local depotCoords = sharedConfig.locations.vehicle.coords
        TaskVehicleDriveToCoord(driverNPC, vehicle, depotCoords.x, depotCoords.y, depotCoords.z, 20.0, 0, GetEntityModel(vehicle), 786603, 1.0, -1)
        
        debugPrint("✅ Driver NPC created and driving to depot")
        
        -- Clean up after reaching depot
        Citizen.CreateThread(function()
            local maxWaitTime = 300000 -- 5 minutes max
            local startTime = GetGameTimer()
            
            while DoesEntityExist(driverNPC) and DoesEntityExist(vehicle) do
                if GetGameTimer() - startTime > maxWaitTime then
                    debugPrint("⏰ Driver NPC timeout, cleaning up")
                    break
                end
                
                local driverCoords = GetEntityCoords(driverNPC)
                local distance = #(driverCoords - vector3(depotCoords.x, depotCoords.y, depotCoords.z))
                
                if distance < 10.0 then
                    debugPrint("✅ Driver reached depot, cleaning up")
                    break
                end
                
                Citizen.Wait(5000)
            end
            
            -- Cleanup
            if DoesEntityExist(driverNPC) then
                DeleteEntity(driverNPC)
                driverNPC = nil
            end
            
            if DoesEntityExist(vehicle) then
                DeleteVehicle(vehicle)
            end
        end)
    else
        debugPrint("⚠️ No depot location configured for driver NPC")
    end
end

local function onPlayerExitVehicle(vehicle)
    if not jobActive or not isTruckerVehicle(vehicle) or (currentPlate and currentPlate ~= GetVehicleNumberPlateText(vehicle)) then
        return
    end
    
    local ped = PlayerPedId()
    if GetPedInVehicleSeat(vehicle, -1) == ped then
        createDriverNPC(vehicle)
        notify("Your vehicle is being returned to the spawn location by a driver.", "inform")
    end
end

local function setInitState()
    removeElements()
    deleteNPC()
    currentLocation = {}
    currentBlip = 0
    hasBox = false
    jobActive = false
    returningToStation = false
    returningToDepot = false
    currentPlate = nil
    totalDeliveries = 0
    completedDeliveries = 0
    waitingForNextDelivery = false
    isDelivering = false
    
    if driverNPC and DoesEntityExist(driverNPC) then
        DeleteEntity(driverNPC)
        driverNPC = nil
    end
    
    -- Close NUI
    if nuiOpen then
        closeTruckerNUI()
    end
end

-- Debug commands
RegisterCommand('truckernui', function()
    openTruckerNUI()
end, false)

RegisterCommand('truckerdebug', function()
    local ped = PlayerPedId()
    local playerCoords = GetEntityCoords(ped)
    local vehicle = GetClosestVehicle(playerCoords.x, playerCoords.y, playerCoords.z, 5.0, 0, 71)
    
    debugPrint("=== TRUCKER DEBUG ===")
    debugPrint("Has box:", hasBox)
    debugPrint("Job active:", jobActive)
    debugPrint("Total deliveries:", totalDeliveries)
    debugPrint("Completed deliveries:", completedDeliveries)
    debugPrint("Current plate:", currentPlate)
    debugPrint("Returning to depot:", returningToDepot)
    debugPrint("Is delivering:", isDelivering)
    debugPrint("NUI Open:", nuiOpen)
    
    -- Debug config data
    debugPrint("=== CONFIG DEBUG ===")
    if sharedConfig.deliveries then
        if sharedConfig.deliveries.stores then
            debugPrint("Stores available:", #sharedConfig.deliveries.stores)
            for i = 1, math.min(5, #sharedConfig.deliveries.stores) do
                local store = sharedConfig.deliveries.stores[i]
                debugPrint(("Store [%d]: %s - Coords: %s"):format(
                    i, 
                    store.label or "No label",
                    store.coords and ("x:" .. store.coords.x .. " y:" .. store.coords.y) or "No coords"
                ))
            end
        else
            debugPrint("❌ No stores config found")
        end
        
        if sharedConfig.deliveries.houses then
            debugPrint("Houses available:", #sharedConfig.deliveries.houses)
            for i = 1, math.min(5, #sharedConfig.deliveries.houses) do
                local house = sharedConfig.deliveries.houses[i]
                debugPrint(("House [%d]: %s - Coords: %s"):format(
                    i, 
                    house.label or "No label",
                    house.coords and ("x:" .. house.coords.x .. " y:" .. house.coords.y) or "No coords"
                ))
            end
        else
            debugPrint("No houses config found")
        end
    else
        debugPrint("No deliveries config found at all!")
    end
    
    -- Debug player locations pool
    debugPrint("=== PLAYER POOL DEBUG ===")
    local pid = GetPlayerServerId(PlayerId())
    local playerLocations = locations[pid]
    if playerLocations and playerLocations.pool then
        debugPrint("Player pool size:", #playerLocations.pool)
        for i = 1, math.min(10, #playerLocations.pool) do
            local poolItem = playerLocations.pool[i]
            debugPrint(("Pool [%d]: Type: %s, Index: %d"):format(i, poolItem.type or "nil", poolItem.index or 0))
        end
    else
        debugPrint("No player pool found")
    end
    
    if vehicle and DoesEntityExist(vehicle) then
        debugPrint("=== VEHICLE DEBUG ===")
        debugPrint("Vehicle found:", vehicle)
        debugPrint("Vehicle model:", GetEntityModel(vehicle))
        debugPrint("Vehicle plate:", GetVehicleNumberPlateText(vehicle))
        debugPrint("Is trucker vehicle:", isTruckerVehicle(vehicle))
        debugPrint("Are doors open:", areBackDoorsOpen(vehicle))
        
        for i = 0, 5 do
            local angle = GetVehicleDoorAngleRatio(vehicle, i)
            debugPrint("Door "..i.." angle:", angle)
        end
    else
        debugPrint("No vehicle nearby")
    end
    
    if currentLocation and currentLocation.coords then
        debugPrint("=== CURRENT LOCATION DEBUG ===")
        debugPrint("Current location:", currentLocation.storeLabel)
        debugPrint("Drop count:", currentLocation.dropCount)
        debugPrint("Current count:", currentLocation.currentCount)
        debugPrint("Location type:", currentLocation.type)
        
        local distance = #(playerCoords - vector3(currentLocation.coords.x, currentLocation.coords.y, currentLocation.coords.z))
        debugPrint("Distance to delivery:", distance)
    else
        debugPrint("No current location set")
    end
end, false)

RegisterCommand('truckercheckloc', function(source, args)
    if not args[1] then
        debugPrint("Usage: /truckercheckloc <index>")
        return
    end
    
    local index = tonumber(args[1])
    if not index then
        debugPrint("Invalid index provided")
        return
    end
    
    debugPrint("=== CHECKING LOCATION INDEX", index, "===")
    
    -- Check stores
    if sharedConfig.deliveries and sharedConfig.deliveries.stores then
        local store = sharedConfig.deliveries.stores[index]
        if store then
            debugPrint("Store found:")
            debugPrint("  Label:", store.label or "No label")
            debugPrint("  Coords:", store.coords and json.encode(store.coords) or "No coords")
            debugPrint("  NPC Model:", store.npcModel or "Default")
        else
            debugPrint("No store at index", index, "/ Max stores:", #sharedConfig.deliveries.stores)
        end
    end
    
    -- Check houses
    if sharedConfig.deliveries and sharedConfig.deliveries.houses then
        local house = sharedConfig.deliveries.houses[index]
        if house then
            debugPrint("House found:")
            debugPrint("  Label:", house.label or "No label") 
            debugPrint("  Coords:", house.coords and json.encode(house.coords) or "No coords")
            debugPrint("  NPC Model:", house.npcModel or "Default")
        else
            debugPrint("No house at index", index, "/ Max houses:", #sharedConfig.deliveries.houses)
        end
    end
end, false)

-- Event handlers
AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    setInitState()
    createElements()
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBX.PlayerData or {}
    PlayerJob = PlayerData.job or {}
    setInitState()
    createElements()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    setInitState()
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerJob = JobInfo
    removeElements()
    deleteNPC()

    if currentLocation and currentLocation.zoneCombo and currentLocation.zoneCombo.remove then
        currentLocation.zoneCombo:remove()
    end

    createElements()
end)

RegisterNetEvent('qbx_truckerjob:client:spawnVehicle', function(modelHash)
    if jobActive then
        return notify(localeStrings.error_vehicle_already_out, 'error')
    end

    local success = true
    if lib and lib.progressBar then
        success = lib.progressBar({
            duration = 2000,
            label = 'Preparing your delivery van...',
            useWhileDead = false,
            canCancel = false,
            disable = { car=true, move=true, combat=true }
        })
    end
    if not success then return end

    if not lib or not lib.callback then
        notify("Callback system not available", "error")
        return
    end

    local netId, plate = lib.callback.await('qbx_truckerjob:server:spawnVehicle', false, modelHash)
    if not netId then 
        notify("Failed to spawn vehicle", "error")
        return 
    end

    currentPlate = plate
    completedDeliveries = 0
    currentLocation = {}
    
    if DoesBlipExist(currentBlip) then
        SetBlipRoute(currentBlip, false)
        RemoveBlip(currentBlip)
        currentBlip = 0
    end

    totalDeliveries = math.random(20, 30)

    local vehicle
    for i = 1, 20 do
        vehicle = NetToVeh(netId)
        if DoesEntityExist(vehicle) then break end
        Wait(100)
    end
    
    if not vehicle or not DoesEntityExist(vehicle) then
        return notify("Vehicle spawn failed.", "error")
    end

    SetVehicleEngineOn(vehicle, true, true, false)
    jobActive = true

    -- Update NUI
    updateNUIJobStatus()

    -- Notify about delivery count
    Citizen.SetTimeout(20000, function()
        notify(("Deliveries Today: %d"):format(totalDeliveries), "inform")
    end)

    -- Open trunk doors and add target after delay
    Citizen.SetTimeout(3000, function()
        openTrunkDoors(vehicle)
        if type(addBoxGrabTarget) == "function" then
            addBoxGrabTarget(vehicle)
        else
            debugPrint("⚠️ addBoxGrabTarget not available")
        end
    end)

    -- Get first delivery assignment
    Citizen.CreateThread(function()
        Citizen.Wait(5000)
        
        local poolIndex, boxCount, pool = lib.callback.await('qbx_truckerjob:server:getNewTask', false, true)

        if pool then
            local pid = GetPlayerServerId(PlayerId())
            locations[pid] = locations[pid] or {}
            locations[pid].pool = pool
        end

        if poolIndex and boxCount and poolIndex > 0 then
            assignDelivery(poolIndex, boxCount)
        else
            notify("No delivery locations available.", "error")
        end
    end)
end)

AddEventHandler('baseevents:leftVehicle', function(vehicle, seat, displayName, netId)
    onPlayerExitVehicle(vehicle)
end)

-- Initialize when script starts
Citizen.CreateThread(function()
    Wait(1000)
    setInitState()
    createElements()
end)