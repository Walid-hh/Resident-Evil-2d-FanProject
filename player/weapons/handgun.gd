class_name Handgun extends Weapon

func _ready() -> void:
	super._ready()
	add_to_group("handgun")
	is_weapon_unlocked = true


func get_weapon_key() -> StringName:
	return &"handgun"
