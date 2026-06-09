class_name HealthComponent extends Node2D

signal health_changed(current_health: int, max_health: int)
signal damaged(amount: int, source: Variant)
signal died(source: Variant)

@export var hurt_box: HurtBox2D = null
@export var max_health: int = 5

var health: int = 0: set = set_health
var _is_dead := false
var _death_source: Variant = null


func _ready() -> void:
	set_health(max_health)
	if hurt_box == null:
		return

	hurt_box.took_hit.connect(func(hit_box: HitBox2D) -> void:
		take_damage(hit_box.damage, hit_box)
	)


func take_damage(amount: int, source: Variant = null) -> void:
	var damage_amount: int = maxi(amount, 0)
	if damage_amount == 0 or health == 0:
		return

	damaged.emit(damage_amount, source)
	_death_source = source
	set_health(health - damage_amount)
	_death_source = null


func heal(amount: int) -> void:
	var heal_amount: int = maxi(amount, 0)
	if heal_amount == 0:
		return

	set_health(health + heal_amount)


func set_health(new_health: int) -> void:
	var previous_health := health
	health = clampi(new_health, 0, max_health)

	if health > 0:
		_is_dead = false

	if health == previous_health:
		return

	health_changed.emit(health, max_health)

	if health == 0 and !_is_dead:
		_is_dead = true
		died.emit(_death_source)


func set_max_health(new_max_health: int, keep_current_ratio := false) -> void:
	var previous_max_health := max_health
	var previous_health := health
	max_health = maxi(new_max_health, 1)

	if keep_current_ratio and previous_max_health > 0:
		var health_ratio := float(previous_health) / float(previous_max_health)
		set_health(roundi(float(max_health) * health_ratio))
	else:
		set_health(min(health, max_health))
