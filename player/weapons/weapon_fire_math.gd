class_name WeaponFireMath extends Object

static func get_fire_direction(aim_direction: Vector2, fallback_direction: float) -> Vector2:
	var fire_direction := aim_direction.normalized()
	if fire_direction == Vector2.ZERO:
		fire_direction.x = fallback_direction
	return fire_direction


static func apply_anchor_rotation(anchor: Node2D, fire_direction: Vector2) -> void:
	if anchor == null:
		return

	anchor.global_rotation = fire_direction.angle()


static func apply_spread(fire_direction: Vector2, spread_degrees: float) -> Vector2:
	if spread_degrees == 0.0:
		return fire_direction

	return fire_direction.rotated(deg_to_rad(spread_degrees))
