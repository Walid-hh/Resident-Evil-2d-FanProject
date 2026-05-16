class_name Shotgun extends Weapon

@export var fire_rate : float = 1.0
var fire_direction := Vector2.ZERO
var fire_timer : float

#func _ready() -> void:
	#visible = false
	#set_physics_process(false)

func _ready() -> void:
	super._ready()
	add_to_group("shotgun")
	fire_timer = fire_rate
	is_weapon_unlocked = true

	
func _physics_process(delta: float) -> void :
	fire_timer += delta
	fire_direction = Global.player_aim_direction.normalized()
	## bullet direction if player isnt moving joystick or dpad
	if fire_direction == Vector2.ZERO :
		fire_direction.x = Global.player_last_direction
	anchor.global_rotation = fire_direction.angle()
	if Input.is_action_just_pressed("fire"):
		if fire_timer >= fire_rate :
			_shoot()
			fire_timer = 0.0

func _shoot() -> void :
	var projectile := projectile_scene.instantiate()
	projectile.direction = fire_direction
	projectile.global_transform = global_transform
	get_tree().root.add_child(projectile)

func get_is_weapon_unlocked() -> bool :
	return is_weapon_unlocked
