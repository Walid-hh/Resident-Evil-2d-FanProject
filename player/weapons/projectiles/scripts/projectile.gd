class_name Projectile extends Node2D

@onready var hit_box: HitBox2D = %HitBox2D
@export var damage := 1
@export var speed : float = 50.0
@export var max_range : float  = 200.0
@export var active_time : float = 0.8
var _initial_position : Vector2
var direction : Vector2 
var active_timer : Timer

func _ready() -> void:
	_initial_position = position
	hit_box.damage = damage
	active_timer = Timer.new()
	active_timer.one_shot = true
	active_timer.wait_time = active_time
	add_child(active_timer)
	active_timer.timeout.connect(_destroy)

func _physics_process(delta: float) -> void:
	pass
	
func _travel(delta: float) -> void:
		var velocity := direction * speed
		position += velocity * delta
		var distance_traveled := _initial_position.distance_to(position)
		if distance_traveled > max_range :
			_destroy()

func destroy_on_hit() -> void:
	hit_box.hit_hurt_box.connect(func(hurt_box : HurtBox2D) :
		_destroy())

func _destroy() -> void :
		queue_free()
