extends GutTest

const InventoryItemDefinitionScript := preload("res://inventory/inventory_item_definition.gd")
const InventoryQuantityResultScript := preload("res://inventory/inventory_quantity_result.gd")
const InventorySlotDefinitionScript := preload("res://inventory/inventory_slot_definition.gd")


func test_player_inventory_initializes_authored_slots_with_default_quantities() -> void:
	var player_inventory := _make_player_inventory()

	assert_true(player_inventory.has_item_slot(&"green_herb"))
	assert_true(player_inventory.has_item_slot(&"shotgun_ammo"))
	assert_true(player_inventory.has_item_slot(&"first_aid_spray"))
	assert_eq(player_inventory.get_item_quantity(&"green_herb"), 1)
	assert_eq(player_inventory.get_item_quantity(&"shotgun_ammo"), 10)
	assert_eq(player_inventory.get_item_quantity(&"first_aid_spray"), 1)


func test_player_inventory_keeps_zero_quantity_slot_valid() -> void:
	var empty_herb_slot := _make_slot(_make_item_definition(&"green_herb", 1), 0)
	var player_inventory := _make_player_inventory([empty_herb_slot])

	assert_true(player_inventory.has_item_slot(&"green_herb"))
	assert_eq(player_inventory.get_item_quantity(&"green_herb"), 0)
	assert_false(player_inventory.has_item_quantity(&"green_herb", 1))


func test_player_inventory_consumes_valid_quantity_and_emits_change() -> void:
	var player_inventory := _make_player_inventory()
	watch_signals(player_inventory)

	assert_true(player_inventory.consume_item_quantity(&"shotgun_ammo", 3))
	assert_eq(player_inventory.get_item_quantity(&"shotgun_ammo"), 7)
	assert_signal_emit_count(player_inventory, "inventory_changed", 1)


func test_player_inventory_rejects_insufficient_quantity_without_mutating() -> void:
	var player_inventory := _make_player_inventory()
	watch_signals(player_inventory)

	assert_false(player_inventory.consume_item_quantity(&"shotgun_ammo", 11))
	assert_eq(player_inventory.get_item_quantity(&"shotgun_ammo"), 10)
	assert_signal_emit_count(player_inventory, "inventory_changed", 0)


func test_player_inventory_adds_quantity_until_item_max_and_reports_leftover() -> void:
	var ammo_definition := _make_item_definition(&"shotgun_ammo", 12)
	var player_inventory := _make_player_inventory([_make_slot(ammo_definition, 10)])
	watch_signals(player_inventory)

	var result := player_inventory.add_item_quantity(ammo_definition, 5)

	assert_true(result.success)
	assert_eq(result.accepted_quantity, 2)
	assert_eq(result.leftover_quantity, 3)
	assert_eq(player_inventory.get_item_quantity(&"shotgun_ammo"), 12)
	assert_signal_emit_count(player_inventory, "inventory_changed", 1)


func test_player_inventory_unknown_item_key_fails_and_pushes_error() -> void:
	var player_inventory := _make_player_inventory()
	var missing_definition := _make_item_definition(&"missing_item", 5)

	assert_eq(player_inventory.get_item_quantity(&"missing_item"), 0)
	assert_push_error("Unknown inventory item key")
	assert_false(player_inventory.has_item_quantity(&"missing_item", 1))
	assert_push_error("Unknown inventory item key")
	assert_false(player_inventory.consume_item_quantity(&"missing_item", 1))
	assert_push_error("Unknown inventory item key")

	var result := player_inventory.add_item_quantity(missing_definition, 1)

	assert_false(result.success)
	assert_eq(result.reason, InventoryQuantityResultScript.Reason.UNKNOWN_ITEM)
	assert_eq(result.leftover_quantity, 1)
	assert_push_error("Unknown inventory item key")


func test_player_inventory_empty_item_key_is_infinite_compatibility_surface() -> void:
	var player_inventory := _make_player_inventory()

	assert_eq(player_inventory.get_item_quantity(&""), 0)
	assert_true(player_inventory.has_item_quantity(&"", 999))
	assert_true(player_inventory.consume_item_quantity(&"", 999))


func _make_player_inventory(slot_definitions: Array[Resource] = []) -> PlayerInventory:
	var player_inventory := PlayerInventory.new()
	if slot_definitions.is_empty():
		player_inventory.slot_definitions = [
			_make_slot(_make_item_definition(&"green_herb", 1), 1),
			_make_slot(_make_item_definition(&"shotgun_ammo", 20), 10),
			_make_slot(_make_item_definition(&"first_aid_spray", 1), 1),
		]
	else:
		player_inventory.slot_definitions = slot_definitions

	add_child_autofree(player_inventory)
	player_inventory.initialize()
	return player_inventory


func _make_slot(
	item_definition: Resource,
	starting_quantity: int
) -> Resource:
	var slot_definition := InventorySlotDefinitionScript.new()
	slot_definition.item_definition = item_definition
	slot_definition.starting_quantity = starting_quantity
	return slot_definition


func _make_item_definition(item_key: StringName, max_quantity: int) -> Resource:
	var item_definition := InventoryItemDefinitionScript.new()
	item_definition.item_key = item_key
	item_definition.display_name = String(item_key)
	item_definition.max_quantity = max_quantity
	return item_definition
