return {
    locations = {
        npc = {
            talk   = "Talk to rental manager",
            name   = "Vehicle Rental Manager",
            model  = "s_m_m_trucker_01",
            coords = vec4(130.3860, -3220.2898, 5.8576, 358.0981),
            heading= 0.0,
            icon   = 'fa-solid fa-user-tie',
            debug  = false
        },

        rentalNpc = {
            model  = "s_m_m_autoshop_02",
            coords = vec4(130.0339, -3178.6028, 5.8960, 176.9028),
            heading= 180.0,
            icon   = 'fa-solid fa-undo',
            debug  = false
        },

        main = {
            label              = 'Truck Shed',
            coords             = vec3(153.0, -3211.68, 5.91),
            size               = vec3(3.0, 3.0, 5.0),
            markerType         = 2,
            markerRadius       = 10.0,
            interactionsRadius = 5.0,
            rotation           = 274.5,
            icon               = 'fa-solid fa-truck',
            debug              = false
        },

        vehicle = {
            label              = 'Truck Storage',
            coords             = vec4(162.0192, -3210.5688, 5.9588, 287.1212),
            size               = vec3(3.0, 3.0, 5.0),
            markerType         = 2,
            markerRadius       = 10.0,
            interactionsRadius = 5.0,
            rotation           = 267.5,
            icon               = 'fa-solid fa-warehouse',
            debug              = false
        }
    },

    deliveries = {
        stores = {
            [1]  = { label='LTD Gasoline (Grove St)', coords=vec3(-41.07, -1747.91, 28.40), size=vec3(40,40,5), icon='fa-solid fa-store', debug=false, npcModel='s_m_m_shopkeep_01' },
            [2]  = { label='24/7 Supermarket (Strawberry)', coords=vec3(31.6354, -1315.9624, 28.5229), size=vec3(40,40,5), icon='fa-solid fa-store', debug=false, npcModel='s_m_m_shopkeep_01' },
            [3]  = { label='24/7 Supermarket (Clinton Ave)', coords=vec3(383.2124, 327.7420, 102.5664), size=vec3(40,40,5), icon='fa-solid fa-store', debug=false, npcModel='s_m_m_shopkeep_01' },
            [4]  = { label='24/7 Supermarket (Innocence Blvd)', coords=vec3(2557.458, 382.282, 107.622), size=vec3(40,40,5), icon='fa-solid fa-store', debug=false, npcModel='s_m_m_shopkeep_01' },
            [5]  = { label='24/7 Supermarket (Barbareno Rd)', coords=vec3(-3241.927, 1001.462, 11.830), size=vec3(40,40,5), icon='fa-solid fa-store', debug=false, npcModel='s_m_m_shopkeep_01' },
            [6]  = { label='24/7 Supermarket (Route 68)', coords=vec3(549.131, 2671.294, 41.156), size=vec3(40,40,5), icon='fa-solid fa-store', debug=false, npcModel='s_m_m_shopkeep_01' },
            [7]  = { label='24/7 Supermarket (Grapeseed)', coords=vec3(1702.6796, 4918.2876, 41.0636), size=vec3(40,40,5), icon='fa-solid fa-store', debug=false, npcModel='s_m_m_shopkeep_01' },
            [8]  = { label='24/7 Supermarket (Paleto Bay)', coords=vec3(1738.5829, 6414.3950, 34.0372), size=vec3(40,40,5), icon='fa-solid fa-store', debug=false, npcModel='s_m_m_shopkeep_01' },
            [9]  = { label='Rob\'s Liquor (El Rancho)', coords=vec3(1135.808, -982.281, 45.415), size=vec3(40,40,5), icon='fa-solid fa-store', debug=false, npcModel='s_m_m_shopkeep_01' },
            [10] = { label='Rob\'s Liquor (San Andreas Ave)', coords=vec3(-1227.2878, -906.3984, 11.3264), size=vec3(40,40,5), icon='fa-solid fa-store', debug=false, npcModel='s_m_m_shopkeep_01' },
            [11] = { label='Rob\'s Liquor (Prosperity St)', coords=vec3(-1487.553, -379.107, 39.163), size=vec3(40,40,5), icon='fa-solid fa-store', debug=false, npcModel='s_m_m_shopkeep_01' },
            [12] = { label='Rob\'s Liquor (Great Ocean Hwy)', coords=vec3(-2968.243, 390.910, 14.043), size=vec3(40,40,5), icon='fa-solid fa-store', debug=false, npcModel='s_m_m_shopkeep_01' },
            [13] = { label='Rob\'s Liquor (Route 68)', coords=vec3(539.7084, 2666.0496, 41.1565), size=vec3(40,40,5), icon='fa-solid fa-store', debug=false, npcModel='s_m_m_shopkeep_01' }
        },

        houses = {
            [1]  = { label='House 1', coords=vec3(-831.2563, -865.6202, 19.7080), size=vec3(25,25,5), icon='fa-solid fa-house', debug=false, npcModel='a_m_m_fatlatin_01' },
            [2]  = { label='House 2', coords=vec3(-1477.1259, -674.4476, 28.0416), size=vec3(25,25,5), icon='fa-solid fa-house', debug=false, npcModel='a_f_m_fatwhite_01' },
            [3]  = { label='House 3', coords=vec3(-933.0837, -383.2635, 37.9613), size=vec3(25,25,5), icon='fa-solid fa-house', debug=false, npcModel='a_m_m_skater_01' },
            [4]  = { label='House 4', coords=vec3(-902.0938, 191.7701, 68.6052), size=vec3(25,25,5), icon='fa-solid fa-house', debug=false, npcModel='a_f_y_hipster_02' },
            [5]  = { label='House 5', coords=vec3(331.6364, 465.3325, 150.2530), size=vec3(25,25,5), icon='fa-solid fa-house', debug=false, npcModel='a_m_m_eastsa_02' },
            [6]  = { label='House 6', coords=vec3(-230.4044, 487.8981, 127.7681), size=vec3(25,25,5), icon='fa-solid fa-house', debug=false, npcModel='a_f_m_eastsa_01' },
            [7]  = { label='House 7', coords=vec3(-112.9455, 985.9448, 234.7543), size=vec3(25,25,5), icon='fa-solid fa-house', debug=false, npcModel='a_m_y_latino_01' },
            [8]  = { label='House 8', coords=vec3(-765.6406, 650.3317, 144.6974), size=vec3(25,25,5), icon='fa-solid fa-house', debug=false, npcModel='a_f_y_business_02' },
            [9]  = { label='House 9', coords=vec3(-714.6807, 697.2386, 157.2076), size=vec3(25,25,5), icon='fa-solid fa-house', debug=false, npcModel='a_m_m_business_01' },
            [10] = { label='House 10', coords=vec3(427.2119, -1842.1766, 27.4635), size=vec3(25,25,5), icon='fa-solid fa-house', debug=false, npcModel='a_f_y_fitness_01' },
            [11] = { label='House 11', coords=vec3(427.1853, -1842.1492, 27.4635), size=vec3(25,25,5), icon='fa-solid fa-house', debug=false, npcModel='a_m_y_fitness_01' },
            [12] = { label='House 12', coords=vec3(500.5060, -1813.1780, 27.8912), size=vec3(25,25,5), icon='fa-solid fa-house', debug=false, npcModel='a_f_m_bevhills_01' },
            [13] = { label='House 13', coords=vec3(512.5681, -1790.7244, 28.9195), size=vec3(25,25,5), icon='fa-solid fa-house', debug=false, npcModel='a_m_m_bevhills_02' },
            [14] = { label='House 14', coords=vec3(1241.4265, -566.4406, 68.6574), size=vec3(25,25,5), icon='fa-solid fa-house', debug=false, npcModel='a_f_y_yoga_01' },
            [15] = { label='House 15', coords=vec3(1250.9578, -620.9065, 68.5721), size=vec3(25,25,5), icon='fa-solid fa-house', debug=false, npcModel='a_m_y_yoga_01' },
            [16] = { label='House 16', coords=vec3(1265.5613, -648.6990, 67.1214), size=vec3(25,25,5), icon='fa-solid fa-house', debug=false, npcModel='a_f_y_runner_01' },
            [17] = { label='House 17', coords=vec3(1271.1799, -683.5729, 65.0316), size=vec3(25,25,5), icon='fa-solid fa-house', debug=false, npcModel='a_m_y_runner_01' },
            [18] = { label='House 18', coords=vec3(1264.7527, -702.8154, 63.9090), size=vec3(25,25,5), icon='fa-solid fa-house', debug=false, npcModel='a_f_y_tennis_01' },
            [19] = { label='House 19', coords=vec3(1229.6952, -725.3804, 60.9567), size=vec3(25,25,5), icon='fa-solid fa-house', debug=false, npcModel='a_m_y_tennis_01' },
            [20] = { label='House 20', coords=vec3(-831.2563, -865.6202, 19.7080), size=vec3(25,25,5), icon='fa-solid fa-house', debug=false, npcModel='a_f_m_fatcult_01' }
        }
    },

    vehicles = {
        [GetHashKey('rumpo')] = 'Dumbo Delivery Van',
        [GetHashKey('pony')] = 'Pony Van',
        [GetHashKey('mule')] = 'Mule Truck'
    },

    job = {
        name  = 'trucker',
        label = 'Trucker'
    },

    payment = {
        base        = 250,   -- base pay per drop
        bonusPerBox = 30,   -- bonus per extra box
        maxBoxes    = 10,    -- max boxes delivered per stop
        deposit     = 100,  -- deposit for vehicle rental
        multipliers = {
            store = 2.0,     -- normal rate
            house = .9       -- houses pay 10% less
        }
    },

    truckDoors = {
        [GetHashKey('mule')]      = {2,3,5},
        [GetHashKey('mule2')]     = {2,3,5},
        [GetHashKey('mule3')]     = {2,3,5},
        [GetHashKey('benson')]    = {2,3,5},
        [GetHashKey('pounder')]   = {2,3,5},
        [GetHashKey('pounder2')]  = {2,3,5},
        [GetHashKey('boxville')]  = {2,3,5},
        [GetHashKey('boxville2')] = {2,3,5},
        [GetHashKey('boxville3')] = {2,3,5},
        [GetHashKey('boxville4')] = {2,3,5},
        [GetHashKey('rumpo')]     = {2,3,5},
        [GetHashKey('pony')]      = {2,3,5}
    },

    boxGrab = {
        maxDistance  = 3.0,
        grabTime     = 20000,   -- ms
        deliveryTime = 30000,   -- ms
        timeout      = 300000  -- ms (5 minutes)
    },

    useTarget = true,
    debug     = true,

    animations = {
        grabBox    = { dict = 'anim@gangops@facility@servers@', clip = 'hotwire' },
        deliverBox = { dict = 'anim@gangops@facility@servers@', clip = 'hotwire' },
        boxEmote   = 'box'
    }
}