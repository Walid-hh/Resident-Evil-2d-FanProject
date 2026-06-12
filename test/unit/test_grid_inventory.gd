extends GutTest

const GridInventoryScript := preload("uid://bjt8wqgl14qn6")
const InventoryPlacementResultScript := preload("uid://iltn4hw7jlhj")
const ItemConfigScript := preload("uid://b2dfkpbc1vskx")

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


func test_add_item_at_assigns_stack_quantity() -> void:
	var config := _make_config(&"ammo", 2, 1)
	config.stackable = true
	config.max_stack_quantity = 20

	var result = _inventory.add_item_at(config, Vector2i(0, 0), false, 12)

	assert_true(result.success)
	assert_eq(result.item.quantity, 12)


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


func test_add_item_stack_merges_partial_stacks_before_creating_new_stack() -> void:
	var config := _make_config(&"shotgun_ammo", 2, 1)
	config.stackable = true
	config.max_stack_quantity = 20
	var partial = _inventory.add_item_at(config, Vector2i(0, 0), false, 18)

	var result = _inventory.add_item_stack(config, 5)

	assert_true(result.success)
	assert_eq(result.leftover_quantity, 0)
	assert_eq(partial.item.quantity, 20)
	assert_eq(_inventory.get_items().size(), 2)
	assert_eq(_inventory.get_total_quantity(&"shotgun_ammo"), 23)


func test_add_item_stack_reports_leftover_when_space_runs_out() -> void:
	var config := _make_config(&"shotgun_ammo", 2, 1)
	config.stackable = true
	config.max_stack_quantity = 20
	_inventory.columns = 2
	_inventory.rows = 1

	var result = _inventory.add_item_stack(config, 25)

	assert_true(result.success)
	assert_eq(result.leftover_quantity, 5)
	assert_eq(_inventory.get_total_quantity(&"shotgun_ammo"), 20)


func test_consume_item_quantity_spends_lowest_count_stack_first_and_removes_empty_stack() -> void:
	var config := _make_config(&"shotgun_ammo", 1, 1)
	config.stackable = true
	config.max_stack_quantity = 20
	var high = _inventory.add_item_at(config, Vector2i(0, 0), false, 10)
	var low = _inventory.add_item_at(config, Vector2i(1, 0), false, 3)

	var consumed := _inventory.consume_item_quantity(&"shotgun_ammo", 4)

	assert_true(consumed)
	assert_null(_inventory.get_item(low.item.instance_id))
	assert_eq(high.item.quantity, 9)
	assert_eq(_inventory.get_total_quantity(&"shotgun_ammo"), 9)


func test_consume_item_quantity_rejects_insufficient_quantity_without_mutating() -> void:
	var config := _make_config(&"shotgun_ammo", 1, 1)
	config.stackable = true
	config.max_stack_quantity = 20
	var stack = _inventory.add_item_at(config, Vector2i(0, 0), false, 2)

	var consumed := _inventory.consume_item_quantity(&"shotgun_ammo", 3)

	assert_false(consumed)
	assert_eq(stack.item.quantity, 2)
	assert_eq(_inventory.get_total_quantity(&"shotgun_ammo"), 2)


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


func test_move_item_can_update_rotation_atomically() -> void:
	var config := _make_config(&"shotgun", 3, 1)
	var added = _inventory.add_item_at(config, Vector2i(0, 0))

	var result = _inventory.move_item_with_rotation(added.item.instance_id, Vector2i(2, 0), true)

	assert_true(result.success)
	assert_eq(added.item.origin, Vector2i(2, 0))
	assert_true(added.item.rotated)
	assert_eq(_inventory.get_occupied_cells(added.item.instance_id), [Vector2i(2, 0), Vector2i(2, 1), Vector2i(2, 2)])


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


func test_get_item_at_cell_returns_item_for_any_occupied_footprint_cell() -> void:
	var config := _make_config(&"shotgun", 2, 2)
	var added = _inventory.add_item_at(config, Vector2i(1, 0))

	assert_eq(_inventory.get_item_at_cell(Vector2i(1, 0)), added.item)
	assert_eq(_inventory.get_item_at_cell(Vector2i(2, 0)), added.item)
	assert_eq(_inventory.get_item_at_cell(Vector2i(1, 1)), added.item)
	assert_eq(_inventory.get_item_at_cell(Vector2i(2, 1)), added.item)


func test_get_item_at_cell_returns_null_for_empty_and_out_of_bounds_cells() -> void:
	var config := _make_config(&"herb", 1, 1)
	_inventory.add_item_at(config, Vector2i(0, 0))

	assert_null(_inventory.get_item_at_cell(Vector2i(1, 0)))
	assert_null(_inventory.get_item_at_cell(Vector2i(-1, 0)))
	assert_null(_inventory.get_item_at_cell(Vector2i(4, 0)))


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


func test_inventory_changed_emits_for_stack_quantity_mutations() -> void:
	var config := _make_config(&"shotgun_ammo", 1, 1)
	config.stackable = true
	config.max_stack_quantity = 20
	watch_signals(_inventory)

	_inventory.add_item_stack(config, 5)
	_inventory.add_item_stack(config, 2)
	_inventory.consume_item_quantity(&"shotgun_ammo", 7)

	assert_signal_emit_count(_inventory, "inventory_changed", 3)


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
