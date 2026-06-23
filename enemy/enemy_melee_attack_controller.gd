class_name EnemyMeleeAttackController extends EnemyAttackController


@export var attack_hit_box: HitBox2D
@export var attack_enabler: AnimationPlayer

var _is_attacking := false


func _ready() -> void:
	disable_attack_hit_box()
	if attack_enabler != null:
		attack_enabler.animation_finished.connect(_on_animation_finished)


func start_attack(_body: CharacterBody2D, _target: Node2D, config: EnemyConfig) -> void:
	if _is_attacking:
		return

	_is_attacking = true
	disable_attack_hit_box()
	if attack_enabler != null:
		attack_enabler.play(config.attack_animation if config != null else &"")


func cancel_attack() -> void:
	_is_attacking = false
	disable_attack_hit_box()
	if attack_enabler != null:
		attack_enabler.stop()


func is_attacking() -> bool:
	return _is_attacking


func disable_attack_hit_box() -> void:
	if attack_hit_box == null:
		return
	attack_hit_box.set_deferred("monitoring", false)
	attack_hit_box.set_deferred("monitorable", false)
	attack_hit_box.visible = false


func _on_animation_finished(_animation_name: StringName) -> void:
	if !_is_attacking:
		return

	_is_attacking = false
	disable_attack_hit_box()
	attack_finished.emit()
