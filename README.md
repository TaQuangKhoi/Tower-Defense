# Checkpoint Rush

A Roblox obby game with server-authoritative checkpoint system, economy, and shop - built with anti-exploit best practices.

## 🎮 Features

- **Sequential Checkpoint System**: Players must complete checkpoints in order, preventing stage skipping
- **Economy System**: Collect coins scattered throughout the map
- **Shop System**: Purchase items with collected coins
  - Speed Boost (Passive) - Increases walk speed
  - Double Jump (Ability) - Jump twice in mid-air
  - Checkpoint Warp (Consumable) - Teleport to current checkpoint
  - Coin Magnet (Passive) - Auto-collect nearby coins
- **Data Persistence**: Progress, coins, and owned items are saved using DataStore
- **Anti-Exploit**: All game state is server-authoritative with client validation

## 🏗️ Architecture

### Module Structure

```
src/
├── client/
│   ├── init.client.luau          # Client initialization
│   └── Controllers/
│       ├── UIController.luau     # UI management and server event listeners
│       └── InputController.luau  # Input handling (double jump, etc.)
├── server/
│   ├── init.server.luau          # Server initialization & game logic
│   └── Services/
│       ├── ProgressService.luau  # Stage/checkpoint tracking
│       ├── EconomyService.luau   # Coin management
│       ├── InventoryService.luau # Item ownership tracking
│       ├── PurchaseService.luau  # Shop purchase validation
│       └── DataService.luau      # DataStore persistence
└── shared/
    ├── Types.luau                # Type definitions
    ├── RemotesDoc.luau           # Remote events documentation
    └── Config/
        ├── Items.luau            # Shop item definitions
        └── Stages.luau           # Stage configuration
```

### Client-Server Boundary

**Server → Client RemoteEvents:**
- `ProgressUpdated` - Stage changed
- `CoinsUpdated` - Coin balance updated
- `CheckpointReached` - Visual/audio feedback
- `ItemPurchased` - Purchase result
- `DataLoaded` - Initial data on join

**Client → Server RemoteEvents:**
- `PurchaseRequest` - Request to buy an item
- `UseItem` - Use a consumable item

## 🚀 Setup Instructions

### 1. In Roblox Studio

1. Open `Checkpoint-Rush.rbxl` in Roblox Studio

2. **Create the Remotes folder:**
   - In `ReplicatedStorage`, create a Folder named "Remotes"
   - Inside "Remotes", create the following RemoteEvents:
     - `ProgressUpdated`
     - `CoinsUpdated`
     - `CheckpointReached`
     - `ItemPurchased`
     - `DataLoaded`
     - `PurchaseRequest`
     - `UseItem`

3. **Set up Checkpoints:**
   - Create BasePart objects for each checkpoint
   - Add the tag "Checkpoint" to each checkpoint part (use the Tag Editor)
   - Add a number attribute "StageIndex" to each checkpoint (1, 2, 3, etc.)
   - Place checkpoints in sequential order throughout your obby

4. **Set up Coins:**
   - Create BasePart objects for coins (e.g., small spheres or cylinders)
   - Add the tag "Coin" to each coin part
   - (Optional) Add a number attribute "CoinValue" to customize coin worth (default: 10)
   - Make coins non-collidable and visually appealing

5. **Enable API Services:**
   - Go to Home → Game Settings → Security
   - Enable "Enable Studio Access to API Services"
   - This allows DataStore to work in Studio

### 2. Build with Rojo (Optional)

If using Rojo for syncing:

```bash
rojo serve
```

Then connect from Roblox Studio using the Rojo plugin.

### 3. Configuration

Edit [src/shared/Config/Stages.luau](src/shared/Config/Stages.luau) to customize:
- `TotalStages` - Number of stages in your obby
- `DefaultSpawn` - Starting spawn position
- `CoinRespawnTime` - How long before coins respawn

Edit [src/shared/Config/Items.luau](src/shared/Config/Items.luau) to:
- Add/remove shop items
- Adjust prices
- Modify item effects

## 🎯 How It Works

### Checkpoint System

1. Player touches a checkpoint part tagged with "Checkpoint"
2. Server validates the checkpoint is the **next sequential stage** (anti-skip)
3. Server updates player's stage and spawn point
4. Client receives update and shows visual feedback
5. On respawn, player teleports to their saved checkpoint

### Coin Collection

1. Player touches a coin part tagged with "Coin"
2. Server validates collection (cooldown prevents spam)
3. Server adds coins to player's balance
4. Coin becomes invisible and respawns after configured delay
5. Client receives coin update and updates UI

### Shop Purchase Flow

1. Client opens shop UI and clicks "Buy"
2. Client sends `PurchaseRequest` to server with item ID
3. Server validates:
   - Item exists
   - Player doesn't already own it (for non-consumables)
   - Player has enough coins
4. Server deducts coins and adds item to inventory
5. Server sends result back to client
6. Client updates UI and shows notification

### Data Persistence

- **On Join**: Server loads player data from DataStore
- **Auto-Save**: Server saves all players every 2 minutes
- **On Leave**: Server saves player data immediately
- **Saved Data**:
  - Current stage/checkpoint
  - Coin balance
  - Owned items

## 🛡️ Anti-Exploit Measures

1. **Server-Authoritative State**: All game state (coins, stage, items) is stored and validated on the server
2. **Sequential Progression**: Players cannot skip checkpoints - must complete in order
3. **Purchase Validation**: All purchases are validated server-side
4. **Coin Collection Cooldown**: Prevents rapid-fire coin collection exploits
5. **No Client Trust**: Client never directly modifies game state

## 🎨 Customization

### Adding New Items

1. Edit [src/shared/Config/Items.luau](src/shared/Config/Items.luau)
2. Add your item with this structure:
```lua
NewItem = {
    Id = "NewItem",
    Name = "Display Name",
    Description = "What it does",
    Price = 100,
    Type = "Passive" | "Ability" | "Consumable",
    Effects = {
        -- Your custom effects
    }
}
```

3. Implement the effect in [src/server/init.server.luau](src/server/init.server.luau):
   - For passives: Add to `ApplyPassiveItems()`
   - For abilities: Add setup in character spawn
   - For consumables: Add to `UseItem` handler

### Adjusting Difficulty

- **Coin Prices**: Edit values in Items.luau
- **Coin Values**: Set "CoinValue" attribute on coin parts
- **Coin Respawn**: Change `CoinRespawnTime` in Stages.luau
- **Auto-Save Interval**: Change `AUTO_SAVE_INTERVAL` in DataService.luau

## 📝 Best Practices Applied

✅ Modular architecture with separated concerns  
✅ Type-safe code with `--!strict` mode  
✅ Server-authoritative design  
✅ Proper use of RemoteEvents for client-server communication  
✅ DataStore with error handling and auto-save  
✅ CollectionService tags for dynamic object management  
✅ Anti-exploit validation on all player actions  

## 🐛 Troubleshooting

**Problem**: "Remotes not found" error  
**Solution**: Make sure you created all RemoteEvent instances in ReplicatedStorage.Remotes

**Problem**: Checkpoints not working  
**Solution**: Verify checkpoints have the "Checkpoint" tag and "StageIndex" attribute

**Problem**: Data not saving  
**Solution**: Enable "Studio Access to API Services" in Game Settings → Security

**Problem**: Coins not spawning  
**Solution**: Make sure coin parts have the "Coin" tag

## 📚 References

This implementation follows Roblox best practices from:
- [Roblox RemoteEvent Documentation](https://create.roblox.com/docs/scripting/events/remote)
- [DataStore Best Practices](https://devforum.roblox.com/t/datastore-best-practices/2845439)
- [Checkpoint System Tutorial](https://devforum.roblox.com/t/how-to-create-an-obby-part-1-checkpoints-system-and-lava-bricks/874825)

## 📜 License

MIT License - Feel free to use and modify for your own projects!
Generated by [Rojo](https://github.com/rojo-rbx/rojo) 7.6.0.

## Getting Started
To build the place from scratch, use:

```bash
rojo build -o "Checkpoint-Rush.rbxlx"
```

Next, open `Checkpoint-Rush.rbxlx` in Roblox Studio and start the Rojo server:

```bash
rojo serve
```

For more help, check out [the Rojo documentation](https://rojo.space/docs).