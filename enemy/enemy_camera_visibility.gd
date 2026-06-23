class_name EnemyCameraVisibility extends Node

@export var camera: Camera2D
@export var margin := 0.0


func is_point_visible(point: Vector2) -> bool:
	var active_camera := _get_camera()
	if active_camera == null:
		return false

	return _get_visible_world_rect(active_camera).grow(margin).has_point(point)


func _get_camera() -> Camera2D:
	if camera != null:
		return camera

	var viewport := get_viewport()
	if viewport == null:
		return null

	return viewport.get_camera_2d()


func _get_visible_world_rect(active_camera: Camera2D) -> Rect2:
	if active_camera.has_method("get_visible_world_rect"):
		return active_camera.call("get_visible_world_rect")

	var viewport_rect := active_camera.get_viewport_rect()
	var visible_size := viewport_rect.size / active_camera.zoom
	return Rect2(active_camera.get_screen_center_position() - visible_size * 0.5, visible_size)
