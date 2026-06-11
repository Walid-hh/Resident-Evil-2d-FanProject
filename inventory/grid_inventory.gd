class_name GridInventory extends Node

signal inventory_changed

const InventoryItemScript := preload("res://inventory/inventory_item.gd")
const InventoryPlacementResultScript := preload("res://inventory/inventory_placement_result.gd")
const ItemConfigScript := preload("res://inventory/item_config.gd")

@export_range(1, 64, 1) var columns := 8
@export_range(1, 64, 1) var rows := 4

var _items: Dictionary = {}
var _occupied_cells: Dictionary = {}
var _next_instance_number := 1


func add_item_at(config: Resource, origin: Vector2i, rotated := false) -> RefCounted:
	var validation := _validate_placement(config, origin, rotated)
	if !validation.success:
		return validation

	var item := InventoryItemScript.new(_generate_instance_id(), config, origin, rotated)
	_place_item(item)
	inventory_changed.emit()
	return InventoryPlacementResultScript.ok(item)


func add_item_first_fit(config: Resource, rotated := false) -> RefCounted:
	var first_check := _validate_item(config, rotated)
	if !first_check.success:
		return first_check

	for y in range(rows):
		for x in range(columns):
			var origin := Vector2i(x, y)
			if _validate_placement(config, origin, rotated).success:
				return add_item_at(config, origin, rotated)

	return InventoryPlacementResultScript.fail(InventoryPlacementResultScript.Reason.NOT_ENOUGH_SPACE)


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

	var validation := _validate_placement(item.config, new_origin, item.rotated, instance_id)
	if !validation.success:
		return validation

	_clear_item_cells(item)
	item.origin = new_origin
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


func get_item(instance_id: StringName) -> RefCounted:
	return _items.get(instance_id) as RefCounted


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
