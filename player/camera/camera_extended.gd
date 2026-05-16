## camera.gd :: main camera controller, bound by CameraAreas
class_name Camera extends Camera2D

@export var player: CharacterBody2D

const LOOKAHEAD_STRENGTH: float = 50.0
const LOOKAHEAD_DEADZONE: float = 32.0
const LOOKAHEAD_MOVE_SPEED: float = 400.0  # pixels per second, tune this
const LOOKAHEAD_SPEED: float = 5.0
const SMOOTHING_SPEED: float = 5.0
const SMOOTHING_SNAP_THRESHOLD: float = 2.0
const ZOOM_SPEED: float = 3.0
const DEFAULT_ZOOM: float = 1.0
const OFFSET_ABOVE_PLAYER: Vector2 = Vector2(0, -48)
const PEEK_DISTANCE: float = 160.0
const PEEK_TWEEN_DURATION: float = 0.4

var all_areas: Array[CameraArea] = []
var current_area: CameraArea = null
var previous_area: CameraArea = null
var transitioning: bool = false
var transition_tween: Tween = null

var velocity_smooth: Vector2 = Vector2.ZERO
var lookahead_target: Vector2 = Vector2.ZERO
var lookahead_current: Vector2 = Vector2.ZERO
var peek_tween: Tween = null

var base_offset: Vector2 = Vector2.ZERO
var peek_offset: Vector2 = Vector2.ZERO
var shake_tween: Tween = null
var shake_offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	# Fetch all CameraAreas in the scene
	all_areas.assign(get_tree().get_nodes_in_group("camera_area"))
	base_offset = offset



func _physics_process(delta: float) -> void:
	# Get the current CameraArea
	_find_current_area()

	# Determine where the camera wants to be
	var desired_position := _get_desired_position(delta)
	# Bind the desired position according to the area
	var bound_position := current_area.get_bound_position(desired_position) if current_area else desired_position

	# Smoothly move the camera, and adjust zoom
	_update_camera_position(bound_position, delta)
	_update_zoom(delta)
	offset = base_offset + peek_offset + shake_offset




func _get_lookahead(delta: float) -> Vector2:
	var w: float = clamp(LOOKAHEAD_SPEED * delta, 0.0, 1.0)
	velocity_smooth = velocity_smooth.lerp(player.velocity, w)

	if player.velocity.length() > 10.0:
		lookahead_target = Vector2(player.velocity.normalized().x * LOOKAHEAD_STRENGTH, 0.0)

	# Only move lookahead once the target is beyond the deadzone
	var to_target := lookahead_target - lookahead_current
	if abs(to_target.x) > LOOKAHEAD_DEADZONE:
		lookahead_current = lookahead_current.move_toward(lookahead_target, LOOKAHEAD_MOVE_SPEED * delta)

	return lookahead_current


func _get_desired_position(delta: float) -> Vector2:
	return player.global_position + OFFSET_ABOVE_PLAYER + _get_lookahead(delta)


func _update_camera_position(target_position: Vector2, delta: float) -> void:
	if transitioning:
		return
	var new_pos: Vector2
	if global_position.distance_to(target_position) < SMOOTHING_SNAP_THRESHOLD:
		new_pos = target_position
	else:
		new_pos = global_position.lerp(target_position, clamp(SMOOTHING_SPEED * delta, 0.0, 1.0))
	
	# Snap to nearest pixel to prevent sub-pixel shimmer
	global_position = new_pos.round()


func _update_zoom(delta: float) -> void:
	var target_zoom := current_area.zoom_level if current_area else DEFAULT_ZOOM
	zoom = zoom.lerp(Vector2.ONE * target_zoom, ZOOM_SPEED * delta)


func _find_current_area() -> void:
	var player_pos := player.global_position

	if current_area and current_area.contains_point(player_pos):
		return

	for area in all_areas:
		if area.contains_point(player_pos):
			if area != current_area:
				_enter_area(area)
			return


func instant_snap() -> void:
	velocity_smooth = Vector2.ZERO
	lookahead_target = Vector2.ZERO
	lookahead_current = Vector2.ZERO

	for area in all_areas:
		if area.contains_point(player.global_position):
			current_area = area
			global_position = area.get_bound_position(player.global_position + OFFSET_ABOVE_PLAYER)
			zoom = Vector2.ONE * area.zoom_level
			return


func _enter_area(next: CameraArea) -> void:
	previous_area = current_area
	current_area = next

	if not previous_area:
		return

	var desired := player.global_position + OFFSET_ABOVE_PLAYER + lookahead_current
	var new_bound_pos := current_area.get_bound_position(desired)
	var zoom_target := Vector2.ONE * current_area.zoom_level

	if transition_tween:
		transition_tween.kill()
	transitioning = true
	transition_tween = create_tween()
	transition_tween.set_trans(current_area.enter_trans).set_ease(current_area.enter_ease)
	transition_tween.tween_property(self, "global_position", new_bound_pos, current_area.enter_duration)
	transition_tween.parallel().tween_property(self, "zoom", zoom_target, current_area.enter_duration)
	transition_tween.finished.connect(func() -> void: transitioning = false)


# ========== SPECIAL EFFECTS ==========

func request_peek(dir: int) -> void:
	if dir == 0:
		cancel_peek()
		return
	var y := dir * PEEK_DISTANCE
	tween_peek(Vector2(0.0, y))


func cancel_peek() -> void:
	tween_peek(Vector2.ZERO)


func tween_peek(target: Vector2) -> void:
	if peek_tween:
		peek_tween.kill()
	peek_tween = create_tween()
	peek_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	peek_tween.tween_property(self, "peek_offset", target, PEEK_TWEEN_DURATION)


func shake(magnitude: float, duration: float) -> void:
	if shake_tween:
		shake_tween.kill()
	shake_tween = create_tween()
	var steps: int = int(duration / 0.05)
	for i in steps:
		shake_tween.tween_callback(func() -> void:
			shake_offset = Vector2(randf_range(-magnitude, magnitude), randf_range(-magnitude, magnitude)))
		shake_tween.tween_interval(0.05)
	shake_tween.tween_callback(func() -> void: shake_offset = Vector2.ZERO)
