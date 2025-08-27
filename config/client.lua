Config = {}

Config.BusJob = {
    NPC = {
        model = 'a_m_m_business_01',
        position = vector4(1352.9449, 3607.4919, 34.00, 114.2468),
        description = "Talk to start your bus driving job"
    },

    -- Bus rental configuration
    Rental = {
        coords = vector4(1347.1390, 3604.4553, 34.9019, 194.0733),
        spawn = vector4(1347.1390, 3604.4553, 34.9019, 194.0733),
        price = 500
    },

    BusModel = 'bus',

    Payment = {
        base = 20,   -- base fare per passenger
        bonus = 500, -- base route completion bonus
        distanceBonus = 2, -- bonus per 100m distance for individual fares
        passengerMultiplier = 1.5, -- multiplier for final bonus based on total passengers delivered
        distanceBonusRate = 0.1 -- bonus rate for total distance traveled (optional)
    },

    -- Waiting Stations (where passengers board the bus)
    WaitingStations = {
        -- Major pickup points with high passenger traffic
        {
            id = "paleto_medical",
            position = vector4(-231.6429, 6315.3267, 31.4671, 224.5174),
            name = "Paleto Medical Center",
            description = "Paleto Hospital - High Traffic",
            passengerSpawnChance = 0.8, -- 80% chance of passengers
            maxPassengers = 20,
            waitTime = 60 -- seconds
        },
        {
            id = "paleto_square",
            position = vector4(-86.5103, 6434.3003, 31.4117, 47.4896),
            name = "Paleto Square",
            description = "Central Paleto Shopping Area",
            passengerSpawnChance = 0.2,
            maxPassengers = 20,
            waitTime = 20
        },
        {
            id = "BCSO",
            position = vector4(-427.6915, 6031.3555, 31.4900, 292.4161),
            name = "BCSO Station",
            description = "BCSO Headquarters",
            passengerSpawnChance = 0.5,
            maxPassengers = 20,
            waitTime = 60
        },
        {
            id = "sandy_airfield",
            position = vector4(1775.8014, 3347.5017, 40.6283, 298.4591),
            name = "Sandy Airfield",
            description = "Sandy Shores Airport",
            passengerSpawnChance = 0.7,
            maxPassengers = 20,
            waitTime = 60
        },
        {
            id = "procopio_pier",
            position = vector4(1050.5828, 6504.7905, 21.0869, 194.3493),
            name = "Procopio Pier",
            description = "Fishing & Tourist Attraction",
            passengerSpawnChance = 0.8,
            maxPassengers = 20,
            waitTime = 60
        },
        {
            id = "grapeseed_main",
            position = vector4(1686.2367, 4775.8794, 41.9215, 102.5551),
            name = "Grapeseed Main",
            description = "Agricultural Hub",
            passengerSpawnChance = 0.8,
            maxPassengers = 20,
            waitTime = 60
        },
        {
            id = "Sheriff Sandy",
            position = vector4(1866.6033, 3678.2026, 33.5924, 210.7623),
            name = "Sheriff Sandy",
            description = "Sandy Shores Sheriff's Department",
            passengerSpawnChance = 0.75,
            maxPassengers = 5,
            waitTime = 60
        }
    },

    -- Dropoff Locations (where passengers get off)
    DropoffLocations = {
        -- Residential Areas
        residential = {
            {
                id = "paleto_residential",
                position = vector4(-337.6029, 6253.1851, 31.4925, 315.3944),
                name = "Paleto Residential",
                description = "Suburban Homes near Paleto Bay",
                dropoffChance = 0.1,
                payment_multiplier = 1.0
            },
            {
                id = "paleto_hillside",
                position = vector4(-303.8770, 6376.0122, 30.5317, 219.3772),
                name = "Paleto Hillside",
                description = "Upscale Neighborhood in Paleto",
                dropoffChance = 0.1,
                payment_multiplier = .8
            },
            {
                id = "paleto_cabin",
                position = vector4(-781.8638, 5541.9639, 33.5155, 104.6658),
                name = "Paleto Cabin",
                description = "Small cabins tucked in the forest near Paleto",
                dropoffChance = 0.1,
                payment_multiplier = 1.2
            },
            {
                id = "paleto_beachside",
                position = vector4(429.6274, 6550.6450, 27.6002, 349.8727),
                name = "Paleto Beachside",
                description = "Houses close to the Paleto shoreline",
                dropoffChance = 0.1,
                payment_multiplier = 1.5
            },
        
--CITY
            {
                id = "Los Santos International Airport",
                position = vector4(-1037.8167, -2731.4941, 20.1693, 329.2514),
                name = "Los Santos International Airport",
                description = "Main airport serving Los Santos",
                dropoffChance = 10,
                payment_multiplier = 1.5
            },
            {
                id = "Customs",
                position = vector4(-1102.7850, -1981.9576, 13.1405, 279.2874),
                name = "Customs",
                description = "Customs area at Los Santos International Airport",
                dropoffChance = 10,
                payment_multiplier = 1.5
            },

            {
                id = "The ViceRoy Hotel",
                position = vector4(-876.5607, -1159.4531, 5.2932, 213.7023),
                name = "The ViceRoy Hotel",
                description = "Luxury hotel in Los Santos",
                dropoffChance = 10,
                payment_multiplier = 1.5
            },

            {
                id = "Mission Row Police Department",
                position = vector4(-1149.0389, -802.4852, 15.5317, 218.1563),
                name = "Mission Row Police Department",
                description = "Police station in downtown Los Santos",
                dropoffChance = 10,
                payment_multiplier = 1.5
            },

            {
                id = "Legion Square area",
                position = vector4(142.7278, -945.1485, 29.8280, 71.3645),
                name = "Legion Square area",
                description = "Central area in Los Santos",
                dropoffChance = 10,
                payment_multiplier = 1.5
            },

            {
                id = "Maze Bank Tower",
                position = vector4(-51.3814, -790.8192, 44.2251, 334.2307),
                name = "Maze Bank Tower",
                description = "Iconic skyscraper in Los Santos",
                dropoffChance = 10,
                payment_multiplier = 1.5
            },

            {
                id = "Pillbox Hill area",
                position = vector4(92.4084, -662.8737, 44.2450, 79.1992),
                name = "Pillbox Hill area",
                description = "Residential area in Pillbox Hill",
                dropoffChance = 10,
                payment_multiplier = 1.5
            },

            {
                id = "Vinewood Hills",
                position = vector4(154.5243, 195.2651, 106.2375, 338.0299),
                name = "Vinewood Hills",
                description = "Luxury homes in the Vinewood Hills",
                dropoffChance = 10,
                payment_multiplier = 1.5
            },

            {
                id = "senatorial hills area",
                position = vector4(1227.7558, 227.3785, 105.5480, 68.2378),
                name = "Senatorial Hills",
                description = " Senatorial Hills",
                dropoffChance = 10,
                payment_multiplier = 1.5
            }
        },

        -- Commercial/Business Areas
        commercial = {
            {
                id = "sandy_textile",
                position = vector4(2505.3125, 4101.8022, 38.3497, 61.6180),
                name = "Sandy Textile Depot",
                description = "Rural Trade Hub",
                dropoffChance = 0.1,
                payment_multiplier = 1.1
            },
            {
                id = "sandy_commercial",
                position = vector4(1926.1208, 3714.4417, 32.6264, 214.6962),
                name = "Sandy Commercial",
                description = "Local Business District",
                dropoffChance = 0.1,
                payment_multiplier = 1.3
            },
            {
                id = "grapeseed_market",
                position = vector4(1685.3920, 4940.6489, 42.1901, 45.6444),
                name = "Grapeseed Market",
                description = "Commercial District",
                dropoffChance = 0.1,
                payment_multiplier = 1.1
            },
            {
                id = "paleto_factory",
                position = vector4(-133.4886, 6221.6885, 31.3534, 47.3851),
                name = "Paleto Factory",
                description = "Industrial Facility in Paleto Bay",
                dropoffChance = 0.8,
                payment_multiplier = 1.3
            }
        },

        -- Industrial Areas
        industrial = {
            {
                id = "sandy_industrial",
                position = vector4(1634.2164, 3634.5310, 35.2593, 114.9778),
                name = "El Burro Heights",
                description = "Industrial Complex",
                dropoffChance = 0.1,
                payment_multiplier = 0.9
            },
            {
                id = "Sandy Medical Hospital",
                position = vector4(1829.3452, 3657.8728, 34.0005, 205.5364),
                name = "Strawberry Industrial",
                description = "Manufacturing District",
                dropoffChance = 0.1,
                payment_multiplier = 0.9
            },
            {
                id = "paleto_lumberyard",
                position = vector4(-838.0295, 5436.0068, 34.1644, 41.0279),
                name = "Paleto Lumberyard",
                description = "Lumber Processing Facility",
                dropoffChance = 0.1,
                payment_multiplier = 1.0
            }
        },

        -- Tourist/Entertainment Areas
        tourist = {
            {
                id = "zancudo_river",
                position = vector4(-715.0189, 5779.7729, 17.6652, 53.5885),
                name = "Zancudo River area",
                description = "River that flows from the Alamo Sea out to the ocean.",
                dropoffChance = 0.91,
                payment_multiplier = 1.2
            },
            {
                id = "Mount Josiah",
                position = vector4(-782.2749, 5542.7285, 33.5157, 97.6057),
                name = "Vespucci Canals",
                description = "Venice Beach Area",
                dropoffChance = 0.85,
                payment_multiplier = 1.1
            },
            {
                id = "Procopio Beach",
                position = vector4(158.5726, 6549.5986, 31.9567, 232.9598),
                name = "Vinewood Hills",
                description = "Celebrity Homes",
                dropoffChance = 0.6,
                payment_multiplier = 1.8
            },
            {
                id = "coastal highway at beach.",
                position = vector4(-104.6674, 6416.6743, 31.3933, 47.2064),
                name = "West Vinewood",
                description = "Theater District",
                dropoffChance = 0.8,
                payment_multiplier = 1.3
            },
            {
                id = "Paleto Bay Sheriff's Office",
                position = vector4(-396.9376, 6035.9448, 31.5881, 139.2227),
                name = "Rockford Hills North",
                description = "Upscale Shopping",
                dropoffChance = 0.7,
                payment_multiplier = 1.4
            }
        },

        -- Special/Medical Areas
        special = {
            {
                id = "Procopio Beach",
                position = vector4(-190.0043, 6358.7144, 31.4796, 239.2149),
                name = "Paleto Medical Center",
                description = "Regional Hospital",
                dropoffChance = 0.85,
                payment_multiplier = 1.2
            },
            {
                id = "Alamo Sea side",
                position = vector4(2588.6487, 4730.8662, 33.7198, 53.4810),
                name = "Grapeseed",
                description = "Korean District",
                dropoffChance = 0.75,
                payment_multiplier = 1.1
            }
        }
    },

    -- Route Configuration
    Routes = {
        {
            name = "Downtown Circuit",
            waitingStations = {"pillbox_medical", "legion_square", "mission_row_pd", "davis_avenue"},
            preferredDropoffs = {"residential", "commercial"},
            routeBonus = 100
        },
        {
            name = "Tourist Route",
            waitingStations = {"del_perro_pier", "vinewood_blvd"},
            preferredDropoffs = {"tourist", "special"},
            routeBonus = 150
        },
        {
            name = "Residential Route",
            waitingStations = {"alta_apartments"},
            preferredDropoffs = {"commercial", "industrial"},
            routeBonus = 80
        }
    },

    -- Passenger System Settings
    PassengerSettings = {
        MinPassengers = 3,
        MaxPassengers = 8,
        WaitTime = 25, -- base wait time at stations
        DropoffRadius = 15.0, -- radius for dropoff detection
        BoardingTime = 3, -- seconds per passenger boarding
        ExitTime = 2, -- seconds per passenger exiting
        
        -- Passenger behavior
        SpawnDistance = 50.0, -- distance to spawn passengers around station
        DespawnTime = 300, -- seconds before unused passengers despawn
        TipChance = 0.3, -- 30% chance for passenger tips
        TipAmount = {min = 5, max = 25}
    },

    -- Final return station
    DepotStation = {
        position = vector4(1346.3530, 3603.5234, 34.8945, 188.4264),
        name = "Bus Depot",
        description = "Central Bus Terminal",
        completionBonus = 500
    },

    -- Blip configuration
    Blips = {
        WaitingStation = {
            sprite = 513,
            color = 5,
            scale = 1.2,
            name = "Bus Stop"
        },
        DropoffLocation = {
            sprite = 162,
            color = 3,
            scale = 1.0,
            name = "Dropoff Point"
        },
        Depot = {
            sprite = 513,
            color = 1,
            scale = 1.5,
            name = "Bus Depot"
        }
    }
}