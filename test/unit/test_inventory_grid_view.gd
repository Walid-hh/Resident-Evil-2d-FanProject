extends GutTest

const GridInventoryScript: GDScript = preload("uid://bjt8wqgl14qn6")
const ItemConfigScript: GDScript = preload("uid://b2dfkpbc1vskx")


func test_inventory_grid_view_renders_one_tile_per_inventory_item_with_footprint_size() -> void:
	var grid_inventory: GridInventory = add_child_autofree(GridInventoryScript.new())
	grid_inventory.columns = 4
	grid_inventory.rows = 2
	var config: ItemConfig = _make_item_config(&"wide_item", Vector2i(2, 1))
	grid_inventory.add_item_at(config, Vector2i(1, 0))

	var grid_view: InventoryGridView = add_child_autofree(InventoryGridView.new())
	grid_view.cell_size = Vector2(10, 10)
	grid_view.cell_gap = 2
	grid_view.grid_inventory = grid_inventory
	grid_view.refresh()

	var tiles: Array[Control] = grid_view.get_item_tiles()
	assert_eq(tiles.size(), 1)
	assert_eq(tiles[0].position, Vector2(12, 0))
	assert_eq(tiles[0].size, Vector2(22, 10))


func test_inventory_grid_view_renders_quantity_label_for_stack_quantity_above_one() -> void:
	var grid_inventory: GridInventory = add_child_autofree(GridInventoryScript.new())
	grid_inventory.columns = 4
	grid_inventory.rows = 2
	var config: ItemConfig = _make_item_config(&"shotgun_ammo", Vector2i(2, 1))
	config.stackable = true
	config.max_stack_quantity = 20
	grid_inventory.add_item_at(config, Vector2i(0, 0), false, 12)

	var grid_view := _make_grid_view(grid_inventory)
	var quantity_label := grid_view.get_item_tiles()[0].get_node("QuantityLabel") as Label

	assert_eq(quantity_label.text, "12")


func test_inventory_grid_view_starts_cursor_at_top_left_cell() -> void:
	var grid_view := _make_grid_view()

	assert_eq(grid_view.get_cursor_cell(), Vector2i.ZERO)


func test_inventory_grid_view_moves_cursor_one_cell_and_wraps_edges() -> void:
	var grid_view := _make_grid_view()

	grid_view.move_cursor(Vector2i.LEFT)
	assert_eq(grid_view.get_cursor_cell(), Vector2i(3, 0))

	grid_view.move_cursor(Vector2i.RIGHT)
	assert_eq(grid_view.get_cursor_cell(), Vector2i(0, 0))

	grid_view.move_cursor(Vector2i.UP)
	assert_eq(grid_view.get_cursor_cell(), Vector2i(0, 1))

	grid_view.move_cursor(Vector2i.DOWN)
	assert_eq(grid_view.get_cursor_cell(), Vector2i(0, 0))


func test_inventory_grid_view_draws_one_cell_cursor_on_empty_cell() -> void:
	var grid_view := _make_grid_view()
	var cursor := _get_cursor_node(grid_view)

	assert_eq(cursor.position, Vector2.ZERO)
	assert_eq(cursor.size, Vector2(10, 10))


func test_inventory_grid_view_selected_item_follows_cursor_occupancy() -> void:
	var grid_inventory: GridInventory = add_child_autofree(GridInventoryScript.new())
	grid_inventory.columns = 4
	grid_inventory.rows = 2
	var config: ItemConfig = _make_item_config(&"wide_item", Vector2i(2, 1))
	var added = grid_inventory.add_item_at(config, Vector2i(1, 0))
	var grid_view := _make_grid_view(grid_inventory)

	assert_null(grid_view.get_selected_item())

	grid_view.move_cursor(Vector2i.RIGHT)
	assert_eq(grid_view.get_selected_item(), added.item)

	grid_view.move_cursor(Vector2i.RIGHT)
	assert_null(grid_view.get_selected_item())


func test_inventory_grid_view_moving_right_from_horizontal_item_skips_past_footprint() -> void:
	var grid_inventory: GridInventory = add_child_autofree(GridInventoryScript.new())
	grid_inventory.columns = 4
	grid_inventory.rows = 2
	var config: ItemConfig = _make_item_config(&"wide_item", Vector2i(2, 1))
	grid_inventory.add_item_at(config, Vector2i(1, 0))
	var grid_view := _make_grid_view(grid_inventory)
	var cursor := _get_cursor_node(grid_view)

	grid_view.move_cursor(Vector2i.RIGHT)
	assert_eq(grid_view.get_cursor_cell(), Vector2i(1, 0))
	assert_eq(cursor.position, Vector2(12, 0))
	assert_eq(cursor.size, Vector2(22, 10))

	grid_view.move_cursor(Vector2i.RIGHT)
	assert_eq(grid_view.get_cursor_cell(), Vector2i(3, 0))
	assert_null(grid_view.get_selected_item())
	assert_eq(cursor.position, Vector2(36, 0))
	assert_eq(cursor.size, Vector2(10, 10))


func test_inventory_grid_view_moving_left_from_horizontal_item_skips_before_footprint() -> void:
	var grid_inventory: GridInventory = add_child_autofree(GridInventoryScript.new())
	grid_inventory.columns = 4
	grid_inventory.rows = 2
	var config: ItemConfig = _make_item_config(&"wide_item", Vector2i(2, 1))
	grid_inventory.add_item_at(config, Vector2i(1, 0))
	var grid_view := _make_grid_view(grid_inventory)
	var cursor := _get_cursor_node(grid_view)

	grid_view.move_cursor(Vector2i.LEFT)
	assert_eq(grid_view.get_cursor_cell(), Vector2i(3, 0))

	grid_view.move_cursor(Vector2i.LEFT)
	assert_eq(grid_view.get_cursor_cell(), Vector2i(2, 0))
	assert_eq(cursor.position, Vector2(12, 0))
	assert_eq(cursor.size, Vector2(22, 10))

	grid_view.move_cursor(Vector2i.LEFT)
	assert_eq(grid_view.get_cursor_cell(), Vector2i(0, 0))
	assert_null(grid_view.get_selected_item())
	assert_eq(cursor.position, Vector2.ZERO)
	assert_eq(cursor.size, Vector2(10, 10))


func test_inventory_grid_view_moving_down_from_vertical_item_skips_past_footprint() -> void:
	var grid_inventory: GridInventory = add_child_autofree(GridInventoryScript.new())
	grid_inventory.columns = 4
	grid_inventory.rows = 3
	var config: ItemConfig = _make_item_config(&"tall_item", Vector2i(1, 2))
	grid_inventory.add_item_at(config, Vector2i(0, 1))
	var grid_view := _make_grid_view(grid_inventory)
	var cursor := _get_cursor_node(grid_view)

	grid_view.move_cursor(Vector2i.DOWN)
	assert_eq(grid_view.get_cursor_cell(), Vector2i(0, 1))
	assert_eq(cursor.position, Vector2(0, 12))
	assert_eq(cursor.size, Vector2(10, 22))

	grid_view.move_cursor(Vector2i.DOWN)
	assert_eq(grid_view.get_cursor_cell(), Vector2i(0, 0))
	assert_null(grid_view.get_selected_item())
	assert_eq(cursor.position, Vector2.ZERO)
	assert_eq(cursor.size, Vector2(10, 10))


func test_inventory_grid_view_moving_up_from_vertical_item_skips_before_footprint() -> void:
	var grid_inventory: GridInventory = add_child_autofree(GridInventoryScript.new())
	grid_inventory.columns = 4
	grid_inventory.rows = 4
	var config: ItemConfig = _make_item_config(&"tall_item", Vector2i(1, 2))
	grid_inventory.add_item_at(config, Vector2i(0, 1))
	var grid_view := _make_grid_view(grid_inventory)
	var cursor := _get_cursor_node(grid_view)

	grid_view.move_cursor(Vector2i.DOWN)
	assert_eq(grid_view.get_cursor_cell(), Vector2i(0, 1))
	assert_eq(cursor.position, Vector2(0, 12))
	assert_eq(cursor.size, Vector2(10, 22))

	grid_view.move_cursor(Vector2i.UP)
	assert_eq(grid_view.get_cursor_cell(), Vector2i(0, 0))
	assert_null(grid_view.get_selected_item())
	assert_eq(cursor.position, Vector2.ZERO)
	assert_eq(cursor.size, Vector2(10, 10))


func test_inventory_grid_view_skipping_from_item_can_select_adjacent_item() -> void:
	var grid_inventory: GridInventory = add_child_autofree(GridInventoryScript.new())
	grid_inventory.columns = 5
	grid_inventory.rows = 2
	var wide_config: ItemConfig = _make_item_config(&"wide_item", Vector2i(2, 1))
	var adjacent_config: ItemConfig = _make_item_config(&"adjacent_item", Vector2i(1, 1))
	var wide = grid_inventory.add_item_at(wide_config, Vector2i(1, 0))
	var adjacent = grid_inventory.add_item_at(adjacent_config, Vector2i(3, 0))
	var grid_view := _make_grid_view(grid_inventory)
	var cursor := _get_cursor_node(grid_view)

	grid_view.move_cursor(Vector2i.RIGHT)
	assert_eq(grid_view.get_selected_item(), wide.item)

	grid_view.move_cursor(Vector2i.RIGHT)
	assert_eq(grid_view.get_cursor_cell(), Vector2i(3, 0))
	assert_eq(grid_view.get_selected_item(), adjacent.item)
	assert_eq(cursor.position, Vector2(36, 0))
	assert_eq(cursor.size, Vector2(10, 10))


func test_inventory_grid_view_skipping_past_item_edge_wraps_same_row_or_column() -> void:
	var grid_inventory: GridInventory = add_child_autofree(GridInventoryScript.new())
	grid_inventory.columns = 4
	grid_inventory.rows = 4
	var wide_config: ItemConfig = _make_item_config(&"wide_item", Vector2i(2, 1))
	var tall_config: ItemConfig = _make_item_config(&"tall_item", Vector2i(1, 2))
	grid_inventory.add_item_at(wide_config, Vector2i(2, 0))
	grid_inventory.add_item_at(tall_config, Vector2i(0, 2))
	var grid_view := _make_grid_view(grid_inventory)

	grid_view.move_cursor(Vector2i.LEFT)
	assert_eq(grid_view.get_cursor_cell(), Vector2i(3, 0))

	grid_view.move_cursor(Vector2i.RIGHT)
	assert_eq(grid_view.get_cursor_cell(), Vector2i(0, 0))

	grid_view.move_cursor(Vector2i.UP)
	assert_eq(grid_view.get_cursor_cell(), Vector2i(0, 3))

	grid_view.move_cursor(Vector2i.DOWN)
	assert_eq(grid_view.get_cursor_cell(), Vector2i(0, 0))


func test_inventory_grid_view_reset_cursor_returns_to_top_left_cell() -> void:
	var grid_view := _make_grid_view()

	grid_view.move_cursor(Vector2i.LEFT)
	assert_eq(grid_view.get_cursor_cell(), Vector2i(3, 0))

	grid_view.reset_cursor()
	assert_eq(grid_view.get_cursor_cell(), Vector2i.ZERO)


func test_inventory_grid_view_picks_item_without_mutating_committed_origin() -> void:
	var grid_inventory: GridInventory = add_child_autofree(GridInventoryScript.new())
	grid_inventory.columns = 4
	grid_inventory.rows = 2
	var config := _make_item_config(&"wide_item", Vector2i(2, 1))
	var added = grid_inventory.add_item_at(config, Vector2i(1, 0))
	var grid_view := _make_grid_view(grid_inventory)

	grid_view.move_cursor(Vector2i.RIGHT)
	grid_view.pick_or_place_held_item()

	assert_true(grid_view.is_holding_item())
	assert_eq(grid_view.get_held_item(), added.item)
	assert_eq(added.item.origin, Vector2i(1, 0))
	assert_eq(_get_held_preview(grid_view).position, Vector2(12, 0))


func test_inventory_grid_view_held_item_movement_clamps_at_edges() -> void:
	var grid_inventory: GridInventory = add_child_autofree(GridInventoryScript.new())
	grid_inventory.columns = 4
	grid_inventory.rows = 2
	var config := _make_item_config(&"wide_item", Vector2i(2, 1))
	grid_inventory.add_item_at(config, Vector2i(1, 0))
	var grid_view := _make_grid_view(grid_inventory)

	grid_view.move_cursor(Vector2i.RIGHT)
	grid_view.pick_or_place_held_item()
	grid_view.move_cursor(Vector2i.RIGHT)
	grid_view.move_cursor(Vector2i.RIGHT)

	assert_eq(grid_view.get_cursor_cell(), Vector2i(2, 0))
	assert_eq(_get_held_preview(grid_view).position, Vector2(24, 0))


func test_inventory_grid_view_places_held_item_at_valid_target() -> void:
	var grid_inventory: GridInventory = add_child_autofree(GridInventoryScript.new())
	grid_inventory.columns = 4
	grid_inventory.rows = 2
	var config := _make_item_config(&"wide_item", Vector2i(2, 1))
	var added = grid_inventory.add_item_at(config, Vector2i(0, 0))
	var grid_view := _make_grid_view(grid_inventory)

	grid_view.pick_or_place_held_item()
	grid_view.move_cursor(Vector2i.RIGHT)
	grid_view.pick_or_place_held_item()

	assert_false(grid_view.is_holding_item())
	assert_eq(added.item.origin, Vector2i(1, 0))


func test_inventory_grid_view_invalid_held_placement_stays_held_without_mutating() -> void:
	var grid_inventory: GridInventory = add_child_autofree(GridInventoryScript.new())
	grid_inventory.columns = 4
	grid_inventory.rows = 2
	var wide_config := _make_item_config(&"wide_item", Vector2i(2, 1))
	var blocker_config := _make_item_config(&"blocker", Vector2i(1, 1))
	var added = grid_inventory.add_item_at(wide_config, Vector2i(0, 0))
	grid_inventory.add_item_at(blocker_config, Vector2i(2, 0))
	var grid_view := _make_grid_view(grid_inventory)

	grid_view.pick_or_place_held_item()
	grid_view.move_cursor(Vector2i.RIGHT)
	grid_view.pick_or_place_held_item()

	assert_true(grid_view.is_holding_item())
	assert_eq(added.item.origin, Vector2i(0, 0))
	assert_eq(_get_preview_background(grid_view).color, grid_view.held_item_invalid_color)


func test_inventory_grid_view_merges_matching_held_stack_into_target_stack() -> void:
	var grid_inventory: GridInventory = add_child_autofree(GridInventoryScript.new())
	grid_inventory.columns = 4
	grid_inventory.rows = 2
	var config := _make_item_config(&"shotgun_ammo", Vector2i(1, 1))
	config.stackable = true
	config.max_stack_quantity = 20
	var source = grid_inventory.add_item_at(config, Vector2i(0, 0), false, 5)
	var target = grid_inventory.add_item_at(config, Vector2i(1, 0), false, 10)
	var grid_view := _make_grid_view(grid_inventory)

	grid_view.pick_or_place_held_item()
	grid_view.move_cursor(Vector2i.RIGHT)
	grid_view.pick_or_place_held_item()

	assert_false(grid_view.is_holding_item())
	assert_null(grid_inventory.get_item(source.item.instance_id))
	assert_eq(target.item.quantity, 15)


func test_inventory_grid_view_keeps_leftover_stack_held_after_partial_merge() -> void:
	var grid_inventory: GridInventory = add_child_autofree(GridInventoryScript.new())
	grid_inventory.columns = 4
	grid_inventory.rows = 2
	var config := _make_item_config(&"shotgun_ammo", Vector2i(1, 1))
	config.stackable = true
	config.max_stack_quantity = 20
	var source = grid_inventory.add_item_at(config, Vector2i(0, 0), false, 8)
	var target = grid_inventory.add_item_at(config, Vector2i(1, 0), false, 15)
	var grid_view := _make_grid_view(grid_inventory)

	grid_view.pick_or_place_held_item()
	grid_view.move_cursor(Vector2i.RIGHT)
	grid_view.pick_or_place_held_item()

	assert_true(grid_view.is_holding_item())
	assert_eq(source.item.quantity, 3)
	assert_eq(target.item.quantity, 20)


func test_inventory_grid_view_rejects_merge_for_different_item_key() -> void:
	var grid_inventory: GridInventory = add_child_autofree(GridInventoryScript.new())
	grid_inventory.columns = 4
	grid_inventory.rows = 2
	var ammo_config := _make_item_config(&"shotgun_ammo", Vector2i(1, 1))
	ammo_config.stackable = true
	ammo_config.max_stack_quantity = 20
	var herb_config := _make_item_config(&"green_herb", Vector2i(1, 1))
	herb_config.stackable = true
	herb_config.max_stack_quantity = 20
	var source = grid_inventory.add_item_at(ammo_config, Vector2i(0, 0), false, 5)
	var target = grid_inventory.add_item_at(herb_config, Vector2i(1, 0), false, 10)
	var grid_view := _make_grid_view(grid_inventory)

	grid_view.pick_or_place_held_item()
	grid_view.move_cursor(Vector2i.RIGHT)
	grid_view.pick_or_place_held_item()

	assert_true(grid_view.is_holding_item())
	assert_eq(source.item.quantity, 5)
	assert_eq(target.item.quantity, 10)


func test_inventory_grid_view_held_rotation_commits_on_valid_place() -> void:
	var grid_inventory: GridInventory = add_child_autofree(GridInventoryScript.new())
	grid_inventory.columns = 4
	grid_inventory.rows = 2
	var config := _make_item_config(&"wide_item", Vector2i(2, 1))
	var added = grid_inventory.add_item_at(config, Vector2i(0, 0))
	var grid_view := _make_grid_view(grid_inventory)

	grid_view.pick_or_place_held_item()
	grid_view.rotate_held_item()
	grid_view.pick_or_place_held_item()

	assert_false(grid_view.is_holding_item())
	assert_true(added.item.rotated)
	assert_eq(grid_inventory.get_occupied_cells(added.item.instance_id), [Vector2i(0, 0), Vector2i(0, 1)])


func test_inventory_grid_view_held_rotation_ignores_non_rotatable_items() -> void:
	var grid_inventory: GridInventory = add_child_autofree(GridInventoryScript.new())
	grid_inventory.columns = 4
	grid_inventory.rows = 2
	var config := _make_item_config(&"key_item", Vector2i(2, 1), false)
	var added = grid_inventory.add_item_at(config, Vector2i(0, 0))
	var grid_view := _make_grid_view(grid_inventory)

	grid_view.pick_or_place_held_item()
	grid_view.rotate_held_item()
	grid_view.pick_or_place_held_item()

	assert_false(added.item.rotated)
	assert_eq(grid_inventory.get_occupied_cells(added.item.instance_id), [Vector2i(0, 0), Vector2i(1, 0)])


func test_inventory_grid_view_held_rotation_ignores_out_of_bounds_rotation() -> void:
	var grid_inventory: GridInventory = add_child_autofree(GridInventoryScript.new())
	grid_inventory.columns = 4
	grid_inventory.rows = 2
	var config := _make_item_config(&"tall_item", Vector2i(1, 2))
	var added = grid_inventory.add_item_at(config, Vector2i(3, 0))
	var grid_view := _make_grid_view(grid_inventory)

	grid_view.move_cursor(Vector2i.LEFT)
	grid_view.pick_or_place_held_item()
	grid_view.rotate_held_item()
	grid_view.pick_or_place_held_item()

	assert_false(added.item.rotated)
	assert_eq(grid_inventory.get_occupied_cells(added.item.instance_id), [Vector2i(3, 0), Vector2i(3, 1)])


func test_inventory_grid_view_cancel_held_item_preserves_committed_state() -> void:
	var grid_inventory: GridInventory = add_child_autofree(GridInventoryScript.new())
	grid_inventory.columns = 4
	grid_inventory.rows = 2
	var config := _make_item_config(&"wide_item", Vector2i(2, 1))
	var added = grid_inventory.add_item_at(config, Vector2i(0, 0))
	var grid_view := _make_grid_view(grid_inventory)

	grid_view.pick_or_place_held_item()
	grid_view.move_cursor(Vector2i.RIGHT)
	grid_view.cancel_held_item()

	assert_false(grid_view.is_holding_item())
	assert_eq(added.item.origin, Vector2i(0, 0))


func _make_grid_view(grid_inventory: GridInventory = null) -> InventoryGridView:
	if grid_inventory == null:
		grid_inventory = add_child_autofree(GridInventoryScript.new())
		grid_inventory.columns = 4
		grid_inventory.rows = 2

	var grid_view: InventoryGridView = add_child_autofree(InventoryGridView.new())
	grid_view.cell_size = Vector2(10, 10)
	grid_view.cell_gap = 2
	grid_view.grid_inventory = grid_inventory
	grid_view.refresh()
	return grid_view


func _get_cursor_node(grid_view: InventoryGridView) -> Panel:
	return grid_view.get_node("InventoryCursor") as Panel


func _get_held_preview(grid_view: InventoryGridView) -> Control:
	return grid_view.get_node("HeldItemPreview") as Control


func _get_preview_background(grid_view: InventoryGridView) -> ColorRect:
	return _get_held_preview(grid_view).get_node("Background") as ColorRect


func _make_item_config(item_key: StringName, size: Vector2i, can_rotate := true) -> ItemConfig:
	var config: ItemConfig = ItemConfigScript.new()
	config.item_key = item_key
	config.display_name = "Wide Item"
	config.width = size.x
	config.height = size.y
	config.can_rotate = can_rotate
	return config
