@tool
class_name CameraBounds extends Node2D

const CAMERA_BOUNDS_GROUP := "camera_bounds"
const EDITOR_FILL_COLOR := Color(0.1, 0.8, 1.0, 0.08)
const EDITOR_OUTLINE_COLOR := Color(0.1, 0.8, 1.0, 0.85)

@export var bounds := Rect2(-120, -16, 2000, 180):
	set(value):
		bounds = value
		queue_redraw()


func _ready() -> void:
	add_to_group(CAMERA_BOUNDS_GROUP)
	queue_redraw()


func _draw() -> void:
	if !Engine.is_editor_hint():
		return

	draw_rect(bounds, EDITOR_FILL_COLOR, true)
	draw_rect(bounds, EDITOR_OUTLINE_COLOR, false, 1.0)


func get_camera_bounds() -> Rect2:
	return bounds
