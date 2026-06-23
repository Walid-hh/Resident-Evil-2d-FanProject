class_name WeaponInventory extends Node

signal unlocked_weapon_configs_changed(unlocked_weapon_configs: Array[WeaponConfig])
signal active_weapon_config_changed(active_weapon_config: WeaponConfig)

@export var anchor: Marker2D
@export var weapon: Weapon
@export var player_inventory: PlayerInventory
@export var weapon_configs: Array[WeaponConfig] = []

var unlocked_weapon_configs: Array[WeaponConfig] = []
var active_weapon_config: WeaponConfig
var last_fired_weapon_config: WeaponConfig
var _active_weapon_index := -1
var _cooldowns: Dictionary = {}


func initialize() -> void:
	_unlock_weapon_configs()
	_connect_player_inventory_signals()
	_select_weapon_index(0)
	_enforce_active_weapon_availability(false)
	unlocked_weapon_configs_changed.emit(unlocked_weapon_configs.duplicate())
	active_weapon_config_changed.emit(active_weapon_config)


func physics_update(delta: float, fire_pressed: bool, aim_direction: Vector2, fallback_direction: float) -> bool:
	last_fired_weapon_config = null
	_process_active_cooldown(delta)
	var fire_direction := WeaponFireMath.get_fire_direction(aim_direction, fallback_direction)

	WeaponFireMath.apply_anchor_rotation(anchor, fire_direction)

	if fire_pressed and weapon != null and active_weapon_config != null and _can_active_weapon_fire():
		var fired_weapon_config := active_weapon_config
		if !_consume_weapon_ammo(fired_weapon_config):
			return false

		weapon.config = fired_weapon_config
		weapon.fire(fire_direction)
		_cooldowns[_get_config_key(fired_weapon_config)] = 0.0
		last_fired_weapon_config = fired_weapon_config
		_enforce_active_weapon_availability()
		if weapon != null:
			weapon.config = active_weapon_config
		return true

	return false


func cycle_next_unlocked_weapon() -> void:
	if unlocked_weapon_configs.is_empty():
		return

	_select_available_weapon_from(_active_weapon_index + 1, 1)


func cycle_previous_unlocked_weapon() -> void:
	if unlocked_weapon_configs.is_empty():
		return

	_select_available_weapon_from(_active_weapon_index - 1, -1)


func get_weapon_in_use() -> Weapon:
	return weapon


func get_active_weapon_config() -> WeaponConfig:
	return active_weapon_config


func get_last_fired_weapon_config() -> WeaponConfig:
	return last_fired_weapon_config


func get_unlocked_weapon_configs() -> Array[WeaponConfig]:
	return unlocked_weapon_configs


func _unlock_weapon_configs() -> void:
	unlocked_weapon_configs.clear()
	active_weapon_config = null
	last_fired_weapon_config = null
	_active_weapon_index = -1
	_cooldowns.clear()

	for config: WeaponConfig in weapon_configs:
		if config == null or !config.unlocked_by_default:
			continue

		unlocked_weapon_configs.append(config)
		_cooldowns[_get_config_key(config)] = config.fire_rate


func _connect_player_inventory_signals() -> void:
	if player_inventory == null:
		return

	var callback := Callable(self, "_on_player_inventory_changed")
	if player_inventory.inventory_changed.is_connected(callback):
		return

	player_inventory.inventory_changed.connect(callback)


func _select_weapon_index(index: int) -> void:
	if unlocked_weapon_configs.is_empty():
		active_weapon_config = null
		_active_weapon_index = -1
		if weapon != null:
			weapon.config = null
		return

	_active_weapon_index = posmod(index, unlocked_weapon_configs.size())
	active_weapon_config = unlocked_weapon_configs[_active_weapon_index]
	if weapon != null:
		weapon.config = active_weapon_config


func _select_available_weapon_from(start_index: int, step: int) -> void:
	if unlocked_weapon_configs.is_empty():
		return

	for offset in unlocked_weapon_configs.size():
		var candidate_index := posmod(start_index + (offset * step), unlocked_weapon_configs.size())
		var candidate_config := unlocked_weapon_configs[candidate_index]
		if !_is_weapon_available(candidate_config):
			continue

		_select_weapon_index(candidate_index)
		active_weapon_config_changed.emit(active_weapon_config)
		return

	_force_select_handgun()


func _enforce_active_weapon_availability(emit_signal := true) -> void:
	if active_weapon_config == null or _is_weapon_available(active_weapon_config):
		return

	if _force_select_handgun() and emit_signal:
		active_weapon_config_changed.emit(active_weapon_config)


func _force_select_handgun() -> bool:
	var handgun_index := _get_handgun_index()
	if handgun_index == -1:
		return false
	if handgun_index == _active_weapon_index:
		return false

	_select_weapon_index(handgun_index)
	return true


func _get_handgun_index() -> int:
	for index in unlocked_weapon_configs.size():
		if _get_config_key(unlocked_weapon_configs[index]) == &"handgun":
			return index

	return -1


func _is_weapon_available(config: WeaponConfig, report_errors := false) -> bool:
	if config == null:
		return false
	if config.ammo_item_key == &"":
		return true
	if player_inventory == null:
		return false
	if !report_errors and !player_inventory.has_item_slot(config.ammo_item_key):
		return false

	return player_inventory.has_item_quantity(config.ammo_item_key, config.ammo_per_shot)


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
	if !_is_weapon_available(active_weapon_config, true):
		return false

	var key := _get_config_key(active_weapon_config)
	return float(_cooldowns.get(key, active_weapon_config.fire_rate)) >= active_weapon_config.fire_rate


func _consume_weapon_ammo(config: WeaponConfig) -> bool:
	if config == null:
		return false
	if config.ammo_item_key == &"":
		return true
	if player_inventory == null:
		return false

	return player_inventory.consume_item_quantity(config.ammo_item_key, config.ammo_per_shot)


func _on_player_inventory_changed() -> void:
	_enforce_active_weapon_availability()


func _get_config_key(config: WeaponConfig) -> StringName:
	if config == null or config.weapon_key == &"":
		return &"weapon"

	return config.weapon_key
