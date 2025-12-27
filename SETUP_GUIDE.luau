--!strict
-- SETUP_GUIDE.luau
-- Quick setup checklist for Checkpoint Rush

--[[

📋 SETUP CHECKLIST FOR CHECKPOINT RUSH
======================================

Follow these steps in order to get your game running:

1️⃣ CREATE REMOTE EVENTS
------------------------
In ReplicatedStorage, create a Folder named "Remotes"
Inside it, create these RemoteEvent instances:
  ✓ ProgressUpdated
  ✓ CoinsUpdated
  ✓ CheckpointReached
  ✓ ItemPurchased
  ✓ DataLoaded
  ✓ PurchaseRequest
  ✓ UseItem

How to create:
- Right-click ReplicatedStorage → Insert Object → Folder
- Name it "Remotes"
- Right-click Remotes → Insert Object → RemoteEvent
- Rename each RemoteEvent to match the names above


2️⃣ CREATE CHECKPOINTS
----------------------
For each stage in your obby:
  ✓ Create a BasePart (Part, SpawnLocation, etc.)
  ✓ Add tag "Checkpoint" (View → Tag Editor)
  ✓ Add attribute "StageIndex" (number) = 1, 2, 3, etc.
  ✓ Position the checkpoint where players should spawn

Example Checkpoint Setup:
- Name: "Checkpoint1"
- Tag: "Checkpoint"
- Attribute: StageIndex = 1
- Position: At the end of Stage 1


3️⃣ CREATE COINS
----------------
Scatter coins throughout your map:
  ✓ Create BasePart objects (spheres work well)
  ✓ Add tag "Coin"
  ✓ (Optional) Add attribute "CoinValue" = 10, 20, etc.
  ✓ Make them visually distinct (bright yellow/gold)
  ✓ Set CanCollide = false

Tip: Clone coins to place many quickly


4️⃣ ENABLE API SERVICES
-----------------------
Required for DataStore to work:
  ✓ Home → Game Settings
  ✓ Security tab
  ✓ Enable "Enable Studio Access to API Services"


5️⃣ BUILD YOUR OBBY
-------------------
  ✓ Create obstacle courses for each stage
  ✓ Make sure there's a clear path from Stage 1 → Stage N
  ✓ Place checkpoints at the end of each stage
  ✓ Add coins along the path (optional but recommended)
  ✓ Test that players can complete stages sequentially


6️⃣ TEST THE GAME
-----------------
  ✓ Press Play (F5)
  ✓ Walk to Checkpoint 1 and verify it saves
  ✓ Collect coins and verify UI updates
  ✓ Die/reset and verify respawn at checkpoint
  ✓ Open shop and try purchasing items
  ✓ Verify speed boost/double jump work after purchase


7️⃣ CUSTOMIZE (OPTIONAL)
------------------------
Edit these files to customize:
  • src/shared/Config/Stages.luau - Stage count, spawn position, coin respawn time
  • src/shared/Config/Items.luau - Shop items, prices, effects
  • src/client/Controllers/UIController.luau - UI colors, sizes, positions


🎯 QUICK START
==============

Minimum setup to test:
1. Create Remotes folder with all 7 RemoteEvents
2. Create 1 checkpoint part with tag "Checkpoint" and attribute StageIndex = 2
3. Create 1 coin part with tag "Coin"
4. Enable API Services
5. Press Play and test!


🔧 TROUBLESHOOTING
==================

Error: "Remotes:WaitForChild(...) is not a valid member"
Fix: Make sure all 7 RemoteEvents are created in ReplicatedStorage.Remotes

Error: Checkpoints not working
Fix: Verify the part has both:
     - Tag: "Checkpoint" (use Tag Editor)
     - Attribute: "StageIndex" (number)

Error: Data not saving
Fix: Enable "Studio Access to API Services" in Game Settings


📚 NEED HELP?
=============

See README.md for detailed documentation
All code is documented with comments

Happy developing! 🚀

--]]

return {}
