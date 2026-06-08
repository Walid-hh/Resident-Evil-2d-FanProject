extends GutTest


class TestPlayer:
	extends Player

	var active_weapon_config: WeaponConfig
	var unlocked_weapon_configs: Array[WeaponConfig] = []

	func _ready() -> void:
		pass

	func get_active_weapon_config() -> WeaponConfig:
		return active_weapon_config

	func get_unlocked_weapon_configs() -> Array[WeaponConfig]:
		return unlocked_weapon_configs


func test_unlocked_configs_show_their_hud_slots_and_icons() -> void:
	var hud: PlayerHUD = autofree(_make_hud())
	var player: TestPlayer = autofree(TestPlayer.new())
	var handgun := _make_config(&"handgun")
	var shotgun := _make_config(&"shotgun")

	player.unlocked_weapon_configs = [handgun, shotgun]
	player.active_weapon_config = handgun
	hud.player = player

	hud.set_unlocked_weapon_visible()

	assert_true(hud.handgun_canvas.visible)
	assert_true(hud.shotgun_canvas.visible)
	assert_eq(hud.handgun_ui.texture, handgun.hud_ui_texture)
	assert_eq(hud.shotgun_ui.texture, shotgun.hud_ui_texture)


func test_physics_update_focuses_the_active_config_slot() -> void:
	var hud: PlayerHUD = autofree(_make_hud())
	var player: TestPlayer = autofree(TestPlayer.new())
	var handgun := _make_config(&"handgun")
	var shotgun := _make_config(&"shotgun")

	player.unlocked_weapon_configs = [handgun, shotgun]
	player.active_weapon_config = shotgun
	hud.player = player

	hud._physics_process(0.0)

	assert_eq(hud.handgun_canvas.texture, hud.gun_texture_no_focus)
	assert_eq(hud.shotgun_canvas.texture, hud.gun_texture_focus)
	assert_false(hud.hg_focus_indicator.visible)
	assert_true(hud.sg_focus_indicator.visible)


func _make_hud() -> PlayerHUD:
	var hud := PlayerHUD.new()
	hud.handgun_canvas = autofree(TextureRect.new())
	hud.handgun_ui = autofree(TextureRect.new())
	hud.hg_focus_indicator = autofree(TextureRect.new())
	hud.shotgun_canvas = autofree(TextureRect.new())
	hud.shotgun_ui = autofree(TextureRect.new())
	hud.sg_focus_indicator = autofree(TextureRect.new())
	return hud


func _make_config(weapon_key: StringName) -> WeaponConfig:
	var config := WeaponConfig.new()
	config.weapon_key = weapon_key
	config.hud_ui_texture = ImageTexture.create_from_image(Image.create(1, 1, false, Image.FORMAT_RGBA8))
	config.projectile_scene = PackedScene.new()
	config.unlocked_by_default = true
	return config
