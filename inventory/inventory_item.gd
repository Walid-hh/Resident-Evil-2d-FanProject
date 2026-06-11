class_name InventoryItem extends RefCounted

var instance_id: StringName
var config: Resource
var origin := Vector2i.ZERO
var rotated := false


func _init(
	p_instance_id: StringName = &"",
	p_config: Resource = null,
	p_origin := Vector2i.ZERO,
	p_rotated := false
) -> void:
	instance_id = p_instance_id
	config = p_config
	origin = p_origin
	rotated = p_rotated


func get_size() -> Vector2i:
	if config == null:
		return Vector2i.ZERO

	return config.get_size(rotated)


func get_occupied_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var size := get_size()

	for y in range(size.y):
		for x in range(size.x):
			cells.append(origin + Vector2i(x, y))

	return cells
