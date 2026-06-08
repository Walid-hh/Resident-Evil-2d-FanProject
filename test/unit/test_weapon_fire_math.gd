extends GutTest


func test_zero_aim_uses_fallback_fire_direction() -> void:
	var result := WeaponFireMath.get_fire_direction(Vector2.ZERO, -1.0)

	assert_eq(result, Vector2.LEFT)


func test_anchor_rotation_matches_fire_direction() -> void:
	var anchor: Marker2D = add_child_autofree(Marker2D.new())

	WeaponFireMath.apply_anchor_rotation(anchor, Vector2.UP)

	assert_true(is_equal_approx(anchor.global_rotation, Vector2.UP.angle()))
