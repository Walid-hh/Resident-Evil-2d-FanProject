extends Node

signal player_died
signal enemy_died(enemy: Enemy)

var player_level = 1
var player_position : Vector2
var player_last_direction : float = 1
var player_aim_direction : Vector2


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
