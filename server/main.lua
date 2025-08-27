local config = require 'config.server'
local sharedConfig = require 'config.shared'

-- State storage tables
local bail = {}           -- Player bail amounts
local drops = {}          -- Completed drops counter for payment
local locations = {}      -- Player delivery sessions
local antiAbuse = {}      -- Vehicle spawn abuse prevention
local vehicleData = {}    -- Track spawned vehicles

---@alias NotificationPosition 'top' | 'top-right' | 'top-left' | 'bottom' | 'bottom-right' | 'bottom-left' | 'center-right' | 'center-left'
---@alias NotificationType 'info' | 'warning' | 'success' | 'error'

---Text box popup for player which disappears after a set time.
---@param text table|string text of the notification
---@param notifyType? NotificationType informs default styling. Defaults to 'inform'
---@param duration? integer milliseconds notification will remain on screen. Defaults to 5000
---@param subTitle? string extra text under the title
---@param notifyPosition? NotificationPosition
---@param notifyStyle? table Custom styling. Please refer too https://coxdocs.dev/ox_lib/Modules/Interface/Client/notify#libnotify
---@param notifyIcon? string Font Awesome 6 icon name
---@param notifyIconColor? string Custom color for the icon chosen before
local function notify(player, text, notifyType, duration, subTitle, notifyPosition, notifyStyle, notifyIcon, notifyIconColor)
    if not player or not player.PlayerData then return end
    return exports.qbx_core:Notify(player.PlayerData.source, text, notifyType or 'inform', duration, subTitle, notifyPosition, notifyStyle, notifyIcon, notifyIconColor)
end

---Get player (NO JOB VALIDATION - SIDE JOB FOR EVERYONE)
---@param source number
---@return table|nil player
local function getPlayer(source)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then 
        print(('[TruckerJob] Player not found for source: %d'):format(source))
        return nil
    end

    -- REMOVED JOB VALIDATION - SIDE JOB FOR EVERYONE
    -- if player.PlayerData.job.name ~= 'trucker' then
    --     print(('[TruckerJob] Exploit attempt detected from source: %d (job: %s)'):format(source, player.PlayerData.job.name))
    --     return DropPlayer(source, 'Exploit attempt detected: Invalid job')
    -- end

    return player
end

---Toggle anti spawn abuse flag with configurable cooldown
---@param citizenid string
local function turnAntiSpawnAbuseOn(citizenid)
    if antiAbuse[citizenid] then return end
    
    antiAbuse[citizenid] = true
    CreateThread(function()
        Wait(config.job.spawnBreakTime or 30000) -- Default 30 seconds if not configured
        antiAbuse[citizenid] = nil
    end)
end

---Initialize player delivery session
---@param source number
local function initializePlayerSession(source)
    if locations[source] then return locations[source] end
    
    locations[source] = {
        pool = {},
        done = {},
        current = nil,
        totalDeliveries = 0,
        completedDeliveries = 0,
        sessionStartTime = os.time()
    }
    
    -- Validate delivery configurations exist
    if not sharedConfig.deliveries then
        print('[TruckerJob] ERROR: No delivery configuration found!')
        return locations[source]
    end
    
    -- Create delivery pool with stores
    if sharedConfig.deliveries.stores then
        for i = 1, #sharedConfig.deliveries.stores do
            table.insert(locations[source].pool, { type = "store", index = i })
        end
    end
    
    -- Create delivery pool with houses
    if sharedConfig.deliveries.houses then
        for i = 1, #sharedConfig.deliveries.houses do
            table.insert(locations[source].pool, { type = "house", index = i })
        end
    end
    
    print(('[TruckerJob] Initialized session for source %d with %d locations'):format(source, #locations[source].pool))
    return locations[source]
end

---Clean up player session data
---@param source number
local function cleanupPlayerSession(source)
    if locations[source] then
        print(('[TruckerJob] Cleaning up session for source: %d'):format(source))
        locations[source] = nil
    end
    if vehicleData[source] then
        vehicleData[source] = nil
    end
end

---Check if value exists in table
---@param tbl table
---@param value any
---@return boolean
local function tableIncludes(tbl, value)
    for _, v in ipairs(tbl) do
        if v == value then return true end
    end
    return false
end

---Calculate payment based on completed deliveries and performance
---@param playerDrops number
---@return number payment, number bonus
local function calculatePayment(playerDrops)
    local basePrice = math.random(config.payment?.baseMin or 100, config.payment?.baseMax or 120)
    local bonus = 0
    
    -- Performance-based bonuses
    if playerDrops >= 20 then
        bonus = math.ceil((basePrice / 10) * 12) + 500
    elseif playerDrops >= 15 then
        bonus = math.ceil((basePrice / 10) * 10) + 400
    elseif playerDrops >= 10 then
        bonus = math.ceil((basePrice / 10) * 7) + 300
    elseif playerDrops >= 5 then
        bonus = math.ceil((basePrice / 10) * 5) + 100
    end
    
    local grossPay = (basePrice * playerDrops) + bonus
    local taxAmount = math.ceil((grossPay / 100) * (config.job.paymentTax or 10))
    local netPay = grossPay - taxAmount
    
    return netPay, bonus
end

-- Event Handlers

RegisterNetEvent('qbx_truckerjob:server:returnVehicle', function()
    local player = getPlayer(source)
    if not player then return end

    local citizenid = player.PlayerData.citizenid
    
    -- Refund bail if exists
    if bail[citizenid] then
        player.Functions.AddMoney('cash', bail[citizenid], 'trucker-bail-refunded')
        notify(player, ('Bail refunded: $%d'):format(bail[citizenid]), 'success')
        bail[citizenid] = nil
    end
    
    -- Clean up vehicle tracking
    if vehicleData[source] then
        vehicleData[source] = nil
    end
    
    print(('[TruckerJob] Vehicle returned by source: %d'):format(source))
end)

-- Bail / Vehicle rental
RegisterNetEvent('qbx_truckerjob:server:doBail', function(vehicleModel)
    local player = getPlayer(source)
    if not player then return end

    local citizenid = player.PlayerData.citizenid
    
    -- Check anti-abuse
    if antiAbuse[citizenid] then
        return notify(player, ('Vehicle rental cooldown active. Deposit required: $%d'):format(config.job.bailPrice), 'error')
    end
    
    -- Check if vehicle model is valid
    if not vehicleModel or not sharedConfig.vehicles or not sharedConfig.vehicles[vehicleModel] then
        return notify(player, 'Invalid vehicle selection', 'error')
    end
    
    local money = player.PlayerData.money
    local bailPrice = config.job.bailPrice or 500
    
    -- Check and deduct money
    if money.cash >= bailPrice then
        player.Functions.RemoveMoney('cash', bailPrice, 'trucker-bail-payment')
        notify(player, ('Deposit paid with cash: $%d'):format(bailPrice), 'success')
    elseif money.bank >= bailPrice then
        player.Functions.RemoveMoney('bank', bailPrice, 'trucker-bail-payment')
        notify(player, ('Deposit paid with bank: $%d'):format(bailPrice), 'success')
    else
        return notify(player, ('Insufficient funds. Deposit required: $%d'):format(bailPrice), 'error')
    end
    
    bail[citizenid] = bailPrice
    turnAntiSpawnAbuseOn(citizenid)
    
    -- Reset drops when starting new job
    drops[citizenid] = 0

    TriggerClientEvent('qbx_truckerjob:client:spawnVehicle', source, vehicleModel)
end)

-- 🔹 Record deliveries
RegisterNetEvent('qbx_truckerjob:server:recordDrop', function()
    local player = getPlayer(source)
    if not player then return end

    local citizenid = player.PlayerData.citizenid
    drops[citizenid] = (drops[citizenid] or 0) + 1

    notify(player, ('Delivery completed! Total so far: %d'):format(drops[citizenid]), 'success')
    print(('[TruckerJob] %s completed a drop. Total: %d'):format(citizenid, drops[citizenid]))
end)

-- Payment
RegisterNetEvent('qbx_truckerjob:server:getPaid', function(payAmount, completed, total)
    local player = getPlayer(source)
    if not player then return end

    local citizenid = player.PlayerData.citizenid
    local finalPayment = payAmount
    
    -- If no specific amount provided, calculate based on drops
    if not finalPayment then
        local playerDrops = drops[citizenid] or 0
        
        if playerDrops == 0 then
            return notify(player, 'No deliveries completed', 'error')
        end
        
        local payment, bonus = calculatePayment(playerDrops)
        finalPayment = payment
        drops[citizenid] = nil -- Reset counter
        
        print(('[TruckerJob] Calculated payment for %s: $%d (drops: %d, bonus: $%d)'):format(citizenid, payment, playerDrops, bonus))
    end
    
    -- Add money to player
    player.Functions.AddMoney('cash', finalPayment, 'trucker-salary')
    
    -- Send appropriate notification
    if completed and total then
        notify(player, ('Job completed: %d/%d deliveries | Earned: $%d'):format(completed, total, finalPayment), 'success')
    else
        notify(player, ('Payment received: $%d'):format(finalPayment), 'success')
    end
    
    print(('[TruckerJob] Paid %s: $%d'):format(player.PlayerData.name, finalPayment))
end)

RegisterNetEvent('qbx_truckerjob:server:addDrop', function()
    local player = getPlayer(source)
    if not player then return end
    
    local citizenid = player.PlayerData.citizenid
    drops[citizenid] = (drops[citizenid] or 0) + 1
    
    print(('[TruckerJob] Drop completed by %s. Total: %d'):format(citizenid, drops[citizenid]))
end)

-- Callbacks

lib.callback.register('qbx_truckerjob:server:spawnVehicle', function(source, model)
    local player = getPlayer(source)
    if not player then return nil end

    -- Validate vehicle location configuration
    if not sharedConfig.locations or not sharedConfig.locations.vehicle then
        print('[TruckerJob] ERROR: Vehicle spawn location not configured!')
        return nil
    end
    
    local vehicleLocation = sharedConfig.locations.vehicle
    local plate = ('TRUK%04d'):format(math.random(1, 9999))

    local spawnCoords = vector4(
        vehicleLocation.coords.x, 
        vehicleLocation.coords.y, 
        vehicleLocation.coords.z, 
        vehicleLocation.coords.w or vehicleLocation.heading or 0.0
    )

    local netId = qbx.spawnVehicle({
        model = model,
        spawnSource = spawnCoords,
        warp = true,
        props = {
            plate = plate,
            modLivery = 1,
            color1 = 122,
            color2 = 122,
        }
    })

    if not netId or netId == 0 then
        print(('[TruckerJob] Failed to spawn vehicle model: %s for source: %d'):format(model, source))
        return nil
    end
    
    -- Track vehicle data
    vehicleData[source] = {
        netId = netId,
        plate = plate,
        model = model,
        spawnTime = os.time()
    }
    
    -- Give vehicle keys
    TriggerClientEvent('vehiclekeys:client:SetOwner', source, plate)
    
    print(('[TruckerJob] Spawned vehicle %s (plate: %s) for source: %d'):format(model, plate, source))
    return netId, plate
end)

lib.callback.register('qbx_truckerjob:server:getNewTask', function(source, isInitial)
    local player = getPlayer(source)
    if not player then return 0, 0 end

    -- Initialize or get player session
    local playerSession = initializePlayerSession(source)
    local pool = playerSession.pool

    -- Check if pool is empty
    if #pool == 0 then
        print(('[TruckerJob] No delivery locations available for source: %d'):format(source))
        return 0, 0
    end

    -- Handle initial task assignment
    if isInitial then
        local randomIndex = math.random(#pool)
        playerSession.current = randomIndex
        playerSession.totalDeliveries = math.random(config.job?.minDeliveries or 3, config.job?.maxDeliveries or 8)
        
        local delivery = pool[randomIndex]
        local dropCount = (delivery.type == "house") and 1 or math.random(
            config.deliveries?.drops?.min or 1, 
            config.deliveries?.drops?.max or 3
        )
        
        print(('[TruckerJob] Initial task assigned to source %d: index %d, drops %d'):format(source, randomIndex, dropCount))
        return randomIndex, dropCount, pool
    end

    -- Handle subsequent task assignment
    local currentIndex = playerSession.current
    if currentIndex then
        table.insert(playerSession.done, currentIndex)
        playerSession.completedDeliveries = playerSession.completedDeliveries + 1
    end

    -- Check if maximum deliveries reached
    local maxLocations = config.job?.maxLocations or 10
    if #playerSession.done >= maxLocations or playerSession.completedDeliveries >= playerSession.totalDeliveries then
        print(('[TruckerJob] Max deliveries reached for source: %d'):format(source))
        playerSession.current = nil
        return 0, 0
    end

    -- Find available (not completed) locations
    local availableIndexes = {}
    for i = 1, #pool do
        if not tableIncludes(playerSession.done, i) then
            table.insert(availableIndexes, i)
        end
    end

    if #availableIndexes == 0 then
        print(('[TruckerJob] No available locations remaining for source: %d'):format(source))
        playerSession.current = nil
        return 0, 0
    end

    -- Select next random available location
    local nextIndex = availableIndexes[math.random(#availableIndexes)]
    playerSession.current = nextIndex

    local nextDelivery = pool[nextIndex]
    local dropCount = (nextDelivery.type == "house") and 1 or math.random(
        config.deliveries?.drops?.min or 1, 
        config.deliveries?.drops?.max or 3
    )

    print(('[TruckerJob] Next task assigned to source %d: index %d, drops %d'):format(source, nextIndex, dropCount))
    return nextIndex, dropCount
end)

-- Event handlers for cleanup

AddEventHandler('playerDropped', function(reason)
    local src = source
    print(('[TruckerJob] Player dropped (source: %d, reason: %s)'):format(src, reason))
    cleanupPlayerSession(src)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    
    print('[TruckerJob] Resource stopping, cleaning up data...')
    
    -- Clean up all player sessions
    for source, _ in pairs(locations) do
        cleanupPlayerSession(source)
    end
    
    -- Clear all tables
    bail = {}
    drops = {}
    locations = {}
    antiAbuse = {}
    vehicleData = {}
end)

-- Admin/Debug Commands (if needed)

if config.debug then
    RegisterCommand('trucker:debug', function(source, args)
        local player = getPlayer(source)
        if not player then return end
        
        print(('[TruckerJob] Debug info for %s:'):format(player.PlayerData.name))
        print(('  Bail: %s'):format(bail[player.PlayerData.citizenid] or 'None'))
        print(('  Drops: %d'):format(drops[player.PlayerData.citizenid] or 0))
        print(('  Anti-abuse: %s'):format(antiAbuse[player.PlayerData.citizenid] and 'Active' or 'None'))
        
        if locations[source] then
            local session = locations[source]
            print(('  Session: %d locations, %d done, current: %s'):format(
                #session.pool, 
                #session.done, 
                session.current or 'None'
            ))
        else
            print('  Session: Not initialized')
        end
    end, true)
end

print('[TruckerJob] Server script loaded successfully - SIDE JOB MODE ENABLED')