extends Projectile


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	super.destroy_on_hit()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	super._travel(delta)
