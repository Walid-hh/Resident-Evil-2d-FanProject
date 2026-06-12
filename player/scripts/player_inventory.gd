class_name PlayerInventory extends Node

const GridInventoryScript: GDScript = preload("uid://bjt8wqgl14qn6")
const GREEN_HERB_CONFIG: ItemConfig = preload("res://inventory/items/green_herb.tres")
const HANDGUN_AMMO_CONFIG: ItemConfig = preload("res://inventory/items/handgun_ammo.tres")
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


func _seed_demo_items() -> void:
	if !grid_inventory.get_items().is_empty():
		return

	grid_inventory.add_item_at(GREEN_HERB_CONFIG, Vector2i(0, 0))
	grid_inventory.add_item_at(HANDGUN_AMMO_CONFIG, Vector2i(2, 0))
	grid_inventory.add_item_at(FIRST_AID_SPRAY_CONFIG, Vector2i(5, 1))
