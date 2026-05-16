class_name Mob extends CharacterBody2D

# ── Exports ───────────────────────────────────────────────────────────────────
@export var acceleration := 1400.0
@export var max_speed    := 80.0
# ── Node refs ─────────────────────────────────────────────────────────────────
@onready var animated_sprite_2d: AnimatedSprite2D = %AnimatedSprite2D
@onready var activation_area: Area2D = %ActivationArea
@onready var attack_area: Area2D = %AttackArea
@onready var state_debug_label: Label = %StateDebugLabel
@onready var attack_enabler: AnimationPlayer = %AttackEnabler
@onready var wait_timer: Timer = %WaitTimer
@onready var attack: HitBox2D = %Attack

# ── State ─────────────────────────────────────────────────────────────────────
enum State {INACTIVE, RUN, ATTACK, DIE, WAIT}
var current_state_name := "INACTIVE"
var current_state := State.INACTIVE


# ── Flags ─────────────────────────────────────────────────────────────────────
@export var jump_height := 50.0
@export_range(0.1, 1.5) var jump_time_to_descent := 0.2
@onready var fall_gravity := calculate_fall_gravity(jump_height, jump_time_to_descent)
# ── Helper Vars ───────────────────────────────────────────────────────────────
var player : Player
var direction_to_player : float

# ── Ready ─────────────────────────────────────────────────────────────────────
func _ready() -> void:
	_find_player()
	activation_area.monitoring = true
	attack_area.monitoring = false
	activation_area.body_entered.connect(
		func(body_that_entered) -> void:
			if body_that_entered == player :
				_transition_to_state(State.RUN)
)
	attack_area.body_entered.connect(func(body_that_entered) -> void:
			if body_that_entered == player :
				_transition_to_state(State.ATTACK)
				)
	attack_enabler.animation_finished.connect(func(anim) -> void :
		_transition_to_state(State.WAIT)
		)
	wait_timer.timeout.connect(func() -> void:
		_transition_to_state(State.INACTIVE)
		)
	Global.player_died.connect(func() -> void:
		_transition_to_state(State.INACTIVE)
		)



# ── Main loop ─────────────────────────────────────────────────────────────────
func _physics_process(delta: float) -> void:
	print(attack.monitoring , "   ", attack.monitorable)
	state_debug_label.text = current_state_name
	direction_to_player = global_position.direction_to(player.global_position).x
	_set_facing(direction_to_player)
	match current_state:
		State.INACTIVE: _process_inactive()
		State.RUN: _process_run(delta)
		State.ATTACK: _process_attack()
	velocity.y += fall_gravity * delta
	move_and_slide()
	
# ── State processors ──────────────────────────────────────────────────────────
func _process_inactive() -> void:
	pass

func _process_run(delta: float) -> void:
	velocity.x = clampf(velocity.x + direction_to_player * acceleration * delta, -max_speed, max_speed)
	
func _process_attack() -> void :
	attack_enabler.play("attack")



# ── Transitions ───────────────────────────────────────────────────────────────
func _transition_to_state(new_state: State) -> void:
	var previous_state := current_state
	current_state = new_state
	match previous_state:
		State.INACTIVE:
			activation_area.set_deferred("monitoring", false)
		State.RUN:
			attack_area.set_deferred("monitoring", false)
	match current_state:
		State.INACTIVE:
			current_state_name = "INACTIVE"
			activation_area.set_deferred("monitoring", true)
		State.RUN:
			current_state_name = "RUN"
			attack_area.set_deferred("monitoring", true)
			animated_sprite_2d.play("run")
		State.ATTACK:
			velocity = Vector2.ZERO
			current_state_name = "ATTACK"
			animated_sprite_2d.play("attack")
		State.WAIT:
			current_state_name = "WAIT"
			wait_timer.start()
			animated_sprite_2d.play("idle")

# ── Helpers ───────────────────────────────────────────────────────────────────
func _set_facing(dir: float) -> void:
	var flip := dir < 0.0
	animated_sprite_2d.flip_h = flip

func _find_player() -> void:
	player = get_tree().get_first_node_in_group("player")

# ── Physics Helpers ───────────────────────────────────────────────────────────
func calculate_fall_gravity(height: float, time_to_descent: float) -> float:
	return (2.0 * height) / pow(time_to_descent, 2.0)
