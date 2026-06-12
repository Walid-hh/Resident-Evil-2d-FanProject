class_name ItemConfig extends Resource

enum ItemType {
	NONE,
	AMMO,
	HEALING,
	KEY,
}

@export var item_key: StringName = &"item"
@export var display_name := ""
@export var item_type := ItemType.NONE
@export_range(1, 64, 1) var width := 1
@export_range(1, 64, 1) var height := 1
@export var can_rotate := true
@export var icon_texture: Texture2D
@export var stackable := false
@export_range(1, 999, 1) var max_stack_quantity := 1


func is_valid() -> bool:
	return width > 0 and height > 0 and max_stack_quantity > 0


func get_size(rotated := false) -> Vector2i:
	if rotated and can_rotate:
		return Vector2i(height, width)

	return Vector2i(width, height)


func get_max_stack_quantity() -> int:
	if !stackable:
		return 1

	return maxi(max_stack_quantity, 1)
