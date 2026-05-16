extends Node

signal player_died
signal mob_died(mob: Mob)

var player_level = 1
var player_position : Vector2
var player_last_direction : float = 1
var player_aim_direction : Vector2


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
