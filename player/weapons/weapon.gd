class_name Weapon extends Node2D

@onready var anchor: Marker2D
@export var projectile_scene : PackedScene
@export var fire_rate : float = 1.0
var is_weapon_unlocked := false
var fire_timer : float

func _ready() -> void:
	add_to_group("weapons")
	anchor = get_parent()
	fire_timer = fire_rate


func tick_cooldown(delta: float) -> void:
	fire_timer += delta


func can_fire() -> bool:
	return fire_timer >= fire_rate


func fire(direction: Vector2) -> void:
	if !can_fire():
		return

	_shoot(direction)
	fire_timer = 0.0


func _shoot(direction: Vector2) -> void:
	var projectile := projectile_scene.instantiate()
	projectile.direction = direction
	projectile.global_transform = global_transform
	get_tree().root.add_child(projectile)


func get_weapon_key() -> StringName:
	return &"weapon"

func get_is_weapon_unlocked() -> bool :
	return is_weapon_unlocked
