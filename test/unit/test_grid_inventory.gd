extends GutTest

const GridInventoryScript := preload("res://inventory/grid_inventory.gd")
const InventoryPlacementResultScript := preload("res://inventory/inventory_placement_result.gd")
const ItemConfigScript := preload("res://inventory/item_config.gd")

var _inventory: Node


func before_each() -> void:
	_inventory = add_child_autofree(GridInventoryScript.new())
	_inventory.columns = 4
	_inventory.rows = 3


func test_add_item_at_places_valid_footprint_within_bounds() -> void:
	var config := _make_config(&"handgun", 2, 1)

	var result = _inventory.add_item_at(config, Vector2i(1, 1))

	assert_true(result.success)
	assert_eq(result.reason, InventoryPlacementResultScript.Reason.OK)
	assert_eq(result.item.config, config)
	assert_eq(result.item.origin, Vector2i(1, 1))
	assert_eq(_inventory.get_occupied_cells(result.item.instance_id), [Vector2i(1, 1), Vector2i(2, 1)])


func test_add_item_at_rejects_out_of_bounds_footprint() -> void:
	var config := _make_config(&"shotgun", 3, 1)

	var result = _inventory.add_item_at(config, Vector2i(2, 0))

	assert_false(result.success)
	assert_eq(result.reason, InventoryPlacementResultScript.Reason.OUT_OF_BOUNDS)
	assert_true(_inventory.get_items().is_empty())


func test_add_item_at_rejects_overlapping_occupied_cells() -> void:
	var config := _make_config(&"ammo", 2, 1)
	_inventory.add_item_at(config, Vector2i(0, 0))

	var result = _inventory.add_item_at(config, Vector2i(1, 0))

	assert_false(result.success)
	assert_eq(result.reason, InventoryPlacementResultScript.Reason.OCCUPIED)
	assert_eq(_inventory.get_items().size(), 1)


func test_add_item_first_fit_chooses_earliest_available_top_left_cell() -> void:
	var one_cell := _make_config(&"herb", 1, 1)
	var two_cells := _make_config(&"ammo", 2, 1)
	_inventory.add_item_at(one_cell, Vector2i(0, 0))
	_inventory.add_item_at(one_cell, Vector2i(1, 0))

	var result = _inventory.add_item_first_fit(two_cells)

	assert_true(result.success)
	assert_eq(result.item.origin, Vector2i(2, 0))


func test_remove_item_frees_occupied_cells() -> void:
	var config := _make_config(&"herb", 1, 1)
	var added = _inventory.add_item_at(config, Vector2i(0, 0))

	var result = _inventory.remove_item(added.item.instance_id)

	assert_true(result.success)
	assert_false(_inventory.is_cell_occupied(Vector2i(0, 0)))
	assert_true(_inventory.can_place(config, Vector2i(0, 0)))


func test_move_item_updates_origin_and_occupied_cells() -> void:
	var config := _make_config(&"handgun", 2, 1)
	var added = _inventory.add_item_at(config, Vector2i(0, 0))

	var result = _inventory.move_item(added.item.instance_id, Vector2i(1, 1))

	assert_true(result.success)
	assert_eq(added.item.origin, Vector2i(1, 1))
	assert_false(_inventory.is_cell_occupied(Vector2i(0, 0)))
	assert_true(_inventory.is_cell_occupied(Vector2i(1, 1)))
	assert_true(_inventory.is_cell_occupied(Vector2i(2, 1)))


func test_move_item_rejects_invalid_target_without_mutating_state() -> void:
	var config := _make_config(&"ammo", 2, 1)
	var first = _inventory.add_item_at(config, Vector2i(0, 0))
	_inventory.add_item_at(config, Vector2i(2, 0))

	var occupied_result = _inventory.move_item(first.item.instance_id, Vector2i(1, 0))
	var bounds_result = _inventory.move_item(first.item.instance_id, Vector2i(3, 2))

	assert_false(occupied_result.success)
	assert_eq(occupied_result.reason, InventoryPlacementResultScript.Reason.OCCUPIED)
	assert_false(bounds_result.success)
	assert_eq(bounds_result.reason, InventoryPlacementResultScript.Reason.OUT_OF_BOUNDS)
	assert_eq(first.item.origin, Vector2i(0, 0))
	assert_true(_inventory.is_cell_occupied(Vector2i(0, 0)))
	assert_true(_inventory.is_cell_occupied(Vector2i(1, 0)))


func test_rotate_item_swaps_footprint_when_it_fits() -> void:
	var config := _make_config(&"shotgun", 3, 1, true)
	var added = _inventory.add_item_at(config, Vector2i(0, 0))

	var result = _inventory.rotate_item(added.item.instance_id)

	assert_true(result.success)
	assert_true(added.item.rotated)
	assert_eq(_inventory.get_occupied_cells(added.item.instance_id), [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2)])


func test_rotate_item_rejects_non_rotatable_item_without_mutating_state() -> void:
	var config := _make_config(&"key", 2, 1, false)
	var added = _inventory.add_item_at(config, Vector2i(0, 0))

	var result = _inventory.rotate_item(added.item.instance_id)

	assert_false(result.success)
	assert_eq(result.reason, InventoryPlacementResultScript.Reason.CANNOT_ROTATE)
	assert_false(added.item.rotated)
	assert_eq(_inventory.get_occupied_cells(added.item.instance_id), [Vector2i(0, 0), Vector2i(1, 0)])


func test_rotate_item_rejects_footprint_that_would_not_fit() -> void:
	var config := _make_config(&"shotgun", 3, 1, true)
	var added = _inventory.add_item_at(config, Vector2i(3, 0), true)

	var result = _inventory.rotate_item(added.item.instance_id)

	assert_false(result.success)
	assert_eq(result.reason, InventoryPlacementResultScript.Reason.OUT_OF_BOUNDS)
	assert_true(added.item.rotated)
	assert_eq(added.item.origin, Vector2i(3, 0))


func test_duplicate_configs_get_distinct_instance_ids() -> void:
	var config := _make_config(&"herb", 1, 1)

	var first = _inventory.add_item_at(config, Vector2i(0, 0))
	var second = _inventory.add_item_at(config, Vector2i(1, 0))

	assert_ne(first.item.instance_id, second.item.instance_id)
	assert_eq(_inventory.get_item(first.item.instance_id), first.item)
	assert_eq(_inventory.get_item(second.item.instance_id), second.item)


func test_inventory_changed_emits_only_after_successful_mutations() -> void:
	var config := _make_config(&"herb", 1, 1)
	watch_signals(_inventory)

	var added = _inventory.add_item_at(config, Vector2i(0, 0))
	_inventory.add_item_at(config, Vector2i(0, 0))
	_inventory.move_item(added.item.instance_id, Vector2i(1, 0))
	_inventory.move_item(added.item.instance_id, Vector2i(4, 0))
	_inventory.rotate_item(added.item.instance_id)
	_inventory.remove_item(added.item.instance_id)
	_inventory.remove_item(added.item.instance_id)

	assert_signal_emit_count(_inventory, "inventory_changed", 4)


func test_invalid_inventory_size_causes_placement_checks_to_fail() -> void:
	var config := _make_config(&"herb", 1, 1)
	_inventory.columns = 0

	var result = _inventory.add_item_at(config, Vector2i.ZERO)

	assert_false(result.success)
	assert_eq(result.reason, InventoryPlacementResultScript.Reason.OUT_OF_BOUNDS)
	assert_false(_inventory.can_place(config, Vector2i.ZERO))


func _make_config(item_key: StringName, width: int, height: int, can_rotate := true) -> Resource:
	var config := ItemConfigScript.new()
	config.item_key = item_key
	config.display_name = String(item_key).capitalize()
	config.width = width
	config.height = height
	config.can_rotate = can_rotate
	return config
