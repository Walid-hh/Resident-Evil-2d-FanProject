extends GutTest

const MELEE_ENEMY_SCENE := preload("res://enemy/melee_enemy.tscn")
const RANGED_ENEMY_SCENE := preload("res://enemy/ranged_enemy.tscn")
const PLAYER_CAMERA_SCRIPT := preload("res://player/camera/player_camera.gd")

var _player: CharacterBody2D
var _enemy: MeleeEnemy
var _spawned_projectiles: Array[Node] = []


func before_each() -> void:
	_player = add_child_autofree(CharacterBody2D.new())
	_player.add_to_group("player")
	_player.global_position = Vector2(64, 0)
	_enemy = add_child_autofree(MELEE_ENEMY_SCENE.instantiate())
	_enemy.global_position = Vector2.ZERO


func after_each() -> void:
	for projectile: Node in _spawned_projectiles:
		if is_instance_valid(projectile):
			projectile.queue_free()
	_spawned_projectiles.clear()


func test_melee_enemy_starts_inactive() -> void:
	assert_eq(_enemy.get_state(), Enemy.State.INACTIVE)
	assert_eq(_enemy.get_state_name(), "INACTIVE")


func test_activation_transitions_to_chase() -> void:
	_enemy.sensing.player_activated.emit()

	assert_eq(_enemy.get_state(), Enemy.State.CHASE)
	assert_eq(_enemy.get_state_name(), "CHASE")


func test_attack_finishes_into_recover() -> void:
	_enemy.sensing.player_activated.emit()
	_enemy.sensing.player_entered_attack_range.emit()

	assert_eq(_enemy.get_state(), Enemy.State.ATTACK)
	assert_true(_enemy.melee_attack.is_attacking())

	_enemy.melee_attack._on_animation_finished(&"attack")

	assert_eq(_enemy.get_state(), Enemy.State.RECOVER)
	assert_false(_enemy.melee_attack.is_attacking())
	await wait_process_frames(1)
	assert_false(_enemy.melee_attack.attack_hit_box.monitoring)


func test_recovery_returns_to_chase_when_player_is_valid() -> void:
	_enemy.sensing.player_activated.emit()
	_enemy.sensing.player_entered_attack_range.emit()
	_enemy.melee_attack._on_animation_finished(&"attack")
	_enemy.sensing._on_attack_body_exited(_player)

	_enemy._on_recovery_timeout()

	assert_eq(_enemy.get_state(), Enemy.State.CHASE)


func test_attack_range_enter_does_not_interrupt_recovery() -> void:
	_enemy.sensing.player_activated.emit()
	_enemy.sensing.player_entered_attack_range.emit()
	_enemy.melee_attack._on_animation_finished(&"attack")

	_enemy.sensing._on_attack_body_entered(_player)

	assert_eq(_enemy.get_state(), Enemy.State.RECOVER)


func test_player_death_returns_enemy_to_inactive() -> void:
	_enemy.sensing.player_activated.emit()

	Global.player_died.emit()

	assert_eq(_enemy.get_state(), Enemy.State.INACTIVE)
	await wait_process_frames(1)
	assert_false(_enemy.melee_attack.attack_hit_box.monitoring)


func test_attack_start_defers_hit_box_physics_property_changes() -> void:
	_enemy.melee_attack.attack_hit_box.monitoring = true
	_enemy.melee_attack.attack_hit_box.monitorable = true

	_enemy.sensing.player_activated.emit()
	_enemy.sensing.player_entered_attack_range.emit()

	assert_true(_enemy.melee_attack.attack_hit_box.monitoring)
	assert_true(_enemy.melee_attack.attack_hit_box.monitorable)

	await wait_process_frames(1)

	assert_false(_enemy.melee_attack.attack_hit_box.monitoring)
	assert_false(_enemy.melee_attack.attack_hit_box.monitorable)


func test_enemy_death_enters_death_once_and_emits_compat_signal() -> void:
	watch_signals(Global)

	_enemy.health_component.take_damage(_enemy.health_component.health)
	_enemy.health_component.take_damage(1)

	assert_eq(_enemy.get_state(), Enemy.State.DEATH)
	assert_signal_emit_count(Global, "enemy_died", 1)
	assert_true(_enemy.is_queued_for_deletion())


func test_melee_enemy_scene_has_required_components() -> void:
	assert_not_null(_enemy.config)
	assert_not_null(_enemy.sensing)
	assert_not_null(_enemy.movement)
	assert_not_null(_enemy.attack_controller)
	assert_true(_enemy.attack_controller is EnemyMeleeAttackController)
	assert_not_null(_enemy.melee_attack)
	assert_not_null(_enemy.melee_attack.attack_hit_box)
	assert_not_null(_enemy.melee_attack.attack_enabler)


func test_damage_flags_match_player_and_enemy_hurt_boxes() -> void:
	var enemy_hurt_box := _enemy.get_node("HurtBox2D") as HurtBox2D
	var enemy_attack := _enemy.get_node("Attack") as HitBox2D
	var player_scene := add_child_autofree(load("res://player/player.tscn").instantiate())
	var player_hurt_box := player_scene.get_node("HurtBox2D") as HurtBox2D
	var handgun_bullet := add_child_autofree(load("res://player/weapons/projectiles/handgun_bullet.tscn").instantiate())
	var player_projectile_hit_box := handgun_bullet.get_node("HitBox2D") as HitBox2D

	assert_eq(enemy_attack.damage_source, HitBox2D.DAMAGE_SOURCE_ENEMY)
	assert_true((enemy_attack.detected_hurtboxes & HurtBox2D.DAMAGE_SOURCE_PLAYER) != 0)
	assert_true((player_hurt_box.damage_source & HitBox2D.DAMAGE_SOURCE_ENEMY) != 0)
	assert_eq(enemy_hurt_box.hurtbox_type, HurtBox2D.DAMAGE_SOURCE_ENEMY)
	assert_true((enemy_hurt_box.damage_source & HitBox2D.DAMAGE_SOURCE_PLAYER) != 0)
	assert_true((player_projectile_hit_box.detected_hurtboxes & HurtBox2D.DAMAGE_SOURCE_ENEMY) != 0)


func test_ranged_enemy_scene_has_required_components() -> void:
	var ranged_enemy := _add_ranged_enemy()

	assert_not_null(ranged_enemy.config)
	assert_true(ranged_enemy.config is RangedEnemyConfig)
	assert_not_null(ranged_enemy.sensing)
	assert_not_null(ranged_enemy.movement)
	assert_not_null(ranged_enemy.attack_controller)
	assert_true(ranged_enemy.attack_controller is EnemyRangedAttackController)
	assert_not_null(ranged_enemy.ranged_attack.projectile_spawn)
	assert_not_null(ranged_enemy.ranged_attack.camera_visibility)
	assert_not_null((ranged_enemy.config as RangedEnemyConfig).projectile_scene)


func test_ranged_enemy_activation_transitions_to_chase() -> void:
	var ranged_enemy := _add_ranged_enemy()
	_assign_visible_camera(ranged_enemy, Rect2(-160, -90, 320, 180))
	_player.global_position = Vector2(400, 0)

	ranged_enemy.sensing.player_activated.emit()

	assert_eq(ranged_enemy.get_state(), Enemy.State.CHASE)


func test_ranged_enemy_chases_when_player_is_out_of_attack_range() -> void:
	var ranged_enemy := _add_ranged_enemy()
	var fired_projectiles := _watch_ranged_projectiles(ranged_enemy)
	_assign_visible_camera(ranged_enemy, Rect2(-160, -90, 320, 180))
	_player.global_position = Vector2(400, 0)

	ranged_enemy.sensing.player_activated.emit()
	ranged_enemy._physics_process(0.1)

	assert_eq(ranged_enemy.get_state(), Enemy.State.CHASE)
	assert_gt(ranged_enemy.velocity.x, 0.0)
	assert_true(fired_projectiles.is_empty())


func test_ranged_enemy_does_not_attack_when_spawn_point_is_outside_camera() -> void:
	var ranged_enemy := _add_ranged_enemy()
	var fired_projectiles := _watch_ranged_projectiles(ranged_enemy)
	_assign_visible_camera(ranged_enemy, Rect2(500, -90, 320, 180))
	_player.global_position = Vector2(64, 0)

	ranged_enemy.sensing.player_activated.emit()
	ranged_enemy._physics_process(0.1)

	assert_eq(ranged_enemy.get_state(), Enemy.State.CHASE)
	assert_true(fired_projectiles.is_empty())


func test_ranged_enemy_fires_once_and_recovers_when_in_range_and_visible() -> void:
	var ranged_enemy := _add_ranged_enemy()
	var fired_projectiles := _watch_ranged_projectiles(ranged_enemy)
	_assign_visible_camera(ranged_enemy, Rect2(-160, -90, 320, 180))
	_player.global_position = Vector2(64, 0)

	ranged_enemy.sensing.player_activated.emit()

	assert_eq(ranged_enemy.get_state(), Enemy.State.RECOVER)
	assert_eq(fired_projectiles.size(), 1)
	var projectile := fired_projectiles[0]
	assert_not_null(projectile)
	assert_almost_eq(projectile.direction.x, 0.9445, 0.001)
	assert_almost_eq(projectile.direction.y, 0.3285, 0.001)


func test_ranged_enemy_projectile_damage_flags_target_player_hurt_box() -> void:
	var ranged_enemy := _add_ranged_enemy()
	var projectile_scene := (ranged_enemy.config as RangedEnemyConfig).projectile_scene
	var projectile := add_child_autofree(projectile_scene.instantiate())
	var hit_box := projectile.get_node("HitBox2D") as HitBox2D
	var player_scene := add_child_autofree(load("res://player/player.tscn").instantiate())
	var player_hurt_box := player_scene.get_node("HurtBox2D") as HurtBox2D

	assert_eq(hit_box.damage_source, HitBox2D.DAMAGE_SOURCE_ENEMY)
	assert_true((hit_box.detected_hurtboxes & HurtBox2D.DAMAGE_SOURCE_PLAYER) != 0)
	assert_true((player_hurt_box.damage_source & HitBox2D.DAMAGE_SOURCE_ENEMY) != 0)


func test_enemy_camera_visibility_uses_player_camera_visible_world_rect() -> void:
	var visibility := add_child_autofree(EnemyCameraVisibility.new())
	var camera := add_child_autofree(PLAYER_CAMERA_SCRIPT.new())
	camera.viewport_size = Vector2(320, 180)
	camera.global_position = Vector2(100, 50)
	camera.make_current()
	visibility.camera = camera

	assert_true(visibility.is_point_visible(Vector2(100, 50)))
	assert_false(visibility.is_point_visible(Vector2(400, 50)))


func _add_ranged_enemy() -> RangedEnemy:
	var ranged_enemy := add_child_autofree(RANGED_ENEMY_SCENE.instantiate()) as RangedEnemy
	ranged_enemy.global_position = Vector2.ZERO
	return ranged_enemy


func _assign_visible_camera(ranged_enemy: RangedEnemy, visible_rect: Rect2) -> void:
	var camera := add_child_autofree(PLAYER_CAMERA_SCRIPT.new())
	camera.viewport_size = visible_rect.size
	camera.global_position = visible_rect.get_center()
	camera.make_current()
	ranged_enemy.camera_visibility.camera = camera


func _watch_ranged_projectiles(ranged_enemy: RangedEnemy) -> Array[Projectile]:
	var projectiles: Array[Projectile] = []
	ranged_enemy.ranged_attack.projectile_fired.connect(func(projectile: Projectile) -> void:
		projectiles.append(projectile)
		_spawned_projectiles.append(projectile)
	)
	return projectiles
