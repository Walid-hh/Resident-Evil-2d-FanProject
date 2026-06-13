class_name PlayerCamera extends Camera2D

const CAMERA_BOUNDS_GROUP := "camera_bounds"
const CAMERA_STOP_AREA_GROUP := "camera_stop_area"

@export var target: Node2D
@export var viewport_size := Vector2(320, 180)
@export var player_screen_x := 104.0
@export var left_edge_margin := 8.0
@export var right_edge_margin := 8.0
@export var vertical_offset := -48.0
@export var lookahead_distance := 12.0
@export var lookahead_speed := 8.0
@export var horizontal_camera_tween_duration := 0.18
@export var horizontal_camera_tween_speed_scale := 1.0
@export var horizontal_camera_tween_transition := Tween.TRANS_LINEAR
@export var horizontal_camera_tween_ease := Tween.EASE_OUT
@export var vertical_camera_tween_duration := 0.5
@export var vertical_camera_tween_speed_scale := 1.0
@export var vertical_camera_tween_transition := Tween.TRANS_SINE
@export var vertical_camera_tween_ease := Tween.EASE_OUT

var camera_bounds := Rect2(-120, -16, 2000, 180)
var target_camera_position := Vector2.ZERO
var _lookahead_x := 0.0
var _active_stop_positions: Array[float] = []
var _grounded_camera_y := 0.0
var _has_grounded_camera_y := false
var _camera_motion_start_x := 0.0
var _camera_motion_target_x := 0.0
var _camera_motion_elapsed_x := 0.0
var _camera_motion_start_y := 0.0
var _camera_motion_target_y := 0.0
var _camera_motion_elapsed_y := 0.0


func _ready() -> void:
	top_level = true
	position_smoothing_enabled = false
	set_physics_process(false)
	make_current()
	if target == null:
		target = get_parent() as Node2D
	call_deferred("_initialize_from_level")


func _initialize_from_level() -> void:
	_configure_from_level()
	snap_to_target()
	set_physics_process(true)


func _physics_process(delta: float) -> void:
	physics_update(delta)


func physics_update(delta: float) -> void:
	if target == null:
		return

	_update_lookahead(delta)
	var desired_position := _snap_camera_position(_clamp_camera_center(Vector2(
		_get_forward_target_x(),
		_get_vertical_target_y()
	)))
	_advance_camera_motion(desired_position, delta)


func configure_bounds(bounds: Rect2) -> void:
	camera_bounds = bounds
	target_camera_position = _snap_camera_position(_clamp_camera_center(target_camera_position))
	_apply_hard_camera_target(target_camera_position)


func request_camera_stop(stop_camera_x: float) -> void:
	_active_stop_positions.append(stop_camera_x)
	target_camera_position.x = minf(target_camera_position.x, _get_active_stop_x())
	_apply_hard_camera_target(target_camera_position)


func release_camera_stop(stop_camera_x: float) -> void:
	_active_stop_positions.erase(stop_camera_x)
	target_camera_position.x = minf(target_camera_position.x, _get_active_stop_x())
	_apply_hard_camera_target(target_camera_position)


func snap_to_target() -> void:
	if target == null:
		return

	target_camera_position = _snap_camera_position(_clamp_camera_center(Vector2(
		_get_desired_camera_x(),
		_get_vertical_target_y()
	)))
	_apply_hard_camera_target(target_camera_position)


func get_screen_left() -> float:
	return get_screen_center_position().x - viewport_size.x * 0.5


func get_screen_right() -> float:
	return get_screen_center_position().x + viewport_size.x * 0.5


func get_target_camera_position() -> Vector2:
	return target_camera_position


func _configure_from_level() -> void:
	var tree := get_tree()
	if tree == null:
		return

	var bounds_node := tree.get_first_node_in_group(CAMERA_BOUNDS_GROUP)
	if bounds_node != null and bounds_node.has_method("get_camera_bounds"):
		configure_bounds(bounds_node.get_camera_bounds())
		snap_to_target()

	for node in tree.get_nodes_in_group(CAMERA_STOP_AREA_GROUP):
		_connect_stop_area(node)


func _connect_stop_area(node: Node) -> void:
	if node.has_signal("camera_stop_requested"):
		node.camera_stop_requested.connect(request_camera_stop)
	if node.has_signal("camera_stop_released"):
		node.camera_stop_released.connect(release_camera_stop)


func _update_lookahead(delta: float) -> void:
	var velocity_x := 0.0
	if target is CharacterBody2D:
		velocity_x = (target as CharacterBody2D).velocity.x

	var desired_lookahead := 0.0
	if velocity_x > 0.0:
		desired_lookahead = lookahead_distance
	_lookahead_x = move_toward(_lookahead_x, desired_lookahead, lookahead_speed * lookahead_distance * delta)


func _get_forward_target_x() -> float:
	var desired_x := _get_desired_camera_x()
	desired_x = maxf(target_camera_position.x, desired_x)
	desired_x = minf(desired_x, _get_active_stop_x())
	return desired_x


func _get_desired_camera_x() -> float:
	return target.global_position.x + viewport_size.x * 0.5 - player_screen_x + _lookahead_x


func _get_vertical_target_y() -> float:
	if _is_target_grounded():
		_grounded_camera_y = target.global_position.y + vertical_offset
		_has_grounded_camera_y = true
		return _grounded_camera_y

	if _has_grounded_camera_y:
		return _grounded_camera_y

	return target.global_position.y + vertical_offset


func _clamp_camera_center(value: Vector2) -> Vector2:
	return Vector2(
		_clamp_axis_center(value.x, camera_bounds.position.x, camera_bounds.size.x, viewport_size.x),
		_clamp_axis_center(value.y, camera_bounds.position.y, camera_bounds.size.y, viewport_size.y)
	)


func _clamp_axis_center(value: float, start: float, size: float, viewport_length: float) -> float:
	if size <= viewport_length:
		return start + size * 0.5
	return clampf(value, start + viewport_length * 0.5, start + size - viewport_length * 0.5)


func _get_active_stop_x() -> float:
	if _active_stop_positions.is_empty():
		return INF

	var stop_x := INF
	for active_stop_x: float in _active_stop_positions:
		stop_x = minf(stop_x, active_stop_x)
	return stop_x


func _has_active_stop() -> bool:
	return !_active_stop_positions.is_empty()


func _apply_hard_camera_target(position: Vector2) -> void:
	_apply_camera_position(position)
	_sync_camera_motion(target_camera_position)


func _snap_camera_position(position: Vector2) -> Vector2:
	return position.snapped(Vector2.ONE)


func _advance_camera_motion(desired_position: Vector2, delta: float) -> void:
	var horizontal_duration := _get_horizontal_camera_tween_duration()
	var vertical_duration := _get_vertical_camera_tween_duration()

	if desired_position.x != _camera_motion_target_x:
		_camera_motion_start_x = target_camera_position.x
		_camera_motion_target_x = desired_position.x
		_camera_motion_elapsed_x = 0.0

	if desired_position.y != _camera_motion_target_y:
		_camera_motion_start_y = target_camera_position.y
		_camera_motion_target_y = desired_position.y
		_camera_motion_elapsed_y = 0.0

	var next_x := desired_position.x
	if horizontal_duration > 0.0:
		_camera_motion_elapsed_x = minf(_camera_motion_elapsed_x + delta, horizontal_duration)
		next_x = _interpolate_camera_axis(
			_camera_motion_start_x,
			_camera_motion_target_x,
			_camera_motion_elapsed_x,
			horizontal_duration,
			horizontal_camera_tween_transition,
			horizontal_camera_tween_ease
		)
	else:
		_camera_motion_start_x = desired_position.x
		_camera_motion_target_x = desired_position.x
		_camera_motion_elapsed_x = 0.0

	var next_y := desired_position.y
	if vertical_duration > 0.0:
		_camera_motion_elapsed_y = minf(_camera_motion_elapsed_y + delta, vertical_duration)
		next_y = _interpolate_camera_axis(
			_camera_motion_start_y,
			_camera_motion_target_y,
			_camera_motion_elapsed_y,
			vertical_duration,
			vertical_camera_tween_transition,
			vertical_camera_tween_ease
		)
	else:
		_camera_motion_start_y = desired_position.y
		_camera_motion_target_y = desired_position.y
		_camera_motion_elapsed_y = 0.0

	_apply_camera_position(Vector2(
		next_x,
		next_y
	))


func _apply_camera_position(position: Vector2) -> void:
	target_camera_position = _snap_camera_position(_clamp_camera_center(position))
	global_position = target_camera_position


func _sync_camera_motion(position: Vector2) -> void:
	_camera_motion_start_x = position.x
	_camera_motion_target_x = position.x
	_camera_motion_elapsed_x = 0.0
	_camera_motion_start_y = position.y
	_camera_motion_target_y = position.y
	_camera_motion_elapsed_y = 0.0


func _interpolate_camera_axis(
	start: float,
	target_axis: float,
	elapsed: float,
	duration: float,
	transition: Tween.TransitionType,
	ease: Tween.EaseType
) -> float:
	return Tween.interpolate_value(
		start,
		target_axis - start,
		elapsed,
		duration,
		transition,
		ease
	)


func _get_horizontal_camera_tween_duration() -> float:
	if horizontal_camera_tween_duration <= 0.0:
		return 0.0

	return horizontal_camera_tween_duration / maxf(horizontal_camera_tween_speed_scale, 0.001)


func _get_vertical_camera_tween_duration() -> float:
	if vertical_camera_tween_duration <= 0.0:
		return 0.0

	return vertical_camera_tween_duration / maxf(vertical_camera_tween_speed_scale, 0.001)


func _is_target_grounded() -> bool:
	if target == null:
		return false

	if target.has_method("camera_is_on_floor"):
		return bool(target.call("camera_is_on_floor"))

	if target.has_method("is_on_floor"):
		return bool(target.call("is_on_floor"))

	return false
