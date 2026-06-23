class_name Enemy extends CharacterBody2D

enum State { INACTIVE, CHASE, ATTACK, RECOVER, DEATH }

@export var config: EnemyConfig

@onready var animated_sprite_2d: AnimatedSprite2D = %AnimatedSprite2D
@onready var state_debug_label: Label = %StateDebugLabel
@onready var health_component: HealthComponent = %HealthComponent
@onready var sensing: EnemySensing = %EnemySensing
@onready var movement: EnemyHorizontalChaseMovement = %EnemyHorizontalChaseMovement
@onready var attack_controller: EnemyAttackController = %EnemyAttackController
@onready var recovery_timer: Timer = %RecoveryTimer

var current_state := State.INACTIVE
var current_state_name := "INACTIVE"
var target: Node2D = null


func _ready() -> void:
	if config == null:
		config = EnemyConfig.new()

	target = get_tree().get_first_node_in_group("player") as Node2D
	health_component.set_max_health(config.max_health)
	health_component.set_health(config.max_health)

	sensing.target = target
	sensing.player_activated.connect(func() -> void:
		_transition_to_state(State.CHASE)
	)
	sensing.player_entered_attack_range.connect(func() -> void:
		_try_transition_to_attack()
	)
	attack_controller.attack_finished.connect(func() -> void:
		_transition_to_state(State.RECOVER)
	)
	recovery_timer.timeout.connect(_on_recovery_timeout)
	health_component.died.connect(_on_died)
	Global.player_died.connect(_on_player_died)
	_transition_to_state(State.INACTIVE)


func _physics_process(delta: float) -> void:
	_update_debug_label()
	_update_facing()

	match current_state:
		State.CHASE:
			movement.chase(self, target, delta, config)
			_try_transition_to_attack()

	movement.apply_gravity(self, delta, config)
	move_and_slide()


func get_state() -> State:
	return current_state


func get_state_name() -> String:
	return current_state_name


func _transition_to_state(new_state: State) -> void:
	if current_state == State.DEATH:
		return
	if current_state == new_state:
		return

	_exit_state(current_state)
	current_state = new_state
	_enter_state(current_state)


func _exit_state(state: State) -> void:
	match state:
		State.ATTACK:
			attack_controller.cancel_attack()


func _enter_state(state: State) -> void:
	match state:
		State.INACTIVE:
			current_state_name = "INACTIVE"
			movement.stop(self)
			sensing.set_inactive_mode()
			_play_animation(config.inactive_animation)
		State.CHASE:
			current_state_name = "CHASE"
			sensing.set_chase_mode()
			_play_animation(config.chase_animation)
			_try_transition_to_attack()
		State.ATTACK:
			current_state_name = "ATTACK"
			movement.stop(self)
			sensing.set_attack_mode()
			_play_animation(config.attack_animation)
			attack_controller.start_attack(self, target, config)
		State.RECOVER:
			current_state_name = "RECOVER"
			movement.stop(self)
			sensing.set_attack_mode()
			_play_animation(config.recovery_animation)
			recovery_timer.start(config.recovery_time)
		State.DEATH:
			current_state_name = "DEATH"
			movement.stop(self)
			sensing.set_disabled_mode()
			attack_controller.cancel_attack()
			_play_animation(config.death_animation)


func _on_recovery_timeout() -> void:
	if current_state != State.RECOVER:
		return
	if target == null or !is_instance_valid(target):
		_transition_to_state(State.INACTIVE)
		return
	_transition_to_state(State.ATTACK if _has_attack_opportunity() else State.CHASE)


func _on_player_died() -> void:
	_transition_to_state(State.INACTIVE)


func _on_died(_source: Variant) -> void:
	if current_state == State.DEATH:
		return

	_exit_state(current_state)
	current_state = State.DEATH
	_enter_state(current_state)
	Global.enemy_died.emit(self)
	queue_free()


func _try_transition_to_attack() -> void:
	if current_state != State.CHASE:
		return
	if _has_attack_opportunity():
		_transition_to_state(State.ATTACK)


func _has_attack_opportunity() -> bool:
	if attack_controller == null:
		return false
	if target == null or !is_instance_valid(target):
		return false
	return attack_controller.has_attack_opportunity(self, target, config, sensing)


func _update_facing() -> void:
	if target == null or !is_instance_valid(target):
		return

	var direction_x := global_position.direction_to(target.global_position).x
	if !is_zero_approx(direction_x):
		animated_sprite_2d.flip_h = direction_x < 0.0


func _update_debug_label() -> void:
	if state_debug_label != null:
		state_debug_label.text = current_state_name


func _play_animation(animation_name: StringName) -> void:
	if animated_sprite_2d == null or animation_name == &"":
		return
	if animated_sprite_2d.sprite_frames == null:
		return
	if !animated_sprite_2d.sprite_frames.has_animation(animation_name):
		return
	if animated_sprite_2d.animation != animation_name:
		animated_sprite_2d.play(animation_name)
