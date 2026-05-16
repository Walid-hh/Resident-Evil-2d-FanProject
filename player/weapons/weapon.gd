class_name Weapon extends Node2D

@onready var anchor: Marker2D
@export var projectile_scene : PackedScene
var is_weapon_unlocked := false

func _ready() -> void:
	add_to_group("weapons")
	anchor = get_parent()


func _shoot() -> void :
	pass

func get_is_weapon_unlocked() -> bool :
	return is_weapon_unlocked
