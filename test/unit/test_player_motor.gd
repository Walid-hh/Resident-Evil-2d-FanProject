extends GutTest

var _player: CharacterBody2D
var _anchor: Marker2D
var _motor: PlayerMotor


func before_each() -> void:
	_player = add_child_autofree(CharacterBody2D.new())
	_anchor = Marker2D.new()
	_player.add_child(_anchor)
	_motor = PlayerMotor.new()
	_motor.anchor = _anchor
	_player.add_child(_motor)


func test_initial_state_is_ground() -> void:
	assert_eq(_motor.get_state(), PlayerMotor.State.GROUND)
	assert_eq(_motor.get_state_name(), "GROUND")


func test_jump_request_transitions_to_jump_and_sets_velocity() -> void:
	_motor.physics_update(0.016, 1.0, true, false, false, false, false, true)

	assert_eq(_motor.get_state(), PlayerMotor.State.JUMP)
	assert_eq(_motor.get_animation_key(), PlayerMotor.ANIMATION_JUMP)
	assert_lt(_player.velocity.y, 0.0, "Jump should set upward velocity.")
	assert_gt(_player.velocity.x, 0.0, "Jump should apply horizontal jump velocity.")


func test_falling_state_uses_fall_animation_key() -> void:
	_motor.physics_update(0.016, 0.0, true, false, false, false, false, true)
	_player.velocity.y = 0.0

	_motor.physics_update(0.016, 0.0, false, false, false, false, false, true)

	assert_eq(_motor.get_state(), PlayerMotor.State.FALL)
	assert_eq(_motor.get_animation_key(), PlayerMotor.ANIMATION_FALL)


func test_crouch_applies_anchor_offset_and_retry_exit_restores_ground() -> void:
	_motor.physics_update(0.016, 0.0, false, false, false, true, false, true)

	assert_eq(_motor.get_state(), PlayerMotor.State.CROUCH)
	assert_eq(_anchor.position.y, 2.0)

	_motor.retry_crouch_exit(false, true)

	assert_eq(_motor.get_state(), PlayerMotor.State.GROUND)
	assert_eq(_anchor.position.y, -8.0)
