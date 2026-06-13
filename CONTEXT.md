# Resident Evil 4 2D

Resident Evil 4 2D is a Godot 4.6 side-scrolling action prototype. This document is the project handbook for future contributors and coding agents: it defines the project language, explains the main runtime systems, and points to the files that matter when changing behavior.

## Project Shape

- The project is configured in `project.godot`.
- The main scene is `levels/test_level.tscn`.
- The game runs at a 320x180 viewport and stretches to a 1920x1080 window.
- `Global` is an autoload from `common/global.gd` and stores shared player-facing state and signals.
- Current playable scope is a test level containing the player and Hector enemy instances.

## Canonical Language

**Player**:
The controllable character. The player owns movement state, aim direction, weapon selection, health, and the HUD.
_Code_: `player/scripts/player.gd`

**Enemy**:
A hostile NPC. Use "Enemy" in design and documentation even though the current base script class is named `Mob`.
_Avoid_: Mob, hostile

**Mob**:
The current code-level base class for enemies. Treat this as an implementation name, not the canonical domain term.
_Code_: `enemy/mob.gd`

**Hector**:
The current concrete enemy type used in the test level.
_Code_: `enemy/hector.tscn`

**Weapon**:
A player-owned firing tool mounted under the player's anchor. The player uses one generic weapon node whose active `WeaponConfig` determines the current weapon identity, projectile, active and inactive HUD icons, fire rate, and spread.
_Code_: `player/weapons/weapon.gd`

**Ammo-backed Weapon**:
A Weapon whose `WeaponConfig` names an ammunition item key and ammo-per-shot cost. It can stay unlocked and selectable at zero ammunition, but it only fires when the PlayerInventory can supply the required Stack Quantity.
_Code_: `player/scripts/weapon_inventory.gd`

**Unlocked Weapon**:
A weapon config available for player cycling and firing. Locked configs are ignored by the current weapon inventory.

**Handgun**:
An integrated current weapon. It fires a handgun projectile, is represented in the HUD, and intentionally uses infinite ammunition instead of consuming an inventory item.

**Shotgun**:
An integrated current Ammo-backed Weapon. It fires a shotgun projectile, is represented in the HUD, and consumes `shotgun_ammo` from the PlayerInventory when a shot actually fires.

**Sniper Rifle**:
A planned or future weapon. Sniper bullet and UI assets exist, but the sniper rifle is not currently wired into the player weapon set.

**Projectile**:
A spawned damaging object created by a weapon. Projectiles carry direction, damage, speed, range, and optional active lifetime.

**HitBox**:
An area that deals damage. Hit boxes emit when they overlap compatible hurt boxes and carry damage source flags.
_Code_: `common/hit_box.gd`

**HurtBox**:
An area that receives hits. Hurt boxes emit when compatible hit boxes overlap them and use flags to filter accepted damage sources.
_Code_: `common/hurt_box.gd`

**HealthComponent**:
The shared health state and damage-intake component for damageable actors. It can listen to an optional hurt box, exposes direct damage and healing methods, and emits health and death signals for the owning scene to handle.
_Code_: `common/health_component.gd`

**Aim Direction**:
The player's current snapped attack direction. It is shared through `Global.player_aim_direction` so weapons and animations can agree on firing direction.

**GridInventory**:
A reusable spatial inventory with finite columns and rows. It owns placed inventory items, validates rectangular cell occupancy, and emits when successful mutations change its contents. Do not confuse this with `WeaponInventory`, which is the current player weapon loadout selector.
_Code_: `inventory/grid_inventory.gd`

**Cell**:
One addressable position in a `GridInventory`. Cells use `Vector2i` coordinates with `(0, 0)` as the top-left cell.

**Inventory Cursor**:
The Pause Menu selector for the player inventory grid. It points at one focused `GridInventory` cell, moves by Cell through empty space while the Pause Menu is open, wraps at grid edges, can identify the `InventoryItem` occupying its current Cell, and treats that item's occupied footprint as one movement target while visually framing the full footprint.
_Code_: `player/scripts/inventory_grid_view.gd`

**Held Item**:
The Pause Menu inventory item currently picked up for repositioning. A Held Item follows the Inventory Cursor as a placement preview, can be rotated before placement, and does not mutate committed `GridInventory` state until placed.
_Code_: `player/scripts/inventory_grid_view.gd`

**Ammunition**:
A stackable inventory item consumed by an Ammo-backed Weapon. `shotgun_ammo` is the current ammunition item; handgun ammunition is intentionally not represented as an inventory item.
_Code_: `inventory/items/shotgun_ammo.tres`

**ItemConfig**:
A reusable item definition. It stores shared item data such as canonical item key, item type, display name, rectangular footprint, rotation permission, optional UI icon, stackability, and maximum stack quantity.
_Code_: `inventory/item_config.gd`

**InventoryItem**:
One placed copy of an `ItemConfig` inside a `GridInventory`. It owns per-copy state such as generated instance id, origin cell, rotation state, and Stack Quantity.
_Code_: `inventory/inventory_item.gd`

**Stackable Item**:
An InventoryItem whose ItemConfig allows multiple units to share one grid footprint up to a configured maximum. Stackable Items can merge with matching stackable items, and an empty stack is removed from the GridInventory.
_Code_: `inventory/grid_inventory.gd`

**Stack Quantity**:
The per-InventoryItem quantity stored on a Stackable Item. Stack Quantity is instance state, not shared ItemConfig state.
_Code_: `inventory/inventory_item.gd`

**PlayerInventory**:
A player-owned inventory component. It wraps the reusable `GridInventory`, owns the player's current spatial inventory contents, seeds the current demo inventory items, and exposes item quantity helpers used by ammo-backed weapons and the HUD.
_Code_: `player/scripts/player_inventory.gd`

**Pause Menu**:
The player-facing pause overlay opened by the `pause_menu` input action. It pauses gameplay and shows the player's inventory grid, including Inventory Cursor navigation and Held Item repositioning.
_Code_: `player/scripts/pause_menu.gd`

## Runtime Systems

### Player

The player is a `CharacterBody2D` with explicit movement states: ground, jump, fall, aim, and crouch. `player/scripts/player.gd` is a thin orchestrator that reads input once per physics frame and delegates behavior to child-node components in `player/player.tscn`.

Player ownership is split across:
- `PlayerMotor`: movement state, gravity, coyote timer, jump buffer, velocity changes, and crouch anchor offsets.
- `AimController`: horizontal input, snapped aim direction, facing, and compatibility writes to `Global.player_aim_direction` and `Global.player_last_direction`.
- `WeaponInventory`: exported weapon config inventory, unlocked config filtering, active config cycling, single weapon-node assignment, anchor rotation, per-weapon-key cooldown flow, and ammo-backed firing checks through `PlayerInventory`.
- `PlayerAnimator`: legs, body, head, and arms animation routing, including attack animation state and weapon-specific arm animations. It avoids restarting unchanged non-attack animations every frame, while attack animation restarts remain explicit.
- `PlayerInventory`: player-owned spatial inventory state backed by `GridInventory`.

Weapon choice and successful firing state influence arm animations, while aim direction can influence head and arm direction. `PlayerAnimator` resolves arm animations from `WeaponConfig.weapon_key` profiles and shared direction tokens, with handgun as the fallback profile. The player wires weapon inventory, inventory quantity, and health signals to the HUD; player weapon getters still delegate to the weapon inventory for compatibility with existing callers.

Important file: `player/scripts/player.gd`

### Aiming And Firing

`AimController` computes a snapped aim direction from movement input. When no meaningful aim input is present, `WeaponInventory` falls back to the player's last horizontal facing direction.

Pressing fire lets the active weapon spawn its projectile only when its fire timer is ready and any configured ammunition cost can be paid. The player's attack animation starts only for a successful shot. Firing can temporarily block crouch exit until the firing animation finishes. `Global.player_aim_direction` remains a compatibility surface written by `AimController`; new player internals should prefer direct controller/inventory references.

### Weapons And Projectiles

One generic weapon node lives under the player's `Anchor` marker. At startup, `WeaponInventory` filters exported `WeaponConfig` resources to the unlocked configs, assigns the first unlocked config to the weapon node, and cycles by swapping that node's active config.

The current integrated weapons are handgun and shotgun. Both use standalone config resources for projectile scene, fire rate, spread, active and inactive HUD icons, canonical weapon key, and optional ammunition data. `WeaponInventory` supplies the current fire direction, rotates the anchor, consumes configured ammunition only for successful shots, and tracks cooldowns per weapon key so cycling does not reset a weapon's cooldown.

Projectiles inherit from the shared projectile script, move along their direction, and destroy themselves on range, timer, animation completion, or hit depending on the concrete projectile.

Important files:
- `player/weapons/weapon.gd`
- `player/weapons/weapon_config.gd`
- `player/weapons/configs/handgun_weapon_config.tres`
- `player/weapons/configs/shotgun_weapon_config.tres`
- `player/weapons/weapon_fire_math.gd`
- `player/scripts/weapon_inventory.gd`
- `player/weapons/projectiles/scripts/projectile.gd`

### Damage And Health

Damage is handled through hit box and hurt box overlap, not direct calls between attackers and victims. Hit boxes declare their damage source and target mask. Hurt boxes declare their own type and accepted damage sources.

`HealthComponent` owns health state, damage math, clamping, and health/death signals. It can connect to a hurt box's hit signal as an adapter, but UI updates, death animation, global events, and queue-free behavior belong to the owning player, Enemy, or environment scene.

Important files:
- `common/hit_box.gd`
- `common/hurt_box.gd`
- `common/health_component.gd`

### Enemies

Enemy is the canonical project term. The current enemy base class is `Mob`, and Hector is the concrete enemy currently placed in `levels/test_level.tscn`.

The current enemy behavior is state-based: inactive, run, attack, wait, and die are represented in code. Hector has activation and attack areas, an attack hit box, health, and an animation player for enabling attack collision.

Important file: `enemy/mob.gd`

### Camera

The player owns the active `PlayerCamera`, a custom `Camera2D` controller that creates a Metal Slug-style side-scroller frame. Camera progress moves forward only, keeps the player around the left third of the 320x180 viewport when it can advance, and stops at authored camera bounds or active camera stops without rewriting the Player's position or velocity. It also uses lightweight forward lookahead and independently tunable horizontal and vertical tween-eased, pixel-snapped camera axes so the camera stays crisp for pixel art, while following a fixed `-48` pixel floor offset only while the Player is grounded.

The player scene also carries two `StaticBody2D` camera boundary bodies on the Camera node, one at each horizontal side of the frame, with controlled collision layer and mask settings so they only keep the Player inside the visible area. This visible-frame confinement is owned by scene collision bodies, not by `PlayerCamera`.

Levels define explicit `CameraBounds` so camera limits are authored intentionally instead of inferred from TileMap content. Authored level camera bounds are applied before the player's initial camera snap, so default camera bounds must not rewrite authored player spawn positions. The current test level includes explicit camera bounds. `CameraStopArea` can request and release horizontal camera stops for arena or boss encounters. Player off-screen movement is allowed by default when the camera is stopped; encounter confinement is a future opt-in gameplay system, not a responsibility of `PlayerCamera`.

Important files:
- `player/camera/player_camera.gd`
- `levels/camera_bounds.gd`
- `levels/camera_stop_area.gd`

### HUD

The player HUD shows weapon focus state, per-slot ammo counts, and player health. It renders weapon slots from the player's unlocked weapon configs in inventory order, uses each weapon config's active or inactive HUD icon for weapon-specific art, and owns the shared slot frame and focus indicator. Handgun displays infinite ammunition, while ammo-backed weapons display their current total matching Stack Quantity. The HUD updates from weapon inventory, inventory, and health signals instead of polling player state every frame.

Important files:
- `player/scripts/player_hud.gd`
- `player/scripts/player_hud_weapon_slot.gd`

### Grid Inventory

`GridInventory` is the core model for Resident Evil 4-style spatial inventory behavior. It is reusable gameplay infrastructure, not player-only UI state. The v1 system supports rectangular item footprints, per-item rotation permission, explicit placement, first-fit placement, moving, rotating, removing, occupancy queries, item lookup by Cell, stack quantities, stack merging, item quantity consumption, and result objects with failure reasons and leftover quantity.

The player currently has a Pause Menu inventory screen that renders the player-owned `GridInventory`, supports Inventory Cursor navigation, shows Stack Quantity labels, and lets the player use `inventory_pick_place` to pick/place a Held Item, merge matching stackable Held Items, and `inventory_rotate_item` to rotate before placement. There is no mouse drag and drop, stack splitting, pickup integration, or save/load format yet. `WeaponInventory` remains the current weapon loadout selector and cooldown owner.

Important files:
- `inventory/grid_inventory.gd`
- `inventory/item_config.gd`
- `inventory/inventory_item.gd`
- `inventory/inventory_placement_result.gd`

## Scene And Content Map

`common/` contains shared gameplay components such as global state, health, hit boxes, and hurt boxes.

`inventory/` contains reusable grid inventory model scripts.

`player/` contains the player scene, player logic, camera logic, weapons, projectiles, player animation assets, and HUD assets.

`enemy/` contains the enemy base scene/script and the Hector enemy scene and assets.

`levels/` contains level scenes and level assets. `levels/test_level.tscn` is the current main scene.

## Controls And Run Context

Input actions are defined in `project.godot`:

- `up`, `down`, `left`, `right`: movement and aim direction.
- `jump`: jump.
- `fire`: fire the current weapon.
- `aim`: enter aim state.
- `next_weapon`: cycle forward through unlocked weapons.
- `previous_weapon`: cycle backward through unlocked weapons.
- `pause_menu`: open and close the Pause Menu.
- `inventory_pick_place`: pick up or place the selected Pause Menu inventory item.
- `inventory_rotate_item`: rotate the currently Held Item in the Pause Menu inventory.

Keyboard defaults are WASD for directions, Space for jump, U for fire, I for aim, K for next weapon, J for previous weapon, Escape for the Pause Menu, Y for inventory pick/place, and Backspace for inventory item rotation. Gamepad bindings also exist for movement, jump, fire, aim, and weapon cycling.

## Tests

Player component tests use GUT 9.6.0 under `test/unit`. Run them with `scripts/run_gut_tests.ps1`; set `GODOT_BIN` to the local Godot 4.6 executable when Godot is not on `PATH`.

## Current Gaps

- Enemy activation, attack area transitions, and attack animation completion wiring are partly present but commented out in `enemy/mob.gd`.
- The enemy state enum includes `DIE`, but current Enemy death handling still removes the Enemy directly when health reaches zero.
- Sniper rifle assets, sniper bullet scene/script, and sniper HUD assets exist, but the sniper rifle is not integrated as a current player weapon.
- Camera stop triggers can request and release stops, but no current encounter system automatically releases stops when an Enemy wave or boss is cleared.
- Path2D camera rails are intentionally not part of the v1 camera implementation.
- The player scene's Camera node includes two boundary `StaticBody2D` nodes with constrained collision layers and masks to keep the Player from leaving the visible frame.
- The `Global` autoload defines `player_died`, `mob_died`, `player_level`, and `player_position`, but the inspected runtime code does not fully use all player state fields yet.
- Temporary `player.tscn*.tmp` files are present in the player folder and should not be treated as canonical scenes.
- The Pause Menu inventory screen does not yet have mouse drag/drop interaction, stack splitting, pickup integration, or save/load support.

## Contributor Notes

- Prefer the canonical terms in this document when naming new design concepts or writing documentation.
- Keep code changes aligned with the current scene ownership: player behavior in `player/`, enemy behavior in `enemy/`, and shared combat primitives in `common/`.
- When adding a weapon, create a weapon config resource, add it to the player's weapon inventory config list, provide projectile and HUD assets, and add animation profile handling if the weapon needs a new arm animation set.
- When adding an enemy, use "Enemy" in documentation and player-facing language, even if it inherits from the current `Mob` class.
- When changing damage behavior, verify hit box and hurt box flags together; mismatched flags make overlaps look broken even when collision shapes are correct.
- Future inventory item visuals should use predefined item view scenes attached to `ItemConfig` or selected by it. Keep `ItemConfig` and `InventoryItem` as the gameplay data source of truth, and treat item view scenes as presentation/interaction templates for rendering children such as ColorRects, Labels, icons, and quantity text.
