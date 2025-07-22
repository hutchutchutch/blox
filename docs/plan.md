# 🔥❄️ "Heat Seeker" - Hotter Colder Exploration Game

## Core Concept
Players explore a mysterious map searching for hidden treasures and dangers using temperature-based clues. The twist: "hot" doesn't always mean good! Players must learn to distinguish between beneficial heat (treasure) and dangerous heat (predators).

## 🎮 Game Mechanics

### Temperature System
- **Detection Range**: 0-100 units from target
- **Update Rate**: Real-time temperature calculation every 0.1 seconds
- **Multiple Targets**: Up to 10 active hot spots on the map simultaneously

### Heat Types

#### 💰 Good Heat (Treasure)
- **Visual Indicators**:
  - Golden particles floating upward
  - Warm yellow/orange glow around screen edges
  - Shimmering heat waves effect
  - Sparkle particles increase with proximity
  - Screen brightens subtly

#### 🔪 Bad Heat (Danger)
- **Visual Indicators**:
  - Dark red pulsing vignette
  - Black smoke particles
  - Screen edges crack effect
  - Ominous shadow tendrils
  - Screen contrast increases (darker darks)

### Distance-Based Effects

**100-75 Units Away**:
- Subtle color tint (barely noticeable)
- Temperature meter shows "Cold" (blue)

**75-50 Units Away**:
- Light particle effects begin
- Temperature meter shows "Cool" (light blue)
- Faint audio cues start

**50-25 Units Away**:
- Medium intensity effects
- Temperature meter shows "Warm" (yellow/red)
- Clear audio feedback
- Screen effects become obvious

**25-10 Units Away**:
- Strong visual effects
- Temperature meter shows "Hot" (orange/dark red)
- Intense audio cues
- Heart beat effect for danger

**10-0 Units Away**:
- Maximum effect intensity
- Temperature meter shows "BURNING!" (flashing)
- Screen shake for danger zones
- Dramatic particle effects

## 🗺️ Map Design

### Environment Types

**Forest Biome**
- Dense trees provide cover
- Hidden clearings contain treasures
- Predators: Wolves, Bears
- Treasure: Ancient coins, gems

**Desert Biome**
- Open terrain with sand dunes
- Mirages create false heat signatures
- Predators: Scorpions, Sand Worms
- Treasure: Buried artifacts

**Cave System**
- Dark environments requiring torches
- Echo effects affect audio cues
- Predators: Bats, Cave Spiders
- Treasure: Crystal formations

**Ruins Biome**
- Broken structures to explore
- Trap mechanisms (bad heat)
- Predators: Guardian Statues
- Treasure: Royal treasures

## 💎 Rewards & Dangers

### Treasure Types (Good Heat)

**Common (70% spawn rate)**
- Silver Coins: 10-50 money
- Small Gems: 25-75 money
- Effect: Light money rain (5-10 bills)

**Rare (25% spawn rate)**
- Gold Bars: 100-250 money
- Large Crystals: 150-300 money
- Effect: Medium money rain (15-25 bills)

**Legendary (5% spawn rate)**
- Ancient Artifacts: 500-1000 money
- Magic Orbs: 750-1500 money
- Effect: Heavy money rain (50+ bills) with rainbow effects

### Predator Types (Bad Heat)

**Tier 1 Predators**
- Wolves: Chase at medium speed
- Spiders: Jump attack from above
- Damage: 25% health

**Tier 2 Predators**
- Bears: Charge attack with knockback
- Scorpions: Poison effect (DoT)
- Damage: 50% health

**Tier 3 Predators**
- Sand Worms: Emerge from below
- Guardian Statues: Area blast attack
- Damage: Instant death

## 🎨 Visual Effects System

### Screen Overlay Layers

**Layer 1: Color Grading**
- Good Heat: Warm filter (yellows, golds)
- Bad Heat: Cold filter (reds, purples)
- Intensity: 0-60% based on distance

**Layer 2: Particle Effects**
- Good: Golden sparkles, light rays
- Bad: Ash, smoke, shadow wisps
- Density: Increases with proximity

**Layer 3: Screen Distortion**
- Good: Gentle wave effect
- Bad: Static/glitch effect
- Strength: 0-30% based on distance

**Layer 4: Edge Effects**
- Good: Soft glow vignette
- Bad: Dark crack/corruption effect
- Opacity: 0-80% based on distance

## 🔊 Audio Design

### Good Heat Sounds
- Gentle chimes (far)
- Coin jingling (medium)
- Treasure chest opening (close)
- Angelic choir (legendary items)

### Bad Heat Sounds
- Low rumble (far)
- Growling (medium)
- Heartbeat + breathing (close)
- Monster roar (encounter)

## 🥚 Egg Hunt System

### Egg Types & Temperature Signatures

**Common Eggs** (White)
- Temperature: Cool blue aura
- Visual: Soft blue particles, gentle frost effect
- Spawn Rate: 40% of egg spawns
- Reward: 100-200 money + 1 rebirth token

**Uncommon Eggs** (Green)
- Temperature: Neutral green shimmer
- Visual: Nature particles (leaves, grass)
- Spawn Rate: 30% of egg spawns
- Reward: 300-500 money + 2 rebirth tokens

**Rare Eggs** (Blue)
- Temperature: Shifting blue-purple waves
- Visual: Water ripple overlay effect
- Spawn Rate: 20% of egg spawns
- Reward: 750-1000 money + 5 rebirth tokens

**Epic Eggs** (Purple)
- Temperature: Pulsing violet heat
- Visual: Magic sparkles, portal effect
- Spawn Rate: 8% of egg spawns
- Reward: 2000-3000 money + 10 rebirth tokens

**Legendary Eggs** (Rainbow)
- Temperature: Cycling rainbow spectrum
- Visual: Prismatic light beams, rainbow particles
- Spawn Rate: 2% of egg spawns
- Reward: 5000-10000 money + 25 rebirth tokens

### Egg Detection Mechanics
- Eggs have unique "neutral" temperature that differs from good/bad heat
- Screen overlay shows special egg-specific effects:
  - Eggshell crack patterns appear on screen edges
  - Easter-themed particles (butterflies, flowers)
  - Pastel color gradients
- Temperature meter shows "EGG!" in corresponding color

## 🔄 Rebirth System

### Rebirth Requirements
- **Rebirth 1**: 10 rebirth tokens
- **Rebirth 2**: 25 rebirth tokens
- **Rebirth 3**: 50 rebirth tokens
- **Rebirth 4**: 100 rebirth tokens
- **Rebirth 5+**: Previous requirement × 1.5

### Rebirth Bonuses (Permanent)
**Rebirth 1 Perks**:
- +10% movement speed
- +25% money from all sources
- Eggs visible from 10 units further

**Rebirth 2 Perks**:
- +20% movement speed
- +50% money from all sources
- Start with Heat Detector v2
- Unlock "Egg Finder" badge

**Rebirth 3 Perks**:
- +30% movement speed
- +100% money from all sources
- 2x rebirth tokens from eggs
- Unlock exclusive "Golden Aura" effect

**Rebirth 4 Perks**:
- +40% movement speed
- +200% money from all sources
- Legendary egg magnet (auto-collect within 20 units)
- Unlock "Phoenix" pet that follows you

**Rebirth 5+ Perks**:
- +5% all stats per additional rebirth
- Unlock special rainbow trail
- Access to "Prestige Island" with better spawns

## 🎯 Gameplay Loop

1. **Explore**: Move through the map freely
2. **Detect**: Notice temperature changes
3. **Identify**: Determine if heat is good/bad/egg
4. **Decide**: Approach or avoid
5. **Encounter**: Collect treasure/eggs or escape danger
6. **Progress**: Earn money and rebirth tokens
7. **Upgrade**: Buy improvements or rebirth for permanent buffs

## 🛍️ Progression System

### Purchasable Upgrades

**Heat Detector v2** (500 money)
- Shows heat type earlier (at 75 units)
- Adds directional indicator

**Sprint Boots** (750 money)
- 50% faster movement
- Essential for escaping predators

**Treasure Magnet** (1000 money)
- Auto-collect money within 10 units
- Increases money rain amount by 25%

**Danger Sense** (1500 money)
- Mini-map shows bad heat sources
- 30-second cooldown ability

**Lucky Charm** (2000 money)
- 25% chance to spawn rare treasures
- 10% chance to avoid predator attacks

## 📊 Balancing

### Spawn Rates
- Good heat sources: 70%
- Bad heat sources: 30%
- Multiple sources minimum distance: 50 units

### Difficulty Scaling
- Every 5 minutes: +10% predator speed
- Every 10 treasures: +1 bad heat source
- Every 1000 money: Unlock new biome

### Risk vs Reward
- Legendary treasures always spawn near Tier 3 predators
- Money rain duration: 3-10 seconds
- Predator chase duration: 5-15 seconds
- Safe zones every 200 units for strategy

## 🎮 Controls

**PC**
- WASD/Arrow Keys: Movement
- Shift: Sprint (if upgraded)
- E: Interact/Collect
- Tab: View upgrades

**Mobile**
- Joystick: Movement
- Double-tap: Sprint
- Auto-collect when near
- Menu button: Upgrades

## 🎮 Core Roblox Features

### Badge System
**Gameplay Badges**:
- "First Egg" - Find your first egg
- "Egg Collector" - Find 10 eggs
- "Egg Master" - Find 100 eggs
- "Rainbow Hunter" - Find a legendary egg
- "Survivor" - Escape 50 predators
- "Rich Player" - Collect 100,000 money
- "Speed Demon" - Rebirth 5 times

### Daily Rewards
**Day 1**: 100 money + 1 rebirth token
**Day 2**: 250 money + 2 rebirth tokens  
**Day 3**: 500 money + 1 speed boost (1 hour)
**Day 4**: 750 money + 3 rebirth tokens
**Day 5**: 1000 money + 2x money boost (30 min)
**Day 6**: 1500 money + 5 rebirth tokens
**Day 7**: 3000 money + Exclusive "Lucky Egg" pet

### Game Passes (Robux)
**VIP Pass** (399 Robux)
- 2x rebirth tokens permanently
- VIP chat tag
- Golden name color
- Start with 1000 money each life

**Super Speed** (299 Robux)
- +50% base movement speed
- Exclusive speed trail effect
- Stack with rebirth bonuses

**Egg Magnet** (499 Robux)
- Auto-collect eggs within 30 units
- See egg locations on minimap
- 2x chance for rare eggs

**Lucky Gamepass** (799 Robux)
- 3x money from all sources
- 25% chance to not lose health from predators
- Double daily reward streak bonuses

### Codes System
Example codes (enter in menu):
- "LAUNCH" - 500 money + 5 rebirth tokens
- "EASTER2025" - Egg finder boost (1 hour)
- "SPEEDY" - 2x speed (30 minutes)
- "RICH" - 1000 money
- "RAINBOW" - Guaranteed legendary egg spawn (one-time)

### Pets System
**Pet Rarities & Effects**:
- **Bunny** (Common): +10% egg detection range
- **Chick** (Uncommon): +25% money from eggs
- **Duck** (Rare): +15% movement speed
- **Phoenix** (Epic): Revive once per life
- **Dragon** (Legendary): Burn nearby predators

### Server Events
**Egg Rain** (Every 30 minutes)
- 50 eggs spawn across the map
- 2x rebirth tokens for 5 minutes
- Special golden eggs appear (10x rewards)

**Predator Swarm** (Every 45 minutes)
- 3x predator spawns for 3 minutes
- But 5x money if you survive
- Hide in safe zones or team up

**Rainbow Rush** (Every hour)
- All heat signatures become rainbow
- Can't tell good from bad!
- 10x rewards but 2x risk
- Lasts 2 minutes

### Leaderboards
**Global**:
- Total Money Collected
- Most Eggs Found
- Highest Rebirth Level
- Longest Survival Streak

**Server**:
- Current Money
- Eggs This Session
- Predators Escaped
- Active Streak

### Social Features
**Teams** (up to 4 players)
- Share heat detection within 50 units
- Split money and tokens equally
- Team revival system
- Exclusive team chat

**Trading**
- Trade rebirth tokens
- Trade pets (except exclusives)
- Trade limited egg skins
- Safe trade GUI with confirmation

### Premium Currency: Gems
**Earning Gems**:
- Daily login: 5 gems
- Find legendary egg: 10 gems
- Complete all daily badges: 20 gems
- Buy with Robux: 100 gems = 99 Robux

**Gem Shop**:
- Exclusive "Diamond Egg" pet: 500 gems
- Permanent 2x egg spawn: 1000 gems
- Custom egg trail effects: 250 gems
- Skip rebirth requirements: 750 gems