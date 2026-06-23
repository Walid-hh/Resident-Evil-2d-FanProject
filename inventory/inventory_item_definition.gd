class_name InventoryItemDefinition extends Resource

enum ItemType {
	NONE,
	AMMO,
	HEALING,
	KEY,
}

@export var item_key: StringName = &"item"
@export var display_name := ""
@export var item_type := ItemType.NONE
@export var icon_texture: Texture2D
@export_range(0, 999, 1) var max_quantity := 1


func is_valid() -> bool:
	return item_key != &"" and max_quantity >= 0


func get_max_quantity() -> int:
	return maxi(max_quantity, 0)
