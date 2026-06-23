class_name InventorySlotDefinition extends Resource

const InventoryItemDefinitionScript := preload("res://inventory/inventory_item_definition.gd")

@export var item_definition: Resource
@export_range(0, 999, 1) var starting_quantity := 0


func is_valid() -> bool:
	return item_definition != null and item_definition is InventoryItemDefinitionScript and item_definition.is_valid()


func get_starting_quantity() -> int:
	if item_definition == null:
		return 0

	return clampi(starting_quantity, 0, item_definition.get_max_quantity())
