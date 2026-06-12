class_name GridInventory extends Node

signal inventory_changed

const InventoryItemScript := preload("uid://cq2loov70akoe")
const InventoryPlacementResultScript := preload("uid://iltn4hw7jlhj")
const ItemConfigScript := preload("uid://b2dfkpbc1vskx")

@export_range(1, 64, 1) var columns := 8
@export_range(1, 64, 1) var rows := 4

var _items: Dictionary = {}
var _occupied_cells: Dictionary = {}
var _next_instance_number := 1


func add_item_at(config: Resource, origin: Vector2i, rotated := false, quantity := 1) -> RefCounted:
	var validation := _validate_placement(config, origin, rotated)
	if !validation.success:
		return validation

	var sanitized_quantity := _sanitize_item_quantity(config, quantity)
	if sanitized_quantity <= 0:
		return InventoryPlacementResultScript.fail(InventoryPlacementResultScript.Reason.INVALID_ITEM)

	var item := InventoryItemScript.new(_generate_instance_id(), config, origin, rotated, sanitized_quantity)
	_place_item(item)
	inventory_changed.emit()
	return InventoryPlacementResultScript.ok(item)


func add_item_first_fit(config: Resource, rotated := false, quantity := 1) -> RefCounted:
	var first_check := _validate_item(config, rotated)
	if !first_check.success:
		return first_check

	for y in range(rows):
		for x in range(columns):
			var origin := Vector2i(x, y)
			if _validate_placement(config, origin, rotated).success:
				return add_item_at(config, origin, rotated, quantity)

	return InventoryPlacementResultScript.fail(InventoryPlacementResultScript.Reason.NOT_ENOUGH_SPACE)


func add_item_stack(config: Resource, quantity: int, rotated := false) -> RefCounted:
	var validation := _validate_item(config, rotated)
	if !validation.success:
		return validation
	if quantity <= 0:
		return InventoryPlacementResultScript.fail(InventoryPlacementResultScript.Reason.INVALID_ITEM, null, maxi(quantity, 0))
	if !config.stackable:
		return _add_non_stackable_items(config, quantity, rotated)

	var remaining := quantity
	var changed := false
	var last_item: InventoryItem = null

	for item: InventoryItem in _get_matching_stackable_items(config.item_key):
		if remaining <= 0:
			break

		var max_quantity: int = item.config.get_max_stack_quantity()
		var available := max_quantity - item.quantity
		if available <= 0:
			continue

		var transfer := mini(remaining, available)
		item.quantity += transfer
		remaining -= transfer
		changed = true
		last_item = item

	while remaining > 0:
		var stack_quantity: int = mini(remaining, config.get_max_stack_quantity())
		var result := _add_item_first_fit_without_signal(config, rotated, stack_quantity)
		if !result.success:
			break

		remaining -= stack_quantity
		changed = true
		last_item = result.item as InventoryItem

	if changed:
		inventory_changed.emit()
		return InventoryPlacementResultScript.ok(last_item, remaining)

	return InventoryPlacementResultScript.fail(InventoryPlacementResultScript.Reason.NOT_ENOUGH_SPACE, null, remaining)


func consume_item_quantity(item_key: StringName, quantity: int) -> bool:
	if quantity <= 0:
		return true
	if _get_total_stackable_quantity(item_key) < quantity:
		return false

	var remaining := quantity
	for item: InventoryItem in _get_matching_stackable_items(item_key, true):
		if remaining <= 0:
			break

		var consumed := mini(remaining, item.quantity)
		item.quantity -= consumed
		remaining -= consumed
		if item.quantity <= 0:
			_clear_item_cells(item)
			_items.erase(item.instance_id)

	inventory_changed.emit()
	return true


func get_total_quantity(item_key: StringName) -> int:
	var total := 0
	for item: InventoryItem in get_items():
		if item.config == null or item.config.item_key != item_key:
			continue

		total += item.quantity

	return total


func merge_item_stack(source_instance_id: StringName, target_instance_id: StringName) -> RefCounted:
	var source := get_item(source_instance_id)
	var target := get_item(target_instance_id)
	if source == null or target == null:
		return InventoryPlacementResultScript.fail(InventoryPlacementResultScript.Reason.NOT_FOUND)
	if !_can_merge_item_stacks(source, target):
		return InventoryPlacementResultScript.fail(InventoryPlacementResultScript.Reason.OCCUPIED, source, source.quantity)

	var available: int = target.config.get_max_stack_quantity() - target.quantity
	var transfer := mini(source.quantity, available)
	if transfer <= 0:
		return InventoryPlacementResultScript.fail(InventoryPlacementResultScript.Reason.OCCUPIED, source, source.quantity)

	target.quantity += transfer
	source.quantity -= transfer
	if source.quantity <= 0:
		_clear_item_cells(source)
		_items.erase(source.instance_id)

	inventory_changed.emit()
	return InventoryPlacementResultScript.ok(source if source.quantity > 0 else target, source.quantity)


func remove_item(instance_id: StringName) -> RefCounted:
	var item := get_item(instance_id)
	if item == null:
		return InventoryPlacementResultScript.fail(InventoryPlacementResultScript.Reason.NOT_FOUND)

	_clear_item_cells(item)
	_items.erase(instance_id)
	inventory_changed.emit()
	return InventoryPlacementResultScript.ok(item)


func move_item(instance_id: StringName, new_origin: Vector2i) -> RefCounted:
	var item := get_item(instance_id)
	if item == null:
		return InventoryPlacementResultScript.fail(InventoryPlacementResultScript.Reason.NOT_FOUND)

	return _move_item_to(item, new_origin, item.rotated)


func move_item_with_rotation(instance_id: StringName, new_origin: Vector2i, rotated: bool) -> RefCounted:
	var item := get_item(instance_id)
	if item == null:
		return InventoryPlacementResultScript.fail(InventoryPlacementResultScript.Reason.NOT_FOUND)

	return _move_item_to(item, new_origin, rotated)


func _move_item_to(item: InventoryItem, new_origin: Vector2i, target_rotated: bool) -> RefCounted:
	var validation := _validate_placement(item.config, new_origin, target_rotated, item.instance_id)
	if !validation.success:
		return validation

	_clear_item_cells(item)
	item.origin = new_origin
	item.rotated = target_rotated
	_mark_item_cells(item)
	inventory_changed.emit()
	return InventoryPlacementResultScript.ok(item)


func rotate_item(instance_id: StringName) -> RefCounted:
	var item := get_item(instance_id)
	if item == null:
		return InventoryPlacementResultScript.fail(InventoryPlacementResultScript.Reason.NOT_FOUND)

	var next_rotated: bool = !item.rotated
	var validation := _validate_placement(item.config, item.origin, next_rotated, instance_id)
	if !validation.success:
		return validation

	_clear_item_cells(item)
	item.rotated = next_rotated
	_mark_item_cells(item)
	inventory_changed.emit()
	return InventoryPlacementResultScript.ok(item)


func get_items() -> Array:
	var items := []
	for item in _items.values():
		items.append(item)

	return items


func get_item(instance_id: StringName) -> InventoryItem:
	return _items.get(instance_id) as InventoryItem


func get_item_at_cell(cell: Vector2i) -> InventoryItem:
	var instance_id := _occupied_cells.get(cell, &"") as StringName
	if instance_id == &"":
		return null

	return get_item(instance_id)


func get_occupied_cells(instance_id: StringName) -> Array[Vector2i]:
	var item := get_item(instance_id)
	if item == null:
		return []

	return item.get_occupied_cells()


func can_place(config: Resource, origin: Vector2i, rotated := false) -> bool:
	return _validate_placement(config, origin, rotated).success


func is_cell_occupied(cell: Vector2i) -> bool:
	return _occupied_cells.has(cell)


func _validate_placement(
	config: Resource,
	origin: Vector2i,
	rotated := false,
	ignored_instance_id: StringName = &""
) -> RefCounted:
	var item_check := _validate_item(config, rotated)
	if !item_check.success:
		return item_check

	var size: Vector2i = config.get_size(rotated)
	if origin.x < 0 or origin.y < 0:
		return InventoryPlacementResultScript.fail(InventoryPlacementResultScript.Reason.OUT_OF_BOUNDS)
	if origin.x + size.x > columns or origin.y + size.y > rows:
		return InventoryPlacementResultScript.fail(InventoryPlacementResultScript.Reason.OUT_OF_BOUNDS)

	for y in range(size.y):
		for x in range(size.x):
			var cell := origin + Vector2i(x, y)
			var occupant_id := _occupied_cells.get(cell, &"") as StringName
			if occupant_id != &"" and occupant_id != ignored_instance_id:
				return InventoryPlacementResultScript.fail(InventoryPlacementResultScript.Reason.OCCUPIED)

	return InventoryPlacementResultScript.ok()


func _validate_item(config: Resource, rotated := false) -> RefCounted:
	if columns <= 0 or rows <= 0:
		return InventoryPlacementResultScript.fail(InventoryPlacementResultScript.Reason.OUT_OF_BOUNDS)
	if config == null or !(config is ItemConfigScript) or !config.is_valid():
		return InventoryPlacementResultScript.fail(InventoryPlacementResultScript.Reason.INVALID_ITEM)
	if rotated and !config.can_rotate:
		return InventoryPlacementResultScript.fail(InventoryPlacementResultScript.Reason.CANNOT_ROTATE)

	return InventoryPlacementResultScript.ok()


func _place_item(item: RefCounted) -> void:
	_items[item.instance_id] = item
	_mark_item_cells(item)


func _add_item_first_fit_without_signal(config: Resource, rotated := false, quantity := 1) -> RefCounted:
	for y in range(rows):
		for x in range(columns):
			var origin := Vector2i(x, y)
			if _validate_placement(config, origin, rotated).success:
				var item := InventoryItemScript.new(_generate_instance_id(), config, origin, rotated, quantity)
				_place_item(item)
				return InventoryPlacementResultScript.ok(item)

	return InventoryPlacementResultScript.fail(InventoryPlacementResultScript.Reason.NOT_ENOUGH_SPACE, null, quantity)


func _add_non_stackable_items(config: Resource, quantity: int, rotated := false) -> RefCounted:
	var remaining := quantity
	var changed := false
	var last_item: InventoryItem = null

	while remaining > 0:
		var result := _add_item_first_fit_without_signal(config, rotated, 1)
		if !result.success:
			break

		remaining -= 1
		changed = true
		last_item = result.item as InventoryItem

	if changed:
		inventory_changed.emit()
		return InventoryPlacementResultScript.ok(last_item, remaining)

	return InventoryPlacementResultScript.fail(InventoryPlacementResultScript.Reason.NOT_ENOUGH_SPACE, null, remaining)


func _sanitize_item_quantity(config: Resource, quantity: int) -> int:
	if config == null:
		return 0
	if !config.stackable and quantity != 1:
		return 0
	if config.stackable:
		return clampi(quantity, 1, config.get_max_stack_quantity())

	return 1


func _get_matching_stackable_items(item_key: StringName, lowest_quantity_first := false) -> Array[InventoryItem]:
	var matching_items: Array[InventoryItem] = []
	for item: InventoryItem in get_items():
		if item.config == null:
			continue
		if item.config.item_key != item_key:
			continue
		if !item.config.stackable:
			continue

		matching_items.append(item)

	if lowest_quantity_first:
		matching_items.sort_custom(_compare_stack_quantity_then_origin)
	else:
		matching_items.sort_custom(_compare_origin_then_stack_quantity)

	return matching_items


func _get_total_stackable_quantity(item_key: StringName) -> int:
	var total := 0
	for item: InventoryItem in _get_matching_stackable_items(item_key):
		total += item.quantity

	return total


func _can_merge_item_stacks(source: InventoryItem, target: InventoryItem) -> bool:
	if source == target:
		return false
	if source.config == null or target.config == null:
		return false
	if !source.config.stackable or !target.config.stackable:
		return false
	if source.config.item_key != target.config.item_key:
		return false

	return target.quantity < target.config.get_max_stack_quantity()


func _compare_stack_quantity_then_origin(a: InventoryItem, b: InventoryItem) -> bool:
	if a.quantity == b.quantity:
		return _compare_origin_then_stack_quantity(a, b)

	return a.quantity < b.quantity


func _compare_origin_then_stack_quantity(a: InventoryItem, b: InventoryItem) -> bool:
	if a.origin.y == b.origin.y:
		if a.origin.x == b.origin.x:
			return a.quantity < b.quantity

		return a.origin.x < b.origin.x

	return a.origin.y < b.origin.y


func _mark_item_cells(item: RefCounted) -> void:
	for cell in item.get_occupied_cells():
		_occupied_cells[cell] = item.instance_id


func _clear_item_cells(item: RefCounted) -> void:
	for cell in item.get_occupied_cells():
		_occupied_cells.erase(cell)


func _generate_instance_id() -> StringName:
	var instance_id := StringName("inventory_item_%d" % _next_instance_number)
	_next_instance_number += 1
	return instance_id
