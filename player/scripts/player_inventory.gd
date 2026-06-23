class_name PlayerInventory extends Node

signal inventory_changed

const InventoryItemDefinitionScript := preload("res://inventory/inventory_item_definition.gd")
const InventoryQuantityResultScript := preload("res://inventory/inventory_quantity_result.gd")
const InventorySlotDefinitionScript := preload("res://inventory/inventory_slot_definition.gd")

@export var slot_definitions: Array[Resource] = []

var _initialized: bool = false
var _item_definitions: Dictionary = {}
var _quantities: Dictionary = {}


func _ready() -> void:
	initialize()


func initialize() -> void:
	if _initialized:
		return

	_initialized = true
	_item_definitions.clear()
	_quantities.clear()
	for slot_definition: Resource in slot_definitions:
		if slot_definition == null or !(slot_definition is InventorySlotDefinitionScript) or !slot_definition.is_valid():
			continue

		var item_definition: Resource = slot_definition.item_definition
		var item_key: StringName = item_definition.item_key
		if _item_definitions.has(item_key):
			push_error("Duplicate inventory slot for item key: %s" % item_key)
			continue

		_item_definitions[item_key] = item_definition
		_quantities[item_key] = slot_definition.get_starting_quantity()


func get_item_quantity(item_key: StringName) -> int:
	initialize()
	if item_key == &"":
		return 0
	if !_has_known_item_key(item_key):
		return 0

	return int(_quantities.get(item_key, 0))


func has_item_quantity(item_key: StringName, quantity: int) -> bool:
	initialize()
	if item_key == &"":
		return true
	if quantity <= 0:
		return true
	if !_has_known_item_key(item_key):
		return false

	return get_item_quantity(item_key) >= quantity


func consume_item_quantity(item_key: StringName, quantity: int) -> bool:
	initialize()
	if item_key == &"":
		return true
	if quantity <= 0:
		return true
	if !_has_known_item_key(item_key):
		return false
	if get_item_quantity(item_key) < quantity:
		return false

	_quantities[item_key] = get_item_quantity(item_key) - quantity
	inventory_changed.emit()
	return true


func add_item_quantity(item_definition: Resource, quantity: int) -> RefCounted:
	initialize()
	if item_definition == null or !(item_definition is InventoryItemDefinitionScript) or !item_definition.is_valid() or quantity <= 0:
		return InventoryQuantityResultScript.new(
			false,
			InventoryQuantityResultScript.Reason.INVALID_ITEM,
			0,
			maxi(quantity, 0)
		)
	if !_has_known_item_key(item_definition.item_key):
		return InventoryQuantityResultScript.new(
			false,
			InventoryQuantityResultScript.Reason.UNKNOWN_ITEM,
			0,
			quantity
		)

	var current_quantity := get_item_quantity(item_definition.item_key)
	var max_quantity: int = item_definition.get_max_quantity()
	var accepted_quantity := mini(quantity, maxi(max_quantity - current_quantity, 0))
	var leftover_quantity := quantity - accepted_quantity
	if accepted_quantity <= 0:
		return InventoryQuantityResultScript.new(
			false,
			InventoryQuantityResultScript.Reason.MAX_QUANTITY_REACHED,
			0,
			quantity
		)

	_quantities[item_definition.item_key] = current_quantity + accepted_quantity
	inventory_changed.emit()
	return InventoryQuantityResultScript.new(
		true,
		InventoryQuantityResultScript.Reason.OK,
		accepted_quantity,
		leftover_quantity
	)


func has_item_slot(item_key: StringName) -> bool:
	initialize()
	if item_key == &"":
		return true

	return _item_definitions.has(item_key)


func get_item_definition(item_key: StringName) -> Resource:
	initialize()
	return _item_definitions.get(item_key) as Resource


func _has_known_item_key(item_key: StringName) -> bool:
	if _item_definitions.has(item_key):
		return true

	push_error("Unknown inventory item key: %s" % item_key)
	return false
