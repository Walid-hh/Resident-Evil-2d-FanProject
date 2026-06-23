extends GutTest


func after_each() -> void:
	get_tree().paused = false


func test_pause_menu_starts_hidden_and_toggles_tree_pause() -> void:
	var pause_menu: PauseMenu = add_child_autofree(PauseMenu.new())

	assert_false(pause_menu.visible)

	pause_menu.toggle_open()

	assert_true(pause_menu.visible)
	assert_true(get_tree().paused)

	pause_menu.toggle_open()

	assert_false(pause_menu.visible)
	assert_false(get_tree().paused)


func test_pause_menu_ignores_non_pause_input_while_hidden() -> void:
	var pause_menu: PauseMenu = add_child_autofree(PauseMenu.new())

	pause_menu._unhandled_input(_make_action_event("right"))

	assert_false(pause_menu.visible)
	assert_false(get_tree().paused)


func test_pause_menu_ignores_non_pause_actions_while_visible() -> void:
	var pause_menu: PauseMenu = add_child_autofree(PauseMenu.new())
	pause_menu.set_open(true)

	pause_menu._unhandled_input(_make_action_event("right"))
	pause_menu._unhandled_input(_make_action_event("fire"))

	assert_true(pause_menu.visible)
	assert_true(get_tree().paused)


func test_pause_menu_action_toggles_open() -> void:
	var pause_menu: PauseMenu = add_child_autofree(PauseMenu.new())

	pause_menu._unhandled_input(_make_action_event("pause_menu"))

	assert_true(pause_menu.visible)
	assert_true(get_tree().paused)


func _make_action_event(action: StringName) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	return event
