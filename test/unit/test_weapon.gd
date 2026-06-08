extends GutTest


class TestProjectile:
	extends Node2D

	var direction := Vector2.ZERO

	func _ready() -> void:
		name = "TestProjectile"


func before_each() -> void:
	_free_projectiles()


func after_each() -> void:
	_free_projectiles()


func _free_projectiles() -> void:
	for projectile: Node in _find_projectiles():
		projectile.free()


func test_fire_spawns_projectile_from_config() -> void:
	var weapon: Weapon = _make_weapon(0.0)
	weapon.position = Vector2(12, 8)

	weapon.fire(Vector2.RIGHT)

	var projectile := _find_projectile()

	assert_not_null(projectile)
	assert_eq(projectile.direction, Vector2.RIGHT)
	assert_eq(projectile.global_transform, weapon.global_transform)
	projectile.free()


func test_fire_does_nothing_without_projectile_scene() -> void:
	var weapon: Weapon = add_child_autofree(Weapon.new())
	weapon.config = WeaponConfig.new()

	weapon.fire(Vector2.RIGHT)

	assert_eq(_find_projectiles().size(), 0)


func test_fire_applies_fixed_spread_offset() -> void:
	var weapon: Weapon = _make_weapon(12.0)

	weapon.fire(Vector2.RIGHT)

	var projectile := _find_projectile()
	var expected_direction := Vector2.RIGHT.rotated(deg_to_rad(12.0))

	assert_true(projectile.direction.is_equal_approx(expected_direction))
	projectile.free()


func _make_weapon(spread_degrees: float) -> Weapon:
	var weapon: Weapon = add_child_autofree(Weapon.new())
	weapon.config = _make_config(spread_degrees)
	return weapon


func _make_config(spread_degrees: float) -> WeaponConfig:
	var projectile_scene := PackedScene.new()
	var projectile := TestProjectile.new()
	var error := projectile_scene.pack(projectile)

	assert_eq(error, OK)
	projectile.free()

	var config := WeaponConfig.new()
	config.weapon_key = &"test_weapon"
	config.projectile_scene = projectile_scene
	config.spread_degrees = spread_degrees
	config.unlocked_by_default = true
	return config


func _find_projectile() -> Node2D:
	var projectiles := _find_projectiles()
	if projectiles.is_empty():
		return null

	return projectiles[0]


func _find_projectiles() -> Array[Node]:
	return get_tree().root.find_children("TestProjectile", "", true, false)
