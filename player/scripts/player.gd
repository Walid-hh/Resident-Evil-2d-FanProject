class_name Player extends CharacterBody2D

@onready var legs: AnimatedSprite2D = %Legs
@onready var arms: AnimatedSprite2D = %Arms
@onready var body: AnimatedSprite2D = %Body
@onready var head: AnimatedSprite2D = %Head
@onready var state_debug_label: Label = %StateDebugLabel
@onready var animation_debug_label: Label = %AnimationDebugLabel

@onready var motor: PlayerMotor = %PlayerMotor
@onready var aim_controller: AimController = %AimController
@onready var weapon_inventory: WeaponInventory = %WeaponInventory
@onready var player_animator: PlayerAnimator = %PlayerAnimator


func _ready() -> void:
	weapon_inventory.initialize()
	player_animator.attack_animation_finished.connect(_on_attack_animation_finished)


func _physics_process(delta: float) -> void:
	var jump_pressed := Input.is_action_just_pressed("jump")
	var aim_pressed := Input.is_action_pressed("aim")
	var aim_released := Input.is_action_just_released("aim")
	var crouch_pressed := Input.is_action_pressed("down")
	var crouch_released := Input.is_action_just_released("down")
	var fire_pressed := Input.is_action_just_pressed("fire")
	var next_weapon_pressed := Input.is_action_just_pressed("next_weapon")
	var previous_weapon_pressed := Input.is_action_just_pressed("previous_weapon")

	aim_controller.physics_update(motor.get_state(), motor.is_crouching(), arms.flip_h)
	if !motor.is_crouching():
		aim_controller.apply_facing([legs, arms, body, head])

	motor.physics_update(
		delta,
		aim_controller.get_direction_x(),
		jump_pressed,
		aim_pressed,
		aim_released,
		crouch_pressed,
		crouch_released,
		!player_animator.is_firing()
	)

	weapon_inventory.physics_update(
		delta,
		fire_pressed,
		aim_controller.get_aim_direction(),
		aim_controller.get_last_horizontal_direction()
	)
	if fire_pressed:
		player_animator.start_attack(aim_controller.get_aim_direction())

	if next_weapon_pressed:
		weapon_inventory.cycle_next_unlocked_weapon()
	if previous_weapon_pressed:
		weapon_inventory.cycle_previous_unlocked_weapon()

	player_animator.physics_update(
		motor.get_animation_key(),
		motor.get_state(),
		weapon_inventory.get_weapon_in_use(),
		aim_controller.get_aim_direction()
	)
	_update_debug_labels()
	move_and_slide()


func _on_attack_animation_finished() -> void:
	motor.retry_crouch_exit(Input.is_action_pressed("down"), !player_animator.is_firing())


func _update_debug_labels() -> void:
	state_debug_label.text = motor.get_state_name()
	animation_debug_label.text = arms.animation


func get_weapon_in_use() -> Weapon:
	return weapon_inventory.get_weapon_in_use()


func get_active_weapon_config() -> WeaponConfig:
	return weapon_inventory.get_active_weapon_config()


func get_unlocked_weapon_configs() -> Array[WeaponConfig]:
	return weapon_inventory.get_unlocked_weapon_configs()
