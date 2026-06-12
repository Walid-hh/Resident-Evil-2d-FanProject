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
@export var held_item_valid_color: Color = Color(0.45, 0.57, 0.42, 0.82)
@export var held_item_invalid_color: Color = Color(0.63, 0.27, 0.24, 0.82)
@export var cursor_color: Color = Color(0.92, 0.78, 0.37, 1.0)

var _cell_nodes: Array[ColorRect] = []
var _item_tile_nodes: Array[Control] = []
var _cursor_cell := Vector2i.ZERO
var _cursor_node: Panel
var _held_preview_node: Control
var _held_item: InventoryItem
var _held_origin := Vector2i.ZERO
var _held_rotated := false


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
	_build_held_preview()
	_build_cursor()


func get_item_tiles() -> Array[Control]:
	return _item_tile_nodes.duplicate()


func get_cursor_cell() -> Vector2i:
	return _cursor_cell


func get_selected_item() -> InventoryItem:
	if grid_inventory == null:
		return null

	return grid_inventory.get_item_at_cell(_cursor_cell) as InventoryItem


func is_holding_item() -> bool:
	return _held_item != null


func get_held_item() -> InventoryItem:
	return _held_item


func pick_or_place_held_item() -> void:
	if grid_inventory == null:
		return

	if is_holding_item():
		var merge_target := _get_merge_target_at_held_origin()
		if merge_target != null:
			var merge_result := grid_inventory.merge_item_stack(_held_item.instance_id, merge_target.instance_id)
			if merge_result.success and grid_inventory.get_item(_held_item.instance_id) == null:
				_clear_held_item()
			refresh()
			return

		if !_can_place_held_item():
			_update_held_preview_visual()
			return

		var item_id := _held_item.instance_id
		var target_origin := _held_origin
		var target_rotated := _held_rotated
		_clear_held_item()
		grid_inventory.move_item_with_rotation(item_id, target_origin, target_rotated)
		refresh()
		return

	var selected_item := get_selected_item()
	if selected_item == null:
		return

	_held_item = selected_item
	_held_origin = selected_item.origin
	_held_rotated = selected_item.rotated
	_cursor_cell = _held_origin
	refresh()


func rotate_held_item() -> void:
	if !is_holding_item():
		return
	if _held_item.config == null or !_held_item.config.can_rotate:
		return

	var next_rotated := !_held_rotated
	if !_is_footprint_in_bounds(_held_origin, _held_item.config.get_size(next_rotated)):
		return

	_held_rotated = next_rotated
	_clamp_held_origin()
	_cursor_cell = _held_origin
	refresh()


func cancel_held_item() -> void:
	if !is_holding_item():
		return

	_clear_held_item()
	refresh()


func reset_cursor() -> void:
	cancel_held_item()
	_cursor_cell = Vector2i.ZERO
	_update_cursor_visual()


func move_cursor(direction: Vector2i) -> void:
	if grid_inventory == null or grid_inventory.columns <= 0 or grid_inventory.rows <= 0:
		return
	if direction == Vector2i.ZERO:
		return

	if is_holding_item():
		_move_held_item(direction)
		return

	var selected_item := get_selected_item()
	if selected_item != null:
		_cursor_cell = _next_cell_after_item(selected_item, direction)
	else:
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
		tile.visible = !is_holding_item() or item.instance_id != _held_item.instance_id
		add_child(tile)
		_item_tile_nodes.append(tile)
		_populate_item_tile(tile, item, item_color)


func _build_held_preview() -> void:
	if !is_holding_item():
		return

	_held_preview_node = Control.new()
	_held_preview_node.name = "HeldItemPreview"
	_held_preview_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_held_preview_node.set_meta("inventory_item_id", _held_item.instance_id)
	add_child(_held_preview_node)
	_populate_item_tile(_held_preview_node, _held_item, held_item_valid_color)

	_update_held_preview_visual()


func _populate_item_tile(tile: Control, item: InventoryItem, background_color: Color) -> void:
	var background := ColorRect.new()
	background.name = "Background"
	background.color = background_color
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	tile.add_child(background)

	var icon := TextureRect.new()
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

	var label := Label.new()
	label.name = "Label"
	label.text = _abbreviate_display_name(item.config.display_name)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	tile.add_child(label)

	if item.config.stackable and item.quantity > 1:
		var quantity_label := Label.new()
		quantity_label.name = "QuantityLabel"
		quantity_label.text = str(item.quantity)
		quantity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		quantity_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		quantity_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		quantity_label.offset_right = -2
		tile.add_child(quantity_label)


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

	if is_holding_item():
		_cursor_node.position = _cell_position(_held_origin)
		_cursor_node.size = _item_pixel_size(_get_held_item_size())
		return

	var selected_item := get_selected_item()
	if selected_item != null:
		_cursor_node.position = _cell_position(selected_item.origin)
		_cursor_node.size = _item_pixel_size(selected_item.get_size())
	else:
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
	if _held_preview_node != null:
		remove_child(_held_preview_node)
		_held_preview_node.queue_free()
		_held_preview_node = null

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


func _move_held_item(direction: Vector2i) -> void:
	_held_origin += Vector2i(signi(direction.x), signi(direction.y))
	_clamp_held_origin()
	_cursor_cell = _held_origin
	_update_held_preview_visual()
	_update_cursor_visual()


func _clamp_held_origin() -> void:
	var held_size := _get_held_item_size()
	var max_x := maxi(grid_inventory.columns - held_size.x, 0)
	var max_y := maxi(grid_inventory.rows - held_size.y, 0)
	_held_origin.x = clampi(_held_origin.x, 0, max_x)
	_held_origin.y = clampi(_held_origin.y, 0, max_y)


func _update_held_preview_visual() -> void:
	if _held_preview_node == null or !is_holding_item():
		return

	var held_size := _get_held_item_size()
	_held_preview_node.position = _cell_position(_held_origin)
	_held_preview_node.size = _item_pixel_size(held_size)
	_held_preview_node.custom_minimum_size = _held_preview_node.size

	var background := _held_preview_node.get_node_or_null("Background") as ColorRect
	if background != null:
		background.color = held_item_valid_color if _can_place_held_item() or _get_merge_target_at_held_origin() != null else held_item_invalid_color


func _get_held_item_size() -> Vector2i:
	if !is_holding_item() or _held_item.config == null:
		return Vector2i.ZERO

	return _held_item.config.get_size(_held_rotated)


func _can_place_held_item() -> bool:
	if !is_holding_item() or grid_inventory == null:
		return false

	var held_size := _get_held_item_size()
	if !_is_footprint_in_bounds(_held_origin, held_size):
		return false

	for y in range(held_size.y):
		for x in range(held_size.x):
			var occupant := grid_inventory.get_item_at_cell(_held_origin + Vector2i(x, y)) as InventoryItem
			if occupant != null and occupant.instance_id != _held_item.instance_id:
				return false

	return true


func _get_merge_target_at_held_origin() -> InventoryItem:
	if !is_holding_item() or grid_inventory == null:
		return null
	if _held_item.config == null or !_held_item.config.stackable:
		return null

	var target := grid_inventory.get_item_at_cell(_held_origin) as InventoryItem
	if target == null or target.instance_id == _held_item.instance_id:
		return null
	if target.config == null or !target.config.stackable:
		return null
	if target.config.item_key != _held_item.config.item_key:
		return null
	if target.quantity >= target.config.get_max_stack_quantity():
		return null

	return target


func _is_footprint_in_bounds(origin: Vector2i, item_size: Vector2i) -> bool:
	if grid_inventory == null:
		return false
	if origin.x < 0 or origin.y < 0:
		return false

	return origin.x + item_size.x <= grid_inventory.columns and origin.y + item_size.y <= grid_inventory.rows


func _clear_held_item() -> void:
	_held_item = null
	_held_origin = Vector2i.ZERO
	_held_rotated = false


func _next_cell_after_item(item: InventoryItem, direction: Vector2i) -> Vector2i:
	var item_size := item.get_size()
	var next_cell := _cursor_cell
	var horizontal_step := signi(direction.x)
	var vertical_step := signi(direction.y)

	if horizontal_step > 0:
		next_cell.x = item.origin.x + item_size.x
	elif horizontal_step < 0:
		next_cell.x = item.origin.x - 1
	elif vertical_step > 0:
		next_cell.y = item.origin.y + item_size.y
	elif vertical_step < 0:
		next_cell.y = item.origin.y - 1

	next_cell.x = wrapi(next_cell.x, 0, grid_inventory.columns)
	next_cell.y = wrapi(next_cell.y, 0, grid_inventory.rows)
	return next_cell


func _abbreviate_display_name(display_name: String) -> String:
	var abbreviation: String = ""
	for word: String in display_name.split(" ", false):
		abbreviation += word.substr(0, 1)

	return abbreviation
