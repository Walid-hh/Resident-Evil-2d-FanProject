class_name PauseMenu extends Control

@export var player_inventory: PlayerInventory
@export var inventory_grid_view: InventoryGridView


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	if inventory_grid_view != null and player_inventory != null:
		inventory_grid_view.grid_inventory = player_inventory.get_grid_inventory()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_menu"):
		toggle_open()
		get_viewport().set_input_as_handled()
		return

	if !visible:
		return

	if event.is_action_pressed("left"):
		_move_inventory_cursor(Vector2i.LEFT)
	elif event.is_action_pressed("right"):
		_move_inventory_cursor(Vector2i.RIGHT)
	elif event.is_action_pressed("up"):
		_move_inventory_cursor(Vector2i.UP)
	elif event.is_action_pressed("down"):
		_move_inventory_cursor(Vector2i.DOWN)


func toggle_open() -> void:
	set_open(!visible)


func set_open(open: bool) -> void:
	visible = open
	get_tree().paused = open
	if open and inventory_grid_view != null:
		inventory_grid_view.reset_cursor()


func _move_inventory_cursor(direction: Vector2i) -> void:
	if inventory_grid_view != null:
		inventory_grid_view.move_cursor(direction)
	get_viewport().set_input_as_handled()
