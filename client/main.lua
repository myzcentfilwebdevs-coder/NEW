local QBCore = exports['qb-core']:GetCoreObject()
local isWorking = false
local hasRentedBus = false
local currentRoute = nil
local busEntity = nil
local busBlip = nil
local npcPed = nil
local activePassengers = {}
local waitingNPCs = {}
local stationBlips = {}
local dropoffBlips = {}
local currentStationIndex = 1
local isWaitingAtStation = false
local stationTimer = 0
local stationNPCs = {} -- Table to store NPCs at each station
local selectedWaitingStations = {} -- Randomly selected stations for current job
local allDropoffLocations = {} -- All possible dropoff locations from config
local stationMarkers = {} -- Table to store marker data for stations
local totalDeliveredPassengers = 0 -- Counter for delivered passengers
local routeDisplay = {} -- In-bus route display

-- Wait for config and create initial setup
CreateThread(function()
    while not Config or not Config.BusJob or not Config.BusJob.NPC do
        Wait(500)
    end
    print('[BusJob] Config loaded, creating NPC and preparing locations')
    CreateBusJobNPC()
    PrepareAllDropoffLocations()
end)

function CreateBusJobNPC()
    local npc = Config.BusJob.NPC
    local modelHash = GetHashKey(npc.model)
    
    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do
        Wait(10)
    end
    
    npcPed = CreatePed(4, modelHash, npc.position.x, npc.position.y, npc.position.z, npc.position.w, false, true)
    SetEntityHeading(npcPed, npc.position.w)
    FreezeEntityPosition(npcPed, true)
    SetEntityInvincible(npcPed, true)
    SetBlockingOfNonTemporaryEvents(npcPed, true)
    
    -- Ox_target interaction - now opens comprehensive NUI
    exports['ox_target']:addLocalEntity(npcPed, {
        {
            name = 'busjob:interact',
            icon = 'fas fa-bus',
            label = 'Bus Job Coordinator',
            distance = 2.5,
            onSelect = function()
                OpenBusJobNUI()
            end
        }
    })

    --  Create Blip for Bus Job NPC
    local blip = AddBlipForCoord(npc.position.x, npc.position.y, npc.position.z)
    SetBlipSprite(blip, 513)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 1.2)
    SetBlipColour(blip, 8)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Bus Job")
    EndTextCommandSetBlipName(blip)

    print('[BusJob] NPC created successfully with blip')
end

-- Prepare all dropoff locations from config into a single table
function PrepareAllDropoffLocations()
    allDropoffLocations = {}
    
    if Config.BusJob.DropoffLocations then
        for category, locations in pairs(Config.BusJob.DropoffLocations) do
            for _, location in ipairs(locations) do
                table.insert(allDropoffLocations, {
                    id = location.id,
                    position = location.position,
                    name = location.name,
                    description = location.description,
                    category = category,
                    payment_multiplier = location.payment_multiplier or 1.0
                })
            end
        end
    end
    
    print('[BusJob] Prepared ' .. #allDropoffLocations .. ' dropoff locations')
end

-- Randomly select waiting stations for the current job
function SelectRandomWaitingStations()
    selectedWaitingStations = {}
    
    if not Config.BusJob.WaitingStations then
        print('[BusJob] No waiting stations configured!')
        return
    end
    
    local availableStations = {}
    for i, station in ipairs(Config.BusJob.WaitingStations) do
        table.insert(availableStations, station)
    end
    
    -- Randomly select 3-5 stations for this job
    local numStations = math.random(3, math.min(5, #availableStations))
    
    for i = 1, numStations do
        if #availableStations > 0 then
            local randomIndex = math.random(1, #availableStations)
            local selectedStation = table.remove(availableStations, randomIndex)
            table.insert(selectedWaitingStations, selectedStation)
        end
    end
    
    print('[BusJob] Selected ' .. #selectedWaitingStations .. ' random waiting stations')
end

function CreateStationBlips()
    -- Clear existing blips
    for _, blip in ipairs(stationBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    stationBlips = {}
    
    -- Create blips only for selected stations
    for i, station in ipairs(selectedWaitingStations) do
        local blip = AddBlipForCoord(station.position.x, station.position.y, station.position.z)
        SetBlipSprite(blip, Config.BusJob.Blips and Config.BusJob.Blips.WaitingStation and Config.BusJob.Blips.WaitingStation.sprite or 513)
        SetBlipColour(blip, Config.BusJob.Blips and Config.BusJob.Blips.WaitingStation and Config.BusJob.Blips.WaitingStation.color or 5)
        SetBlipScale(blip, Config.BusJob.Blips and Config.BusJob.Blips.WaitingStation and Config.BusJob.Blips.WaitingStation.scale or 1.2) -- Increased size
        SetBlipAsShortRange(blip, true)
        
        -- Make the blip non-movable/non-draggable
        SetBlipAsMissionCreatorBlip(blip, true)
        SetBlipDisplay(blip, 2) -- Show on both main map and minimap
        
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Bus Stop - " .. station.name)
        EndTextCommandSetBlipName(blip)
        
        stationBlips[i] = blip
    end
    print('[BusJob] Created ' .. #stationBlips .. ' station blips')
end

-- Create blinking markers at stations
function CreateStationMarkers()
    stationMarkers = {}
    
    for i, station in ipairs(selectedWaitingStations) do
        stationMarkers[i] = {
            position = station.position,
            name = station.name,
            isActive = true,
            blinkTimer = 0
        }
    end
    
    CreateThread(function()
        while isWorking do
            for i, marker in ipairs(stationMarkers) do
                if marker.isActive then
                    local pos = marker.position
                    
                    -- Create blinking effect
                    marker.blinkTimer = marker.blinkTimer + GetFrameTime()
                    local alpha = math.floor(math.abs(math.sin(marker.blinkTimer * 3)) * 255)
                    
                    -- Draw marker
                    DrawMarker(1, pos.x, pos.y, pos.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 
                        5.0, 5.0, 2.0, 0, 150, 255, alpha, false, true, 2, false, nil, nil, false) -- Increased size
                    
                    -- Check if player is near
                    local playerCoords = GetEntityCoords(PlayerPedId())
                    local distance = #(playerCoords - vector3(pos.x, pos.y, pos.z))
                    
                    if distance < 15.0 and GetVehiclePedIsIn(PlayerPedId(), false) == busEntity then
                        DrawText3D(pos.x, pos.y, pos.z + 0.5, 
                            "~g~" .. marker.name .. "~w~\nPress ~b~[E]~w~ to board passengers")
                        
                        if IsControlJustPressed(0, 38) and distance < 15.0 then -- E key
                            StartAutomaticBoardingProcess(i)
                        end
                    end
                end
            end
            Wait(0)
        end
    end)
end

function SpawnWaitingNPCsAtStations()
    -- Clear any existing station NPCs
    ClearStationNPCs()
    
    local pedModels = {'a_f_y_business_01', 'a_m_y_business_01', 'a_f_m_fatwhite_01', 'a_m_m_afriamer_01', 'a_f_y_hipster_01', 'a_m_y_hipster_01', 'a_f_m_tramp_01', 'a_m_m_tramp_01'}
    
    for i, station in ipairs(selectedWaitingStations) do
        stationNPCs[i] = {}
        
        -- Use station's passenger spawn chance and max passengers
        local spawnChance = station.passengerSpawnChance or 0.8
        local maxPassengers = station.maxPassengers or 5
        
        if math.random() < spawnChance then
            local numNPCs = math.random(2, maxPassengers)
            
            for j = 1, numNPCs do
                local model = GetHashKey(pedModels[math.random(1, #pedModels)])
                RequestModel(model)
                
                while not HasModelLoaded(model) do
                    Wait(10)
                end
                
                -- Get a random position near the station
                local spawnCoords = GetRandomCoordsNearPoint(station.position, 5.0)
                
                -- Make sure the NPC is on the ground
                local groundZ = spawnCoords.z
                local found, groundZCoord = GetGroundZFor_3dCoord(spawnCoords.x, spawnCoords.y, spawnCoords.z + 5.0, false)
                if found then
                    groundZ = groundZCoord
                else
                    groundZ = spawnCoords.z
                end
                
                local npc = CreatePed(4, model, spawnCoords.x, spawnCoords.y, groundZ, math.random(0, 360), false, true)
                
                SetEntityInvincible(npc, true)
                SetBlockingOfNonTemporaryEvents(npc, true)
                SetPedRelationshipGroupHash(npc, GetHashKey("CIVMALE"))
                
                -- Assign random destination and calculate initial fare
                local destination = GetRandomDropoffDestination()
                local distance = CalculateDistance(station.position, destination.position)
                local baseFare = Config.BusJob.Payment.base or 20
                local distanceMultiplier = Config.BusJob.Payment.distanceBonus or 2
                local fare = math.floor((baseFare + (distance * distanceMultiplier / 100)) * destination.payment_multiplier)
                
                -- Store NPC data
                local npcData = {
                    entity = npc,
                    destination = destination,
                    pickupLocation = station.position,
                    fare = fare,
                    distance = distance,
                    boarded = false,
                    stationIndex = i
                }
                
                -- Give the NPC random waiting animations
                TaskStartScenarioInPlace(npc, "WORLD_HUMAN_STAND_MOBILE", 0, true)
                
                table.insert(stationNPCs[i], npcData)
                SetModelAsNoLongerNeeded(model)
            end
        end
    end
    
    print('[BusJob] Spawned NPCs at ' .. #selectedWaitingStations .. ' stations')
end

-- Enhanced automatic boarding process
function StartAutomaticBoardingProcess(stationIndex)
    local station = selectedWaitingStations[stationIndex]
    
    if not stationNPCs[stationIndex] or #stationNPCs[stationIndex] == 0 then
        QBCore.Functions.Notify('No passengers waiting at this station.', 'error')
        stationMarkers[stationIndex].isActive = false
        return
    end
    
    -- Check for unboarded passengers
    local availablePassengers = {}
    for _, npcData in ipairs(stationNPCs[stationIndex]) do
        if not npcData.boarded and DoesEntityExist(npcData.entity) then
            table.insert(availablePassengers, npcData)
        end
    end
    
    if #availablePassengers == 0 then
        QBCore.Functions.Notify('All passengers from this station have already boarded.', 'info')
        stationMarkers[stationIndex].isActive = false
        return
    end
    
    QBCore.Functions.Notify('Boarding passengers automatically...', 'primary')
    
    -- Board all available passengers with a delay between each
    CreateThread(function()
        for i, npcData in ipairs(availablePassengers) do
            if DoesEntityExist(npcData.entity) and not npcData.boarded then
                Wait(1500) -- Delay between boardings
                BoardIndividualPassenger(npcData, stationIndex)
            end
        end
        
        -- Mark station as completed and notify server
        stationMarkers[stationIndex].isActive = false
        TriggerServerEvent('busjob:server:passengerPickup', station.name, #availablePassengers)
        
        -- Remove the station blip after boarding passengers
        if stationBlips[stationIndex] and DoesBlipExist(stationBlips[stationIndex]) then
            RemoveBlip(stationBlips[stationIndex])
            stationBlips[stationIndex] = nil
        end
        
        QBCore.Functions.Notify('All passengers boarded from ' .. station.name, 'success')
    end)
end

-- Individual passenger boarding
function BoardIndividualPassenger(npcData, stationIndex)
    if npcData.boarded or not DoesEntityExist(npcData.entity) then return end
    
    npcData.boarded = true
    
    -- Add to active passengers
    table.insert(activePassengers, {
        id = #activePassengers + 1,
        destination = npcData.destination,
        fare = npcData.fare,
        distance = npcData.distance,
        pickupLocation = npcData.pickupLocation,
        npcEntity = npcData.entity,
        boardedAt = GetGameTimer()
    })
    
    -- Animate NPC boarding
    local busCoords = GetEntityCoords(busEntity)
    local doorOffset = GetOffsetFromEntityInWorldCoords(busEntity, -2.0, 0.0, 0.0)
    
    -- Clear any existing tasks
    ClearPedTasks(npcData.entity)
    TaskGoToCoordAnyMeans(npcData.entity, doorOffset.x, doorOffset.y, doorOffset.z, 1.5, 0, 0, 786603, 0xbf800000)
    
    -- Delete NPC after boarding animation
    SetTimeout(4000, function()
        if DoesEntityExist(npcData.entity) then
            DeleteEntity(npcData.entity)
        end
    end)
    
    QBCore.Functions.Notify('Passenger boarded! Destination: ' .. npcData.destination.name .. ' ($' .. npcData.fare .. ')', 'success')
    
    -- Create dropoff blip
    CreateDropoffBlipForPassenger(npcData.destination)
    UpdateRouteDisplay()
end

function ClearStationNPCs()
    for i, npcs in ipairs(stationNPCs) do
        if npcs then
            for j, npcData in ipairs(npcs) do
                if DoesEntityExist(npcData.entity) then
                    DeleteEntity(npcData.entity)
                end
            end
        end
    end
    stationNPCs = {}
end

function GetRandomCoordsNearPoint(center, radius)
    local angle = math.random() * 2 * math.pi
    local distance = math.random() * radius
    return {
        x = center.x + distance * math.cos(angle),
        y = center.y + distance * math.sin(angle),
        z = center.z
    }
end

-- Enhanced distance calculation
function CalculateDistance(pos1, pos2)
    return math.sqrt(
        (pos1.x - pos2.x)^2 + 
        (pos1.y - pos2.y)^2 + 
        (pos1.z - pos2.z)^2
    )
end

-- Comprehensive NUI System
function OpenBusJobNUI()
    local playerCoords = GetEntityCoords(PlayerPedId())
    local nearestDestination = nil
    local nearestDistance = math.huge
    
    -- Find nearest destination if passengers aboard
    if #activePassengers > 0 then
        for _, passenger in ipairs(activePassengers) do
            local destCoords = vector3(passenger.destination.position.x, passenger.destination.position.y, passenger.destination.position.z)
            local distance = #(playerCoords - destCoords)
            if distance < nearestDistance then
                nearestDistance = distance
                nearestDestination = passenger.destination
            end
        end
    end
    
    -- Prepare passenger list for NUI
    local passengerList = {}
    for _, passenger in ipairs(activePassengers) do
        local destCoords = vector3(passenger.destination.position.x, passenger.destination.position.y, passenger.destination.position.z)
        local distance = #(playerCoords - destCoords)
        table.insert(passengerList, {
            destination = passenger.destination.name,
            category = passenger.destination.category,
            fare = passenger.fare,
            distance = math.floor(distance),
            isNearest = nearestDestination and passenger.destination.id == nearestDestination.id
        })
    end
    
    -- Sort passengers by distance
    table.sort(passengerList, function(a, b) return a.distance < b.distance end)
    
    -- Prepare station list
    local stationList = {}
    for i, station in ipairs(selectedWaitingStations) do
        local marker = stationMarkers[i]
        table.insert(stationList, {
            name = station.name,
            description = station.description,
            active = marker and marker.isActive or false,
            distance = math.floor(#(playerCoords - vector3(station.position.x, station.position.y, station.position.z)))
        })
    end
    
    local menuData = {
        title = "Los Santos Bus Company",
        subtitle = "Professional Transportation Services",
        isWorking = isWorking,
        hasRentedBus = hasRentedBus,
        rentalPrice = Config.BusJob.Rental.price,
        currentRoute = currentRoute and {
            name = currentRoute.name,
            stationCount = #selectedWaitingStations
        } or nil,
        activePassengers = #activePassengers,
        totalDelivered = totalDeliveredPassengers,
        passengerList = passengerList,
        stationList = stationList,
        nearestDestination = nearestDestination and {
            name = nearestDestination.name,
            distance = math.floor(nearestDistance)
        } or nil,
        jobStats = isWorking and {
            earnings = CalculateCurrentEarnings(),
            stationsVisited = CountCompletedStations(),
            efficiency = CalculateEfficiency()
        } or nil
    }
    
    SetNuiFocus(true, true)
    SendNUIMessage({
        type = "openBusNUI",
        data = menuData
    })
end

-- Helper functions for statistics
function CalculateCurrentEarnings()
    local totalEarnings = 0
    -- This would be tracked properly in a real implementation
    return totalEarnings
end

function CountCompletedStations()
    local completed = 0
    for _, marker in ipairs(stationMarkers) do
        if not marker.isActive then
            completed = completed + 1
        end
    end
    return completed
end

function CalculateEfficiency()
    if totalDeliveredPassengers == 0 then return 0 end
    local totalStations = #selectedWaitingStations
    if totalStations == 0 then return 0 end
    return math.floor((totalDeliveredPassengers / totalStations) * 100)
end

-- Enhanced NUI Callbacks with proper closing
RegisterNUICallback('closeNUI', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('startJob', function(data, cb)
    if not isWorking then
        StartBusJob()
    end
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('rentBus', function(data, cb)
    if isWorking and not hasRentedBus then
        RentBus()
    end
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('finishJob', function(data, cb)
    if isWorking then
        FinishJob()
    end
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('cancelJob', function(data, cb)
    if isWorking then
        CancelJob()
    end
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('navigateToNearest', function(data, cb)
    NavigateToNearestDestination()
    cb('ok')
end)

RegisterNUICallback('navigateToDestination', function(data, cb)
    local destinationName = data.destination
    NavigateToSpecificDestination(destinationName)
    cb('ok')
end)

RegisterNUICallback('refreshData', function(data, cb)
    -- Refresh NUI data without closing
    OpenBusJobNUI()
    cb('ok')
end)

-- Function to navigate to specific destination
function NavigateToSpecificDestination(destinationName)
    if #activePassengers == 0 then
        QBCore.Functions.Notify('No passengers aboard!', 'error')
        return
    end
    
    for _, passenger in ipairs(activePassengers) do
        if passenger.destination.name == destinationName then
            SetWaypointOff()
            SetNewWaypoint(passenger.destination.position.x, passenger.destination.position.y)
            QBCore.Functions.Notify('Navigation set to: ' .. destinationName, 'success')
            return
        end
    end
    
    QBCore.Functions.Notify('Destination not found!', 'error')
end

-- Enhanced ESC key handling
CreateThread(function()
    while true do
        Wait(0)
        
        -- Check if NUI is focused and ESC is pressed
        if HasNuiFocus() then
            if IsControlJustPressed(0, 322) then -- ESC key
                SetNuiFocus(false, false)
                SendNUIMessage({
                    type = "forceClose"
                })
            end
        end
    end
end)

function StartBusJob()
    QBCore.Functions.TriggerCallback('busjob:server:canStartJob', function(canStart)
        if canStart then
            isWorking = true
            activePassengers = {}
            totalDeliveredPassengers = 0
            
            -- Select random waiting stations for this job
            SelectRandomWaitingStations()
            
            if #selectedWaitingStations == 0 then
                QBCore.Functions.Notify('No stations available! Contact an administrator.', 'error')
                isWorking = false
                return
            end
            
            currentRoute = {
                name = "Random Route - " .. #selectedWaitingStations .. " Stations",
                stations = selectedWaitingStations
            }
            
            -- Create blips for selected stations
            CreateStationBlips()
            
            -- Spawn NPCs at selected stations
            SpawnWaitingNPCsAtStations()
            
            QBCore.Functions.Notify('Random route created with ' .. #selectedWaitingStations .. ' stations! Rent a bus to begin.', 'success')
            TriggerServerEvent('busjob:server:jobStarted', currentRoute)
        else
            QBCore.Functions.Notify('You already have an active job!', 'error')
        end
    end)
end

function RentBus()
    QBCore.Functions.TriggerCallback('busjob:server:rentBus', function(success, reason)
        if success then
            SpawnBus()
        else
            if reason == 'insufficient_funds' then
                QBCore.Functions.Notify('Not enough money! Need $' .. Config.BusJob.Rental.price, 'error')
            else
                QBCore.Functions.Notify('Failed to rent bus!', 'error')
            end
        end
    end)
end

function SpawnBus()
    local model = GetHashKey(Config.BusJob.BusModel)
    local spawnCoords = Config.BusJob.Rental.spawn
    
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(10)
    end
    
    busEntity = CreateVehicle(model, spawnCoords.x, spawnCoords.y, spawnCoords.z, spawnCoords.w, true, false)
    
    if DoesEntityExist(busEntity) then
        hasRentedBus = true
        SetVehicleNumberPlateText(busEntity, "BUS"..math.random(100,999))
        SetVehicleEngineOn(busEntity, true, true, false)
        
        -- Give keys to player
        local plate = QBCore.Functions.GetPlate(busEntity)
        TriggerEvent("vehiclekeys:client:SetOwner", plate)
        
        -- Create bus blip
        busBlip = AddBlipForEntity(busEntity)
        SetBlipSprite(busBlip, 513)
        SetBlipColour(busBlip, 3)
        SetBlipScale(busBlip, 1.0)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Your Bus")
        EndTextCommandSetBlipName(busBlip)
        
        TaskWarpPedIntoVehicle(PlayerPedId(), busEntity, -1)
        
        -- Start station markers
        CreateStationMarkers()
        
        -- Initialize route display
        InitializeRouteDisplay()
        
        QBCore.Functions.Notify('Bus rented! Look for blinking markers at stations to pick up passengers.', 'success')
        
        CreateThread(JobMainLoop)
    else
        QBCore.Functions.Notify('Failed to spawn bus!', 'error')
    end
    
    SetModelAsNoLongerNeeded(model)
end

-- Initialize route display inside bus
function InitializeRouteDisplay()
    routeDisplay = {}
    CreateThread(function()
        while isWorking and hasRentedBus do
            if GetVehiclePedIsIn(PlayerPedId(), false) == busEntity then
                if DisplayRouteInformation then
                    DisplayRouteInformation()
                end
            end
            Wait(0) -- para smooth draw
        end
    end)
end

function UpdateRouteDisplay()
    -- Route display is updated automatically in the display loop
end

function JobMainLoop()
    while isWorking and hasRentedBus do
        CheckPassengerDropoffs()
        
        -- Check if all passengers delivered and all stations visited
        if #activePassengers == 0 and AllStationsVisited() then
            QBCore.Functions.Notify('All passengers delivered! Return to depot to complete job.', 'success')
            CreateDepotBlip()
        end
        
        Wait(1000)
    end
end

function AllStationsVisited()
    for _, marker in ipairs(stationMarkers) do
        if marker.isActive then
            return false
        end
    end
    return true
end

function CreateDepotBlip()
    if Config.BusJob.DepotStation then
        local depot = Config.BusJob.DepotStation
        local blip = AddBlipForCoord(depot.position.x, depot.position.y, depot.position.z)
        SetBlipSprite(blip, Config.BusJob.Blips and Config.BusJob.Blips.Depot and Config.BusJob.Blips.Depot.sprite or 513)
        SetBlipColour(blip, Config.BusJob.Blips and Config.BusJob.Blips.Depot and Config.BusJob.Blips.Depot.color or 1)
        SetBlipScale(blip, Config.BusJob.Blips and Config.BusJob.Blips.Depot and Config.BusJob.Blips.Depot.scale or 1.5) -- Increased size
        
        -- Make the blip non-movable/non-draggable
        SetBlipAsMissionCreatorBlip(blip, true)
        SetBlipDisplay(blip, 2) -- Show on both main map and minimap
        
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Bus Depot - Return Here")
        EndTextCommandSetBlipName(blip)
        SetBlipRoute(blip, true)
    end
end

-- Get a completely random dropoff destination from all categories
function GetRandomDropoffDestination()
    if #allDropoffLocations == 0 then
        print('[BusJob] No dropoff locations available!')
        return {
            id = "default",
            position = vector4(0, 0, 0, 0),
            name = "Unknown Location",
            description = "Default",
            category = "unknown",
            payment_multiplier = 1.0
        }
    end
    
    local randomIndex = math.random(1, #allDropoffLocations)
    return allDropoffLocations[randomIndex]
end

function CreateDropoffBlipForPassenger(destination)
    -- Check if blip already exists for this destination
    for _, blip in ipairs(dropoffBlips) do
        if blip.destinationId == destination.id then
            return -- Blip already exists
        end
    end
    
    local blip = AddBlipForCoord(destination.position.x, destination.position.y, destination.position.z)
    SetBlipSprite(blip, Config.BusJob.Blips and Config.BusJob.Blips.DropoffLocation and Config.BusJob.Blips.DropoffLocation.sprite or 162)
    SetBlipColour(blip, Config.BusJob.Blips and Config.BusJob.Blips.DropoffLocation and Config.BusJob.Blips.DropoffLocation.color or 3)
    SetBlipScale(blip, Config.BusJob.Blips and Config.BusJob.Blips.DropoffLocation and Config.BusJob.Blips.DropoffLocation.scale or 1.0) -- Increased size
    SetBlipAsShortRange(blip, true)
    
    -- Make the blip non-movable/non-draggable
    SetBlipAsMissionCreatorBlip(blip, true)
    SetBlipDisplay(blip, 2) -- Show on both main map and minimap
    
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Dropoff - " .. destination.name)
    EndTextCommandSetBlipName(blip)
    
    table.insert(dropoffBlips, {
        blip = blip,
        destinationId = destination.id
    })
end

-- ENHANCED DROPOFF SYSTEM with better detection and NPC dropping
function CheckPassengerDropoffs()
    if #activePassengers == 0 then return end
    
    local playerCoords = GetEntityCoords(PlayerPedId())
    local dropoffRadius = (Config.BusJob.PassengerSettings and Config.BusJob.PassengerSettings.DropoffRadius) or 15.0
    
    for i = #activePassengers, 1, -1 do
        local passenger = activePassengers[i]
        local destCoords = vector3(passenger.destination.position.x, passenger.destination.position.y, passenger.destination.position.z)
        local distance = #(playerCoords - destCoords)
        
        if distance < 50.0 then
            -- Draw enhanced dropoff marker
            DrawDropoffMarker(destCoords, passenger.destination.name, passenger.fare, distance)
            
            if distance < dropoffRadius then
                local busSpeed = GetEntitySpeed(busEntity)
                -- Allow dropoff if bus is slow or stopped
                if busSpeed < 2.0 then
                    -- Start dropoff process if not already started
                    if not passenger.droppingOff then
                        passenger.droppingOff = true
                        
                        CreateThread(function()
                            QBCore.Functions.Notify('Passengers exiting at ' .. passenger.destination.name .. '...', 'primary')
                            
                            -- Simulate passengers getting off the bus
                            for exitCount = 1, math.random(1, 3) do
                                Wait(1000)
                                -- Create exit animation effect
                                local exitCoord = GetOffsetFromEntityInWorldCoords(busEntity, -2.0, 0.0, 0.0)
                                -- You could spawn a temp NPC here for visual effect
                            end
                            
                            -- Complete the dropoff
                            TriggerServerEvent('busjob:server:passengerDropped', passenger.fare, passenger.distance, passenger.destination.name)
                            
                            -- Remove passenger from active list
                            for j = #activePassengers, 1, -1 do
                                if activePassengers[j].id == passenger.id then
                                    table.remove(activePassengers, j)
                                    break
                                end
                            end
                            
                            totalDeliveredPassengers = totalDeliveredPassengers + 1
                            
                            QBCore.Functions.Notify('Passengers dropped off at ' .. passenger.destination.name .. '! Earned $' .. passenger.fare, 'success')
                            
                            -- Update route display
                            UpdateRouteDisplay()
                            
                            -- Remove dropoff blip if no more passengers going there
                            local stillNeeded = false
                            for _, remainingPassenger in ipairs(activePassengers) do
                                if remainingPassenger.destination.id == passenger.destination.id then
                                    stillNeeded = true
                                    break
                                end
                            end
                            
                            if not stillNeeded then
                                RemoveDropoffBlip(passenger.destination.id)
                            end
                        end)
                    end
                else
                    DrawText3D(destCoords.x, destCoords.y, destCoords.z + 2.5, 
                        "~r~SLOW DOWN TO DROP OFF PASSENGERS~w~\n~y~Current Speed: " .. math.floor(busSpeed * 3.6) .. " km/h")
                end
            end
        end
    end
end

-- Enhanced dropoff marker function with better visuals
function DrawDropoffMarker(coords, name, fare, distance)
    local alpha = math.floor(math.abs(math.sin(GetGameTimer() / 1000.0 * 2)) * 255)
    
    -- Draw large pulsing outer marker
    DrawMarker(1, coords.x, coords.y, coords.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 
        12.0, 12.0, 3.0, 255, 165, 0, alpha, false, true, 2, false, nil, nil, false)
    
    -- Draw inner marker
    DrawMarker(1, coords.x, coords.y, coords.z - 0.5, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 
        6.0, 6.0, 2.0, 0, 255, 0, 200, false, true, 2, false, nil, nil, false)
    
    -- Draw center marker
    DrawMarker(1, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 
        2.0, 2.0, 1.0, 255, 255, 255, 255, false, true, 2, false, nil, nil, false)
    
    -- Draw info text
    if distance < 35.0 then
        DrawText3D(coords.x, coords.y, coords.z + 2.0, 
            "~g~" .. name .. "~w~\n~y~Fare: $" .. fare .. "~w~\n~b~Distance: " .. math.floor(distance) .. "m\n~w~Stop here to drop off passengers")
    end
end

function RemoveDropoffBlip(destinationId)
    for i, blipData in ipairs(dropoffBlips) do
        if blipData.destinationId == destinationId then
            RemoveBlip(blipData.blip)
            table.remove(dropoffBlips, i)
            break
        end
    end
end

-- Passenger Information Functions
function ShowPassengerInfo()
    if not hasRentedBus then
        QBCore.Functions.Notify('You need to rent a bus first!', 'error')
        return
    end
    
    local playerCoords = GetEntityCoords(PlayerPedId())
    local info = "🚌 BUS PASSENGER INFORMATION 🚌\n\n"
    
    -- Route information
    info = info .. "Route: " .. (currentRoute and currentRoute.name or "No Route") .. "\n"
    info = info .. "Active Passengers: " .. #activePassengers .. "\n"
    info = info .. "Total Delivered: " .. totalDeliveredPassengers .. "\n\n"
    
    if #activePassengers > 0 then
        info = info .. "CURRENT DESTINATIONS:\n"
        
        -- Sort passengers by distance
        local sortedPassengers = {}
        for _, passenger in ipairs(activePassengers) do
            local destCoords = vector3(passenger.destination.position.x, passenger.destination.position.y, passenger.destination.position.z)
            local distance = #(playerCoords - destCoords)
            table.insert(sortedPassengers, {
                passenger = passenger,
                distance = distance
            })
        end
        
        table.sort(sortedPassengers, function(a, b) return a.distance < b.distance end)
        
        for i, data in ipairs(sortedPassengers) do
            local passenger = data.passenger
            local distance = data.distance
            local nearest = i == 1 and " ⭐ NEAREST" or ""
            
            info = info .. string.format("• %s%s\n", passenger.destination.name, nearest)
            info = info .. string.format("  Category: %s | Fare: $%d | Distance: %.0fm\n", 
                passenger.destination.category, passenger.fare, distance)
        end
        
        info = info .. "\nPress H to navigate to nearest destination"
    else
        info = info .. "No passengers aboard.\nHead to blinking markers to pick up passengers."
    end
    
    QBCore.Functions.Notify(info, 'primary', 10000)
end

-- Navigate to nearest passenger destination
function NavigateToNearestDestination()
    if #activePassengers == 0 then
        QBCore.Functions.Notify('No passengers aboard to navigate to!', 'error')
        return
    end
    
    local playerCoords = GetEntityCoords(PlayerPedId())
    local nearestDistance = math.huge
    local nearestDestination = nil
    
    -- Find the nearest destination
    for _, passenger in ipairs(activePassengers) do
        local destCoords = vector3(passenger.destination.position.x, passenger.destination.position.y, passenger.destination.position.z)
        local distance = #(playerCoords - destCoords)
        
        if distance < nearestDistance then
            nearestDistance = distance
            nearestDestination = passenger.destination
        end
    end
    
    if nearestDestination then
        -- Clear any existing waypoint
        SetWaypointOff()
        
        -- Set waypoint to nearest destination
        SetNewWaypoint(nearestDestination.position.x, nearestDestination.position.y)
        
        QBCore.Functions.Notify('Navigation set to nearest destination: ' .. nearestDestination.name .. ' (' .. math.floor(nearestDistance) .. 'm away)', 'success')
    end
end

-- Add keyboard control for navigation
CreateThread(function()
    while true do
        Wait(0)
        if isWorking and hasRentedBus then
            if IsControlJustPressed(0, 101) then -- H key
                NavigateToNearestDestination()
            end
        else
            Wait(1000)
        end
    end
end)

function FinishJob()
    if totalDeliveredPassengers == 0 then
        QBCore.Functions.Notify('No passengers delivered! Job cancelled.', 'error')
        CancelJob()
        return
    end
    
    CleanupJob()
    TriggerServerEvent('busjob:server:jobCompleted', totalDeliveredPassengers)
    QBCore.Functions.Notify('Job completed! Total passengers delivered: ' .. totalDeliveredPassengers, 'success')
end

function CancelJob()
    CleanupJob()
    TriggerServerEvent('busjob:server:jobCancelled')
    QBCore.Functions.Notify('Job cancelled.', 'info')
end

function CleanupJob()
    isWorking = false
    hasRentedBus = false
    currentRoute = nil
    activePassengers = {}
    selectedWaitingStations = {}
    stationMarkers = {}
    totalDeliveredPassengers = 0
    routeDisplay = {}
    
    if DoesEntityExist(busEntity) then
        DeleteEntity(busEntity)
        busEntity = nil
    end
    
    if busBlip then
        RemoveBlip(busBlip)
        busBlip = nil
    end
    
    ClearStationNPCs()
    
    for _, blipData in ipairs(dropoffBlips) do
        if DoesBlipExist(blipData.blip) then
            RemoveBlip(blipData.blip)
        end
    end
    dropoffBlips = {}
    
    for i, blip in ipairs(stationBlips) do
        if blip and DoesBlipExist(blip) then
            SetBlipRoute(blip, false)
            RemoveBlip(blip)
        end
    end
    stationBlips = {}
end

function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextEntry("STRING")
        SetTextCentre(true)
        AddTextComponentString(text)
        DrawText(_x, _y)
        local factor = (string.len(text)) / 370
        DrawRect(_x, _y + 0.0125, 0.015 + factor, 0.03, 0, 0, 0, 75)
    end
end

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        CleanupJob()
        if DoesEntityExist(npcPed) then
            DeleteEntity(npcPed)
        end
    end
end)