class_name PauseMenu extends Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_menu"):
		toggle_open()
		get_viewport().set_input_as_handled()
		return

	if !visible:
		return


func toggle_open() -> void:
	set_open(!visible)


func set_open(open: bool) -> void:
	visible = open
	get_tree().paused = open
