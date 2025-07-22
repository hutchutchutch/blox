# 🎮 How to Play Heat Seeker in Roblox Studio

## Quick Start (Easiest Method)

### Option 1: Open Existing File
1. Open Roblox Studio
2. Click "Open from File"
3. Navigate to this folder and open `grassland.rbxl`
4. Press **F5** or click the "Play" button to start playing!

### Option 2: Manual Setup (If grassland.rbxl doesn't work)

## 📦 Method 1: Using Rojo (Recommended for Development)

### Prerequisites:
1. Install [Rojo](https://rojo.space/docs/v7/getting-started/installation/) 
2. Install Rojo Studio Plugin from Roblox Studio's Plugin Marketplace

### Steps:
1. Open terminal/command prompt in the `plugin` folder
2. Run: `rojo serve`
3. Open Roblox Studio and create a new Baseplate
4. Click the Rojo plugin icon and click "Connect"
5. Press F5 to play!

## 🔧 Method 2: Manual Installation (No External Tools)

### Steps:
1. **Open Roblox Studio**
   - Create a new place (Baseplate template)

2. **Create the Game Structure:**
   ```
   In Explorer window, create this structure:
   
   ServerScriptService/
   ├── Main (Script)
   ├── GrasslandSetup (Script)
   ├── Types (ModuleScript)
   ├── RewardSystem (ModuleScript)
   └── RebirthSystem (ModuleScript)
   
   StarterPlayer/
   └── StarterPlayerScripts/
       ├── ClientMain (LocalScript)
       ├── MovementController (LocalScript)
       └── MusicSystem (LocalScript)
   
   ReplicatedStorage/
   └── Types (ModuleScript) [copy of the one in ServerScriptService]
   ```

3. **Copy Code Files:**
   - Open each `.luau` file from `plugin/src/` in a text editor
   - Copy the contents
   - Paste into the corresponding script in Roblox Studio
   - **IMPORTANT**: Remove the `.server` and `.client` from script names

4. **Configure Settings:**
   - In Workspace properties, set:
     - FilteringEnabled: true
     - StreamingEnabled: true
   
5. **Play the Game:**
   - Press F5 or click Play button
   - The grassland will generate automatically!

## 🎮 Game Controls

### PC Controls:
- **WASD/Arrow Keys**: Move around
- **Shift**: Sprint (uses stamina)
- **E**: Collect treasures/eggs when close
- **Click Rebirth Button**: Rebirth when you have enough tokens

### Mobile Controls:
- **Joystick**: Move around
- **Sprint Button**: Hold to sprint
- **Auto-collect**: Walk near items to collect

## 🎯 How to Play

1. **Explore the grassland** - Move around to find heat sources
2. **Watch the temperature meter** - It shows how close you are to something
3. **Identify heat types**:
   - 🟡 **Gold effects** = Treasure (good!)
   - 🔴 **Red effects** = Danger (stay away!)
   - 🩷 **Pink effects** = Eggs (collect for rebirth tokens!)
4. **Collect rewards** - Press E near treasures and eggs
5. **Rebirth** - When you have enough tokens, click the rebirth button for permanent upgrades

## 🔍 Temperature Guide

- **COLD** (Blue) - Nothing nearby
- **COOL** (Light Blue) - Something 75+ units away
- **WARM** (Yellow) - Getting closer (50-75 units)
- **HOT** (Orange) - Very close (25-50 units)
- **BURNING!** (Red) - Right next to it! (under 25 units)

## 💡 Tips

- Listen to the music - it changes when danger is near!
- Eggs give both money AND rebirth tokens
- Higher rebirth levels = faster movement and more money
- Legendary (rainbow) eggs are super rare but give huge rewards
- Sprint wisely - stamina takes time to regenerate

## 🐛 Troubleshooting

### "Scripts not running"
- Make sure all scripts are in the correct services
- Check that script types are correct (Script vs LocalScript vs ModuleScript)
- Look in Output window (View → Output) for errors

### "No heat sources spawning"
- Wait 2-3 seconds after starting
- Check that GrasslandSetup script is in ServerScriptService
- Ensure Main script is also in ServerScriptService

### "Can't collect items"
- Get within 10 units of the item
- Press E (not automatic except on mobile)
- Make sure ClientMain is in StarterPlayerScripts

## 📝 Quick Test Commands

In Studio's command bar (View → Command Bar), you can run:

```lua
-- Give yourself money
game.Players.LocalPlayer.leaderstats.Money.Value = 10000

-- Give yourself rebirth tokens (run after getting in-game)
game.ReplicatedStorage.HeatSeekerRemotes.UpdatePlayerData:FireClient(game.Players.LocalPlayer, {
    money = 10000,
    rebirthTokens = 100,
    rebirthLevel = 0,
    eggsFound = 0,
    upgrades = {},
    totalMoneyCollected = 10000,
    lastDailyReward = 0
})

-- Teleport to coordinates
game.Players.LocalPlayer.Character:SetPrimaryPartCFrame(CFrame.new(0, 10, 0))
```

---

Have fun playing Heat Seeker! 🎮🔥❄️