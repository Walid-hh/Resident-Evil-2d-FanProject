class_name CameraStopArea extends Area2D

signal camera_stop_requested(stop_camera_x: float)
signal camera_stop_released(stop_camera_x: float)

const CAMERA_STOP_AREA_GROUP := "camera_stop_area"

@export var stop_camera_x := 0.0
@export var enabled := true

var _has_requested_stop := false


func _ready() -> void:
	add_to_group(CAMERA_STOP_AREA_GROUP)
	body_entered.connect(_on_body_entered)


func release_stop() -> void:
	if !_has_requested_stop:
		return

	_has_requested_stop = false
	camera_stop_released.emit(stop_camera_x)


func _on_body_entered(body: Node2D) -> void:
	if !enabled or _has_requested_stop or !body.is_in_group("player"):
		return

	_has_requested_stop = true
	camera_stop_requested.emit(stop_camera_x)
