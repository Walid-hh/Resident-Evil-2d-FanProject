class_name Weapon extends Node2D

@onready var anchor: Marker2D
@export var config: WeaponConfig

func _ready() -> void:
	add_to_group("weapons")
	anchor = get_parent() as Marker2D


func fire(direction: Vector2) -> void:
	var projectile_scene := get_projectile_scene()
	if projectile_scene == null:
		return

	_shoot(WeaponFireMath.apply_spread(direction, get_spread_degrees()), projectile_scene)


func _shoot(direction: Vector2, projectile_scene: PackedScene) -> void:
	var projectile := projectile_scene.instantiate()
	projectile.direction = direction
	projectile.global_transform = global_transform
	get_tree().root.add_child(projectile)


func get_weapon_key() -> StringName:
	if config == null or config.weapon_key == &"":
		return &"weapon"

	return config.weapon_key


func get_weapon_config() -> WeaponConfig:
	return config


func get_projectile_scene() -> PackedScene:
	if config == null:
		return null

	return config.projectile_scene


func get_spread_degrees() -> float:
	if config == null:
		return 0.0

	return config.spread_degrees
