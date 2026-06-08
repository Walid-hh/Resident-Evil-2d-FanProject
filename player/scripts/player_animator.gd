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

const ARM_ANIMATIONS: Dictionary = {
	&"handgun": {
		"idle": "arms_hg_idle",
		"right": "arms_hg_right",
		"diagonal_up": "arms_hg_diagonal_up",
		"up": "arms_hg_up",
		"down": "arms_hg_down",
		"crouch": "arms_hg_crouch",
		"fire_right": "arms_hg_right_fire",
		"fire_diagonal_up": "arms_hg_diagonal_up_fire",
		"fire_up": "arms_hg_up_fire",
		"fire_down": "arms_hg_down_fire",
		"fire_crouch": "arms_hg_crouch_fire",
	},
	&"shotgun": {
		"idle": "arms_sg_idle",
		"right": "arms_sg_right",
		"diagonal_up": "arms_sg_diagonal_up",
		"up": "arms_sg_up",
		"down": "arms_sg_down",
		"crouch": "arms_sg_crouch",
		"fire_right": "arms_sg_right_fire",
		"fire_diagonal_up": "arms_sg_diagonal_up_fire",
		"fire_up": "arms_sg_up_fire",
		"fire_down": "arms_sg_down_fire",
		"fire_crouch": "arms_sg_crouch_fire",
	},
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

	var weapon_anims: Dictionary = ARM_ANIMATIONS.get(weapon.get_weapon_key(), ARM_ANIMATIONS[&"handgun"])
	var is_crouching := player_state == PlayerMotor.State.CROUCH
	if is_crouching and !_is_firing:
		_play_if_changed(arms, weapon_anims["crouch"])
	elif is_crouching and _is_firing:
		arms.play(weapon_anims["fire_crouch"])
		_is_firing_animation_finished = false
	elif _is_firing:
		arms.play(_get_fire_animation_name(weapon_anims, aim_direction))
		_is_firing_animation_finished = false
	else:
		_play_if_changed(arms, _get_ready_animation_name(weapon_anims, aim_direction, player_state))


func _play_if_changed(sprite: AnimatedSprite2D, animation_name: StringName) -> void:
	if sprite.animation == animation_name:
		return

	sprite.play(animation_name)


func _get_ready_animation_name(weapon_anims: Dictionary, aim_direction: Vector2, player_state: int) -> String:
	match aim_direction:
		Vector2.RIGHT, Vector2.LEFT:
			return weapon_anims["right"]
		Vector2(1, -0.8), Vector2(-1, -0.8):
			return weapon_anims["diagonal_up"]
		Vector2.UP:
			return weapon_anims["up"]
		Vector2.DOWN:
			return weapon_anims["down"]
		_:
			if player_state != PlayerMotor.State.AIM:
				return weapon_anims["idle"]
			return weapon_anims["right"]


func _get_fire_animation_name(weapon_anims: Dictionary, aim_direction: Vector2) -> String:
	match aim_direction:
		Vector2.RIGHT, Vector2.LEFT:
			return weapon_anims["fire_right"]
		Vector2(1, -0.8), Vector2(-1, -0.8):
			return weapon_anims["fire_diagonal_up"]
		Vector2.UP:
			return weapon_anims["fire_up"]
		Vector2.DOWN:
			return weapon_anims["fire_down"]
		_:
			return weapon_anims["fire_right"]


func _on_arms_animation_finished() -> void:
	if _is_firing:
		_is_firing = false
		_is_firing_animation_finished = true
		attack_animation_finished.emit()
