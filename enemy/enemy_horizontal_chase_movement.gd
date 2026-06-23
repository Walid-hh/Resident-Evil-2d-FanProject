class_name EnemyHorizontalChaseMovement extends Node


func chase(body: CharacterBody2D, target: Node2D, delta: float, config: EnemyConfig) -> void:
	if body == null or target == null or config == null:
		return

	var direction_x := body.global_position.direction_to(target.global_position).x
	body.velocity.x = clampf(
		body.velocity.x + direction_x * config.acceleration * delta,
		-config.max_speed,
		config.max_speed
	)


func stop(body: CharacterBody2D) -> void:
	if body == null:
		return
	body.velocity.x = 0.0


func apply_gravity(body: CharacterBody2D, delta: float, config: EnemyConfig) -> void:
	if body == null or config == null:
		return
	body.velocity.y += calculate_fall_gravity(config.jump_height, config.jump_time_to_descent) * delta


func calculate_fall_gravity(height: float, time_to_descent: float) -> float:
	return (2.0 * height) / pow(time_to_descent, 2.0)
