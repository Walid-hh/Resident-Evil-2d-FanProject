class_name WeaponInventory extends Node

@export var anchor: Marker2D
@export var weapon: Weapon
@export var weapon_configs: Array[WeaponConfig] = []

var unlocked_weapon_configs: Array[WeaponConfig] = []
var active_weapon_config: WeaponConfig
var _active_weapon_index := -1
var _cooldowns: Dictionary = {}


func initialize() -> void:
	_unlock_weapon_configs()
	_select_weapon_index(0)


func physics_update(delta: float, fire_pressed: bool, aim_direction: Vector2, fallback_direction: float) -> void:
	_process_active_cooldown(delta)
	var fire_direction := WeaponFireMath.get_fire_direction(aim_direction, fallback_direction)

	WeaponFireMath.apply_anchor_rotation(anchor, fire_direction)

	if fire_pressed and weapon != null and active_weapon_config != null and _can_active_weapon_fire():
		weapon.fire(fire_direction)
		_cooldowns[_get_config_key(active_weapon_config)] = 0.0


func cycle_next_unlocked_weapon() -> void:
	if unlocked_weapon_configs.is_empty():
		return

	_select_weapon_index((_active_weapon_index + 1) % unlocked_weapon_configs.size())


func cycle_previous_unlocked_weapon() -> void:
	if unlocked_weapon_configs.is_empty():
		return

	_select_weapon_index((_active_weapon_index - 1) % unlocked_weapon_configs.size())


func get_weapon_in_use() -> Weapon:
	return weapon


func get_active_weapon_config() -> WeaponConfig:
	return active_weapon_config


func get_unlocked_weapon_configs() -> Array[WeaponConfig]:
	return unlocked_weapon_configs


func _unlock_weapon_configs() -> void:
	unlocked_weapon_configs.clear()
	active_weapon_config = null
	_active_weapon_index = -1
	_cooldowns.clear()

	for config: WeaponConfig in weapon_configs:
		if config == null or !config.unlocked_by_default:
			continue

		unlocked_weapon_configs.append(config)
		_cooldowns[_get_config_key(config)] = config.fire_rate


func _select_weapon_index(index: int) -> void:
	if unlocked_weapon_configs.is_empty() or weapon == null:
		return

	_active_weapon_index = posmod(index, unlocked_weapon_configs.size())
	active_weapon_config = unlocked_weapon_configs[_active_weapon_index]
	weapon.config = active_weapon_config


func _process_active_cooldown(delta: float) -> void:
	if active_weapon_config == null:
		return

	var key := _get_config_key(active_weapon_config)
	_cooldowns[key] = float(_cooldowns.get(key, active_weapon_config.fire_rate)) + delta


func _can_active_weapon_fire() -> bool:
	if active_weapon_config == null:
		return false
	if active_weapon_config.projectile_scene == null:
		return false

	var key := _get_config_key(active_weapon_config)
	return float(_cooldowns.get(key, active_weapon_config.fire_rate)) >= active_weapon_config.fire_rate


func _get_config_key(config: WeaponConfig) -> StringName:
	if config == null or config.weapon_key == &"":
		return &"weapon"

	return config.weapon_key
