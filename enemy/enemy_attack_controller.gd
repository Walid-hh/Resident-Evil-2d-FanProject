class_name EnemyAttackController extends Node

signal attack_finished


func has_attack_opportunity(
	_body: CharacterBody2D,
	_target: Node2D,
	_config: EnemyConfig,
	sensing: EnemySensing
) -> bool:
	return sensing != null and sensing.is_target_in_attack_range


func start_attack(_body: CharacterBody2D, _target: Node2D, _config: EnemyConfig) -> void:
	attack_finished.emit()


func cancel_attack() -> void:
	pass


func is_attacking() -> bool:
	return false
