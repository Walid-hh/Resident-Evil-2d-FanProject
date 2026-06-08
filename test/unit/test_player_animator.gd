extends GutTest

class TestWeapon:
	extends Weapon

	func _ready() -> void:
		pass

	func get_weapon_key() -> StringName:
		return &"handgun"


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
	]))
	_weapon = add_child_autofree(TestWeapon.new())

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


func test_attack_animation_uses_forced_fire_path() -> void:
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


func _make_texture() -> Texture2D:
	var image := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	return ImageTexture.create_from_image(image)
