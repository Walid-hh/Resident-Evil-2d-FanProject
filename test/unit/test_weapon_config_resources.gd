extends GutTest


func test_handgun_weapon_config_resource_is_complete() -> void:
	var config := load("res://player/weapons/configs/handgun_weapon_config.tres") as WeaponConfig

	assert_not_null(config)
	assert_eq(config.weapon_key, &"handgun")
	assert_not_null(config.projectile_scene)
	assert_not_null(config.hud_ui_texture)
	assert_eq(config.fire_rate, 0.133)
	assert_true(config.unlocked_by_default)


func test_shotgun_weapon_config_resource_is_complete() -> void:
	var config := load("res://player/weapons/configs/shotgun_weapon_config.tres") as WeaponConfig

	assert_not_null(config)
	assert_eq(config.weapon_key, &"shotgun")
	assert_not_null(config.projectile_scene)
	assert_not_null(config.hud_ui_texture)
	assert_eq(config.fire_rate, 0.75)
	assert_true(config.unlocked_by_default)
