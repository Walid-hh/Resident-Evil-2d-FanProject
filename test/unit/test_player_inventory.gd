extends GutTest


func test_player_inventory_creates_and_seeds_default_grid_inventory() -> void:
	var player_inventory: PlayerInventory = add_child_autofree(PlayerInventory.new())

	var grid_inventory: GridInventory = player_inventory.get_grid_inventory()

	assert_eq(grid_inventory.columns, 8)
	assert_eq(grid_inventory.rows, 4)
	assert_eq(grid_inventory.get_items().size(), 3)
	assert_has_seeded_item(grid_inventory, &"green_herb", Vector2i(0, 0), Vector2i(1, 2))
	assert_has_seeded_item(grid_inventory, &"shotgun_ammo", Vector2i(2, 0), Vector2i(2, 1), 10)
	assert_has_seeded_item(grid_inventory, &"first_aid_spray", Vector2i(5, 1), Vector2i(1, 2))
	assert_eq(player_inventory.get_item_quantity(&"shotgun_ammo"), 10)


func test_player_inventory_consumes_and_adds_item_quantities() -> void:
	var player_inventory: PlayerInventory = add_child_autofree(PlayerInventory.new())
	var ammo_config := load("res://inventory/items/shotgun_ammo.tres") as ItemConfig

	assert_true(player_inventory.consume_item_quantity(&"shotgun_ammo", 3))
	assert_eq(player_inventory.get_item_quantity(&"shotgun_ammo"), 7)

	var result = player_inventory.add_item_quantity(ammo_config, 5)

	assert_true(result.success)
	assert_eq(result.leftover_quantity, 0)
	assert_eq(player_inventory.get_item_quantity(&"shotgun_ammo"), 12)


func assert_has_seeded_item(
	grid_inventory: GridInventory,
	item_key: StringName,
	origin: Vector2i,
	size: Vector2i,
	quantity := 1
) -> void:
	for item: InventoryItem in grid_inventory.get_items():
		if item.config.item_key == item_key:
			assert_eq(item.origin, origin)
			assert_eq(item.get_size(), size)
			assert_eq(item.quantity, quantity)
			return

	fail_test("Expected seeded item %s." % item_key)
