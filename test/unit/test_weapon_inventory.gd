extends GutTest

const InventoryItemDefinitionScript := preload("res://inventory/inventory_item_definition.gd")
const InventorySlotDefinitionScript := preload("res://inventory/inventory_slot_definition.gd")

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
var _player_inventory: PlayerInventory


func before_each() -> void:
	_anchor = add_child_autofree(Marker2D.new())
	_weapon = add_child_autofree(TestWeapon.new())
	_player_inventory = PlayerInventory.new()
	_player_inventory.slot_definitions = [_make_slot(_make_item_definition(&"shotgun_ammo", 20), 10)]
	add_child_autofree(_player_inventory)
	_inventory = add_child_autofree(WeaponInventory.new())
	_inventory.anchor = _anchor
	_inventory.weapon = _weapon
	_inventory.player_inventory = _player_inventory


func test_initialize_selects_first_unlocked_config() -> void:
	var first := _make_config(&"handgun", true)
	var second := _make_config(&"shotgun", true)
	_inventory.weapon_configs = [first, second]

	_inventory.initialize()

	assert_eq(_inventory.get_unlocked_weapon_configs(), [first, second])
	assert_eq(_inventory.get_active_weapon_config(), first)
	assert_eq(_inventory.get_weapon_in_use(), _weapon)
	assert_eq(_weapon.get_weapon_config(), first)


func test_initialize_emits_weapon_state_signals() -> void:
	var first := _make_config(&"handgun", true)
	var second := _make_config(&"shotgun", true)
	watch_signals(_inventory)
	_inventory.weapon_configs = [first, second]

	_inventory.initialize()

	assert_signal_emit_count(_inventory, "unlocked_weapon_configs_changed", 1)
	assert_signal_emitted_with_parameters(_inventory, "unlocked_weapon_configs_changed", [[first, second]])
	assert_signal_emit_count(_inventory, "active_weapon_config_changed", 1)
	assert_signal_emitted_with_parameters(_inventory, "active_weapon_config_changed", [first])


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


func test_cycle_emits_active_weapon_config_changed() -> void:
	var first := _make_config(&"handgun", true)
	var second := _make_config(&"shotgun", true)
	watch_signals(_inventory)
	_inventory.weapon_configs = [first, second]
	_inventory.initialize()

	_inventory.cycle_next_unlocked_weapon()

	assert_signal_emit_count(_inventory, "active_weapon_config_changed", 2)
	assert_signal_emitted_with_parameters(_inventory, "active_weapon_config_changed", [second])


func test_physics_update_fires_only_active_config() -> void:
	var first := _make_config(&"handgun", true)
	var second := _make_config(&"shotgun", true)
	_inventory.weapon_configs = [first, second]
	_inventory.initialize()

	var shot_fired := _inventory.physics_update(0.1, true, Vector2.RIGHT, 1.0)

	assert_true(shot_fired)
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


func test_cycle_skips_ammo_backed_weapon_without_ammo() -> void:
	var handgun := _make_config(&"handgun", true)
	var shotgun := _make_config(&"shotgun", true)
	shotgun.ammo_item_key = &"shotgun_ammo"
	_inventory.weapon_configs = [handgun, shotgun]
	_inventory.initialize()
	_empty_shotgun_ammo()

	_inventory.cycle_next_unlocked_weapon()

	assert_eq(_inventory.get_unlocked_weapon_configs(), [handgun, shotgun])
	assert_eq(_inventory.get_active_weapon_config(), handgun)
	assert_eq(_weapon.get_weapon_config(), handgun)


func test_cycle_can_select_ammo_backed_weapon_after_ammo_is_added() -> void:
	var handgun := _make_config(&"handgun", true)
	var shotgun := _make_config(&"shotgun", true)
	shotgun.ammo_item_key = &"shotgun_ammo"
	_inventory.weapon_configs = [handgun, shotgun]
	_inventory.initialize()
	_empty_shotgun_ammo()
	_player_inventory.add_item_quantity(_player_inventory.get_item_definition(&"shotgun_ammo"), 1)

	_inventory.cycle_next_unlocked_weapon()

	assert_eq(_inventory.get_active_weapon_config(), shotgun)
	assert_eq(_weapon.get_weapon_config(), shotgun)


func test_final_ammo_backed_shot_force_selects_handgun() -> void:
	var handgun := _make_config(&"handgun", true)
	var shotgun := _make_config(&"shotgun", true)
	shotgun.ammo_item_key = &"shotgun_ammo"
	_inventory.weapon_configs = [handgun, shotgun]
	_inventory.initialize()
	_player_inventory.consume_item_quantity(&"shotgun_ammo", 9)
	_inventory.cycle_next_unlocked_weapon()

	var shot_fired := _inventory.physics_update(0.0, true, Vector2.RIGHT, 1.0)

	assert_true(shot_fired)
	assert_eq(_weapon.fired_directions.size(), 1)
	assert_eq(_player_inventory.get_item_quantity(&"shotgun_ammo"), 0)
	assert_eq(_inventory.get_last_fired_weapon_config(), shotgun)
	assert_eq(_inventory.get_active_weapon_config(), handgun)
	assert_eq(_weapon.get_weapon_config(), handgun)


func test_forced_handgun_fallback_emits_active_weapon_config_changed() -> void:
	var handgun := _make_config(&"handgun", true)
	var shotgun := _make_config(&"shotgun", true)
	shotgun.ammo_item_key = &"shotgun_ammo"
	_inventory.weapon_configs = [handgun, shotgun]
	_inventory.initialize()
	_player_inventory.consume_item_quantity(&"shotgun_ammo", 9)
	_inventory.cycle_next_unlocked_weapon()
	watch_signals(_inventory)

	_inventory.physics_update(0.0, true, Vector2.RIGHT, 1.0)

	assert_signal_emit_count(_inventory, "active_weapon_config_changed", 1)
	assert_signal_emitted_with_parameters(_inventory, "active_weapon_config_changed", [handgun])


func test_missing_handgun_fallback_keeps_current_weapon() -> void:
	var shotgun := _make_config(&"shotgun", true)
	shotgun.ammo_item_key = &"shotgun_ammo"
	_inventory.weapon_configs = [shotgun]
	_inventory.initialize()
	_player_inventory.consume_item_quantity(&"shotgun_ammo", 9)

	var shot_fired := _inventory.physics_update(0.0, true, Vector2.RIGHT, 1.0)

	assert_true(shot_fired)
	assert_eq(_player_inventory.get_item_quantity(&"shotgun_ammo"), 0)
	assert_eq(_inventory.get_last_fired_weapon_config(), shotgun)
	assert_eq(_inventory.get_active_weapon_config(), shotgun)
	assert_eq(_weapon.get_weapon_config(), shotgun)


func test_ammo_backed_weapon_consumes_ammo_when_firing() -> void:
	var shotgun := _make_config(&"shotgun", true)
	shotgun.ammo_item_key = &"shotgun_ammo"
	_inventory.weapon_configs = [shotgun]
	_inventory.initialize()

	var shot_fired := _inventory.physics_update(0.0, true, Vector2.RIGHT, 1.0)

	assert_true(shot_fired)
	assert_eq(_weapon.fired_directions.size(), 1)
	assert_eq(_player_inventory.get_item_quantity(&"shotgun_ammo"), 9)


func test_ammo_backed_weapon_does_not_fire_without_ammo() -> void:
	var shotgun := _make_config(&"shotgun", true)
	shotgun.ammo_item_key = &"missing_ammo"
	_inventory.weapon_configs = [shotgun]
	_inventory.initialize()

	var shot_fired := _inventory.physics_update(0.0, true, Vector2.RIGHT, 1.0)

	assert_false(shot_fired)
	assert_true(_weapon.fired_directions.is_empty())
	assert_push_error("Unknown inventory item key")


func test_cooldown_blocked_fire_does_not_consume_ammo_or_report_shot() -> void:
	var shotgun := _make_config(&"shotgun", true, 1.0)
	shotgun.ammo_item_key = &"shotgun_ammo"
	_inventory.weapon_configs = [shotgun]
	_inventory.initialize()

	assert_true(_inventory.physics_update(0.0, true, Vector2.RIGHT, 1.0))
	var ammo_after_first_shot := _player_inventory.get_item_quantity(&"shotgun_ammo")
	var shot_fired := _inventory.physics_update(0.5, true, Vector2.RIGHT, 1.0)

	assert_false(shot_fired)
	assert_eq(_weapon.fired_directions.size(), 1)
	assert_eq(_player_inventory.get_item_quantity(&"shotgun_ammo"), ammo_after_first_shot)


func _make_config(weapon_key: StringName, unlocked: bool, fire_rate: float = 0.0) -> WeaponConfig:
	var config := WeaponConfig.new()
	config.weapon_key = weapon_key
	config.projectile_scene = PackedScene.new()
	config.fire_rate = fire_rate
	config.unlocked_by_default = unlocked
	return config


func _make_slot(
	item_definition: Resource,
	starting_quantity: int
) -> Resource:
	var slot_definition := InventorySlotDefinitionScript.new()
	slot_definition.item_definition = item_definition
	slot_definition.starting_quantity = starting_quantity
	return slot_definition


func _make_item_definition(item_key: StringName, max_quantity: int) -> Resource:
	var item_definition := InventoryItemDefinitionScript.new()
	item_definition.item_key = item_key
	item_definition.max_quantity = max_quantity
	return item_definition


func _empty_shotgun_ammo() -> void:
	_player_inventory.consume_item_quantity(&"shotgun_ammo", _player_inventory.get_item_quantity(&"shotgun_ammo"))
