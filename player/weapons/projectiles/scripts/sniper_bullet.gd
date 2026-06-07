extends Projectile

@onready var sprite_2d: AnimatedSprite2D = %Sprite2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	active_timer.start()
	sprite_2d.animation_finished.connect(_destroy)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	super._travel(delta)
