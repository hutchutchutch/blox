# 🎮 Heat Seeker - Roblox Game

A hot/cold exploration game where players search for treasures and eggs while avoiding dangers in a beautiful grassland environment!

## 🚀 Quick Start - 3 Ways to Play

### Option 1: Use the Pre-built File (Easiest)
```bash
1. Open Roblox Studio
2. File → Open from File
3. Navigate to this folder and select: grassland.rbxl
4. Press F5 to play!
```

### Option 2: Rojo Setup (For Developers)
```bash
# In terminal/command prompt
cd plugin
rojo serve

# In Roblox Studio
1. Install Rojo plugin from marketplace
2. Create new Baseplate
3. Connect Rojo
4. Press F5 to play!
```

### Option 3: Manual Setup
1. Open `HOW_TO_PLAY.md` for detailed instructions
2. Copy scripts from `plugin/src/` folder
3. Follow the step-by-step guide

## 🎯 Game Features

### Core Gameplay
- **Temperature-based exploration** - Screen effects show proximity to items
- **Dynamic music system** - Haunting music plays near danger, happy music when safe
- **Beautiful grassland environment** - 500x500 stud terrain with trees, rocks, and flowers

### Heat Types
- 🟡 **Gold (Treasure)** - Collect for money
- 🔴 **Red (Danger)** - Stay away!
- 🩷 **Pink (Eggs)** - Collect for rebirth tokens

### Progression System
- **Money** - Buy upgrades and items
- **Rebirth Tokens** - Earned from eggs, used to rebirth
- **Rebirth Levels** - Permanent speed and money bonuses

### Egg Rarities
1. **Common** (White) - 1 token
2. **Uncommon** (Green) - 2 tokens
3. **Rare** (Blue) - 5 tokens
4. **Epic** (Purple) - 10 tokens
5. **Legendary** (Rainbow) - 25 tokens

## 🎮 Controls

### PC
- **WASD/Arrows** - Move
- **Shift** - Sprint
- **E** - Collect items

### Mobile
- **Joystick** - Move
- **Sprint Button** - Hold to run
- **Auto-collect** - Walk near items

## 📁 Project Structure

```
blox/
├── grassland.rbxl          # Pre-built game file
├── HOW_TO_PLAY.md         # Detailed setup guide
├── docs/
│   ├── gameplay.md        # Game design document
│   └── plan.md           # Implementation plan
└── plugin/
    └── src/
        ├── Main.server.luau           # Game manager
        ├── GrasslandSetup.server.luau # World generation
        ├── ClientMain.client.luau     # UI and effects
        ├── MovementController.client.luau # Player movement
        ├── MusicSystem.client.luau    # Dynamic music
        ├── RewardSystem.luau          # Treasures and eggs
        ├── RebirthSystem.luau         # Rebirth mechanics
        └── Types.luau                 # Type definitions
```

## 🔧 Game Systems

### Temperature Detection
- Calculates distance to nearest heat source
- Updates visual effects based on proximity
- Different effects for each heat type

### Reward System
- Treasure chests with opening animations
- Egg collection with crack effects
- Money rain visual effects
- Rarity-based rewards

### Rebirth System
- Token requirements: 10, 25, 50, 100, then ×1.5
- Permanent bonuses per level
- Visual effects on rebirth
- Special perks at higher levels

### Music System
- Smooth transitions between tracks
- Volume increases with danger proximity
- Playback speed changes for tension

## 📊 Technical Details

- **Filtering Enabled** - Secure client-server architecture
- **Data Persistence** - Player progress saves automatically
- **Optimized Performance** - Streaming enabled for large worlds
- **Type Safety** - Full Luau type annotations

## 🐛 Troubleshooting

### Common Issues

**"Scripts not running"**
- Ensure all scripts are in correct services
- Check script types (Script vs LocalScript)
- Look for errors in Output window

**"No heat sources spawning"**
- Wait 2-3 seconds after game start
- Check that server scripts are running
- Verify GrasslandSetup completed

**"Can't collect items"**
- Get within 10 units of items
- Press E key (PC) or tap (mobile)
- Check ClientMain is running

## 🎯 Tips for Players

1. **Listen to the music** - It warns you of danger!
2. **Watch the temperature meter** - Shows distance to items
3. **Collect eggs** - Essential for progression
4. **Sprint wisely** - Stamina is limited
5. **Explore thoroughly** - Rare items spawn randomly

## 🛠️ For Developers

### Adding New Features
- All types defined in `Types.luau`
- Server logic in `Main.server.luau`
- Client effects in `ClientMain.client.luau`
- Use RemoteEvents for client-server communication

### Modifying the World
- Edit `GrasslandSetup.server.luau`
- Adjust terrain size, decoration counts
- Change lighting and atmosphere settings

### Creating New Heat Types
1. Add to `HeatType` in Types.luau
2. Create visual model in RewardSystem
3. Add collection handler in Main
4. Create client effects in ClientMain

## 📝 Credits

Built as a Roblox implementation of the Heat Seeker game concept, featuring:
- Dynamic temperature-based gameplay
- Beautiful grassland environment
- Engaging progression system
- Atmospheric music system

Enjoy exploring the grasslands! 🌿🎮