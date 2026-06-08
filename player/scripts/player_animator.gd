class_name PlayerAnimator extends Node

signal attack_animation_finished

const ANIMATIONS: Dictionary = {
	"idle": { "body": "body_idle", "legs": "legs_idle", "head": "head_idle" },
	"run": { "body": "body_run", "legs": "legs_run", "head": "head_idle" },
	"jump": { "body": "body_jump", "legs": "legs_jump" },
	"fall": { "body": "body_fall", "legs": "legs_fall" },
	"aim": { "body": "body_aim", "legs": "legs_idle", "head": "head_idle" },
	"crouch": { "body": "body_crouch", "legs": "legs_crouch", "head": "head_crouch" },
}

const DEFAULT_ARM_PREFIX := &"arms_hg"
const ARM_PREFIX_BY_WEAPON_KEY: Dictionary = {
	&"handgun": &"arms_hg",
	&"shotgun": &"arms_sg",
}

const AIM_DIRECTION_TOKENS: Dictionary = {
	Vector2.RIGHT: &"right",
	Vector2.LEFT: &"right",
	Vector2(1, -0.8): &"diagonal_up",
	Vector2(-1, -0.8): &"diagonal_up",
	Vector2.UP: &"up",
	Vector2.DOWN: &"down",
}

@export var legs: AnimatedSprite2D
@export var arms: AnimatedSprite2D
@export var body: AnimatedSprite2D
@export var head: AnimatedSprite2D

var _is_firing := false
var _is_firing_animation_finished := true


func _ready() -> void:
	if arms != null:
		arms.animation_finished.connect(_on_arms_animation_finished)


func physics_update(animation_key: String, player_state: int, weapon: Weapon, aim_direction: Vector2) -> void:
	_update_body_animations(animation_key)
	_update_head_animation(player_state, aim_direction)
	_update_arm_animation(player_state, weapon, aim_direction)


func start_attack(_aim_direction: Vector2) -> void:
	if _is_firing:
		return

	_is_firing = true


func is_firing() -> bool:
	return _is_firing


func is_attack_animation_finished() -> bool:
	return _is_firing_animation_finished


func _update_body_animations(animation_key: String) -> void:
	var anims: Dictionary = ANIMATIONS.get(animation_key, {})
	if anims.has("legs") and legs != null:
		_play_if_changed(legs, anims["legs"])
	if anims.has("body") and body != null:
		_play_if_changed(body, anims["body"])
	if anims.has("head") and head != null:
		_play_if_changed(head, anims["head"])


func _update_head_animation(player_state: int, aim_direction: Vector2) -> void:
	if player_state == PlayerMotor.State.CROUCH or head == null:
		return

	match aim_direction:
		Vector2.UP:
			_play_if_changed(head, "head_up")
		Vector2.DOWN:
			_play_if_changed(head, "head_down")


func _update_arm_animation(player_state: int, weapon: Weapon, aim_direction: Vector2) -> void:
	if arms == null or weapon == null or !_is_firing_animation_finished:
		return

	var is_crouching := player_state == PlayerMotor.State.CROUCH
	if is_crouching and !_is_firing:
		_play_if_changed(arms, _get_arm_animation_name(weapon, &"crouch", false))
	elif is_crouching and _is_firing:
		arms.play(_get_arm_animation_name(weapon, &"crouch", true))
		_is_firing_animation_finished = false
	elif _is_firing:
		arms.play(_get_arm_animation_name(weapon, _get_aim_direction_token(aim_direction), true))
		_is_firing_animation_finished = false
	else:
		_play_if_changed(arms, _get_arm_animation_name(weapon, _get_ready_direction_token(aim_direction, player_state), false))


func _play_if_changed(sprite: AnimatedSprite2D, animation_name: StringName) -> void:
	if sprite.animation == animation_name:
		return

	sprite.play(animation_name)


func _get_arm_animation_name(weapon: Weapon, direction_token: StringName, is_firing: bool) -> StringName:
	var prefix := _get_arm_animation_prefix(weapon)
	var animation_name := "%s_%s" % [prefix, direction_token]
	if is_firing:
		animation_name += "_fire"
	return StringName(animation_name)


func _get_arm_animation_prefix(weapon: Weapon) -> StringName:
	if weapon == null:
		return DEFAULT_ARM_PREFIX

	var weapon_key := _get_weapon_key(weapon)
	return ARM_PREFIX_BY_WEAPON_KEY.get(weapon_key, DEFAULT_ARM_PREFIX)


func _get_weapon_key(weapon: Weapon) -> StringName:
	var weapon_config := weapon.get_weapon_config()
	if weapon_config != null and weapon_config.weapon_key != &"":
		return weapon_config.weapon_key

	return weapon.get_weapon_key()


func _get_ready_direction_token(aim_direction: Vector2, player_state: int) -> StringName:
	if AIM_DIRECTION_TOKENS.has(aim_direction):
		return AIM_DIRECTION_TOKENS[aim_direction]

	if player_state != PlayerMotor.State.AIM:
		return &"idle"
	return &"right"


func _get_aim_direction_token(aim_direction: Vector2) -> StringName:
	return AIM_DIRECTION_TOKENS.get(aim_direction, &"right")


func _on_arms_animation_finished() -> void:
	if _is_firing:
		_is_firing = false
		_is_firing_animation_finished = true
		attack_animation_finished.emit()
