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
