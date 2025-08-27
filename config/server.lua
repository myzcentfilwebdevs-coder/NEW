return {
    job = {
        maxLocations   = 10,        -- max delivery stops per run
        spawnBreakTime = 300000,   -- cooldown (5 mins) between jobs
        bailPrice      = 250,      -- rental fee
        paymentTax     = 15        -- tax percentage
    },

    deliveries = {
        drops       = { min = 3, max = 3 }, -- boxes per delivery
        allowPartial= true,                 -- allow payment for partial routes
        bonusFull   = 100                  -- bonus for completing full route
    },

    vehicleTypes = {
        truck = { model = "mule", capacity = 5, payMultiplier = 1.0 },
        van   = { model = "pony", capacity = 3, payMultiplier = 0.8 }
    },

    payment = {
        baseMin = 100,
        baseMax = 120
    },

    debug = true
}