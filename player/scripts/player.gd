class_name Player extends CharacterBody2D

# ── Exports ───────────────────────────────────────────────────────────────────
@export var acceleration := 1400.0
@export var deceleration := 2100.0
@export var max_speed    := 120.0
@export var fall_deceleration := 1000

@export_category("Jump")
@export var jump_height := 50.0
@export var jump_time_to_peak := 0.37
@export_range(50.0, 200.0) var jump_horizontal_distance := 80.0
@export var air_acceleration := 500.0
@export_range(0.1, 1.5) var jump_time_to_descent := 0.2
@export var max_fall_speed := 250.0
@export_range(5.0, 50.0) var jump_cut_divider := 15.0

# ── Node refs ─────────────────────────────────────────────────────────────────
@onready var legs: AnimatedSprite2D = %Legs
@onready var arms: AnimatedSprite2D = %Arms
@onready var body: AnimatedSprite2D = %Body
@onready var head: AnimatedSprite2D = %Head
@onready var anchor: Marker2D = %Anchor
@onready var handgun: Weapon = %Handgun
@onready var shotgun: Shotgun = %Shotgun
@onready var state_debug_label: Label = %StateDebugLabel
@onready var animation_debug_label: Label = %AnimationDebugLabel
@onready var coyote_timer := Timer.new()
@onready var jump_buffer  := Timer.new()

# ── Derived physics ───────────────────────────────────────────────────────────
@onready var jump_speed := calculate_jump_speed(jump_height, jump_time_to_peak)
@onready var jump_gravity := calculate_jump_gravity(jump_height, jump_time_to_peak)
@onready var fall_gravity := calculate_fall_gravity(jump_height, jump_time_to_descent)
@onready var jump_horizontal_speed := calculate_jump_horizontal_speed(jump_horizontal_distance, jump_time_to_peak, jump_time_to_descent)

# ── State ─────────────────────────────────────────────────────────────────────
enum State { GROUND, JUMP, FALL, AIM, CROUCH }

const ALLOWED_AIM_DIRECTIONS := [
	Vector2(-1, -0.8),
	Vector2( 0, -1),
	Vector2( 1, -0.8),
	Vector2(-1,  0),
	Vector2( 1,  0),
]

var current_state_name := "GROUND"
var current_state := State.GROUND
var current_gravity := 0.0
var direction_x := 0.0

# ── Weapon ────────────────────────────────────────────────────────────────────
var weapons_unlocked : Array[Weapon]
var weapon_in_use : Weapon

# ── Attack state ──────────────────────────────────────────────────────────────
var _is_firing := false
var _is_firing_animation_finished := true
var _attack_aim_direction := Vector2.ZERO

# ── Animation table ───────────────────────────────────────────────────────────
enum Animation_keys { IDLE, RUN, JUMP, FALL, AIM, CROUCH }
const animation_names : Array = [
	"idle", "run", "jump", "fall", "aim", "crouch",
]
var current_animation : String
const ANIMATIONS: Dictionary = {
	"idle":{ "body": "body_idle", "legs": "legs_idle", "head": "head_idle" },
	"run":{ "body": "body_run", "legs": "legs_run",  "head": "head_idle"  },
	"jump":{ "body": "body_jump" , "legs": "legs_jump" },
	"fall":{  "body": "body_fall", "legs": "legs_fall" },
	"aim":{ "body": "body_aim", "legs": "legs_idle", "head": "head_idle" },
	"crouch":{ "body": "body_crouch", "legs": "legs_crouch",  "head": "head_crouch" },
}
# ── Flags ─────────────────────────────────────────────────────────────────────
var is_moving := false

# ── Ready ─────────────────────────────────────────────────────────────────────
func _ready() -> void:
	weapon_in_use = handgun
	coyote_timer.wait_time = 0.12
	coyote_timer.one_shot  = true
	add_child(coyote_timer)

	jump_buffer.wait_time = 0.12
	jump_buffer.one_shot  = true
	add_child(jump_buffer)

	arms.animation_finished.connect(_on_attack_animation_finished.bind(arms.animation))

	_transition_to_state(current_state)
	_unlock_weapons()

# ── Main loop ─────────────────────────────────────────────────────────────────
func _physics_process(delta: float) -> void:
	animation_debug_label.text = arms.animation
	state_debug_label.text = current_state_name
	# Direction Input
	direction_x = signf(Input.get_axis("left", "right"))
	if direction_x != 0 and current_state != State.CROUCH:
		Global.player_last_direction = direction_x
	# State processor
	match current_state:
		State.GROUND: _process_ground(delta)
		State.JUMP:   _process_jump(delta)
		State.FALL:   _process_fall(delta)
		State.AIM:    _process_aim()
		State.CROUCH: _process_crouch()
	# Apply Gravity
	velocity.y += current_gravity * delta
	velocity.y  = minf(velocity.y, max_fall_speed)
	# Weapon Processor
	_process_weapon_in_use()
	# Weapon Fire on Input
	if Input.is_action_just_pressed("fire"):
		_start_attack()
	# Animation Update Every Frame
	_update_animations(current_animation)
	Global.player_aim_direction = _get_snapped_direction()
	# Weapon cycle on input
	if Input.is_action_just_pressed("next_weapon"):
		_cycle_next_unlocked_weapon()
		_update_animations(current_animation)
	if Input.is_action_just_pressed("previous_weapon"):
		_cycle_previous_unlocked_weapon()
		_update_animations(current_animation)
	move_and_slide()

# ── State processors ──────────────────────────────────────────────────────────
func _process_ground(delta: float) -> void:
	is_moving = absf(direction_x) > 0.0

	if is_moving:
		current_animation = animation_names[Animation_keys.RUN]
		velocity.x = clampf(velocity.x + direction_x * acceleration * delta, -max_speed, max_speed)
		_set_facing(direction_x)
	else:
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)
		if velocity == Vector2.ZERO :
			current_animation = animation_names[Animation_keys.IDLE]
	

	if !jump_buffer.is_stopped() or Input.is_action_just_pressed("jump"):
		_transition_to_state(State.JUMP)
	elif Input.is_action_pressed("aim"):
		_transition_to_state(State.AIM)
	elif Input.is_action_pressed("down"):
		if !_is_firing:
			_transition_to_state(State.CROUCH)
	elif !is_on_floor():
		_transition_to_state(State.FALL)


func _process_jump(delta: float) -> void:
	if direction_x != 0:
		velocity.x = clampf(velocity.x + air_acceleration * direction_x * delta, -jump_horizontal_speed, jump_horizontal_speed)
		_set_facing(direction_x)

	if velocity.y >= 0.0:
		_transition_to_state(State.FALL)

func _process_fall(delta: float) -> void:
	if direction_x != 0:
		velocity.x = clampf(velocity.x + air_acceleration * direction_x * delta, -jump_horizontal_speed, jump_horizontal_speed)
		_set_facing(direction_x)
	else :
		velocity.x = move_toward(velocity.x, 0.0, fall_deceleration * delta)
		

	if Input.is_action_just_pressed("jump"):
		jump_buffer.start()
		if !coyote_timer.is_stopped():
			_transition_to_state(State.JUMP)

	if is_on_floor():
		_transition_to_state(State.GROUND)

func _process_aim() -> void:
	if Input.is_action_just_released("aim"):
		_transition_to_state(State.GROUND)
	if direction_x != 0:
		_set_facing(direction_x)

func _process_crouch() -> void:
	if Input.is_action_just_released("down") and !_is_firing:
		_transition_to_state(State.GROUND)

# ── Transitions ───────────────────────────────────────────────────────────────
func _transition_to_state(new_state: State) -> void:
	_update_animations(current_animation)
	var previous_state := current_state
	current_state = new_state
	match previous_state:
		State.FALL: coyote_timer.stop()
		State.CROUCH: anchor.position.y = -8.0

	match current_state:
		State.GROUND:
			current_state_name = "GROUND"
		State.JUMP:
			current_state_name = "JUMP"
			velocity.y   = jump_speed
			velocity.x   = direction_x * jump_horizontal_speed
			current_gravity = jump_gravity
			current_animation = animation_names[Animation_keys.JUMP]
		State.FALL:
			current_state_name = "FALL"
			current_gravity = fall_gravity
			current_animation = animation_names[Animation_keys.FALL]
		State.AIM:
			current_state_name = "AIM"
			velocity.x = 0.0
			current_animation = animation_names[Animation_keys.AIM]
		State.CROUCH:
			current_state_name = "CROUCH"
			anchor.position.y = 2.0
			velocity.x = 0.0
			current_animation = animation_names[Animation_keys.CROUCH]



# ── Attack ────────────────────────────────────────────────────────────────────
func _start_attack() -> void:
	_attack_aim_direction = Global.player_aim_direction
	_is_firing = true
	_update_animations(current_animation)
	_is_firing_animation_finished = false

func _on_attack_animation_finished(anim_name: StringName) -> void:
	if _is_firing:
		_is_firing = false
		_is_firing_animation_finished = true
		# re-evaluate pending state exits that were blocked
		if current_state == State.CROUCH and !Input.is_action_pressed("down"):
			_transition_to_state(State.GROUND)

# ── Weapon ────────────────────────────────────────────────────────────────────
func _unlock_weapons() -> void:
	for weapon : Weapon in anchor.get_children():
		if weapon.get_is_weapon_unlocked():
			weapons_unlocked.append(weapon)
		else :
			weapon.set_physics_process(false)
		

func _process_weapon_in_use() -> void:
	for weapon in weapons_unlocked:
		if weapon != weapon_in_use:
			weapon.set_physics_process(false)
		else:
			weapon.set_physics_process(true)

func _cycle_next_unlocked_weapon() -> void:
	for weapon in weapons_unlocked:
		if weapon == weapon_in_use:
			var index = weapons_unlocked.find(weapon)
			var next_index = (index + 1) % weapons_unlocked.size()
			weapon_in_use = weapons_unlocked[next_index]
			break

func _cycle_previous_unlocked_weapon() -> void:
	for weapon in weapons_unlocked:
		if weapon == weapon_in_use:
			var index = weapons_unlocked.find(weapon)
			var previous_index = (index - 1) % weapons_unlocked.size()
			weapon_in_use = weapons_unlocked[previous_index]
			break

# ── Animation ─────────────────────────────────────────────────────────────────
func _update_animations(key : String) -> void:
	var anims: Dictionary = ANIMATIONS.get(key, {})
	for part_name in ["legs", "body", "head"]:
		if anims.has(part_name):
			(get(part_name) as AnimatedSprite2D).play(anims[part_name])
	if current_state != State.CROUCH:
		match Global.player_aim_direction:
			Vector2.UP:
				head.play("head_up")
			Vector2.DOWN:
				head.play("head_down")
	if weapon_in_use == handgun and _is_firing_animation_finished:
		if current_state != State.CROUCH and !_is_firing:
			match Global.player_aim_direction:
				Vector2.RIGHT: 
					arms.play("arms_hg_right")
				Vector2.LEFT: arms.play("arms_hg_right")
				Vector2(1, -0.8): 
					arms.play("arms_hg_diagonal_up")
				Vector2(-1, -0.8): 
					arms.play("arms_hg_diagonal_up")
				Vector2.UP: 
					arms.play("arms_hg_up")
				Vector2.DOWN: 
					arms.play("arms_hg_down")
				_:if current_state != State.AIM:
					arms.play("arms_hg_idle")
				else:
					arms.play("arms_hg_right")
		elif current_state == State.CROUCH and !_is_firing:
			arms.play("arms_hg_crouch")
		elif current_state == State.CROUCH and _is_firing:
			arms.play("arms_hg_crouch_fire")
		elif _is_firing:
			match Global.player_aim_direction:
				Vector2.RIGHT: arms.play("arms_hg_right_fire")
				Vector2.LEFT: arms.play("arms_hg_right_fire")
				Vector2(1, -0.8): 
					arms.play("arms_hg_diagonal_up_fire")
				Vector2(-1, -0.8): 
					arms.play("arms_hg_diagonal_up_fire")
				Vector2.UP: 
					arms.play("arms_hg_up_fire")
				Vector2.DOWN: 
					arms.play("arms_hg_down_fire")
				_:arms.play("arms_hg_right_fire")
	elif weapon_in_use == shotgun and _is_firing_animation_finished:
		if current_state != State.CROUCH and !_is_firing:
			match Global.player_aim_direction:
				Vector2.RIGHT: 
					arms.play("arms_sg_right")
				Vector2.LEFT: arms.play("arms_sg_right")
				Vector2(1, -0.8): 
					arms.play("arms_sg_diagonal_up")
				Vector2(-1, -0.8): 
					arms.play("arms_sg_diagonal_up")
				Vector2.UP: 
					arms.play("arms_sg_up")
				Vector2.DOWN: 
					arms.play("arms_sg_down")
				_:if current_state != State.AIM:
					arms.play("arms_sg_idle")
				else:
					arms.play("arms_sg_right")
		elif current_state == State.CROUCH and !_is_firing:
			arms.play("arms_sg_crouch")
		elif current_state == State.CROUCH and _is_firing:
			arms.play("arms_sg_crouch_fire")
		elif _is_firing:
			match Global.player_aim_direction:
				Vector2.RIGHT: arms.play("arms_sg_right_fire")
				Vector2.LEFT: arms.play("arms_sg_right_fire")
				Vector2(1, -0.8): 
					arms.play("arms_sg_diagonal_up_fire")
				Vector2(-1, -0.8): 
					arms.play("arms_sg_diagonal_up_fire")
				Vector2.UP: 
					arms.play("arms_sg_up_fire")
				Vector2.DOWN: 
					arms.play("arms_sg_down_fire")
				_:arms.play("arms_sg_right_fire")

# ── Helpers ───────────────────────────────────────────────────────────────────
func _set_facing(dir: float) -> void:
	var flip := dir < 0.0
	for part: AnimatedSprite2D in [legs, arms, body, head]:
		part.flip_h = flip

func _get_snapped_direction() -> Vector2:
	var raw := Input.get_vector("left", "right", "up", "down")
	var allowed := ALLOWED_AIM_DIRECTIONS.duplicate()
	if raw.length() < 0.2:
		return Vector2.ZERO
	if current_state != State.JUMP and raw == Vector2.DOWN:
		return Vector2.ZERO
	elif current_state == State.CROUCH:
		if arms.flip_h:
			return Vector2(-1, 0)
		else:
			return Vector2(1, 0)
	var best_dir := Vector2.ZERO
	var best_dot := -INF
	for dir in allowed:
		var dot := raw.dot(dir.normalized())
		if dot > best_dot:
			best_dot = dot
			best_dir = dir
	return best_dir

# ── Physics helpers ───────────────────────────────────────────────────────────
func calculate_jump_speed(height: float, time_to_peak: float) -> float:
	return (-2.0 * height) / time_to_peak

func calculate_jump_gravity(height: float, time_to_peak: float) -> float:
	return (2.0 * height) / pow(time_to_peak, 2.0)

func calculate_fall_gravity(height: float, time_to_descent: float) -> float:
	return (2.0 * height) / pow(time_to_descent, 2.0)

func calculate_jump_horizontal_speed(distance: float, time_to_peak: float, time_to_descent: float) -> float:
	return distance / (time_to_peak + time_to_descent)

# ── Var Exposers ──────────────────────────────────────────────────────────────
func get_weapon_in_use() -> Weapon:
	return weapon_in_use

func get_weapons_unlocked() -> Array[Weapon]:
	return weapons_unlocked
