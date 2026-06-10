class_name CameraBounds extends Node2D

const CAMERA_BOUNDS_GROUP := "camera_bounds"

@export var bounds := Rect2(-120, -16, 2000, 180)


func _ready() -> void:
	add_to_group(CAMERA_BOUNDS_GROUP)


func get_camera_bounds() -> Rect2:
	return bounds
