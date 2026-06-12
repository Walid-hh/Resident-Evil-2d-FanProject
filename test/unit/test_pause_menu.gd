extends GutTest

const GridInventoryScript: GDScript = preload("uid://bjt8wqgl14qn6")
const ItemConfigScript: GDScript = preload("uid://b2dfkpbc1vskx")


func after_each() -> void:
	get_tree().paused = false


func test_pause_menu_starts_hidden_and_toggles_tree_pause() -> void:
	var pause_menu: PauseMenu = add_child_autofree(PauseMenu.new())

	assert_false(pause_menu.visible)

	pause_menu.toggle_open()

	assert_true(pause_menu.visible)
	assert_true(get_tree().paused)

	pause_menu.toggle_open()

	assert_false(pause_menu.visible)
	assert_false(get_tree().paused)


func test_pause_menu_resets_inventory_cursor_when_opened() -> void:
	var pause_menu: PauseMenu = add_child_autofree(PauseMenu.new())
	var grid_view := _make_grid_view()
	pause_menu.inventory_grid_view = grid_view
	grid_view.move_cursor(Vector2i.LEFT)

	pause_menu.set_open(true)

	assert_eq(grid_view.get_cursor_cell(), Vector2i.ZERO)


func test_pause_menu_moves_inventory_cursor_only_while_visible() -> void:
	var pause_menu: PauseMenu = add_child_autofree(PauseMenu.new())
	var grid_view := _make_grid_view()
	pause_menu.inventory_grid_view = grid_view

	pause_menu._unhandled_input(_make_action_event("right"))
	assert_eq(grid_view.get_cursor_cell(), Vector2i.ZERO)

	pause_menu.set_open(true)
	pause_menu._unhandled_input(_make_action_event("right"))

	assert_eq(grid_view.get_cursor_cell(), Vector2i(1, 0))


func test_pause_menu_pick_place_and_rotate_inputs_only_apply_while_visible() -> void:
	var pause_menu: PauseMenu = add_child_autofree(PauseMenu.new())
	var grid_view := _make_grid_view()
	grid_view.grid_inventory.add_item_at(_make_item_config(&"wide_item", Vector2i(2, 1)), Vector2i(0, 0))
	pause_menu.inventory_grid_view = grid_view

	pause_menu._unhandled_input(_make_action_event("inventory_pick_place"))
	assert_false(grid_view.is_holding_item())

	pause_menu.set_open(true)
	pause_menu._unhandled_input(_make_action_event("inventory_pick_place"))
	pause_menu._unhandled_input(_make_action_event("inventory_rotate_item"))
	pause_menu._unhandled_input(_make_action_event("inventory_pick_place"))

	var item := grid_view.grid_inventory.get_item_at_cell(Vector2i(0, 0)) as InventoryItem
	assert_not_null(item)
	assert_true(item.rotated)


func test_pause_menu_closing_cancels_held_item() -> void:
	var pause_menu: PauseMenu = add_child_autofree(PauseMenu.new())
	var grid_view := _make_grid_view()
	var added = grid_view.grid_inventory.add_item_at(_make_item_config(&"wide_item", Vector2i(2, 1)), Vector2i(0, 0))
	pause_menu.inventory_grid_view = grid_view

	pause_menu.set_open(true)
	pause_menu._unhandled_input(_make_action_event("inventory_pick_place"))
	pause_menu._unhandled_input(_make_action_event("right"))
	pause_menu.set_open(false)

	assert_false(grid_view.is_holding_item())
	assert_eq(added.item.origin, Vector2i(0, 0))


func _make_grid_view() -> InventoryGridView:
	var grid_inventory: GridInventory = add_child_autofree(GridInventoryScript.new())
	grid_inventory.columns = 2
	grid_inventory.rows = 2

	var grid_view: InventoryGridView = add_child_autofree(InventoryGridView.new())
	grid_view.grid_inventory = grid_inventory
	grid_view.refresh()
	return grid_view


func _make_action_event(action: StringName) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	return event


func _make_item_config(item_key: StringName, size: Vector2i) -> ItemConfig:
	var config: ItemConfig = ItemConfigScript.new()
	config.item_key = item_key
	config.display_name = "Wide Item"
	config.width = size.x
	config.height = size.y
	return config
