class_name EnemyRangedAttackController extends EnemyAttackController

signal projectile_fired(projectile: Projectile)

@export var projectile_spawn: Marker2D
@export var camera_visibility: EnemyCameraVisibility


func has_attack_opportunity(
	_body: CharacterBody2D,
	target: Node2D,
	config: EnemyConfig,
	_sensing: EnemySensing
) -> bool:
	var ranged_config := config as RangedEnemyConfig
	if target == null or ranged_config == null or projectile_spawn == null:
		return false
	if ranged_config.projectile_scene == null:
		return false
	if camera_visibility == null or !camera_visibility.is_point_visible(projectile_spawn.global_position):
		return false

	return projectile_spawn.global_position.distance_to(target.global_position) <= ranged_config.attack_range


func start_attack(_body: CharacterBody2D, target: Node2D, config: EnemyConfig) -> void:
	var ranged_config := config as RangedEnemyConfig
	if target == null or ranged_config == null:
		attack_finished.emit()
		return

	_fire_projectile(target, ranged_config)
	attack_finished.emit()


func _fire_projectile(target: Node2D, config: RangedEnemyConfig) -> void:
	if projectile_spawn == null or config.projectile_scene == null:
		return

	var projectile := config.projectile_scene.instantiate() as Projectile
	if projectile == null:
		return

	projectile.direction = projectile_spawn.global_position.direction_to(target.global_position)
	projectile.global_position = projectile_spawn.global_position
	projectile.global_rotation = projectile.direction.angle()
	get_tree().root.call_deferred("add_child", projectile)
	projectile_fired.emit(projectile)
