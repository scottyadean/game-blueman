# Project Init — Next Steps

A vertical-slice roadmap from "scaffold exists" to "playable game". Build one tiny end-to-end loop before going deep on any subsystem.

## 1. Verify the toolchain end-to-end (~30 min) ✅

- `rokit install`
- `rojo build -o place/SendHelp.rbxlx` (first-time bootstrap only)
- Open [place/SendHelp.rbxlx](../place/SendHelp.rbxlx) in Studio → install Rojo plugin from Marketplace → click **Connect**.
- Edit [src/ServerScriptService/GameLoop.server.luau](../src/ServerScriptService/GameLoop.server.luau) → save → confirm `[GameLoop] server starting` shows in Studio's Output panel.

**Don't move forward until this loop works.** Most Rojo headaches are setup-day headaches.

## 2. Decide where world geometry lives ✅ chose (A)

Code lives in [src/](../src/) via Rojo, but rooms, baseplates, spawn points, and props live in the Roblox `.rbxlx` place file. We chose **option (A): check the place file into git** at [place/SendHelp.rbxlx](../place/SendHelp.rbxlx). Simple, fine while solo. Diffs are effectively useless (XML), but you don't need diffs as a one-person team.

Future revisit triggers (then move to B or C):

- **(B) Export rooms as `.rbxmx` model files** under `src/Workspace/Rooms/`, version-controlled, Rojo merges them in. Cleaner for collaborators. More upfront work.
- **(C) Hybrid:** baseplate via (A), individual rooms via (B).

Switch to (B/C) the first time a friend joins Team Create or merge conflicts on the place file become real.

## 3. First playable slice (1–2 weeks)

Smallest thing that's actually *a game*: **one safe room → one zone → escape beacon.** No procedural gen. No crafting yet.

1. Build geometry in Studio: safe room, hallway, target room with an "exit" Part.
2. Movement: Roblox gives free WASD + jump. Add Shift-sprint with the 5s stamina cooldown from the design doc — first custom control to write.
3. One enemy: **Splat** (lower-damage, slower) before Blueboons. Spawn it, simple chase AI (`Humanoid:MoveTo`), damage on touch.
4. One weapon: Roblox `Tool` instance with basic raycast + damage. Skip recipes — start as a starter tool in `StarterPack`.
5. Win condition: walking onto the exit Part → server fires a `RemoteEvent` → "You escaped" GUI.

Once it's playable for 60 seconds, *then* layer on the rest.

## 4. Then, in priority order

- **HUD**: stamina bar (health bar comes free from Roblox).
- **Crafting**: one recipe end-to-end (pickup `Gunpowder` + `Casing` → workbench prompt → grenade tool appears). [CraftingRecipes.luau](../src/ReplicatedStorage/Shared/CraftingRecipes.luau) already has the shape.
- **Currency**: blueViles pickups + DataStore persistence. DataStore is where new Roblox devs hit their first real bug — set aside time.
- **Second enemy**: Blueboons.
- **Multiple zones** (still hand-built, not procedural).
- **Procedural generation**: hard. Save it for last. Many shipped Roblox games fake it with prefab room shuffling rather than true PCG — that's almost certainly what you want.
- **Hero's Journey / unlocks**: only after everything else works.

## Practical recommendations

- **Test in Studio with multiple players** early — `Test → Start` with 2 players. Filtering bugs (server vs client logic) surface immediately and are painful to retrofit.
- **Set up Team Create now**, even before inviting friends. It auto-saves every few minutes to Roblox cloud — your real backup for world geometry that git can't usefully diff.
