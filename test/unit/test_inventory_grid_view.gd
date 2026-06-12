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
	assert_eq(grid_view.get_selected_item(), added.item)

	grid_view.move_cursor(Vector2i.RIGHT)
	assert_null(grid_view.get_selected_item())


func test_inventory_grid_view_reset_cursor_returns_to_top_left_cell() -> void:
	var grid_view := _make_grid_view()

	grid_view.move_cursor(Vector2i.LEFT)
	assert_eq(grid_view.get_cursor_cell(), Vector2i(3, 0))

	grid_view.reset_cursor()
	assert_eq(grid_view.get_cursor_cell(), Vector2i.ZERO)


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


func _make_item_config(item_key: StringName, size: Vector2i) -> ItemConfig:
	var config: ItemConfig = ItemConfigScript.new()
	config.item_key = item_key
	config.display_name = "Wide Item"
	config.width = size.x
	config.height = size.y
	return config
