extends GutTest

class TestWeapon:
	extends Weapon

	var fired_directions: Array[Vector2] = []

	func _ready() -> void:
		pass

	func fire(direction: Vector2) -> void:
		fired_directions.append(direction)


var _anchor: Marker2D
var _weapon: TestWeapon
var _inventory: WeaponInventory


func before_each() -> void:
	_anchor = add_child_autofree(Marker2D.new())
	_weapon = add_child_autofree(TestWeapon.new())
	_inventory = add_child_autofree(WeaponInventory.new())
	_inventory.anchor = _anchor
	_inventory.weapon = _weapon


func test_initialize_selects_first_unlocked_config() -> void:
	var first := _make_config(&"handgun", true)
	var second := _make_config(&"shotgun", true)
	_inventory.weapon_configs = [first, second]

	_inventory.initialize()

	assert_eq(_inventory.get_unlocked_weapon_configs(), [first, second])
	assert_eq(_inventory.get_active_weapon_config(), first)
	assert_eq(_inventory.get_weapon_in_use(), _weapon)
	assert_eq(_weapon.get_weapon_config(), first)


func test_initialize_ignores_locked_configs() -> void:
	var locked := _make_config(&"locked", false)
	var unlocked := _make_config(&"handgun", true)
	_inventory.weapon_configs = [locked, unlocked]

	_inventory.initialize()

	assert_eq(_inventory.get_unlocked_weapon_configs(), [unlocked])
	assert_eq(_inventory.get_active_weapon_config(), unlocked)
	assert_eq(_weapon.get_weapon_config(), unlocked)


func test_cycle_next_and_previous_wraps_active_config() -> void:
	var first := _make_config(&"handgun", true)
	var second := _make_config(&"shotgun", true)
	_inventory.weapon_configs = [first, second]
	_inventory.initialize()

	_inventory.cycle_next_unlocked_weapon()
	assert_eq(_inventory.get_active_weapon_config(), second)
	assert_eq(_weapon.get_weapon_config(), second)

	_inventory.cycle_next_unlocked_weapon()
	assert_eq(_inventory.get_active_weapon_config(), first)

	_inventory.cycle_previous_unlocked_weapon()
	assert_eq(_inventory.get_active_weapon_config(), second)


func test_physics_update_fires_only_active_config() -> void:
	var first := _make_config(&"handgun", true)
	var second := _make_config(&"shotgun", true)
	_inventory.weapon_configs = [first, second]
	_inventory.initialize()

	_inventory.physics_update(0.1, true, Vector2.RIGHT, 1.0)

	assert_eq(_weapon.get_weapon_config(), first)
	assert_eq(_weapon.fired_directions, [Vector2.RIGHT])
	assert_eq(_inventory.get_active_weapon_config(), first)


func test_cooldown_is_preserved_per_weapon_key_when_cycling() -> void:
	var handgun := _make_config(&"handgun", true, 1.0)
	var shotgun := _make_config(&"shotgun", true, 1.0)
	_inventory.weapon_configs = [handgun, shotgun]
	_inventory.initialize()

	_inventory.physics_update(0.0, true, Vector2.RIGHT, 1.0)
	_inventory.cycle_next_unlocked_weapon()
	_inventory.physics_update(0.0, true, Vector2.RIGHT, 1.0)
	_inventory.cycle_previous_unlocked_weapon()
	_inventory.physics_update(0.5, true, Vector2.RIGHT, 1.0)

	assert_eq(_weapon.fired_directions.size(), 2, "Handgun should not fire again before its own cooldown completes.")

	_inventory.physics_update(0.5, true, Vector2.RIGHT, 1.0)

	assert_eq(_weapon.fired_directions.size(), 3, "Handgun should fire after its preserved cooldown completes.")


func _make_config(weapon_key: StringName, unlocked: bool, fire_rate: float = 0.0) -> WeaponConfig:
	var config := WeaponConfig.new()
	config.weapon_key = weapon_key
	config.projectile_scene = PackedScene.new()
	config.fire_rate = fire_rate
	config.unlocked_by_default = unlocked
	return config
