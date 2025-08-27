-- Test Script for QBX Trucker Job
-- This file can be used to test if the resource loads correctly

Citizen.CreateThread(function()
    print("🚛 Testing QBX Trucker Job Startup...")
    
    -- Test 1: Check if dependencies are available
    Citizen.Wait(1000)
    
    local qbxState = GetResourceState('qbx_core')
    local oxlibState = GetResourceState('ox_lib')
    local oxtargetState = GetResourceState('ox_target')
    
    print("📋 Dependency Check:")
    print("  - QBX Core:", qbxState)
    print("  - OX Lib:", oxlibState)
    print("  - OX Target:", oxtargetState)
    
    -- Test 2: Check if config files load
    local success, config = pcall(function()
        return require 'config.shared'
    end)
    
    if success and config then
        print("✅ Config files loaded successfully")
        print("  - Vehicles available:", config.vehicles and #table.getkeys(config.vehicles) or 0)
        print("  - Store locations:", config.deliveries and config.deliveries.stores and #config.deliveries.stores or 0)
        print("  - House locations:", config.deliveries and config.deliveries.houses and #config.deliveries.houses or 0)
    else
        print("❌ Config files failed to load:", config)
    end
    
    -- Test 3: Wait for QBX if needed
    if qbxState ~= 'started' then
        print("⏳ Waiting for QBX Core to start...")
        while GetResourceState('qbx_core') ~= 'started' do
            Citizen.Wait(1000)
        end
        print("✅ QBX Core is now available")
    end
    
    -- Test 4: Test QBX access
    Citizen.Wait(2000)
    if QBX then
        print("✅ QBX global is available")
        if QBX.PlayerData then
            print("✅ QBX.PlayerData is accessible")
        else
            print("⚠️ QBX.PlayerData not available (player might not be loaded)")
        end
    else
        print("❌ QBX global not available")
    end
    
    print("🎉 Startup test completed!")
end)

-- Helper function
function table.getkeys(t)
    local keys = {}
    for k, v in pairs(t) do
        table.insert(keys, k)
    end
    return keys
end