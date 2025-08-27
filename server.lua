local QBCore = exports['qb-core']:GetCoreObject()

-- Player job tracking
local activeJobs = {}

-- Server Callbacks
QBCore.Functions.CreateCallback('busjob:server:canStartJob', function(source, cb)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then
        cb(false)
        return
    end
    
    -- Check if player already has an active job
    if activeJobs[src] then
        cb(false)
        return
    end
    
    cb(true)
end)

QBCore.Functions.CreateCallback('busjob:server:rentBus', function(source, cb)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then
        cb(false, 'player_not_found')
        return
    end
    
    local rentalPrice = Config.BusJob.Rental.price
    
    -- Check if player has enough money
    if Player.PlayerData.money.cash >= rentalPrice then
        Player.Functions.RemoveMoney('cash', rentalPrice, 'bus-rental')
        cb(true)
    elseif Player.PlayerData.money.bank >= rentalPrice then
        Player.Functions.RemoveMoney('bank', rentalPrice, 'bus-rental')
        cb(true)
    else
        cb(false, 'insufficient_funds')
    end
end)

-- Server Events
RegisterNetEvent('busjob:server:jobStarted', function(routeData)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    activeJobs[src] = {
        player = Player,
        route = routeData,
        startTime = os.time(),
        passengersPickedUp = 0,
        passengersDelivered = 0,
        totalEarnings = 0
    }
    
    print('[BusJob] Player ' .. Player.PlayerData.name .. ' started a bus job')
end)

RegisterNetEvent('busjob:server:passengerPickup', function(stationName, passengerCount)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player or not activeJobs[src] then return end
    
    activeJobs[src].passengersPickedUp = activeJobs[src].passengersPickedUp + passengerCount
    
    print('[BusJob] Player ' .. Player.PlayerData.name .. ' picked up ' .. passengerCount .. ' passengers at ' .. stationName)
end)

RegisterNetEvent('busjob:server:passengerDropped', function(fare, distance, destinationName)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player or not activeJobs[src] then return end
    
    -- Pay the player
    Player.Functions.AddMoney('cash', fare, 'bus-passenger-fare')
    
    -- Update job stats
    activeJobs[src].passengersDelivered = activeJobs[src].passengersDelivered + 1
    activeJobs[src].totalEarnings = activeJobs[src].totalEarnings + fare
    
    TriggerClientEvent('QBCore:Notify', src, 'Passenger fare received: $' .. fare, 'success')
    
    print('[BusJob] Player ' .. Player.PlayerData.name .. ' delivered passenger to ' .. destinationName .. ' for $' .. fare)
end)

RegisterNetEvent('busjob:server:jobCompleted', function(totalPassengers)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player or not activeJobs[src] then return end
    
    local job = activeJobs[src]
    local completionBonus = Config.BusJob.Payment.completionBonus or 100
    
    -- Give completion bonus
    if totalPassengers > 0 then
        Player.Functions.AddMoney('cash', completionBonus, 'bus-job-completion')
        TriggerClientEvent('QBCore:Notify', src, 'Job completion bonus: $' .. completionBonus, 'success')
    end
    
    -- Calculate final stats
    local totalEarnings = job.totalEarnings + (totalPassengers > 0 and completionBonus or 0)
    local duration = os.time() - job.startTime
    
    TriggerClientEvent('QBCore:Notify', src, 
        'Job completed!\nPassengers delivered: ' .. totalPassengers .. 
        '\nTotal earnings: $' .. totalEarnings .. 
        '\nDuration: ' .. math.floor(duration / 60) .. ' minutes', 
        'success'
    )
    
    -- Clean up
    activeJobs[src] = nil
    
    print('[BusJob] Player ' .. Player.PlayerData.name .. ' completed bus job - Delivered: ' .. totalPassengers .. ', Earned: $' .. totalEarnings)
end)

RegisterNetEvent('busjob:server:jobCancelled', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Clean up
    activeJobs[src] = nil
    
    TriggerClientEvent('QBCore:Notify', src, 'Bus job cancelled', 'error')
    
    print('[BusJob] Player ' .. Player.PlayerData.name .. ' cancelled bus job')
end)

-- Clean up on player disconnect
AddEventHandler('playerDropped', function(reason)
    local src = source
    if activeJobs[src] then
        activeJobs[src] = nil
        print('[BusJob] Cleaned up job for disconnected player: ' .. src)
    end
end)

-- Resource cleanup
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        activeJobs = {}
        print('[BusJob] Server cleanup completed')
    end
end)