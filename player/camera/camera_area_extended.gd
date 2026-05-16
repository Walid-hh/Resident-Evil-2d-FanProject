## camera_area.gd :: defines camera restrictions and zone-specific behavior
# @icon("uid://d35wd78tw0u4o") <-- Custom Icon Resource we added
@tool
class_name CameraArea extends Node2D

enum AreaType { STANDARD, FOCUS }

@export_group("Area Settings")
@export var area_type: AreaType = AreaType.STANDARD
@export var zoom_level: float = 1.0

@export_group("Zone Shapes")
@export var jurisdiction: Polygon2D
@export var center_boundary: Polygon2D
@export var focus_point: Marker2D

@export_group("Transition Settings")
@export var enter_duration: float = 1.0
@export var enter_trans: Tween.TransitionType = Tween.TRANS_SINE
@export var enter_ease: Tween.EaseType = Tween.EASE_OUT

var _jurisdiction_aabb: Rect2
var _debug_markers: Array[Node2D] = []


func _ready() -> void:
	_precompute_aabb()
	if not Engine.is_editor_hint():
		clear_markers()


func contains_point(point: Vector2) -> bool:
	if not jurisdiction or not _jurisdiction_aabb.has_point(point):
		return false

	var world_points := _get_world_polygon(jurisdiction)
	return Geometry2D.is_point_in_polygon(point, world_points)


func get_bound_position(desired: Vector2) -> Vector2:
	if area_type == AreaType.FOCUS and focus_point:
		return focus_point.global_position
	return _clamp_to_boundary(desired)


func _precompute_aabb() -> void:
	if not jurisdiction or jurisdiction.polygon.size() == 0:
		return

	var world_points := _get_world_polygon(jurisdiction)
	_jurisdiction_aabb = Rect2(world_points[0], Vector2.ZERO)
	for point in world_points:
		_jurisdiction_aabb = _jurisdiction_aabb.expand(point)


func _get_world_polygon(poly: Polygon2D) -> PackedVector2Array:
	var pts := poly.polygon
	var world := PackedVector2Array()
	world.resize(pts.size())
	for i in pts.size():
		world[i] = poly.to_global(pts[i])
	return world


func _clamp_to_boundary(world_pos: Vector2) -> Vector2:
	if not center_boundary:
		return world_pos

	var world_points := _get_world_polygon(center_boundary)
	if Geometry2D.is_point_in_polygon(world_pos, world_points):
		return world_pos

	var closest := world_points[0]
	var min_dist_sq := world_pos.distance_squared_to(closest)

	for i in world_points.size():
		var a := world_points[i]
		var b := world_points[(i + 1) % world_points.size()]
		var candidate := Geometry2D.get_closest_point_to_segment(world_pos, a, b)
		var dist_sq := world_pos.distance_squared_to(candidate)
		if dist_sq < min_dist_sq:
			min_dist_sq = dist_sq
			closest = candidate

	return closest


# ========== DEBUG ==========

@export_group("Debugging")
@export_tool_button("Visualize Boundary", "EditorIcons")
var visualize_action: Callable = visualize_boundary
@export_tool_button("Clear Markers", "EditorIcons")
var clear_action: Callable = clear_markers


func visualize_boundary() -> void:
	clear_markers()
	if not center_boundary:
		return

	var viewport_size := Vector2(1920, 1080)
	var half_size := viewport_size * 0.5 / zoom_level
	var corner_offsets := [
		Vector2(half_size.x, half_size.y),
		Vector2(-half_size.x, half_size.y),
		Vector2(-half_size.x, -half_size.y),
		Vector2(half_size.x, -half_size.y)
	]

	for point in center_boundary.polygon:
		var world_pos := center_boundary.to_global(point)
		var line := Line2D.new()

		for offset: Vector2 in corner_offsets:
			line.add_point(to_local(world_pos + offset))
		line.add_point(to_local(world_pos + corner_offsets[0]))

		line.default_color = Color.WHITE
		line.width = 15.0
		line.z_index = 100

		add_child(line)
		_debug_markers.append(line)


func clear_markers() -> void:
	for marker in _debug_markers:
		if is_instance_valid(marker):
			marker.queue_free()
	_debug_markers.clear()
