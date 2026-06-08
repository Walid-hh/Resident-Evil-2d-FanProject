extends GutTest

class TestWeapon:
	extends Weapon
	var weapon_key: StringName = &"handgun"

	func _ready() -> void:
		pass

	func get_weapon_key() -> StringName:
		return weapon_key


var _texture: Texture2D
var _animator: PlayerAnimator
var _legs: AnimatedSprite2D
var _body: AnimatedSprite2D
var _head: AnimatedSprite2D
var _arms: AnimatedSprite2D
var _weapon: Weapon


func before_each() -> void:
	_texture = _make_texture()
	_legs = add_child_autofree(_make_sprite([
		"legs_idle",
		"legs_run",
		"legs_jump",
		"legs_fall",
		"legs_crouch",
	]))
	_body = add_child_autofree(_make_sprite([
		"body_idle",
		"body_run",
		"body_jump",
		"body_fall",
		"body_aim",
		"body_crouch",
	]))
	_head = add_child_autofree(_make_sprite([
		"head_idle",
		"head_up",
		"head_down",
		"head_crouch",
	]))
	_arms = add_child_autofree(_make_sprite([
		"arms_hg_idle",
		"arms_hg_right",
		"arms_hg_diagonal_up",
		"arms_hg_up",
		"arms_hg_down",
		"arms_hg_crouch",
		"arms_hg_right_fire",
		"arms_hg_diagonal_up_fire",
		"arms_hg_up_fire",
		"arms_hg_down_fire",
		"arms_hg_crouch_fire",
		"arms_sg_idle",
		"arms_sg_right",
		"arms_sg_diagonal_up",
		"arms_sg_up",
		"arms_sg_down",
		"arms_sg_crouch",
		"arms_sg_right_fire",
		"arms_sg_diagonal_up_fire",
		"arms_sg_up_fire",
		"arms_sg_down_fire",
		"arms_sg_crouch_fire",
	]))
	_weapon = add_child_autofree(_make_weapon(&"handgun"))

	_animator = add_child_autofree(PlayerAnimator.new())
	_animator.legs = _legs
	_animator.body = _body
	_animator.head = _head
	_animator.arms = _arms


func test_fall_legs_animation_is_not_restarted_while_still_falling() -> void:
	_animator.physics_update("fall", PlayerMotor.State.FALL, _weapon, Vector2.ZERO)
	_legs.frame = 1
	_legs.stop()

	_animator.physics_update("fall", PlayerMotor.State.FALL, _weapon, Vector2.ZERO)

	assert_eq(_legs.animation, &"legs_fall", "Legs should stay on fall animation.")
	assert_eq(_legs.frame, 1, "Repeated fall updates should not restart legs_fall.")
	assert_false(_legs.is_playing(), "Repeated fall updates should not resume a stopped non-looping fall animation.")


func test_fall_can_change_to_idle_animation() -> void:
	_animator.physics_update("fall", PlayerMotor.State.FALL, _weapon, Vector2.ZERO)

	_animator.physics_update("idle", PlayerMotor.State.GROUND, _weapon, Vector2.ZERO)

	assert_eq(_legs.animation, &"legs_idle", "Changing animation keys should still start the new legs animation.")
	assert_eq(_body.animation, &"body_idle", "Changing animation keys should still start the new body animation.")


func test_handgun_attack_animation_uses_forced_fire_path() -> void:
	_animator.start_attack(Vector2.RIGHT)

	_animator.physics_update("idle", PlayerMotor.State.GROUND, _weapon, Vector2.RIGHT)

	assert_eq(_arms.animation, &"arms_hg_right_fire", "Attack should route to the fire animation.")
	assert_false(_animator.is_attack_animation_finished(), "Attack animation should mark itself unfinished after starting.")


func test_attack_can_start_again_after_animation_finished() -> void:
	_animator.start_attack(Vector2.RIGHT)
	_animator.physics_update("idle", PlayerMotor.State.GROUND, _weapon, Vector2.RIGHT)
	_animator._on_arms_animation_finished()

	_animator.start_attack(Vector2.UP)
	_animator.physics_update("idle", PlayerMotor.State.GROUND, _weapon, Vector2.UP)

	assert_eq(_arms.animation, &"arms_hg_up_fire", "A later attack should be able to start a new fire animation.")


func test_shotgun_ready_and_fire_paths_use_shotgun_prefix() -> void:
	_weapon = add_child_autofree(_make_weapon(&"shotgun"))

	_animator.physics_update("idle", PlayerMotor.State.GROUND, _weapon, Vector2.RIGHT)
	assert_eq(_arms.animation, &"arms_sg_right", "Shotgun ready state should use shotgun arm art.")

	_animator.start_attack(Vector2.RIGHT)
	_animator.physics_update("idle", PlayerMotor.State.GROUND, _weapon, Vector2.RIGHT)
	assert_eq(_arms.animation, &"arms_sg_right_fire", "Shotgun firing should use shotgun fire art.")


func test_crouch_precedence_changes_between_ready_and_fire_paths() -> void:
	_animator.physics_update("crouch", PlayerMotor.State.CROUCH, _weapon, Vector2.RIGHT)
	assert_eq(_arms.animation, &"arms_hg_crouch", "Crouch without firing should use the crouch pose.")

	_animator.start_attack(Vector2.RIGHT)
	_animator.physics_update("crouch", PlayerMotor.State.CROUCH, _weapon, Vector2.RIGHT)
	assert_eq(_arms.animation, &"arms_hg_crouch_fire", "Crouch while firing should use the crouch fire pose.")


func test_aim_direction_routes_to_the_expected_ready_animations() -> void:
	_animator.physics_update("aim", PlayerMotor.State.AIM, _weapon, Vector2.RIGHT)
	assert_eq(_arms.animation, &"arms_hg_right", "Right aim should use the right ready pose.")

	_animator.physics_update("aim", PlayerMotor.State.AIM, _weapon, Vector2(1, -0.8))
	assert_eq(_arms.animation, &"arms_hg_diagonal_up", "Diagonal up aim should use the diagonal ready pose.")

	_animator.physics_update("aim", PlayerMotor.State.AIM, _weapon, Vector2.UP)
	assert_eq(_arms.animation, &"arms_hg_up", "Up aim should use the up ready pose.")

	_animator.physics_update("aim", PlayerMotor.State.AIM, _weapon, Vector2.DOWN)
	assert_eq(_arms.animation, &"arms_hg_down", "Down aim should use the down ready pose.")


func test_unknown_weapon_falls_back_to_handgun_animations() -> void:
	_weapon = add_child_autofree(_make_weapon(&"laser"))

	_animator.physics_update("idle", PlayerMotor.State.GROUND, _weapon, Vector2.RIGHT)

	assert_eq(_arms.animation, &"arms_hg_right", "Unknown weapons should fall back to the handgun prefix.")


func test_unknown_aim_falls_back_to_idle_or_right_ready_poses() -> void:
	_animator.physics_update("idle", PlayerMotor.State.GROUND, _weapon, Vector2(0.5, 0.5))
	assert_eq(_arms.animation, &"arms_hg_idle", "Unknown aim should fall back to idle when not in aim state.")

	_animator.physics_update("aim", PlayerMotor.State.AIM, _weapon, Vector2(0.5, 0.5))
	assert_eq(_arms.animation, &"arms_hg_right", "Unknown aim should fall back to right when in aim state.")


func test_repeated_ready_updates_do_not_restart_stable_arm_animation() -> void:
	_animator.physics_update("idle", PlayerMotor.State.GROUND, _weapon, Vector2.RIGHT)
	_arms.frame = 1
	_arms.stop()

	_animator.physics_update("idle", PlayerMotor.State.GROUND, _weapon, Vector2.RIGHT)

	assert_eq(_arms.animation, &"arms_hg_right", "Repeated ready updates should keep the same arm animation.")
	assert_eq(_arms.frame, 1, "Repeated ready updates should not restart the arm animation.")
	assert_false(_arms.is_playing(), "Repeated ready updates should not resume a stopped arm animation.")


func _make_sprite(animation_names: Array) -> AnimatedSprite2D:
	var frames := SpriteFrames.new()
	for animation_name: String in animation_names:
		frames.add_animation(animation_name)
		frames.set_animation_loop(animation_name, false)
		frames.add_frame(animation_name, _texture)
		frames.add_frame(animation_name, _texture)

	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	return sprite


func _make_weapon(weapon_key: StringName) -> Weapon:
	var weapon := TestWeapon.new()
	weapon.weapon_key = weapon_key
	return weapon


func _make_texture() -> Texture2D:
	var image := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	return ImageTexture.create_from_image(image)
