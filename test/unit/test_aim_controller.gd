extends GutTest

var _controller: AimController


func before_each() -> void:
	_controller = add_child_autofree(AimController.new())


func test_zero_input_returns_zero_aim_direction() -> void:
	var result := _controller.get_snapped_direction_for_input(Vector2.ZERO, PlayerMotor.State.GROUND, false, false)

	assert_eq(result, Vector2.ZERO)


func test_down_input_is_blocked_outside_jump() -> void:
	var result := _controller.get_snapped_direction_for_input(Vector2.DOWN, PlayerMotor.State.GROUND, false, false)

	assert_eq(result, Vector2.ZERO)


func test_crouch_aim_uses_left_facing_when_arms_are_flipped() -> void:
	var result := _controller.get_snapped_direction_for_input(Vector2.RIGHT, PlayerMotor.State.CROUCH, true, true)

	assert_eq(result, Vector2.LEFT)


func test_crouch_aim_uses_right_facing_when_arms_are_not_flipped() -> void:
	var result := _controller.get_snapped_direction_for_input(Vector2.LEFT, PlayerMotor.State.CROUCH, true, false)

	assert_eq(result, Vector2.RIGHT)


func test_up_input_snaps_to_up() -> void:
	var result := _controller.get_snapped_direction_for_input(Vector2.UP, PlayerMotor.State.GROUND, false, false)

	assert_eq(result, Vector2.UP)


func test_horizontal_input_snaps_to_right() -> void:
	var result := _controller.get_snapped_direction_for_input(Vector2.RIGHT, PlayerMotor.State.GROUND, false, false)

	assert_eq(result, Vector2.RIGHT)


func test_diagonal_up_input_snaps_to_allowed_diagonal() -> void:
	var result := _controller.get_snapped_direction_for_input(Vector2(1, -1), PlayerMotor.State.GROUND, false, false)

	assert_eq(result, Vector2(1, -0.8))
