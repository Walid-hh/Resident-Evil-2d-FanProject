class_name PlayerInventory extends Node

const GridInventoryScript: GDScript = preload("uid://bjt8wqgl14qn6")
const GREEN_HERB_CONFIG: ItemConfig = preload("res://inventory/items/green_herb.tres")
const SHOTGUN_AMMO_CONFIG: ItemConfig = preload("res://inventory/items/shotgun_ammo.tres")
const FIRST_AID_SPRAY_CONFIG: ItemConfig = preload("res://inventory/items/first_aid_spray.tres")

@export var grid_inventory: GridInventory

var _initialized: bool = false


func _ready() -> void:
	initialize()


func initialize() -> void:
	if _initialized:
		return

	_initialized = true
	if grid_inventory == null:
		grid_inventory = get_node_or_null("GridInventory") as GridInventory
	if grid_inventory == null:
		grid_inventory = GridInventoryScript.new()
		grid_inventory.name = "GridInventory"
		add_child(grid_inventory)

	grid_inventory.columns = 8
	grid_inventory.rows = 4
	_seed_demo_items()


func get_grid_inventory() -> GridInventory:
	initialize()
	return grid_inventory


func get_item_quantity(item_key: StringName) -> int:
	initialize()
	return grid_inventory.get_total_quantity(item_key)


func has_item_quantity(item_key: StringName, quantity: int) -> bool:
	if item_key == &"":
		return true
	if quantity <= 0:
		return true

	return get_item_quantity(item_key) >= quantity


func consume_item_quantity(item_key: StringName, quantity: int) -> bool:
	initialize()
	if item_key == &"":
		return true

	return grid_inventory.consume_item_quantity(item_key, quantity)


func add_item_quantity(config: ItemConfig, quantity: int) -> RefCounted:
	initialize()
	return grid_inventory.add_item_stack(config, quantity)


func _seed_demo_items() -> void:
	if !grid_inventory.get_items().is_empty():
		return

	grid_inventory.add_item_at(GREEN_HERB_CONFIG, Vector2i(0, 0))
	grid_inventory.add_item_at(SHOTGUN_AMMO_CONFIG, Vector2i(2, 0), false, 10)
	grid_inventory.add_item_at(SHOTGUN_AMMO_CONFIG, Vector2i(1, 1), false, 10)
	grid_inventory.add_item_at(FIRST_AID_SPRAY_CONFIG, Vector2i(5, 1))
