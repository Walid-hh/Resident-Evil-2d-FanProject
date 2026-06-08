class_name Shotgun extends Weapon

func _ready() -> void:
	super._ready()
	add_to_group("shotgun")
	is_weapon_unlocked = true


func get_weapon_key() -> StringName:
	return &"shotgun"
