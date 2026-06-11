extends GutTest

const GridInventoryScript: GDScript = preload("res://inventory/grid_inventory.gd")
const ItemConfigScript: GDScript = preload("res://inventory/item_config.gd")


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


func _make_item_config(item_key: StringName, size: Vector2i) -> ItemConfig:
	var config: ItemConfig = ItemConfigScript.new()
	config.item_key = item_key
	config.display_name = "Wide Item"
	config.width = size.x
	config.height = size.y
	return config
