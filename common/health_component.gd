class_name HealthComponent extends Node2D
@export var hurt_box : HurtBox2D = null
@export var max_health : int = 5 : set = set_max_health
var health : int : set = set_health
var health_bar : ProgressBar

func _ready():
	health_bar = get_node_or_null("%HealthBar")
	if health_bar != null :
		health_bar.max_value = max_health
		health_bar.value = max_health
	health = max_health
	hurt_box.took_hit.connect(func(hit_box) -> void :
		damage_health(hit_box)
		)

func set_health(new_health):
	health = clamp(new_health, 0, max_health)
	if health_bar != null :
		health_bar.value = health
	if health == 0 :
		get_parent().queue_free()

func damage_health(hit_box : HitBox2D):
	set_health(health - hit_box.damage)

func set_max_health(new_value: int) -> void:
	var difference := new_value - max_health
	max_health = new_value
	health += difference
