class_name AimController extends Node

const ALLOWED_AIM_DIRECTIONS := [
	Vector2(-1, -0.8),
	Vector2(0, -1),
	Vector2(1, -0.8),
	Vector2(-1, 0),
	Vector2(1, 0),
]

var direction_x := 0.0
var aim_direction := Vector2.ZERO
var last_horizontal_direction := 1.0


func physics_update(player_state: int, is_crouching: bool, arms_flipped: bool) -> void:
	direction_x = signf(Input.get_axis("left", "right"))
	if direction_x != 0.0 and !is_crouching:
		last_horizontal_direction = direction_x
		Global.player_last_direction = direction_x

	aim_direction = get_snapped_direction_for_input(
		Input.get_vector("left", "right", "up", "down"),
		player_state,
		is_crouching,
		arms_flipped
	)
	Global.player_aim_direction = aim_direction


func get_direction_x() -> float:
	return direction_x


func get_aim_direction() -> Vector2:
	return aim_direction


func get_last_horizontal_direction() -> float:
	return last_horizontal_direction


func apply_facing(parts: Array) -> void:
	if direction_x == 0.0:
		return

	var flip := direction_x < 0.0
	for part: AnimatedSprite2D in parts:
		if part != null:
			part.flip_h = flip


func get_snapped_direction_for_input(raw: Vector2, player_state: int, is_crouching: bool, arms_flipped: bool) -> Vector2:
	if raw.length() < 0.2:
		return Vector2.ZERO

	if player_state != PlayerMotor.State.JUMP and raw == Vector2.DOWN:
		return Vector2.ZERO
	elif is_crouching:
		if arms_flipped:
			return Vector2.LEFT
		return Vector2.RIGHT

	var best_dir := Vector2.ZERO
	var best_dot := -INF
	for dir: Vector2 in ALLOWED_AIM_DIRECTIONS:
		var dot := raw.dot(dir.normalized())
		if dot > best_dot:
			best_dot = dot
			best_dir = dir
	return best_dir
