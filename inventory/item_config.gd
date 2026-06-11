class_name ItemConfig extends Resource

@export var item_key: StringName = &"item"
@export var display_name := ""
@export_range(1, 64, 1) var width := 1
@export_range(1, 64, 1) var height := 1
@export var can_rotate := true
@export var icon_texture: Texture2D


func is_valid() -> bool:
	return width > 0 and height > 0


func get_size(rotated := false) -> Vector2i:
	if rotated and can_rotate:
		return Vector2i(height, width)

	return Vector2i(width, height)
