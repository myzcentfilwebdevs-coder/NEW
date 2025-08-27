Config = {}

Config.BusJob = {
    -- Bus Job NPC Configuration
    NPC = {
        model = "s_m_m_pilot_01",
        position = vector4(453.32, -602.34, 28.59, 266.46) -- Bus Depot
    },
    
    -- Bus Model
    BusModel = "bus",
    
    -- Rental Configuration
    Rental = {
        price = 500,
        spawn = vector4(461.65, -602.24, 28.50, 90.0) -- Bus spawn location
    },
    
    -- Payment Configuration
    Payment = {
        base = 25,              -- Base fare per passenger
        distanceBonus = 3,      -- Bonus per 100m distance
        completionBonus = 100   -- Bonus for completing full route
    },
    
    -- Passenger Settings
    PassengerSettings = {
        DropoffRadius = 15.0,   -- Distance for passenger dropoff
        MaxPassengersPerStation = 6,
        BoardingTime = 4000     -- Time in ms for boarding animation
    },
    
    -- Blip Configuration (Enhanced sizes)
    Blips = {
        WaitingStation = {
            sprite = 513,
            color = 3,
            scale = 1.0
        },
        DropoffLocation = {
            sprite = 162,
            color = 1,
            scale = 0.9
        },
        Depot = {
            sprite = 513,
            color = 2,
            scale = 1.2
        }
    },
    
    -- Depot Station (where players return bus)
    DepotStation = {
        position = vector4(453.32, -602.34, 28.59, 266.46),
        name = "Bus Depot"
    },
    
    -- Waiting Stations (Random selection)
    WaitingStations = {
        {
            name = "Downtown Terminal",
            position = vector4(-1037.23, -2737.41, 20.17, 0.0),
            passengerSpawnChance = 0.9,
            maxPassengers = 5
        },
        {
            name = "Airport Bus Stop",
            position = vector4(-1678.07, -3146.47, 13.99, 0.0),
            passengerSpawnChance = 0.8,
            maxPassengers = 6
        },
        {
            name = "Beach Plaza",
            position = vector4(-1553.01, -999.56, 13.02, 0.0),
            passengerSpawnChance = 0.7,
            maxPassengers = 4
        },
        {
            name = "Shopping District",
            position = vector4(126.71, -1037.73, 29.28, 0.0),
            passengerSpawnChance = 0.8,
            maxPassengers = 5
        },
        {
            name = "Business Center",
            position = vector4(-227.74, -2043.85, 27.75, 0.0),
            passengerSpawnChance = 0.9,
            maxPassengers = 6
        },
        {
            name = "Residential Area",
            position = vector4(-14.84, -1441.83, 30.98, 0.0),
            passengerSpawnChance = 0.6,
            maxPassengers = 3
        },
        {
            name = "University Campus",
            position = vector4(-1582.67, -405.41, 42.38, 0.0),
            passengerSpawnChance = 0.8,
            maxPassengers = 5
        },
        {
            name = "Hospital District",
            position = vector4(294.13, -1448.88, 29.97, 0.0),
            passengerSpawnChance = 0.7,
            maxPassengers = 4
        }
    },
    
    -- Dropoff Locations (Categorized)
    DropoffLocations = {
        -- Shopping Centers
        shopping = {
            {
                id = "mall_1",
                name = "Del Perro Mall",
                description = "Popular shopping destination",
                position = vector4(-3188.52, 1044.29, 20.86, 0.0),
                payment_multiplier = 1.2
            },
            {
                id = "mall_2", 
                name = "Rockford Plaza",
                description = "Upscale shopping center",
                position = vector4(-1285.24, -294.52, 39.52, 0.0),
                payment_multiplier = 1.3
            },
            {
                id = "shop_1",
                name = "24/7 Convenience Store",
                description = "Local convenience store",
                position = vector4(25.74, -1347.59, 29.50, 0.0),
                payment_multiplier = 1.0
            }
        },
        
        -- Entertainment
        entertainment = {
            {
                id = "cinema_1",
                name = "Downtown Cinema",
                description = "Movie theater complex",
                position = vector4(300.79, 180.50, 104.39, 0.0),
                payment_multiplier = 1.1
            },
            {
                id = "casino_1",
                name = "Diamond Casino",
                description = "Premier gaming destination",
                position = vector4(925.33, 46.15, 80.90, 0.0),
                payment_multiplier = 1.5
            },
            {
                id = "beach_1",
                name = "Vespucci Beach",
                description = "Popular beach destination",
                position = vector4(-1223.88, -1491.61, 4.38, 0.0),
                payment_multiplier = 1.1
            }
        },
        
        -- Residential
        residential = {
            {
                id = "apt_1",
                name = "Eclipse Towers",
                description = "Luxury apartment complex",
                position = vector4(-773.30, 341.68, 87.00, 0.0),
                payment_multiplier = 1.3
            },
            {
                id = "house_1",
                name = "Vinewood Hills",
                description = "Upscale residential area",
                position = vector4(117.69, 564.09, 184.31, 0.0),
                payment_multiplier = 1.4
            },
            {
                id = "apt_2",
                name = "Downtown Apartments",
                description = "City center housing",
                position = vector4(-268.29, -1432.61, 31.36, 0.0),
                payment_multiplier = 1.0
            }
        },
        
        -- Business
        business = {
            {
                id = "office_1",
                name = "Maze Bank Tower",
                description = "Corporate headquarters",
                position = vector4(-75.01, -826.67, 243.39, 0.0),
                payment_multiplier = 1.6
            },
            {
                id = "office_2",
                name = "Downtown Business District",
                description = "Financial center",
                position = vector4(-1581.22, -558.85, 35.12, 0.0),
                payment_multiplier = 1.3
            },
            {
                id = "factory_1",
                name = "Industrial Zone",
                description = "Manufacturing area",
                position = vector4(716.93, -962.02, 30.40, 0.0),
                payment_multiplier = 1.1
            }
        },
        
        -- Medical/Services
        services = {
            {
                id = "hospital_1",
                name = "Central Los Santos Medical",
                description = "Main hospital",
                position = vector4(294.13, -1448.88, 29.97, 0.0),
                payment_multiplier = 1.2
            },
            {
                id = "police_1",
                name = "Mission Row Police Station",
                description = "LSPD headquarters",
                position = vector4(425.13, -979.55, 30.71, 0.0),
                payment_multiplier = 1.0
            },
            {
                id = "bank_1",
                name = "Fleeca Bank",
                description = "Banking services",
                position = vector4(150.03, -1040.54, 29.37, 0.0),
                payment_multiplier = 1.1
            }
        }
    }
}