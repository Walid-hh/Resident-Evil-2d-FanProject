extends GutTest

class TestWeapon:
	extends Weapon

	var unlocked := true
	var tick_count := 0
	var fired_directions: Array[Vector2] = []

	func get_is_weapon_unlocked() -> bool:
		return unlocked

	func tick_cooldown(_delta: float) -> void:
		tick_count += 1

	func can_fire() -> bool:
		return true

	func fire(direction: Vector2) -> void:
		fired_directions.append(direction)

	func get_weapon_key() -> StringName:
		return &"test_weapon"


var _anchor: Marker2D
var _inventory: WeaponInventory


func before_each() -> void:
	_anchor = add_child_autofree(Marker2D.new())
	_inventory = add_child_autofree(WeaponInventory.new())
	_inventory.anchor = _anchor


func test_initialize_selects_first_unlocked_weapon() -> void:
	var first := _add_weapon(true)
	var second := _add_weapon(true)

	_inventory.initialize()

	assert_eq(_inventory.get_weapons_unlocked(), [first, second])
	assert_eq(_inventory.get_weapon_in_use(), first)


func test_initialize_ignores_locked_weapons() -> void:
	var locked := _add_weapon(false)
	var unlocked := _add_weapon(true)

	_inventory.initialize()

	assert_eq(_inventory.get_weapons_unlocked(), [unlocked])
	assert_eq(_inventory.get_weapon_in_use(), unlocked)
	assert_false(locked.is_physics_processing(), "Locked weapons should have physics processing disabled.")


func test_cycle_next_and_previous_wraps_active_weapon() -> void:
	var first := _add_weapon(true)
	var second := _add_weapon(true)
	_inventory.initialize()

	_inventory.cycle_next_unlocked_weapon()
	assert_eq(_inventory.get_weapon_in_use(), second)

	_inventory.cycle_next_unlocked_weapon()
	assert_eq(_inventory.get_weapon_in_use(), first)

	_inventory.cycle_previous_unlocked_weapon()
	assert_eq(_inventory.get_weapon_in_use(), second)


func test_zero_aim_uses_fallback_fire_direction() -> void:
	var result := _inventory.get_fire_direction(Vector2.ZERO, -1.0)

	assert_eq(result, Vector2.LEFT)


func test_physics_update_ticks_and_fires_only_active_weapon() -> void:
	var first := _add_weapon(true)
	var second := _add_weapon(true)
	_inventory.initialize()

	_inventory.physics_update(0.1, true, Vector2.RIGHT, 1.0)

	assert_eq(first.tick_count, 1)
	assert_eq(second.tick_count, 0)
	assert_eq(first.fired_directions, [Vector2.RIGHT])
	assert_eq(second.fired_directions, [])


func _add_weapon(unlocked: bool) -> TestWeapon:
	var weapon := TestWeapon.new()
	weapon.unlocked = unlocked
	_anchor.add_child(weapon)
	return weapon
