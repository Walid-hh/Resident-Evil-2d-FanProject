# Resident Evil 4 2D

Resident Evil 4 2D is a Godot 4.6 side-scrolling action prototype. This document is the project handbook for future contributors and coding agents: it defines the project language, explains the main runtime systems, and points to the files that matter when changing behavior.

## Project Shape

- The project is configured in `project.godot`.
- The main scene is `levels/test_level.tscn`.
- The game runs at a 320x180 viewport and stretches to a 1920x1080 window.
- `Global` is an autoload from `common/global.gd` and stores shared player-facing state and signals.
- Current playable scope is a test level containing the player, a MeleeEnemy instance, and a RangedEnemy instance.

## Canonical Language

**Player**:
The controllable character. The player owns movement state, aim direction, weapon selection, health, and the HUD.
_Code_: `player/scripts/player.gd`

**Enemy**:
A hostile NPC. Use "Enemy" in design and documentation.
_Code_: `enemy/enemy.gd`
_Avoid_: Mob, hostile

**MeleeEnemy**:
The first concrete Enemy type. It is a normal-speed melee enemy that wakes from an activation area, chases horizontally, attacks through an authored melee hit window, recovers, and resumes chasing.
_Code_: `enemy/melee_enemy.tscn`

**RangedEnemy**:
A concrete Enemy type that wakes from an activation area, chases horizontally until the Player is within maximum attack range, fires an enemy-owned projectile from an authored spawn point only when that spawn point is visible in the active camera frame, recovers, and resumes chasing or firing.
_Code_: `enemy/ranged_enemy.tscn`

**Weapon**:
A player-owned firing tool mounted under the player's anchor. The player uses one generic weapon node whose active `WeaponConfig` determines the current weapon identity, projectile, active and inactive HUD icons, fire rate, and spread.
_Code_: `player/weapons/weapon.gd`

**Ammo-backed Weapon**:
A Weapon whose `WeaponConfig` names an ammunition item key and ammo-per-shot cost. It can stay unlocked at zero ammunition, but it is only selectable and fireable when the PlayerInventory can supply the required Item Quantity.
_Code_: `player/scripts/weapon_inventory.gd`

**Unlocked Weapon**:
A weapon config included in the player's weapon loadout. Locked configs are ignored by the current weapon inventory.

**Available Weapon**:
An Unlocked Weapon that can currently be selected. Infinite-ammo weapons are always available, while Ammo-backed Weapons require enough Item Quantity for one shot.

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

**Fixed-Slot Inventory**:
A player-owned inventory model made of authored Inventory Slots. Each slot is tied to one predefined Inventory Item Definition and stores only that item's Item Quantity; items are not moved, rotated, swapped, or placed in a spatial grid.
_Code_: `player/scripts/player_inventory.gd`

**Ammunition**:
A predefined inventory item consumed by an Ammo-backed Weapon. `shotgun_ammo` is the current ammunition item; handgun ammunition is intentionally not represented as an inventory item.
_Code_: `inventory/items/shotgun_ammo.tres`

**Inventory Item Definition**:
A reusable non-spatial item definition. It stores the canonical item key, item type, display name, optional icon, and maximum Item Quantity.
_Code_: `inventory/inventory_item_definition.gd`

**Inventory Slot**:
An authored PlayerInventory entry that points to one Inventory Item Definition and provides its starting Item Quantity. The slot remains part of the inventory even when its Item Quantity reaches zero.
_Code_: `inventory/inventory_slot_definition.gd`

**Item Quantity**:
The runtime count stored for one Inventory Slot. Item Quantity is player inventory state, not shared Inventory Item Definition state.
_Code_: `player/scripts/player_inventory.gd`

**PlayerInventory**:
A player-owned Fixed-Slot Inventory component. It owns current Item Quantities for authored Inventory Slots and exposes quantity helpers used by ammo-backed weapons and the HUD.
_Code_: `player/scripts/player_inventory.gd`

**Pause Menu**:
The player-facing pause overlay opened by the `pause_menu` input action. It pauses gameplay and currently does not show inventory UI.
_Code_: `player/scripts/pause_menu.gd`

## Runtime Systems

### Player

The player is a `CharacterBody2D` with explicit movement states: ground, jump, fall, aim, and crouch. `player/scripts/player.gd` is a thin orchestrator that reads input once per physics frame and delegates behavior to child-node components in `player/player.tscn`.

Player ownership is split across:
- `PlayerMotor`: movement state, gravity, coyote timer, jump buffer, velocity changes, and crouch anchor offsets.
- `AimController`: horizontal input, snapped aim direction, facing, and compatibility writes to `Global.player_aim_direction` and `Global.player_last_direction`.
- `WeaponInventory`: exported weapon config inventory, unlocked config filtering, available weapon cycling, single weapon-node assignment, anchor rotation, per-weapon-key cooldown flow, and ammo-backed firing checks through `PlayerInventory`.
- `PlayerAnimator`: legs, body, head, and arms animation routing, including attack animation state and weapon-specific arm animations. It avoids restarting unchanged non-attack animations every frame, while attack animation restarts remain explicit.
- `PlayerInventory`: player-owned Fixed-Slot Inventory state.

Weapon choice and successful firing state influence arm animations, while aim direction can influence head and arm direction. `PlayerAnimator` resolves arm animations from `WeaponConfig.weapon_key` profiles and shared direction tokens, with handgun as the fallback profile. The player wires weapon inventory, inventory quantity, and health signals to the HUD; player weapon getters still delegate to the weapon inventory for compatibility with existing callers.

Important file: `player/scripts/player.gd`

### Aiming And Firing

`AimController` computes a snapped aim direction from movement input. When no meaningful aim input is present, `WeaponInventory` falls back to the player's last horizontal facing direction.

Pressing fire lets the active weapon spawn its projectile only when its fire timer is ready and any configured ammunition cost can be paid. The player's attack animation starts only for a successful shot. If an Ammo-backed Weapon spends its last available shot, weapon selection falls back to Handgun. Firing can temporarily block crouch exit until the firing animation finishes. `Global.player_aim_direction` remains a compatibility surface written by `AimController`; new player internals should prefer direct controller/inventory references.

### Weapons And Projectiles

One generic weapon node lives under the player's `Anchor` marker. At startup, `WeaponInventory` filters exported `WeaponConfig` resources to the unlocked configs, assigns the first unlocked config to the weapon node, and cycles by swapping that node's active config. Empty Ammo-backed Weapons remain visible in the HUD but are skipped by weapon cycling until ammunition is available again.

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

Enemy is the canonical project term. `Enemy` is the shared base behavior. `MeleeEnemy` and `RangedEnemy` are the current concrete enemy types.

Current enemy behavior is state-based: inactive, chase, attack, recover, and death. MeleeEnemy uses authored activation and attack areas, horizontal side-scroller chase movement, an animation-driven attack hit box, a recovery timer, and HealthComponent-driven death. RangedEnemy uses authored activation, horizontal side-scroller chase movement, maximum attack-range checks, camera-visible projectile spawn checks, enemy-owned projectile firing, a recovery timer, and HealthComponent-driven death.

Enemy behavior is split across:
- `Enemy`: state ownership, health/death handling, animation routing, and component orchestration.
- `EnemyConfig`: per-type health, movement, recovery, and animation names.
- `RangedEnemyConfig`: RangedEnemy attack range and projectile scene tuning.
- `EnemySensing`: activation and attack-area player detection.
- `EnemyHorizontalChaseMovement`: v1 horizontal chase movement and gravity.
- `EnemyAttackController`: shared attack-controller boundary used by concrete attack controllers.
- `EnemyMeleeAttackController`: attack hit-box lifecycle and attack completion.
- `EnemyRangedAttackController`: projectile spawn, enemy projectile instancing, and ranged attack completion.
- `EnemyCameraVisibility`: camera-frame visibility queries for enemy-owned attack gates.

Important files:
- `enemy/enemy.gd`
- `enemy/melee_enemy.tscn`
- `enemy/ranged_enemy.tscn`
- `enemy/configs/melee_enemy_config.tres`
- `enemy/configs/ranged_enemy_config.tres`

### Camera

The player owns the active `PlayerCamera`, a custom `Camera2D` controller that creates a Metal Slug-style side-scroller frame. Camera progress moves forward only, keeps the player around the left third of the 320x180 viewport when it can advance, and stops at authored camera bounds or active camera stops without rewriting the Player's position or velocity. It also uses lightweight forward lookahead and independently tunable horizontal and vertical tween-eased, pixel-snapped camera axes so the camera stays crisp for pixel art, while following a fixed `-48` pixel floor offset only while the Player is grounded.

The player scene also carries two `StaticBody2D` camera boundary bodies on the Camera node, one at each horizontal side of the frame, with controlled collision layer and mask settings so they only keep the Player inside the visible area. This visible-frame confinement is owned by scene collision bodies, not by `PlayerCamera`.

Levels define explicit `CameraBounds` so camera limits are authored intentionally instead of inferred from TileMap content. Authored level camera bounds are applied before the player's initial camera snap, so default camera bounds must not rewrite authored player spawn positions. The current test level includes explicit camera bounds. `CameraStopArea` can request and release horizontal camera stops for arena or boss encounters. Player off-screen movement is allowed by default when the camera is stopped; encounter confinement is a future opt-in gameplay system, not a responsibility of `PlayerCamera`.

Important files:
- `player/camera/player_camera.gd`
- `levels/camera_bounds.gd`
- `levels/camera_stop_area.gd`

### HUD

The player HUD shows weapon focus state, per-slot ammo counts, and player health. It renders weapon slots from the player's unlocked weapon configs in inventory order, uses each weapon config's active or inactive HUD icon for weapon-specific art, and owns the shared slot frame and focus indicator. Handgun displays infinite ammunition, while ammo-backed weapons display their current Item Quantity. The HUD updates from weapon inventory, inventory, and health signals instead of polling player state every frame.

Important files:
- `player/scripts/player_hud.gd`
- `player/scripts/player_hud_weapon_slot.gd`

### Fixed-Slot Inventory

`PlayerInventory` is the core model for current inventory behavior. It owns authored Inventory Slots and runtime Item Quantities keyed by Inventory Item Definition item keys. The current integrated slots are green herb, shotgun ammo, and first aid spray. Unknown non-empty item keys are treated as authoring errors, while an empty item key remains the compatibility surface for infinite or no-ammunition weapons.

The Pause Menu no longer renders inventory contents or supports item movement. There is no item-use flow, pickup integration, inventory display UI, or save/load format yet. `WeaponInventory` remains the current weapon loadout selector and cooldown owner.

Important files:
- `player/scripts/player_inventory.gd`
- `inventory/inventory_item_definition.gd`
- `inventory/inventory_slot_definition.gd`
- `inventory/inventory_quantity_result.gd`

## Scene And Content Map

`common/` contains shared gameplay components such as global state, health, hit boxes, and hurt boxes.

`inventory/` contains fixed-slot inventory item and slot definition resources.

`player/` contains the player scene, player logic, camera logic, weapons, projectiles, player animation assets, and HUD assets.

`enemy/` contains the Enemy base scene/script, MeleeEnemy content, enemy configs, enemy components, and enemy assets.

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

Keyboard defaults are WASD for directions, Space for jump, U for fire, I for aim, K for next weapon, J for previous weapon, and Escape for the Pause Menu. Gamepad bindings also exist for movement, jump, fire, aim, weapon cycling, and the Pause Menu.

## Tests

Player component tests use GUT 9.6.0 under `test/unit`. Run them with `test/run_gut_tests.ps1`; set `GODOT_BIN` to the local Godot 4.6 executable when Godot is not on `PATH`.

## Current Gaps

- Sniper rifle assets, sniper bullet scene/script, and sniper HUD assets exist, but the sniper rifle is not integrated as a current player weapon.
- Camera stop triggers can request and release stops, but no current encounter system automatically releases stops when an Enemy wave or boss is cleared.
- Path2D camera rails are intentionally not part of the v1 camera implementation.
- The player scene's Camera node includes two boundary `StaticBody2D` nodes with constrained collision layers and masks to keep the Player from leaving the visible frame.
- The `Global` autoload defines `player_died`, `enemy_died`, `player_level`, and `player_position`, but the inspected runtime code does not fully use all player state fields yet.
- Temporary `player.tscn*.tmp` files are present in the player folder and should not be treated as canonical scenes.
- There is no inventory display UI, item-use flow, pickup integration, or save/load support.

## Contributor Notes

- Prefer the canonical terms in this document when naming new design concepts or writing documentation.
- Keep code changes aligned with the current scene ownership: player behavior in `player/`, enemy behavior in `enemy/`, and shared combat primitives in `common/`.
- When adding a weapon, create a weapon config resource, add it to the player's weapon inventory config list, provide projectile and HUD assets, and add animation profile handling if the weapon needs a new arm animation set.
- When adding an enemy, use "Enemy" in documentation and player-facing language. Prefer EnemyConfig and enemy-owned components over adding behavior to the shared Enemy owner.
- When changing damage behavior, verify hit box and hurt box flags together; mismatched flags make overlaps look broken even when collision shapes are correct.
- Future inventory item visuals should treat `InventoryItemDefinition` and `PlayerInventory` as the gameplay data source of truth. Keep item presentation separate from Item Quantity storage.
