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
A player-owned firing tool mounted under the player's anchor. A weapon can be unlocked, selected, and responsible for spawning a projectile scene.
_Code_: `player/weapons/weapon.gd`

**Unlocked Weapon**:
A weapon available for player cycling and firing. Locked weapons are ignored by the current weapon processor.

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
The shared health owner for damageable actors. It listens to a hurt box, subtracts hit box damage, updates an optional health bar, and removes its parent at zero health.
_Code_: `common/health_component.gd`

**Aim Direction**:
The player's current snapped attack direction. It is shared through `Global.player_aim_direction` so weapons and animations can agree on firing direction.

**CameraArea**:
A level-authored zone that constrains or focuses camera movement. Camera areas define jurisdiction, center boundary, zoom, and transition behavior.
_Code_: `player/camera/camera_area_extended.gd`

## Runtime Systems

### Player

The player is a `CharacterBody2D` with explicit movement states: ground, jump, fall, aim, and crouch. `player/scripts/player.gd` is a thin orchestrator that reads input once per physics frame and delegates behavior to child-node components in `player/player.tscn`.

Player ownership is split across:
- `PlayerMotor`: movement state, gravity, coyote timer, jump buffer, velocity changes, and crouch anchor offsets.
- `AimController`: horizontal input, snapped aim direction, facing, and compatibility writes to `Global.player_aim_direction` and `Global.player_last_direction`.
- `WeaponInventory`: unlocked weapon discovery from the player's anchor, active weapon cycling, active weapon processing, anchor rotation, and shared fire cooldown flow.
- `PlayerAnimator`: legs, body, head, and arms animation routing, including attack animation state and weapon-specific arm animations. It avoids restarting unchanged non-attack animations every frame, while attack animation restarts remain explicit.

Weapon choice and firing state influence arm animations, while aim direction can influence head and arm direction. `PlayerAnimator` resolves arm animations from weapon-specific prefixes and shared direction tokens, with handgun as the fallback profile. HUD-facing player getters still delegate to the weapon inventory so the HUD can read the active and unlocked weapons without owning weapon state.

Important file: `player/scripts/player.gd`

### Aiming And Firing

`AimController` computes a snapped aim direction from movement input. When no meaningful aim input is present, `WeaponInventory` falls back to the player's last horizontal facing direction.

Pressing fire starts the player's attack animation state and lets the active weapon spawn its projectile if its fire timer is ready. Firing can temporarily block crouch exit until the firing animation finishes. `Global.player_aim_direction` remains a compatibility surface written by `AimController`; new player internals should prefer direct controller/inventory references.

### Weapons And Projectiles

Weapons live under the player's `Anchor` marker. At startup, `WeaponInventory` gathers unlocked weapons from that anchor and disables processing for weapons that are not currently selected.

The current integrated weapons are handgun and shotgun. Both inherit from `Weapon`; the shared base owns cooldown timing and projectile spawning, while `WeaponInventory` supplies the current fire direction and rotates the anchor.

Projectiles inherit from the shared projectile script, move along their direction, and destroy themselves on range, timer, animation completion, or hit depending on the concrete projectile.

Important files:
- `player/weapons/weapon.gd`
- `player/weapons/handgun.gd`
- `player/weapons/shotgun.gd`
- `player/scripts/weapon_inventory.gd`
- `player/weapons/projectiles/scripts/projectile.gd`

### Damage And Health

Damage is handled through hit box and hurt box overlap, not direct calls between attackers and victims. Hit boxes declare their damage source and target mask. Hurt boxes declare their own type and accepted damage sources.

`HealthComponent` connects to a hurt box's hit signal, subtracts the incoming hit box damage, updates a local health bar if one exists, and queues the actor for deletion when health reaches zero.

Important files:
- `common/hit_box.gd`
- `common/hurt_box.gd`
- `common/health_component.gd`

### Enemies

Enemy is the canonical project term. The current enemy base class is `Mob`, and Hector is the concrete enemy currently placed in `levels/test_level.tscn`.

The current enemy behavior is state-based: inactive, run, attack, wait, and die are represented in code. Hector has activation and attack areas, an attack hit box, health, and an animation player for enabling attack collision.

Important file: `enemy/mob.gd`

### Camera

The camera follows the player with horizontal lookahead, smoothing, pixel snapping, zoom interpolation, optional peek, and shake. Camera bounds and focus behavior come from `CameraArea` nodes grouped as `camera_area`.

Camera areas own two related concepts:
- Jurisdiction: the polygon that decides whether the player is inside the area.
- Center boundary: the polygon that constrains where the camera center may move.

Important files:
- `player/camera/camera_extended.gd`
- `player/camera/camera_area_extended.gd`

### HUD

The player HUD shows weapon focus state and player health. The HUD currently supports handgun and shotgun weapon slots. It reads the player's current weapon and unlocked weapon list instead of maintaining an independent weapon model.

Important file: `player/scripts/player_hud.gd`

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
- The enemy state enum includes `DIE`, but current health behavior removes the parent directly when health reaches zero.
- Sniper rifle assets, sniper bullet scene/script, and sniper HUD assets exist, but the sniper rifle is not integrated as a current player weapon.
- The `Global` autoload defines `player_died`, `mob_died`, `player_level`, and `player_position`, but the inspected runtime code does not fully use all of them yet.
- Temporary `player.tscn*.tmp` files are present in the player folder and should not be treated as canonical scenes.

## Contributor Notes

- Prefer the canonical terms in this document when naming new design concepts or writing documentation.
- Keep code changes aligned with the current scene ownership: player behavior in `player/`, enemy behavior in `enemy/`, and shared combat primitives in `common/`.
- When adding a weapon, wire it through the player anchor, unlock flow, projectile scene, animation handling, and HUD representation.
- When adding an enemy, use "Enemy" in documentation and player-facing language, even if it inherits from the current `Mob` class.
- When changing damage behavior, verify hit box and hurt box flags together; mismatched flags make overlaps look broken even when collision shapes are correct.
