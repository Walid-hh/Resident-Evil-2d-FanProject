class_name WeaponInventory extends Node

@export var anchor: Marker2D

var weapons_unlocked: Array[Weapon] = []
var weapon_in_use: Weapon


func initialize() -> void:
	_unlock_weapons()


func physics_update(delta: float, fire_pressed: bool, aim_direction: Vector2, fallback_direction: float) -> void:
	_process_weapon_in_use(delta)
	var fire_direction := get_fire_direction(aim_direction, fallback_direction)

	if anchor != null:
		anchor.global_rotation = fire_direction.angle()

	if fire_pressed and weapon_in_use != null and weapon_in_use.can_fire():
		weapon_in_use.fire(fire_direction)


func get_fire_direction(aim_direction: Vector2, fallback_direction: float) -> Vector2:
	var fire_direction := aim_direction.normalized()
	if fire_direction == Vector2.ZERO:
		fire_direction.x = fallback_direction
	return fire_direction


func cycle_next_unlocked_weapon() -> void:
	if weapons_unlocked.is_empty() or weapon_in_use == null:
		return

	var index := weapons_unlocked.find(weapon_in_use)
	var next_index := (index + 1) % weapons_unlocked.size()
	weapon_in_use = weapons_unlocked[next_index]


func cycle_previous_unlocked_weapon() -> void:
	if weapons_unlocked.is_empty() or weapon_in_use == null:
		return

	var index := weapons_unlocked.find(weapon_in_use)
	var previous_index := (index - 1) % weapons_unlocked.size()
	weapon_in_use = weapons_unlocked[previous_index]


func get_weapon_in_use() -> Weapon:
	return weapon_in_use


func get_weapons_unlocked() -> Array[Weapon]:
	return weapons_unlocked


func _unlock_weapons() -> void:
	weapons_unlocked.clear()
	weapon_in_use = null
	if anchor == null:
		return

	for child: Node in anchor.get_children():
		var weapon := child as Weapon
		if weapon == null:
			continue

		if weapon.get_is_weapon_unlocked():
			weapons_unlocked.append(weapon)
			if weapon_in_use == null:
				weapon_in_use = weapon
		else:
			weapon.set_physics_process(false)


func _process_weapon_in_use(delta: float) -> void:
	for weapon: Weapon in weapons_unlocked:
		var is_active := weapon == weapon_in_use
		weapon.set_physics_process(is_active)
		if is_active:
			weapon.tick_cooldown(delta)
