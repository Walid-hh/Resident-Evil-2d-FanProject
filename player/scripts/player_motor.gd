class_name PlayerMotor extends Node

enum State { GROUND, JUMP, FALL, AIM, CROUCH }

const ANIMATION_IDLE := "idle"
const ANIMATION_RUN := "run"
const ANIMATION_JUMP := "jump"
const ANIMATION_FALL := "fall"
const ANIMATION_AIM := "aim"
const ANIMATION_CROUCH := "crouch"

@export var acceleration := 1400.0
@export var deceleration := 2100.0
@export var max_speed := 120.0
@export var fall_deceleration := 1000.0

@export_category("Jump")
@export var jump_height := 50.0
@export var jump_time_to_peak := 0.37
@export_range(50.0, 200.0) var jump_horizontal_distance := 80.0
@export var air_acceleration := 500.0
@export_range(0.1, 1.5) var jump_time_to_descent := 0.2
@export var max_fall_speed := 250.0
@export_range(5.0, 50.0) var jump_cut_divider := 15.0
@export var anchor: Marker2D

var player: CharacterBody2D
var current_state := State.GROUND
var current_state_name := "GROUND"
var current_animation := ANIMATION_IDLE
var current_gravity := 0.0

var jump_speed := 0.0
var jump_gravity := 0.0
var fall_gravity := 0.0
var jump_horizontal_speed := 0.0

var coyote_timer := Timer.new()
var jump_buffer := Timer.new()


func _ready() -> void:
	player = get_parent() as CharacterBody2D
	jump_speed = calculate_jump_speed(jump_height, jump_time_to_peak)
	jump_gravity = calculate_jump_gravity(jump_height, jump_time_to_peak)
	fall_gravity = calculate_fall_gravity(jump_height, jump_time_to_descent)
	jump_horizontal_speed = calculate_jump_horizontal_speed(jump_horizontal_distance, jump_time_to_peak, jump_time_to_descent)

	coyote_timer.wait_time = 0.12
	coyote_timer.one_shot = true
	add_child(coyote_timer)

	jump_buffer.wait_time = 0.12
	jump_buffer.one_shot = true
	add_child(jump_buffer)

	_transition_to_state(current_state, 0.0)


func physics_update(
	delta: float,
	direction_x: float,
	wants_jump: bool,
	wants_aim: bool,
	aim_released: bool,
	wants_crouch: bool,
	crouch_released: bool,
	can_exit_crouch: bool
) -> void:
	match current_state:
		State.GROUND:
			_process_ground(delta, direction_x, wants_jump, wants_aim, wants_crouch, can_exit_crouch)
		State.JUMP:
			_process_jump(delta, direction_x)
		State.FALL:
			_process_fall(delta, direction_x, wants_jump)
		State.AIM:
			_process_aim(aim_released)
		State.CROUCH:
			_process_crouch(crouch_released, can_exit_crouch)

	player.velocity.y += current_gravity * delta
	player.velocity.y = minf(player.velocity.y, max_fall_speed)


func retry_crouch_exit(crouch_pressed: bool, can_exit_crouch: bool) -> void:
	if current_state == State.CROUCH and !crouch_pressed and can_exit_crouch:
		_transition_to_state(State.GROUND, 0.0)


func _process_ground(delta: float, direction_x: float, wants_jump: bool, wants_aim: bool, wants_crouch: bool, can_exit_crouch: bool) -> void:
	var is_moving := absf(direction_x) > 0.0

	if is_moving:
		current_animation = ANIMATION_RUN
		player.velocity.x = clampf(player.velocity.x + direction_x * acceleration * delta, -max_speed, max_speed)
	else:
		player.velocity.x = move_toward(player.velocity.x, 0.0, deceleration * delta)
		if player.velocity == Vector2.ZERO:
			current_animation = ANIMATION_IDLE

	if !jump_buffer.is_stopped() or wants_jump:
		_transition_to_state(State.JUMP, direction_x)
	elif wants_aim:
		_transition_to_state(State.AIM, direction_x)
	elif wants_crouch and can_exit_crouch:
		_transition_to_state(State.CROUCH, direction_x)
	elif !player.is_on_floor():
		coyote_timer.start()
		_transition_to_state(State.FALL, direction_x)


func _process_jump(delta: float, direction_x: float) -> void:
	if direction_x != 0.0:
		player.velocity.x = clampf(player.velocity.x + air_acceleration * direction_x * delta, -jump_horizontal_speed, jump_horizontal_speed)

	if player.velocity.y >= 0.0:
		_transition_to_state(State.FALL, direction_x)


func _process_fall(delta: float, direction_x: float, wants_jump: bool) -> void:
	if direction_x != 0.0:
		player.velocity.x = clampf(player.velocity.x + air_acceleration * direction_x * delta, -jump_horizontal_speed, jump_horizontal_speed)
	else:
		player.velocity.x = move_toward(player.velocity.x, 0.0, fall_deceleration * delta)

	if wants_jump:
		jump_buffer.start()
		if !coyote_timer.is_stopped():
			_transition_to_state(State.JUMP, direction_x)

	if player.is_on_floor():
		_transition_to_state(State.GROUND, direction_x)


func _process_aim(aim_released: bool) -> void:
	if aim_released:
		_transition_to_state(State.GROUND, 0.0)


func _process_crouch(crouch_released: bool, can_exit_crouch: bool) -> void:
	if crouch_released and can_exit_crouch:
		_transition_to_state(State.GROUND, 0.0)


func _transition_to_state(new_state: int, direction_x: float) -> void:
	var previous_state := current_state
	current_state = new_state

	match previous_state:
		State.FALL:
			coyote_timer.stop()
		State.CROUCH:
			if anchor != null:
				anchor.position.y = -8.0

	match current_state:
		State.GROUND:
			current_state_name = "GROUND"
		State.JUMP:
			current_state_name = "JUMP"
			player.velocity.y = jump_speed
			player.velocity.x = direction_x * jump_horizontal_speed
			current_gravity = jump_gravity
			current_animation = ANIMATION_JUMP
		State.FALL:
			current_state_name = "FALL"
			current_gravity = fall_gravity
			current_animation = ANIMATION_FALL
		State.AIM:
			current_state_name = "AIM"
			player.velocity.x = 0.0
			current_animation = ANIMATION_AIM
		State.CROUCH:
			current_state_name = "CROUCH"
			if anchor != null:
				anchor.position.y = 2.0
			player.velocity.x = 0.0
			current_animation = ANIMATION_CROUCH


func get_state() -> int:
	return current_state


func get_state_name() -> String:
	return current_state_name


func is_crouching() -> bool:
	return current_state == State.CROUCH


func is_jumping() -> bool:
	return current_state == State.JUMP


func is_falling() -> bool:
	return current_state == State.FALL


func get_animation_key() -> String:
	return current_animation


func calculate_jump_speed(height: float, time_to_peak: float) -> float:
	return (-2.0 * height) / time_to_peak


func calculate_jump_gravity(height: float, time_to_peak: float) -> float:
	return (2.0 * height) / pow(time_to_peak, 2.0)


func calculate_fall_gravity(height: float, time_to_descent: float) -> float:
	return (2.0 * height) / pow(time_to_descent, 2.0)


func calculate_jump_horizontal_speed(distance: float, time_to_peak: float, time_to_descent: float) -> float:
	return distance / (time_to_peak + time_to_descent)
