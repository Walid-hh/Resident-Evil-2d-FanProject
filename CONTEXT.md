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

**Unlocked Weapon**:
A weapon config available for player cycling and firing. Locked configs are ignored by the current weapon inventory.

**Handgun**:
An integrated current weapon. It fires a handgun projectile and is represented in the HUD.

**Shotgun**:
An integrated current weapon. It fires a shotgun projectile and is represented in the HUD.

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

## Runtime Systems

### Player

The player is a `CharacterBody2D` with explicit movement states: ground, jump, fall, aim, and crouch. `player/scripts/player.gd` is a thin orchestrator that reads input once per physics frame and delegates behavior to child-node components in `player/player.tscn`.

Player ownership is split across:
- `PlayerMotor`: movement state, gravity, coyote timer, jump buffer, velocity changes, and crouch anchor offsets.
- `AimController`: horizontal input, snapped aim direction, facing, and compatibility writes to `Global.player_aim_direction` and `Global.player_last_direction`.
- `WeaponInventory`: exported weapon config inventory, unlocked config filtering, active config cycling, single weapon-node assignment, anchor rotation, and per-weapon-key cooldown flow.
- `PlayerAnimator`: legs, body, head, and arms animation routing, including attack animation state and weapon-specific arm animations. It avoids restarting unchanged non-attack animations every frame, while attack animation restarts remain explicit.

Weapon choice and firing state influence arm animations, while aim direction can influence head and arm direction. `PlayerAnimator` resolves arm animations from `WeaponConfig.weapon_key` profiles and shared direction tokens, with handgun as the fallback profile. The player wires weapon inventory and health signals to the HUD; player weapon getters still delegate to the weapon inventory for compatibility with existing callers.

Important file: `player/scripts/player.gd`

### Aiming And Firing

`AimController` computes a snapped aim direction from movement input. When no meaningful aim input is present, `WeaponInventory` falls back to the player's last horizontal facing direction.

Pressing fire starts the player's attack animation state and lets the active weapon spawn its projectile if its fire timer is ready. Firing can temporarily block crouch exit until the firing animation finishes. `Global.player_aim_direction` remains a compatibility surface written by `AimController`; new player internals should prefer direct controller/inventory references.

### Weapons And Projectiles

One generic weapon node lives under the player's `Anchor` marker. At startup, `WeaponInventory` filters exported `WeaponConfig` resources to the unlocked configs, assigns the first unlocked config to the weapon node, and cycles by swapping that node's active config.

The current integrated weapons are handgun and shotgun. Both use standalone config resources for projectile scene, fire rate, spread, active and inactive HUD icons, and canonical weapon key. `WeaponInventory` supplies the current fire direction, rotates the anchor, and tracks cooldowns per weapon key so cycling does not reset a weapon's cooldown.

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

The player owns the active `PlayerCamera`, a custom `Camera2D` controller that creates a Metal Slug-style side-scroller frame. Camera progress moves forward only, keeps the player around the left third of the 320x180 viewport, prevents the player from falling behind the left screen edge, and while a camera stop is active it pins the player inside both visible frame edges. It also uses lightweight forward lookahead and keeps vertical motion mostly fixed so jumps do not bob the view.

Levels define explicit `CameraBounds` so camera limits are authored intentionally instead of inferred from TileMap content. `CameraStopArea` can request and release horizontal camera stops for arena or boss encounters.

Important files:
- `player/camera/player_camera.gd`
- `levels/camera_bounds.gd`
- `levels/camera_stop_area.gd`

### HUD

The player HUD shows weapon focus state and player health. It renders weapon slots from the player's unlocked weapon configs in inventory order, uses each weapon config's active or inactive HUD icon for weapon-specific art, and owns the shared slot frame and focus indicator. It updates from weapon inventory and health signals instead of polling player state every frame.

Important files:
- `player/scripts/player_hud.gd`
- `player/scripts/player_hud_weapon_slot.gd`

## Scene And Content Map

`common/` contains shared gameplay components such as global state, health, hit boxes, and hurt boxes.

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

Keyboard defaults are WASD for directions, Space for jump, U for fire, I for aim, K for next weapon, and J for previous weapon. Gamepad bindings also exist for movement, jump, fire, aim, and weapon cycling.

## Tests

Player component tests use GUT 9.6.0 under `test/unit`. Run them with `scripts/run_gut_tests.ps1`; set `GODOT_BIN` to the local Godot 4.6 executable when Godot is not on `PATH`.

## Current Gaps

- Enemy activation, attack area transitions, and attack animation completion wiring are partly present but commented out in `enemy/mob.gd`.
- The enemy state enum includes `DIE`, but current Enemy death handling still removes the Enemy directly when health reaches zero.
- Sniper rifle assets, sniper bullet scene/script, and sniper HUD assets exist, but the sniper rifle is not integrated as a current player weapon.
- Camera stop triggers can request and release stops, but no current encounter system automatically releases stops when an Enemy wave or boss is cleared.
- Path2D camera rails are intentionally not part of the v1 camera implementation.
- The `Global` autoload defines `player_died`, `mob_died`, `player_level`, and `player_position`, but the inspected runtime code does not fully use all player state fields yet.
- Temporary `player.tscn*.tmp` files are present in the player folder and should not be treated as canonical scenes.

## Contributor Notes

- Prefer the canonical terms in this document when naming new design concepts or writing documentation.
- Keep code changes aligned with the current scene ownership: player behavior in `player/`, enemy behavior in `enemy/`, and shared combat primitives in `common/`.
- When adding a weapon, create a weapon config resource, add it to the player's weapon inventory config list, provide projectile and HUD assets, and add animation profile handling if the weapon needs a new arm animation set.
- When adding an enemy, use "Enemy" in documentation and player-facing language, even if it inherits from the current `Mob` class.
- When changing damage behavior, verify hit box and hurt box flags together; mismatched flags make overlaps look broken even when collision shapes are correct.
