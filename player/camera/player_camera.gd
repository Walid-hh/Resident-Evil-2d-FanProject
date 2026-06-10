class_name PlayerCamera extends Camera2D

const CAMERA_BOUNDS_GROUP := "camera_bounds"
const CAMERA_STOP_AREA_GROUP := "camera_stop_area"

@export var target: Node2D
@export var viewport_size := Vector2(320, 180)
@export var player_screen_x := 104.0
@export var left_edge_margin := 8.0
@export var right_edge_margin := 8.0
@export var vertical_offset := -48.0
@export var follow_speed := 20.0
@export_range(0.0, 1.0, 0.01) var follow_ease_weight := 1.0
@export var vertical_follow_speed := 20.0
@export_range(0.0, 1.0, 0.01) var vertical_follow_ease_weight := 1.0
@export var lookahead_distance := 12.0
@export var lookahead_speed := 8.0

var camera_bounds := Rect2(-120, -16, 2000, 180)
var target_camera_position := Vector2.ZERO
var _lookahead_x := 0.0
var _active_stop_positions: Array[float] = []


func _ready() -> void:
	top_level = true
	make_current()
	if target == null:
		target = get_parent() as Node2D
	call_deferred("_configure_from_level")
	snap_to_target()


func _physics_process(delta: float) -> void:
	physics_update(delta)


func physics_update(delta: float) -> void:
	if target == null:
		return

	_update_lookahead(delta)
	var desired_position := Vector2(
		_get_forward_target_x(),
		_get_vertical_target_y()
	)
	target_camera_position = _clamp_camera_center(desired_position)
	var horizontal_lerp := _get_lerp_alpha(follow_speed, delta, follow_ease_weight)
	global_position.x = lerpf(global_position.x, target_camera_position.x, horizontal_lerp)
	if _is_target_grounded():
		var vertical_lerp := _get_lerp_alpha(vertical_follow_speed, delta, vertical_follow_ease_weight)
		global_position.y = lerpf(global_position.y, target_camera_position.y, vertical_lerp)
	if _has_active_stop():
		_apply_stop_frame_constraint()
	else:
		_apply_left_edge_constraint()


func configure_bounds(bounds: Rect2) -> void:
	camera_bounds = bounds
	target_camera_position = _clamp_camera_center(target_camera_position)
	global_position = _clamp_camera_center(global_position)


func request_camera_stop(stop_camera_x: float) -> void:
	_active_stop_positions.append(stop_camera_x)
	target_camera_position.x = minf(target_camera_position.x, _get_active_stop_x())


func release_camera_stop(stop_camera_x: float) -> void:
	_active_stop_positions.erase(stop_camera_x)


func snap_to_target() -> void:
	if target == null:
		return

	target_camera_position = _clamp_camera_center(Vector2(
		_get_desired_camera_x(),
		target.global_position.y + vertical_offset
	))
	global_position = target_camera_position
	if _has_active_stop():
		_apply_stop_frame_constraint()
	else:
		_apply_left_edge_constraint()


func get_screen_left() -> float:
	return global_position.x - viewport_size.x * 0.5


func get_screen_right() -> float:
	return global_position.x + viewport_size.x * 0.5


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
	if !_is_target_grounded():
		return target_camera_position.y

	return target.global_position.y + vertical_offset


func _apply_left_edge_constraint() -> void:
	if target == null:
		return

	var left_limit := get_screen_left() + left_edge_margin
	if target.global_position.x >= left_limit:
		return

	target.global_position.x = left_limit
	if target is CharacterBody2D:
		var body := target as CharacterBody2D
		body.velocity.x = maxf(body.velocity.x, 0.0)


func _apply_stop_frame_constraint() -> void:
	if target == null:
		return

	var left_limit := get_screen_left() + left_edge_margin
	var right_limit := get_screen_right() - right_edge_margin
	if target.global_position.x < left_limit:
		target.global_position.x = left_limit
		if target is CharacterBody2D:
			var body := target as CharacterBody2D
			body.velocity.x = maxf(body.velocity.x, 0.0)
	elif target.global_position.x > right_limit:
		target.global_position.x = right_limit
		if target is CharacterBody2D:
			var body := target as CharacterBody2D
			body.velocity.x = minf(body.velocity.x, 0.0)


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


func _is_target_grounded() -> bool:
	if target.has_meta("camera_is_on_floor"):
		return target.get_meta("camera_is_on_floor")
	if target.has_method("get_camera_is_on_floor"):
		return target.get_camera_is_on_floor()
	if target is CharacterBody2D:
		return (target as CharacterBody2D).is_on_floor()
	return true


func _get_lerp_alpha(speed: float, delta: float, ease_weight: float) -> float:
	var speed_alpha := clampf(speed * delta, 0.0, 1.0)
	var eased_alpha := 1.0 - exp(-speed * delta)
	return lerpf(speed_alpha, eased_alpha, clampf(ease_weight, 0.0, 1.0))
