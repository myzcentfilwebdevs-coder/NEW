local QBCore = exports['qb-core']:GetCoreObject()
local activeJobs = {}
Config = Config or {}

-- Enhanced job tracking with more detailed statistics
local function CreateJobRecord(playerId, route)
    return {
        playerId = playerId,
        startTime = os.time(),
        route = route,
        totalPassengers = 0,
        totalEarnings = 0,
        totalDistance = 0,
        deliveredPassengers = 0,
        passengerPickups = {},
        passengerDropoffs = {},
        stationsVisited = 0,
        bestStreak = 0,
        currentStreak = 0
    }
end

-- Get job performance multiplier based on streak and time
local function GetPerformanceMultiplier(job)
    local timeMultiplier = 1.0
    local streakMultiplier = 1.0
    
    -- Time-based bonus (working longer gives slight bonus)
    local workTime = os.time() - job.startTime
    if workTime > 1800 then -- 30 minutes
        timeMultiplier = 1.1
    elseif workTime > 3600 then -- 1 hour
        timeMultiplier = 1.2
    end
    
    -- Streak-based bonus
    if job.currentStreak >= 5 then
        streakMultiplier = 1.1
    elseif job.currentStreak >= 10 then
        streakMultiplier = 1.2
    elseif job.currentStreak >= 15 then
        streakMultiplier = 1.3
    end
    
    return timeMultiplier * streakMultiplier
end

QBCore.Functions.CreateCallback('busjob:server:canStartJob', function(source, cb)
    local src = source
    if not activeJobs[src] then
        cb(true)
    else
        cb(false)
    end
end)

QBCore.Functions.CreateCallback('busjob:server:rentBus', function(source, cb)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local rentalPrice = Config.BusJob.Rental.price
    
    if not Player then
        cb(false, 'player_not_found')
        return
    end
    
    if Player.Functions.RemoveMoney('cash', rentalPrice, 'bus-rental') then
        cb(true)
        print('[BusJob] Player ' .. src .. ' rented bus for $' .. rentalPrice)
    else
        -- Try bank if cash insufficient
        if Player.Functions.RemoveMoney('bank', rentalPrice, 'bus-rental') then
            cb(true)
            print('[BusJob] Player ' .. src .. ' rented bus for $' .. rentalPrice .. ' (from bank)')
        else
            cb(false, 'insufficient_funds')
        end
    end
end)

RegisterServerEvent('busjob:server:jobStarted')
AddEventHandler('busjob:server:jobStarted', function(route)
    local src = source
    activeJobs[src] = CreateJobRecord(src, route)
    
    TriggerClientEvent('QBCore:Notify', src, 'Bus job started! Route: ' .. route.name, 'success')
    print('[BusJob] Player ' .. src .. ' started job: ' .. route.name)
end)

RegisterServerEvent('busjob:server:passengerPickup')
AddEventHandler('busjob:server:passengerPickup', function(stationName, passengerCount)
    local src = source
    if activeJobs[src] then
        local job = activeJobs[src]
        job.stationsVisited = job.stationsVisited + 1
        
        -- Record pickup details
        table.insert(job.passengerPickups, {
            station = stationName,
            count = passengerCount,
            timestamp = os.time()
        })
        
        print('[BusJob] Player ' .. src .. ' picked up ' .. passengerCount .. ' passengers at ' .. stationName)
    end
end)

RegisterServerEvent('busjob:server:passengerDropped')
AddEventHandler('busjob:server:passengerDropped', function(payment, distance, destinationName)
    local src = source
    if activeJobs[src] then
        local job = activeJobs[src]
        job.deliveredPassengers = job.deliveredPassengers + 1
        job.totalEarnings = job.totalEarnings + payment
        job.totalDistance = job.totalDistance + (distance or 0)
        job.currentStreak = job.currentStreak + 1
        
        -- Update best streak
        if job.currentStreak > job.bestStreak then
            job.bestStreak = job.currentStreak
        end
        
        -- Apply performance multiplier
        local multiplier = GetPerformanceMultiplier(job)
        local bonusPayment = 0
        
        if multiplier > 1.0 then
            bonusPayment = math.floor(payment * (multiplier - 1.0))
        end
        
        local totalPayment = payment + bonusPayment
        
        local Player = QBCore.Functions.GetPlayer(src)
        if Player then
            Player.Functions.AddMoney('cash', totalPayment, 'passenger-dropoff')
            
            -- Record dropoff details
            table.insert(job.passengerDropoffs, {
                destination = destinationName or "Unknown",
                payment = totalPayment,
                bonusPayment = bonusPayment,
                distance = distance or 0,
                timestamp = os.time()
            })
            
            if bonusPayment > 0 then
                TriggerClientEvent('QBCore:Notify', src, 
                    string.format('Passenger delivered! Base: $%d + Bonus: $%d = $%d', 
                        payment, bonusPayment, totalPayment), 'success')
            end
        end
        
        print('[BusJob] Player ' .. src .. ' delivered passenger. Payment: $' .. totalPayment .. 
              ' (Base: $' .. payment .. ', Bonus: $' .. bonusPayment .. '), Distance: ' .. (distance or 0))
    end
end)

RegisterServerEvent('busjob:server:jobCompleted')
AddEventHandler('busjob:server:jobCompleted', function(totalDeliveredPassengers)
    local src = source
    if activeJobs[src] then
        local job = activeJobs[src]
        
        -- Calculate comprehensive completion bonus
        local baseBonus = Config.BusJob.Payment.bonus or 500
        local passengerMultiplier = Config.BusJob.Payment.passengerMultiplier or 1.5
        local performanceMultiplier = GetPerformanceMultiplier(job)
        
        -- Base completion bonus
        local passengerBonus = math.floor(baseBonus * totalDeliveredPassengers * passengerMultiplier)
        
        -- Distance bonus
        local distanceBonus = 0
        if job.totalDistance > 0 then
            local distanceBonusRate = Config.BusJob.Payment.distanceBonusRate or 0.1
            distanceBonus = math.floor(job.totalDistance * distanceBonusRate)
        end
        
        -- Efficiency bonus (for completing quickly with many passengers)
        local efficiencyBonus = 0
        local jobDuration = os.time() - job.startTime
        if jobDuration > 0 and totalDeliveredPassengers > 0 then
            local passengersPerMinute = totalDeliveredPassengers / (jobDuration / 60)
            if passengersPerMinute > 0.5 then
                efficiencyBonus = math.floor(baseBonus * 0.3)
            elseif passengersPerMinute > 0.3 then
                efficiencyBonus = math.floor(baseBonus * 0.2)
            elseif passengersPerMinute > 0.2 then
                efficiencyBonus = math.floor(baseBonus * 0.1)
            end
        end
        
        -- Streak bonus
        local streakBonus = 0
        if job.bestStreak >= 10 then
            streakBonus = math.floor(baseBonus * 0.5)
        elseif job.bestStreak >= 5 then
            streakBonus = math.floor(baseBonus * 0.3)
        end
        
        -- Apply performance multiplier to all bonuses
        local totalBonus = math.floor((passengerBonus + distanceBonus + efficiencyBonus + streakBonus) * performanceMultiplier)
        
        local Player = QBCore.Functions.GetPlayer(src)
        if Player then
            Player.Functions.AddMoney('cash', totalBonus, 'bus-route-completion-bonus')
        end
        
        -- Calculate job statistics
        local jobDurationMinutes = math.floor((os.time() - job.startTime) / 60)
        local avgFarePerPassenger = job.totalEarnings > 0 and math.floor(job.totalEarnings / math.max(1, totalDeliveredPassengers)) or 0
        local totalJobEarnings = job.totalEarnings + totalBonus
        
        -- Send detailed completion message
        local completionMessage = string.format(
    '🚌 ROUTE COMPLETION REPORT 🚌\n\n' ..
    'Passengers Delivered: %d\n' ..
    'Stations Covered: %d\n' ..
    'Distance Traveled: %.1f km\n' ..
    'Time on Duty: %d minutes\n' ..
    'Average Fare: $%d\n' ..
    'Fare Earnings: $%d\n' ..
    'Company Bonus: $%d\n' ..
    'Total Payout: $%d',
    totalDeliveredPassengers,
    job.stationsVisited,
    job.totalDistance / 1000,
    jobDurationMinutes,
    avgFarePerPassenger,
    job.totalEarnings,
    totalBonus,
    totalJobEarnings
)

        
        TriggerClientEvent('QBCore:Notify', src, completionMessage, 'success', 12000)
        
        print('[BusJob] Player ' .. src .. ' completed job. Stats: ' .. 
              'Passengers: ' .. totalDeliveredPassengers .. 
              ', Earnings: $' .. job.totalEarnings .. 
              ', Bonus: $' .. totalBonus .. 
              ', Duration: ' .. jobDurationMinutes .. 'min')
        
        activeJobs[src] = nil
    end
end)

RegisterServerEvent('busjob:server:jobCancelled')
AddEventHandler('busjob:server:jobCancelled', function()
    local src = source
    if activeJobs[src] then
        local job = activeJobs[src]
        local jobDuration = os.time() - job.startTime
        
        print('[BusJob] Player ' .. src .. ' cancelled job after ' .. math.floor(jobDuration / 60) .. ' minutes. ' ..
              'Delivered: ' .. job.deliveredPassengers .. ' passengers, Earned: $' .. job.totalEarnings)
        
        activeJobs[src] = nil
    end
end)

-- Cleanup on player disconnect
AddEventHandler('playerDropped', function(reason)
    local src = source
    if activeJobs[src] then
        local job = activeJobs[src]
        print('[BusJob] Player ' .. src .. ' disconnected during job. ' ..
              'Delivered: ' .. job.deliveredPassengers .. ' passengers, Earned: $' .. job.totalEarnings)
        activeJobs[src] = nil
    end
end)

-- Get job stats for a player (for admin commands or statistics)
QBCore.Functions.CreateCallback('busjob:server:getJobStats', function(source, cb)
    local src = source
    if activeJobs[src] then
        local job = activeJobs[src]
        local stats = {
            startTime = job.startTime,
            duration = os.time() - job.startTime,
            route = job.route.name,
            deliveredPassengers = job.deliveredPassengers,
            totalEarnings = job.totalEarnings,
            totalDistance = job.totalDistance,
            stationsVisited = job.stationsVisited,
            bestStreak = job.bestStreak,
            currentStreak = job.currentStreak,
            avgFarePerPassenger = job.totalEarnings > 0 and math.floor(job.totalEarnings / math.max(1, job.deliveredPassengers)) or 0,
            performanceMultiplier = GetPerformanceMultiplier(job)
        }
        cb(stats)
    else
        cb(nil)
    end
end)

-- Admin command to get all active jobs
QBCore.Commands.Add('busjobs', 'View all active bus jobs (Admin Only)', {}, false, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player or not QBCore.Functions.HasPermission(src, 'admin') then
        TriggerClientEvent('QBCore:Notify', src, 'No permission!', 'error')
        return
    end
    
    local activeCount = 0
    local jobList = "🚌 ACTIVE BUS JOBS:\n"
    
    for playerId, job in pairs(activeJobs) do
        activeCount = activeCount + 1
        local duration = math.floor((os.time() - job.startTime) / 60)
        jobList = jobList .. string.format(
            "Player %d: %s | %d passengers | $%d earned | %d min\n",
            playerId, job.route.name, job.deliveredPassengers, job.totalEarnings, duration
        )
    end
    
    if activeCount == 0 then
        jobList = jobList .. "No active bus jobs."
    end
    
    TriggerClientEvent('QBCore:Notify', src, jobList, 'primary', 8000)
end, 'admin')

-- Debug command for testing
if GetConvar('bus_debug', 'false') == 'true' then
    QBCore.Commands.Add('bustest', 'Test bus job payment', {{name = 'amount', help = 'Payment amount'}}, true, function(source, args)
        local src = source
        local amount = tonumber(args[1]) or 100
        
        TriggerServerEvent('busjob:server:passengerDropped', amount, 1000, 'Test Location')
        TriggerClientEvent('QBCore:Notify', src, 'Test payment sent: $' .. amount, 'success')
    end)
end