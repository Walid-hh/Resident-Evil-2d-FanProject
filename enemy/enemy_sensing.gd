class_name EnemySensing extends Node

signal player_activated
signal player_entered_attack_range
signal player_exited_attack_range

@export var activation_area: Area2D
@export var attack_area: Area2D

var target: Node2D = null
var is_target_in_attack_range := false
var _emit_attack_entered := false


func _ready() -> void:
	if activation_area != null:
		activation_area.body_entered.connect(_on_activation_body_entered)
	if attack_area != null:
		attack_area.body_entered.connect(_on_attack_body_entered)
		attack_area.body_exited.connect(_on_attack_body_exited)
	set_inactive_mode()


func set_inactive_mode() -> void:
	is_target_in_attack_range = false
	_emit_attack_entered = false
	_set_area_monitoring(activation_area, true)
	_set_area_monitoring(attack_area, false)


func set_chase_mode() -> void:
	_emit_attack_entered = true
	_set_area_monitoring(activation_area, false)
	_set_area_monitoring(attack_area, true)


func set_attack_mode() -> void:
	_emit_attack_entered = false
	_set_area_monitoring(activation_area, false)
	_set_area_monitoring(attack_area, true)


func set_disabled_mode() -> void:
	is_target_in_attack_range = false
	_emit_attack_entered = false
	_set_area_monitoring(activation_area, false)
	_set_area_monitoring(attack_area, false)


func _on_activation_body_entered(body: Node2D) -> void:
	if body == target:
		player_activated.emit()


func _on_attack_body_entered(body: Node2D) -> void:
	if body == target:
		is_target_in_attack_range = true
		if _emit_attack_entered:
			player_entered_attack_range.emit()


func _on_attack_body_exited(body: Node2D) -> void:
	if body == target:
		is_target_in_attack_range = false
		player_exited_attack_range.emit()


func _set_area_monitoring(area: Area2D, enabled: bool) -> void:
	if area == null:
		return
	area.set_deferred("monitoring", enabled)
