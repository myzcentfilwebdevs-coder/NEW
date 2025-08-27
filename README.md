# Enhanced Bus Job System

Modernong bus job system para sa FiveM QBCore servers na may mga enhanced features at modern NUI interface.

## 🚌 Features

### Fixed Issues
- ✅ **NPCs na tumatawid sa drop-off locations** - Fixed ang issue kung saan hindi bumababa ang mga passengers
- ✅ **Enhanced blip sizes** - Mas malaki at mas visible ang lahat ng blips sa mapa
- ✅ **Modern NUI Interface** - Gumamit ng custom modern UI instead ng ox_lib

### Key Features
- 🎯 Random route generation (3-5 stations per job)
- 👥 Realistic passenger boarding and drop-off animations
- 💰 Dynamic fare calculation based on distance and destination
- 🗺️ Enhanced blip system with larger, more visible markers
- 📱 Modern glass-morphism NUI interface
- 🎨 Beautiful animations and effects
- 📊 Comprehensive passenger tracking system
- 🚏 Multiple categories ng drop-off locations

## 📋 Requirements

- QBCore Framework
- ox_target (for NPC interactions)
- FiveM Server

## 🛠️ Installation

1. **Download** ang resource files
2. **Place** sa inyong `resources` folder
3. **Add** sa inyong `server.cfg`:
   ```
   ensure busjob
   ```
4. **Restart** ang server

## 🎮 How to Use

### Para sa Players
1. **Punta** sa Bus Job NPC (usually sa bus depot)
2. **Interact** gamit ang target system
3. **Select** "Start Bus Job" sa modern menu
4. **Rent** a bus when prompted
5. **Drive** sa mga blinking blue markers para mag-pickup ng passengers
6. **Press E** when near stations para automatic boarding
7. **Drive** sa red dropoff markers para mag-deliver ng passengers
8. **Return** sa depot kapag tapos na lahat

### Para sa Admins
- Configure ang `config.lua` file para sa custom locations
- Adjust payment rates, blip settings, at iba pang options
- Monitor player activities sa server console

## ⚙️ Configuration

### Basic Settings (config.lua)
```lua
Config.BusJob = {
    -- Payment Configuration
    Payment = {
        base = 25,              -- Base fare per passenger
        distanceBonus = 3,      -- Bonus per 100m distance
        completionBonus = 100   -- Bonus for completing full route
    },
    
    -- Enhanced Blip Sizes
    Blips = {
        WaitingStation = {
            sprite = 513,
            color = 3,
            scale = 1.0  -- Increased from 0.8
        },
        DropoffLocation = {
            sprite = 162,
            color = 1,
            scale = 0.9  -- Increased from 0.6
        }
    }
}
```

## 🔧 Key Fixes Implemented

### 1. NPC Drop-off Issue
- **Problem**: NPCs were being deleted immediately after boarding
- **Solution**: NPCs are now made invisible but kept in the bus, then made visible again during drop-off
- **Result**: Passengers now properly disembark at destinations with walking animations

### 2. Enhanced Blip Visibility
- **Updated**: All blip scales increased for better visibility
- **Station blips**: 0.8 → 1.0
- **Dropoff blips**: 0.6 → 0.9
- **NPC blip**: Added larger, orange-colored blip

### 3. Modern NUI Interface
- **Replaced**: ox_lib context menus with custom modern interface
- **Features**: Glass-morphism design, smooth animations, keyboard navigation
- **Responsive**: Works on different screen sizes
- **Accessible**: Full keyboard and mouse support

## 🎨 NUI Interface Features

- **Modern Design**: Glass-morphism effects with smooth gradients
- **Animations**: Smooth slide-in animations and hover effects
- **Icons**: Font Awesome icons for better visual appeal
- **Responsive**: Adapts to different screen sizes
- **Keyboard Support**: Full navigation with arrow keys and Enter/Escape
- **Professional Look**: Business-themed color scheme

## 📱 Commands & Controls

- **E Key**: Board passengers at stations
- **H Key**: Navigate to nearest passenger destination
- **ESC**: Close NUI menu
- **Arrow Keys**: Navigate menu items
- **Enter**: Select menu option

## 🐛 Troubleshooting

### Common Issues

1. **NPCs not spawning**
   - Check if Config.BusJob.WaitingStations is properly configured
   - Verify NPC models are valid

2. **Blips not showing**
   - Ensure blip sprites and colors are valid numbers
   - Check if stations are properly defined in config

3. **NUI not opening**
   - Verify html files are in correct location
   - Check browser console for JavaScript errors

### Debug Information
- Check server console for `[BusJob]` logs
- Enable F8 console sa client para sa detailed error messages

## 🔄 Version History

### v2.0.0 (Current)
- ✅ Fixed NPC drop-off animations
- ✅ Enhanced blip visibility 
- ✅ Modern NUI interface implementation
- ✅ Improved passenger tracking system
- ✅ Better error handling

### v1.0.0 (Original)
- Basic bus job functionality
- ox_lib integration
- Simple blip system

## 💡 Future Enhancements

- [ ] Multi-language support
- [ ] Custom vehicle support
- [ ] Advanced statistics tracking
- [ ] Player ranking system
- [ ] Route editor for admins

## 📞 Support

Para sa issues o suggestions, mag-create ng ticket sa support system o contact ang development team.

---
**Note**: This enhanced bus job system ay fully compatible sa QBCore framework at tested sa latest versions.