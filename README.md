# 🚛 Advanced Trucker Job with NUI

## 📋 Overview

An advanced delivery job system for QBX Framework featuring a modern NUI interface, enhanced NPC interactions, and comprehensive delivery management.

## ✨ Features

### 🎨 Modern NUI Interface
- **Beautiful Design**: Gradient backgrounds, smooth animations, and modern UI components
- **Tabbed Navigation**: Vehicles, Jobs, Statistics, and Settings tabs
- **Vehicle Selection**: Interactive vehicle cards with rental options
- **Job Management**: Real-time delivery tracking and progress bars
- **Statistics Dashboard**: Performance metrics and charts
- **Settings Panel**: Customizable preferences and options

### 🤖 Enhanced NPCs
- **Main Manager NPC**: Vehicle rental and job management
- **Return NPC**: Vehicle return processing
- **Delivery NPCs**: Dynamic spawn at delivery locations
- **Driver NPCs**: Automatic vehicle return to depot

### 📦 Delivery System
- **Multiple Location Types**: Stores and houses with different requirements
- **Dynamic Box Counts**: Stores (1-3 boxes), Houses (1 box)
- **Progressive Difficulty**: Randomized delivery counts and locations
- **Performance Tracking**: Delivery statistics and earnings

### 🔧 Advanced Features
- **Side Job**: Available to all players, not restricted by job
- **Vehicle Tracking**: Rental deposits and return system
- **Anti-Abuse**: Cooldown periods and validation
- **Progress Tracking**: Real-time delivery progress
- **Dynamic Pricing**: Performance-based payments

## 🛠️ Installation

### Prerequisites
- QBX Core Framework
- ox_lib
- ox_target
- FiveM Server

### Steps

1. **Download and Extract**
   ```bash
   git clone https://github.com/yourusername/qbx_truckerjob
   cd qbx_truckerjob
   ```

2. **Place in Resources**
   ```
   resources/
   └── [jobs]/
       └── qbx_truckerjob/
   ```

3. **Add to server.cfg**
   ```cfg
   ensure qbx_truckerjob
   ```

4. **Configure Dependencies**
   Make sure you have these resources running:
   - `qbx_core`
   - `ox_lib`
   - `ox_target`

## 🎮 Usage

### For Players

#### Starting a Job
1. Go to the trucker depot location
2. Interact with the **Delivery Coordinator** NPC
3. Select a vehicle from the modern NUI interface
4. Pay the rental deposit ($500 default)
5. Begin your delivery route

#### Using the NUI
- **Open NUI**: Use `/truckernui` command or interact with NPCs
- **Vehicle Tab**: Browse and rent available vehicles
- **Jobs Tab**: View active delivery information
- **Stats Tab**: Check your performance metrics
- **Settings Tab**: Customize preferences and return vehicles

#### Making Deliveries
1. Drive to your assigned delivery location
2. Open the vehicle's back doors
3. Grab boxes from the truck (interact with vehicle)
4. Deliver boxes to the customer NPC
5. Return to truck for more boxes if needed
6. Continue to next location when batch is complete

#### Completing Jobs
- Complete all assigned deliveries
- Return vehicle to depot for full payment
- Collect earnings based on performance

### For Administrators

#### Commands
```lua
/truckernui           -- Open NUI interface
/truckerdebug        -- Debug information
/truckercheckloc <id> -- Check specific location
/trucker:debug       -- Server debug (admin only)
```

#### Configuration
Edit files in `config/` directory:
- `client.lua` - Client-side settings
- `server.lua` - Server-side settings  
- `shared.lua` - Shared configuration

## ⚙️ Configuration

### Vehicle Configuration
```lua
vehicles = {
    [GetHashKey('rumpo')] = 'Dumbo Delivery Van',
    [GetHashKey('pony')] = 'Pony Van',
    [GetHashKey('mule')] = 'Mule Truck'
}
```

### Payment Settings
```lua
payment = {
    base = 250,           -- Base pay per delivery
    bonusPerBox = 30,     -- Bonus per extra box
    deposit = 100,        -- Vehicle rental deposit
    multipliers = {
        store = 2.0,      -- Store delivery rate
        house = 0.9       -- House delivery rate (10% less)
    }
}
```

### Location Setup
```lua
locations = {
    npc = {
        model = "s_m_m_trucker_01",
        coords = vec4(130.3860, -3220.2898, 5.8576, 358.0981)
    },
    vehicle = {
        coords = vec4(162.0192, -3210.5688, 5.9588, 287.1212)
    }
}
```

## 🐛 Troubleshooting

### Common Issues

#### NPCs Not Spawning
- Check console for error messages
- Verify NPC model names in config
- Ensure ox_target is running
- Use `/truckerdebug` to check NPC status

#### NUI Not Opening
- Check browser console (F12)
- Verify all HTML/CSS/JS files are present
- Ensure SetNuiFocus is working
- Try `/truckernui` command directly

#### Vehicle Issues
- Check if vehicle models exist in game
- Verify spawn location coordinates
- Ensure proper permissions for vehicle spawning
- Check server console for spawn errors

#### Delivery Problems
- Verify delivery location coordinates
- Check if delivery NPCs are spawning
- Ensure box grab interactions are working
- Use `/truckercheckloc <id>` to test locations

### Debug Tools

#### Client Debug
```lua
/truckerdebug -- Shows:
-- Job status
-- Vehicle information
-- Delivery progress
-- NPC status
-- Configuration validation
```

#### Server Debug
```lua
/trucker:debug -- Shows:
-- Player session data
-- Bail/deposit status
-- Active deliveries
-- Anti-abuse status
```

## 🎨 Customization

### NUI Styling
Edit `html/style.css` to customize:
- Colors and themes
- Animations and transitions
- Layout and spacing
- Button styles
- Modal designs

### Adding Vehicles
1. Add to `config/shared.lua`:
```lua
vehicles = {
    [GetHashKey('newvehicle')] = 'New Vehicle Name'
}
```

2. Add door configuration:
```lua
truckDoors = {
    [GetHashKey('newvehicle')] = {2, 3, 5}
}
```

### Adding Delivery Locations
Edit `config/shared.lua`:
```lua
deliveries = {
    stores = {
        [14] = {
            label = 'New Store',
            coords = vec3(x, y, z),
            npcModel = 's_m_m_shopkeep_01'
        }
    }
}
```

## 📊 Performance

### Optimizations
- Cached native functions for better performance
- Efficient NPC management with cleanup
- Minimal network events
- Optimized blip and target management

### Resource Usage
- Client: ~0.01ms idle, ~0.05ms active
- Server: ~0.00ms idle, ~0.02ms active
- Memory: ~15MB client, ~5MB server

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Discord**: [Your Discord Server]
- **Issues**: [GitHub Issues](https://github.com/yourusername/qbx_truckerjob/issues)
- **Documentation**: [Wiki](https://github.com/yourusername/qbx_truckerjob/wiki)

## 🙏 Credits

- **Framework**: QBX Core Team
- **Libraries**: ox_lib, ox_target
- **Design**: Modern UI inspired by contemporary web design
- **Icons**: Font Awesome 6

---

**Made with ❤️ for the FiveM community**