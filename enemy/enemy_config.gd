class_name EnemyConfig extends Resource

@export var max_health := 5
@export var acceleration := 1400.0
@export var max_speed := 50.0
@export var jump_height := 50.0
@export_range(0.1, 1.5) var jump_time_to_descent := 0.2
@export var recovery_time := 0.6
@export var inactive_animation := &"idle"
@export var chase_animation := &"run"
@export var attack_animation := &"attack"
@export var recovery_animation := &"idle"
@export var death_animation := &"idle"
