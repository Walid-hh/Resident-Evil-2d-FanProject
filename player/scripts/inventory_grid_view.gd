class_name InventoryGridView extends Control

@export var grid_inventory: GridInventory:
	set(value):
		_disconnect_inventory_changed()
		grid_inventory = value
		_connect_inventory_changed()
		refresh()

@export var cell_size: Vector2 = Vector2(18, 18)
@export var cell_gap: int = 1
@export var cell_color: Color = Color(0.12, 0.13, 0.13, 1.0)
@export var item_color: Color = Color(0.32, 0.39, 0.36, 1.0)
@export var cursor_color: Color = Color(0.92, 0.78, 0.37, 1.0)

var _cell_nodes: Array[ColorRect] = []
var _item_tile_nodes: Array[Control] = []
var _cursor_cell := Vector2i.ZERO
var _cursor_node: Panel


func _ready() -> void:
	_connect_inventory_changed()
	refresh()


func refresh() -> void:
	if !is_node_ready():
		return

	_clear_dynamic_nodes()
	if grid_inventory == null:
		return

	custom_minimum_size = _grid_pixel_size()
	size = custom_minimum_size
	_build_cells()
	_build_item_tiles()
	_build_cursor()


func get_item_tiles() -> Array[Control]:
	return _item_tile_nodes.duplicate()


func get_cursor_cell() -> Vector2i:
	return _cursor_cell


func get_selected_item() -> InventoryItem:
	if grid_inventory == null:
		return null

	return grid_inventory.get_item_at_cell(_cursor_cell) as InventoryItem


func reset_cursor() -> void:
	_cursor_cell = Vector2i.ZERO
	_update_cursor_visual()


func move_cursor(direction: Vector2i) -> void:
	if grid_inventory == null or grid_inventory.columns <= 0 or grid_inventory.rows <= 0:
		return
	if direction == Vector2i.ZERO:
		return

	_cursor_cell.x = wrapi(_cursor_cell.x + signi(direction.x), 0, grid_inventory.columns)
	_cursor_cell.y = wrapi(_cursor_cell.y + signi(direction.y), 0, grid_inventory.rows)
	_update_cursor_visual()


func _build_cells() -> void:
	for y: int in range(grid_inventory.rows):
		for x: int in range(grid_inventory.columns):
			var cell: ColorRect = ColorRect.new()
			cell.name = "InventoryCell"
			cell.color = cell_color
			cell.position = _cell_position(Vector2i(x, y))
			cell.size = cell_size
			add_child(cell)
			_cell_nodes.append(cell)


func _build_item_tiles() -> void:
	for item: InventoryItem in grid_inventory.get_items():
		var tile: Control = Control.new()
		tile.name = "InventoryItemTile"
		tile.position = _cell_position(item.origin)
		tile.size = _item_pixel_size(item.get_size())
		tile.custom_minimum_size = tile.size
		tile.set_meta("inventory_item_id", item.instance_id)
		add_child(tile)
		_item_tile_nodes.append(tile)

		var background: ColorRect = ColorRect.new()
		background.name = "Background"
		background.color = item_color
		background.set_anchors_preset(Control.PRESET_FULL_RECT)
		tile.add_child(background)

		var icon: TextureRect = TextureRect.new()
		icon.name = "Icon"
		icon.texture = item.config.icon_texture
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon.offset_left = 2
		icon.offset_top = 2
		icon.offset_right = -2
		icon.offset_bottom = -8
		tile.add_child(icon)

		var label: Label = Label.new()
		label.name = "Label"
		label.text = _abbreviate_display_name(item.config.display_name)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		label.set_anchors_preset(Control.PRESET_FULL_RECT)
		tile.add_child(label)


func _build_cursor() -> void:
	_cursor_node = Panel.new()
	_cursor_node.name = "InventoryCursor"
	_cursor_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cursor_node.size = cell_size

	var style_box := StyleBoxFlat.new()
	style_box.bg_color = Color.TRANSPARENT
	style_box.border_width_left = 1
	style_box.border_width_top = 1
	style_box.border_width_right = 1
	style_box.border_width_bottom = 1
	style_box.border_color = cursor_color
	style_box.anti_aliasing = false
	_cursor_node.add_theme_stylebox_override("panel", style_box)

	add_child(_cursor_node)
	_update_cursor_visual()


func _update_cursor_visual() -> void:
	if _cursor_node == null or grid_inventory == null:
		return
	if grid_inventory.columns <= 0 or grid_inventory.rows <= 0:
		_cursor_node.visible = false
		return

	_cursor_node.visible = true
	_cursor_cell.x = wrapi(_cursor_cell.x, 0, grid_inventory.columns)
	_cursor_cell.y = wrapi(_cursor_cell.y, 0, grid_inventory.rows)
	_cursor_node.position = _cell_position(_cursor_cell)
	_cursor_node.size = cell_size


func _clear_dynamic_nodes() -> void:
	for node: ColorRect in _cell_nodes:
		if node != null:
			remove_child(node)
			node.queue_free()
	for node: Control in _item_tile_nodes:
		if node != null:
			remove_child(node)
			node.queue_free()
	if _cursor_node != null:
		remove_child(_cursor_node)
		_cursor_node.queue_free()
		_cursor_node = null

	_cell_nodes.clear()
	_item_tile_nodes.clear()


func _connect_inventory_changed() -> void:
	if grid_inventory != null and !grid_inventory.inventory_changed.is_connected(refresh):
		grid_inventory.inventory_changed.connect(refresh)


func _disconnect_inventory_changed() -> void:
	if grid_inventory != null and grid_inventory.inventory_changed.is_connected(refresh):
		grid_inventory.inventory_changed.disconnect(refresh)


func _grid_pixel_size() -> Vector2:
	var width: float = grid_inventory.columns * cell_size.x + maxi(grid_inventory.columns - 1, 0) * cell_gap
	var height: float = grid_inventory.rows * cell_size.y + maxi(grid_inventory.rows - 1, 0) * cell_gap
	return Vector2(width, height)


func _cell_position(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * (cell_size.x + cell_gap), cell.y * (cell_size.y + cell_gap))


func _item_pixel_size(item_size: Vector2i) -> Vector2:
	var width: float = item_size.x * cell_size.x + maxi(item_size.x - 1, 0) * cell_gap
	var height: float = item_size.y * cell_size.y + maxi(item_size.y - 1, 0) * cell_gap
	return Vector2(width, height)


func _abbreviate_display_name(display_name: String) -> String:
	var abbreviation: String = ""
	for word: String in display_name.split(" ", false):
		abbreviation += word.substr(0, 1)

	return abbreviation
