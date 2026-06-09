extends GutTest


var _hud: PlayerHUD


func before_each() -> void:
	_hud = add_child_autofree(PlayerHUD.new())
	_hud.weapon_slots_container = add_child_autofree(HBoxContainer.new())
	_hud.health_bar = add_child_autofree(ProgressBar.new())


func test_set_weapon_slots_builds_data_driven_slots() -> void:
	var handgun := _make_config(&"handgun")
	var shotgun := _make_config(&"shotgun")

	_hud.set_weapon_slots([handgun, null, shotgun])

	assert_eq(_hud.weapon_slots_container.get_child_count(), 2)

	var first_slot = _hud.weapon_slots_container.get_child(0)
	var second_slot = _hud.weapon_slots_container.get_child(1)

	assert_eq(first_slot.get_weapon_config(), handgun)
	assert_eq(first_slot.weapon_icon.texture, handgun.hud_ui_no_focus_texture)
	assert_eq(first_slot.texture, first_slot.frame_no_focus_texture)
	assert_false(first_slot.focus_indicator.visible)

	assert_eq(second_slot.get_weapon_config(), shotgun)
	assert_eq(second_slot.weapon_icon.texture, shotgun.hud_ui_no_focus_texture)
	assert_eq(second_slot.texture, second_slot.frame_no_focus_texture)
	assert_false(second_slot.focus_indicator.visible)


func test_set_active_weapon_config_highlights_only_matching_slot() -> void:
	var handgun := _make_config(&"handgun")
	var shotgun := _make_config(&"shotgun")

	_hud.set_weapon_slots([handgun, shotgun])
	_hud.set_active_weapon_config(shotgun)

	var first_slot = _hud.weapon_slots_container.get_child(0)
	var second_slot = _hud.weapon_slots_container.get_child(1)

	assert_eq(first_slot.texture, first_slot.frame_no_focus_texture)
	assert_eq(first_slot.weapon_icon.texture, handgun.hud_ui_no_focus_texture)
	assert_false(first_slot.focus_indicator.visible)
	assert_eq(second_slot.texture, second_slot.frame_focus_texture)
	assert_eq(second_slot.weapon_icon.texture, shotgun.hud_ui_texture)
	assert_true(second_slot.focus_indicator.visible)


func test_set_weapon_slots_rebuilds_existing_slots() -> void:
	var handgun := _make_config(&"handgun")
	var shotgun := _make_config(&"shotgun")

	_hud.set_weapon_slots([handgun])
	_hud.set_active_weapon_config(handgun)
	_hud.set_weapon_slots([shotgun])

	var slot = _hud.weapon_slots_container.get_child(0)

	assert_eq(_hud.weapon_slots_container.get_child_count(), 1)
	assert_eq(slot.get_weapon_config(), shotgun)
	assert_eq(slot.texture, slot.frame_no_focus_texture)
	assert_eq(slot.weapon_icon.texture, shotgun.hud_ui_no_focus_texture)
	assert_false(slot.focus_indicator.visible)


func test_inactive_icon_falls_back_to_active_icon_when_missing() -> void:
	var handgun := _make_config(&"handgun")
	handgun.hud_ui_no_focus_texture = null

	_hud.set_weapon_slots([handgun])

	var slot = _hud.weapon_slots_container.get_child(0)

	assert_eq(slot.weapon_icon.texture, handgun.hud_ui_texture)


func test_set_health_values_updates_health_bar() -> void:
	_hud.set_health_values(3, 5)

	assert_eq(_hud.health_bar.max_value, 5.0)
	assert_eq(_hud.health_bar.value, 3.0)


func _make_config(weapon_key: StringName) -> WeaponConfig:
	var config := WeaponConfig.new()
	config.weapon_key = weapon_key
	config.hud_ui_texture = ImageTexture.create_from_image(Image.create(1, 1, false, Image.FORMAT_RGBA8))
	config.hud_ui_no_focus_texture = ImageTexture.create_from_image(Image.create(1, 1, false, Image.FORMAT_RGBA8))
	config.projectile_scene = PackedScene.new()
	config.unlocked_by_default = true
	return config
